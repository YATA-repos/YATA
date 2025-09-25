import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/patterns/patterns.dart";

/// 注文履歴のスタブページ。
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  static const String routeName = "/history";

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: YataColorTokens.background,
    appBar: YataAppTopBar(
      navItems: <YataNavItem>[
        YataNavItem(label: "注文", icon: Icons.shopping_cart_outlined, onTap: () => context.go("/")),
        const YataNavItem(label: "履歴", icon: Icons.receipt_long_outlined, isActive: true),
        YataNavItem(
          label: "在庫管理",
          icon: Icons.inventory_2_outlined,
          onTap: () => context.go("/inventory"),
        ),
        const YataNavItem(label: "売上分析", icon: Icons.query_stats_outlined),
      ],
    ),
    body: const YataPageContainer(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(YataSpacingTokens.xl),
          child: Text(
            "履歴画面の準備中です。\nこの後、注文一覧と詳細を実装します。",
            textAlign: TextAlign.center,
            style: YataTypographyTokens.titleMedium,
          ),
        ),
      ),
    ),
  );
}
