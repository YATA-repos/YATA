import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/enums.dart";
import "../../../../core/providers/common_providers.dart";
import "../../../auth/models/user_profile.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../models/order_model.dart";
import "../../services/kitchen_service.dart";
import "order_providers.dart";

part "order_status_providers.g.dart";

/// 注文ステータス変更情報
class OrderStatusChange {
  const OrderStatusChange({
    required this.orderId,
    required this.previousStatus,
    required this.newStatus,
    required this.changedAt,
    required this.changedBy,
    this.reason,
    this.estimatedTime,
  });

  final String orderId;
  final OrderStatus previousStatus;
  final OrderStatus newStatus;
  final DateTime changedAt;
  final String changedBy;
  final String? reason;
  final Duration? estimatedTime;

  /// ステータス変更が進行を表すかどうか
  bool get isProgression {
    final int prevIndex = OrderStatus.values.indexOf(previousStatus);
    final int newIndex = OrderStatus.values.indexOf(newStatus);
    return newIndex > prevIndex;
  }

  /// ステータス変更が後退を表すかどうか
  bool get isRegression => !isProgression && previousStatus != newStatus;

  /// 重要な変更かどうか（顧客に通知すべき）
  bool get isImportant =>
      newStatus == OrderStatus.ready ||
      newStatus == OrderStatus.delivered ||
      newStatus == OrderStatus.cancelled;
}

/// 注文ステータス管理プロバイダー
@riverpod
class OrderStatusManager extends _$OrderStatusManager {
  @override
  Map<String, OrderStatusChange> build() => <String, OrderStatusChange>{};

