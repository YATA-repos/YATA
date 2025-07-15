import "../../../core/utils/logger_mixin.dart";
import "../../auth/models/user_model.dart";
import "../../auth/services/auth_service.dart";
import "../../inventory/models/inventory_model.dart";
import "../../inventory/repositories/material_repository.dart";
import "../../order/models/order_model.dart";
import "../../order/repositories/order_repository.dart";
import "../dto/alert_dto.dart";
import "../dto/dashboard_data_dto.dart";
import "../models/alert_model.dart";
import "../models/dashboard_stats_model.dart";
import "../models/quick_stat_model.dart";
import "../repositories/alert_repository.dart";
import "../repositories/dashboard_repository.dart";

/// ダッシュボードサービス
///
/// ダッシュボードに関するビジネスロジックを提供します。
class DashboardService with LoggerMixin {
  DashboardService({
    required DashboardRepository dashboardRepository,
    required AlertRepository alertRepository,
    required OrderRepository orderRepository,
    required MaterialRepository materialRepository,
    required AuthService authService,
  }) : _dashboardRepository = dashboardRepository,
       _alertRepository = alertRepository,
       _orderRepository = orderRepository,
       _materialRepository = materialRepository,
       _authService = authService;

  final DashboardRepository _dashboardRepository;
  final AlertRepository _alertRepository;
  final OrderRepository _orderRepository;
  final MaterialRepository _materialRepository;
  final AuthService _authService;

  @override
  String get loggerComponent => "DashboardService";

  /// ダッシュボードデータ全体を取得
  Future<DashboardDataDto> getDashboardData() async {
    try {
      logInfo("Starting to retrieve dashboard data");

      // 現在のユーザーを取得
      final UserModel? currentUser = await _authService.getCurrentUser();
      final String? userId = currentUser?.id;

      // 並行してデータを取得
      final Future<DashboardStatsModel> statsFuture = _getOrCreateTodayStats(userId);
      final Future<List<Order>> ordersFuture = _getRecentOrders(userId);
      final Future<List<AlertModel>> alertsFuture = _getActiveAlerts(userId);
      final Future<List<QuickStatModel>> quickStatsFuture = _generateQuickStats(userId);

      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        statsFuture,
        ordersFuture,
        alertsFuture,
        quickStatsFuture,
      ]);

      final DashboardStatsModel stats = results[0] as DashboardStatsModel;
      final List<Order> recentOrders = results[1] as List<Order>;
      final List<AlertModel> alerts = results[2] as List<AlertModel>;
      final List<QuickStatModel> quickStats = results[3] as List<QuickStatModel>;

      logInfo("Successfully retrieved dashboard data");

