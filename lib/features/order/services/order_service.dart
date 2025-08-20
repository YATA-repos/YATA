import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/logging/logger_mixin.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "order_management_service.dart";

/// 注文サービス統合クラス
/// OrderManagementServiceを使用
class OrderService with LoggerMixin {
  OrderService({
    required Ref ref,
    OrderManagementService? orderManagementService,
  }) : _orderManagementService = orderManagementService ?? OrderManagementService(ref: ref);

  final OrderManagementService _orderManagementService;

  @override
  String get loggerComponent => "OrderService";

  // ===== 注文管理関連メソッド =====

  /// カートを確定して正式注文に変換（戻り値: (Order, 成功フラグ)）
  Future<(Order?, bool)> checkoutCart(
    String cartId,
    OrderCheckoutRequest request,
    String userId,
  ) async => _orderManagementService.checkoutCart(cartId, request, userId);

  /// 注文をキャンセル（在庫復元含む）
  Future<(Order?, bool)> cancelOrder(String orderId, String reason, String userId) async =>
      _orderManagementService.cancelOrder(orderId, reason, userId);

  /// 注文履歴を取得（ページネーション付き）
  Future<Map<String, dynamic>> getOrderHistory(OrderSearchRequest request, String userId) async =>
      _orderManagementService.getOrderHistory(request, userId);

  /// 注文詳細を取得
  Future<Order?> getOrderDetails(String orderId, String userId) async =>
      _orderManagementService.getOrderDetails(orderId, userId);

  /// 注文と注文明細を一括取得
  Future<Map<String, dynamic>?> getOrderWithItems(String orderId, String userId) async =>
      _orderManagementService.getOrderWithItems(orderId, userId);

/// OrderService のプロバイダー定義
final Provider<OrderService> orderServiceProvider =
    Provider<OrderService>((Ref ref) => OrderService(ref: ref));
}