  /// 注文ステータスを更新
  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? reason,
    Duration? estimatedTime,
  }) async {
    try {
      final UserProfile? currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception("ユーザーが認証されていません");
      }

      // 現在の注文情報を取得
      final Order? currentOrder = await ref.read(
        orderDetailsProvider(orderId, currentUser.id!).future,
      );
      if (currentOrder == null) {
        throw Exception("注文が見つかりません");
      }

      // ステータス変更が有効かチェック
      if (!_isValidStatusTransition(currentOrder.status, newStatus)) {
        throw Exception("無効なステータス変更です: ${currentOrder.status.name} -> ${newStatus.name}");
      }

      // KitchenServiceを使用してステータスを更新
      final KitchenService kitchenService = KitchenService(ref: ref);
      final bool success = await _performStatusUpdate(
        kitchenService,
        orderId,
        newStatus,
        currentUser.id!,
      );

      if (success) {
        // ステータス変更を記録
        final OrderStatusChange statusChange = OrderStatusChange(
          orderId: orderId,
          previousStatus: currentOrder.status,
          newStatus: newStatus,
          changedAt: DateTime.now(),
          changedBy: currentUser.id!,
          reason: reason,
          estimatedTime: estimatedTime,
        );

        state = <String, OrderStatusChange>{...state, orderId: statusChange};

        // 重要な変更の場合は通知
        if (statusChange.isImportant) {
          _sendStatusNotification(statusChange);
        }

        // プロバイダーを無効化してリフレッシュ
        ref..invalidate(orderDetailsProvider(orderId, currentUser.id!))
        ..invalidate(activeOrdersByStatusProvider(currentUser.id!));

        return true;
      }

      return false;
    } catch (e) {
      ref.read(globalErrorProvider.notifier).setError("ステータス更新に失敗しました: ${e.toString()}");
      return false;
    }
  }

  /// ステータス更新を実行
  Future<bool> _performStatusUpdate(
    KitchenService kitchenService,
    String orderId,
    OrderStatus newStatus,
    String userId,
  ) async {
    try {
      Order? result;
      switch (newStatus) {
        case OrderStatus.confirmed:
        // 注文確認は直接サポートされていないため、調理開始と同等に扱う
        case OrderStatus.preparing:
          result = await kitchenService.startOrderPreparation(orderId, userId);
          break;
        case OrderStatus.ready:
          result = await kitchenService.markOrderReady(orderId, userId);
          break;
        case OrderStatus.delivered:
          result = await kitchenService.deliverOrder(orderId, userId);
          break;
        case OrderStatus.completed:
          // 完了は提供後の自動遷移であり、直接のメソッドはない
          // ここでは簡単に成功として扱う
          return true;
        default:
          // その他のステータスは直接サポートされていない
          return false;
      }
      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// ステータス変更が有効かチェック
  bool _isValidStatusTransition(OrderStatus from, OrderStatus to) {
    // キャンセルと返金は任意のステータスから可能
    if (to == OrderStatus.cancelled || to == OrderStatus.refunded) {
      return true;
    }

    // 通常の進行順序をチェック
    final Map<OrderStatus, List> validTransitions = <OrderStatus, List>{
      OrderStatus.pending: <OrderStatus>[OrderStatus.confirmed, OrderStatus.cancelled],
      OrderStatus.confirmed: <OrderStatus>[OrderStatus.preparing, OrderStatus.cancelled],
      OrderStatus.preparing: <OrderStatus>[OrderStatus.ready, OrderStatus.cancelled],
      OrderStatus.ready: <OrderStatus>[OrderStatus.delivered, OrderStatus.cancelled],
      OrderStatus.delivered: <OrderStatus>[OrderStatus.completed],
      OrderStatus.completed: <dynamic>[], // 完了からは変更不可
      OrderStatus.cancelled: <OrderStatus>[OrderStatus.refunded],
      OrderStatus.refunded: <dynamic>[], // 返金済みからは変更不可
    };

    return validTransitions[from]?.contains(to) ?? false;
  }

  /// ステータス通知を送信
  void _sendStatusNotification(OrderStatusChange change) {
    final String message = _getStatusChangeMessage(change);

    if (change.newStatus == OrderStatus.ready) {
      ref.read(successMessageProvider.notifier).setMessage(message);
    } else if (change.newStatus == OrderStatus.cancelled) {
      ref.read(warningMessageProvider.notifier).setMessage(message);
    } else {
      ref.read(successMessageProvider.notifier).setMessage(message);
    }
  }

  /// ステータス変更メッセージを生成
  String _getStatusChangeMessage(OrderStatusChange change) {
    switch (change.newStatus) {
      case OrderStatus.ready:
        return "注文${change.orderId.substring(0, 8)}の準備が完了しました";
      case OrderStatus.delivered:
        return "注文${change.orderId.substring(0, 8)}が提供されました";
      case OrderStatus.cancelled:
        return "注文${change.orderId.substring(0, 8)}がキャンセルされました";
      case OrderStatus.completed:
        return "注文${change.orderId.substring(0, 8)}が完了しました";
      default:
        return "注文${change.orderId.substring(0, 8)}のステータスが${change.newStatus.displayName}に更新されました";
    }
  }

  /// 特定の注文のステータス履歴を取得
  List<OrderStatusChange> getOrderStatusHistory(String orderId) =>
      state.values.where((OrderStatusChange change) => change.orderId == orderId).toList()
        ..sort((OrderStatusChange a, OrderStatusChange b) => b.changedAt.compareTo(a.changedAt));

  /// ステータス変更履歴をクリア
  void clearHistory() {
    state = <String, OrderStatusChange>{};
  }
}

/// 注文ワークフロー管理プロバイダー
@riverpod
class OrderWorkflowManager extends _$OrderWorkflowManager {
  @override
  Map<String, OrderStatus> build() => <String, OrderStatus>{};

  /// 注文を次の段階に進める
  Future<bool> progressOrder(String orderId) async {
    try {
      final UserProfile? currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        return false;
      }

      final Order? order = await ref.read(orderDetailsProvider(orderId, currentUser.id!).future);
      if (order == null) {
        return false;
      }

      final OrderStatus? nextStatus = _getNextStatus(order.status);
      if (nextStatus == null) {
        return false;
      }

      return await ref
          .read(orderStatusManagerProvider.notifier)
          .updateOrderStatus(orderId, nextStatus);
    } catch (e) {
      return false;
    }
  }

  /// 注文を前の段階に戻す
  Future<bool> regressOrder(String orderId, String reason) async {
    try {
      final UserProfile? currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        return false;
      }

      final Order? order = await ref.read(orderDetailsProvider(orderId, currentUser.id!).future);
      if (order == null) {
        return false;
      }

      final OrderStatus? previousStatus = _getPreviousStatus(order.status);
      if (previousStatus == null) {
        return false;
      }

      return await ref
          .read(orderStatusManagerProvider.notifier)
          .updateOrderStatus(orderId, previousStatus, reason: reason);
    } catch (e) {
      return false;
    }
  }

  /// 次のステータスを取得
  OrderStatus? _getNextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
        return OrderStatus.completed;
      default:
        return null;
    }
  }

  /// 前のステータスを取得
  OrderStatus? _getPreviousStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.confirmed:
        return OrderStatus.pending;
      case OrderStatus.preparing:
        return OrderStatus.confirmed;
      case OrderStatus.ready:
        return OrderStatus.preparing;
      case OrderStatus.delivered:
        return OrderStatus.ready;
      default:
        return null;
    }
  }
}

/// 注文ステータス統計プロバイダー
@riverpod
Future<OrderStatusStats> orderStatusStats(Ref ref, String userId) async {
  final Map<OrderStatus, List<Order>> ordersByStatus = await ref.watch(
    activeOrdersByStatusProvider(userId).future,
  );

  final OrderStatusStats stats = OrderStatusStats(
    pending: ordersByStatus[OrderStatus.pending]?.length ?? 0,
    confirmed: ordersByStatus[OrderStatus.confirmed]?.length ?? 0,
    preparing: ordersByStatus[OrderStatus.preparing]?.length ?? 0,
    ready: ordersByStatus[OrderStatus.ready]?.length ?? 0,
    delivered: ordersByStatus[OrderStatus.delivered]?.length ?? 0,
    completed: ordersByStatus[OrderStatus.completed]?.length ?? 0,
    canceled: ordersByStatus[OrderStatus.cancelled]?.length ?? 0,
  );

  return stats;
}

