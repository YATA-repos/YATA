import "../../../core/constants/enums.dart";
import "../../../core/utils/logger_mixin.dart";
import "../../inventory/models/inventory_model.dart";
import "../../inventory/repositories/material_repository.dart";
import "../../inventory/repositories/recipe_repository.dart";
import "../../menu/models/menu_model.dart";
import "../../menu/repositories/menu_item_repository.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "../repositories/order_item_repository.dart";
import "../repositories/order_repository.dart";

class CartService with LoggerMixin {
  CartService({
    OrderRepository? orderRepository,
    OrderItemRepository? orderItemRepository,
    MenuItemRepository? menuItemRepository,
    MaterialRepository? materialRepository,
    RecipeRepository? recipeRepository,
  }) : _orderRepository = orderRepository ?? OrderRepository(),
       _orderItemRepository = orderItemRepository ?? OrderItemRepository(),
       _menuItemRepository = menuItemRepository ?? MenuItemRepository(),
       _materialRepository = materialRepository ?? MaterialRepository(),
       _recipeRepository = recipeRepository ?? RecipeRepository();

  final OrderRepository _orderRepository;

  @override
  String get loggerComponent => "CartService";
  final OrderItemRepository _orderItemRepository;
  final MenuItemRepository _menuItemRepository;
  final MaterialRepository _materialRepository;
  final RecipeRepository _recipeRepository;

  /// アクティブなカート（下書き注文）を取得または作成
  Future<Order?> getOrCreateActiveCart(String userId) async {
    logInfo("Started retrieving or creating active cart for user");

    try {
      // 既存のアクティブカートを検索
      final Order? existingCart = await _orderRepository.findActiveDraftByUser(userId);

      if (existingCart != null) {
        logInfo("Active cart found and returned");
        return existingCart;
      }

      // 新しいカートを作成
      logDebug("Creating new cart for user");
      final Order newCart = Order(
        totalAmount: 0,
        status: OrderStatus.preparing,
        paymentMethod: PaymentMethod.cash, // デフォルト値
        discountAmount: 0,
        orderedAt: DateTime.now(),
        userId: userId,
      );

      final Order? createdCart = await _orderRepository.create(newCart);

      if (createdCart != null) {
        logInfo("New cart created successfully");
      } else {
        logError("Failed to create new cart");
      }

      return createdCart;
    } catch (e, stackTrace) {
      logError("Failed to get or create active cart", e, stackTrace);
      rethrow;
    }
  }

