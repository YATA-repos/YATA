import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "cart_management_service.dart";
import "order_calculation_service.dart";

/// カートサービス統合クラス
/// CartManagementServiceとOrderCalculationServiceを組み合わせて使用
class CartService {
  CartService({
    required CartManagementService cartManagementService,
    required OrderCalculationService orderCalculationService,
  }) : _cartManagementService = cartManagementService,
       _orderCalculationService = orderCalculationService;

  final CartManagementService _cartManagementService;
  final OrderCalculationService _orderCalculationService;

  String get loggerComponent => "CartService";

  // ===== カート管理関連メソッド =====

  /// アクティブなカート（下書き注文）を取得または作成
  Future<Order?> getOrCreateActiveCart(String userId) async =>
      _cartManagementService.getOrCreateActiveCart(userId);

  /// カートに商品を追加（戻り値: (OrderItem, 在庫充足フラグ)）
  Future<(OrderItem?, bool)> addItemToCart(
    String cartId,
    CartItemRequest request,
    String userId,
  ) async => _cartManagementService.addItemToCart(cartId, request, userId);

  /// カート内商品の数量を更新
  Future<(OrderItem?, bool)> updateCartItemQuantity(
    String cartId,
    String orderItemId,
    int newQuantity,
    String userId,
  ) async =>
      _cartManagementService.updateCartItemQuantity(cartId, orderItemId, newQuantity, userId);

  /// カートから商品を削除
  Future<bool> removeItemFromCart(String cartId, String orderItemId, String userId) async =>
      _cartManagementService.removeItemFromCart(cartId, orderItemId, userId);

  /// カートを空にする
  Future<bool> clearCart(String cartId, String userId) async =>
      _cartManagementService.clearCart(cartId, userId);

  /// カート内全商品の在庫を検証（戻り値: {order_item_id: 在庫充足フラグ}）
  Future<Map<String, bool>> validateCartStock(String cartId, String userId) async =>
      _cartManagementService.validateCartStock(cartId, userId);

  // ===== カート金額計算関連メソッド =====

  /// カートの金額を計算
  Future<OrderCalculationResult> calculateCartTotal(
    String cartId, {
    int discountAmount = 0,
  }) async => _orderCalculationService.calculateCartTotal(cartId, discountAmount: discountAmount);
}
