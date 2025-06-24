import "../../../core/constants/enums.dart";
import "../../../core/utils/logger_mixin.dart";
import "../../inventory/repositories/material_repository.dart";
import "../../inventory/repositories/recipe_repository.dart";
import "../../menu/repositories/menu_item_repository.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "../repositories/order_item_repository.dart";
import "../repositories/order_repository.dart";

/// カート（下書き注文）管理サービス
@loggerComponent
class CartService with LoggerMixin {
  /// コンストラクタ
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
  final OrderItemRepository _orderItemRepository;
  final MenuItemRepository _menuItemRepository;
  final MaterialRepository _materialRepository;
  final RecipeRepository _recipeRepository;

  /// ログコンポーネント名
  @override
  String get loggerComponent => "CartService";

  /// アクティブなカート（下書き注文）を取得または作成
  Future<Order?> getOrCreateActiveCart(String userId) async {
    // 既存のアクティブカートを検索
    final Order? existingCart = await _orderRepository.findActiveDraftByUser(
      userId,
    );

    if (existingCart != null) {
      return existingCart;
    }

    // 新しいカートを作成
    final Order newCart = Order(
      totalAmount: 0,
      status: OrderStatus.preparing,
      paymentMethod: PaymentMethod.cash, // デフォルト値
      discountAmount: 0,
      orderedAt: DateTime.now(),
      userId: userId,
    );

    final Order? createdCart = await _orderRepository.create(newCart);
    return createdCart;
  }

  /// カートに商品を追加（戻り値: (OrderItem, 在庫充足フラグ)）
  Future<(OrderItem?, bool)> addItemToCart(
    String cartId,
    CartItemRequest request,
    String userId,
  ) async {
    // カートの存在確認
    final Order? cart = await _orderRepository.getById(cartId);
    if (cart == null || cart.userId != userId) {
      throw Exception("Cart $cartId not found or access denied");
    }

    // メニューアイテムの取得
    final dynamic menuItem = await _menuItemRepository.getById(
      request.menuItemId,
    );
    if (menuItem == null || menuItem.userId != userId) {
      throw Exception("Menu item ${request.menuItemId} not found");
    }

    // 在庫確認
    final bool isStockSufficient = await _checkMenuItemStock(
      request.menuItemId,
      request.quantity,
      userId,
    );

    // 既存のアイテムがあるかチェック
    final OrderItem? existingItem = await _orderItemRepository.findExistingItem(
      cartId,
      request.menuItemId,
    );

    if (existingItem != null) {
      // 既存アイテムの数量を更新
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

      return (updatedItem, isStockSufficient);
    } else {
      // 新しいアイテムを作成
      final OrderItem orderItem = OrderItem(
        orderId: cartId,
        menuItemId: request.menuItemId,
        quantity: request.quantity,
        unitPrice: menuItem.price as int,
        subtotal: (menuItem.price as int) * request.quantity,
        selectedOptions: request.selectedOptions,
        specialRequest: request.specialRequest,
        createdAt: DateTime.now(),
        userId: userId,
      );

      final OrderItem? createdItem = await _orderItemRepository.create(
        orderItem,
      );

      // カート合計を更新
      await _updateCartTotal(cartId);

      return (createdItem, isStockSufficient);
    }
  }

  /// カート内商品の数量を更新
  Future<(OrderItem?, bool)> updateCartItemQuantity(
    String cartId,
    String orderItemId,
    int newQuantity,
    String userId,
  ) async {
    if (newQuantity <= 0) {
      throw Exception("Quantity must be greater than 0");
    }

    // カートと注文アイテムの存在確認
    final Order? cart = await _orderRepository.getById(cartId);
    if (cart == null || cart.userId != userId) {
      throw Exception("Cart $cartId not found or access denied");
    }

    final OrderItem? orderItem = await _orderItemRepository.getById(
      orderItemId,
    );
    if (orderItem == null || orderItem.orderId != cartId) {
      throw Exception("Order item $orderItemId not found in cart");
    }

    // メニューアイテムの取得（価格情報のため）
    final dynamic menuItem = await _menuItemRepository.getById(
      orderItem.menuItemId,
    );
    if (menuItem == null) {
      throw Exception("Menu item ${orderItem.menuItemId} not found");
    }

    // 在庫確認
    final bool isStockSufficient = await _checkMenuItemStock(
      orderItem.menuItemId,
      newQuantity,
      userId,
    );

    // 数量と小計を更新
    final OrderItem? updatedItem = await _orderItemRepository.updateById(
      orderItemId,
      <String, dynamic>{
        "quantity": newQuantity,
        "subtotal": (menuItem.price as int) * newQuantity,
      },
    );

    // カート合計を更新
    await _updateCartTotal(cartId);

    return (updatedItem, isStockSufficient);
  }

