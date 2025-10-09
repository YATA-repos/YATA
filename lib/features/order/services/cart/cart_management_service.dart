import "../../../../core/constants/enums.dart";
import "../../../../core/constants/exceptions/repository/repository_exception.dart";
import "../../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../../core/contracts/repositories/menu/menu_repository_contracts.dart";
import "../../../../core/contracts/repositories/order/order_repository_contracts.dart";
import "../../../menu/models/menu_model.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "models/cart_snapshot.dart";
import "../order/order_calculation_service.dart";
import "../order/order_inventory_integration_service.dart";
import "../shared/order_validation_utils.dart";

/// カート管理サービス
class CartManagementService {
  CartManagementService({
    required log_contract.LoggerContract logger,
    required OrderRepositoryContract<Order> orderRepository,
    required OrderItemRepositoryContract<OrderItem> orderItemRepository,
    required MenuItemRepositoryContract<MenuItem> menuItemRepository,
    required OrderCalculationService orderCalculationService,
    required OrderInventoryIntegrationService orderInventoryIntegrationService,
  }) : _logger = logger,
       _orderRepository = orderRepository,
       _orderItemRepository = orderItemRepository,
       _menuItemRepository = menuItemRepository,
       _orderCalculationService = orderCalculationService,
  _inventoryIntegrationService = orderInventoryIntegrationService;

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final OrderRepositoryContract<Order> _orderRepository;
  final OrderItemRepositoryContract<OrderItem> _orderItemRepository;
  final MenuItemRepositoryContract<MenuItem> _menuItemRepository;
  final OrderCalculationService _orderCalculationService;
  final OrderInventoryIntegrationService _inventoryIntegrationService;

  String get loggerComponent => "CartManagementService";

