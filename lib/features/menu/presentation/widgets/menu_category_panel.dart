import "package:flutter/material.dart";

import "../../../../shared/components/category/category_panel.dart";
import "../../../../shared/components/data_display/status_badge.dart";
import "../controllers/menu_management_state.dart";

/// メニューカテゴリ一覧を表示するパネル。
class MenuCategoryPanel extends StatelessWidget {
  /// [MenuCategoryPanel]を生成する。
  const MenuCategoryPanel({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    super.key,
    this.onAddCategory,
    this.isLoading = false,
    this.onEditCategory,
    this.onDeleteCategory,
  });

  /// 表示対象のカテゴリ一覧。
  final List<MenuCategoryViewData> categories;

  /// 選択中のカテゴリID。
  final String? selectedCategoryId;

  /// カテゴリ選択時のコールバック。
  final ValueChanged<String?> onCategorySelected;

  /// カテゴリ追加ボタン押下時のコールバック。
  final VoidCallback? onAddCategory;

  /// 読み込み中かどうか。
  final bool isLoading;

  /// カテゴリ編集要求。
  final ValueChanged<MenuCategoryViewData>? onEditCategory;

  /// カテゴリ削除要求。
  final ValueChanged<MenuCategoryViewData>? onDeleteCategory;

  @override
  Widget build(BuildContext context) => CategoryPanel<MenuCategoryViewData>(
    items: categories.map(_mapToItem).toList(growable: false),
    selectedId: selectedCategoryId,
    onSelect: onCategorySelected,
    onAdd: onAddCategory,
    onEdit: onEditCategory,
    onDelete: onDeleteCategory,
    isLoading: isLoading,
  );

  CategoryPanelItem<MenuCategoryViewData> _mapToItem(MenuCategoryViewData category) {
    final bool isAll = category.isAll;

    return CategoryPanelItem<MenuCategoryViewData>(
      payload: category,
      id: category.id,
      name: category.name,
      isAll: isAll,
      headerBadge: CategoryPanelBadgeData(
        label: "登録 ${category.totalItems}件",
        type: YataStatusBadgeType.info,
      ),
    );
  }
}
