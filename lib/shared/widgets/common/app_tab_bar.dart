import "package:flutter/material.dart";

import "../../constants/app_constants.dart";
import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTabBar({
    required this.tabs,
    super.key,
    this.controller,
    this.variant = TabBarVariant.standard,
    this.isScrollable = false,
    this.onTap,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorWeight = 2.0,
  });

  final List<Widget> tabs;
  final TabController? controller;
  final TabBarVariant variant;
  final bool isScrollable;
  final ValueChanged<int>? onTap;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final double indicatorWeight;

  @override
  Widget build(BuildContext context) {
    final _TabBarStyle tabBarStyle = _getTabBarStyle();

    return AnimatedContainer(
      duration: AppConstants.animationFast,
      curve: AppConstants.defaultCurve,
      decoration: _buildDecoration(tabBarStyle),
      child: TabBar(
        controller: controller,
        tabs: tabs,
        isScrollable: isScrollable,
        onTap: onTap,
        indicator: _buildIndicator(tabBarStyle),
        labelColor: labelColor ?? tabBarStyle.labelColor,
        unselectedLabelColor: unselectedLabelColor ?? tabBarStyle.unselectedLabelColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: variant == TabBarVariant.underlined
            ? tabBarStyle.dividerColor
            : Colors.transparent,
        indicatorWeight: indicatorWeight,
        labelPadding: EdgeInsets.symmetric(
          horizontal: AppLayout.spacing4,
          vertical: AppLayout.spacing2,
        ),
        padding: variant == TabBarVariant.pills ? AppLayout.padding2 : EdgeInsets.zero,
      ),
    );
  }

  BoxDecoration? _buildDecoration(_TabBarStyle tabBarStyle) {
    switch (variant) {
      case TabBarVariant.contained:
        return BoxDecoration(
          color: tabBarStyle.backgroundColor,
          borderRadius: AppLayout.radiusMd,
          border: Border.all(color: tabBarStyle.borderColor),
        );
      case TabBarVariant.pills:
        return BoxDecoration(color: tabBarStyle.backgroundColor, borderRadius: AppLayout.radiusLg);
      case TabBarVariant.standard:
      case TabBarVariant.underlined:
        return null;
    }
  }

  Decoration? _buildIndicator(_TabBarStyle tabBarStyle) {
    switch (variant) {
      case TabBarVariant.standard:
      case TabBarVariant.underlined:
        return UnderlineTabIndicator(
          borderSide: BorderSide(
            color: indicatorColor ?? tabBarStyle.indicatorColor,
            width: indicatorWeight,
          ),
          insets: EdgeInsets.symmetric(horizontal: AppLayout.spacing2),
        );
      case TabBarVariant.pills:
        return BoxDecoration(color: tabBarStyle.indicatorColor, borderRadius: AppLayout.radiusMd);
      case TabBarVariant.contained:
        return BoxDecoration(color: tabBarStyle.indicatorColor, borderRadius: AppLayout.radiusSm);
    }
  }

  _TabBarStyle _getTabBarStyle() {
    switch (variant) {
      case TabBarVariant.standard:
        return _TabBarStyle(
          backgroundColor: AppColors.background,
          borderColor: AppColors.border,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedForeground,
          dividerColor: AppColors.border,
        );
      case TabBarVariant.underlined:
        return _TabBarStyle(
          backgroundColor: AppColors.background,
          borderColor: AppColors.border,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.foreground,
          unselectedLabelColor: AppColors.mutedForeground,
          dividerColor: AppColors.border,
        );
      case TabBarVariant.pills:
        return _TabBarStyle(
          backgroundColor: AppColors.muted,
          borderColor: Colors.transparent,
          indicatorColor: AppColors.background,
          labelColor: AppColors.foreground,
          unselectedLabelColor: AppColors.mutedForeground,
          dividerColor: Colors.transparent,
        );
      case TabBarVariant.contained:
        return _TabBarStyle(
          backgroundColor: AppColors.background,
          borderColor: AppColors.border,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryForeground,
          unselectedLabelColor: AppColors.mutedForeground,
          dividerColor: Colors.transparent,
        );
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(AppLayout.tabBarHeight);
}

class _TabBarStyle {
  const _TabBarStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.indicatorColor,
    required this.labelColor,
    required this.unselectedLabelColor,
    required this.dividerColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color indicatorColor;
  final Color labelColor;
  final Color unselectedLabelColor;
  final Color dividerColor;
}