      return DashboardDataDto(
        stats: stats,
        recentOrders: recentOrders,
        alerts: alerts,
        quickStats: quickStats,
      );
    } catch (e, stackTrace) {
      logError("Failed to retrieve dashboard data", e, stackTrace);
      rethrow;
    }
  }

  /// 本日の統計を取得または作成
  Future<DashboardStatsModel> _getOrCreateTodayStats(String? userId) async {
    try {
      DashboardStatsModel? stats = await _dashboardRepository.getTodayStats(userId: userId);

      if (stats == null) {
        // 本日の統計が存在しない場合は、リアルタイム計算で作成
        stats = await _calculateTodayStats(userId);
        stats = await _dashboardRepository.upsertStats(stats);
      }

      return stats;
    } catch (e, stackTrace) {
      logError("Failed to get or create today's stats", e, stackTrace);
      rethrow;
    }
  }

  /// 本日の統計をリアルタイム計算
  Future<DashboardStatsModel> _calculateTodayStats(String? userId) async {
    try {
      logDebug("Calculating today's statistics");

      // 本日の注文を取得
      final List<Order> todayOrders = await _getTodayOrders(userId);

      // アクティブな注文数を取得
      final List<Order> activeOrders = await _getActiveOrders(userId);

      // 統計を計算
      final int todayOrderCount = todayOrders.length;
      final double todayRevenue = todayOrders.fold<double>(
        0.0,
        (double sum, Order order) => sum + order.totalAmount.toDouble(),
      );
      final int activeOrderCount = activeOrders.length;

      // 前日の統計を取得（比較用）
      final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      final DashboardStatsModel? yesterdayStats = await _dashboardRepository.getStatsByDate(
        yesterday,
        userId: userId,
      );

      return DashboardStatsModel(
        userId: userId,
        todayOrders: todayOrderCount,
        todayRevenue: todayRevenue,
        activeOrders: activeOrderCount,
        lowStockItems: await _calculateLowStockItems(userId),
        date: DateTime.now(),
        previousDayOrders: yesterdayStats?.todayOrders,
        previousDayRevenue: yesterdayStats?.todayRevenue,
        averageOrderValue: todayOrderCount > 0 ? todayRevenue / todayOrderCount : 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      logError("Failed to calculate today's statistics", e, stackTrace);
      rethrow;
    }
  }

  /// 本日の注文を取得
  Future<List<Order>> _getTodayOrders(String? userId) async {
    final DateTime today = DateTime.now();
    final DateTime todayStart = DateTime(today.year, today.month, today.day);
    final DateTime todayEnd = todayStart.add(const Duration(days: 1));

    return _orderRepository.findByDateRange(todayStart, todayEnd, userId ?? "");
  }

  /// アクティブな注文を取得
  Future<List<Order>> _getActiveOrders(String? userId) async =>
      _orderRepository.findActiveOrders(userId ?? "");

  /// 最近の注文を取得
  Future<List<Order>> _getRecentOrders(String? userId, {int limit = 5}) async =>
      _orderRepository.findRecentOrders(userId ?? "", limit: limit);

  /// アクティブなアラートを取得
  Future<List<AlertModel>> _getActiveAlerts(String? userId) async =>
      _alertRepository.getActiveAlerts(userId: userId);

  /// 在庫不足アイテム数を計算
  Future<int> _calculateLowStockItems(String? userId) async {
    try {
      if (userId == null) {
        return 0;
      }

      // アラート閾値以下の材料を取得
      final List<Material> lowStockMaterials = await _materialRepository.findBelowAlertThreshold(
        userId,
      );
      logDebug("Found ${lowStockMaterials.length} low stock items");
      return lowStockMaterials.length;
    } catch (e, stackTrace) {
      logError("Failed to calculate low stock items", e, stackTrace);
      // エラーが発生した場合は0を返す（ダッシュボード表示は継続）
      return 0;
    }
  }

  /// クイック統計を生成
  Future<List<QuickStatModel>> _generateQuickStats(String? userId) async {
    try {
      final List<QuickStatModel> quickStats = <QuickStatModel>[];
      final DashboardStatsModel stats = await _getOrCreateTodayStats(userId);

      // 注文数の変化
      if (stats.ordersChangeRate != null) {
        quickStats.add(
          QuickStatModel(
            userId: userId,
            label: "注文数変化",
            value: "${stats.ordersChangeRate!.toStringAsFixed(1)}%",
            trend: stats.ordersChangeRate! > 0
                ? TrendDirection.up
                : stats.ordersChangeRate! < 0
                ? TrendDirection.down
                : TrendDirection.stable,
            trendPercentage: stats.ordersChangeRate!.abs(),
            displayOrder: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // 売上の変化
      if (stats.revenueChangeRate != null) {
        quickStats.add(
          QuickStatModel(
            userId: userId,
            label: "売上変化",
            value: "${stats.revenueChangeRate!.toStringAsFixed(1)}%",
            trend: stats.revenueChangeRate! > 0
                ? TrendDirection.up
                : stats.revenueChangeRate! < 0
                ? TrendDirection.down
                : TrendDirection.stable,
            trendPercentage: stats.revenueChangeRate!.abs(),
            displayOrder: 2,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // 平均注文金額
      quickStats.add(
        QuickStatModel(
          userId: userId,
          label: "平均注文金額",
          value: stats.currentAverageOrderValue.toStringAsFixed(0),
          trend: TrendDirection.stable,
          unit: "円",
          displayOrder: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      return quickStats;
    } catch (e, stackTrace) {
      logError("Failed to generate quick stats", e, stackTrace);
      return <QuickStatModel>[];
    }
  }

  /// 統計を手動更新
  Future<DashboardStatsModel> refreshStats() async {
    try {
      final UserModel? currentUser = await _authService.getCurrentUser();
      final DashboardStatsModel freshStats = await _calculateTodayStats(currentUser?.id);
      return await _dashboardRepository.upsertStats(freshStats);
    } catch (e, stackTrace) {
      logError("Failed to refresh stats", e, stackTrace);
      rethrow;
    }
  }

  /// アラートを作成
  Future<AlertModel> createAlert(AlertDto alertDto) async {
    try {
      final UserModel? currentUser = await _authService.getCurrentUser();
      final AlertModel alert = alertDto.toModel(userId: currentUser?.id);

      // 同じタイプの重複アラートを削除
      if (currentUser?.id != null) {
        await _alertRepository.removeDuplicateAlerts(alert.type, currentUser!.id!);
      }

      final AlertModel? created = await _alertRepository.create(alert);
      return created ?? alert;
    } catch (e, stackTrace) {
      logError("Failed to create alert", e, stackTrace);
      rethrow;
    }
  }

  /// アラートを既読にマーク
  Future<AlertModel?> markAlertAsRead(String alertId) async {
    try {
      return await _alertRepository.markAsRead(alertId);
    } catch (e, stackTrace) {
      logError("Failed to mark alert as read", e, stackTrace);
      rethrow;
    }
  }

  /// アラートを検索
  Future<List<AlertModel>> searchAlerts(AlertFilterDto filter) async {
    try {
      return await _alertRepository.searchAlerts(filter);
    } catch (e, stackTrace) {
      logError("Failed to search alerts", e, stackTrace);
      rethrow;
    }
  }

  /// システムアラートを自動生成
  Future<void> generateSystemAlerts() async {
    try {
      final UserModel? currentUser = await _authService.getCurrentUser();
      if (currentUser?.id == null) {
        return;
      }

      // 在庫不足アラート
      await _generateLowStockAlert(currentUser!.id!);

      // 長時間待機注文アラート
      await _generateOldOrdersAlert(currentUser.id!);
    } catch (e, stackTrace) {
      logError("Failed to generate system alerts", e, stackTrace);
    }
  }

  /// 在庫不足アラートを生成
  Future<void> _generateLowStockAlert(String userId) async {
    final int lowStockCount = await _calculateLowStockItems(userId);
    if (lowStockCount > 0) {
      final AlertDto alertDto = AlertDto(
        type: "low_stock",
        title: "在庫不足",
        message: "$lowStockCount個のアイテムの在庫が少なくなっています",
        severity: lowStockCount > 5 ? AlertSeverity.error : AlertSeverity.warning,
        actionUrl: "/inventory",
        userId: userId,
      );

      await createAlert(alertDto);
    }
  }

  /// 長時間待機注文アラートを生成
  Future<void> _generateOldOrdersAlert(String userId) async {
    final List<Order> activeOrders = await _getActiveOrders(userId);
    final DateTime now = DateTime.now();
    final List<Order> oldOrders = activeOrders
        .where((Order order) => now.difference(order.orderedAt).inMinutes > 30)
        .toList();

    if (oldOrders.isNotEmpty) {
      final AlertDto alertDto = AlertDto(
        type: "old_orders",
        title: "長時間待機注文",
        message: "${oldOrders.length}件の注文が30分以上待機しています",
        severity: AlertSeverity.warning,
        actionUrl: "/orders",
        userId: userId,
      );

      await createAlert(alertDto);
    }
  }
}
