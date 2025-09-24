import "../../../core/constants/enums.dart";
import "../../../core/constants/log_enums/kitchen.dart";
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
// Removed LoggerComponent mixin; use local tag
import "../../../core/logging/compat.dart" as log;
import "../models/order_model.dart";

/// キッチン調理進行管理サービス
class KitchenOperationService {
  KitchenOperationService({required OrderRepositoryContract<Order> orderRepository})
    : _orderRepository = orderRepository;

  final OrderRepositoryContract<Order> _orderRepository;

  String get loggerComponent => "KitchenOperationService";

  /// ステータス別進行中注文を取得
  Future<Map<OrderStatus, List<Order>>> getActiveOrdersByStatus(String userId) async {
    log.d("Retrieving active orders by status", tag: loggerComponent);

    try {
      final List<OrderStatus> activeStatuses = <OrderStatus>[OrderStatus.preparing];
      final List<Order> activeOrders = await _orderRepository.findByStatusList(activeStatuses);

      // ステータス別に分類
      final Map<OrderStatus, List<Order>> ordersByStatus = <OrderStatus, List<Order>>{};
      for (final Order order in activeOrders) {
        ordersByStatus[order.status] ??= <Order>[];
        ordersByStatus[order.status]!.add(order);
      }

      log.d("Retrieved ${activeOrders.length} active orders", tag: loggerComponent);
      return ordersByStatus;
    } catch (e, stackTrace) {
      log.e(
        "Failed to retrieve active orders by status",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 注文キューを取得（調理順序順）
  Future<List<Order>> getOrderQueue(String userId) async {
    log.d("Retrieving order queue", tag: loggerComponent);

    try {
      final List<Order> activeOrders = await _orderRepository.findByStatusList(<OrderStatus>[
        OrderStatus.preparing,
      ]);

      // 調理開始前の注文を優先順位順に並べる
      final List<Order> notStarted = activeOrders
          .where((Order o) => o.startedPreparingAt == null)
          .toList();
      final List<Order> inProgress = activeOrders
          .where((Order o) => o.startedPreparingAt != null && o.readyAt == null)
          .toList();

      // 注文時刻順に並べる
      notStarted.sort((Order a, Order b) => a.orderedAt.compareTo(b.orderedAt));
      inProgress.sort((Order a, Order b) {
        final DateTime aTime = a.startedPreparingAt ?? a.orderedAt;
        final DateTime bTime = b.startedPreparingAt ?? b.orderedAt;
        return aTime.compareTo(bTime);
      });

      final List<Order> queue = <Order>[...notStarted, ...inProgress];
      log.d("Order queue retrieved: ${queue.length} orders", tag: loggerComponent);
      return queue;
    } catch (e, stackTrace) {
      log.e("Failed to retrieve order queue", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 注文の調理を開始
  Future<Order?> startOrderPreparation(String orderId, String userId) async {
    log.i(KitchenInfo.preparationStarted.message, tag: loggerComponent);

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        log.e(KitchenError.orderAccessDenied.message, tag: loggerComponent);
        throw Exception("Order $orderId not found or access denied");
      }

      if (order.status != OrderStatus.preparing) {
        log.e(KitchenError.orderNotInPreparingStatus.message, tag: loggerComponent);
        throw Exception("Order is not in preparing status");
      }

      if (order.startedPreparingAt != null) {
        log.w(KitchenWarning.preparationAlreadyStarted.message, tag: loggerComponent);
        throw Exception("Order preparation already started");
      }

      // 調理開始時刻を記録
      final Order? updatedOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "started_preparing_at": DateTime.now().toIso8601String(),
      });

      if (updatedOrder != null) {
        log.i(KitchenInfo.preparationStartedSuccessfully.message, tag: loggerComponent);
      } else {
        log.w(KitchenWarning.preparationStartFailed.message, tag: loggerComponent);
      }

      return updatedOrder;
    } catch (e, stackTrace) {
      log.e(
        KitchenError.startPreparationFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 注文の調理を完了
  Future<Order?> completeOrderPreparation(String orderId, String userId) async {
    log.i(KitchenInfo.preparationCompletionStarted.message, tag: loggerComponent);

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        log.e(KitchenError.orderAccessDenied.message, tag: loggerComponent);
        throw Exception("Order $orderId not found or access denied");
      }

      if (order.startedPreparingAt == null) {
        log.e(KitchenError.preparationNotStarted.message, tag: loggerComponent);
        throw Exception("Order preparation not started");
      }

      if (order.readyAt != null) {
        log.w(KitchenWarning.orderAlreadyCompleted.message, tag: loggerComponent);
        throw Exception("Order already completed");
      }

      // 調理完了時刻を記録
      final Order? updatedOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "ready_at": DateTime.now().toIso8601String(),
      });

      if (updatedOrder != null) {
        log.i(KitchenInfo.preparationCompletedSuccessfully.message, tag: loggerComponent);
      } else {
        log.w(KitchenWarning.preparationCompletionFailed.message, tag: loggerComponent);
      }

      return updatedOrder;
    } catch (e, stackTrace) {
      log.e(
        KitchenError.completePreparationFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 注文を提供準備完了にマーク
  Future<Order?> markOrderReady(String orderId, String userId) async =>
      // completeOrderPreparationと同じ処理
      completeOrderPreparation(orderId, userId);

  /// 注文を提供完了
  Future<Order?> deliverOrder(String orderId, String userId) async {
    log.i(KitchenInfo.deliveryStarted.message, tag: loggerComponent);

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        log.e(KitchenError.orderAccessDenied.message, tag: loggerComponent);
        throw Exception("Order $orderId not found or access denied");
      }

      if (order.readyAt == null) {
        log.e(KitchenError.orderNotReadyForDelivery.message, tag: loggerComponent);
        throw Exception("Order not ready for delivery");
      }

      if (order.status == OrderStatus.completed) {
        log.w(KitchenWarning.orderAlreadyDelivered.message, tag: loggerComponent);
        throw Exception("Order already delivered");
      }

      // 提供完了
      final Order? updatedOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "status": OrderStatus.completed.value,
        "completed_at": DateTime.now().toIso8601String(),
      });

      if (updatedOrder != null) {
        log.i(KitchenInfo.deliverySuccessful.message, tag: loggerComponent);
      } else {
        log.w(KitchenWarning.deliveryFailed.message, tag: loggerComponent);
      }

      return updatedOrder;
    } catch (e, stackTrace) {
      log.e(
        KitchenError.deliverOrderFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 完成予定時刻を調整
  Future<Order?> adjustEstimatedCompletionTime(
    String orderId,
    int additionalMinutes,
    String userId,
  ) async {
    log.d("Adjusting estimated completion time", tag: loggerComponent);

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        throw Exception("Order $orderId not found or access denied");
      }

      // ノート欄に調整理由を記録
      final String adjustmentNote = "Est. time adjusted by $additionalMinutes minutes";
      final String currentNotes = order.notes ?? "";
      final String newNotes = "$currentNotes [$adjustmentNote]".trim();

      final Order? updatedOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "notes": newNotes,
      });

      log.i("Estimated completion time adjusted successfully", tag: loggerComponent);
      return updatedOrder;
    } catch (e, stackTrace) {
      log.e(
        "Failed to adjust estimated completion time",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// キッチン状況を更新
  Future<bool> updateKitchenStatus(int activeStaffCount, String? notes, String userId) async {
    log.d("Updating kitchen status: $activeStaffCount staff", tag: loggerComponent);

    // キッチン状況は別のモデルで管理されることを想定
    // ここでは簡単にログして成功を返す（実装は要件に応じて）
    log.i(
      "Kitchen status updated for user $userId: $activeStaffCount staff, notes: $notes",
      tag: loggerComponent,
    );
    return true;
  }

  /// 実際の調理時間を取得（分）
  double? getActualPrepTimeMinutes(Order order) {
    final DateTime? startedAt = order.startedPreparingAt;
    final DateTime? readyAt = order.readyAt;
    if (startedAt != null && readyAt != null) {
      final Duration delta = readyAt.difference(startedAt);
      final double minutes = delta.inSeconds / 60.0;
      log.d(
        "Actual prep time calculated: ${minutes.toStringAsFixed(1)} minutes",
        tag: loggerComponent,
      );
      return minutes;
    }
    return null;
  }
}
