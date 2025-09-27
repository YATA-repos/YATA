import "dart:math" as math;

import "package:flutter/material.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../controllers/menu_management_controller.dart";

/// メニュー管理画面のカテゴリパネル。
class MenuCategoryPanel extends StatelessWidget {
  /// [MenuCategoryPanel]を生成する。
  const MenuCategoryPanel({
    required this.state,
    required this.controller,
    required this.searchController,
    required this.onCreateCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    super.key,
  });

  /// 現在の画面状態。
  final MenuManagementState state;

  /// 状態制御用のコントローラー。
  final MenuManagementController controller;

  /// カテゴリ検索テキストコントローラ。
  final TextEditingController searchController;

  /// カテゴリ追加時に呼び出すコールバック。
  final VoidCallback onCreateCategory;

  /// カテゴリ編集時に呼び出すコールバック。
  final ValueChanged<MenuCategoryViewData> onEditCategory;

  /// カテゴリ削除時に呼び出すコールバック。
  final ValueChanged<MenuCategoryViewData> onDeleteCategory;

  static const double _rowHeight = 64;

  @override
  Widget build(BuildContext context) {
    final List<MenuCategoryViewData> visibleCategories = state.visibleCategories;
    final bool isFiltered = state.categoryQuery.trim().isNotEmpty;
    final int totalItems = state.items.length;
    final int availableItems = state.items
        .where(
          (MenuItemViewData item) => state.availabilityFor(item.id).isAvailable && item.isAvailable,
        )
        .length;
    final int pausedItems = state.items.where((MenuItemViewData item) => !item.isAvailable).length;
    final int insufficientItems = state.items.where((MenuItemViewData item) {
      final MenuAvailabilityViewData availability = state.availabilityFor(item.id);
      return availability.status == MenuAvailabilityStatus.unavailable ||
          availability.status == MenuAvailabilityStatus.error;
    }).length;

    return YataSectionCard(
      title: "カテゴリ",
      subtitle: "ドラッグ&ドロップで表示順を調整できます",
      actions: <Widget>[
        FilledButton.icon(
          onPressed: onCreateCategory,
          icon: const Icon(Icons.add),
          label: const Text("カテゴリ追加"),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          YataSearchField(
            controller: searchController,
            hintText: "カテゴリ名で検索",
            onChanged: controller.updateCategorySearch,
          ),
          const SizedBox(height: YataSpacingTokens.md),
          Wrap(
            spacing: YataSpacingTokens.sm,
            runSpacing: YataSpacingTokens.xs,
            children: <Widget>[
              YataStatusBadge(
                label: "カテゴリ ${state.categories.length}件",
                type: YataStatusBadgeType.info,
              ),
              if (isFiltered)
                YataStatusBadge(
                  label: "表示 ${visibleCategories.length}件",
                  type: YataStatusBadgeType.warning,
                ),
              YataStatusBadge(label: "登録メニュー $totalItems件"),
              YataStatusBadge(label: "提供可 $availableItems件", type: YataStatusBadgeType.success),
              YataStatusBadge(label: "販売停止 $pausedItems件", type: YataStatusBadgeType.warning),
              YataStatusBadge(label: "在庫注意 $insufficientItems件", type: YataStatusBadgeType.danger),
            ],
          ),
          const SizedBox(height: YataSpacingTokens.md),
          _AllCategoryTile(
            isSelected: state.selectedCategoryId == null,
            totalItems: totalItems,
            availableItems: availableItems,
            insufficientItems: insufficientItems,
            onTap: () => controller.selectCategory(null),
          ),
          const SizedBox(height: YataSpacingTokens.md),
          if (visibleCategories.isEmpty)
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: YataColorTokens.neutral100,
                borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
              ),
              child: Text(
                isFiltered ? "条件に合致するカテゴリがありません" : "カテゴリがまだ登録されていません",
                style: Theme.of(context).textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
              ),
            )
          else
            SizedBox(
              height: math.min<double>(visibleCategories.length * _rowHeight + 12, 420),
              child: ReorderableListView.builder(
                padding: EdgeInsets.zero,
                itemCount: visibleCategories.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (int oldIndex, int newIndex) {
                  if (isFiltered) {
                    return;
                  }
                  controller.reorderCategories(oldIndex, newIndex);
                },
                itemBuilder: (BuildContext context, int index) {
                  final MenuCategoryViewData category = visibleCategories[index];
                  return _CategoryTile(
                    key: ValueKey<String>(category.id),
                    category: category,
                    isSelected: state.selectedCategoryId == category.id,
                    index: index,
                    onTap: () => controller.selectCategory(category.id),
                    onEdit: () => onEditCategory(category),
                    onDelete: () => onDeleteCategory(category),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AllCategoryTile extends StatelessWidget {
  const _AllCategoryTile({
    required this.isSelected,
    required this.totalItems,
    required this.availableItems,
    required this.insufficientItems,
    required this.onTap,
  });

  final bool isSelected;
  final int totalItems;
  final int availableItems;
  final int insufficientItems;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color bg = isSelected ? YataColorTokens.primarySoft : YataColorTokens.neutral0;
    final Color fg = isSelected ? YataColorTokens.primary : YataColorTokens.textPrimary;

    return Material(
      color: bg,
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YataSpacingTokens.md,
            vertical: YataSpacingTokens.sm,
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.view_list_outlined, color: fg),
              const SizedBox(width: YataSpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "すべてのカテゴリ",
                      style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium).copyWith(
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: YataSpacingTokens.xs),
                    Text(
                      "合計$availableItems件提供可・$insufficientItems件要確認",
                      style: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall).copyWith(
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "$totalItems",
                style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium).copyWith(
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final MenuCategoryViewData category;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color fg = isSelected ? YataColorTokens.primary : YataColorTokens.textPrimary;
    final Color bg = isSelected ? YataColorTokens.primarySoft : Colors.transparent;

    return Material(
      key: key,
      color: bg,
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YataSpacingTokens.sm,
            vertical: YataSpacingTokens.xs,
          ),
          child: Row(
            children: <Widget>[
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_indicator, color: fg.withValues(alpha: 0.8)),
              ),
              const SizedBox(width: YataSpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      category.name,
                      style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium).copyWith(
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: YataSpacingTokens.xs),
                    Text(
                      "表示順 ${category.displayOrder} / メニュー ${category.itemCount}件",
                      style: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall).copyWith(
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "カテゴリを編集",
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: fg.withValues(alpha: 0.9)),
              ),
              IconButton(
                tooltip: "カテゴリを削除",
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: YataColorTokens.danger),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
