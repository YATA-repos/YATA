import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

import "table_specs.dart";

/// YATAのテーブル表現を標準化するラッパー。
///
/// 使用上の注意:
/// - [columns] の数と、各 [DataRow.cells] の長さは必ず一致させてください。
///   一致しない場合、Flutterの [DataTable] 内部アサーションにより実行時に失敗します。
class YataDataTable extends StatelessWidget {
  /// [YataDataTable]を生成する（従来のDataRow/DataColumnベース）。
  const YataDataTable({
    required List<DataColumn> columns,
    required List<DataRow> rows,
    super.key,
    this.onRowTap,
    this.showCheckboxColumn = false,
    this.shrinkWrap = false,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.headingRowHeight,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.horizontalMargin,
    this.columnSpacing,
  }) : columns = columns,
       rows = rows,
       columnSpecs = null,
       rowSpecs = null,
       sortColumnId = null;

  /// 行/列スペックを受け取る新しいコンストラクタ。
  const YataDataTable.fromSpecs({
    required List<YataTableColumnSpec> columns,
    required List<YataTableRowSpec> rows,
    super.key,
    this.onRowTap,
    this.showCheckboxColumn = false,
    this.shrinkWrap = false,
    this.sortColumnId,
    this.sortAscending = true,
    this.headingRowHeight,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.horizontalMargin,
    this.columnSpacing,
  }) : columns = const <DataColumn>[],
       rows = const <DataRow>[],
       columnSpecs = columns,
       rowSpecs = rows,
       sortColumnIndex = null;

  /// テーブルヘッダー。
  final List<DataColumn> columns;

  /// テーブル行。
  final List<DataRow> rows;

  /// 列スペック。
  final List<YataTableColumnSpec>? columnSpecs;

  /// 行スペック。
  final List<YataTableRowSpec>? rowSpecs;

  /// 行タップ時のコールバック。
  final ValueChanged<int>? onRowTap;

  /// チェックボックス列を表示するかどうか。
  final bool showCheckboxColumn;

  /// shrinkWrapモードでビルドするかどうか。
  final bool shrinkWrap;

  /// ソート対象のカラムインデックス。
  final int? sortColumnIndex;

  /// スペック利用時のソート対象ID。
  final String? sortColumnId;

  /// 昇順かどうか。
  final bool sortAscending;

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
          final List<DataColumn> effectiveColumns = columnSpecs == null
              ? columns
              : _buildColumnsFromSpecs();
          final List<DataRow> effectiveRows = columnSpecs == null
              ? _buildRows(rows)
              : _buildRowsFromSpecs(context);
          final int? effectiveSortIndex = columnSpecs == null
              ? sortColumnIndex
              : _resolveSortColumnIndex();

          Widget table = DataTable(
            columns: effectiveColumns,
            rows: effectiveRows,
            showCheckboxColumn: showCheckboxColumn,
            sortColumnIndex: effectiveSortIndex,
            sortAscending: sortAscending,
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

  List<DataColumn> _buildColumnsFromSpecs() {
    final List<YataTableColumnSpec> specs = columnSpecs!;
    final List<DataColumn> result = <DataColumn>[];
    for (int index = 0; index < specs.length; index++) {
      final YataTableColumnSpec spec = specs[index];
      Widget label = spec.label;
      if (spec.tooltip != null && spec.tooltip!.isNotEmpty) {
        label = Tooltip(message: spec.tooltip!, child: label);
      }
      result.add(
        DataColumn(
          label: label,
          numeric: spec.numeric,
          onSort: spec.onSort == null ? null : (int _, bool ascending) => spec.onSort!(ascending),
        ),
      );
    }
    return result;
  }

  List<DataRow> _buildRows(List<DataRow> baseRows) {
    if (onRowTap == null) {
      return baseRows;
    }

    final List<DataRow> tappableRows = <DataRow>[];
    for (int index = 0; index < baseRows.length; index++) {
      final DataRow baseRow = baseRows[index];
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

  List<DataRow> _buildRowsFromSpecs(BuildContext context) {
    final List<YataTableColumnSpec> specs = columnSpecs!;
    final List<YataTableRowSpec> specRows = rowSpecs!;
    final int columnCount = specs.length;

    return List<DataRow>.generate(specRows.length, (int rowIndex) {
      final YataTableRowSpec rowSpec = specRows[rowIndex];
      assert(
        rowSpec.cells.length == columnCount,
        "Row ${rowSpec.id} must provide $columnCount cells, got ${rowSpec.cells.length}",
      );

      final List<DataCell> cells = <DataCell>[];
      for (int cellIndex = 0; cellIndex < columnCount; cellIndex++) {
        final YataTableCellSpec cellSpec = rowSpec.cells[cellIndex];
        final YataTableColumnSpec columnSpec = specs[cellIndex];

        Widget content = cellSpec.builder(context);

        if (columnSpec.minWidth != null || columnSpec.maxWidth != null) {
          content = ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: columnSpec.minWidth ?? 0,
              maxWidth: columnSpec.maxWidth ?? double.infinity,
            ),
            child: content,
          );
        }

        final AlignmentGeometry? alignment = cellSpec.alignment ?? columnSpec.defaultAlignment;
        if (alignment != null) {
          content = Align(alignment: alignment, child: content);
        }

        if (rowSpec.errorMessage != null &&
            rowSpec.errorMessage!.isNotEmpty &&
            cellSpec.errorMessage == null &&
            cellIndex == 0) {
          content = yataTableCellWithError(child: content, message: rowSpec.errorMessage!);
        }
        if (cellSpec.errorMessage != null && cellSpec.errorMessage!.isNotEmpty) {
          content = yataTableCellWithError(child: content, message: cellSpec.errorMessage!);
        }

        final bool showBusy = (rowSpec.isBusy && cellSpec.applyRowBusyOverlay) || cellSpec.isBusy;
        if (showBusy) {
          content = yataTableBusyOverlay(content);
        }

        if (cellSpec.semanticLabel != null) {
          content = Semantics(label: cellSpec.semanticLabel, child: content);
        } else if (rowSpec.semanticLabel != null && cellIndex == 0) {
          content = Semantics(label: rowSpec.semanticLabel, child: content);
        }

        final String? tooltipMessage =
            cellSpec.tooltip ?? (cellIndex == 0 ? rowSpec.tooltip : null);
        if (tooltipMessage != null && tooltipMessage.isNotEmpty) {
          content = Tooltip(message: tooltipMessage, child: content);
        }

        cells.add(DataCell(content));
      }

      VoidCallback? tapHandler = rowSpec.onTap;
      if (tapHandler == null && onRowTap != null) {
        tapHandler = () => onRowTap!(rowIndex);
      }

      final MaterialStateProperty<Color?>? rowColor = rowSpec.errorMessage == null
          ? null
          : MaterialStateProperty.all<Color?>(YataColorTokens.dangerSoft.withValues(alpha: 0.6));

      return DataRow(
        key: rowSpec.key ?? ValueKey<String>(rowSpec.id),
        color: rowColor,
        cells: cells,
        onSelectChanged: tapHandler == null ? null : (_) => tapHandler!(),
      );
    });
  }

  int? _resolveSortColumnIndex() {
    if (sortColumnId == null) {
      return null;
    }
    final int index = columnSpecs!.indexWhere(
      (YataTableColumnSpec spec) => spec.id == sortColumnId,
    );
    return index >= 0 ? index : null;
  }
}
