import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/buttons/export_button.dart";
import "../../../../shared/widgets/cards/stats_card.dart";
import "../../../../shared/widgets/common/loading_indicator.dart";
import "../../../../shared/widgets/dialogs/menu_item_detail_dialog.dart";
import "../../../../shared/widgets/filters/category_filter.dart";
import "../../../../shared/widgets/forms/search_field.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../models/menu_model.dart";
import "../../services/menu_service.dart";
import "../providers/menu_providers.dart";

/// メニュー管理ビュー
///
/// テーブル形式での詳細管理機能を提供
/// 一括操作・統計表示・エクスポート機能に対応
class MenuManagementView extends ConsumerStatefulWidget {
  const MenuManagementView({super.key});

  @override
  ConsumerState<MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends ConsumerState<MenuManagementView> {
  // フィルター状態
  String _searchQuery = "";
  List<String> _selectedCategories = <String>[];
  bool? _availabilityFilter; // null: 全て, true: 販売中, false: 販売停止

  // 選択状態
  final Set<String> _selectedItems = <String>{};

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

          // 統計カード
          _buildStatsCards(),
          const SizedBox(height: 16),

          // フィルター・検索
          _buildFilters(),
          const SizedBox(height: 16),

          // データテーブル
          Expanded(
            child: userId != null ? _buildDataTable() : const Center(child: Text("ユーザー情報が取得できません")),
          ),
        ],
      ),
    );

  /// ヘッダー部分
  Widget _buildHeader() => Row(
      children: <Widget>[
        Text("メニュー詳細管理", style: AppTextTheme.cardTitle),
        const Spacer(),
        // 一括操作ボタン
        if (_selectedItems.isNotEmpty) ...<Widget>[
          AppButton(
            text: "選択解除",
            size: ButtonSize.small,
            variant: ButtonVariant.outline,
            onPressed: () => setState(_selectedItems.clear),
          ),
          const SizedBox(width: 8),
          AppButton(
            text: "一括販売開始",
            size: ButtonSize.small,
            onPressed: () => _bulkUpdateAvailability(true),
          ),
          const SizedBox(width: 8),
          AppButton(
            text: "一括販売停止",
            size: ButtonSize.small,
            variant: ButtonVariant.danger,
            onPressed: () => _bulkUpdateAvailability(false),
          ),
          const SizedBox(width: 8),
        ],
        // エクスポートボタン
        ExportButton(
          onExport: _exportData,
          formats: const <ExportFormat>[ExportFormat.csv, ExportFormat.json],
        ),
      ],
    );

  /// 統計カード
  Widget _buildStatsCards() {
    if (userId == null) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) => ref
            .watch(menuItemsProvider(null))
            .when(
              data: (List<MenuItem> items) {
                final int totalItems = items.length;
                final int availableItems = items.where((MenuItem item) => item.isAvailable).length;
                final int unavailableItems = totalItems - availableItems;

                return Row(
                  children: <Widget>[
                    Expanded(
                      child: StatsCard(
                        title: "総メニュー数",
                        value: totalItems.toString(),
                        variant: StatsCardVariant.info,
                        icon: LucideIcons.utensils,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: "販売中",
                        value: availableItems.toString(),
                        variant: StatsCardVariant.success,
                        icon: LucideIcons.checkCircle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: "販売停止",
                        value: unavailableItems.toString(),
                        variant: StatsCardVariant.danger,
                        icon: LucideIcons.xCircle,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LoadingIndicator(),
              error: (Object error, StackTrace stack) => const SizedBox.shrink(),
            ),
    );
  }

  /// フィルター部分
  Widget _buildFilters() => Column(
      children: <Widget>[
        // 検索フィールドと販売状況フィルター
        Row(
          children: <Widget>[
            Expanded(
              child: SearchField(
                hintText: "メニューを検索...",
                onChanged: (String query) => setState(() => _searchQuery = query),
              ),
            ),
            const SizedBox(width: 12),
            // 販売状況フィルター
            DropdownButton<bool?>(
              value: _availabilityFilter,
              hint: const Text("販売状況"),
              items: const <DropdownMenuItem<bool?>>[
                DropdownMenuItem<bool?>(child: Text("全て")),
                DropdownMenuItem<bool?>(value: true, child: Text("販売中")),
                DropdownMenuItem<bool?>(value: false, child: Text("販売停止")),
              ],
              onChanged: (bool? value) => setState(() => _availabilityFilter = value),
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
                      selectedCategories: _selectedCategories,
                      onSelectionChanged: (List<String> categories) =>
                          setState(() => _selectedCategories = categories),
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

  /// データテーブル
  Widget _buildDataTable() {
    if (userId == null) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) => ref
            .watch(menuItemsProvider(null))
            .when(
              data: (List<MenuItem> items) {
                final List<MenuItem> filteredItems = _filterItems(items);

                if (filteredItems.isEmpty) {
                  return const Center(child: Text("条件に合うメニューが見つかりません"));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text("メニュー名")),
                      DataColumn(label: Text("カテゴリ")),
                      DataColumn(label: Text("価格")),
                      DataColumn(label: Text("販売状況")),
                      DataColumn(label: Text("調理時間")),
                      DataColumn(label: Text("操作")),
                    ],
                    rows: filteredItems.map(_buildDataRow).toList(),
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (Object error, StackTrace stack) => Center(child: Text("エラー: $error")),
            ),
    );
  }

  /// データ行を構築
  DataRow _buildDataRow(MenuItem item) => DataRow(
      selected: _selectedItems.contains(item.id),
      onSelectChanged: (bool? selected) {
        setState(() {
          if (selected ?? false) {
            _selectedItems.add(item.id!);
          } else {
            _selectedItems.remove(item.id);
          }
        });
      },
      cells: <DataCell>[
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (item.description != null) ...<Widget>[
                Text(
                  item.description!,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        DataCell(FutureBuilder<String>(
          future: _getCategoryName(item.categoryId),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) => Text(snapshot.data ?? "不明"),
        )),
        DataCell(Text("¥${_formatPrice(item.price)}")),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.isAvailable ? AppColors.successMuted : AppColors.dangerMuted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.isAvailable ? "販売中" : "販売停止",
              style: TextStyle(
                color: item.isAvailable ? AppColors.success : AppColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(Text("${item.estimatedPrepTimeMinutes}分")),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  item.isAvailable ? LucideIcons.pauseCircle : LucideIcons.playCircle,
                  size: 16,
                ),
                onPressed: () => _toggleItemAvailability(item),
                tooltip: item.isAvailable ? "販売停止" : "販売開始",
              ),
              IconButton(
                icon: const Icon(LucideIcons.eye, size: 16),
                onPressed: () => _showItemDetails(item),
                tooltip: "詳細表示",
              ),
            ],
          ),
        ),
      ],
    );

  /// アイテムをフィルター
  List<MenuItem> _filterItems(List<MenuItem> items) {
    List<MenuItem> filtered = items;

    // 検索フィルター
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((MenuItem item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (item.description != null && item.description!.toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    }

    // カテゴリフィルター
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((MenuItem item) => _selectedCategories.contains(item.categoryId)).toList();
    }

    // 販売状況フィルター
    if (_availabilityFilter != null) {
      filtered = filtered.where((MenuItem item) => item.isAvailable == _availabilityFilter).toList();
    }

    return filtered;
  }

  /// カテゴリ名を取得
  Future<String> _getCategoryName(String categoryId) async {
    try {
      final List<MenuCategory> categories = await ref.read(menuCategoriesProvider.future);
      final MenuCategory? category = categories.cast<MenuCategory?>().firstWhere(
            (MenuCategory? cat) => cat?.id == categoryId,
            orElse: () => null,
          );
      return category?.name ?? "不明";
    } catch (e) {
      return "不明";
    }
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

  /// 価格をフォーマット
  String _formatPrice(int price) =>
      price.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (Match match) => "${match[1]},");

  /// アイテムの販売可否を切り替え
  void _toggleItemAvailability(MenuItem item) async {
    if (userId == null) return;

    try {

      final MenuService service = ref.read(menuServiceProvider);
      await service.toggleMenuItemAvailability(
        item.id!,
        !item.isAvailable,
        userId!,
      );

      // プロバイダーを更新
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
    } finally {
      if (mounted) {
      }
    }
  }

  /// 一括販売可否更新
  void _bulkUpdateAvailability(bool isAvailable) async {
    if (userId == null || _selectedItems.isEmpty) return;

    try {

      final Map<String, bool> updates = <String, bool>{};
      for (final String itemId in _selectedItems) {
        updates[itemId] = isAvailable;
      }

      final MenuService service = ref.read(menuServiceProvider);
      await service.bulkUpdateMenuAvailability(updates, userId!);

      // プロバイダーを更新
      ref.invalidate(menuItemsProvider);

      // 選択をクリア
      setState(_selectedItems.clear);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${updates.length}件のメニューを${isAvailable ? '販売開始' : '販売停止'}しました"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("エラー: $e"), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
      }
    }
  }

  /// アイテム詳細を表示
  void _showItemDetails(MenuItem item) {
    MenuItemDetailDialog.show(context, item);
  }

  /// データをエクスポート
  void _exportData(ExportFormat format) {
    // エクスポート機能は別の専用タスクとして実装予定
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${format.name}形式でのエクスポート機能は開発中です")),
    );
  }
}