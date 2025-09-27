import "../../../core/constants/enums.dart";
import "../../../core/contracts/repositories/menu/menu_repository_contracts.dart";
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
// Removed LoggerComponent mixin; use local tag
import "../../../core/logging/compat.dart" as log;
import "../../menu/models/menu_model.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "order_calculation_service.dart";
import "order_stock_service.dart";

/// カート管理サービス
class CartManagementService {
  CartManagementService({
    required OrderRepositoryContract<Order> orderRepository,
    required OrderItemRepositoryContract<OrderItem> orderItemRepository,
    required MenuItemRepositoryContract<MenuItem> menuItemRepository,
    required OrderCalculationService orderCalculationService,
    required OrderStockService orderStockService,
  }) : _orderRepository = orderRepository,
       _orderItemRepository = orderItemRepository,
       _menuItemRepository = menuItemRepository,
       _orderCalculationService = orderCalculationService,
       _orderStockService = orderStockService;

  final OrderRepositoryContract<Order> _orderRepository;
  final OrderItemRepositoryContract<OrderItem> _orderItemRepository;
  final MenuItemRepositoryContract<MenuItem> _menuItemRepository;
  final OrderCalculationService _orderCalculationService;
  final OrderStockService _orderStockService;

  String get loggerComponent => "CartManagementService";

