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

    final List<YataTableRowSpec> rows = items.map(_buildRow).toList(growable: false);

    return YataDataTable.fromSpecs(
      columns: _columnSpecs,
      rows: rows,
      onRowTap: (int index) => onRowTap(items[index].id),
      dataRowMinHeight: 60,
      dataRowMaxHeight: 68,
      columnSpacing: YataSpacingTokens.xl,
    );
  }

  static const List<YataTableColumnSpec> _columnSpecs = <YataTableColumnSpec>[
    YataTableColumnSpec(id: "menu", label: Text("メニュー")),
    YataTableColumnSpec(id: "category", label: Text("カテゴリ")),
    YataTableColumnSpec(
      id: "price",
      label: Text("価格"),
      numeric: true,
      defaultAlignment: Alignment.centerRight,
    ),
    YataTableColumnSpec(id: "status", label: Text("ステータス")),
    YataTableColumnSpec(id: "stockNote", label: Text("在庫メモ")),
    YataTableColumnSpec(id: "updatedAt", label: Text("更新日時")),
    YataTableColumnSpec(id: "availability", label: Text("販売状態")),
  ];

  YataTableRowSpec _buildRow(MenuItemViewData item) {
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
        ? (item.isStockAvailable ? "適切" : "在庫未取得")
        : item.missingMaterials.join(", ");

    return YataTableRowSpec(
      id: item.id,
      semanticLabel: item.name,
      cells: <YataTableCellSpec>[
        YataTableCellSpec.text(
          label: item.name,
          description: item.description,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          descriptionStyle: const TextStyle(color: YataColorTokens.textSecondary, fontSize: 12),
          descriptionMaxLines: 1,
        ),
        YataTableCellSpec.text(label: item.categoryName),
        YataTableCellSpec.text(label: price, alignment: Alignment.centerRight),
        YataTableCellSpec.badges(badges: statusBadges),
        YataTableCellSpec.text(label: stockNote, labelMaxLines: 1),
        YataTableCellSpec.text(label: updatedAt),
        YataTableCellSpec.widget(
          builder: (_) => _AvailabilityToggle(
            menuId: item.id,
            isAvailable: item.isAvailable,
            isBusy: isToggleBusy,
            onToggleAvailability: onToggleAvailability,
          ),
          errorMessage: error,
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
