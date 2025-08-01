import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";
import "../common/app_badge.dart";

/// CategoryFilter - カテゴリフィルターコンポーネント
///
/// 既存のAppColors・AppTextThemeを活用し、
/// メニューカテゴリ・在庫カテゴリ等のフィルタリング機能を提供します。
class CategoryFilter extends StatelessWidget {
  const CategoryFilter({
    required this.categories,
    this.selectedCategories = const <String>[],
    this.onSelectionChanged,
    this.variant = CategoryFilterVariant.chips,
    this.allowMultipleSelection = false,
    this.showAllOption = true,
    this.allOptionText = "すべて",
    this.maxDisplayedItems,
    super.key,
  });

  final List<CategoryOption> categories;
  final List<String> selectedCategories;
  final ValueChanged<List<String>>? onSelectionChanged;
  final CategoryFilterVariant variant;
  final bool allowMultipleSelection;
  final bool showAllOption;
  final String allOptionText;
  final int? maxDisplayedItems;

  bool get _isAllSelected => selectedCategories.isEmpty;

  @override
  Widget build(BuildContext context) => switch (variant) {
    CategoryFilterVariant.chips => _buildChipFilter(),
    CategoryFilterVariant.list => _buildListFilter(),
    CategoryFilterVariant.grid => _buildGridFilter(),
    CategoryFilterVariant.dropdown => _buildDropdownFilter(),
  };