  /// アクティブなカート（下書き注文）を取得（存在しない場合は `null`）。
  Future<Order?> getActiveCart(String userId) async {
    log.i("Started retrieving active cart for user", tag: loggerComponent);

    try {
      final Order? existingCart = await _orderRepository.findActiveDraftByUser();

      if (existingCart != null) {
        log.i("Active cart found and returned", tag: loggerComponent);
        return existingCart;
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
      final Order newCart = Order(
        totalAmount: 0,
        status: OrderStatus.preparing,
        paymentMethod: PaymentMethod.cash, // デフォルト値
        discountAmount: 0,
        orderedAt: now,
        createdAt: now,
        updatedAt: now,
        userId: userId,
      );

      final Order? createdCart = await _orderRepository.create(newCart);

      if (createdCart != null) {
        log.i("New cart created successfully", tag: loggerComponent);
      } else {
        log.e("Failed to create new cart", tag: loggerComponent);
      }

      return createdCart;
    } catch (e, stackTrace) {
      log.e("Failed to get or create active cart", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カートに商品を追加（戻り値: (OrderItem, 在庫充足フラグ)）
  Future<(OrderItem?, bool)> addItemToCart(
    String cartId,
    CartItemRequest request,
    String userId,
  ) async {
    log.i("Started adding item to cart: quantity=${request.quantity}", tag: loggerComponent);

    try {
      final Map<String, String> resolvedSelectedOptions =
          request.selectedOptions ?? <String, String>{};
      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        log.e("Cart access denied or cart not found", tag: loggerComponent);
        throw Exception("Cart $cartId not found or access denied");
      }

      // メニューアイテムの取得
      final MenuItem? menuItem = await _menuItemRepository.getById(request.menuItemId);
      if (menuItem == null || menuItem.userId != userId) {
        log.e("Menu item access denied or menu item not found", tag: loggerComponent);
        throw Exception("Menu item ${request.menuItemId} not found");
      }

      // 在庫確認
      log.d("Checking stock availability for menu item", tag: loggerComponent);
      final bool isStockSufficient = await _orderStockService.checkMenuItemStock(
        request.menuItemId,
        request.quantity,
      );

      if (!isStockSufficient) {
        log.w("Stock insufficient for requested quantity", tag: loggerComponent);
      }

      // 既存のアイテムがあるかチェック
      final OrderItem? existingItem = await _orderItemRepository.findExistingItem(
        cartId,
        request.menuItemId,
      );

      if (existingItem != null) {
        // 既存アイテムの数量を更新
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

        final OrderItem? updatedItem = await _orderItemRepository
            .updateById(existingItem.id!, updatePayload);

        // カート合計を更新
        await _updateCartTotal(cartId);

        log.i("Cart item quantity updated successfully", tag: loggerComponent);
        return (updatedItem, isStockSufficient);
      } else {
        // 新しいアイテムを作成
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

        final OrderItem? createdItem = await _orderItemRepository.create(orderItem);

        // カート合計を更新
        await _updateCartTotal(cartId);

        log.i("New cart item created successfully", tag: loggerComponent);
        return (createdItem, isStockSufficient);
      }
    } catch (e, stackTrace) {
      log.e("Failed to add item to cart", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カート内商品の数量を更新
  Future<(OrderItem?, bool)> updateCartItemQuantity(
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

      // カートと注文アイテムの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        log.e("Cart access denied or cart not found", tag: loggerComponent);
        throw Exception("Cart $cartId not found or access denied");
      }

      final OrderItem? orderItem = await _orderItemRepository.getById(orderItemId);
      if (orderItem == null || orderItem.orderId != cartId) {
        log.e("Order item not found in cart", tag: loggerComponent);
        throw Exception("Order item $orderItemId not found in cart");
      }

      // メニューアイテムの取得（価格情報のため）
      final MenuItem? menuItem = await _menuItemRepository.getById(orderItem.menuItemId);
      if (menuItem == null) {
        log.e("Menu item not found for order item", tag: loggerComponent);
        throw Exception("Menu item ${orderItem.menuItemId} not found");
      }

      // 在庫確認
      log.d("Checking stock availability for updated quantity", tag: loggerComponent);
      final bool isStockSufficient = await _orderStockService.checkMenuItemStock(
        orderItem.menuItemId,
        newQuantity,
      );

      if (!isStockSufficient) {
        log.w("Stock insufficient for updated quantity", tag: loggerComponent);
      }

      // 数量と小計を更新
      final int newSubtotal = _orderCalculationService.calculateItemSubtotal(
        menuItem.price,
        newQuantity,
      );
      final OrderItem? updatedItem = await _orderItemRepository.updateById(
        orderItemId,
        <String, dynamic>{"quantity": newQuantity, "subtotal": newSubtotal},
      );

      // カート合計を更新
      await _updateCartTotal(cartId);

      log.i("Cart item quantity updated successfully", tag: loggerComponent);
      return (updatedItem, isStockSufficient);
    } catch (e, stackTrace) {
      log.e("Failed to update cart item quantity", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カートから商品を削除
  Future<bool> removeItemFromCart(String cartId, String orderItemId, String userId) async {
    log.i("Started removing item from cart", tag: loggerComponent);

    try {
      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        log.e("Cart access denied or cart not found", tag: loggerComponent);
        throw Exception("Cart $cartId not found or access denied");
      }

      // 注文アイテムの存在確認
      final OrderItem? orderItem = await _orderItemRepository.getById(orderItemId);
      if (orderItem == null || orderItem.orderId != cartId) {
        log.e("Order item not found in cart", tag: loggerComponent);
        throw Exception("Order item $orderItemId not found in cart");
      }

      // アイテムを削除
      await _orderItemRepository.deleteById(orderItemId);

      // カート合計を更新
      await _updateCartTotal(cartId);

      log.i("Cart item removed successfully", tag: loggerComponent);
      return true;
    } catch (e, stackTrace) {
      log.e("Failed to remove item from cart", tag: loggerComponent, error: e, st: stackTrace);
      return false;
    }
  }

  /// カートを空にする
  Future<bool> clearCart(String cartId, String userId) async {
    log.i("Started clearing cart", tag: loggerComponent);

    try {
      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        log.e("Cart access denied or cart not found", tag: loggerComponent);
        throw Exception("Cart $cartId not found or access denied");
      }

      // カート内の全アイテムを削除
      final bool success = await _orderItemRepository.deleteByOrderId(cartId);

      if (success) {
        // カートの合計金額をリセット
        await _orderRepository.updateById(cartId, <String, dynamic>{"total_amount": 0});
        log.i("Cart cleared successfully", tag: loggerComponent);
      } else {
        log.w("Failed to clear cart items", tag: loggerComponent);
      }

      return success;
    } catch (e, stackTrace) {
      log.e("Failed to clear cart", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カート内全商品の在庫を検証（戻り値: {order_item_id: 在庫充足フラグ}）
  Future<Map<String, bool>> validateCartStock(String cartId, String userId) async {
    log.i("Started validating cart stock", tag: loggerComponent);

    try {
      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        log.e("Cart access denied or cart not found", tag: loggerComponent);
        throw Exception("Cart $cartId not found or access denied");
      }

      // カート内のアイテムを取得
      final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);

      log.d("Validating stock for ${cartItems.length} cart items", tag: loggerComponent);

      // 在庫検証サービスを使用
      return _orderStockService.validateCartStock(cartItems);
    } catch (e, stackTrace) {
      log.e("Failed to validate cart stock", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カートの合計金額を更新
  Future<void> _updateCartTotal(String cartId) async {
    final int totalAmount = await _orderCalculationService.updateCartTotal(cartId);
    await _orderRepository.updateById(cartId, <String, dynamic>{"total_amount": totalAmount});
  }
}