/// 注文ステータス統計データ
class OrderStatusStats {
  const OrderStatusStats({
    required this.pending,
    required this.confirmed,
    required this.preparing,
    required this.ready,
    required this.delivered,
    required this.completed,
    required this.canceled,
  });

  final int pending;
  final int confirmed;
  final int preparing;
  final int ready;
  final int delivered;
  final int completed;
  final int canceled;

  /// アクティブな注文の総数
  int get totalActive => pending + confirmed + preparing + ready;

  /// 完了した注文の総数
  int get totalCompleted => delivered + completed;

  /// 全注文数
  int get totalOrders => totalActive + totalCompleted + canceled;

  /// 進行率（0-100%）
  double get progressRate {
    if (totalOrders == 0) {
      return 0.0;
    }
    return (totalCompleted / totalOrders) * 100;
  }

  /// キャンセル率（0-100%）
  double get cancelRate {
    if (totalOrders == 0) {
      return 0.0;
    }
    return (canceled / totalOrders) * 100;
  }
}

/// 遅延注文アラートプロバイダー
@riverpod
Future<List<Order>> delayedOrders(
  Ref ref,
  String userId, {
  Duration threshold = const Duration(minutes: 30),
}) async {
  final Map<OrderStatus, List<Order>> allOrders = await ref.watch(
    activeOrdersByStatusProvider(userId).future,
  );
  final DateTime now = DateTime.now();

  final List<Order> delayedOrders = <Order>[];

  for (final List<Order> orders in allOrders.values) {
    for (final Order order in orders) {
      final Duration elapsed = now.difference(order.orderedAt);
      if (elapsed > threshold && order.status.isActive) {
        delayedOrders.add(order);
      }
    }
  }

  // 経過時間順でソート（長い順）
  delayedOrders.sort(
    (Order a, Order b) => now.difference(b.orderedAt).compareTo(now.difference(a.orderedAt)),
  );

  return delayedOrders;
}

/// ステータス別注文フィルタープロバイダー
@riverpod
class StatusFilter extends _$StatusFilter {
  @override
  Set<OrderStatus> build() =>
      OrderStatus.values.where((OrderStatus status) => status.isActive).toSet();

  /// ステータスを追加
  void addStatus(OrderStatus status) {
    state = <OrderStatus>{...state, status};
  }

  /// ステータスを削除
  void removeStatus(OrderStatus status) {
    final Set<OrderStatus> newState = Set<OrderStatus>.from(state)..remove(status);
    state = newState;
  }

  /// アクティブなステータスのみを表示
  void showActiveOnly() {
    state = OrderStatus.values.where((OrderStatus status) => status.isActive).toSet();
  }

  /// 完了したステータスのみを表示
  void showCompletedOnly() {
    state = OrderStatus.values.where((OrderStatus status) => status.isFinished).toSet();
  }

  /// 全てを表示
  void showAll() {
    state = OrderStatus.values.toSet();
  }

  /// フィルターをリセット
  void reset() {
    state = OrderStatus.values.where((OrderStatus status) => status.isActive).toSet();
  }
}

/// フィルター済み注文プロバイダー
@riverpod
Future<List<Order>> filteredOrders(Ref ref, String userId) async {
  final Set<OrderStatus> filter = ref.watch(statusFilterProvider);
  final Map<OrderStatus, List<Order>> ordersByStatus = await ref.watch(
    activeOrdersByStatusProvider(userId).future,
  );

  final List<Order> filteredOrders = <Order>[];

  for (final OrderStatus status in filter) {
    final List<Order> orders = ordersByStatus[status] ?? <Order>[];
    filteredOrders.addAll(orders);
  }

  // 注文時刻順でソート（新しい順）
  filteredOrders.sort((Order a, Order b) => b.orderedAt.compareTo(a.orderedAt));

  return filteredOrders;
}

/// リアルタイム注文ストリームプロバイダー
@riverpod
Stream<List<Order>> realTimeOrdersStream(Ref ref, String userId) async* {
  // 定期的に注文状況をチェックしてストリームで配信
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 10));

    try {
      // プロバイダーを無効化してリフレッシュ
      ref.invalidate(activeOrdersByStatusProvider(userId));

      final Map<OrderStatus, List<Order>> ordersByStatus = await ref.read(
        activeOrdersByStatusProvider(userId).future,
      );
      final List<Order> allOrders = <Order>[];

      for (final List<Order> orders in ordersByStatus.values) {
        allOrders.addAll(orders);
      }

      allOrders.sort((Order a, Order b) => b.orderedAt.compareTo(a.orderedAt));
      yield allOrders;
    } catch (e) {
      // エラーの場合は空のリストを返す
      yield <Order>[];
    }
  }
}
