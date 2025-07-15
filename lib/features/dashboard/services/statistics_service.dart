import "../../../core/constants/enums.dart";
import "../../../core/utils/logger_mixin.dart";
import "../../inventory/models/inventory_model.dart";
import "../../inventory/repositories/material_repository.dart";
import "../../order/models/order_model.dart";
import "../../order/repositories/order_repository.dart";
import "../models/dashboard_stats_model.dart";
import "../repositories/dashboard_repository.dart";

/// 統計サービス
///
/// ダッシュボード統計の計算と分析機能を提供します。
class StatisticsService with LoggerMixin {
  StatisticsService({
    required DashboardRepository dashboardRepository,
    required OrderRepository orderRepository,
    required MaterialRepository materialRepository,
  }) : _dashboardRepository = dashboardRepository,
       _orderRepository = orderRepository,
       _materialRepository = materialRepository;

  final DashboardRepository _dashboardRepository;
  final OrderRepository _orderRepository;
  final MaterialRepository _materialRepository;

  @override
  String get loggerComponent => "StatisticsService";

  /// 期間指定でダッシュボード統計を計算
  Future<DashboardStatsModel> calculateStatsForPeriod(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    try {
      logInfo(
        "Calculating stats for period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}",
      );

      // 期間内の注文を取得
      final List<Order> orders = await _orderRepository.findByDateRange(startDate, endDate, userId);

      // 完了した注文のみを抽出
      final List<Order> completedOrders = orders
          .where((Order order) => order.status == OrderStatus.completed)
          .toList();

      // アクティブな注文を取得
      final List<Order> activeOrders = await _orderRepository.findActiveOrders(userId);

      // 統計を計算
      final int orderCount = completedOrders.length;
      final double totalRevenue = completedOrders.fold<double>(
        0.0,
        (double sum, Order order) => sum + order.totalAmount.toDouble(),
      );
      final int lowStockItems = await _calculateLowStockItemCount(userId);

      return DashboardStatsModel(
        userId: userId,
        todayOrders: orderCount,
        todayRevenue: totalRevenue,
        activeOrders: activeOrders.length,
        lowStockItems: lowStockItems,
        date: DateTime.now(),
        averageOrderValue: orderCount > 0 ? totalRevenue / orderCount : 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      logError("Failed to calculate stats for period", e, stackTrace);
      rethrow;
    }
  }

  /// 日別統計の比較分析
  Future<Map<String, dynamic>> compareDailyStats(
    DateTime targetDate,
    DateTime comparisonDate,
    String userId,
  ) async {
    try {
      logInfo(
        "Comparing daily stats: ${targetDate.toIso8601String()} vs ${comparisonDate.toIso8601String()}",
      );

      // 両日の統計を取得
      final DashboardStatsModel? targetStats = await _dashboardRepository.getStatsByDate(
        targetDate,
        userId: userId,
      );
      final DashboardStatsModel? comparisonStats = await _dashboardRepository.getStatsByDate(
        comparisonDate,
        userId: userId,
      );

      if (targetStats == null || comparisonStats == null) {
        throw Exception("統計データが見つかりません");
      }

      // 変化率を計算
      final double orderChangeRate = _calculateChangeRate(
        targetStats.todayOrders.toDouble(),
        comparisonStats.todayOrders.toDouble(),
      );
      final double revenueChangeRate = _calculateChangeRate(
        targetStats.todayRevenue,
        comparisonStats.todayRevenue,
      );
      final double avgOrderValueChangeRate = _calculateChangeRate(
        targetStats.currentAverageOrderValue,
        comparisonStats.currentAverageOrderValue,
      );

      return <String, dynamic>{
        "target_date": targetDate.toIso8601String().split("T")[0],
        "comparison_date": comparisonDate.toIso8601String().split("T")[0],
        "target_stats": <String, num>{
          "orders": targetStats.todayOrders,
          "revenue": targetStats.todayRevenue,
          "avg_order_value": targetStats.currentAverageOrderValue,
          "active_orders": targetStats.activeOrders,
        },
        "comparison_stats": <String, num>{
          "orders": comparisonStats.todayOrders,
          "revenue": comparisonStats.todayRevenue,
          "avg_order_value": comparisonStats.currentAverageOrderValue,
          "active_orders": comparisonStats.activeOrders,
        },
        "changes": <String, double>{
          "order_change_rate": orderChangeRate,
          "revenue_change_rate": revenueChangeRate,
          "avg_order_value_change_rate": avgOrderValueChangeRate,
        },
      };
    } catch (e, stackTrace) {
      logError("Failed to compare daily stats", e, stackTrace);
      rethrow;
    }
  }

  /// 週間統計を計算
  Future<Map<String, dynamic>> calculateWeeklyStats(DateTime weekStartDate, String userId) async {
    try {
      final DateTime weekEndDate = weekStartDate.add(const Duration(days: 6));
      logInfo(
        "Calculating weekly stats: ${weekStartDate.toIso8601String()} to ${weekEndDate.toIso8601String()}",
      );

      final List<DashboardStatsModel> weeklyStats = await _dashboardRepository.getStatsByDateRange(
        weekStartDate,
        weekEndDate,
        userId: userId,
      );

      // 日別データを集計
      final Map<String, Map<String, dynamic>> dailyBreakdown = <String, Map<String, dynamic>>{};
      double totalRevenue = 0.0;
      int totalOrders = 0;
      int peakActiveOrders = 0;

      for (final DashboardStatsModel stat in weeklyStats) {
        final String dateKey = stat.date?.toIso8601String().split("T")[0] ?? "unknown";
        dailyBreakdown[dateKey] = <String, dynamic>{
          "orders": stat.todayOrders,
          "revenue": stat.todayRevenue,
          "active_orders": stat.activeOrders,
          "avg_order_value": stat.currentAverageOrderValue,
        };

        totalRevenue += stat.todayRevenue;
        totalOrders += stat.todayOrders;
        if (stat.activeOrders > peakActiveOrders) {
          peakActiveOrders = stat.activeOrders;
        }
      }

      final double avgDailyRevenue = weeklyStats.isNotEmpty ? totalRevenue / 7 : 0.0;
      final double avgDailyOrders = weeklyStats.isNotEmpty ? totalOrders / 7 : 0.0;
      final double avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

      return <String, dynamic>{
        "week_start": weekStartDate.toIso8601String().split("T")[0],
        "week_end": weekEndDate.toIso8601String().split("T")[0],
        "summary": <String, num>{
          "total_revenue": totalRevenue,
          "total_orders": totalOrders,
          "avg_daily_revenue": avgDailyRevenue,
          "avg_daily_orders": avgDailyOrders,
          "avg_order_value": avgOrderValue,
          "peak_active_orders": peakActiveOrders,
        },
        "daily_breakdown": dailyBreakdown,
        "days_with_data": weeklyStats.length,
      };
    } catch (e, stackTrace) {
      logError("Failed to calculate weekly stats", e, stackTrace);
      rethrow;
    }
  }

  /// 月間統計を計算
  Future<Map<String, dynamic>> calculateMonthlyStats(int year, int month, String userId) async {
    try {
      final DateTime monthStart = DateTime(year, month);
      final DateTime monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
      logInfo("Calculating monthly stats for $year-$month");

      final List<DashboardStatsModel> monthlyStats = await _dashboardRepository.getStatsByDateRange(
        monthStart,
        monthEnd,
        userId: userId,
      );

      // 月間集計
      double totalRevenue = 0.0;
      int totalOrders = 0;
      int peakActiveOrders = 0;
      final Map<int, Map<String, dynamic>> weeklyBreakdown = <int, Map<String, dynamic>>{};

      for (final DashboardStatsModel stat in monthlyStats) {
        totalRevenue += stat.todayRevenue;
        totalOrders += stat.todayOrders;
        if (stat.activeOrders > peakActiveOrders) {
          peakActiveOrders = stat.activeOrders;
        }

        // 週別の集計
        if (stat.date != null) {
          final int weekOfYear = _getWeekOfYear(stat.date!);
          weeklyBreakdown[weekOfYear] ??= <String, dynamic>{"revenue": 0.0, "orders": 0, "days": 0};
          weeklyBreakdown[weekOfYear]!["revenue"] =
              (weeklyBreakdown[weekOfYear]!["revenue"] as double) + stat.todayRevenue;
          weeklyBreakdown[weekOfYear]!["orders"] =
              (weeklyBreakdown[weekOfYear]!["orders"] as int) + stat.todayOrders;
          weeklyBreakdown[weekOfYear]!["days"] = (weeklyBreakdown[weekOfYear]!["days"] as int) + 1;
        }
      }

      final int daysInMonth = monthEnd.day;
      final double avgDailyRevenue = daysInMonth > 0 ? totalRevenue / daysInMonth : 0.0;
      final double avgDailyOrders = daysInMonth > 0 ? totalOrders / daysInMonth : 0.0;
      final double avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

      return <String, dynamic>{
        "year": year,
        "month": month,
        "summary": <String, num>{
          "total_revenue": totalRevenue,
          "total_orders": totalOrders,
          "avg_daily_revenue": avgDailyRevenue,
          "avg_daily_orders": avgDailyOrders,
          "avg_order_value": avgOrderValue,
          "peak_active_orders": peakActiveOrders,
          "days_in_month": daysInMonth,
        },
        "weekly_breakdown": weeklyBreakdown,
        "days_with_data": monthlyStats.length,
      };
    } catch (e, stackTrace) {
      logError("Failed to calculate monthly stats", e, stackTrace);
      rethrow;
    }
  }

  /// 統計トレンド分析
  Future<Map<String, dynamic>> analyzeStatsTrend(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    try {
      logInfo(
        "Analyzing stats trend from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}",
      );

      final List<DashboardStatsModel> stats = await _dashboardRepository.getStatsByDateRange(
        startDate,
        endDate,
        userId: userId,
      );

      if (stats.isEmpty) {
        return <String, dynamic>{
          "period_start": startDate.toIso8601String().split("T")[0],
          "period_end": endDate.toIso8601String().split("T")[0],
          "trend_analysis": "データが不足しています",
        };
      }

      // トレンド計算
      final List<double> revenues = stats.map((DashboardStatsModel s) => s.todayRevenue).toList();
      final List<int> orders = stats.map((DashboardStatsModel s) => s.todayOrders).toList();

      final Map<String, dynamic> revenueTrend = _calculateTrend(revenues);
      final Map<String, dynamic> orderTrend = _calculateTrend(
        orders.map((int o) => o.toDouble()).toList(),
      );

      return <String, dynamic>{
        "period_start": startDate.toIso8601String().split("T")[0],
        "period_end": endDate.toIso8601String().split("T")[0],
        "data_points": stats.length,
        "revenue_trend": revenueTrend,
        "order_trend": orderTrend,
        "summary": <String, num>{
          "total_revenue": revenues.reduce((double a, double b) => a + b),
          "total_orders": orders.reduce((int a, int b) => a + b),
          "avg_revenue": revenues.reduce((double a, double b) => a + b) / revenues.length,
          "avg_orders": orders.reduce((int a, int b) => a + b) / orders.length,
        },
      };
    } catch (e, stackTrace) {
      logError("Failed to analyze stats trend", e, stackTrace);
      rethrow;
    }
  }

  /// 在庫不足アイテム数を計算
  Future<int> _calculateLowStockItemCount(String userId) async {
    try {
      final List<Material> lowStockMaterials = await _materialRepository.findBelowAlertThreshold(
        userId,
      );
      return lowStockMaterials.length;
    } catch (e, stackTrace) {
      logError("Failed to calculate low stock item count", e, stackTrace);
      return 0;
    }
  }

  /// 変化率を計算
  double _calculateChangeRate(double current, double previous) {
    if (previous == 0) {
      return 0.0;
    }
    return ((current - previous) / previous) * 100;
  }

  /// 年の週番号を取得
  int _getWeekOfYear(DateTime date) {
    final DateTime firstDayOfYear = DateTime(date.year);
    final int daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday) / 7).ceil();
  }

  /// トレンド分析を実行
  Map<String, dynamic> _calculateTrend(List<double> values) {
    if (values.length < 2) {
      return <String, dynamic>{"direction": "insufficient_data", "slope": 0.0, "correlation": 0.0};
    }

    // 線形回帰で傾きを計算
    final int n = values.length;
    final List<double> x = List<double>.generate(n, (int i) => i.toDouble());

    final double sumX = x.reduce((double a, double b) => a + b);
    final double sumY = values.reduce((double a, double b) => a + b);
    final double sumXY = List<double>.generate(
      n,
      (int i) => x[i] * values[i],
    ).reduce((double a, double b) => a + b);
    final double sumXX = x.map((double v) => v * v).reduce((double a, double b) => a + b);

    final double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);

    String direction;
    if (slope > 0.1) {
      direction = "increasing";
    } else if (slope < -0.1) {
      direction = "decreasing";
    } else {
      direction = "stable";
    }

    return <String, dynamic>{"direction": direction, "slope": slope, "trend_strength": slope.abs()};
  }
}
