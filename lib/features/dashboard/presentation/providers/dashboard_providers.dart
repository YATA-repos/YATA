import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../auth/models/user_model.dart";
import "../../../auth/presentation/providers/auth_provider.dart";
import "../../../auth/repositories/user_repository.dart";
import "../../../auth/services/auth_service.dart";
import "../../../inventory/repositories/material_repository.dart";
import "../../../order/repositories/order_repository.dart";
import "../../dto/dashboard_data_dto.dart";
import "../../models/alert_model.dart";
import "../../models/dashboard_stats_model.dart";
import "../../repositories/alert_repository.dart";
import "../../repositories/dashboard_repository.dart";
import "../../services/dashboard_service.dart";
import "../../services/statistics_service.dart";

/// ダッシュボードリポジトリプロバイダー
final Provider<DashboardRepository> dashboardRepositoryProvider = Provider<DashboardRepository>(
  (Ref ref) => DashboardRepository(),
);

/// アラートリポジトリプロバイダー
final Provider<AlertRepository> alertRepositoryProvider = Provider<AlertRepository>(
  (Ref ref) => AlertRepository(),
);

/// ユーザーリポジトリプロバイダー
final Provider<UserRepository> userRepositoryProvider = Provider<UserRepository>(
  (Ref ref) => UserRepository(),
);

/// 注文リポジトリプロバイダー
final Provider<OrderRepository> orderRepositoryProvider = Provider<OrderRepository>(
  (Ref ref) => OrderRepository(),
);

/// 材料リポジトリプロバイダー
final Provider<MaterialRepository> materialRepositoryProvider = Provider<MaterialRepository>(
  (Ref ref) => MaterialRepository(),
);

/// 認証サービスプロバイダー
final Provider<AuthService> authServiceProvider2 = Provider<AuthService>(
  (Ref ref) => AuthService(
    supabaseAuthService: ref.read(authServiceProvider),
    userRepository: ref.read(userRepositoryProvider),
  ),
);

/// ダッシュボードサービスプロバイダー
final Provider<DashboardService> dashboardServiceProvider = Provider<DashboardService>(
  (Ref ref) => DashboardService(
    dashboardRepository: ref.read(dashboardRepositoryProvider),
    alertRepository: ref.read(alertRepositoryProvider),
    orderRepository: ref.read(orderRepositoryProvider),
    materialRepository: ref.read(materialRepositoryProvider),
    authService: ref.read(authServiceProvider2),
  ),
);

/// 統計サービスプロバイダー
final Provider<StatisticsService> statisticsServiceProvider = Provider<StatisticsService>(
  (Ref ref) => StatisticsService(
    dashboardRepository: ref.read(dashboardRepositoryProvider),
    orderRepository: ref.read(orderRepositoryProvider),
    materialRepository: ref.read(materialRepositoryProvider),
  ),
);

/// 現在のユーザーIDプロバイダー
final FutureProvider<String> currentUserIdProvider = FutureProvider<String>((Ref ref) async {
  final AuthService authService = ref.read(authServiceProvider2);
  final UserModel? user = await authService.getCurrentUser();
  return user?.id ?? "";
});

/// ダッシュボードデータプロバイダー
final FutureProvider<DashboardDataDto> dashboardDataProvider = FutureProvider<DashboardDataDto>((
  Ref ref,
) async {
  final DashboardService dashboardService = ref.read(dashboardServiceProvider);
  return dashboardService.getDashboardData();
});

/// 今日の統計プロバイダー
final FutureProvider<DashboardStatsModel> todayStatsProvider = FutureProvider<DashboardStatsModel>((
  Ref ref,
) async {
  final DashboardService dashboardService = ref.read(dashboardServiceProvider);
  return dashboardService.refreshStats();
});

/// アクティブアラートプロバイダー
final FutureProvider<List<AlertModel>> activeAlertsProvider = FutureProvider<List<AlertModel>>((
  Ref ref,
) async {
  final AlertRepository alertRepository = ref.read(alertRepositoryProvider);
  return alertRepository.getActiveAlerts();
});

