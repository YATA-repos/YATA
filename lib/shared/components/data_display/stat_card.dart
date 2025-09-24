import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/elevetion_token.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// 指標カードのトレンド方向。
enum YataStatTrend {
  /// 前回より上昇。
  up,

  /// 前回より下降。
  down,

  /// 変化なしまたは比較不可。
  steady,
}

/// 売上や在庫などの指標を表示するカード。
class YataStatCard extends StatelessWidget {
  /// [YataStatCard]を生成する。
  const YataStatCard({
    required this.title,
    required this.value,
    super.key,
    this.prefix,
    this.suffix,
    this.trend,
    this.trendLabel,
  });

  /// 指標名。
  final String title;

  /// 指標の値。
  final String value;

  /// 値の前に表示する補足ウィジェット。
  final Widget? prefix;

  /// 値の後に表示する補足ウィジェット。
  final Widget? suffix;

  /// トレンド方向。
  final YataStatTrend? trend;

  /// トレンドの説明テキスト。
  final String? trendLabel;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = const BorderRadius.all(
      Radius.circular(YataRadiusTokens.large),
    );
    final List<BoxShadow> shadow = YataElevationTokens.level1;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(YataSpacingTokens.lg),
      decoration: BoxDecoration(
        color: YataColorTokens.surface,
        borderRadius: borderRadius,
        border: Border.all(color: YataColorTokens.border),
        boxShadow: shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium),
          const SizedBox(height: YataSpacingTokens.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (prefix != null) ...<Widget>[prefix!, const SizedBox(width: YataSpacingTokens.xs)],
              Text(value, style: textTheme.headlineLarge ?? YataTypographyTokens.headlineLarge),
              if (suffix != null) ...<Widget>[const SizedBox(width: YataSpacingTokens.xs), suffix!],
            ],
          ),
          if (trend != null && trendLabel != null) ...<Widget>[
            const SizedBox(height: YataSpacingTokens.sm),
            _TrendLabel(trend: trend!, label: trendLabel!),
          ],
        ],
      ),
    );
  }
}

class _TrendLabel extends StatelessWidget {
  const _TrendLabel({required this.trend, required this.label});

  final YataStatTrend trend;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle =
        Theme.of(context).textTheme.bodySmall ?? YataTypographyTokens.bodySmall;
    final Color color;
    final IconData icon;

    switch (trend) {
      case YataStatTrend.up:
        color = YataColorTokens.success;
        icon = Icons.arrow_drop_up;
        break;
      case YataStatTrend.down:
        color = YataColorTokens.danger;
        icon = Icons.arrow_drop_down;
        break;
      case YataStatTrend.steady:
        color = YataColorTokens.textSecondary;
        icon = Icons.drag_handle;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: YataSpacingTokens.xs),
        Text(label, style: baseStyle.copyWith(color: color)),
      ],
    );
  }
}
