import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_card.dart";

/// 統計カードコンポーネント
///
/// 売上、注文数等の統計表示、前月比表示に対応
class StatsCard extends StatelessWidget {
  const StatsCard({
    required this.title,
    required this.value,
    super.key,
    this.subtitle,
    this.icon,
    this.trend,
    this.trendValue,
    this.trendLabel = "前月比",
    this.onTap,
    this.isLoading = false,
    this.currencySymbol,
    this.unit,
    this.precision = 0,
  });

  /// カードタイトル
  final String title;

  /// メイン数値
  final num value;

  /// サブタイトル
  final String? subtitle;

  /// アイコン
  final IconData? icon;

  /// トレンド傾向
  final StatsTrend? trend;

  /// トレンド数値
  final num? trendValue;

  /// トレンドラベル
  final String trendLabel;

  /// タップ処理
  final VoidCallback? onTap;

  /// ローディング状態
  final bool isLoading;

  /// 通貨記号
  final String? currencySymbol;

  /// 単位
  final String? unit;

  /// 小数点以下桁数
  final int precision;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(context),
        const SizedBox(height: AppLayout.spacing4),
        if (isLoading)
          _buildLoadingState()
        else ...<Widget>[
          _buildValue(context),
          if (trend != null || trendValue != null) ...<Widget>[
            const SizedBox(height: AppLayout.spacing3),
            _buildTrend(context),
          ],
        ],
      ],
    ),
  );

  Widget _buildHeader(BuildContext context) => Row(
    children: <Widget>[
      if (icon != null) ...<Widget>[
        Container(
          padding: AppLayout.padding2,
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(AppLayout.spacing2),
          ),
          child: Icon(icon, size: AppLayout.iconSize, color: AppColors.primary),
        ),
        const SizedBox(width: AppLayout.spacing3),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: AppLayout.spacing1),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ],
        ),
      ),
      if (onTap != null)
        Icon(
          LucideIcons.chevronRight,
          size: AppLayout.iconSizeSm,
          color: AppColors.mutedForeground,
        ),
    ],
  );

  Widget _buildLoadingState() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Container(
        height: 32,
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(AppLayout.spacing1),
        ),
      ),
      const SizedBox(height: AppLayout.spacing2),
      Container(
        height: 16,
        width: 80,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(AppLayout.spacing1),
        ),
      ),
    ],
  );

  Widget _buildValue(BuildContext context) {
    final String formattedValue = _formatValue(value);
    final String displayValue = "${currencySymbol ?? ""}$formattedValue${unit ?? ""}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          displayValue,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }

  Widget _buildTrend(BuildContext context) {
    if (trend == null && trendValue == null) {
      return const SizedBox.shrink();
    }

    final Color trendColor = _getTrendColor();
    final IconData trendIcon = _getTrendIcon();
    final String trendText = _getTrendText();

    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.spacing2,
            vertical: AppLayout.spacing1,
          ),
          decoration: BoxDecoration(
            color: trendColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppLayout.spacing2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(trendIcon, size: AppLayout.iconSizeSm, color: trendColor),
              const SizedBox(width: AppLayout.spacing1),
              Text(
                trendText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: trendColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppLayout.spacing2),
        Text(
          trendLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  String _formatValue(num value) {
    if (precision == 0) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
        (Match match) => "${match[1]},",
      );
    } else {
      return value
          .toStringAsFixed(precision)
          .replaceAllMapped(
            RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
            (Match match) => "${match[1]},",
          );
    }
  }

  Color _getTrendColor() {
    switch (trend) {
      case StatsTrend.up:
        return AppColors.success;
      case StatsTrend.down:
        return AppColors.danger;
      case StatsTrend.neutral:
        return AppColors.mutedForeground;
      case null:
        if (trendValue != null) {
          if (trendValue! > 0) {
            return AppColors.success;
          }
          if (trendValue! < 0) {
            return AppColors.danger;
          }
        }
        return AppColors.mutedForeground;
    }
  }

  IconData _getTrendIcon() {
    switch (trend) {
      case StatsTrend.up:
        return LucideIcons.trendingUp;
      case StatsTrend.down:
        return LucideIcons.trendingDown;
      case StatsTrend.neutral:
        return LucideIcons.minus;
      case null:
        if (trendValue != null) {
          if (trendValue! > 0) {
            return LucideIcons.trendingUp;
          }
          if (trendValue! < 0) {
            return LucideIcons.trendingDown;
          }
        }
        return LucideIcons.minus;
    }
  }

  String _getTrendText() {
    if (trendValue != null) {
      final String formattedTrend = _formatValue(trendValue!.abs());
      final String sign = trendValue! >= 0 ? "+" : "-";
      return "$sign$formattedTrend${unit ?? ""}";
    }

    switch (trend) {
      case StatsTrend.up:
        return "上昇";
      case StatsTrend.down:
        return "下降";
      case StatsTrend.neutral:
        return "変わらず";
      case null:
        return "";
    }
  }
}

/// 統計トレンド列挙型
enum StatsTrend {
  up, // 上昇
  down, // 下降
  neutral, // 変わらず
}

/// 統計カード行レイアウト
class StatsCardRow extends StatelessWidget {
  const StatsCardRow({
    required this.children,
    super.key,
    this.spacing = AppLayout.spacing4,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// 子カード一覧
  final List<Widget> children;

  /// カード間隔
  final double spacing;

  /// 垂直配置
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: crossAxisAlignment,
    children: children
        .asMap()
        .entries
        .map(
          (MapEntry<int, Widget> entry) => entry.key == children.length - 1
              ? Expanded(child: entry.value)
              : Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: spacing),
                    child: entry.value,
                  ),
                ),
        )
        .toList(),
  );
}

/// 統計カードグリッド
class StatsCardGrid extends StatelessWidget {
  const StatsCardGrid({
    required this.children,
    super.key,
    this.crossAxisCount,
    this.spacing = AppLayout.spacing4,
    this.childAspectRatio = 1.5,
    this.maxCrossAxisExtent = 300,
  });

  /// 子カード一覧
  final List<Widget> children;

  /// 列数
  final int? crossAxisCount;

  /// カード間隔
  final double spacing;

  /// アスペクト比
  final double childAspectRatio;

  /// 最大列幅
  final double maxCrossAxisExtent;

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount != null) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount!,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
        children: children,
      );
    }

    return GridView.extent(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      maxCrossAxisExtent: maxCrossAxisExtent,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }
}