/// 未読アラートプロバイダー
final FutureProvider<List<AlertModel>> unreadAlertsProvider = FutureProvider<List<AlertModel>>((
  Ref ref,
) async {
  final AlertRepository alertRepository = ref.read(alertRepositoryProvider);
  return alertRepository.getUnreadAlerts();
});

/// 重要度別アラート数プロバイダー
final FutureProvider<Map<AlertSeverity, int>> alertCountBySeverityProvider =
    FutureProvider<Map<AlertSeverity, int>>((Ref ref) async {
      final AlertRepository alertRepository = ref.read(alertRepositoryProvider);
      return alertRepository.getAlertCountBySeverity();
    });

/// 週間統計プロバイダー
final FutureProviderFamily<Map<String, dynamic>, DateTime> weeklyStatsProvider =
    FutureProvider.family<Map<String, dynamic>, DateTime>((Ref ref, DateTime weekStart) async {
      final StatisticsService statisticsService = ref.read(statisticsServiceProvider);
      final String userId = await ref.read(currentUserIdProvider.future);
      return statisticsService.calculateWeeklyStats(weekStart, userId);
    });

/// 月間統計プロバイダー
final FutureProviderFamily<Map<String, dynamic>, ({int month, int year})> monthlyStatsProvider =
    FutureProvider.family<Map<String, dynamic>, ({int year, int month})>((
      Ref ref,
      ({int month, int year}) params,
    ) async {
      final StatisticsService statisticsService = ref.read(statisticsServiceProvider);
      final String userId = await ref.read(currentUserIdProvider.future);
      return statisticsService.calculateMonthlyStats(params.year, params.month, userId);
    });

/// 統計比較プロバイダー
final FutureProviderFamily<Map<String, dynamic>, ({DateTime comparison, DateTime target})>
statsComparisonProvider =
    FutureProvider.family<Map<String, dynamic>, ({DateTime target, DateTime comparison})>((
      Ref ref,
      ({DateTime comparison, DateTime target}) params,
    ) async {
      final StatisticsService statisticsService = ref.read(statisticsServiceProvider);
      final String userId = await ref.read(currentUserIdProvider.future);
      return statisticsService.compareDailyStats(params.target, params.comparison, userId);
    });

/// ダッシュボード更新中フラグ
final StateProvider<bool> isDashboardRefreshingProvider = StateProvider<bool>((Ref ref) => false);

/// 選択中のアラートフィルター
final StateProvider<AlertSeverity?> selectedAlertFilterProvider = StateProvider<AlertSeverity?>(
  (Ref ref) => null,
);

/// ダッシュボード表示期間
final StateProvider<int> dashboardPeriodProvider = StateProvider<int>((Ref ref) => 7); // デフォルト7日

/// 手動でダッシュボードを更新するメソッド
final Provider<Future<void> Function()> dashboardRefreshProvider =
    Provider<Future<void> Function()>(
      (Ref ref) => () async {
        ref.read(isDashboardRefreshingProvider.notifier).state = true;
        try {
          // データを再取得
          ref
            ..invalidate(dashboardDataProvider)
            ..invalidate(todayStatsProvider)
            ..invalidate(activeAlertsProvider)
            ..invalidate(unreadAlertsProvider)
            ..invalidate(alertCountBySeverityProvider);

          // 統計を手動更新
          final DashboardService dashboardService = ref.read(dashboardServiceProvider);
          await dashboardService.refreshStats();

          // システムアラートを生成
          await dashboardService.generateSystemAlerts();
        } finally {
          ref.read(isDashboardRefreshingProvider.notifier).state = false;
        }
      },
    );

/// アラートを既読にマークするメソッド
final Provider<Future<void> Function(String alertId)> markAlertAsReadProvider =
    Provider<Future<void> Function(String alertId)>(
      (Ref ref) => (String alertId) async {
        final DashboardService dashboardService = ref.read(dashboardServiceProvider);
        await dashboardService.markAlertAsRead(alertId);

        // アラート関連のプロバイダーを更新
        ref
          ..invalidate(activeAlertsProvider)
          ..invalidate(unreadAlertsProvider)
          ..invalidate(dashboardDataProvider);
      },
    );

