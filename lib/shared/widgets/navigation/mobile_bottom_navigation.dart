import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../core/constants/constants.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";

/// モバイル向けボトムナビゲーションバー
///
/// ResponsiveHelperと連携してモバイルデバイスでのみ表示されます。
/// 既存のテーマシステムを活用してデザインの一貫性を保ちます。
class MobileBottomNavigation extends StatelessWidget {
  const MobileBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentRoute = GoRouterState.of(context).uri.path;

    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(currentRoute),
      onTap: (int index) => _onTabTapped(context, index),
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.mutedForeground,
      selectedLabelStyle: AppTextTheme.mobileNavTextActive,
      unselectedLabelStyle: AppTextTheme.mobileNavText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: AppStrings.navHome),
        BottomNavigationBarItem(icon: Icon(LucideIcons.history), label: AppStrings.navOrderHistory),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.clipboardList),
          label: AppStrings.navOrderStatus,
        ),
        BottomNavigationBarItem(icon: Icon(LucideIcons.barChart4), label: AppStrings.navAnalytics),
        BottomNavigationBarItem(icon: Icon(LucideIcons.utensils), label: AppStrings.navMenu),
      ],
    );
  }

  int _getCurrentIndex(String currentRoute) => switch (currentRoute) {
    "/" => 0,
    "/orders" => 1,
    "/order-status" => 2,
    "/analytics" => 3,
    "/menu" => 4,
    _ => 0,
  };

  void _onTabTapped(BuildContext context, int index) {
    final String route = switch (index) {
      0 => "/",
      1 => "/orders",
      2 => "/order-status",
      3 => "/analytics",
      4 => "/menu",
      _ => "/",
    };
    context.go(route);
  }
}
