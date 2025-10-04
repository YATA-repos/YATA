import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../controllers/menu_management_state.dart";

/// メニュー一覧を表示するテーブル。
class MenuItemTable extends StatelessWidget {
  /// [MenuItemTable]を生成する。
  const MenuItemTable({
    required this.items,
    required this.onRowTap,
    super.key,
    this.isBusy = false,
    this.onToggleAvailability,
    this.busyMenuIds = const <String>{},
    this.availabilityErrors = const <String, String>{},
  });

  /// テーブルに表示する行データ。
  final List<MenuItemViewData> items;

  /// 行をタップした際のコールバック。
  final ValueChanged<String> onRowTap;

  /// 販売可否トグル操作時のコールバック。
  final Future<void> Function(String menuItemId, bool nextAvailability)? onToggleAvailability;

  /// 行単位で処理中のメニューID。
  final Set<String> busyMenuIds;

  /// 行単位のエラーメッセージ。
  final Map<String, String> availabilityErrors;

  /// 操作中かどうか。
  final bool isBusy;

  static final NumberFormat _currencyFormat = NumberFormat.decimalPattern("ja_JP");
  static final DateFormat _dateFormat = DateFormat("MM/dd HH:mm");

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: YataSpacingTokens.xl,
          vertical: YataSpacingTokens.lg,
        ),
        decoration: BoxDecoration(
          color: YataColorTokens.neutral0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: YataColorTokens.border),
        ),
        child: const Center(child: Text("登録済みのメニューがありません")),
      );
    }

    final List<DataRow> rows = items.map(_buildRow).toList(growable: false);

    return YataDataTable(
      columns: _buildColumns(),
      rows: rows,
      onRowTap: (int index) => onRowTap(items[index].id),
      dataRowMinHeight: 60,
      dataRowMaxHeight: 68,
      columnSpacing: YataSpacingTokens.xl,
    );
  }

  List<DataColumn> _buildColumns() => const <DataColumn>[
    DataColumn(label: Text("メニュー")),
    DataColumn(label: Text("カテゴリ")),
    DataColumn(label: Text("価格")),
    DataColumn(label: Text("ステータス")),
    DataColumn(label: Text("在庫メモ")),
    DataColumn(label: Text("更新日時")),
    DataColumn(label: Text("販売状態")),
  ];

  DataRow _buildRow(MenuItemViewData item) {
    final bool isToggleBusy = isBusy || busyMenuIds.contains(item.id);
    final String? error = availabilityErrors[item.id];
    final List<Widget> statusBadges = <Widget>[
      if (item.isAvailable && item.isStockAvailable)
        const YataStatusBadge(label: "提供可", type: YataStatusBadgeType.success)
      else if (!item.isAvailable)
        const YataStatusBadge(label: "販売停止", type: YataStatusBadgeType.danger)
      else
        const YataStatusBadge(label: "在庫不足", type: YataStatusBadgeType.warning),
      if (!item.hasRecipe)
        const YataStatusBadge(label: "レシピ未登録", type: YataStatusBadgeType.warning),
    ];

    final String price = "¥${_currencyFormat.format(item.price)}";
    final String updatedAt = item.updatedAt == null ? "-" : _dateFormat.format(item.updatedAt!);
    final String stockNote = item.missingMaterials.isEmpty
        ? (item.isStockAvailable ? "在庫良好" : "在庫未取得")
        : item.missingMaterials.join(", ");

    return DataRow(
      cells: <DataCell>[
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (item.description != null && item.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: YataColorTokens.textSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        DataCell(Text(item.categoryName)),
        DataCell(Text(price)),
        DataCell(Wrap(spacing: YataSpacingTokens.xs, children: statusBadges)),
        DataCell(Text(stockNote, maxLines: 1, overflow: TextOverflow.ellipsis)),
        DataCell(Text(updatedAt)),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AvailabilityToggle(
                menuId: item.id,
                isAvailable: item.isAvailable,
                isBusy: isToggleBusy,
                onToggleAvailability: onToggleAvailability,
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    error,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: YataColorTokens.danger, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({
    required this.menuId,
    required this.isAvailable,
    required this.isBusy,
    this.onToggleAvailability,
  });

  final String menuId;
  final bool isAvailable;
  final bool isBusy;
  final Future<void> Function(String menuItemId, bool nextAvailability)? onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasHandler = onToggleAvailability != null;
    final bool interactionEnabled = hasHandler && !isBusy;

    Future<void> handleSelection(bool nextAvailability) async {
      if (!hasHandler || nextAvailability == isAvailable) {
        return;
      }
      await onToggleAvailability!(menuId, nextAvailability);
    }

    final TextStyle labelStyle = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: isAvailable ? YataColorTokens.primary : YataColorTokens.textSecondary,
    );

    final Widget label = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: interactionEnabled
          ? () async {
              await handleSelection(!isAvailable);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: YataSpacingTokens.xs),
        child: Text(isAvailable ? "販売中" : "販売停止", style: labelStyle),
      ),
    );

    Widget toggleContent = AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: interactionEnabled ? 1 : 0.6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Switch.adaptive(
            value: isAvailable,
            onChanged: interactionEnabled
                ? (bool next) async {
                    await handleSelection(next);
                  }
                : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          label,
        ],
      ),
    );

    if (isBusy) {
      toggleContent = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ExcludeSemantics(child: toggleContent),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Semantics(
        container: true,
        label: "販売状態",
        value: isAvailable ? "販売中" : "販売停止",
        hint: isBusy ? "処理中です" : "トグルして販売状態を切り替えます",
        toggled: isAvailable,
        enabled: interactionEnabled,
        child: toggleContent,
      ),
    );
  }
}
