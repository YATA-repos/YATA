import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/themes/app_colors.dart";
import "current_order_panel.dart";
import "menu_selection_panel.dart";

/// オーダー作成モードビュー
///
/// メニュー選択とカート管理を提供する
/// レスポンシブ対応でデスクトップとモバイルで異なるレイアウト
class OrderModeView extends ConsumerWidget {
  const OrderModeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ResponsiveHelper.shouldShowSideNavigation(context)) {
      return _buildDesktopLayout(context, ref);
    } else {
      return _buildMobileLayout(context, ref);
    }
  }

  /// デスクトップレイアウト（横並び）
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) => Row(
    children: <Widget>[
      // メニュー選択パネル（左側）
      const Expanded(flex: 2, child: MenuSelectionPanel()),

      // 区切り線
      Container(width: 1, color: AppColors.border),

      // 現在の注文パネル（右側）
      const Expanded(child: CurrentOrderPanel()),
    ],
  );

  /// モバイルレイアウト（タブ切り替え）
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: Column(
      children: <Widget>[
        // タブバー
        Container(
          color: AppColors.card,
          child: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.primary,
            tabs: const <Widget>[
              Tab(icon: Icon(LucideIcons.coffee), text: "メニュー"),
              Tab(icon: Icon(LucideIcons.shoppingCart), text: "注文"),
            ],
          ),
        ),

        // タブコンテンツ
        Expanded(child: TabBarView(children: <Widget>[MenuSelectionPanel(), CurrentOrderPanel()])),
      ],
    ),
  );
}
