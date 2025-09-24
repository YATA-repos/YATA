import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// 数量の増減を行うステッパー。
class YataQuantityStepper extends StatelessWidget {
  /// [YataQuantityStepper]を生成する。
  const YataQuantityStepper({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max,
    this.compact = false,
  });

  /// 現在の数量。
  final int value;

  /// 数量変更時に呼ばれる。
  final ValueChanged<int> onChanged;

  /// 最小値。
  final int min;

  /// 最大値。未指定の場合は制限なし。
  final int? max;

  /// コンパクト表示にするかどうか。
  final bool compact;

  bool get _canDecrement => value > min;

  bool get _canIncrement => max == null || value < max!;

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle =
        (Theme.of(context).textTheme.titleMedium ?? YataTypographyTokens.titleMedium).copyWith(
          color: YataColorTokens.textPrimary,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: YataColorTokens.border),
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        color: YataColorTokens.neutral0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: Icons.remove,
            enabled: _canDecrement,
            onPressed: () {
              if (_canDecrement) {
                onChanged(value - 1);
              }
            },
            compact: compact,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: compact ? 22 : 28),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? YataSpacingTokens.sm : YataSpacingTokens.md,
              ),
              alignment: Alignment.center,
              child: Text("$value", style: valueStyle),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: _canIncrement,
            onPressed: () {
              if (_canIncrement) {
                onChanged(value + 1);
              }
            },
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.compact,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
      child: Padding(
        padding: EdgeInsets.all(compact ? YataSpacingTokens.xs : YataSpacingTokens.sm),
        child: Icon(
          icon,
          size: compact ? 18 : 20,
          color: enabled ? YataColorTokens.textPrimary : YataColorTokens.textSecondary,
        ),
      ),
    ),
  );
}
