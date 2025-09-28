import "dart:math" as math;

import "../../../core/constants/enums.dart";
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
// Removed LoggerComponent mixin; use local tag
import "../../../core/logging/compat.dart" as log;
import "../models/order_model.dart";
import "kitchen_operation_service.dart";
import "../shared/order_status_mapper.dart";

/// キッチン分析・予測サービス
class KitchenAnalysisService {
  KitchenAnalysisService({
    required OrderRepositoryContract<Order> orderRepository,
    required OrderItemRepositoryContract<OrderItem> orderItemRepository,
    required KitchenOperationService kitchenOperationService,
  }) : _orderRepository = orderRepository,
       _orderItemRepository = orderItemRepository,
       _kitchenOperationService = kitchenOperationService;

  final OrderRepositoryContract<Order> _orderRepository;
  final OrderItemRepositoryContract<OrderItem> _orderItemRepository;
  final KitchenOperationService _kitchenOperationService;

  String get loggerComponent => "KitchenAnalysisService";

  /// 完成予定時刻を計算
  Future<DateTime?> calculateEstimatedCompletionTime(String orderId, String userId) async {
    log.d("Calculating estimated completion time for order: $orderId", tag: loggerComponent);

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        log.w("Order not found or access denied", tag: loggerComponent);
        return null;
      }

      if (OrderStatusMapper.normalize(order.status) == OrderStatus.completed) {
        log.d("Order already completed, returning completion time", tag: loggerComponent);
        return order.completedAt;
      }

