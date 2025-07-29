import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../core/constants/constants.dart";
import "../../core/utils/responsive_helper.dart";
import "../themes/app_colors.dart";
import "../themes/app_text_theme.dart";
import "../widgets/navigation/main_navigation.dart";
import "../widgets/navigation/mobile_bottom_navigation.dart";

/// メインレイアウト
///
/// アプリケーション全体の基本レイアウト構造を提供します。
/// レスポンシブ対応で、デスクトップ・タブレット・モバイルに適応します。
class MainLayout extends StatelessWidget {
  const MainLayout({
    required this.child,
    this.title,
    this.actions = const <Widget>[],
    this.showAppBar = true,
    this.showNavigation = true,
    super.key,
  });

  final Widget child;
  final String? title;
  final List<Widget> actions;
  final bool showAppBar;
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.shouldShowSideNavigation(context)) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  /// デスクトップ・タブレット向けレイアウト
  Widget _buildDesktopLayout(BuildContext context) => Scaffold(
    body: Row(
      children: <Widget>[
        // サイドナビゲーション
        if (showNavigation) const SideNavigation(),

        // メインコンテンツエリア
        Expanded(
          child: Column(
            children: <Widget>[
              // アプリバー
              if (showAppBar) _buildDesktopAppBar(context),

              // コンテンツ
              Expanded(child: child),
            ],
          ),
        ),
      ],
    ),
  );

  /// モバイル向けレイアウト
  Widget _buildMobileLayout(BuildContext context) => Scaffold(
    appBar: showAppBar ? _buildMobileAppBar(context) : null,
    body: child,
    bottomNavigationBar: showNavigation ? const MobileBottomNavigation() : null,
  );

  /// デスクトップ用アプリバー
  Widget _buildDesktopAppBar(BuildContext context) => Container(
    height: 60,
    decoration: BoxDecoration(
      color: AppColors.card,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title!,
              style: AppTextTheme.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
          ],

          // アクションボタンエリア
          Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    ),
  );

  /// モバイル用アプリバー
  PreferredSizeWidget _buildMobileAppBar(BuildContext context) => AppBar(
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(LucideIcons.coffee, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          title ?? AppStrings.titleApp,
          style: AppTextTheme.navigationText.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    ),
    backgroundColor: AppColors.card,
    elevation: 1,
    actions: actions,
  );
}
