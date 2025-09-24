import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// 単純なタグ表示用のピル型ラベル。
class YataTag extends StatelessWidget {
  /// [YataTag]を生成する。
  const YataTag({
    required this.label,
    super.key,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.outlined = false,
  });

  /// 表示テキスト。
  final String label;

  /// テキスト左側に表示するアイコン。
  final IconData? icon;

  /// 背景色。
  final Color? backgroundColor;

  /// 文字色。
  final Color? foregroundColor;

  /// アウトライン表示にするかどうか。
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        Theme.of(context).textTheme.labelMedium ?? YataTypographyTokens.labelMedium;
    final Color bgColor = backgroundColor ?? YataColorTokens.neutral100;
    final Color textColor = foregroundColor ?? YataColorTokens.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: YataSpacingTokens.sm, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bgColor,
        borderRadius: YataRadiusTokens.borderRadiusPill,
        border: outlined ? Border.all(color: foregroundColor ?? YataColorTokens.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: YataSpacingTokens.xs),
          ],
          Text(label, style: textStyle.copyWith(color: textColor)),
        ],
      ),
    );
  }
}