      // 注文アイテム数を元に平均調理時間を推定
      final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);
      final int itemCount = orderItems.fold<int>(
        0,
        (int total, OrderItem item) => total + item.quantity,
      );

      if (itemCount == 0) {
        log.w("No order items found for estimation", tag: loggerComponent);
        return null;
      }

      final double? avgPrepMinutesPerItem = await _getAveragePrepMinutesPerItem();
      if (avgPrepMinutesPerItem == null) {
        log.w(
          "Historical prep time data unavailable; cannot estimate completion",
          tag: loggerComponent,
        );
        return null;
      }

      int totalPrepTime = math.max(0, (avgPrepMinutesPerItem * itemCount).round());

      log.d(
        "Total estimated prep time (historical average): $totalPrepTime minutes",
        tag: loggerComponent,
      );

      // 基準時刻（調理開始時刻または注文時刻）
      final DateTime baseTime = order.startedPreparingAt ?? order.orderedAt;

      // キューでの待ち時間を考慮
      if (order.startedPreparingAt == null) {
        final int queueWaitTime = await calculateQueueWaitTime(userId);
        totalPrepTime += queueWaitTime;
        log.d("Added queue wait time: $queueWaitTime minutes", tag: loggerComponent);
      }

      final DateTime estimatedTime = baseTime.add(Duration(minutes: totalPrepTime));
      log.d("Estimated completion time: $estimatedTime", tag: loggerComponent);
      return estimatedTime;
    } catch (e, stackTrace) {
      log.e(
        "Failed to calculate estimated completion time",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      return null;
    }
  }

  /// キッチンの負荷状況を取得
  Future<Map<String, dynamic>> getKitchenWorkload(String userId) async {
    log.d("Retrieving kitchen workload", tag: loggerComponent);

    try {
      final List<Order> activeOrders = await _orderRepository.findByStatusList(
        const <OrderStatus>[OrderStatus.inProgress],
      );

      final int notStartedCount = activeOrders
          .where((Order o) => o.startedPreparingAt == null)
          .length;
      final int inProgressCount = activeOrders
          .where((Order o) => o.startedPreparingAt != null && o.readyAt == null)
          .length;
    final int readyCount = activeOrders
      .where(
      (Order o) =>
        o.readyAt != null &&
        OrderStatusMapper.normalize(o.status) != OrderStatus.completed,
      )
          .length;

      // 推定総調理時間を計算
      int totalEstimatedMinutes = 0;
      final double? avgPrepMinutesPerItem = await _getAveragePrepMinutesPerItem();
      if (avgPrepMinutesPerItem == null) {
        log.w(
          "Historical prep data unavailable; estimated totals default to 0",
          tag: loggerComponent,
        );
      } else {
        double aggregated = 0;
        for (final Order order in activeOrders) {
          if (order.readyAt == null && order.id != null) {
            final int itemCount = await _countOrderItems(order.id!);
            aggregated += avgPrepMinutesPerItem * itemCount;
          }
        }
        totalEstimatedMinutes = aggregated.round();
      }

      final Map<String, dynamic> workload = <String, dynamic>{
        "total_active_orders": activeOrders.length,
        "not_started_count": notStartedCount,
        "in_progress_count": inProgressCount,
        "ready_count": readyCount,
        "estimated_total_minutes": totalEstimatedMinutes,
        "average_wait_time_minutes": await calculateQueueWaitTime(userId),
      };

      log.d(
        "Kitchen workload calculated: ${workload['total_active_orders']} active orders",
        tag: loggerComponent,
      );
      return workload;
    } catch (e, stackTrace) {
      log.e("Failed to retrieve kitchen workload", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 注文キューの待ち時間を計算（分）
  Future<int> calculateQueueWaitTime(String userId) async {
    log.d("Calculating queue wait time", tag: loggerComponent);

    try {
      final List<Order> queue = await _kitchenOperationService.getOrderQueue(userId);

      final double? avgPrepMinutesPerItem = await _getAveragePrepMinutesPerItem();
      if (avgPrepMinutesPerItem == null) {
        log.w(
          "Historical prep data unavailable; queue wait time defaults to 0",
          tag: loggerComponent,
        );
        return 0;
      }

      double totalWaitMinutes = 0;
      for (final Order order in queue) {
        if (order.startedPreparingAt == null && order.id != null) {
          // まだ開始していない注文
          final int itemCount = await _countOrderItems(order.id!);
          totalWaitMinutes += avgPrepMinutesPerItem * itemCount;
        }
      }

      // 簡単な計算（実際はより複雑な計算が必要）
      final int waitTime = queue.isNotEmpty
          ? (totalWaitMinutes / math.max(1, queue.length)).round()
          : 0;
      log.d("Queue wait time calculated: $waitTime minutes", tag: loggerComponent);
      return waitTime;
    } catch (e, stackTrace) {
      log.e("Failed to calculate queue wait time", tag: loggerComponent, error: e, st: stackTrace);
      return 0;
    }
  }

  /// 調理順序を最適化（注文IDリストを返す）
  Future<List<String>> optimizeCookingOrder(String userId) async {
    log.d("Optimizing cooking order", tag: loggerComponent);

    try {
      final List<Order> notStartedOrders = await _orderRepository.findByStatusList(
        const <OrderStatus>[OrderStatus.inProgress],
      );

      final List<Order> filteredOrders = notStartedOrders
          .where((Order o) => o.startedPreparingAt == null)
          .toList();

      // 最適化アルゴリズム（簡単な例：平均調理時間を用いた短時間優先）
      final double? avgPrepMinutesPerItem = await _getAveragePrepMinutesPerItem();
      if (avgPrepMinutesPerItem == null) {
        log.w("Historical prep data unavailable; fallback to FIFO order", tag: loggerComponent);
        filteredOrders.sort((Order a, Order b) => a.orderedAt.compareTo(b.orderedAt));
        return filteredOrders
            .where((Order order) => order.id != null)
            .map((Order order) => order.id!)
            .toList();
      }

      final List<(String, int, DateTime)> orderPrepTimes = <(String, int, DateTime)>[];

      for (final Order order in filteredOrders) {
        if (order.id == null) {
          continue;
        }
        final int itemCount = await _countOrderItems(order.id!);
        final int estimatedMinutes = math.max(0, (avgPrepMinutesPerItem * itemCount).round());
        orderPrepTimes.add((order.id!, estimatedMinutes, order.orderedAt));
      }

      // 調理時間の短い順、同じ時間なら注文の早い順
      orderPrepTimes.sort(((String, int, DateTime) a, (String, int, DateTime) b) {
        final int timeComparison = a.$2.compareTo(b.$2);
        return timeComparison != 0 ? timeComparison : a.$3.compareTo(b.$3);
      });

      final List<String> optimizedOrder = orderPrepTimes
          .map(((String, int, DateTime) record) => record.$1)
          .toList();
      log.d("Cooking order optimized: ${optimizedOrder.length} orders", tag: loggerComponent);
      return optimizedOrder;
    } catch (e, stackTrace) {
      log.e("Failed to optimize cooking order", tag: loggerComponent, error: e, st: stackTrace);
      return <String>[];
    }
  }

  /// 全注文の完成予定時刻を予測
  Future<Map<String, DateTime>> predictCompletionTimes(String userId) async {
    log.d("Predicting completion times for all active orders", tag: loggerComponent);

    try {
      final List<Order> activeOrders = await _orderRepository.findByStatusList(
        const <OrderStatus>[OrderStatus.inProgress],
      );
      final Map<String, DateTime> completionTimes = <String, DateTime>{};

      for (final Order order in activeOrders) {
        final DateTime? estimatedTime = await calculateEstimatedCompletionTime(order.id!, userId);
        if (estimatedTime != null) {
          completionTimes[order.id!] = estimatedTime;
        }
      }

      log.d(
        "Completion times predicted for ${completionTimes.length} orders",
        tag: loggerComponent,
      );
      return completionTimes;
    } catch (e, stackTrace) {
      log.e("Failed to predict completion times", tag: loggerComponent, error: e, st: stackTrace);
      return <String, DateTime>{};
    }
  }

  /// キッチンパフォーマンス指標を取得
  Future<Map<String, dynamic>> getKitchenPerformanceMetrics(
    DateTime targetDate,
    String userId,
  ) async {
    log.d("Retrieving kitchen performance metrics for date: $targetDate", tag: loggerComponent);

    try {
      // 指定日の完了注文を取得
      final List<Order> completedOrders = await _orderRepository.findCompletedByDate(targetDate);

      if (completedOrders.isEmpty) {
        log.d("No completed orders found for the specified date", tag: loggerComponent);
        return <String, dynamic>{
          "total_orders": 0,
          "average_prep_time_minutes": 0.0,
          "total_revenue": 0,
          "fastest_order_minutes": 0.0,
          "slowest_order_minutes": 0.0,
        };
      }

      // 調理時間の分析
      final List<double> prepTimes = <double>[];
      int totalRevenue = 0;

      for (final Order order in completedOrders) {
        final double? prepTime = _kitchenOperationService.getActualPrepTimeMinutes(order);
        if (prepTime != null) {
          prepTimes.add(prepTime);
        }

        totalRevenue += order.totalAmount;
      }

      double averagePrepTime = 0.0;
      double fastestOrder = 0.0;
      double slowestOrder = 0.0;

      if (prepTimes.isNotEmpty) {
        averagePrepTime = prepTimes.reduce((double a, double b) => a + b) / prepTimes.length;
        fastestOrder = prepTimes.reduce(math.min);
        slowestOrder = prepTimes.reduce(math.max);
      }

      final Map<String, dynamic> metrics = <String, dynamic>{
        "total_orders": completedOrders.length,
        "average_prep_time_minutes": (averagePrepTime * 10).round() / 10.0,
        "total_revenue": totalRevenue,
        "fastest_order_minutes": (fastestOrder * 10).round() / 10.0,
        "slowest_order_minutes": (slowestOrder * 10).round() / 10.0,
        "orders_per_hour": completedOrders.isNotEmpty ? completedOrders.length / 24.0 : 0.0,
      };

      log.d(
        "Performance metrics calculated: ${metrics['total_orders']} orders processed",
        tag: loggerComponent,
      );
      return metrics;
    } catch (e, stackTrace) {
      log.e(
        "Failed to retrieve kitchen performance metrics",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> _countOrderItems(String orderId) async {
    final List<OrderItem> items = await _orderItemRepository.findByOrderId(orderId);
    return items.fold<int>(0, (int total, OrderItem item) => total + item.quantity);
  }

  Future<double?> _getAveragePrepMinutesPerItem() async {
    try {
      final List<Order> recentOrders = await _orderRepository.findRecentOrders(limit: 20);
      if (recentOrders.isEmpty) {
        return null;
      }

      double totalMinutes = 0;
      int totalItems = 0;

      for (final Order order in recentOrders) {
        if (order.id == null) {
          continue;
        }

        final double? prepMinutes = _kitchenOperationService.getActualPrepTimeMinutes(order);
        if (prepMinutes == null) {
          continue;
        }

        final List<OrderItem> items = await _orderItemRepository.findByOrderId(order.id!);
        final int itemCount = items.fold<int>(0, (int sum, OrderItem item) => sum + item.quantity);
        if (itemCount == 0) {
          continue;
        }

        totalMinutes += prepMinutes;
        totalItems += itemCount;
      }

      if (totalItems == 0) {
        return null;
      }

      final double average = totalMinutes / totalItems;
      if (!average.isFinite) {
        return null;
      }
      return average;
    } catch (e, stackTrace) {
      log.e(
        "Failed to compute average prep minutes per item",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      return null;
    }
  }
}
