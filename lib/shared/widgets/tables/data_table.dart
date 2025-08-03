import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../core/logging/logger_mixin.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";
import "../cards/app_card.dart";

/// 汎用データテーブルウィジェット
///
/// ソート、選択、カスタムアクションをサポート
class AppDataTable<T> extends StatefulWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.selectable = false,
    this.selectedRows = const <int>{},
    this.onSelectionChanged,
    this.actions = const <Widget>[],
    this.emptyMessage = "データがありません",
    super.key,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final void Function(int)? onRowTap;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final bool selectable;
  final Set<int> selectedRows;
  final void Function(Set<int>)? onSelectionChanged;
  final List<Widget> actions;
  final String emptyMessage;

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> with LoggerMixin {
  @override
  String get loggerComponent => "AppDataTable";
  Set<int> _selectedRows = <int>{};

  @override
  void initState() {
    super.initState();
    _selectedRows = Set<int>.from(widget.selectedRows);
  }

  @override
  void didUpdateWidget(AppDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRows != oldWidget.selectedRows) {
      _selectedRows = Set<int>.from(widget.selectedRows);
    }
  }

  @override
  Widget build(BuildContext context) => AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ヘッダーとアクション
          if (widget.actions.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: <Widget>[const Spacer(), ...widget.actions]),
            ),
            const Divider(),
          ],

          // テーブル
          widget.rows.isEmpty ? _buildEmptyState() : _buildDataTable(),
        ],
      ),
    );

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(LucideIcons.database, size: 48, color: AppColors.mutedForeground),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage,
            style: AppTextTheme.cardTitle.copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    ),
  );

  Widget _buildDataTable() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
      child: DataTable(
        sortColumnIndex: widget.sortColumnIndex,
        sortAscending: widget.sortAscending,
        onSelectAll: widget.selectable ? _handleSelectAll : null,
        columns: widget.columns.map((DataColumn column) => DataColumn(
            label: column.label,
            tooltip: column.tooltip,
            numeric: column.numeric,
            onSort: column.onSort ?? widget.onSort,
          )).toList(),
        rows: widget.rows.asMap().entries.map((MapEntry<int, DataRow> entry) {
          final int index = entry.key;
          final DataRow row = entry.value;

          return DataRow(
            selected: widget.selectable && _selectedRows.contains(index),
            onSelectChanged: widget.selectable
                ? (bool? selected) => _handleRowSelection(index, selected ?? false)
                : null,
            cells: row.cells,
            onLongPress: () => widget.onRowTap?.call(index),
          );
        }).toList(),
      ),
    ),
  );

  void _handleSelectAll(bool? selectAll) {
    try {
      logDebug("全選択処理を実行: selectAll=$selectAll, 行数=${widget.rows.length}");
      setState(() {
        if (true == selectAll) {
          _selectedRows = Set<int>.from(List<int>.generate(widget.rows.length, (int index) => index));
          logInfo("全ての行を選択しました: ${_selectedRows.length}行");
        } else {
          final int previousCount = _selectedRows.length;
          _selectedRows.clear();
          logInfo("全ての行の選択を解除しました: $previousCount行");
        }
      });
      widget.onSelectionChanged?.call(_selectedRows);
    } catch (e, stackTrace) {
      logError("全選択処理中にエラーが発生: selectAll=$selectAll", e, stackTrace);
    }
  }

  void _handleRowSelection(int index, bool selected) {
    try {
      logTrace("行選択を変更: index=$index, selected=$selected");
      setState(() {
        if (selected) {
          _selectedRows.add(index);
        } else {
          _selectedRows.remove(index);
        }
      });
      logDebug("選択行数を更新: ${_selectedRows.length}行選択中");
      widget.onSelectionChanged?.call(_selectedRows);
    } catch (e, stackTrace) {
      logError("行選択処理中にエラーが発生: index=$index, selected=$selected", e, stackTrace);
    }
  }
}

/// データテーブルアクション
class DataTableAction extends StatelessWidget {
  const DataTableAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: TextButton.styleFrom(foregroundColor: color ?? AppColors.primary),
  );
}

/// カスタムデータセル
class AppDataCell extends DataCell {
  AppDataCell.text(String text, {TextStyle? style, VoidCallback? onTap})
    : super(Text(text, style: style ?? AppTextTheme.cardDescription), onTap: onTap);

  AppDataCell.status(String status, {required Color color, VoidCallback? onTap})
    : super(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            status,
            style: AppTextTheme.cardDescription.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: onTap,
      );

  AppDataCell.actions(List<Widget> actions, {VoidCallback? onTap})
    : super(
        Row(mainAxisSize: MainAxisSize.min, children: actions),
        onTap: onTap,
      );
}
