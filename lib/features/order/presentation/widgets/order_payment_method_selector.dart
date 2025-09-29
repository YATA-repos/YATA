import "dart:async";

import "package:flutter/material.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../shared/utils/payment_method_label.dart";

/// 支払い方法を選択するチップ群。
class OrderPaymentMethodSelector extends StatelessWidget {
  const OrderPaymentMethodSelector({
    required this.selected,
    required this.isDisabled,
    required this.onChanged,
    super.key,
  });

  /// 現在選ばれている支払い方法。
  final PaymentMethod selected;

  /// 選択操作が無効かどうか。
  final bool isDisabled;

  /// 支払い方法変更時に呼ばれるコールバック。
  final Future<void> Function(PaymentMethod) onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<PaymentMethod> methods = PaymentMethod.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("支払い方法", style: textTheme.titleSmall ?? YataTypographyTokens.titleSmall),
        const SizedBox(height: YataSpacingTokens.sm),
        Wrap(
          spacing: YataSpacingTokens.sm,
          runSpacing: YataSpacingTokens.sm,
          children: methods
              .map((PaymentMethod method) {
                final bool isSelected = method == selected;
                return _PaymentMethodChip(
                  label: paymentMethodLabel(method),
                  selected: isSelected,
                  textTheme: textTheme,
                  isDisabled: isDisabled,
                  onPressed: isDisabled || isSelected ? null : () => unawaited(onChanged(method)),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

/// 支払い方法用のセグメント風チップ。
class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.label,
    required this.selected,
    required this.textTheme,
    required this.isDisabled,
    this.onPressed,
  });

  final String label;
  final bool selected;
  final TextTheme textTheme;
  final bool isDisabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = isDisabled
        ? YataColorTokens.textTertiary
        : selected
        ? YataColorTokens.primary
        : YataColorTokens.textSecondary;
    final Color backgroundColor = isDisabled
        ? YataColorTokens.neutral100
        : selected
        ? YataColorTokens.primarySoft
        : YataColorTokens.neutral0;
    final Color borderColor = isDisabled
        ? YataColorTokens.neutral200
        : selected
        ? YataColorTokens.primary
        : YataColorTokens.border;

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.pill)),
      onTap: isDisabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: YataSpacingTokens.md,
          vertical: YataSpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.pill)),
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: (textTheme.titleSmall ?? YataTypographyTokens.titleSmall).copyWith(
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
