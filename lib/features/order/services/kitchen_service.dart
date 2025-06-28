import "dart:math" as math;

import "../../../core/constants/enums.dart";
import "../../../core/utils/logger_mixin.dart";
import "../../menu/repositories/menu_item_repository.dart";
import "../models/order_model.dart";
import "../repositories/order_item_repository.dart";
import "../repositories/order_repository.dart";

/// 調理・キッチン管理サービス
@loggerComponent
class KitchenService with LoggerMixin {
  /// コンストラクタ
  KitchenService({
    OrderRepository? orderRepository,
    OrderItemRepository? orderItemRepository,
    MenuItemRepository? menuItemRepository,
  }) : _orderRepository = orderRepository ?? OrderRepository(),
       _orderItemRepository = orderItemRepository ?? OrderItemRepository(),
       _menuItemRepository = menuItemRepository ?? MenuItemRepository();

  final OrderRepository _orderRepository;
  final OrderItemRepository _orderItemRepository;
  final MenuItemRepository _menuItemRepository;

  /// ステータス別進行中注文を取得
  Future<Map<OrderStatus, List<Order>>> getActiveOrdersByStatus(
    String userId,
  ) async {
    final List<OrderStatus> activeStatuses = <OrderStatus>[
      OrderStatus.preparing,
    ];
    final List<Order> activeOrders = await _orderRepository.findByStatusList(
      activeStatuses,
      userId,
    );

    // ステータス別に分類
    final Map<OrderStatus, List<Order>> ordersByStatus =
        <OrderStatus, List<Order>>{};
    for (final Order order in activeOrders) {
      ordersByStatus[order.status] ??= <Order>[];
      ordersByStatus[order.status]!.add(order);
    }

    return ordersByStatus;
  }

  /// 注文キューを取得（調理順序順）
  Future<List<Order>> getOrderQueue(String userId) async {
    final List<Order> activeOrders = await _orderRepository.findByStatusList(
      <OrderStatus>[OrderStatus.preparing],
      userId,
    );

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

    return <Order>[...notStarted, ...inProgress];
  }

  /// 注文の調理を開始
  Future<Order?> startOrderPreparation(String orderId, String userId) async {
    final Order? order = await _orderRepository.getById(orderId);
    if (order == null || order.userId != userId) {
      throw Exception("Order $orderId not found or access denied");
    }

    if (order.status != OrderStatus.preparing) {
      throw Exception("Order is not in preparing status");
    }

    if (order.startedPreparingAt != null) {
      throw Exception("Order preparation already started");
    }

    // 調理開始時刻を記録
    final Order? updatedOrder = await _orderRepository.updateById(
      orderId,
      <String, dynamic>{
        "started_preparing_at": DateTime.now().toIso8601String(),
      },
    );

    return updatedOrder;
  }

  /// 注文の調理を完了
  Future<Order?> completeOrderPreparation(String orderId, String userId) async {
    final Order? order = await _orderRepository.getById(orderId);
    if (order == null || order.userId != userId) {
      throw Exception("Order $orderId not found or access denied");
    }

    if (order.startedPreparingAt == null) {
      throw Exception("Order preparation not started");
    }

    if (order.readyAt != null) {
      throw Exception("Order already completed");
    }

    // 調理完了時刻を記録
    final Order? updatedOrder = await _orderRepository.updateById(
      orderId,
      <String, dynamic>{"ready_at": DateTime.now().toIso8601String()},
    );

    return updatedOrder;
  }

  /// 注文を提供準備完了にマーク
  Future<Order?> markOrderReady(String orderId, String userId) async =>
      // completeOrderPreparationと同じ処理
      completeOrderPreparation(orderId, userId);

  /// 注文を提供完了
  Future<Order?> deliverOrder(String orderId, String userId) async {
    final Order? order = await _orderRepository.getById(orderId);
    if (order == null || order.userId != userId) {
      throw Exception("Order $orderId not found or access denied");
    }

    if (order.readyAt == null) {
      throw Exception("Order not ready for delivery");
    }

    if (order.status == OrderStatus.completed) {
      throw Exception("Order already delivered");
    }

    // 提供完了
    final Order? updatedOrder = await _orderRepository
        .updateById(orderId, <String, dynamic>{
          "status": OrderStatus.completed.value,
          "completed_at": DateTime.now().toIso8601String(),
        });

    return updatedOrder;
  }

