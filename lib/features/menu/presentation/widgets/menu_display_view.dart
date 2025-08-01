import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart";
import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/common/loading_indicator.dart";
import "../../../../shared/widgets/dialogs/menu_item_detail_dialog.dart";
import "../../../../shared/widgets/filters/category_filter.dart";
import "../../../../shared/widgets/forms/search_field.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../models/menu_model.dart";
import "../../services/menu_service.dart";
import "../providers/menu_providers.dart";
import "menu_item_card.dart";

/// メニュー表示ビュー
///
/// カード形式でメニューの閲覧・管理機能を提供
/// 検索・フィルター・表示モード切り替え・販売可否管理に対応
class MenuDisplayView extends ConsumerStatefulWidget {
  const MenuDisplayView({super.key});

  @override
  ConsumerState<MenuDisplayView> createState() => _MenuDisplayViewState();
}

class _MenuDisplayViewState extends ConsumerState<MenuDisplayView> {
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
          _buildHeader(),
          const SizedBox(height: 16),

          // 検索・フィルター・表示切り替え
          _buildControls(),
          const SizedBox(height: 16),

          // メニューアイテム表示
          Expanded(
            child: userId != null ? _buildMenuDisplay() : const Center(child: Text("ユーザー情報が取得できません")),
          ),
        ],
      ),
    );

  /// ヘッダー部分
  Widget _buildHeader() => Row(
      children: <Widget>[
        Text("メニュー表示", style: AppTextTheme.cardTitle),
        const Spacer(),
        // 在庫状況自動更新ボタン
        AppButton(
          text: "在庫状況で自動更新",
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          size: ButtonSize.small,
          variant: ButtonVariant.outline,
          onPressed: _updateMenuAvailabilityByStock,
        ),
      ],
    );

  /// コントロール部分（検索・フィルター・表示切り替え）
  Widget _buildControls() => Column(
      children: <Widget>[
        // 検索フィールドと表示モード切り替え
        Row(
          children: <Widget>[
            Expanded(
              child: SearchField(
                hintText: "メニューを検索...",
                onChanged: (String query) => setState(() => searchQuery = query),
              ),
            ),
            const SizedBox(width: 12),
            // 表示モード切り替えボタン
            Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final MenuDisplayMode currentMode = ref.watch(menuDisplayModeNotifierProvider);
                return AppButton(
                  text: "",
                  icon: Icon(
                    currentMode == MenuDisplayMode.grid ? LucideIcons.list : LucideIcons.layoutGrid,
                    size: 16,
                  ),
                  size: ButtonSize.small,
                  variant: ButtonVariant.outline,
                  onPressed: () => ref.read(menuDisplayModeNotifierProvider.notifier).toggleMode(),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // カテゴリフィルター
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            if (userId == null) {
              return const SizedBox.shrink();
            }

            return ref.watch(menuCategoriesProvider).when(
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

  /// メニュー表示部分
  Widget _buildMenuDisplay() {
    if (userId == null) {
      return const SizedBox.shrink();
    }

    // 検索クエリがある場合は検索結果を表示
    if (searchQuery.isNotEmpty) {
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) => ref
              .watch(searchMenuItemsProvider(searchQuery, userId!))
              .when(
                data: (List<MenuItem> items) => _buildItemsView(_filterByCategory(items)),
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

          return _buildItemsView(allItems);
        },
      );
    }

    // 全メニューアイテムを表示（カテゴリIDをnullにして全件取得）
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) => ref
            .watch(menuItemsProvider(null))
            .when(
              data: _buildItemsView,
              loading: () => const LoadingIndicator(),
              error: (Object error, StackTrace stack) => Center(child: Text("エラー: $error")),
            ),
    );
  }

  /// アイテムビュー（グリッドまたはリスト）
  Widget _buildItemsView(List<MenuItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(LucideIcons.utensils, size: 64, color: AppColors.mutedForeground),
            SizedBox(height: 16),
            Text("メニューアイテムが見つかりません", style: TextStyle(color: AppColors.mutedForeground)),
          ],
        ),
      );
    }

    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final MenuDisplayMode displayMode = ref.watch(menuDisplayModeNotifierProvider);
        
        if (displayMode == MenuDisplayMode.grid) {
          return _buildGridView(items);
        } else {
          return _buildListView(items);
        }
      },
    );
  }

  /// グリッドビュー
  Widget _buildGridView(List<MenuItem> items) => GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getMenuGridColumns(context),
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final MenuItem item = items[index];
        return MenuItemCard(
          name: item.name,
          price: item.price,
          description: item.description,
          imageUrl: item.imageUrl,
          isAvailable: item.isAvailable,
          onTap: () => _showMenuItemDetails(item),
          onAddToCart: () => _toggleMenuAvailability(item),
        );
      },
    );

  /// リストビュー
  Widget _buildListView(List<MenuItem> items) => ListView.separated(
      itemCount: items.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final MenuItem item = items[index];
        return CompactMenuItemCard(
          name: item.name,
          price: item.price,
          description: item.description,
          imageUrl: item.imageUrl,
          isAvailable: item.isAvailable,
          onTap: () => _showMenuItemDetails(item),
          onAddToCart: () => _toggleMenuAvailability(item),
        );
      },
    );

  /// カテゴリでフィルター
  List<MenuItem> _filterByCategory(List<MenuItem> items) {
    if (selectedCategories.isEmpty) {
      return items;
    }
    return items.where((MenuItem item) => selectedCategories.contains(item.categoryId)).toList();
  }

  /// カテゴリアイコンを取得
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case "主菜":
      case "メイン":
        return LucideIcons.utensils;
      case "副菜":
      case "サイド":
        return LucideIcons.cookie;
      case "ドリンク":
      case "飲み物":
        return LucideIcons.coffee;
      case "デザート":
        return LucideIcons.cake;
      default:
        return LucideIcons.circle;
    }
  }

  /// メニューアイテムの詳細を表示
  void _showMenuItemDetails(MenuItem item) {
    MenuItemDetailDialog.show(context, item);
  }

  /// メニューの販売可否を切り替え
  void _toggleMenuAvailability(MenuItem item) async {
    if (userId == null) {
      return;
    }

    try {
      final MenuService service = ref.read(menuServiceProvider);
      await service.toggleMenuItemAvailability(
        item.id!,
        !item.isAvailable,
        userId!,
      );

      // プロバイダーを更新して画面を再描画
      ref.invalidate(menuItemsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item.name}を${item.isAvailable ? '販売停止' : '販売開始'}しました"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("エラー: $e"), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  /// 在庫状況に基づいてメニューの販売可否を自動更新
  void _updateMenuAvailabilityByStock() async {
    if (userId == null) {
      return;
    }

    try {
      final MenuService service = ref.read(menuServiceProvider);
      final Map<String, bool> results = await service.autoUpdateMenuAvailabilityByStock(userId!);

      // プロバイダーを更新して画面を再描画
      ref.invalidate(menuItemsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${results.length}件のメニューアイテムを自動更新しました"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("エラー: $e"), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}