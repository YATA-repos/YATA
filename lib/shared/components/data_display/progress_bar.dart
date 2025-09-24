import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// 調理進捗などを表示する横棒プログレスバー。
class YataProgressBar extends StatelessWidget {
  /// [YataProgressBar]を生成する。
  const YataProgressBar({required this.progress, super.key, this.label, this.color})
    : assert(progress >= 0 && progress <= 1, "progressは0〜1で指定してください");

  /// 0〜1で表す進捗率。
  final double progress;

  /// バーの下部に表示するラベル。
  final String? label;

  /// バーの色。未指定時はプライマリカラー。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color barColor = color ?? YataColorTokens.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
          child: Container(
            height: 10,
            decoration: BoxDecoration(color: YataColorTokens.neutral200.withValues(alpha: 0.6)),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) => Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(color: barColor),
                ),
              ),
            ),
          ),
        ),
        if (label != null) ...<Widget>[
          const SizedBox(height: YataSpacingTokens.xs),
          Text(label!, style: textTheme.bodySmall ?? YataTypographyTokens.bodySmall),
        ],
      ],
    );
  }
}
