import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/enums.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "../../services/kitchen_service.dart";
import "../../services/order_service.dart";

part "order_providers.g.dart";

/// OrderService プロバイダー
/// 既存の注文管理サービスをRiverpodで利用可能にする
@riverpod
OrderService orderService(Ref ref) => OrderService();

/// KitchenService プロバイダー
/// 既存のキッチン操作・分析サービスをRiverpodで利用可能にする
@riverpod
KitchenService kitchenService(Ref ref) => KitchenService();

/// 注文履歴プロバイダー
/// 既存のOrderService.getOrderHistoryを直接活用
@riverpod
Future<Map<String, dynamic>> orderHistory(
  Ref ref,
  OrderSearchRequest request,
  String userId,
) async {
  final OrderService service = ref.watch(orderServiceProvider);
  return service.getOrderHistory(request, userId);
}

/// 注文詳細プロバイダー
/// 既存のOrderService.getOrderDetailsを直接活用
@riverpod
Future<Order?> orderDetails(Ref ref, String orderId, String userId) async {
  final OrderService service = ref.watch(orderServiceProvider);
  return service.getOrderDetails(orderId, userId);
}

/// 注文と注文明細一括取得プロバイダー
/// 既存のOrderService.getOrderWithItemsを直接活用
@riverpod
Future<Map<String, dynamic>?> orderWithItems(Ref ref, String orderId, String userId) async {
  final OrderService service = ref.watch(orderServiceProvider);
  return service.getOrderWithItems(orderId, userId);
}

/// ステータス別進行中注文プロバイダー
/// 既存のKitchenService.getActiveOrdersByStatusを直接活用
@riverpod
Future<Map<OrderStatus, List<Order>>> activeOrdersByStatus(Ref ref, String userId) async {
  final KitchenService service = ref.watch(kitchenServiceProvider);
  return service.getActiveOrdersByStatus(userId);
}

/// 注文キュープロバイダー
/// 既存のKitchenService.getOrderQueueを直接活用
@riverpod
Future<List<Order>> orderQueue(Ref ref, String userId) async {
  final KitchenService service = ref.watch(kitchenServiceProvider);
  return service.getOrderQueue(userId);
}

/// キッチン負荷状況プロバイダー
/// 既存のKitchenService.getKitchenWorkloadを直接活用
@riverpod
Future<Map<String, dynamic>> kitchenWorkload(Ref ref, String userId) async {
  final KitchenService service = ref.watch(kitchenServiceProvider);
  return service.getKitchenWorkload(userId);
}

/// 待ち時間計算プロバイダー
/// 既存のKitchenService.calculateQueueWaitTimeを直接活用
@riverpod
Future<int> queueWaitTime(Ref ref, String userId) async {
  final KitchenService service = ref.watch(kitchenServiceProvider);
  return service.calculateQueueWaitTime(userId);
}

/// 完成予定時刻計算プロバイダー
/// 既存のKitchenService.calculateEstimatedCompletionTimeを直接活用
@riverpod
Future<DateTime?> estimatedCompletionTime(Ref ref, String orderId, String userId) async {
  final KitchenService service = ref.watch(kitchenServiceProvider);
  return service.calculateEstimatedCompletionTime(orderId, userId);
}

/// 調理順序最適化プロバイダー
/// 既存のKitchenService.optimizeCookingOrderを直接活用
@riverpod
Future<List<String>> optimizedCookingOrder(Ref ref, String userId) async {
  final KitchenService service = ref.watch(kitchenServiceProvider);
  return service.optimizeCookingOrder(userId);
}

/// UI状態管理：選択中注文ステータスフィルター
@riverpod
class SelectedOrderStatus extends _$SelectedOrderStatus {
  @override
  OrderStatus? build() => null; // デフォルトは全ステータス

  /// ステータスを選択
  void selectStatus(OrderStatus status) {
    state = status;
  }

  /// 全ステータスに戻す
  void clearFilter() {
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
class OrderDateRangeNotifier extends _$OrderDateRangeNotifier {
  @override
  OrderDateRange build() => const OrderDateRange();

  /// 日付範囲を設定
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = OrderDateRange(startDate: startDate, endDate: endDate);
  }

  /// 今日の範囲に設定
  void setToday() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = today
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));
    state = OrderDateRange(startDate: today, endDate: endOfDay);
  }

  /// 今週の範囲に設定
  void setThisWeek() {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
    state = OrderDateRange(startDate: startOfWeek, endDate: endOfWeek);
  }

  /// 範囲をクリア
  void clearRange() {
    state = const OrderDateRange();
  }
}