  /// カートから商品を削除
  Future<bool> removeItemFromCart(
    String cartId,
    String orderItemId,
    String userId,
  ) async {
    // カートの存在確認
    final Order? cart = await _orderRepository.getById(cartId);
    if (cart == null || cart.userId != userId) {
      throw Exception("Cart $cartId not found or access denied");
    }

    // 注文アイテムの存在確認
    final OrderItem? orderItem = await _orderItemRepository.getById(
      orderItemId,
    );
    if (orderItem == null || orderItem.orderId != cartId) {
      throw Exception("Order item $orderItemId not found in cart");
    }

    // アイテムを削除
    try {
      await _orderItemRepository.deleteById(orderItemId);

      // カート合計を更新
      await _updateCartTotal(cartId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// カートを空にする
  Future<bool> clearCart(String cartId, String userId) async {
    // カートの存在確認
    final Order? cart = await _orderRepository.getById(cartId);
    if (cart == null || cart.userId != userId) {
      throw Exception("Cart $cartId not found or access denied");
    }

    // カート内の全アイテムを削除
    final bool success = await _orderItemRepository.deleteByOrderId(cartId);

    if (success) {
      // カートの合計金額をリセット
      await _orderRepository.updateById(cartId, <String, dynamic>{
        "total_amount": 0,
      });
    }

    return success;
  }

  /// カートの金額を計算
  Future<OrderCalculationResult> calculateCartTotal(
    String cartId, {
    int discountAmount = 0,
  }) async {
    // カート内のアイテムを取得
    final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(
      cartId,
    );

    // 小計の計算
    final int subtotal = cartItems.fold(
      0,
      (int sum, OrderItem item) => sum + item.subtotal,
    );

    // 税率（8%と仮定）
    const double taxRate = 0.08;
    final int taxAmount = (subtotal * taxRate).round();

    // 合計金額の計算
    final int totalAmount = subtotal + taxAmount - discountAmount;

    return OrderCalculationResult(
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount > 0 ? totalAmount : 0, // マイナスにならないように
    );
  }

  /// カート内全商品の在庫を検証（戻り値: {order_item_id: 在庫充足フラグ}）
  Future<Map<String, bool>> validateCartStock(
    String cartId,
    String userId,
  ) async {
    // カートの存在確認
    final Order? cart = await _orderRepository.getById(cartId);
    if (cart == null || cart.userId != userId) {
      throw Exception("Cart $cartId not found or access denied");
    }

    // カート内のアイテムを取得
    final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(
      cartId,
    );

    final Map<String, bool> stockValidation = <String, bool>{};

    for (final OrderItem item in cartItems) {
      final bool isSufficient = await _checkMenuItemStock(
        item.menuItemId,
        item.quantity,
        userId,
      );
      stockValidation[item.id!] = isSufficient;
    }

    return stockValidation;
  }

  /// メニューアイテムの在庫充足を確認
  Future<bool> _checkMenuItemStock(
    String menuItemId,
    int quantity,
    String userId,
  ) async {
    // レシピを取得
    final List<dynamic> recipes = await _recipeRepository.findByMenuItemId(
      menuItemId,
      userId,
    );

    for (final dynamic recipe in recipes) {
      if (recipe.isOptional as bool) {
        continue;
      }

      // 必要な材料量を計算
      final double requiredAmount =
          (recipe.requiredAmount as double) * quantity;

      // 材料の在庫を確認
      final dynamic material = await _materialRepository.getById(
        recipe.materialId as String,
      );
      if (material == null ||
          (material.currentStock as double) < requiredAmount) {
        return false;
      }
    }

    return true;
  }

  /// カートの合計金額を更新
  Future<void> _updateCartTotal(String cartId) async {
    final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(
      cartId,
    );
    final int totalAmount = cartItems.fold(
      0,
      (int sum, OrderItem item) => sum + item.subtotal,
    );
    await _orderRepository.updateById(cartId, <String, dynamic>{
      "total_amount": totalAmount,
    });
  }
}
