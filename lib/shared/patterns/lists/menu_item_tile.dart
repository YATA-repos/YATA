import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";
import "../../components/inputs/quantity_stepper.dart";

/// メニュー一覧に表示するタイル。
class YataMenuItemTile extends StatelessWidget {
  /// [YataMenuItemTile]を生成する。
  const YataMenuItemTile({
    required this.name,
    required this.priceLabel,
    super.key,
    this.onTap,
    this.isHighlighted = false,
    this.isSelected = false,
    this.quantity,
    this.onQuantityChanged,
    this.minQuantity = 1,
    this.maxQuantity,
    this.trailing,
  });

  /// 商品名。
  final String name;

  /// 表示する価格文字列。
  final String priceLabel;

  /// タイルタップ時のコールバック。
  final VoidCallback? onTap;

  /// ホバーなどで強調表示するかどうか。
  final bool isHighlighted;

  /// 選択状態を表す。
  final bool isSelected;

  /// 選択時に表示する数量。指定された場合は制御コンポーネントとして動作する。
  /// 未指定の場合は内部状態で数量を管理する。
  final int? quantity;

  /// 数量変更のコールバック。`quantity`と併用した場合は制御運用となる。
  final ValueChanged<int>? onQuantityChanged;

  /// 許容する最小数量。デフォルトは1。
  final int minQuantity;

  /// 許容する最大数量。未指定なら上限なし。
  final int? maxQuantity;

  /// 右側に表示するカスタムウィジェット。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? YataColorTokens.primary
        : YataColorTokens.border.withValues(alpha: isHighlighted ? 0.8 : 0.0);
    final Color backgroundColor = isSelected
        ? YataColorTokens.primarySoft
        : isHighlighted
        ? YataColorTokens.neutral100
        : YataColorTokens.surface;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: YataSpacingTokens.lg,
            vertical: YataSpacingTokens.md,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
            border: Border.all(color: borderColor, width: isSelected ? 1.4 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium).copyWith(
                        color: YataColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: YataSpacingTokens.xs),
                    Text(
                      priceLabel,
                      style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium).copyWith(
                        color: YataColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  (isSelected
                      ? YataQuantityStepper(
                          value: quantity ?? minQuantity,
                          min: minQuantity,
                          max: maxQuantity,
                          compact: true,
                          onChanged: (int v) => onQuantityChanged?.call(v),
                        )
                      : _AddButton(isSelected: isSelected)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected ? YataColorTokens.primary : YataColorTokens.border;
    final Color fillColor = isSelected ? YataColorTokens.primary : YataColorTokens.neutral0;
    final Color iconColor = isSelected ? YataColorTokens.neutral0 : YataColorTokens.primary;
    final IconData iconData = isSelected ? Icons.check : Icons.add;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: borderColor),
      ),
      child: Icon(iconData, color: iconColor, size: 18),
    );
  }
}

/// 数量ステッパー。
