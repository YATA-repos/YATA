import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../routing/route_constants.dart";
import "../providers/device_info_provider.dart";
import "../providers/navigation_provider.dart";
import "../widgets/bottom_navigation.dart";
import "../widgets/navigation_rail.dart";

/// タブ付きナビゲーションのScaffold
///
/// StatefulShellRouteと連携してタブベースのナビゲーションを提供します。
/// デバイスサイズに応じてボトムナビゲーションまたはサイドナビゲーションを表示します。
class TabScaffold extends ConsumerWidget {
  const TabScaffold({required this.navigationShell, super.key});

  /// GoRouterのStatefulNavigationShell
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceInfo deviceInfo = ref.watch(deviceInfoProvider);

    // デバイスに応じたレイアウトを選択
    if (deviceInfo.shouldUseSideNavigation) {
      return _buildSideNavigationLayout(context, ref);
    }

    return _buildBottomNavigationLayout(context, ref);
  }

  /// サイドナビゲーション付きレイアウト
  Widget _buildSideNavigationLayout(BuildContext context, WidgetRef ref) => Scaffold(
    body: Row(
      children: <Widget>[
        // サイドナビゲーションレール
        const AppNavigationRail(),

        // 区切り線
        const VerticalDivider(thickness: 1, width: 1),

        // メインコンテンツ
        Expanded(child: _buildMainContent(context, ref)),
      ],
    ),
  );

  /// ボトムナビゲーション付きレイアウト
  Widget _buildBottomNavigationLayout(BuildContext context, WidgetRef ref) => Scaffold(
    body: _buildMainContent(context, ref),
    bottomNavigationBar: const AppBottomNavigation(),
  );

  /// メインコンテンツエリアを構築
  Widget _buildMainContent(BuildContext context, WidgetRef ref) => Column(
    children: <Widget>[
      // アプリバー
      _buildAppBar(context, ref),

      // コンテンツエリア
      Expanded(child: navigationShell),
    ],
  );

  /// アプリバーを構築
  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final NavigationData navigationState = ref.watch(navigationStateProvider);
    final DeviceInfo deviceInfo = ref.watch(deviceInfoProvider);

    return AppBar(
      title: Text(_getAppBarTitle(navigationState.currentTab)),
      centerTitle: !deviceInfo.shouldUseSideNavigation,
      elevation: 0,

      // 戻るボタン（必要な場合）
      leading: _buildLeadingWidget(context, ref),

      // アクションボタン
      actions: _buildAppBarActions(context, ref),
    );
  }

  /// アプリバーのタイトルを取得
  String _getAppBarTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return "YATA - ホーム";
      case 1:
        return "YATA - 在庫管理";
      case 2:
        return "YATA - メニュー";
      case 3:
        return "YATA - 分析";
      case 4:
        return "YATA - 設定";
      default:
        return "YATA";
    }
  }

  /// アプリバーの左側ウィジェットを構築
  Widget? _buildLeadingWidget(BuildContext context, WidgetRef ref) {
    final NavigationData navigationState = ref.watch(navigationStateProvider);

    // 戻るボタンが必要な場合のみ表示
    if (navigationState.canPop && Navigator.of(context).canPop()) {
      return IconButton(
        onPressed: () => _handleBackPress(context, ref),
        icon: const Icon(LucideIcons.arrowLeft),
        tooltip: "戻る",
      );
    }

    return null;
  }

  /// アプリバーのアクションボタンを構築
  List<Widget> _buildAppBarActions(BuildContext context, WidgetRef ref) {
    final NavigationData navigationState = ref.watch(navigationStateProvider);
    final List<Widget> actions = <Widget>[];

    // タブ固有のアクションボタン
    switch (navigationState.currentTab) {
      case 0: // ホーム/注文
        actions.addAll(<Widget>[
          IconButton(
            onPressed: () => context.go(AppRoutes.cart),
            icon: const Icon(LucideIcons.shoppingCart),
            tooltip: "カート",
          ),
          IconButton(
            onPressed: () => context.go(AppRoutes.orderCreate),
            icon: const Icon(LucideIcons.plus),
            tooltip: "新規注文",
          ),
        ]);
        break;

      case 1: // 在庫
        actions.add(
          IconButton(
            onPressed: () => context.go(AppRoutes.purchase),
            icon: const Icon(LucideIcons.packagePlus),
            tooltip: "仕入れ",
          ),
        );
        break;

      case 2: // メニュー
        actions.add(
          IconButton(
            onPressed: () => _showMenuCreateDialog(context),
            icon: const Icon(LucideIcons.plus),
            tooltip: "メニュー追加",
          ),
        );
        break;

      case 3: // 分析
        actions.add(
          IconButton(
            onPressed: () => _showAnalyticsMenu(context),
            icon: const Icon(LucideIcons.filter),
            tooltip: "フィルター",
          ),
        );
        break;

      case 4: // 設定
        actions.add(
          IconButton(
            onPressed: () => context.go(AppRoutes.profile),
            icon: const Icon(LucideIcons.user),
            tooltip: "プロフィール",
          ),
        );
        break;
    }

    // 共通アクション: 通知
    actions.add(
      IconButton(
        onPressed: () => _showNotifications(context),
        icon: const Icon(LucideIcons.bell),
        tooltip: "通知",
      ),
    );

    return actions;
  }

  /// 戻るボタンが押された時の処理
  void _handleBackPress(BuildContext context, WidgetRef ref) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // ナビゲーション履歴がある場合は前のタブに戻る
      final NavigationHistory history = ref.read(navigationHistoryProvider.notifier);
      final int? previousTab = history.pop();
      if (previousTab != null) {
        ref.read(navigationStateProvider.notifier).updateTab(previousTab);
        navigationShell.goBranch(previousTab);
      }
    }
  }

  /// メニュー作成ダイアログを表示
  void _showMenuCreateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("新しいメニューを作成"),
        content: const Text("メニュー作成機能は開発中です。"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("閉じる")),
        ],
      ),
    );
  }

  /// 分析メニューを表示
  void _showAnalyticsMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(LucideIcons.trendingUp),
              title: const Text("売上分析"),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.salesAnalytics);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.package),
              title: const Text("在庫分析"),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.inventoryAnalytics);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 通知を表示
  void _showNotifications(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("通知"),
        content: const Text("新しい通知はありません。"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("閉じる")),
        ],
      ),
    );
  }
}

/// タブナビゲーションのラッパーウィジェット
///
/// StatefulShellRouteのnavigationShellを適切に処理します。
class TabNavigationWrapper extends ConsumerWidget {
  const TabNavigationWrapper({required this.child, required this.tabIndex, super.key});

  final Widget child;
  final int tabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // タブが変更された時にナビゲーション状態を更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final int currentTab = ref.read(navigationStateProvider).currentTab;
      if (currentTab != tabIndex) {
        ref.read(navigationStateProvider.notifier).updateTab(tabIndex);
      }
    });

    return child;
  }
}

/// タブコンテンツのアニメーション付きコンテナ
class AnimatedTabContainer extends StatelessWidget {
  const AnimatedTabContainer({required this.child, required this.isActive, super.key});

  final Widget child;
  final bool isActive;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: isActive ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 200),
    child: AnimatedScale(
      scale: isActive ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: child,
    ),
  );
}
