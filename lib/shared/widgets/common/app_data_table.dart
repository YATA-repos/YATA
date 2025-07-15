import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";
import "app_button.dart";

/// データテーブルコンポーネント
///
/// ソート機能、ページネーション対応のテーブル表示
class AppDataTable<T> extends StatefulWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    super.key,
    this.onSort,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.showCheckboxColumn = false,
    this.selectedRows = const <int>{},
    this.onSelectChanged,
    this.onSelectAll,
    this.itemsPerPage = 25,
    this.currentPage = 0,
    this.onPageChanged,
    this.showPagination = true,
    this.emptyStateWidget,
    this.loadingWidget,
    this.isLoading = false,
    this.minWidth,
    this.horizontalMargin = AppLayout.spacing4,
    this.columnSpacing = AppLayout.spacing6,
    this.border,
  });

  /// テーブルカラム定義
  final List<AppDataColumn> columns;

  /// テーブル行データ
  final List<AppDataRow<T>> rows;

  /// ソート処理コールバック
  final void Function(int columnIndex, bool ascending)? onSort;

  /// 現在ソート中のカラムインデックス
  final int? sortColumnIndex;

  /// ソート方向（昇順/降順）
  final bool sortAscending;

  /// チェックボックス列の表示
  final bool showCheckboxColumn;

  /// 選択された行のインデックス
  final Set<int> selectedRows;

  /// 行選択変更コールバック
  final void Function(int index, bool selected)? onSelectChanged;

  /// 全選択コールバック
  final void Function(bool selectAll)? onSelectAll;

  /// 1ページあたりのアイテム数
  final int itemsPerPage;

  /// 現在のページ番号
  final int currentPage;

  /// ページ変更コールバック
  final void Function(int page)? onPageChanged;

  /// ページネーション表示
  final bool showPagination;

  /// 空状態ウィジェット
  final Widget? emptyStateWidget;

  /// ローディングウィジェット
  final Widget? loadingWidget;

  /// ローディング状態
  final bool isLoading;

  /// テーブル最小幅
  final double? minWidth;

  /// 水平マージン
  final double horizontalMargin;

  /// カラム間隔
  final double columnSpacing;

  /// テーブル境界線
  final TableBorder? border;

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.rows.isEmpty) {
      return _buildEmptyState();
    }

    return Column(children: <Widget>[_buildTable(), if (widget.showPagination) _buildPagination()]);
  }

  Widget _buildTable() {
    final List<AppDataRow<T>> visibleRows = _getVisibleRows();

    Widget table = DataTable(
      columns: _buildColumns(),
      rows: _buildDataRows(visibleRows),
      sortColumnIndex: widget.sortColumnIndex,
      sortAscending: widget.sortAscending,
      showCheckboxColumn: widget.showCheckboxColumn,
      horizontalMargin: widget.horizontalMargin,
      columnSpacing: widget.columnSpacing,
      border: widget.border,
      headingRowColor: WidgetStateProperty.all(AppColors.muted),
      dataRowMinHeight: AppLayout.listTileMinHeight,
      dataRowMaxHeight: AppLayout.listTileMinHeight + 20,
    );

    if (widget.minWidth != null) {
      table = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: widget.minWidth!),
          child: table,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppLayout.radiusLg,
      ),
      child: ClipRRect(borderRadius: AppLayout.radiusLg, child: table),
    );
  }

  Widget _buildLoadingState() =>
      widget.loadingWidget ??
      Container(height: 200, alignment: Alignment.center, child: const CircularProgressIndicator());

  Widget _buildEmptyState() =>
      widget.emptyStateWidget ??
      Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(LucideIcons.inbox, size: AppLayout.iconSizeXl, color: AppColors.mutedForeground),
            const SizedBox(height: AppLayout.spacing4),
            Text(
              "データがありません",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
      );

  List<DataColumn> _buildColumns() => widget.columns
      .map(
        (AppDataColumn column) => DataColumn(
          label: column.label,
          onSort: column.sortable && widget.onSort != null
              ? (int columnIndex, bool ascending) {
                  widget.onSort!(columnIndex, ascending);
                }
              : null,
          numeric: column.numeric,
          tooltip: column.tooltip,
        ),
      )
      .toList();

  List<DataRow> _buildDataRows(List<AppDataRow<T>> visibleRows) =>
      visibleRows.asMap().entries.map((MapEntry<int, AppDataRow<T>> entry) {
        final int index = entry.key + (widget.currentPage * widget.itemsPerPage);
        final AppDataRow<T> row = entry.value;

        return DataRow(
          cells: row.cells,
          selected: widget.selectedRows.contains(index),
          onSelectChanged: widget.onSelectChanged != null
              ? (bool? selected) {
                  widget.onSelectChanged!(index, selected ?? false);
                }
              : null,
          color: row.color != null ? WidgetStateProperty.all(row.color) : null,
        );
      }).toList();

  List<AppDataRow<T>> _getVisibleRows() {
    if (!widget.showPagination) {
      return widget.rows;
    }

    final int startIndex = widget.currentPage * widget.itemsPerPage;
    final int endIndex = (startIndex + widget.itemsPerPage).clamp(0, widget.rows.length);

    return widget.rows.sublist(startIndex, endIndex);
  }

  Widget _buildPagination() {
    final int totalPages = (widget.rows.length / widget.itemsPerPage).ceil();
    final int currentPage = widget.currentPage;

    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: AppLayout.paddingVertical4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "${widget.rows.length}件中 ${currentPage * widget.itemsPerPage + 1}-"
            "${((currentPage + 1) * widget.itemsPerPage).clamp(0, widget.rows.length)}件を表示",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
          ),
          Row(
            children: <Widget>[
              AppButton(
                onPressed: currentPage > 0 ? _previousPage : null,
                variant: ButtonVariant.ghost,
                size: ButtonSize.small,
                icon: LucideIcons.chevronLeft,
                child: const Text("前へ"),
              ),
              const SizedBox(width: AppLayout.spacing2),
              Text(
                "${currentPage + 1} / $totalPages",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: AppLayout.spacing2),
              AppButton(
                onPressed: currentPage < totalPages - 1 ? _nextPage : null,
                variant: ButtonVariant.ghost,
                size: ButtonSize.small,
                icon: LucideIcons.chevronRight,
                iconPosition: IconPosition.trailing,
                child: const Text("次へ"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (widget.currentPage > 0) {
      widget.onPageChanged?.call(widget.currentPage - 1);
    }
  }

  void _nextPage() {
    final int totalPages = (widget.rows.length / widget.itemsPerPage).ceil();
    if (widget.currentPage < totalPages - 1) {
      widget.onPageChanged?.call(widget.currentPage + 1);
    }
  }
}

/// データテーブルカラム定義
class AppDataColumn {
  const AppDataColumn({
    required this.label,
    this.sortable = false,
    this.numeric = false,
    this.tooltip,
  });

  /// カラムラベル
  final Widget label;

  /// ソート可能フラグ
  final bool sortable;

  /// 数値カラムフラグ
  final bool numeric;

  /// ツールチップ
  final String? tooltip;
}

/// データテーブル行定義
class AppDataRow<T> {
  const AppDataRow({required this.data, required this.cells, this.color, this.onTap});

  /// 行データ
  final T data;

  /// セルデータ
  final List<DataCell> cells;

  /// 行背景色
  final Color? color;

  /// タップ処理
  final VoidCallback? onTap;
}

/// データテーブルセルヘルパー
class AppDataCell {
  AppDataCell._();

  /// テキストセル
  static DataCell text(
    String text, {
    TextStyle? style,
    VoidCallback? onTap,
    bool showEditIcon = false,
    String? placeholder,
  }) => DataCell(
    Text(
      text.isNotEmpty ? text : (placeholder ?? "-"),
      style:
          style?.copyWith(color: text.isNotEmpty ? null : AppColors.mutedForeground) ??
          TextStyle(color: text.isNotEmpty ? null : AppColors.mutedForeground),
    ),
    onTap: onTap,
    showEditIcon: showEditIcon,
  );

  /// 数値セル
  static DataCell number(
    num? value, {
    String format = "#,##0",
    String unit = "",
    TextStyle? style,
    VoidCallback? onTap,
  }) {
    final String text = value != null ? "$value$unit" : "-";
    return DataCell(
      Text(text, style: style ?? const TextStyle(), textAlign: TextAlign.right),
      onTap: onTap,
    );
  }

  /// バッジセル
  static DataCell badge(Widget badge, {VoidCallback? onTap}) => DataCell(badge, onTap: onTap);

  /// アクションセル
  static DataCell actions(List<Widget> actions, {VoidCallback? onTap}) => DataCell(
    Row(mainAxisSize: MainAxisSize.min, children: actions),
    onTap: onTap,
  );
}
