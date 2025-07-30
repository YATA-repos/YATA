import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/common/loading_indicator.dart";
import "../../../../shared/widgets/filters/category_filter.dart";
import "../../../../shared/widgets/forms/search_field.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../../menu/models/menu_model.dart";
import "../../../menu/presentation/providers/menu_providers.dart";
import "../../../menu/presentation/widgets/menu_item_card.dart";
import "../../../order/presentation/providers/cart_providers.dart";

/// メニュー選択パネル
///
/// メニューアイテムの検索・フィルター・選択機能を提供
/// MenuServiceと統合してメニューデータを表示
class MenuSelectionPanel extends ConsumerStatefulWidget {
  const MenuSelectionPanel({super.key});

  @override
  ConsumerState<MenuSelectionPanel> createState() => _MenuSelectionPanelState();
}

class _MenuSelectionPanelState extends ConsumerState<MenuSelectionPanel> {
  String searchQuery = "";
  List<String> selectedCategories = <String>[];

  String? get userId => ref.read(currentUserProvider)?.id;

  @override
  Widget build(BuildContext context) => Padding(
    padding: ResponsiveHelper.getResponsivePadding(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ヘッダー
        Text("メニュー選択", style: AppTextTheme.cardTitle),
        const SizedBox(height: 16),

        // 検索・フィルター
        _buildSearchAndFilter(),

        const SizedBox(height: 16),

        // メニューアイテムグリッド
        Expanded(
          child: userId != null ? _buildMenuGrid() : const Center(child: Text("ユーザー情報が取得できません")),
        ),
      ],
    ),
  );

  /// 検索・フィルター部分
  Widget _buildSearchAndFilter() => Column(
    children: <Widget>[
      // 検索フィールド
      SearchField(
        hintText: "メニューを検索...",
        onChanged: (String query) => setState(() => searchQuery = query),
      ),

      const SizedBox(height: 12),

      // カテゴリフィルター
      Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          if (userId == null) {
            return const SizedBox.shrink();
          }

          return ref
              .watch(menuCategoriesProvider)
              .when(
                data: (List<MenuCategory> categories) {
                  final List<CategoryOption> categoryOptions = categories
                      .map(
                        (MenuCategory category) => CategoryOption(
                          value: category.id!,
                          label: category.name,
                          icon: _getCategoryIcon(category.name),
                        ),
                      )
                      .toList();

                  return CategoryFilter(
                    selectedCategories: selectedCategories,
                    onSelectionChanged: (List<String> categories) =>
                        setState(() => selectedCategories = categories),
                    categories: categoryOptions,
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (Object error, StackTrace stack) => const SizedBox.shrink(),
              );
        },
      ),
    ],
  );

  /// メニューグリッド
  Widget _buildMenuGrid() {
    if (userId == null) {
      return const SizedBox.shrink();
    }

    // 検索クエリがある場合は検索結果を表示
    if (searchQuery.isNotEmpty) {
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) => ref
              .watch(searchMenuItemsProvider(searchQuery, userId!))
              .when(
                data: (List<MenuItem> items) => _buildGridView(_filterByCategory(items)),
                loading: () => const LoadingIndicator(),
                error: (Object error, StackTrace stack) => Center(child: Text("エラー: $error")),
              ),
      );
    }

    // カテゴリフィルターがある場合
    if (selectedCategories.isNotEmpty) {
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          // 選択されたカテゴリのアイテムを取得
          final List<AsyncValue<List<MenuItem>>> categoryResults = selectedCategories
              .map((String categoryId) => ref.watch(menuItemsProvider(categoryId)))
              .toList();

          // すべての結果が取得できているかチェック
          final bool isLoading = categoryResults.any(
            (AsyncValue<List<MenuItem>> result) => result.isLoading,
          );
          final bool hasError = categoryResults.any(
            (AsyncValue<List<MenuItem>> result) => result.hasError,
          );

          if (isLoading) {
            return const LoadingIndicator();
          }
          if (hasError) {
            return const Center(child: Text("エラーが発生しました"));
          }

          // 結果を結合
          final List<MenuItem> allItems = categoryResults
              .where((AsyncValue<List<MenuItem>> result) => result.hasValue)
              .expand((AsyncValue<List<MenuItem>> result) => result.value!)
              .toList();

          return _buildGridView(allItems);
        },
      );
    }

    // フィルターなしの場合は全アイテムを表示
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) => ref
            .watch(menuItemsProvider(null))
            .when(
              data: _buildGridView,
              loading: () => const LoadingIndicator(),
              error: (Object error, StackTrace stack) => Center(child: Text("エラー: $error")),
            ),
    );
  }

  /// グリッドビュー構築
  Widget _buildGridView(List<MenuItem> items) => GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getGridColumns(context),
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final MenuItem item = items[index];
        return MenuItemCard(
          name: item.name,
          price: item.price,
          description: item.description ?? "",
          imageUrl: item.imageUrl,
          isAvailable: item.isAvailable,
          onTap: () => _addToCart(item),
        );
      },
    );

  /// カテゴリーでフィルタリング
  List<MenuItem> _filterByCategory(List<MenuItem> items) {
    if (selectedCategories.isEmpty) {
      return items;
    }

    return items.where((MenuItem item) => selectedCategories.contains(item.categoryId)).toList();
  }

  /// カートに追加
  void _addToCart(MenuItem item) {
    if (!item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${item.name}は現在利用できません"),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ref.read(cartProvider.notifier).addMenuItem(item);
  }

  /// カテゴリーアイコン取得
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case "ドリンク":
      case "drink":
        return LucideIcons.coffee;
      case "フード":
      case "food":
      case "メイン":
        return LucideIcons.chefHat;
      case "デザート":
      case "dessert":
        return LucideIcons.cake;
      case "セット":
      case "set":
        return LucideIcons.package;
      default:
        return LucideIcons.package;
    }
  }
}