  /// 完成予定時刻を計算
  Future<DateTime?> calculateEstimatedCompletionTime(
    String orderId,
    String userId,
  ) async {
    final Order? order = await _orderRepository.getById(orderId);
    if (order == null || order.userId != userId) {
      return null;
    }

    if (order.status == OrderStatus.completed) {
      return order.completedAt;
    }

    // 注文アイテムの調理時間を計算
    final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(
      orderId,
    );
    int totalPrepTime = 0;

    for (final OrderItem item in orderItems) {
      final dynamic menuItem = await _menuItemRepository.getById(
        item.menuItemId,
      );
      if (menuItem != null) {
        totalPrepTime +=
            (menuItem.estimatedPrepTimeMinutes as int) * item.quantity;
      }
    }

    // 基準時刻（調理開始時刻または注文時刻）
    final DateTime baseTime = order.startedPreparingAt ?? order.orderedAt;

    // キューでの待ち時間を考慮
    if (order.startedPreparingAt == null) {
      final int queueWaitTime = await calculateQueueWaitTime(userId);
      totalPrepTime += queueWaitTime;
    }

    return baseTime.add(Duration(minutes: totalPrepTime));
  }

  /// 完成予定時刻を調整
  Future<Order?> adjustEstimatedCompletionTime(
    String orderId,
    int additionalMinutes,
    String userId,
  ) async {
    final Order? order = await _orderRepository.getById(orderId);
    if (order == null || order.userId != userId) {
      throw Exception("Order $orderId not found or access denied");
    }

    // ノート欄に調整理由を記録
    final String adjustmentNote =
        "Est. time adjusted by $additionalMinutes minutes";
    final String currentNotes = order.notes ?? "";
    final String newNotes = "$currentNotes [$adjustmentNote]".trim();

    final Order? updatedOrder = await _orderRepository.updateById(
      orderId,
      <String, dynamic>{"notes": newNotes},
    );

    return updatedOrder;
  }

  /// キッチン状況を更新
  Future<bool> updateKitchenStatus(
    int activeStaffCount,
    String? notes,
    String userId,
  ) async =>
      // キッチン状況は別のモデルで管理されることを想定
      // ここでは簡単にログして成功を返す（実装は要件に応じて）
      // TODO(dev): 実際のログフレームワークに置き換える
      // Logger.info("Kitchen status updated for user $userId: $activeStaffCount staff, notes: $notes");
      true;

  /// キッチンの負荷状況を取得
  Future<Map<String, dynamic>> getKitchenWorkload(String userId) async {
    final List<Order> activeOrders = await _orderRepository.findByStatusList(
      <OrderStatus>[OrderStatus.preparing],
      userId,
    );

    final int notStartedCount = activeOrders
        .where((Order o) => o.startedPreparingAt == null)
        .length;
    final int inProgressCount = activeOrders
        .where((Order o) => o.startedPreparingAt != null && o.readyAt == null)
        .length;
    final int readyCount = activeOrders
        .where(
          (Order o) => o.readyAt != null && o.status != OrderStatus.completed,
        )
        .length;

    // 推定総調理時間を計算
    int totalEstimatedMinutes = 0;
    for (final Order order in activeOrders) {
      if (order.readyAt == null) {
        // まだ完成していない注文
        final List<OrderItem> orderItems = await _orderItemRepository
            .findByOrderId(order.id!);
        for (final OrderItem item in orderItems) {
          final dynamic menuItem = await _menuItemRepository.getById(
            item.menuItemId,
          );
          if (menuItem != null) {
            totalEstimatedMinutes +=
                (menuItem.estimatedPrepTimeMinutes as int) * item.quantity;
          }
        }
      }
    }

    return <String, dynamic>{
      "total_active_orders": activeOrders.length,
      "not_started_count": notStartedCount,
      "in_progress_count": inProgressCount,
      "ready_count": readyCount,
      "estimated_total_minutes": totalEstimatedMinutes,
      "average_wait_time_minutes": await calculateQueueWaitTime(userId),
    };
  }

  /// 注文キューの待ち時間を計算（分）
  Future<int> calculateQueueWaitTime(String userId) async {
    final List<Order> queue = await getOrderQueue(userId);

    int totalWaitTime = 0;
    for (final Order order in queue) {
      if (order.startedPreparingAt == null) {
        // まだ開始していない注文
        final List<OrderItem> orderItems = await _orderItemRepository
            .findByOrderId(order.id!);
        for (final OrderItem item in orderItems) {
          final dynamic menuItem = await _menuItemRepository.getById(
            item.menuItemId,
          );
          if (menuItem != null) {
            totalWaitTime +=
                (menuItem.estimatedPrepTimeMinutes as int) * item.quantity;
          }
        }
      }
    }

    // 簡単な計算（実際はより複雑な計算が必要）
    return queue.isNotEmpty ? totalWaitTime ~/ math.max(1, queue.length) : 0;
  }

