import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../core/constants/constants.dart";
import "../../../core/utils/responsive_helper.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";
import "../../themes/app_text_theme.dart";

/// メインナビゲーションコンポーネント
///
/// 既存のCustomNavigationを拡張し、Go Routerによる画面遷移を提供します。
/// レスポンシブ対応でデスクトップ・タブレット向けのサイドナビゲーションも含みます。
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.shouldShowSideNavigation(context)) {
      return const SideNavigation();
    } else {
      return const TopNavigation();
    }
  }
}

/// トップナビゲーション（モバイル・小画面向け）
class TopNavigation extends StatelessWidget {
  const TopNavigation({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      NavigationItem(
        icon: LucideIcons.home,
        label: AppStrings.navHome,
        route: "/",
        isActive: _isCurrentRoute(context, "/"),
      ),
      const SizedBox(width: 8),
      NavigationItem(
        icon: LucideIcons.history,
        label: AppStrings.navOrderHistory,
        route: "/orders",
        isActive: _isCurrentRoute(context, "/orders"),
      ),
      const SizedBox(width: 8),
      NavigationItem(
        icon: LucideIcons.clipboardList,
        label: AppStrings.navOrderStatus,
        route: "/order-status",
        isActive: _isCurrentRoute(context, "/order-status"),
      ),
      const SizedBox(width: 8),
      NavigationItem(
        icon: LucideIcons.barChart4,
        label: AppStrings.navAnalytics,
        route: "/analytics",
        isActive: _isCurrentRoute(context, "/analytics"),
      ),
      const SizedBox(width: 8),
      NavigationItem(
        icon: LucideIcons.package,
        label: AppStrings.navInventory,
        route: "/inventory",
        isActive: _isCurrentRoute(context, "/inventory"),
      ),
    ],
  );

  bool _isCurrentRoute(BuildContext context, String route) {
    final String currentRoute = GoRouterState.of(context).uri.path;
    return currentRoute == route;
  }
}

/// サイドナビゲーション（デスクトップ・タブレット向け）
class SideNavigation extends ConsumerWidget {
  const SideNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    width: 280,
    decoration: BoxDecoration(
      color: AppColors.card,
      border: Border(right: BorderSide(color: AppColors.border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ヘッダー
        Container(
          padding: AppLayout.paddingMedium,
          child: Row(
            children: <Widget>[
              Icon(LucideIcons.coffee, color: AppColors.primary, size: 32),
              AppLayout.hSpacerDefault,
              Text(
                AppStrings.titleApp,
                style: AppTextTheme.cardTitle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ナビゲーションアイテム
        Expanded(
          child: Padding(
            padding: AppLayout.paddingDefault,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SideNavigationItem(
                  icon: LucideIcons.home,
                  label: AppStrings.navHome,
                  route: "/",
                  isActive: _isCurrentRoute(context, "/"),
                ),
                AppLayout.vSpacerSmall,
                SideNavigationItem(
                  icon: LucideIcons.history,
                  label: AppStrings.navOrderHistory,
                  route: "/orders",
                  isActive: _isCurrentRoute(context, "/orders"),
                ),
                AppLayout.vSpacerSmall,
                SideNavigationItem(
                  icon: LucideIcons.clipboardList,
                  label: AppStrings.navOrderStatus,
                  route: "/order-status",
                  isActive: _isCurrentRoute(context, "/order-status"),
                ),
                AppLayout.vSpacerSmall,
                SideNavigationItem(
                  icon: LucideIcons.barChart4,
                  label: AppStrings.navAnalytics,
                  route: "/analytics",
                  isActive: _isCurrentRoute(context, "/analytics"),
                ),
                AppLayout.vSpacerSmall,
                SideNavigationItem(
                  icon: LucideIcons.package,
                  label: AppStrings.navInventory,
                  route: "/inventory",
                  isActive: _isCurrentRoute(context, "/inventory"),
                ),
              ],
            ),
          ),
        ),

      ],
    ),
  );

  bool _isCurrentRoute(BuildContext context, String route) {
    final String currentRoute = GoRouterState.of(context).uri.path;
    return currentRoute == route;
  }

}

/// ナビゲーションアイテム（トップナビゲーション用）
class NavigationItem extends StatelessWidget {
  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    this.isActive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.go(route),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryHover : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: isActive ? AppColors.primary : AppColors.foreground, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: isActive ? AppTextTheme.navigationTextActive : AppTextTheme.navigationText,
          ),
        ],
      ),
    ),
  );
}

/// サイドナビゲーションアイテム（サイドナビゲーション用）
class SideNavigationItem extends StatelessWidget {
  const SideNavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    this.isActive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.go(route),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryHover : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: isActive ? AppColors.primary : AppColors.foreground, size: 24),
          const SizedBox(width: 16),
          Text(
            label,
            style: isActive ? AppTextTheme.navigationTextActive : AppTextTheme.navigationText,
          ),
        ],
      ),
    ),
  );
}