  Widget _buildChipFilter() {
    final List<CategoryOption> displayCategories = _getDisplayCategories();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        // "すべて"オプション
        if (showAllOption) ...<Widget>[
          _buildChip(text: allOptionText, value: "", isSelected: _isAllSelected),
        ],

        // カテゴリオプション
        ...displayCategories.map(
          (CategoryOption category) => _buildChip(
            text: category.label,
            value: category.value,
            isSelected: selectedCategories.contains(category.value),
            count: category.count,
            icon: category.icon,
          ),
        ),

        // もっと見るボタン
        if (_hasMoreItems()) ...<Widget>[_buildMoreButton()],
      ],
    );
  }

  Widget _buildListFilter() {
    final List<CategoryOption> displayCategories = _getDisplayCategories();

    return Column(
      children: <Widget>[
        // "すべて"オプション
        if (showAllOption) ...<Widget>[
          _buildListItem(text: allOptionText, value: "", isSelected: _isAllSelected),
        ],

        // カテゴリオプション
        ...displayCategories.map(
          (CategoryOption category) => _buildListItem(
            text: category.label,
            value: category.value,
            isSelected: selectedCategories.contains(category.value),
            count: category.count,
            icon: category.icon,
          ),
        ),
      ],
    );
  }

  Widget _buildGridFilter() {
    final List<CategoryOption> displayCategories = _getDisplayCategories();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: <Widget>[
        // "すべて"オプション
        if (showAllOption) ...<Widget>[
          _buildGridItem(text: allOptionText, value: "", isSelected: _isAllSelected),
        ],

        // カテゴリオプション
        ...displayCategories.map(
          (CategoryOption category) => _buildGridItem(
            text: category.label,
            value: category.value,
            isSelected: selectedCategories.contains(category.value),
            count: category.count,
            icon: category.icon,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter() => DropdownButtonFormField<String>(
    value: _isAllSelected ? "" : selectedCategories.first,
    decoration: InputDecoration(
      labelText: "カテゴリ",
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    ),
    items: <DropdownMenuItem<String>>[
      // "すべて"オプション
      if (showAllOption) ...<DropdownMenuItem<String>>[
        DropdownMenuItem<String>(value: "", child: Text(allOptionText)),
      ],

      // カテゴリオプション
      ...categories.map(
        (CategoryOption category) => DropdownMenuItem<String>(
          value: category.value,
          child: Row(
            children: <Widget>[
              if (category.icon != null) ...<Widget>[
                Icon(category.icon, size: 16),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(category.label)),
              if (category.count != null) ...<Widget>[CountBadge(count: category.count!)],
            ],
          ),
        ),
      ),
    ],
    onChanged: (String? value) {
      if (value != null) {
        _handleSelection(value);
      }
    },
  );

  Widget _buildChip({
    required String text,
    required String value,
    required bool isSelected,
    int? count,
    IconData? icon,
  }) => FilterChip(
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[Icon(icon, size: 14), const SizedBox(width: 4)],
        Text(text),
        if (count != null) ...<Widget>[
          const SizedBox(width: 4),
          CountBadge(
            count: count,
            variant: isSelected ? BadgeVariant.primary : BadgeVariant.default_,
          ),
        ],
      ],
    ),
    selected: isSelected,
    onSelected: (_) => _handleSelection(value),
    backgroundColor: AppColors.muted,
    selectedColor: AppColors.primaryHover,
    labelStyle: AppTextTheme.cardDescription.copyWith(
      color: isSelected ? AppColors.primary : AppColors.foreground,
      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
    ),
    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
  );

  Widget _buildListItem({
    required String text,
    required String value,
    required bool isSelected,
    int? count,
    IconData? icon,
  }) => InkWell(
    onTap: () => _handleSelection(value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryHover : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.foreground),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              style: AppTextTheme.cardTitle.copyWith(
                fontSize: 14,
                color: isSelected ? AppColors.primary : AppColors.foreground,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (count != null) ...<Widget>[
            CountBadge(
              count: count,
              variant: isSelected ? BadgeVariant.primary : BadgeVariant.default_,
            ),
          ],
          if (isSelected) ...<Widget>[
            const SizedBox(width: 8),
            Icon(LucideIcons.check, size: 16, color: AppColors.primary),
          ],
        ],
      ),
    ),
  );

  Widget _buildGridItem({
    required String text,
    required String value,
    required bool isSelected,
    int? count,
    IconData? icon,
  }) => InkWell(
    onTap: () => _handleSelection(value),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryHover : AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.foreground),
            const SizedBox(height: 4),
          ],
          Text(
            text,
            style: AppTextTheme.cardDescription.copyWith(
              color: isSelected ? AppColors.primary : AppColors.foreground,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (count != null) ...<Widget>[
            const SizedBox(height: 2),
            CountBadge(
              count: count,
              variant: isSelected ? BadgeVariant.primary : BadgeVariant.default_,
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildMoreButton() => InkWell(
    onTap: () {
      // "もっと見る"機能の実装
      // 通常はダイアログやボトムシートを表示
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(LucideIcons.moreHorizontal, size: 14, color: AppColors.mutedForeground),
          const SizedBox(width: 4),
          Text("もっと見る", style: AppTextTheme.cardDescription),
        ],
      ),
    ),
  );

  List<CategoryOption> _getDisplayCategories() {
    if (maxDisplayedItems == null) {
      return categories;
    }
    return categories.take(maxDisplayedItems!).toList();
  }

  bool _hasMoreItems() => maxDisplayedItems != null && categories.length > maxDisplayedItems!;

  void _handleSelection(String value) {
    List<String> newSelection;

    if (value.isEmpty) {
      // "すべて"が選択された場合
      newSelection = <String>[];
    } else if (allowMultipleSelection) {
      // 複数選択モード
      newSelection = List<String>.from(selectedCategories);
      if (newSelection.contains(value)) {
        newSelection.remove(value);
      } else {
        newSelection.add(value);
      }
    } else {
      // 単一選択モード
      newSelection = <String>[value];
    }

    onSelectionChanged?.call(newSelection);
  }
}

/// メニューカテゴリフィルター
class MenuCategoryFilter extends StatelessWidget {
  const MenuCategoryFilter({
    this.selectedCategories = const <String>[],
    this.onSelectionChanged,
    this.variant = CategoryFilterVariant.chips,
    super.key,
  });

  final List<String> selectedCategories;
  final ValueChanged<List<String>>? onSelectionChanged;
  final CategoryFilterVariant variant;

  @override
  Widget build(BuildContext context) => CategoryFilter(
    categories: const <CategoryOption>[
      CategoryOption(value: "main", label: "メイン", icon: LucideIcons.utensils, count: 25),
      CategoryOption(value: "side", label: "サイド", icon: LucideIcons.salad, count: 12),
      CategoryOption(value: "drink", label: "ドリンク", icon: LucideIcons.glassWater, count: 18),
      CategoryOption(value: "dessert", label: "デザート", icon: LucideIcons.candyOff, count: 8),
    ],
    selectedCategories: selectedCategories,
    onSelectionChanged: onSelectionChanged,
    variant: variant,
  );
}

/// 在庫カテゴリフィルター
class InventoryCategoryFilter extends StatelessWidget {
  const InventoryCategoryFilter({
    this.selectedCategories = const <String>[],
    this.onSelectionChanged,
    this.variant = CategoryFilterVariant.chips,
    super.key,
  });

  final List<String> selectedCategories;
  final ValueChanged<List<String>>? onSelectionChanged;
  final CategoryFilterVariant variant;

  @override
  Widget build(BuildContext context) => CategoryFilter(
    categories: const <CategoryOption>[
      CategoryOption(value: "ingredients", label: "食材", icon: LucideIcons.carrot, count: 45),
      CategoryOption(value: "seasoning", label: "調味料", icon: LucideIcons.flaskConical, count: 23),
      CategoryOption(value: "packaging", label: "包装材", icon: LucideIcons.package, count: 15),
      CategoryOption(value: "supplies", label: "備品", icon: LucideIcons.settings, count: 18),
    ],
    selectedCategories: selectedCategories,
    onSelectionChanged: onSelectionChanged,
    variant: variant,
    allowMultipleSelection: true,
  );
}

/// カテゴリオプション
class CategoryOption {
  const CategoryOption({required this.value, required this.label, this.icon, this.count});

  final String value;
  final String label;
  final IconData? icon;
  final int? count;
}
