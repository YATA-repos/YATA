import "dart:math" as math;

import "../../../core/constants/enums.dart";
import "../../../core/contracts/repositories/menu/menu_repository_contracts.dart";
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
// Removed LoggerComponent mixin; use local tag
import "../../../core/logging/compat.dart" as log;
import "../../menu/models/menu_model.dart";
import "../models/order_model.dart";
import "kitchen_operation_service.dart";

/// キッチン分析・予測サービス
class KitchenAnalysisService {
  KitchenAnalysisService({
    required OrderRepositoryContract<Order> orderRepository,
    required OrderItemRepositoryContract<OrderItem> orderItemRepository,
    required MenuItemRepositoryContract<MenuItem> menuItemRepository,
    required KitchenOperationService kitchenOperationService,
  }) : _orderRepository = orderRepository,
       _orderItemRepository = orderItemRepository,
       _menuItemRepository = menuItemRepository,
       _kitchenOperationService = kitchenOperationService;

  final OrderRepositoryContract<Order> _orderRepository;
  final OrderItemRepositoryContract<OrderItem> _orderItemRepository;
  final MenuItemRepositoryContract<MenuItem> _menuItemRepository;
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

      if (order.status == OrderStatus.completed) {
        log.d("Order already completed, returning completion time", tag: loggerComponent);
        return order.completedAt;
      }

      // 注文アイテムの調理時間を計算
      final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);
      int totalPrepTime = 0;

      for (final OrderItem item in orderItems) {
        final MenuItem? menuItem = await _menuItemRepository.getById(item.menuItemId);
        if (menuItem != null) {
          totalPrepTime += menuItem.estimatedPrepTimeMinutes * item.quantity;
        }
      }

      log.d("Total estimated prep time: $totalPrepTime minutes", tag: loggerComponent);

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
      final List<Order> activeOrders = await _orderRepository.findByStatusList(<OrderStatus>[
        OrderStatus.preparing,
      ]);

      final int notStartedCount = activeOrders
          .where((Order o) => o.startedPreparingAt == null)
          .length;
      final int inProgressCount = activeOrders
          .where((Order o) => o.startedPreparingAt != null && o.readyAt == null)
          .length;
      final int readyCount = activeOrders
          .where((Order o) => o.readyAt != null && o.status != OrderStatus.completed)
          .length;

      // 推定総調理時間を計算
      int totalEstimatedMinutes = 0;
      for (final Order order in activeOrders) {
        if (order.readyAt == null) {
          // まだ完成していない注文
          final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(order.id!);
          for (final OrderItem item in orderItems) {
            final MenuItem? menuItem = await _menuItemRepository.getById(item.menuItemId);
            if (menuItem != null) {
              totalEstimatedMinutes += menuItem.estimatedPrepTimeMinutes * item.quantity;
            }
          }
        }
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

      int totalWaitTime = 0;
      for (final Order order in queue) {
        if (order.startedPreparingAt == null) {
          // まだ開始していない注文
          final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(order.id!);
          for (final OrderItem item in orderItems) {
            final MenuItem? menuItem = await _menuItemRepository.getById(item.menuItemId);
            if (menuItem != null) {
              totalWaitTime += menuItem.estimatedPrepTimeMinutes * item.quantity;
            }
          }
        }
      }

      // 簡単な計算（実際はより複雑な計算が必要）
      final int waitTime = queue.isNotEmpty ? totalWaitTime ~/ math.max(1, queue.length) : 0;
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
      final List<Order> notStartedOrders = await _orderRepository.findByStatusList(<OrderStatus>[
        OrderStatus.preparing,
      ]);

      final List<Order> filteredOrders = notStartedOrders
          .where((Order o) => o.startedPreparingAt == null)
          .toList();

      // 最適化アルゴリズム（簡単な例：調理時間の短い順）
      final List<(String, int, DateTime)> orderPrepTimes = <(String, int, DateTime)>[];

      for (final Order order in filteredOrders) {
        final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(order.id!);
        int totalTime = 0;
        for (final OrderItem item in orderItems) {
          final MenuItem? menuItem = await _menuItemRepository.getById(item.menuItemId);
          if (menuItem != null) {
            totalTime += menuItem.estimatedPrepTimeMinutes * item.quantity;
          }
        }

        orderPrepTimes.add((order.id!, totalTime, order.orderedAt));
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
      final List<Order> activeOrders = await _orderRepository.findByStatusList(<OrderStatus>[
        OrderStatus.preparing,
      ]);
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
}
