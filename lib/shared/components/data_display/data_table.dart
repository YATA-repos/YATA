import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// YATAのテーブル表現を標準化するラッパー。
///
/// 使用上の注意:
/// - [columns] の数と、各 [DataRow.cells] の長さは必ず一致させてください。
///   一致しない場合、Flutterの [DataTable] 内部アサーションにより実行時に失敗します。
class YataDataTable extends StatelessWidget {
  /// [YataDataTable]を生成する。
  const YataDataTable({
    required this.columns,
    required this.rows,
    super.key,
    this.onRowTap,
    this.shrinkWrap = false,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
    this.headingRowHeight,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.horizontalMargin,
    this.columnSpacing,
  });

  /// テーブルヘッダー。
  final List<DataColumn> columns;

  /// テーブル行。
  final List<DataRow> rows;

  /// 行タップ時のコールバック。
  final ValueChanged<int>? onRowTap;

  /// shrinkWrapモードでビルドするかどうか。
  final bool shrinkWrap;

  /// ソート対象のカラムインデックス。
  final int? sortColumnIndex;

  /// 昇順かどうか。
  final bool sortAscending;

  /// すべて選択/解除のハンドラ（チェックボックス列が表示される）。
  final ValueChanged<bool?>? onSelectAll;

  /// 見出し行の高さ（上書き用）。
  final double? headingRowHeight;

  /// データ行の最小/最大高さ（上書き用）。
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;

  /// 左右余白を上書きする。
  final double? horizontalMargin;

  /// 列間スペースを上書きする。
  final double? columnSpacing;

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
          headingRowHeight: headingRowHeight ?? 52,
          dataRowMinHeight: dataRowMinHeight ?? 52,
          dataRowMaxHeight: dataRowMaxHeight ?? 56,
          horizontalMargin: horizontalMargin ?? YataSpacingTokens.lg,
          columnSpacing: columnSpacing ?? YataSpacingTokens.lg,
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          Widget table = DataTable(
            columns: columns,
            rows: _buildRows(),
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            onSelectAll: onSelectAll,
          );
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
