import "package:flutter/material.dart";

import "../../../../shared/components/category/category_panel.dart";
import "../../../../shared/components/data_display/status_badge.dart";
import "../../models/inventory_model.dart";
import "../controllers/inventory_management_controller.dart";

/// 在庫カテゴリ一覧を表示するパネル。
class InventoryCategoryPanel extends StatelessWidget {
  const InventoryCategoryPanel({
    required this.state,
    required this.onCategorySelected,
    required this.onCreateCategory,
    super.key,
    this.onEditCategory,
    this.onDeleteCategory,
  });

  final InventoryManagementState state;
  final ValueChanged<int> onCategorySelected;
  final VoidCallback onCreateCategory;
  final ValueChanged<InventoryCategoryPanelData>? onEditCategory;
  final ValueChanged<InventoryCategoryPanelData>? onDeleteCategory;

  @override
  Widget build(BuildContext context) {
    final List<InventoryCategoryPanelData> summaries = _buildSummaries(state);
    final String? selectedId = _resolveSelectedId(state);

    return CategoryPanel<InventoryCategoryPanelData>(
      items: summaries.map(_toItem).toList(growable: false),
      selectedId: selectedId,
      onSelect: (String? id) => onCategorySelected(_resolveIndex(id, state.categories)),
      onAdd: onCreateCategory,
      isLoading: state.isLoading,
      onEdit: onEditCategory,
      onDelete: onDeleteCategory,
    );
  }

  CategoryPanelItem<InventoryCategoryPanelData> _toItem(InventoryCategoryPanelData summary) {
    final String totalLabel = "登録 ${summary.total}件";

    final bool actionsEnabled =
        summary.categoryId != null && (onEditCategory != null || onDeleteCategory != null);

    return CategoryPanelItem<InventoryCategoryPanelData>(
      payload: summary,
      id: summary.index == 0 ? null : summary.name,
      name: summary.name,
      isAll: summary.index == 0,
      headerBadge: CategoryPanelBadgeData(label: totalLabel, type: YataStatusBadgeType.info),
      enableActions: actionsEnabled,
    );
  }

  String? _resolveSelectedId(InventoryManagementState state) {
    if (state.selectedCategoryIndex <= 0 ||
        state.selectedCategoryIndex >= state.categories.length) {
      return null;
    }
    return state.categories[state.selectedCategoryIndex];
  }

  int _resolveIndex(String? name, List<String> categories) {
    if (name == null) {
      return 0;
    }
    final int index = categories.indexOf(name);
    return index >= 0 ? index : 0;
  }

  List<InventoryCategoryPanelData> _buildSummaries(InventoryManagementState state) {
    final Map<String, MaterialCategory> categoryByName = <String, MaterialCategory>{};
    for (final MaterialCategory category in state.categoryEntities) {
      final String key = category.name.trim();
      if (key.isEmpty || categoryByName.containsKey(key)) {
        continue;
      }
      categoryByName[key] = category;
    }

    final List<InventoryCategoryPanelData> summaries = <InventoryCategoryPanelData>[
      const InventoryCategoryPanelData(
        name: "すべて",
        index: 0,
        total: 0,
        low: 0,
        critical: 0,
        categoryId: null,
      ),
    ];

    final Map<String, List<InventoryItemViewData>> grouped =
        <String, List<InventoryItemViewData>>{};
    for (final InventoryItemViewData item in state.items) {
      final String category = item.category;
      grouped.putIfAbsent(category, () => <InventoryItemViewData>[]).add(item);
    }

    for (int i = 1; i < state.categories.length; i++) {
      final String categoryName = state.categories[i];
      final List<InventoryItemViewData> items = grouped[categoryName] ?? <InventoryItemViewData>[];
      final int total = items.length;
      final int low = items
          .where((InventoryItemViewData item) => item.status == StockStatus.low)
          .length;
      final int critical = items
          .where((InventoryItemViewData item) => item.status == StockStatus.critical)
          .length;
      final MaterialCategory? entity = categoryByName[categoryName.trim()];

      summaries.add(
        InventoryCategoryPanelData(
          name: categoryName,
          index: i,
          total: total,
          low: low,
          critical: critical,
          categoryId: entity?.id,
        ),
      );
    }

    if (summaries.isNotEmpty) {
      final InventoryCategoryPanelData first = summaries.first;
      summaries[0] = first.copyWith(
        total: state.totalItems,
        low: state.lowCount,
        critical: state.criticalCount,
      );
    }

    return summaries;
  }
}

class InventoryCategoryPanelData {
  const InventoryCategoryPanelData({
    required this.name,
    required this.index,
    required this.total,
    required this.low,
    required this.critical,
    required this.categoryId,
  });

  final String name;
  final int index;
  final int total;
  final int low;
  final int critical;
  final String? categoryId;

  int get adequate {
    final int value = total - low - critical;
    return value < 0 ? 0 : value;
  }

  InventoryCategoryPanelData copyWith({
    String? name,
    int? index,
    int? total,
    int? low,
    int? critical,
    String? categoryId,
  }) => InventoryCategoryPanelData(
    name: name ?? this.name,
    index: index ?? this.index,
    total: total ?? this.total,
    low: low ?? this.low,
    critical: critical ?? this.critical,
    categoryId: categoryId ?? this.categoryId,
  );
}
