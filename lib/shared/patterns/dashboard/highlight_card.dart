import "package:flutter/material.dart";

import "../../components/data_display/progress_bar.dart";
import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// 注文状況ボードなどで使用するハイライトカード。
class YataHighlightCard extends StatelessWidget {
  /// [YataHighlightCard]を生成する。
  const YataHighlightCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    super.key,
    this.progressLabel,
    this.badges = const <Widget>[],
    this.footer,
    this.accentColor,
    this.trailing,
  }) : assert(progress >= 0 && progress <= 1, "progressは0〜1で指定してください");

  /// カードタイトル。
  final String title;

  /// 時刻などのサブタイトル。
  final String subtitle;

  /// 進捗率 (0〜1)。
  final double progress;

  /// 進捗ラベル。
  final String? progressLabel;

  /// タイトルの右側に表示するバッジ群。
  final List<Widget> badges;

  /// 最下部に表示するフッター。
  final Widget? footer;

  /// カードのアクセントカラー。
  final Color? accentColor;

  /// 右上に表示するウィジェット。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Color resolvedAccent = accentColor ?? YataColorTokens.info;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(YataSpacingTokens.lg),
      decoration: BoxDecoration(
        color: resolvedAccent.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.large)),
        border: Border.all(color: resolvedAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: textTheme.titleMedium ?? YataTypographyTokens.titleMedium),
                    const SizedBox(height: YataSpacingTokens.xs),
                    Text(
                      subtitle,
                      style: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall).copyWith(
                        color: YataColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badges.isNotEmpty || trailing != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (trailing != null) trailing!,
                    if (badges.isNotEmpty) ...<Widget>[
                      const SizedBox(height: YataSpacingTokens.xs),
                      Wrap(
                        spacing: YataSpacingTokens.xs,
                        runSpacing: YataSpacingTokens.xs,
                        children: badges,
                      ),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: YataSpacingTokens.md),
          YataProgressBar(progress: progress, label: progressLabel, color: resolvedAccent),
          if (footer != null) ...<Widget>[const SizedBox(height: YataSpacingTokens.md), footer!],
        ],
      ),
    );
  }
}
