import "../../../core/constants/enums.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "cart_management_service.dart";
import "models/cart_snapshot.dart";
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

  /// アクティブなカートを取得し、存在しなければ新規作成して返す。
  Future<Order?> getOrCreateActiveCart(String userId) async =>
      _cartManagementService.getOrCreateActiveCart(userId);

  /// 既存のアクティブカートを取得（存在しなければ `null`）。
  Future<Order?> getActiveCart(String userId) async => _cartManagementService.getActiveCart(userId);

  /// カートに商品を追加し、最新スナップショットを返却する。
  Future<CartMutationResult> addItemToCart(
    String cartId,
    CartItemRequest request,
    String userId,
  ) async => _cartManagementService.addItemToCart(cartId, request, userId);

  /// カート内商品の数量を更新
  Future<CartMutationResult> updateCartItemQuantity(
    String cartId,
    String orderItemId,
    int newQuantity,
    String userId,
  ) async =>
      _cartManagementService.updateCartItemQuantity(cartId, orderItemId, newQuantity, userId);

  /// カートから商品を削除
  Future<CartMutationResult> removeItemFromCart(
    String cartId,
    String orderItemId,
    String userId,
  ) async => _cartManagementService.removeItemFromCart(cartId, orderItemId, userId);

  /// カートを空にする
  Future<CartMutationResult> clearCart(String cartId, String userId) async =>
      _cartManagementService.clearCart(cartId, userId);

  /// 支払い方法を更新
  Future<Order?> updateCartPaymentMethod(
    String cartId,
    PaymentMethod method,
    String userId,
  ) async => _cartManagementService.updateCartPaymentMethod(cartId, method, userId);

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
