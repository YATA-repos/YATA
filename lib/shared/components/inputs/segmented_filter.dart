import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// セグメント単位でカテゴリーを切り替えるためのデータモデル。
class YataFilterSegment {
  /// [YataFilterSegment]を生成する。
  const YataFilterSegment({required this.label, this.value, this.badge});

  /// セグメントに表示するラベル。
  final String label;

  /// セグメントに紐づく識別子。
  final Object? value;

  /// 補助表示用のバッジ。
  final String? badge;
}

/// セグメントを並べたフィルタチップ群。
class YataSegmentedFilter extends StatelessWidget {
  /// [YataSegmentedFilter]を生成する。
  const YataSegmentedFilter({
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentSelected,
    super.key,
    this.compact = false,
  });

  /// 表示するセグメントリスト。
  final List<YataFilterSegment> segments;

  /// 現在選択中のインデックス。
  final int selectedIndex;

  /// セグメント選択時に呼び出されるコールバック。
  final ValueChanged<int> onSegmentSelected;

  /// コンパクト表示にするかどうか。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: YataSpacingTokens.sm,
      children: <Widget>[
        for (int index = 0; index < segments.length; index++)
          _SegmentChip(
            label: segments[index].label,
            badge: segments[index].badge,
            selected: index == selectedIndex,
            onPressed: () => onSegmentSelected(index),
            textTheme: textTheme,
            compact: compact,
          ),
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.textTheme,
    this.badge,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final TextTheme textTheme;
  final String? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = selected
        ? YataColorTokens.primary
        : YataColorTokens.textSecondary;
    final Color backgroundColor = selected ? YataColorTokens.primarySoft : YataColorTokens.neutral0;
    final BoxBorder border = Border.all(
      color: selected ? YataColorTokens.primary : YataColorTokens.border,
      width: selected ? 1.4 : 1,
    );

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.large)),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? YataSpacingTokens.sm : YataSpacingTokens.md,
          vertical: compact ? YataSpacingTokens.xs : YataSpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.large)),
          border: border,
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
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(left: YataSpacingTokens.xs),
                padding: const EdgeInsets.symmetric(horizontal: YataSpacingTokens.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? YataColorTokens.primary : YataColorTokens.neutral200,
                  borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.small)),
                ),
                child: Text(
                  badge!,
                  style: (textTheme.labelSmall ?? YataTypographyTokens.labelSmall).copyWith(
                    color: selected ? YataColorTokens.neutral0 : YataColorTokens.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
