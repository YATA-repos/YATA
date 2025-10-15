import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/components/buttons/icon_button.dart";
import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/patterns/navigation/app_top_bar.dart";
import "../../../settings/presentation/pages/settings_page.dart";

/// Data Export 画面。
class DataExportPage extends ConsumerWidget {
  const DataExportPage({super.key});

  /// ルート名。
  static const String routeName = "/settings/data-export";

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
            icon: Icons.settings,
            tooltip: "設定",
            onPressed: () => context.go(SettingsPage.routeName),
          ),
        ],
      ),
      body: YataPageContainer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.construction_outlined, size: 48, color: YataColorTokens.warning),
              const SizedBox(height: YataSpacingTokens.md),
              Text(
                "データエクスポート機能は現在開発中です。",
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: YataSpacingTokens.sm),
              Text(
                "アップデートまでしばらくお待ちください。",
                style: textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
