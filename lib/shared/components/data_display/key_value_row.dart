import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// 注文サマリー等で使用するラベルと値の行。
class YataKeyValueRow extends StatelessWidget {
  /// [YataKeyValueRow]を生成する。
  const YataKeyValueRow({
    required this.label,
    required this.value,
    super.key,
    this.labelStyle,
    this.valueStyle,
    this.divider,
  });

  /// ラベル文字列。
  final String label;

  /// 値文字列。
  final String value;

  /// ラベル用テキストスタイル。
  final TextStyle? labelStyle;

  /// 値用テキストスタイル。
  final TextStyle? valueStyle;

  /// ラベルと値の間に挟むウィジェット。
  final Widget? divider;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: labelStyle ?? textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
          ),
        ),
        if (divider != null) ...<Widget>[
          const SizedBox(width: YataSpacingTokens.sm),
          divider!,
          const SizedBox(width: YataSpacingTokens.sm),
        ] else
          const SizedBox(width: YataSpacingTokens.sm),
        Text(
          value,
          style: valueStyle ?? textTheme.titleMedium ?? YataTypographyTokens.titleMedium,
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

/// 合計など強調行で使う太字バリエーション。
class YataKeyValueTotalRow extends StatelessWidget {
  /// [YataKeyValueTotalRow]を生成する。
  const YataKeyValueTotalRow({required this.label, required this.value, super.key});

  /// ラベル文字列。
  final String label;

  /// 値文字列。
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelTextStyle =
        (Theme.of(context).textTheme.titleMedium ?? YataTypographyTokens.titleMedium).copyWith(
          color: YataColorTokens.textPrimary,
          fontWeight: FontWeight.w700,
        );
    final TextStyle valueTextStyle =
        (Theme.of(context).textTheme.headlineSmall ?? YataTypographyTokens.headlineSmall).copyWith(
          color: YataColorTokens.textPrimary,
          fontWeight: FontWeight.w700,
        );

    return YataKeyValueRow(
      label: label,
      value: value,
      labelStyle: labelTextStyle,
      valueStyle: valueTextStyle,
    );
  }
}