  /// カートに商品を追加（戻り値: (OrderItem, 在庫充足フラグ)）
  Future<(OrderItem?, bool)> addItemToCart(
    String cartId,
    CartItemRequest request,
    String userId,
  ) async {
    logInfo("Started adding item to cart: quantity=${request.quantity}");

    try {
      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        logError("Cart access denied or cart not found");
        throw Exception("Cart $cartId not found or access denied");
      }

      // メニューアイテムの取得
      final MenuItem? menuItem = await _menuItemRepository.getById(request.menuItemId);
      if (menuItem == null || menuItem.userId != userId) {
        logError("Menu item access denied or menu item not found");
        throw Exception("Menu item ${request.menuItemId} not found");
      }

      // 在庫確認
      logDebug("Checking stock availability for menu item");
      final bool isStockSufficient = await _checkMenuItemStock(
        request.menuItemId,
        request.quantity,
        userId,
      );

      if (!isStockSufficient) {
        logWarning("Stock insufficient for requested quantity");
      }

      // 既存のアイテムがあるかチェック
      final OrderItem? existingItem = await _orderItemRepository.findExistingItem(
        cartId,
        request.menuItemId,
      );

      if (existingItem != null) {
        // 既存アイテムの数量を更新
        logDebug("Updating existing cart item quantity");
        final int newQuantity = existingItem.quantity + request.quantity;
        final OrderItem? updatedItem = await _orderItemRepository
            .updateById(existingItem.id!, <String, dynamic>{
              "quantity": newQuantity,
              "subtotal": menuItem.price * newQuantity,
              "selected_options": request.selectedOptions,
              "special_request": request.specialRequest,
            });

        // カート合計を更新
        await _updateCartTotal(cartId);

        logInfo("Cart item quantity updated successfully");
        return (updatedItem, isStockSufficient);
      } else {
        // 新しいアイテムを作成
        logDebug("Creating new cart item");
        final OrderItem orderItem = OrderItem(
          orderId: cartId,
          menuItemId: request.menuItemId,
          quantity: request.quantity,
          unitPrice: menuItem.price,
          subtotal: menuItem.price * request.quantity,
          selectedOptions: request.selectedOptions,
          specialRequest: request.specialRequest,
          createdAt: DateTime.now(),
          userId: userId,
        );

        final OrderItem? createdItem = await _orderItemRepository.create(orderItem);

        // カート合計を更新
        await _updateCartTotal(cartId);

        logInfo("New cart item created successfully");
        return (createdItem, isStockSufficient);
      }
    } catch (e, stackTrace) {
      logError("Failed to add item to cart", e, stackTrace);
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
    logInfo("Started updating cart item quantity: newQuantity=$newQuantity");

    try {
      if (newQuantity <= 0) {
        logError("Invalid quantity provided: must be greater than 0");
        throw Exception("Quantity must be greater than 0");
      }

      // カートと注文アイテムの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        logError("Cart access denied or cart not found");
        throw Exception("Cart $cartId not found or access denied");
      }

      final OrderItem? orderItem = await _orderItemRepository.getById(orderItemId);
      if (orderItem == null || orderItem.orderId != cartId) {
        logError("Order item not found in cart");
        throw Exception("Order item $orderItemId not found in cart");
      }

      // メニューアイテムの取得（価格情報のため）
      final MenuItem? menuItem = await _menuItemRepository.getById(orderItem.menuItemId);
      if (menuItem == null) {
        logError("Menu item not found for order item");
        throw Exception("Menu item ${orderItem.menuItemId} not found");
      }

      // 在庫確認
      logDebug("Checking stock availability for updated quantity");
      final bool isStockSufficient = await _checkMenuItemStock(
        orderItem.menuItemId,
        newQuantity,
        userId,
      );

      if (!isStockSufficient) {
        logWarning("Stock insufficient for updated quantity");
      }

      // 数量と小計を更新
      final OrderItem? updatedItem = await _orderItemRepository.updateById(
        orderItemId,
        <String, dynamic>{"quantity": newQuantity, "subtotal": menuItem.price * newQuantity},
      );

      // カート合計を更新
      await _updateCartTotal(cartId);

      logInfo("Cart item quantity updated successfully");
      return (updatedItem, isStockSufficient);
    } catch (e, stackTrace) {
      logError("Failed to update cart item quantity", e, stackTrace);
      rethrow;
    }
  }

  /// カートから商品を削除
  Future<bool> removeItemFromCart(String cartId, String orderItemId, String userId) async {
    logInfo("Started removing item from cart");

    try {
      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        logError("Cart access denied or cart not found");
        throw Exception("Cart $cartId not found or access denied");
      }

      // 注文アイテムの存在確認
      final OrderItem? orderItem = await _orderItemRepository.getById(orderItemId);
      if (orderItem == null || orderItem.orderId != cartId) {
        logError("Order item not found in cart");
        throw Exception("Order item $orderItemId not found in cart");
      }

      // アイテムを削除
      await _orderItemRepository.deleteById(orderItemId);

      // カート合計を更新
      await _updateCartTotal(cartId);

      logInfo("Cart item removed successfully");
      return true;
    } catch (e, stackTrace) {
      logError("Failed to remove item from cart", e, stackTrace);
      return false;
    }
  }

  /// カートを空にする
  Future<bool> clearCart(String cartId, String userId) async {
    logInfo("Started clearing cart");

    try {
      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        logError("Cart access denied or cart not found");
        throw Exception("Cart $cartId not found or access denied");
      }

      // カート内の全アイテムを削除
      final bool success = await _orderItemRepository.deleteByOrderId(cartId);

      if (success) {
        // カートの合計金額をリセット
        await _orderRepository.updateById(cartId, <String, dynamic>{"total_amount": 0});
        logInfo("Cart cleared successfully");
      } else {
        logWarning("Failed to clear cart items");
      }

      return success;
    } catch (e, stackTrace) {
      logError("Failed to clear cart", e, stackTrace);
      rethrow;
    }
  }

  /// カートの金額を計算
  Future<OrderCalculationResult> calculateCartTotal(String cartId, {int discountAmount = 0}) async {
    logDebug("Calculating cart total with discount: $discountAmount");

    try {
      // カート内のアイテムを取得
      final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);

      logDebug("Retrieved ${cartItems.length} items for calculation");

      // 小計の計算
      final int subtotal = cartItems.fold(0, (int sum, OrderItem item) => sum + item.subtotal);

      // 税率（8%と仮定）
      const double taxRate = 0.08;
      final int taxAmount = (subtotal * taxRate).round();

      // 合計金額の計算
      final int totalAmount = subtotal + taxAmount - discountAmount;

      logDebug("Cart total calculated: subtotal=$subtotal, tax=$taxAmount, total=$totalAmount");

      return OrderCalculationResult(
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount > 0 ? totalAmount : 0, // マイナスにならないように
      );
    } catch (e, stackTrace) {
      logError("Failed to calculate cart total", e, stackTrace);
      rethrow;
    }
  }

  /// カート内全商品の在庫を検証（戻り値: {order_item_id: 在庫充足フラグ}）
  Future<Map<String, bool>> validateCartStock(String cartId, String userId) async {
    logInfo("Started validating cart stock");

    try {
      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        logError("Cart access denied or cart not found");
        throw Exception("Cart $cartId not found or access denied");
      }

      // カート内のアイテムを取得
      final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);

      logDebug("Validating stock for ${cartItems.length} cart items");

      final Map<String, bool> stockValidation = <String, bool>{};
      int insufficientItems = 0;

      for (final OrderItem item in cartItems) {
        final bool isSufficient = await _checkMenuItemStock(item.menuItemId, item.quantity, userId);
        stockValidation[item.id!] = isSufficient;
        if (!isSufficient) {
          insufficientItems++;
        }
      }

      if (insufficientItems > 0) {
        logWarning("Stock validation found $insufficientItems items with insufficient stock");
      } else {
        logInfo("Cart stock validation completed: all items have sufficient stock");
      }

      return stockValidation;
    } catch (e, stackTrace) {
      logError("Failed to validate cart stock", e, stackTrace);
      rethrow;
    }
  }

  /// メニューアイテムの在庫充足を確認
  Future<bool> _checkMenuItemStock(String menuItemId, int quantity, String userId) async {
    // レシピを取得
    final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId, userId);

    for (final Recipe recipe in recipes) {
      if (recipe.isOptional) {
        continue;
      }

      // 必要な材料量を計算
      final double requiredAmount = recipe.requiredAmount * quantity;

      // 材料の在庫を確認
      final Material? material = await _materialRepository.getById(recipe.materialId);
      if (material == null || material.currentStock < requiredAmount) {
        return false;
      }
    }

    return true;
  }

  /// カートの合計金額を更新
  Future<void> _updateCartTotal(String cartId) async {
    final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);
    final int totalAmount = cartItems.fold(0, (int sum, OrderItem item) => sum + item.subtotal);
    await _orderRepository.updateById(cartId, <String, dynamic>{"total_amount": totalAmount});
  }
}
