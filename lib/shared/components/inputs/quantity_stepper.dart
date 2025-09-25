import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";
import "../../themes/app_theme.dart";

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

  int _clampQuantity(int q) {
    if (q < min) return min;
    if (max != null && q > max!) return max!;
    return q;
  }

  Future<void> _promptForValue(BuildContext context) async {
    final TextEditingController controller = TextEditingController(text: "$value");
    int? result;

    Future<void> submit() async {
      final int? parsed = int.tryParse(controller.text.trim());
      if (parsed == null) {
        Navigator.of(context).pop();
        return;
      }
      result = _clampQuantity(parsed);
      Navigator.of(context).pop();
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        final ThemeData theme = Theme.of(ctx);
        final ColorScheme scheme = theme.colorScheme;
        final TextStyle titleStyle =
            (theme.textTheme.headlineSmall ?? YataTypographyTokens.headlineSmall).copyWith(
              color: scheme.onSurface,
            );
        final TextStyle inputTextStyle =
            (theme.textTheme.titleLarge ?? YataTypographyTokens.titleLarge).copyWith(
              color: scheme.onSurface,
            );
        final TextStyle hintStyle = (theme.textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium)
            .copyWith(color: scheme.onSurfaceVariant);

        return Theme(
          data: AppTheme.lightTheme,
          child: Builder(
            builder: (BuildContext lightCtx) {
              final ColorScheme lightScheme = Theme.of(lightCtx).colorScheme;
              return AlertDialog(
                backgroundColor: lightScheme.surface,
                surfaceTintColor: Colors.transparent,
                title: Text("数量を入力", style: titleStyle.copyWith(color: lightScheme.onSurface)),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: inputTextStyle.copyWith(color: lightScheme.onSurface),
                  cursorColor: lightScheme.primary,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    hintText: "$min${max != null ? " ~ ${max!}" : "以上"}",
                    hintStyle: hintStyle.copyWith(color: lightScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: lightScheme.surface,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(lightCtx).pop(),
                    child: const Text("キャンセル"),
                  ),
                  FilledButton(onPressed: submit, child: const Text("OK")),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != null && result != value) {
      onChanged(result!);
    }
  }

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
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => _promptForValue(context),
                borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? YataSpacingTokens.sm : YataSpacingTokens.md,
                  ),
                  alignment: Alignment.center,
                  child: Text("$value", style: valueStyle),
                ),
              ),
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
