import "../../../core/constants/enums.dart";
import "../../../core/constants/log_enums/kitchen.dart";
import "../../../core/utils/logger_mixin.dart";
import "../models/order_model.dart";
import "../repositories/order_repository.dart";

/// キッチン調理進行管理サービス
class KitchenOperationService with LoggerMixin {
  KitchenOperationService({OrderRepository? orderRepository})
    : _orderRepository = orderRepository ?? OrderRepository();

  final OrderRepository _orderRepository;

  @override
  String get loggerComponent => "KitchenOperationService";

  /// ステータス別進行中注文を取得
  Future<Map<OrderStatus, List<Order>>> getActiveOrdersByStatus(String userId) async {
    logDebug("Retrieving active orders by status");

    try {
      final List<OrderStatus> activeStatuses = <OrderStatus>[OrderStatus.preparing];
      final List<Order> activeOrders = await _orderRepository.findByStatusList(
        activeStatuses,
        userId,
      );

      // ステータス別に分類
      final Map<OrderStatus, List<Order>> ordersByStatus = <OrderStatus, List<Order>>{};
      for (final Order order in activeOrders) {
        ordersByStatus[order.status] ??= <Order>[];
        ordersByStatus[order.status]!.add(order);
      }

      logDebug("Retrieved ${activeOrders.length} active orders");
      return ordersByStatus;
    } catch (e, stackTrace) {
      logError("Failed to retrieve active orders by status", e, stackTrace);
      rethrow;
    }
  }

  /// 注文キューを取得（調理順序順）
  Future<List<Order>> getOrderQueue(String userId) async {
    logDebug("Retrieving order queue");

    try {
      final List<Order> activeOrders = await _orderRepository.findByStatusList(<OrderStatus>[
        OrderStatus.preparing,
      ], userId);

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
      logDebug("Order queue retrieved: ${queue.length} orders");
      return queue;
    } catch (e, stackTrace) {
      logError("Failed to retrieve order queue", e, stackTrace);
      rethrow;
    }
  }

  /// 注文の調理を開始
  Future<Order?> startOrderPreparation(String orderId, String userId) async {
    logInfoMessage(KitchenInfo.preparationStarted);

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        logErrorMessage(KitchenError.orderAccessDenied);
        throw Exception("Order $orderId not found or access denied");
      }

      if (order.status != OrderStatus.preparing) {
        logErrorMessage(KitchenError.orderNotInPreparingStatus);
        throw Exception("Order is not in preparing status");
      }

      if (order.startedPreparingAt != null) {
        logWarningMessage(KitchenWarning.preparationAlreadyStarted);
        throw Exception("Order preparation already started");
      }

      // 調理開始時刻を記録
      final Order? updatedOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "started_preparing_at": DateTime.now().toIso8601String(),
      });

      if (updatedOrder != null) {
        logInfoMessage(KitchenInfo.preparationStartedSuccessfully);
      } else {
        logWarningMessage(KitchenWarning.preparationStartFailed);
      }

      return updatedOrder;
    } catch (e, stackTrace) {
      logErrorMessage(KitchenError.startPreparationFailed, null, e, stackTrace);
      rethrow;
    }
  }

  /// 注文の調理を完了
  Future<Order?> completeOrderPreparation(String orderId, String userId) async {
    logInfoMessage(KitchenInfo.preparationCompletionStarted);

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        logErrorMessage(KitchenError.orderAccessDenied);
        throw Exception("Order $orderId not found or access denied");
      }

      if (order.startedPreparingAt == null) {
        logErrorMessage(KitchenError.preparationNotStarted);
        throw Exception("Order preparation not started");
      }

      if (order.readyAt != null) {
        logWarningMessage(KitchenWarning.orderAlreadyCompleted);
        throw Exception("Order already completed");
      }

      // 調理完了時刻を記録
      final Order? updatedOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "ready_at": DateTime.now().toIso8601String(),
      });

      if (updatedOrder != null) {
        logInfoMessage(KitchenInfo.preparationCompletedSuccessfully);
      } else {
        logWarningMessage(KitchenWarning.preparationCompletionFailed);
      }

      return updatedOrder;
    } catch (e, stackTrace) {
      logErrorMessage(KitchenError.completePreparationFailed, null, e, stackTrace);
      rethrow;
    }
  }

  /// 注文を提供準備完了にマーク
  Future<Order?> markOrderReady(String orderId, String userId) async =>
      // completeOrderPreparationと同じ処理
      completeOrderPreparation(orderId, userId);

  /// 注文を提供完了
  Future<Order?> deliverOrder(String orderId, String userId) async {
    logInfoMessage(KitchenInfo.deliveryStarted);

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        logErrorMessage(KitchenError.orderAccessDenied);
        throw Exception("Order $orderId not found or access denied");
      }

      if (order.readyAt == null) {
        logErrorMessage(KitchenError.orderNotReadyForDelivery);
        throw Exception("Order not ready for delivery");
      }

      if (order.status == OrderStatus.completed) {
        logWarningMessage(KitchenWarning.orderAlreadyDelivered);
        throw Exception("Order already delivered");
      }

      // 提供完了
      final Order? updatedOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "status": OrderStatus.completed.value,
        "completed_at": DateTime.now().toIso8601String(),
      });

      if (updatedOrder != null) {
        logInfoMessage(KitchenInfo.deliverySuccessful);
      } else {
        logWarningMessage(KitchenWarning.deliveryFailed);
      }

      return updatedOrder;
    } catch (e, stackTrace) {
      logErrorMessage(KitchenError.deliverOrderFailed, null, e, stackTrace);
      rethrow;
    }
  }

  /// 完成予定時刻を調整
  Future<Order?> adjustEstimatedCompletionTime(
    String orderId,
    int additionalMinutes,
    String userId,
  ) async {
    logDebug("Adjusting estimated completion time");

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

      logInfo("Estimated completion time adjusted successfully");
      return updatedOrder;
    } catch (e, stackTrace) {
      logError("Failed to adjust estimated completion time", e, stackTrace);
      rethrow;
    }
  }

  /// キッチン状況を更新
  Future<bool> updateKitchenStatus(int activeStaffCount, String? notes, String userId) async {
    logDebug("Updating kitchen status: $activeStaffCount staff");

    // キッチン状況は別のモデルで管理されることを想定
    // ここでは簡単にログして成功を返す（実装は要件に応じて）
    logInfo("Kitchen status updated for user $userId: $activeStaffCount staff, notes: $notes");
    return true;
  }

  /// 実際の調理時間を取得（分）
  double? getActualPrepTimeMinutes(Order order) {
    if (order.startedPreparingAt != null && order.readyAt != null) {
      final Duration delta = order.readyAt!.difference(order.startedPreparingAt!);
      final double minutes = delta.inSeconds / 60.0;
      logDebug("Actual prep time calculated: ${minutes.toStringAsFixed(1)} minutes");
      return minutes;
    }
    return null;
  }
}
