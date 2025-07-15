import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../routing/route_constants.dart";
import "../providers/navigation_provider.dart";

/// サイドナビゲーションレールを提供するウィジェット
///
/// タブレット横向きやデスクトップで使用されます。
class AppNavigationRail extends ConsumerWidget {
  const AppNavigationRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(navigationStateProvider).currentTab;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: (int index) => _onDestinationSelected(context, ref, index),
      labelType: NavigationRailLabelType.selected,
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: _buildDestinations(),
      leading: _buildLeading(context),
      trailing: _buildTrailing(context, ref),
    );
  }

  /// ナビゲーション先が選択された時の処理
  void _onDestinationSelected(BuildContext context, WidgetRef ref, int index) {
    // タブインデックスを更新
    ref.read(navigationStateProvider.notifier).updateTab(index);

    // 対応するルートに移動
    final String route = _getRouteForIndex(index);
    context.go(route);
  }

  /// インデックスに対応するルートを取得
  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return AppRoutes.home;
      case 1:
        return AppRoutes.inventory;
      case 2:
        return AppRoutes.menu;
      case 3:
        return AppRoutes.analytics;
      case 4:
        return AppRoutes.settings;
      default:
        return AppRoutes.home;
    }
  }

  /// ナビゲーション先のリストを構築
  List<NavigationRailDestination> _buildDestinations() => const <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(LucideIcons.home),
      selectedIcon: Icon(LucideIcons.home),
      label: Text("ホーム"),
    ),
    NavigationRailDestination(
      icon: Icon(LucideIcons.package),
      selectedIcon: Icon(LucideIcons.package),
      label: Text("在庫"),
    ),
    NavigationRailDestination(
      icon: Icon(LucideIcons.menuSquare),
      selectedIcon: Icon(LucideIcons.menuSquare),
      label: Text("メニュー"),
    ),
    NavigationRailDestination(
      icon: Icon(LucideIcons.barChart3),
      selectedIcon: Icon(LucideIcons.barChart3),
      label: Text("分析"),
    ),
    NavigationRailDestination(
      icon: Icon(LucideIcons.settings),
      selectedIcon: Icon(LucideIcons.settings),
      label: Text("設定"),
    ),
  ];

  /// ナビゲーションレールの上部に表示するウィジェット
  Widget _buildLeading(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: <Widget>[
        // アプリアイコン
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(LucideIcons.store, color: Theme.of(context).colorScheme.onPrimary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          "YATA",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  /// ナビゲーションレールの下部に表示するウィジェット
  Widget _buildTrailing(BuildContext context, WidgetRef ref) => Expanded(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ヘルプボタン
            IconButton(
              onPressed: () => _showHelpDialog(context),
              icon: const Icon(LucideIcons.helpCircle),
              tooltip: "ヘルプ",
            ),
            const SizedBox(height: 8),

            // ログアウトボタン
            IconButton(
              onPressed: () => _showLogoutDialog(context, ref),
              icon: const Icon(LucideIcons.logOut),
              tooltip: "ログアウト",
            ),
          ],
        ),
      ),
    ),
  );

  /// ヘルプダイアログを表示
  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("ヘルプ"),
        content: const Text(
          "YATAは小規模レストラン向けの在庫・注文管理システムです。\n\n"
          "各タブから以下の機能をご利用いただけます：\n"
          "• ホーム：注文管理\n"
          "• 在庫：材料管理\n"
          "• メニュー：メニュー編集\n"
          "• 分析：売上・在庫分析\n"
          "• 設定：アプリ設定",
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("閉じる")),
        ],
      ),
    );
  }

  /// ログアウト確認ダイアログを表示
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("ログアウト"),
        content: const Text("ログアウトしますか？"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("キャンセル")),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 認証Providerからサインアウト処理を呼び出し
              // ref.read(authStateProvider.notifier).signOut();
            },
            child: const Text("ログアウト"),
          ),
        ],
      ),
    );
  }
}

/// コンパクトナビゲーションレール（アイコンのみ）
class CompactNavigationRail extends ConsumerWidget {
  const CompactNavigationRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(navigationStateProvider).currentTab;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: (int index) => _onDestinationSelected(context, ref, index),
      labelType: NavigationRailLabelType.none,
      backgroundColor: Theme.of(context).colorScheme.surface,
      minWidth: 56,
      destinations: _buildCompactDestinations(),
      leading: _buildCompactLeading(context),
    );
  }

  /// ナビゲーション先が選択された時の処理
  void _onDestinationSelected(BuildContext context, WidgetRef ref, int index) {
    ref.read(navigationStateProvider.notifier).updateTab(index);
    final String route = _getRouteForIndex(index);
    context.go(route);
  }

  /// インデックスに対応するルートを取得
  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return AppRoutes.home;
      case 1:
        return AppRoutes.inventory;
      case 2:
        return AppRoutes.menu;
      case 3:
        return AppRoutes.analytics;
      case 4:
        return AppRoutes.settings;
      default:
        return AppRoutes.home;
    }
  }

  /// コンパクトなナビゲーション先のリストを構築
  List<NavigationRailDestination> _buildCompactDestinations() => const <NavigationRailDestination>[
    NavigationRailDestination(icon: Icon(LucideIcons.home), label: Text("")),
    NavigationRailDestination(icon: Icon(LucideIcons.package), label: Text("")),
    NavigationRailDestination(icon: Icon(LucideIcons.menuSquare), label: Text("")),
    NavigationRailDestination(icon: Icon(LucideIcons.barChart3), label: Text("")),
    NavigationRailDestination(icon: Icon(LucideIcons.settings), label: Text("")),
  ];

  /// コンパクトなアプリアイコンを構築
  Widget _buildCompactLeading(BuildContext context) => Container(
    width: 32,
    height: 32,
    margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Icon(LucideIcons.store, color: Theme.of(context).colorScheme.onPrimary, size: 20),
  );
}
