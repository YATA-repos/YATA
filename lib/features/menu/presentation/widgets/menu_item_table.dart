import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../controllers/menu_management_controller.dart";

/// メニューアイテム一覧テーブル。
class MenuItemTable extends StatelessWidget {
  /// [MenuItemTable]を生成する。
  const MenuItemTable({
    required this.items,
    required this.selectedItemId,
    required this.availabilityFor,
    required this.onSelectItem,
    required this.onToggleAvailability,
    required this.isBusy,
    required this.savingItemIds,
    super.key,
  });

  /// 表示対象のメニューアイテム。
  final List<MenuItemViewData> items;

  /// 選択中のアイテムID。
  final String? selectedItemId;

  /// 在庫可用性取得コールバック。
  final MenuAvailabilityViewData Function(String menuItemId) availabilityFor;

  /// 行選択時のコールバック。
  final ValueChanged<MenuItemViewData> onSelectItem;

  /// 販売可否トグル時のコールバック。
  final Future<void> Function(MenuItemViewData item, bool isAvailable)? onToggleAvailability;

  /// テーブルの読み込み中フラグ。
  final bool isBusy;

  /// 保存処理中のメニューID集合。
  final Set<String> savingItemIds;

  static final NumberFormat _currency = NumberFormat.currency(locale: "ja_JP", symbol: "¥");
  static final DateFormat _dateTimeFormat = DateFormat("MM/dd HH:mm");

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<DataColumn> columns = <DataColumn>[
      const DataColumn(label: Text("カテゴリ")),
      const DataColumn(label: Text("商品名")),
      const DataColumn(label: Text("価格")),
      const DataColumn(label: Text("表示順"), numeric: true),
      const DataColumn(label: Text("在庫/提供")),
      const DataColumn(label: Text("更新")),
      const DataColumn(label: Text("販売状態")),
    ];

    final List<DataRow> rows = <DataRow>[
      for (final MenuItemViewData item in items)
        DataRow(
          key: ValueKey<String>(item.id),
          selected: selectedItemId == item.id,
          onSelectChanged: (_) => onSelectItem(item),
          cells: <DataCell>[
            DataCell(Text(item.categoryName)),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(item.name, style: textTheme.titleMedium ?? YataTypographyTokens.titleMedium),
                  if (item.description != null && item.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
                      child: Text(
                        item.description!,
                        style: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall).copyWith(
                          color: YataColorTokens.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            DataCell(Text(_currency.format(item.price))),
            DataCell(Text(item.displayOrder.toString())),
            DataCell(_buildAvailabilityBadge(context, item)),
            DataCell(Text(_formatTimestamp(item))),
            DataCell(_buildAvailabilityToggle(item)),
          ],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (isBusy) const LinearProgressIndicator(minHeight: 2),
        if (items.isEmpty)
          Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: YataColorTokens.neutral100,
              borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
            ),
            child: Text(
              "表示対象のメニューがありません",
              style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
            ),
          )
        else
          YataDataTable(columns: columns, rows: rows, shrinkWrap: true),
      ],
    );
  }

  Widget _buildAvailabilityToggle(MenuItemViewData item) {
    final bool isSaving = savingItemIds.contains(item.id);
    final bool disabled = onToggleAvailability == null || isSaving;
    final Widget switcher = Switch.adaptive(
      value: item.isAvailable,
      onChanged: disabled ? null : (bool value) => onToggleAvailability?.call(item, value),
    );

    if (!isSaving) {
      return switcher;
    }
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        switcher,
        const Positioned.fill(
          child: Align(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityBadge(BuildContext context, MenuItemViewData item) {
    final MenuAvailabilityViewData availability = availabilityFor(item.id);
    switch (availability.status) {
      case MenuAvailabilityStatus.loading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case MenuAvailabilityStatus.available:
        final int servings = availability.info?.estimatedServings ?? 0;
        return Tooltip(
          message: "推定提供可能数: $servings",
          child: YataStatusBadge(
            label: "提供可",
            type: YataStatusBadgeType.success,
            icon: Icons.check_circle_outline,
          ),
        );
      case MenuAvailabilityStatus.unavailable:
        final List<String> missing = availability.info?.missingMaterials ?? <String>[];
        final String message = missing.isEmpty ? "在庫不足" : "不足材料: ${missing.join(', ')}";
        return Tooltip(
          message: message,
          child: YataStatusBadge(
            label: "要補充",
            type: YataStatusBadgeType.danger,
            icon: Icons.error_outline,
          ),
        );
      case MenuAvailabilityStatus.error:
        return Tooltip(
          message: availability.errorMessage ?? "在庫可用性を取得できませんでした",
          child: YataStatusBadge(
            label: "不明",
            type: YataStatusBadgeType.warning,
            icon: Icons.help_outline,
          ),
        );
      case MenuAvailabilityStatus.idle:
        return Tooltip(
          message: "在庫チェック未実行",
          child: const YataStatusBadge(label: "未取得", icon: Icons.hourglass_bottom),
        );
    }
  }

  String _formatTimestamp(MenuItemViewData item) {
    final DateTime? timestamp = item.updatedAt ?? item.createdAt;
    if (timestamp == null) {
      return "-";
    }
    return _dateTimeFormat.format(timestamp);
  }
}