  /// アクティブなカート（下書き注文）を取得（存在しない場合は `null`）。
  Future<Order?> getActiveCart(String userId) async {
    log.i("Started retrieving active cart for user", tag: loggerComponent);

    try {
      final Order? existingCart = await _orderRepository.findActiveDraftByUser(userId);

      if (existingCart != null) {
        final Order ensuredCart = await _ensureCartHasDisplayCode(existingCart);
        log.i("Active cart found and returned", tag: loggerComponent);
        return ensuredCart;
      }

      log.i("Active cart not found", tag: loggerComponent);
      return null;
    } catch (e, stackTrace) {
      log.e("Failed to get active cart", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// アクティブなカートを取得し、存在しなければ新規作成して返す。
  Future<Order?> getOrCreateActiveCart(String userId) async {
    log.i("Started retrieving or creating active cart for user", tag: loggerComponent);

    try {
      final Order? existingCart = await getActiveCart(userId);

      if (existingCart != null) {
        return existingCart;
      }

      log.d("Creating new cart for user", tag: loggerComponent);
      final DateTime now = DateTime.now();
      final String displayCode = await _orderRepository.generateNextOrderNumber();
      final Order newCart = Order(
        totalAmount: 0,
        status: OrderStatus.inProgress,
        paymentMethod: PaymentMethod.cash, // デフォルト値
        discountAmount: 0,
        orderedAt: now,
        isCart: true,
        createdAt: now,
        updatedAt: now,
        userId: userId,
        orderNumber: displayCode,
      );

      final Order? createdCart = await _orderRepository.create(newCart);

      if (createdCart != null) {
        log.i(
          "New cart created successfully",
          tag: loggerComponent,
          fields: <String, Object?>{"orderNumber": createdCart.orderNumber},
        );
        return await _ensureCartHasDisplayCode(createdCart);
      }

      log.e("Failed to create new cart", tag: loggerComponent);
      return createdCart;
    } catch (e, stackTrace) {
      log.e("Failed to get or create active cart", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カートに商品を追加し、最新のスナップショットを返却する。
  Future<CartMutationResult> addItemToCart(
    String cartId,
    CartItemRequest request,
    String userId,
  ) async {
    log.i("Started adding item to cart: quantity=${request.quantity}", tag: loggerComponent);

    try {
      final Map<String, String> resolvedSelectedOptions =
          request.selectedOptions ?? <String, String>{};

      final Future<Order?> cartFuture = _orderRepository.getById(cartId);
      final Future<MenuItem?> menuItemFuture =
          _menuItemRepository.getById(request.menuItemId);
      final Future<bool> stockFuture = _inventoryIntegrationService.checkMenuItemStock(
        request.menuItemId,
        request.quantity,
      );

      final Order cart = OrderValidationUtils.requireOrderOwnedByUser(
        order: await cartFuture,
        orderId: cartId,
        userId: userId,
        logger: log,
        loggerComponent: loggerComponent,
        onFailureLog: () => log.e("Cart access denied or cart not found", tag: loggerComponent),
      );

      final MenuItem? menuItem = await menuItemFuture;
      if (menuItem == null || menuItem.userId != userId) {
        log.e("Menu item access denied or menu item not found", tag: loggerComponent);
        throw Exception("Menu item ${request.menuItemId} not found");
      }

      log.d("Checking stock availability for menu item", tag: loggerComponent);
      final bool isStockSufficient = await stockFuture;

      if (!isStockSufficient) {
        log.w("Stock insufficient for requested quantity", tag: loggerComponent);
      }

      final OrderItem? existingItem = await _orderItemRepository.findExistingItem(
        cartId,
        request.menuItemId,
      );

      OrderItem? mutationItem;
      CartMutationKind mutationKind = CartMutationKind.add;

      if (existingItem != null) {
        log.d("Updating existing cart item quantity", tag: loggerComponent);
        final int newQuantity = existingItem.quantity + request.quantity;
        final int newSubtotal = _orderCalculationService.calculateItemSubtotal(
          menuItem.price,
          newQuantity,
        );

        final Map<String, dynamic> updatePayload = <String, dynamic>{
          "quantity": newQuantity,
          "subtotal": newSubtotal,
          "special_request": request.specialRequest,
        };
        if (request.selectedOptions != null) {
          updatePayload["selected_options"] = request.selectedOptions;
        }

        mutationItem =
            await _orderItemRepository.updateById(existingItem.id!, updatePayload) ?? existingItem
              ..quantity = newQuantity
              ..subtotal = newSubtotal
              ..specialRequest = request.specialRequest;
        mutationKind = CartMutationKind.update;
      } else {
        log.d("Creating new cart item", tag: loggerComponent);
        final int subtotal = _orderCalculationService.calculateItemSubtotal(
          menuItem.price,
          request.quantity,
        );

        final OrderItem orderItem = OrderItem(
          orderId: cartId,
          menuItemId: request.menuItemId,
          quantity: request.quantity,
          unitPrice: menuItem.price,
          subtotal: subtotal,
          selectedOptions: resolvedSelectedOptions,
          specialRequest: request.specialRequest,
          createdAt: DateTime.now(),
          userId: userId,
        );

        mutationItem = await _orderItemRepository.create(orderItem);
        mutationKind = CartMutationKind.add;
      }

      final List<OrderItem> updatedItems = await _orderItemRepository.findByOrderId(cartId);
      final Order? updatedCart = await _updateCartTotal(cartId, preloadedItems: updatedItems);

      final CartSnapshotData? snapshot = await loadCartSnapshot(
        cartId,
        userId,
        preloadOrder: updatedCart,
        preloadItems: updatedItems,
        preloadMenuItems: <MenuItem>[menuItem],
      );

      if (snapshot == null) {
        throw Exception("Cart $cartId not found during snapshot assembly");
      }

      log.i("Cart item mutation completed", tag: loggerComponent);

      return CartMutationResult(
        kind: mutationKind,
        snapshot: snapshot,
        stockStatus: <String, bool>{request.menuItemId: isStockSufficient},
        highlightMenuItemId: mutationItem?.menuItemId,
      );
    } catch (e, stackTrace) {
      log.e("Failed to add item to cart", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カート内商品の数量を更新し、最新スナップショットを返却する。
  Future<CartMutationResult> updateCartItemQuantity(
    String cartId,
    String orderItemId,
    int newQuantity,
    String userId,
  ) async {
    log.i("Started updating cart item quantity: newQuantity=$newQuantity", tag: loggerComponent);

    try {
      if (newQuantity <= 0) {
        log.e("Invalid quantity provided: must be greater than 0", tag: loggerComponent);
        throw Exception("Quantity must be greater than 0");
      }

      final Future<Order?> cartFuture = _orderRepository.getById(cartId);
      final Future<OrderItem?> orderItemFuture = _orderItemRepository.getById(orderItemId);

      final Order cart = _ensureCartOwnership(await cartFuture, cartId, userId);

      final OrderItem? orderItem = await orderItemFuture;
      if (orderItem == null || orderItem.orderId != cartId) {
        log.e("Order item not found in cart", tag: loggerComponent);
        throw Exception("Order item $orderItemId not found in cart");
      }

    final Future<MenuItem?> menuItemFuture = _menuItemRepository.getById(orderItem.menuItemId);
    final Future<bool> stockFuture = _inventoryIntegrationService.checkMenuItemStock(
        orderItem.menuItemId,
        newQuantity,
      );

      final MenuItem? menuItem = await menuItemFuture;
      if (menuItem == null) {
        log.e("Menu item not found for order item", tag: loggerComponent);
        throw Exception("Menu item ${orderItem.menuItemId} not found");
      }

      log.d("Checking stock availability for updated quantity", tag: loggerComponent);
      final bool isStockSufficient = await stockFuture;

      if (!isStockSufficient) {
        log.w("Stock insufficient for updated quantity", tag: loggerComponent);
      }

      final int newSubtotal = _orderCalculationService.calculateItemSubtotal(
        menuItem.price,
        newQuantity,
      );

      final OrderItem? updatedItem = await _orderItemRepository.updateById(
        orderItemId,
        <String, dynamic>{"quantity": newQuantity, "subtotal": newSubtotal},
      );

      final List<OrderItem> updatedItems = await _orderItemRepository.findByOrderId(cartId);
      final Order? updatedCart = await _updateCartTotal(cartId, preloadedItems: updatedItems);

      final CartSnapshotData? snapshot = await loadCartSnapshot(
        cartId,
        userId,
        preloadOrder: updatedCart,
        preloadItems: updatedItems,
        preloadMenuItems: <MenuItem>[menuItem],
      );

      if (snapshot == null) {
        throw Exception("Cart $cartId not found during snapshot assembly");
      }

      log.i("Cart item quantity updated successfully", tag: loggerComponent);

      return CartMutationResult(
        kind: CartMutationKind.update,
        snapshot: snapshot,
        stockStatus: <String, bool>{orderItem.menuItemId: isStockSufficient},
        highlightMenuItemId: updatedItem?.menuItemId ?? orderItem.menuItemId,
      );
    } catch (e, stackTrace) {
      log.e("Failed to update cart item quantity", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カートから商品を削除し、最新スナップショットを返却する。
  Future<CartMutationResult> removeItemFromCart(
    String cartId,
    String orderItemId,
    String userId,
  ) async {
    log.i("Started removing item from cart", tag: loggerComponent);

    try {
      final Future<Order?> cartFuture = _orderRepository.getById(cartId);
      final Future<OrderItem?> orderItemFuture = _orderItemRepository.getById(orderItemId);

      final Order cart = _ensureCartOwnership(await cartFuture, cartId, userId);

      final OrderItem? orderItem = await orderItemFuture;
      if (orderItem == null || orderItem.orderId != cartId) {
        log.e("Order item not found in cart", tag: loggerComponent);
        throw Exception("Order item $orderItemId not found in cart");
      }

      await _orderItemRepository.deleteById(orderItemId);

      final List<OrderItem> updatedItems = await _orderItemRepository.findByOrderId(cartId);
      final Order? updatedCart = await _updateCartTotal(cartId, preloadedItems: updatedItems);

      final CartSnapshotData? snapshot = await loadCartSnapshot(
        cartId,
        userId,
        preloadOrder: updatedCart,
        preloadItems: updatedItems,
      );

      if (snapshot == null) {
        throw Exception("Cart $cartId not found during snapshot assembly");
      }

      log.i("Cart item removed successfully", tag: loggerComponent);

      return CartMutationResult(kind: CartMutationKind.remove, snapshot: snapshot);
    } catch (e, stackTrace) {
      log.e("Failed to remove item from cart", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カートを空にし、最新スナップショットを返却する。
  Future<CartMutationResult> clearCart(String cartId, String userId) async {
    log.i("Started clearing cart", tag: loggerComponent);

    try {
      final Order cart = _ensureCartOwnership(
        await _orderRepository.getById(cartId),
        cartId,
        userId,
      );

      await _orderItemRepository.deleteByOrderId(cartId);

      final DateTime now = DateTime.now();
      final Order? updated = await _orderRepository.updateById(cartId, <String, dynamic>{
        "total_amount": 0,
        "notes": null,
        "updated_at": now.toIso8601String(),
      });

      final Order baseOrder = updated ?? cart;
      baseOrder
        ..totalAmount = 0
        ..notes = null;

      final CartSnapshotData? snapshot = await loadCartSnapshot(
        cartId,
        userId,
        preloadOrder: baseOrder,
        preloadItems: const <OrderItem>[],
      );

      if (snapshot == null) {
        throw Exception("Cart $cartId not found during snapshot assembly");
      }

      log.i("Cart cleared successfully", tag: loggerComponent);

      return CartMutationResult(kind: CartMutationKind.clear, snapshot: snapshot);
    } catch (e, stackTrace) {
      log.e("Failed to clear cart", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 支払い方法を更新する
  Future<Order?> updateCartPaymentMethod(String cartId, PaymentMethod method, String userId) async {
    log.i("Started updating cart payment method", tag: loggerComponent);

    try {
      final Order cart = _ensureCartOwnership(
        await _orderRepository.getById(cartId),
        cartId,
        userId,
      );

      final DateTime now = DateTime.now();
      final Order? updated = await _orderRepository.updateById(cartId, <String, dynamic>{
        "payment_method": method.value,
        "updated_at": now.toIso8601String(),
      });

      if (updated != null) {
        log.i("Cart payment method updated successfully", tag: loggerComponent);
      } else {
        log.w("Cart payment method update returned null", tag: loggerComponent);
      }

      return updated;
    } catch (e, stackTrace) {
      log.e("Failed to update cart payment method", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カート内全商品の在庫を検証（戻り値: {order_item_id: 在庫充足フラグ}）
  Future<Map<String, bool>> validateCartStock(String cartId, String userId) async {
    log.i("Started validating cart stock", tag: loggerComponent);

    try {
      // カートの存在確認
      _ensureCartOwnership(
        await _orderRepository.getById(cartId),
        cartId,
        userId,
      );

      // カート内のアイテムを取得
      final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);

      log.d("Validating stock for ${cartItems.length} cart items", tag: loggerComponent);

    // 在庫検証サービスを使用
    return _inventoryIntegrationService.validateCartStock(cartItems);
    } catch (e, stackTrace) {
      log.e("Failed to validate cart stock", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カートのスナップショットを取得する。
  Future<CartSnapshotData?> loadCartSnapshot(
    String cartId,
    String userId, {
    Order? preloadOrder,
    List<OrderItem>? preloadItems,
    List<MenuItem>? preloadMenuItems,
  }) async {
    final Order? order = OrderValidationUtils.getOrderIfOwnedByUser(
      order: preloadOrder ?? await _orderRepository.getById(cartId),
      orderId: cartId,
      userId: userId,
      logger: log,
      loggerComponent: loggerComponent,
      onFailureLog: () => log.w(
        "Cart snapshot requested but cart not found or access denied",
        tag: loggerComponent,
        fields: <String, Object?>{"cartId": cartId, "userId": userId},
      ),
    );

    if (order == null) {
      return null;
    }

    final List<OrderItem> orderItems =
        preloadItems ?? await _orderItemRepository.findByOrderId(cartId);

    final List<MenuItem> preloadMenus = preloadMenuItems ?? <MenuItem>[];
    final Map<String, MenuItem> preloadIndex = <String, MenuItem>{
      for (final MenuItem menu in preloadMenus)
        if (menu.id != null) menu.id!: menu,
    };

    final Set<String> menuIds = <String>{for (final OrderItem item in orderItems) item.menuItemId};
    final List<String> missingMenuIds = menuIds
        .where((String id) => !preloadIndex.containsKey(id))
        .toList();

    final Map<String, MenuItem> menuIndex = <String, MenuItem>{...preloadIndex};

    if (missingMenuIds.isNotEmpty) {
      final List<MenuItem> fetchedMenus = await _menuItemRepository.findByIds(missingMenuIds);
      for (final MenuItem menu in fetchedMenus) {
        final String? id = menu.id;
        if (id != null) {
          menuIndex[id] = menu;
        }
      }
    }

    final List<MenuItem> menuItems = menuIndex.values.toList(growable: false);

    return CartSnapshotData(order: order, orderItems: orderItems, menuItems: menuItems);
  }

  Order _ensureCartOwnership(
    Order? cart,
    String cartId,
    String userId,
  ) => OrderValidationUtils.requireOrderOwnedByUser(
        order: cart,
        orderId: cartId,
        userId: userId,
        logger: log,
        loggerComponent: loggerComponent,
        onFailureLog: () => log.e("Cart access denied or cart not found", tag: loggerComponent),
      );

  /// カートの合計金額を更新し、更新後のカートを返却する。
  Future<Order?> _updateCartTotal(String cartId, {List<OrderItem>? preloadedItems}) async {
    final int totalAmount = await _orderCalculationService.updateCartTotal(
      cartId,
      preloadedItems: preloadedItems,
    );
    final DateTime now = DateTime.now();
    final Order? updated = await _orderRepository.updateById(cartId, <String, dynamic>{
      "total_amount": totalAmount,
      "updated_at": now.toIso8601String(),
    });
    if (updated != null) {
      return updated;
    }
    return _orderRepository.getById(cartId);
  }

  Future<Order> _ensureCartHasDisplayCode(Order cart) async {
    if (!_needsDisplayCode(cart)) {
      return cart;
    }

    if (cart.id == null) {
      log.w(
        "Cart has no ID; cannot assign order display code",
        tag: loggerComponent,
        fields: <String, Object?>{"userId": cart.userId},
      );
      return cart;
    }

    return _assignDisplayCodeWithRetry(cart);
  }

  Future<Order> _assignDisplayCodeWithRetry(Order cart) async {
    const int maxAttempts = 5;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final String candidate = await _orderRepository.generateNextOrderNumber();
      final DateTime now = DateTime.now();

      try {
        final Order? updated = await _orderRepository.updateById(cart.id!, <String, dynamic>{
          "order_number": candidate,
          "updated_at": now.toIso8601String(),
        });

        final Order result = updated ?? cart
          ..orderNumber = candidate
          ..updatedAt = now;

        log.i(
          "Assigned order display code to cart",
          tag: loggerComponent,
          fields: <String, Object?>{
            "cartId": cart.id,
            "orderNumber": candidate,
            "attempt": attempt + 1,
          },
        );
        return result;
      } on RepositoryException catch (error, stackTrace) {
        if (_isUniqueConstraintViolation(error)) {
          log.w(
            "Order display code collision detected during assignment",
            tag: loggerComponent,
            fields: <String, Object?>{
              "cartId": cart.id,
              "orderNumber": candidate,
              "attempt": attempt + 1,
              "exception": error.toString(),
              "stackTrace": stackTrace.toString(),
            },
          );
          continue;
        }

        rethrow;
      }
    }

    final Exception assignmentError = Exception(
      "Failed to assign order display code to cart after $maxAttempts attempts",
    );
    log.e(
      "Failed to assign order display code to cart",
      tag: loggerComponent,
      error: assignmentError,
      fields: <String, Object?>{"cartId": cart.id},
    );
    throw assignmentError;
  }

  bool _needsDisplayCode(Order cart) {
    final String? code = cart.orderNumber;
    return code == null || code.trim().isEmpty;
  }

  bool _isUniqueConstraintViolation(RepositoryException error) {
    final String? message = error.params["error"];
    if (message == null) {
      return false;
    }

    final String normalized = message.toLowerCase();
    return normalized.contains("duplicate key") || normalized.contains("unique constraint");
  }
}
