import "package:flutter/material.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../controllers/menu_management_state.dart";

/// カテゴリ一覧を表示するパネル。
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
  Widget build(BuildContext context) => YataSectionCard(
      title: "カテゴリ",
      borderColor: Colors.transparent,
      expandChild: true,
      actions: <Widget>[
        if (onAddCategory != null)
          YataIconButton(icon: Icons.add, tooltip: "カテゴリを追加", onPressed: onAddCategory),
      ],
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _CategoryList(
              categories: categories,
              selectedCategoryId: selectedCategoryId,
              onCategorySelected: onCategorySelected,
              onEditCategory: onEditCategory,
              onDeleteCategory: onDeleteCategory,
            ),
    );
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.onEditCategory,
    this.onDeleteCategory,
  });

  final List<MenuCategoryViewData> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<MenuCategoryViewData>? onEditCategory;
  final ValueChanged<MenuCategoryViewData>? onDeleteCategory;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text("カテゴリが登録されていません"));
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: YataSpacingTokens.sm),
      itemBuilder: (BuildContext context, int index) {
        final MenuCategoryViewData category = categories[index];
        final bool selected = category.isAll
            ? selectedCategoryId == null
            : category.id == selectedCategoryId;
        return _CategoryTile(
          category: category,
          selected: selected,
          onTap: () => onCategorySelected(category.id),
          onEdit: onEditCategory,
          onDelete: onDeleteCategory,
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final MenuCategoryViewData category;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<MenuCategoryViewData>? onEdit;
  final ValueChanged<MenuCategoryViewData>? onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = selected ? YataColorTokens.primary : YataColorTokens.textSecondary;
    final Color background = selected ? YataColorTokens.primarySoft : YataColorTokens.neutral100;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(YataSpacingTokens.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? YataColorTokens.primary : YataColorTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      category.name,
                      style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  YataStatusBadge(
                    label: "${category.availableItems}/${category.totalItems}",
                    type: YataStatusBadgeType.success,
                  ),
                  if (!category.isAll && (onEdit != null || onDelete != null))
                    PopupMenuButton<_CategoryAction>(
                      tooltip: "カテゴリ操作",
                      onSelected: (_CategoryAction action) {
                        switch (action) {
                          case _CategoryAction.edit:
                            onEdit?.call(category);
                            break;
                          case _CategoryAction.delete:
                            onDelete?.call(category);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<_CategoryAction>>[
                        if (onEdit != null)
                          const PopupMenuItem<_CategoryAction>(
                            value: _CategoryAction.edit,
                            child: Text("名称を変更"),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem<_CategoryAction>(
                            value: _CategoryAction.delete,
                            child: Text("削除"),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: YataSpacingTokens.xs),
              Row(
                children: <Widget>[
                  Icon(Icons.circle, size: 8, color: YataColorTokens.textSecondary),
                  const SizedBox(width: YataSpacingTokens.xs),
                  Text("提供可能 ${category.availableItems}件", style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: YataSpacingTokens.xxs),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.report_gmailerrorred_outlined,
                    size: 12,
                    color: YataColorTokens.warning,
                  ),
                  const SizedBox(width: YataSpacingTokens.xs),
                  Text(
                    "要確認 ${category.attentionItems}件",
                    style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                      color: YataColorTokens.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CategoryAction { edit, delete }