  /// 調理順序を最適化（注文IDリストを返す）
  Future<List<String>> optimizeCookingOrder(String userId) async {
    final List<Order> notStartedOrders = await _orderRepository
        .findByStatusList(<OrderStatus>[OrderStatus.preparing], userId);

    final List<Order> filteredOrders = notStartedOrders
        .where((Order o) => o.startedPreparingAt == null)
        .toList();

    // 最適化アルゴリズム（簡単な例：調理時間の短い順）
    final List<(String, int, DateTime)> orderPrepTimes =
        <(String, int, DateTime)>[];

    for (final Order order in filteredOrders) {
      final List<OrderItem> orderItems = await _orderItemRepository
          .findByOrderId(order.id!);
      int totalTime = 0;
      for (final OrderItem item in orderItems) {
        final dynamic menuItem = await _menuItemRepository.getById(
          item.menuItemId,
        );
        if (menuItem != null) {
          totalTime +=
              (menuItem.estimatedPrepTimeMinutes as int) * item.quantity;
        }
      }

      orderPrepTimes.add((order.id!, totalTime, order.orderedAt));
    }

    // 調理時間の短い順、同じ時間なら注文の早い順
    orderPrepTimes.sort(((String, int, DateTime) a, (String, int, DateTime) b) {
      final int timeComparison = a.$2.compareTo(b.$2);
      return timeComparison != 0 ? timeComparison : a.$3.compareTo(b.$3);
    });

    return orderPrepTimes
        .map(((String, int, DateTime) record) => record.$1)
        .toList();
  }

  /// 全注文の完成予定時刻を予測
  Future<Map<String, DateTime>> predictCompletionTimes(String userId) async {
    final List<Order> activeOrders = await _orderRepository.findByStatusList(
      <OrderStatus>[OrderStatus.preparing],
      userId,
    );
    final Map<String, DateTime> completionTimes = <String, DateTime>{};

    for (final Order order in activeOrders) {
      final DateTime? estimatedTime = await calculateEstimatedCompletionTime(
        order.id!,
        userId,
      );
      if (estimatedTime != null) {
        completionTimes[order.id!] = estimatedTime;
      }
    }

    return completionTimes;
  }

  /// キッチンパフォーマンス指標を取得
  Future<Map<String, dynamic>> getKitchenPerformanceMetrics(
    DateTime targetDate,
    String userId,
  ) async {
    // 指定日の完了注文を取得
    final List<Order> completedOrders = await _orderRepository
        .findCompletedByDate(targetDate, userId);

    if (completedOrders.isEmpty) {
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
      final double? prepTime = getActualPrepTimeMinutes(order);
      if (prepTime != null) {
        prepTimes.add(prepTime);
      }

      totalRevenue += order.totalAmount;
    }

    double averagePrepTime = 0.0;
    double fastestOrder = 0.0;
    double slowestOrder = 0.0;

    if (prepTimes.isNotEmpty) {
      averagePrepTime =
          prepTimes.reduce((double a, double b) => a + b) / prepTimes.length;
      fastestOrder = prepTimes.reduce(math.min);
      slowestOrder = prepTimes.reduce(math.max);
    }

    return <String, dynamic>{
      "total_orders": completedOrders.length,
      "average_prep_time_minutes": (averagePrepTime * 10).round() / 10.0,
      "total_revenue": totalRevenue,
      "fastest_order_minutes": (fastestOrder * 10).round() / 10.0,
      "slowest_order_minutes": (slowestOrder * 10).round() / 10.0,
      "orders_per_hour": completedOrders.isNotEmpty
          ? completedOrders.length / 24.0
          : 0.0,
    };
  }

  /// 実際の調理時間を取得（分）
  double? getActualPrepTimeMinutes(Order order) {
    if (order.startedPreparingAt != null && order.readyAt != null) {
      final Duration delta = order.readyAt!.difference(
        order.startedPreparingAt!,
      );
      return delta.inSeconds / 60.0;
    }
    return null;
  }
}
