import "package:flutter/material.dart";

import "../../components/inputs/quantity_stepper.dart";
import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// 現在の注文一覧で使用するアイテム行。
class YataOrderItemTile extends StatelessWidget {
  /// [YataOrderItemTile]を生成する。
  const YataOrderItemTile({
    required this.name,
    required this.unitPriceLabel,
    required this.quantity,
    required this.onQuantityChanged,
    super.key,
    this.totalPriceLabel,
    this.onRemove,
    this.showDivider = true,
  });

  /// 商品名。
  final String name;

  /// 単価表示。
  final String unitPriceLabel;

  /// 数量。
  final int quantity;

  /// 数量変更コールバック。
  final ValueChanged<int> onQuantityChanged;

  /// 合計金額表示。
  final String? totalPriceLabel;

  /// 行削除コールバック。
  final VoidCallback? onRemove;

  /// 下部に区切り線を表示するかどうか。
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle primaryStyle = textTheme.titleMedium ?? YataTypographyTokens.titleMedium;
    final TextStyle secondaryStyle = (textTheme.bodySmall ?? YataTypographyTokens.bodySmall)
        .copyWith(color: YataColorTokens.textSecondary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              YataQuantityStepper(value: quantity, onChanged: onQuantityChanged, compact: true),
              const SizedBox(width: YataSpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name, style: primaryStyle),
                    const SizedBox(height: YataSpacingTokens.xs),
                    Text(unitPriceLabel, style: secondaryStyle),
                    if (totalPriceLabel != null) ...<Widget>[
                      const SizedBox(height: YataSpacingTokens.xs),
                      Text(totalPriceLabel!, style: secondaryStyle),
                    ],
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                  tooltip: "削除",
                  splashRadius: 18,
                  color: YataColorTokens.textSecondary,
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: YataSpacingTokens.lg, thickness: 1, color: YataColorTokens.divider),
      ],
    );
  }
}
