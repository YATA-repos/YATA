import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// YATAのテーブル表現を標準化するラッパー。
class YataDataTable extends StatelessWidget {
  /// [YataDataTable]を生成する。
  const YataDataTable({
    required this.columns,
    required this.rows,
    super.key,
    this.onRowTap,
    this.shrinkWrap = false,
  });

  /// テーブルヘッダー。
  final List<DataColumn> columns;

  /// テーブル行。
  final List<DataRow> rows;

  /// 行タップ時のコールバック。
  final ValueChanged<int>? onRowTap;

  /// shrinkWrapモードでビルドするかどうか。
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final TextStyle headingStyle =
        (Theme.of(context).textTheme.titleSmall ?? YataTypographyTokens.titleSmall).copyWith(
          color: YataColorTokens.textSecondary,
          fontWeight: FontWeight.w600,
        );
    final TextStyle rowStyle =
        Theme.of(context).textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium;

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(YataColorTokens.neutral100),
          headingTextStyle: headingStyle,
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return YataColorTokens.primarySoft.withValues(alpha: 0.6);
            }
            return null;
          }),
          dataTextStyle: rowStyle,
          dividerThickness: 1,
          headingRowHeight: 52,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 56,
          horizontalMargin: YataSpacingTokens.lg,
          columnSpacing: YataSpacingTokens.lg,
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          Widget table = DataTable(columns: columns, rows: _buildRows());
          if (shrinkWrap) {
            table = SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
          } else {
            table = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: table,
              ),
            );
          }
          return table;
        },
      ),
    );
  }

  List<DataRow> _buildRows() {
    if (onRowTap == null) {
      return rows;
    }

    final List<DataRow> tappableRows = <DataRow>[];
    for (int index = 0; index < rows.length; index++) {
      final DataRow baseRow = rows[index];
      tappableRows.add(
        DataRow(
          key: baseRow.key,
          color: baseRow.color,
          cells: baseRow.cells,
          onSelectChanged: (_) => onRowTap!(index),
        ),
      );
    }
    return tappableRows;
  }
}
