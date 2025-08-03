import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/enums.dart";
import "../../../../core/utils/provider_logger.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "../../services/kitchen_service.dart";
import "../../services/order_service.dart";

part "order_providers.g.dart";

/// OrderService プロバイダー
/// 既存の注文管理サービスをRiverpodで利用可能にする
@riverpod
OrderService orderService(Ref ref) {
  ProviderLogger.info("OrderProviders", "OrderServiceを初期化しました");
  return OrderService(ref: ref);
}

/// KitchenService プロバイダー
/// 既存のキッチン操作・分析サービスをRiverpodで利用可能にする
@riverpod
KitchenService kitchenService(Ref ref) {
  ProviderLogger.info("OrderProviders", "KitchenServiceを初期化しました");
  return KitchenService(ref: ref);
}

/// 注文履歴プロバイダー
/// 既存のOrderService.getOrderHistoryを直接活用
@riverpod
Future<Map<String, dynamic>> orderHistory(
  Ref ref,
  OrderSearchRequest request,
  String userId,
) async {
  try {
    ProviderLogger.debug("OrderProviders", "注文履歴取得を開始");
    final OrderService service = ref.watch(orderServiceProvider);
    final Map<String, dynamic> result = await service.getOrderHistory(request, userId);
    ProviderLogger.info("OrderProviders", "注文履歴取得が完了");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("OrderProviders", "orderHistory", e, stackTrace);
    rethrow;
  }
}

/// 注文詳細プロバイダー
/// 既存のOrderService.getOrderDetailsを直接活用
@riverpod
Future<Order?> orderDetails(Ref ref, String orderId, String userId) async {
  try {
    ProviderLogger.debug("OrderProviders", "注文詳細取得を開始: $orderId");
    final OrderService service = ref.watch(orderServiceProvider);
    final Order? result = await service.getOrderDetails(orderId, userId);
    ProviderLogger.info("OrderProviders", "注文詳細取得が完了: $orderId");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("OrderProviders", "orderDetails", e, stackTrace);
    rethrow;
  }
}

/// 注文と注文明細一括取得プロバイダー
/// 既存のOrderService.getOrderWithItemsを直接活用
@riverpod
Future<Map<String, dynamic>?> orderWithItems(Ref ref, String orderId, String userId) async {
  try {
    ProviderLogger.debug("OrderProviders", "注文と明細の一括取得を開始: $orderId");
    final OrderService service = ref.watch(orderServiceProvider);
    final Map<String, dynamic>? result = await service.getOrderWithItems(orderId, userId);
    ProviderLogger.info("OrderProviders", "注文と明細の一括取得が完了: $orderId");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("OrderProviders", "orderWithItems", e, stackTrace);
    rethrow;
  }
}

/// ステータス別進行中注文プロバイダー
/// 既存のKitchenService.getActiveOrdersByStatusを直接活用
@riverpod
Future<Map<OrderStatus, List<Order>>> activeOrdersByStatus(Ref ref, String userId) async {
  try {
    ProviderLogger.debug("OrderProviders", "ステータス別進行中注文取得を開始");
    final KitchenService service = ref.watch(kitchenServiceProvider);
    final Map<OrderStatus, List<Order>> result = await service.getActiveOrdersByStatus(userId);
    ProviderLogger.info("OrderProviders", "ステータス別進行中注文取得が完了");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("OrderProviders", "activeOrdersByStatus", e, stackTrace);
    rethrow;
  }
}

/// 注文キュープロバイダー
/// 既存のKitchenService.getOrderQueueを直接活用
@riverpod
Future<List<Order>> orderQueue(Ref ref, String userId) async {
  try {
    ProviderLogger.debug("OrderProviders", "注文キュー取得を開始");
    final KitchenService service = ref.watch(kitchenServiceProvider);
    final List<Order> result = await service.getOrderQueue(userId);
    ProviderLogger.info("OrderProviders", "注文キュー取得が完了: ${result.length}件");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("OrderProviders", "orderQueue", e, stackTrace);
    rethrow;
  }
}

