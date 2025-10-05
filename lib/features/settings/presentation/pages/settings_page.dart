import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/components/buttons/icon_button.dart";
import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/patterns/patterns.dart";

/// 設定画面プレースホルダー。
class SettingsPage extends ConsumerWidget {
  /// [SettingsPage]を生成する。
  const SettingsPage({super.key});

  /// ルート名。
  static const String routeName = "/settings";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: YataColorTokens.background,
      appBar: YataAppTopBar(
        navItems: <YataNavItem>[
          YataNavItem(
            label: "注文",
            icon: Icons.shopping_cart_outlined,
            onTap: () => context.go("/order"),
          ),
          YataNavItem(
            label: "注文状況",
            icon: Icons.dashboard_customize_outlined,
            onTap: () => context.go("/order-status"),
          ),
          YataNavItem(
            label: "履歴",
            icon: Icons.receipt_long_outlined,
            onTap: () => context.go("/history"),
          ),
          YataNavItem(
            label: "在庫管理",
            icon: Icons.inventory_2_outlined,
            onTap: () => context.go("/inventory"),
          ),
          YataNavItem(
            label: "メニュー管理",
            icon: Icons.restaurant_menu_outlined,
            onTap: () => context.go("/menu"),
          ),
          YataNavItem(
            label: "売上分析",
            icon: Icons.query_stats_outlined,
            onTap: () => context.go("/analytics"),
          ),
        ],
        trailing: <Widget>[
          YataIconButton(
            icon: Icons.refresh,
            tooltip: "設定データの再取得 (準備中)",
            onPressed: () => _showRefreshUnavailableMessage(context),
          ),
        ],
      ),
      body: YataPageContainer(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.settings_outlined, size: 72, color: YataColorTokens.textSecondary),
                const SizedBox(height: YataSpacingTokens.lg),
                Text(
                  "設定機能は現在開発中です",
                  style: (textTheme.headlineSmall ?? YataTypographyTokens.headlineSmall).copyWith(
                    color: YataColorTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: YataSpacingTokens.sm),
                Text(
                  "完成まで今しばらくお待ちください。改善のアイデアがあれば、チームまでお気軽にお知らせください。",
                  style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium).copyWith(
                    color: YataColorTokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: YataSpacingTokens.lg),
                FilledButton.icon(
                  onPressed: () => context.go("/order"),
                  icon: const Icon(Icons.arrow_back_ios_new),
                  label: const Text("注文管理に戻る"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 設定データの更新が未提供であることを通知する。
  void _showRefreshUnavailableMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("設定データの再取得は現在準備中です。")),
    );
  }
}
