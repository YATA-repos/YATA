import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/layouts/responsive_padding.dart";
import "../../../../shared/widgets/error_view.dart";
import "../../dto/dashboard_data_dto.dart";
import "../providers/dashboard_providers.dart";
import "../widgets/alerts_section.dart";
import "../widgets/dashboard_header.dart";
import "../widgets/quick_actions_grid.dart";
import "../widgets/recent_orders_section.dart";
import "../widgets/stats_cards_section.dart";

/// ダッシュボード画面
///
/// レストラン運営の中央制御画面を提供します。
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late AnimationController _refreshAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn));

    _fadeAnimationController.forward();

    // 自動更新の設定
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _setupAutoRefresh() {
    // 設定に基づいて自動更新を設定
    ref.listen(dashboardSettingsProvider, (DashboardSettings? previous, DashboardSettings next) {
      if (next.autoRefreshEnabled) {
        // TODO: Timer.periodicで自動更新を実装
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              // ヘッダーセクション
              SliverToBoxAdapter(
                child: ResponsivePadding(
                  child: DashboardHeader(
                    onRefresh: _handleRefresh,
                    isRefreshing: ref.watch(isDashboardRefreshingProvider),
                  ),
                ),
              ),

              // メインコンテンツ
              _buildMainContent(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildMainContent() {
    final AsyncValue<DashboardDataDto> dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      data: _buildDashboardContent,
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()),
        ),
      ),
      error: (Object error, StackTrace stackTrace) => SliverToBoxAdapter(
        child: ResponsivePadding(
          child: ErrorView(message: "ダッシュボードデータの読み込みに失敗しました", onRetry: _handleRefresh),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(DashboardDataDto data) => SliverList(
    delegate: SliverChildListDelegate(<Widget>[
      // クイックアクションセクション
      ResponsivePadding(child: QuickActionsGrid(onActionTap: _handleQuickAction)),

      const ResponsiveVerticalSpacing(compact: 24, medium: 32, expanded: 40),

      // 統計カードセクション
      ResponsivePadding(
        child: StatsCardsSection(stats: data.stats, quickStats: data.quickStats),
      ),

      const ResponsiveVerticalSpacing(compact: 24, medium: 32, expanded: 40),

      // 最近の注文セクション
      ResponsivePadding(
        child: RecentOrdersSection(
          orders: data.recentOrders,
          onViewAll: _navigateToOrders,
          onOrderTap: _handleOrderTap,
        ),
      ),

      const ResponsiveVerticalSpacing(compact: 24, medium: 32, expanded: 40),

      // アラートセクション
      ResponsivePadding(
        child: AlertsSection(
          alerts: data.activeAlerts,
          onAlertTap: _handleAlertTap,
          onMarkAsRead: _handleMarkAlertAsRead,
          onDismiss: _handleDismissAlert,
        ),
      ),

      // 底部スペース
      const ResponsiveVerticalSpacing(compact: 32, medium: 48, expanded: 64),
    ]),
  );

  Widget _buildFloatingActionButton() => FloatingActionButton.extended(
    onPressed: _navigateToOrderCreate,
    icon: const Icon(LucideIcons.plus),
    label: const Text("新規注文"),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
  );

  Future<void> _handleRefresh() async {
    await _refreshAnimationController.repeat();
    try {
      final Future<void> Function() refresh = ref.read(dashboardRefreshProvider);
      await refresh();
    } finally {
      _refreshAnimationController
        ..stop()
        ..reset();
    }
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case "new_order":
        _navigateToOrderCreate();
        break;
      case "cart":
        _navigateToCart();
        break;
      case "inventory":
        _navigateToInventory();
        break;
      case "menu":
        _navigateToMenu();
        break;
      case "analytics":
        _navigateToAnalytics();
        break;
      default:
        _showSnackBar("アクション '$action' は実装されていません");
    }
  }

  void _handleOrderTap(String orderId) {
    Navigator.of(context).pushNamed("/orders/$orderId");
  }

  void _handleAlertTap(String alertId, String? actionUrl) {
    if (actionUrl != null) {
      Navigator.of(context).pushNamed(actionUrl);
    }
  }

  Future<void> _handleMarkAlertAsRead(String alertId) async {
    try {
      final Future<void> Function(String alertId) markAsRead = ref.read(markAlertAsReadProvider);
      await markAsRead(alertId);
      _showSnackBar("アラートを既読にしました");
    } catch (e) {
      _showSnackBar("アラートの更新に失敗しました: $e");
    }
  }

  Future<void> _handleDismissAlert(String alertId) async {
    try {
      final Future<void> Function(String alertId) deactivate = ref.read(deactivateAlertProvider);
      await deactivate(alertId);
      _showSnackBar("アラートを非表示にしました");
    } catch (e) {
      _showSnackBar("アラートの更新に失敗しました: $e");
    }
  }

  void _navigateToOrderCreate() {
    Navigator.of(context).pushNamed("/orders/create");
  }

  void _navigateToCart() {
    Navigator.of(context).pushNamed("/cart");
  }

  void _navigateToInventory() {
    Navigator.of(context).pushNamed("/inventory");
  }

  void _navigateToMenu() {
    Navigator.of(context).pushNamed("/menu");
  }

  void _navigateToAnalytics() {
    Navigator.of(context).pushNamed("/analytics");
  }

  void _navigateToOrders() {
    Navigator.of(context).pushNamed("/orders");
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