/// キッチン負荷状況プロバイダー
/// 既存のKitchenService.getKitchenWorkloadを直接活用
@riverpod
Future<Map<String, dynamic>> kitchenWorkload(Ref ref, String userId) async {
  try {
    ProviderLogger.debug("OrderProviders", "キッチン負荷状況取得を開始");
    final KitchenService service = ref.watch(kitchenServiceProvider);
    final Map<String, dynamic> result = await service.getKitchenWorkload(userId);
    ProviderLogger.info("OrderProviders", "キッチン負荷状況取得が完了");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("OrderProviders", "kitchenWorkload", e, stackTrace);
    rethrow;
  }
}

/// 待ち時間計算プロバイダー
/// 既存のKitchenService.calculateQueueWaitTimeを直接活用
@riverpod
Future<int> queueWaitTime(Ref ref, String userId) async {
  try {
    ProviderLogger.debug("OrderProviders", "待ち時間計算を開始");
    final KitchenService service = ref.watch(kitchenServiceProvider);
    final int result = await service.calculateQueueWaitTime(userId);
    ProviderLogger.info("OrderProviders", "待ち時間計算が完了: $result分");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("OrderProviders", "queueWaitTime", e, stackTrace);
    rethrow;
  }
}

/// 完成予定時刻計算プロバイダー
/// 既存のKitchenService.calculateEstimatedCompletionTimeを直接活用
@riverpod
Future<DateTime?> estimatedCompletionTime(Ref ref, String orderId, String userId) async {
  try {
    ProviderLogger.debug("OrderProviders", "完成予定時刻計算を開始: $orderId");
    final KitchenService service = ref.watch(kitchenServiceProvider);
    final DateTime? result = await service.calculateEstimatedCompletionTime(orderId, userId);
    ProviderLogger.info("OrderProviders", "完成予定時刻計算が完了: $orderId");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("OrderProviders", "estimatedCompletionTime", e, stackTrace);
    rethrow;
  }
}

/// 調理順序最適化プロバイダー
/// 既存のKitchenService.optimizeCookingOrderを直接活用
@riverpod
Future<List<String>> optimizedCookingOrder(Ref ref, String userId) async {
  try {
    ProviderLogger.debug("OrderProviders", "調理順序最適化を開始");
    final KitchenService service = ref.watch(kitchenServiceProvider);
    final List<String> result = await service.optimizeCookingOrder(userId);
    ProviderLogger.info("OrderProviders", "調理順序最適化が完了: ${result.length}件");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("OrderProviders", "optimizedCookingOrder", e, stackTrace);
    rethrow;
  }
}

/// UI状態管理：選択中注文ステータスフィルター
@riverpod
class SelectedOrderStatus extends _$SelectedOrderStatus with ProviderLoggerMixin {
  @override
  String get providerComponent => "SelectedOrderStatus";
  
  @override
  OrderStatus? build() {
    logInfo("選択中注文ステータスフィルターを初期化しました");
    return null; // デフォルトは全ステータス
  }

  /// ステータスを選択
  void selectStatus(OrderStatus status) {
    logDebug("ステータスを選択: $status");
    state = status;
  }

  /// 全ステータスに戻す
  void clearFilter() {
    logDebug("ステータスフィルターをクリア");
    state = null;
  }
}

/// UI状態管理：注文検索期間
class OrderDateRange {
  const OrderDateRange({this.startDate, this.endDate});

  final DateTime? startDate;
  final DateTime? endDate;

  OrderDateRange copyWith({DateTime? startDate, DateTime? endDate}) =>
      OrderDateRange(startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate);
}

@riverpod
class OrderDateRangeNotifier extends _$OrderDateRangeNotifier with ProviderLoggerMixin {
  @override
  String get providerComponent => "OrderDateRangeNotifier";
  
  @override
  OrderDateRange build() {
    logInfo("注文検索期間Notifierを初期化しました");
    return const OrderDateRange();
  }

  /// 日付範囲を設定
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    logDebug("日付範囲を設定: $startDate ～ $endDate");
    state = OrderDateRange(startDate: startDate, endDate: endDate);
  }

  /// 今日の範囲に設定
  void setToday() {
    logDebug("今日の範囲に設定");
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = today
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));
    state = OrderDateRange(startDate: today, endDate: endOfDay);
  }

  /// 今週の範囲に設定
  void setThisWeek() {
    logDebug("今週の範囲に設定");
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
    state = OrderDateRange(startDate: startOfWeek, endDate: endOfWeek);
  }

  /// 範囲をクリア
  void clearRange() {
    logDebug("日付範囲をクリア");
    state = const OrderDateRange();
  }
}
