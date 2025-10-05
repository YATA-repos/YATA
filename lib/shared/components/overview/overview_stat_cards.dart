import "package:flutter/material.dart";

import "../../foundations/tokens/spacing_tokens.dart";
import "../data_display/stat_card.dart";

/// 画面上部に配置する統一スタイルの概要カード群。
class OverviewStatCards extends StatelessWidget {
  const OverviewStatCards({
    required this.stats,
    super.key,
    this.stackBreakpoint = 900,
  });

  /// 表示する統計カードの一覧。
  final List<OverviewStatData> stats;

  /// カードを縦積みに切り替えるブレークポイント。
  final double stackBreakpoint;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stacked = constraints.maxWidth < stackBreakpoint;

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: stats
                .map(
                  (OverviewStatData stat) => Padding(
                    padding: const EdgeInsets.only(bottom: YataSpacingTokens.sm),
                    child: _buildCard(stat),
                  ),
                )
                .toList(growable: false),
          );
        }

        final List<Widget> rowChildren = <Widget>[];
        for (int index = 0; index < stats.length; index++) {
          final OverviewStatData stat = stats[index];
          rowChildren.add(
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == stats.length - 1 ? 0 : YataSpacingTokens.md,
                ),
                child: _buildCard(stat),
              ),
            ),
          );
        }

        return Row(children: rowChildren);
      },
    );
  }

  Widget _buildCard(OverviewStatData stat) => YataStatCard(
        title: stat.title,
        value: stat.value,
        indicatorColor: stat.indicatorColor,
        indicatorLabel: stat.indicatorLabel,
      );
}

/// [OverviewStatCards] に渡す表示データ。
class OverviewStatData {
  const OverviewStatData({
    required this.title,
    required this.value,
    required this.indicatorColor,
    required this.indicatorLabel,
  });

  /// カードタイトル。
  final String title;

  /// 中央の表示値。
  final String value;

  /// インジケータの色。
  final Color indicatorColor;

  /// インジケータ説明文。
  final String indicatorLabel;
}
