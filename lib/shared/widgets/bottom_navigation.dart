import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../routing/route_constants.dart";
import "../providers/navigation_provider.dart";

/// アプリケーションのボトムナビゲーションバー
///
/// 5つのメインタブ（ホーム、在庫、メニュー、分析、設定）を提供します。
class AppBottomNavigation extends ConsumerWidget {
  const AppBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(navigationStateProvider).currentTab;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (int index) => _onDestinationSelected(context, ref, index),
      destinations: _buildDestinations(context),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 8,
      height: 80,
    );
  }

  /// ナビゲーション先が選択された時の処理
  void _onDestinationSelected(BuildContext context, WidgetRef ref, int index) {
    // 現在のタブと同じ場合は何もしない（重複タップの防止）
    final int currentIndex = ref.read(navigationStateProvider).currentTab;
    if (currentIndex == index) {
      return;
    }

    // タブ状態を更新
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
  List<NavigationDestination> _buildDestinations(BuildContext context) => <NavigationDestination>[
    const NavigationDestination(
      icon: Icon(LucideIcons.home),
      selectedIcon: Icon(LucideIcons.home),
      label: "ホーム",
      tooltip: "ホーム・注文管理",
    ),
    const NavigationDestination(
      icon: Icon(LucideIcons.package),
      selectedIcon: Icon(LucideIcons.package),
      label: "在庫",
      tooltip: "在庫管理",
    ),
    const NavigationDestination(
      icon: Icon(LucideIcons.menuSquare),
      selectedIcon: Icon(LucideIcons.menuSquare),
      label: "メニュー",
      tooltip: "メニュー管理",
    ),
    const NavigationDestination(
      icon: Icon(LucideIcons.barChart3),
      selectedIcon: Icon(LucideIcons.barChart3),
      label: "分析",
      tooltip: "売上・在庫分析",
    ),
    const NavigationDestination(
      icon: Icon(LucideIcons.settings),
      selectedIcon: Icon(LucideIcons.settings),
      label: "設定",
      tooltip: "アプリ設定",
    ),
  ];
}

/// レガシー用のBottomNavigationBar（Material 2スタイル）
class LegacyBottomNavigation extends ConsumerWidget {
  const LegacyBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(navigationStateProvider).currentTab;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (int index) => _onTap(context, ref, index),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: _buildBottomNavItems(),
    );
  }

  /// タブがタップされた時の処理
  void _onTap(BuildContext context, WidgetRef ref, int index) {
    final int currentIndex = ref.read(navigationStateProvider).currentTab;
    if (currentIndex == index) {
      return;
    }

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

  /// BottomNavigationBarItemのリストを構築
  List<BottomNavigationBarItem> _buildBottomNavItems() => const <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(LucideIcons.home),
      activeIcon: Icon(LucideIcons.home),
      label: "ホーム",
      tooltip: "ホーム・注文管理",
    ),
    BottomNavigationBarItem(
      icon: Icon(LucideIcons.package),
      activeIcon: Icon(LucideIcons.package),
      label: "在庫",
      tooltip: "在庫管理",
    ),
    BottomNavigationBarItem(
      icon: Icon(LucideIcons.menuSquare),
      activeIcon: Icon(LucideIcons.menuSquare),
      label: "メニュー",
      tooltip: "メニュー管理",
    ),
    BottomNavigationBarItem(
      icon: Icon(LucideIcons.barChart3),
      activeIcon: Icon(LucideIcons.barChart3),
      label: "分析",
      tooltip: "売上・在庫分析",
    ),
    BottomNavigationBarItem(
      icon: Icon(LucideIcons.settings),
      activeIcon: Icon(LucideIcons.settings),
      label: "設定",
      tooltip: "アプリ設定",
    ),
  ];
}

/// カスタムナビゲーションタブ
class CustomNavigationTab extends StatefulWidget {
  const CustomNavigationTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
    super.key,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  State<CustomNavigationTab> createState() => _CustomNavigationTabState();
}

class _CustomNavigationTabState extends State<CustomNavigationTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _animationController.forward(),
    onTapUp: (_) => _animationController.reverse(),
    onTapCancel: () => _animationController.reverse(),
    onTap: widget.onTap,
    child: AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (BuildContext context, Widget? child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // アイコンとバッジ
            Stack(
              children: <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.isSelected ? widget.selectedIcon : widget.icon,
                    key: ValueKey<bool>(widget.isSelected),
                    color: widget.isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                if (widget.badge != null) Positioned(right: 0, top: 0, child: widget.badge!),
              ],
            ),

            const SizedBox(height: 4),

            // ラベル
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// ナビゲーションバッジ
class NavigationBadge extends StatelessWidget {
  const NavigationBadge({this.count = 0, this.showDot = false, super.key});

  final int count;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    if (!showDot && count <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: showDot ? 8 : null,
      height: showDot ? 8 : 16,
      constraints: showDot ? null : const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(showDot ? 4 : 8),
      ),
      child: showDot
          ? null
          : Center(
              child: Text(
                count > 99 ? "99+" : count.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
