import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";
import "app_card.dart";

/// StatsCard - 業務統計表示カード
///
/// 既存のAppColors業務固有色・AppTextThemeを活用し、
/// 売上・在庫・注文数等の業務統計を表示する専用カードです。
class StatsCard extends StatelessWidget {
  const StatsCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.variant = StatsCardVariant.default_,
    this.trend,
    this.trendValue,
    this.trendDirection,
    this.onTap,
    this.isLoading = false,
    super.key,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final StatsCardVariant variant;
  final Widget? trend;
  final String? trendValue;
  final TrendDirection? trendDirection;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: _getCardVariant(),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ヘッダー行（タイトル・アイコン・トレンド）
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: _getVariantColor(), size: 24),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: AppTextTheme.cardTitle.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trend != null) trend!,
            if (trendValue != null && trendDirection != null) ...<Widget>[_buildTrendIndicator()],
          ],
        ),

        const SizedBox(height: 12),

        // メイン値表示
        if (isLoading) ...<Widget>[
          Container(
            height: 32,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ] else ...<Widget>[
          Text(value, style: AppTextTheme.priceLarge.copyWith(color: _getValueColor())),
        ],

        // サブタイトル
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(subtitle!, style: AppTextTheme.cardDescription),
        ],
      ],
    ),
  );

  Widget _buildTrendIndicator() {
    final Color trendColor = _getTrendColor();
    final IconData trendIcon = _getTrendIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(trendIcon, size: 12, color: trendColor),
          const SizedBox(width: 2),
          Text(
            trendValue!,
            style: AppTextTheme.cardDescription.copyWith(
              color: trendColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  CardVariant _getCardVariant() => switch (variant) {
    StatsCardVariant.default_ => CardVariant.default_,
    StatsCardVariant.success => CardVariant.success,
    StatsCardVariant.warning => CardVariant.warning,
    StatsCardVariant.danger => CardVariant.danger,
    StatsCardVariant.info => CardVariant.primary,
    StatsCardVariant.stock => CardVariant.success,
    StatsCardVariant.lowStock => CardVariant.warning,
    StatsCardVariant.sales => CardVariant.success,
  };

  Color _getVariantColor() => switch (variant) {
    StatsCardVariant.default_ => AppColors.primary,
    StatsCardVariant.success => AppColors.success,
    StatsCardVariant.warning => AppColors.warning,
    StatsCardVariant.danger => AppColors.danger,
    StatsCardVariant.info => AppColors.primary,
    // 業務固有色活用
    StatsCardVariant.stock => AppColors.inStock,
    StatsCardVariant.lowStock => AppColors.lowStock,
    StatsCardVariant.sales => AppColors.success,
  };

  Color _getValueColor() => switch (variant) {
    StatsCardVariant.default_ => AppColors.foreground,
    StatsCardVariant.success => AppColors.success,
    StatsCardVariant.warning => AppColors.warning,
    StatsCardVariant.danger => AppColors.danger,
    StatsCardVariant.info => AppColors.foreground,
    StatsCardVariant.stock => AppColors.inStock,
    StatsCardVariant.lowStock => AppColors.lowStock,
    StatsCardVariant.sales => AppColors.success,
  };

  Color _getTrendColor() => switch (trendDirection!) {
    TrendDirection.up => AppColors.success,
    TrendDirection.down => AppColors.danger,
    TrendDirection.neutral => AppColors.mutedForeground,
  };

  IconData _getTrendIcon() => switch (trendDirection!) {
    TrendDirection.up => LucideIcons.trendingUp,
    TrendDirection.down => LucideIcons.trendingDown,
    TrendDirection.neutral => LucideIcons.minus,
  };
}

/// 売上統計カード
class SalesStatsCard extends StatelessWidget {
  const SalesStatsCard({
    required this.amount,
    this.period = "今日",
    this.trendValue,
    this.trendDirection,
    this.onTap,
    super.key,
  });

  final int amount;
  final String period;
  final String? trendValue;
  final TrendDirection? trendDirection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => StatsCard(
    title: "$periodの売上",
    value: "¥${_formatCurrency(amount)}",
    icon: LucideIcons.trendingUp,
    variant: StatsCardVariant.success,
    trendValue: trendValue,
    trendDirection: trendDirection,
    onTap: onTap,
  );

  String _formatCurrency(int amount) => amount.toString().replaceAllMapped(
    RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
    (Match match) => "${match[1]},",
  );
}

/// 在庫統計カード
class InventoryStatsCard extends StatelessWidget {
  const InventoryStatsCard({
    required this.totalItems,
    required this.lowStockCount,
    this.onTap,
    super.key,
  });

  final int totalItems;
  final int lowStockCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final StatsCardVariant variant = lowStockCount > 5
        ? StatsCardVariant.danger
        : lowStockCount > 0
        ? StatsCardVariant.warning
        : StatsCardVariant.stock;

    return StatsCard(
      title: "在庫状況",
      value: "$totalItems品目",
      subtitle: lowStockCount > 0 ? "$lowStockCount品目が在庫少" : "在庫正常",
      icon: LucideIcons.layers,
      variant: variant,
      onTap: onTap,
    );
  }
}

/// 注文統計カード
class OrderStatsCard extends StatelessWidget {
  const OrderStatsCard({
    required this.activeOrders,
    required this.completedToday,
    this.onTap,
    super.key,
  });

  final int activeOrders;
  final int completedToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final StatsCardVariant variant = activeOrders > 10
        ? StatsCardVariant.warning
        : StatsCardVariant.success;

    return StatsCard(
      title: "注文状況",
      value: "$activeOrders件",
      subtitle: "今日完了: $completedToday件",
      icon: LucideIcons.shoppingCart,
      variant: variant,
      onTap: onTap,
    );
  }
}

/// コンパクト統計カード（グリッド表示用）
class CompactStatsCard extends StatelessWidget {
  const CompactStatsCard({
    required this.title,
    required this.value,
    this.icon,
    this.variant = StatsCardVariant.default_,
    this.onTap,
    super.key,
  });

  final String title;
  final String value;
  final IconData? icon;
  final StatsCardVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      StatsCard(title: title, value: value, icon: icon, variant: variant, onTap: onTap);
}