/// 複数アラートを一括既読にマークするメソッド
final Provider<Future<void> Function(List<String> alertIds)> markMultipleAlertsAsReadProvider =
    Provider<Future<void> Function(List<String> alertIds)>(
      (Ref ref) => (List<String> alertIds) async {
        final AlertRepository alertRepository = ref.read(alertRepositoryProvider);
        await alertRepository.markMultipleAsRead(alertIds);

        // アラート関連のプロバイダーを更新
        ref
          ..invalidate(activeAlertsProvider)
          ..invalidate(unreadAlertsProvider)
          ..invalidate(dashboardDataProvider);
      },
    );

/// アラートを非アクティブにするメソッド
final Provider<Future<void> Function(String alertId)> deactivateAlertProvider =
    Provider<Future<void> Function(String alertId)>(
      (Ref ref) => (String alertId) async {
        final AlertRepository alertRepository = ref.read(alertRepositoryProvider);
        await alertRepository.deactivateAlert(alertId);

        // アラート関連のプロバイダーを更新
        ref
          ..invalidate(activeAlertsProvider)
          ..invalidate(unreadAlertsProvider)
          ..invalidate(dashboardDataProvider);
      },
    );

/// 統計トレンド分析プロバイダー
final FutureProviderFamily<Map<String, dynamic>, ({DateTime end, DateTime start})>
statsTrendProvider = FutureProvider.family<Map<String, dynamic>, ({DateTime start, DateTime end})>((
  Ref ref,
  ({DateTime end, DateTime start}) params,
) async {
  final StatisticsService statisticsService = ref.read(statisticsServiceProvider);
  final String userId = await ref.read(currentUserIdProvider.future);
  return statisticsService.analyzeStatsTrend(params.start, params.end, userId);
});

/// ダッシュボード設定プロバイダー
final StateNotifierProvider<DashboardSettingsNotifier, DashboardSettings>
dashboardSettingsProvider = StateNotifierProvider<DashboardSettingsNotifier, DashboardSettings>(
  (Ref ref) => DashboardSettingsNotifier(),
);

/// ダッシュボード設定クラス
class DashboardSettings {
  const DashboardSettings({
    this.autoRefreshEnabled = true,
    this.autoRefreshInterval = 30, // 秒
    this.showTrends = true,
    this.showQuickStats = true,
    this.maxRecentOrders = 5,
    this.defaultPeriodDays = 7,
  });

  final bool autoRefreshEnabled;
  final int autoRefreshInterval;
  final bool showTrends;
  final bool showQuickStats;
  final int maxRecentOrders;
  final int defaultPeriodDays;

  DashboardSettings copyWith({
    bool? autoRefreshEnabled,
    int? autoRefreshInterval,
    bool? showTrends,
    bool? showQuickStats,
    int? maxRecentOrders,
    int? defaultPeriodDays,
  }) => DashboardSettings(
    autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
    autoRefreshInterval: autoRefreshInterval ?? this.autoRefreshInterval,
    showTrends: showTrends ?? this.showTrends,
    showQuickStats: showQuickStats ?? this.showQuickStats,
    maxRecentOrders: maxRecentOrders ?? this.maxRecentOrders,
    defaultPeriodDays: defaultPeriodDays ?? this.defaultPeriodDays,
  );
}

/// ダッシュボード設定ノティファイアー
class DashboardSettingsNotifier extends StateNotifier<DashboardSettings> {
  DashboardSettingsNotifier() : super(const DashboardSettings());

  void updateAutoRefresh(bool enabled) {
    state = state.copyWith(autoRefreshEnabled: enabled);
  }

  void updateRefreshInterval(int seconds) {
    state = state.copyWith(autoRefreshInterval: seconds);
  }

  void updateShowTrends(bool show) {
    state = state.copyWith(showTrends: show);
  }

  void updateShowQuickStats(bool show) {
    state = state.copyWith(showQuickStats: show);
  }

  void updateMaxRecentOrders(int max) {
    state = state.copyWith(maxRecentOrders: max);
  }

  void updateDefaultPeriod(int days) {
    state = state.copyWith(defaultPeriodDays: days);
  }
}
