// Riverpod not required here; DI is provided via app wiring

import "../../../core/base/base_error_msg.dart";
import "../../../core/constants/enums.dart";
import "../../../core/constants/log_enums/analytics.dart";
import "../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../core/contracts/repositories/inventory/stock_transaction_repository_contract.dart";
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
import "../../inventory/models/transaction_model.dart";
import "../../order/models/order_model.dart";
import "../../order/shared/order_status_mapper.dart";
import "../dto/analytics_dto.dart";

class AnalyticsService {
  AnalyticsService({
    required log_contract.LoggerContract logger,
    required OrderRepositoryContract<Order> orderRepository,
    required OrderItemRepositoryContract<OrderItem> orderItemRepository,
    required StockTransactionRepositoryContract<StockTransaction> stockTransactionRepository,
  }) : _logger = logger,
       _orderRepository = orderRepository,
       _orderItemRepository = orderItemRepository,
       _stockTransactionRepository = stockTransactionRepository;

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final OrderRepositoryContract<Order> _orderRepository;
  final OrderItemRepositoryContract<OrderItem> _orderItemRepository;
  final StockTransactionRepositoryContract<StockTransaction> _stockTransactionRepository;

  String get loggerComponent => "AnalyticsService";

  /// リアルタイム日次統計を取得
  Future<DailyStatsResult> getRealTimeDailyStats(DateTime targetDate, String userId) async {
    log.i(AnalyticsInfo.dailyStatsStarted.message, tag: loggerComponent);

    try {
      // 指定日の注文数を取得（findByDateRangeから集計）
      final List<Order> targetDayOrders = await _orderRepository.findByDateRange(
        targetDate,
        targetDate,
      );
      final Map<OrderStatus, int> statusCounts = <OrderStatus, int>{
        for (final OrderStatus s in OrderStatus.primaryStatuses) s: 0,
      };
      for (final Order o in targetDayOrders) {
        final OrderStatus normalizedStatus = OrderStatusMapper.normalize(o.status);
        statusCounts[normalizedStatus] = (statusCounts[normalizedStatus] ?? 0) + 1;
      }

      // 完了注文を取得して売上計算
      final List<Order> completedOrders = await _orderRepository.findCompletedByDate(targetDate);

      log.d(
        "Retrieved ${completedOrders.length} completed orders for stats calculation",
        tag: loggerComponent,
      );

      final int totalRevenue = completedOrders.fold(
        0,
        (int sum, Order order) => sum + order.totalAmount,
      );

      // 平均調理時間を計算
      final List<int> prepTimes = <int>[];
      for (final Order order in completedOrders) {
        final DateTime? startedAt = order.startedPreparingAt;
        final DateTime? readyAt = order.readyAt;
        if (startedAt != null && readyAt != null) {
          final Duration delta = readyAt.difference(startedAt);
          prepTimes.add((delta.inSeconds / 60).floor());
        }
      }

      // 平均調理時間を計算（分単位）
      // もしprepTimesが空ならnullを返す
      final int? averagePrepTime = prepTimes.isNotEmpty
          ? (prepTimes.reduce((int a, int b) => a + b) / prepTimes.length).floor()
          : null;

      // 最人気商品を取得
      final List<Map<String, dynamic>> popularItems = await getPopularItemsRanking(1, 1, userId);
      final Map<String, dynamic>? mostPopularItem = popularItems.isNotEmpty
          ? popularItems[0]
          : null;

      log.i(
        AnalyticsInfo.dailyStatsCompleted.withParams(<String, String>{
          "totalRevenue": totalRevenue.toString(),
          "totalOrders": completedOrders.length.toString(),
        }),
        tag: loggerComponent,
      );

      return DailyStatsResult(
  completedOrders: statusCounts[OrderStatus.completed] ?? 0,
  pendingOrders: statusCounts[OrderStatus.inProgress] ?? 0,
        totalRevenue: totalRevenue,
        averagePrepTimeMinutes: averagePrepTime,
        mostPopularItem: mostPopularItem,
      );
    } catch (e, stackTrace) {
      log.e(
        AnalyticsError.dailyStatsRetrievalFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 人気商品ランキングを取得
  Future<List<Map<String, dynamic>>> getPopularItemsRanking(
    int days,
    int limit,
    String userId,
  ) async {
    log.i(
      AnalyticsInfo.popularItemsStarted.withParams(<String, String>{
        "days": days.toString(),
        "limit": limit.toString(),
      }),
      tag: loggerComponent,
    );

    try {
      // 売上集計を取得
      final List<Map<String, dynamic>> salesSummary = await _orderItemRepository
          .getMenuItemSalesSummary(days);

      log.d("Retrieved sales summary for ${salesSummary.length} menu items", tag: loggerComponent);

      // 上位N件を取得
      final List<Map<String, dynamic>> topItems = salesSummary.take(limit).toList();

      // 結果を整形
      final List<Map<String, dynamic>> ranking = <Map<String, dynamic>>[];
      for (int i = 0; i < topItems.length; i++) {
        final Map<String, dynamic> item = topItems[i];
        ranking.add(<String, dynamic>{
          "rank": i + 1,
          "menu_item_id": item["menu_item_id"],
          "total_quantity": item["total_quantity"],
          "total_amount": item["total_amount"],
        });
      }

      log.i(
        AnalyticsInfo.popularItemsCompleted.withParams(<String, String>{
          "itemCount": ranking.length.toString(),
        }),
        tag: loggerComponent,
      );
      return ranking;
    } catch (e, stackTrace) {
      log.e(
        AnalyticsError.popularItemsRetrievalFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 平均調理時間を計算
  Future<double?> calculateAveragePreparationTime(
    int days,
    String? menuItemId,
    String userId,
  ) async {
    // 期間を計算
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(Duration(days: days));

    // 完了注文を取得
    final List<Order> completedOrders = await _orderRepository.findOrdersByCompletionTimeRange(
      startDate,
      endDate,
    );

    // 特定メニューアイテムの場合はフィルタ
    if (menuItemId != null) {
      // 該当メニューアイテムを含む注文のみ抽出
      final List<Order> filteredOrders = <Order>[];
      for (final Order order in completedOrders) {
        final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(order.id!);
        final bool hasMenuItem = orderItems.any((OrderItem item) => item.menuItemId == menuItemId);
        if (hasMenuItem) {
          filteredOrders.add(order);
        }
      }
      // 元のリストを更新
      completedOrders
        ..clear()
        ..addAll(filteredOrders);
    }

    // 調理時間を計算
    final List<double> prepTimes = <double>[];
    for (final Order order in completedOrders) {
      final DateTime? startedAt = order.startedPreparingAt;
      final DateTime? readyAt = order.readyAt;
      if (startedAt != null && readyAt != null) {
        final Duration delta = readyAt.difference(startedAt);
        prepTimes.add(delta.inSeconds / 60.0); // 分単位
      }
    }

    return prepTimes.isNotEmpty
        ? prepTimes.reduce((double a, double b) => a + b) / prepTimes.length
        : null;
  }

  /// 時間帯別注文分布を取得
  Future<Map<int, int>> getHourlyOrderDistribution(DateTime targetDate, String userId) async {
    // 指定日の全注文を取得
    final List<Order> orders = await _orderRepository.findByDateRange(targetDate, targetDate);

    // 時間帯別に集計
    final Map<int, int> hourlyDistribution = <int, int>{};
    for (final Order order in orders) {
      final int hour = order.orderedAt.hour;
      hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;
    }

    // 0-23時まで全時間を含むMapを作成
    final Map<int, int> result = <int, int>{};
    for (int hour = 0; hour < 24; hour++) {
      result[hour] = hourlyDistribution[hour] ?? 0;
    }

    return result;
  }

  /// 期間指定売上を計算
  Future<Map<String, dynamic>> calculateRevenueByDateRange(
    DateTime dateFrom,
    DateTime dateTo,
    String userId,
  ) async {
    log.i(AnalyticsInfo.revenueCalculationStarted.message, tag: loggerComponent);

    try {
      // 期間内の完了注文を取得
      final List<Order> orders = await _orderRepository.findByDateRange(dateFrom, dateTo);
      final List<Order> completedOrders = orders
          .where((Order order) => order.status == OrderStatus.completed)
          .toList();

      log.d("Found ${completedOrders.length} completed orders in date range", tag: loggerComponent);

      // 売上計算
      final int totalRevenue = completedOrders.fold(
        0,
        (int sum, Order order) => sum + order.totalAmount,
      );
      final int totalOrders = completedOrders.length;
      final double averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

      // 日別売上を計算
      final Map<String, int> dailyRevenue = <String, int>{};
      for (final Order order in completedOrders) {
        final DateTime? completedAt = order.completedAt;
        final String dateKey = completedAt != null
            ? completedAt.toIso8601String().split("T")[0]
            : order.orderedAt.toIso8601String().split("T")[0];
        dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + order.totalAmount;
      }

      log.i(
        AnalyticsInfo.revenueCalculationCompleted.withParams(<String, String>{
          "totalRevenue": totalRevenue.toString(),
          "totalOrders": totalOrders.toString(),
        }),
        tag: loggerComponent,
      );

      return <String, dynamic>{
        "total_revenue": totalRevenue,
        "total_orders": totalOrders,
        "average_order_value": averageOrderValue,
        "daily_breakdown": dailyRevenue,
        "period_start": dateFrom.toIso8601String(),
        "period_end": dateTo.toIso8601String(),
      };
    } catch (e, stackTrace) {
      log.e(
        AnalyticsError.revenueCalculationFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 材料消費分析を取得
  Future<Map<String, dynamic>> getMaterialConsumptionAnalysis(
    String materialId,
    int days,
    String userId,
  ) async {
    // 期間を計算
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(Duration(days: days));

    // 材料の消費取引を取得
    final List<StockTransaction> transactions = await _stockTransactionRepository
        .findByMaterialAndDateRange(materialId, startDate, endDate);

    // 消費取引のみを抽出（負の値）
    final List<StockTransaction> consumptionTransactions = transactions
        .where((StockTransaction tx) => tx.changeAmount < 0)
        .toList();

    // 統計を計算
    final double totalConsumed = consumptionTransactions.fold(
      0.0,
      (double sum, StockTransaction tx) => sum + tx.changeAmount.abs(),
    );
    final Map<String, double> dailyConsumption = <String, double>{};

    for (final StockTransaction tx in consumptionTransactions) {
      final DateTime? createdAt = tx.createdAt;
      final String dateKey = createdAt != null
          ? createdAt.toIso8601String().split("T")[0]
          : DateTime.now().toIso8601String().split("T")[0];
      dailyConsumption[dateKey] = (dailyConsumption[dateKey] ?? 0.0) + tx.changeAmount.abs();
    }

    final double averageDailyConsumption = days > 0 ? totalConsumed / days : 0.0;

    return <String, dynamic>{
      "material_id": materialId,
      "analysis_period_days": days,
      "total_consumed": totalConsumed,
      "average_daily_consumption": averageDailyConsumption,
      "daily_breakdown": dailyConsumption,
      "consumption_events": consumptionTransactions.length,
    };
  }

  /// メニューアイテムの収益性を分析
  Future<Map<String, dynamic>> calculateMenuItemProfitability(
    String menuItemId,
    int days,
    String userId,
  ) async {
    // 期間を計算
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(Duration(days: days));

    // 指定メニューアイテムの注文明細を取得
    final List<OrderItem> orderItems = await _orderItemRepository.findByMenuItemAndDateRange(
      menuItemId,
      startDate,
      endDate,
    );

    // 売上統計を計算
    final int totalQuantity = orderItems.fold(0, (int sum, OrderItem item) => sum + item.quantity);
    final int totalRevenue = orderItems.fold(0, (int sum, OrderItem item) => sum + item.subtotal);
    final double averagePrice = totalQuantity > 0 ? totalRevenue / totalQuantity : 0.0;

    // 日別売上を計算
    final Map<String, Map<String, int>> dailySales = <String, Map<String, int>>{};
    for (final OrderItem item in orderItems) {
      final DateTime? createdAt = item.createdAt;
      final String dateKey = createdAt != null
          ? createdAt.toIso8601String().split("T")[0]
          : DateTime.now().toIso8601String().split("T")[0];
      dailySales[dateKey] ??= <String, int>{"quantity": 0, "revenue": 0};
      final Map<String, int> dailyData = dailySales[dateKey]!;
      dailyData["quantity"] = dailyData["quantity"]! + item.quantity;
      dailyData["revenue"] = dailyData["revenue"]! + item.subtotal;
    }

    return <String, dynamic>{
      "menu_item_id": menuItemId,
      "analysis_period_days": days,
      "total_quantity_sold": totalQuantity,
      "total_revenue": totalRevenue,
      "average_selling_price": averagePrice,
      "daily_breakdown": dailySales,
      "average_daily_quantity": days > 0 ? totalQuantity / days : 0.0,
    };
  }

  /// 日次サマリーをトレンド比較付きで取得
  Future<Map<String, dynamic>> getDailySummaryWithTrends(
    DateTime targetDate,
    int comparisonDays,
    String userId,
  ) async {
    // 対象日の統計を取得
    final DailyStatsResult targetStats = await getRealTimeDailyStats(targetDate, userId);

    // 比較期間の統計を取得
    final DateTime comparisonStart = targetDate.subtract(Duration(days: comparisonDays));
    final DateTime comparisonEnd = targetDate.subtract(const Duration(days: 1));

    final Map<String, dynamic> comparisonRevenue = await calculateRevenueByDateRange(
      comparisonStart,
      comparisonEnd,
      userId,
    );

    // トレンド計算
    final double avgDailyRevenue = comparisonDays > 0
        ? (_parseToInt(comparisonRevenue["total_revenue"]) ?? 0) / comparisonDays
        : 0.0;
    final double revenueTrend = avgDailyRevenue > 0
        ? ((targetStats.totalRevenue - avgDailyRevenue) / avgDailyRevenue * 100)
        : 0.0;

    final double avgDailyOrders = comparisonDays > 0
        ? (_parseToInt(comparisonRevenue["total_orders"]) ?? 0) / comparisonDays
        : 0.0;
    final double orderTrend = avgDailyOrders > 0
        ? ((targetStats.completedOrders - avgDailyOrders) / avgDailyOrders * 100)
        : 0.0;

    return <String, dynamic>{
      "target_date": targetDate.toIso8601String().split("T")[0],
      "current_stats": <String, dynamic>{
        "completed_orders": targetStats.completedOrders,
        "pending_orders": targetStats.pendingOrders,
        "total_revenue": targetStats.totalRevenue,
        "average_prep_time_minutes": targetStats.averagePrepTimeMinutes,
        "most_popular_item": targetStats.mostPopularItem,
      },
      "trends": <String, dynamic>{
        "revenue_change_percent": (revenueTrend * 100).round() / 100.0,
        "order_count_change_percent": (orderTrend * 100).round() / 100.0,
        "comparison_period_days": comparisonDays,
      },
      "comparison_averages": <String, dynamic>{
        "avg_daily_revenue": (avgDailyRevenue * 100).round() / 100.0,
        "avg_daily_orders": (avgDailyOrders * 100).round() / 100.0,
      },
    };
  }

  /// 安全なint変換ヘルパー
  int? _parseToInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
