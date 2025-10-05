import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/constants/enums.dart";
import "../../../core/contracts/realtime/realtime_manager.dart" as r_contract;
import "../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../core/realtime/realtime_service_mixin.dart";
import "../../auth/presentation/providers/auth_providers.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "order_management_service.dart";

/// 注文サービス統合クラス
/// OrderManagementServiceを使用
class OrderService with RealtimeServiceContractMixin implements RealtimeServiceControl {
  OrderService({
    required log_contract.LoggerContract logger,
    required Ref ref,
    required r_contract.RealtimeManagerContract realtimeManager,
    required OrderManagementService orderManagementService,
  }) : _logger = logger,
    _ref = ref,
       _realtimeManager = realtimeManager,
       _orderManagementService = orderManagementService;

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final Ref _ref;
  final OrderManagementService _orderManagementService;
  final r_contract.RealtimeManagerContract _realtimeManager;

  String get loggerComponent => "OrderService";

  // 契約Mixin用の依存提供
  @override
  r_contract.RealtimeManagerContract get realtimeManager => _realtimeManager;

  // 現在のユーザーID（Providerから取得）
  @override
  String? get currentUserId => _ref.read(currentUserIdProvider);

  // ===== Realtime: 注文と注文明細の監視 =====
  @override
  Future<void> enableRealtimeFeatures() async => startRealtimeMonitoring();

  @override
  Future<void> disableRealtimeFeatures() async => stopRealtimeMonitoring();

  @override
  bool isFeatureRealtimeEnabled(String featureName) => isMonitoringFeature(featureName);

  @override
  bool isRealtimeConnected() => isRealtimeHealthy();

  @override
  Map<String, dynamic> getRealtimeInfo() => getRealtimeStats();

  Future<void> startRealtimeMonitoring() async {
    try {
      log.i("Starting order realtime monitoring", tag: loggerComponent);
      await startFeatureMonitoring(
        "orders",
        "orders",
        _handleOrderUpdate,
        eventTypes: const <String>["INSERT", "UPDATE", "DELETE"],
      );
      await startFeatureMonitoring(
        "orders",
        "order_items",
        _handleOrderItemUpdate,
        eventTypes: const <String>["INSERT", "UPDATE", "DELETE"],
      );
      log.i("Order realtime monitoring started", tag: loggerComponent);
    } catch (e) {
      log.e("Failed to start order realtime monitoring", tag: loggerComponent, error: e);
      rethrow;
    }
  }

  Future<void> stopRealtimeMonitoring() async {
    try {
      log.i("Stopping order realtime monitoring", tag: loggerComponent);
      await stopFeatureMonitoring("orders");
      log.i("Order realtime monitoring stopped", tag: loggerComponent);
    } catch (e) {
      log.e("Failed to stop order realtime monitoring", tag: loggerComponent, error: e);
      rethrow;
    }
  }

  void _handleOrderUpdate(Map<String, dynamic> data) {
    final String eventType = data["event_type"] as String? ?? "unknown";
    final Map<String, dynamic>? newRecord = data["new_record"] as Map<String, dynamic>?;
    final Map<String, dynamic>? oldRecord = data["old_record"] as Map<String, dynamic>?;
    final bool isCartEvent =
        ((newRecord?["is_cart"] as bool?) ?? false) || ((oldRecord?["is_cart"] as bool?) ?? false);
    if (isCartEvent) {
      log.d(
        "Ignoring cart order event",
        tag: loggerComponent,
        fields: <String, dynamic>{"eventType": eventType},
      );
      return;
    }
    log.d(
      "Order event: $eventType",
      tag: loggerComponent,
      fields: <String, dynamic>{"order": newRecord ?? oldRecord},
    );
  }

  void _handleOrderItemUpdate(Map<String, dynamic> data) {
    final String eventType = data["event_type"] as String? ?? "unknown";
    final Map<String, dynamic>? newRecord = data["new_record"] as Map<String, dynamic>?;
    final Map<String, dynamic>? oldRecord = data["old_record"] as Map<String, dynamic>?;
    log.d(
      "OrderItem event: $eventType",
      tag: loggerComponent,
      fields: <String, dynamic>{"item": newRecord ?? oldRecord},
    );
  }

  // ===== 注文管理関連メソッド =====

  /// カートを確定して正式注文に変換する。
  Future<OrderCheckoutResult> checkoutCart(
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

  /// ステータスに応じた注文一覧を取得
  Future<Map<OrderStatus, List<Order>>> getOrdersByStatuses(
    List<OrderStatus> statuses,
    String userId, {
    int limit = 50,
  }) async => _orderManagementService.getOrdersByStatuses(statuses, userId, limit: limit);

  /// 注文ステータスを更新
  Future<Order?> updateOrderStatus(String orderId, OrderStatus newStatus, String userId) async =>
      _orderManagementService.updateOrderStatus(orderId, newStatus, userId);
}
