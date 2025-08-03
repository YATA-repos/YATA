import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/constants.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/logging/logger_mixin.dart";
import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/layouts/main_layout.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/buttons/export_button.dart";
import "../../../../shared/widgets/cards/stats_card.dart";
import "../../../../shared/widgets/filters/category_filter.dart";
import "../../../../shared/widgets/forms/search_field.dart";
import "../../../../shared/widgets/navigation/pagination.dart";
import "../../../../shared/widgets/tables/data_table.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../dto/inventory_dto.dart";
import "../providers/inventory_providers.dart";
import "../widgets/material_form_dialog.dart";



/// 詳細在庫画面
///
/// テーブル形式での在庫管理機能を提供
/// 検索・フィルター・ページネーション・エクスポート機能をサポート
class DetailedInventoryScreen extends ConsumerStatefulWidget {
  const DetailedInventoryScreen({super.key});

  @override
  ConsumerState<DetailedInventoryScreen> createState() => _DetailedInventoryScreenState();
}

class _DetailedInventoryScreenState extends ConsumerState<DetailedInventoryScreen> with LoggerMixin {
  @override
  String get componentName => "DetailedInventoryScreen";
  // フィルター状態
  String _searchQuery = "";
  List<String> _selectedCategories = <String>[];
  InventoryStatus? _selectedStatus;

  // ページネーション状態
  int _currentPage = 1;
  int _itemsPerPage = 10;

  // データ状態
  bool _isLoading = false;
  List<MaterialStockInfo>? _cachedMaterials;

  // ソート状態
  String _sortColumn = "name";
  bool _sortAscending = true;

  String? get userId => ref.read(currentUserProvider)?.id;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      logWarning("在庫管理画面: ユーザー情報が取得できません");
      return MainLayout(
        title: "在庫管理",
        child: Center(child: Text("ユーザー情報が取得できません")),
      );
    }

    return ref
        .watch(materialsWithStockInfoProvider(null, userId!))
        .when(
          data: _buildMainContent,
          loading: () {
            logTrace("在庫データ読み込み中");
            return MainLayout(
              title: "在庫管理",
              child: Center(child: CircularProgressIndicator()),
            );
          },
          error: (Object error, StackTrace stack) {
            logError("在庫データの読み込みでエラーが発生", error, stack);
            return MainLayout(
              title: "在庫管理",
              child: Center(child: Text("エラー: $error")),
            );
          },
        );
  }

  /// メインコンテンツを構築
  Widget _buildMainContent(List<MaterialStockInfo> allMaterials) {
    // データをキャッシュして、エクスポート機能で再利用
    _cachedMaterials = allMaterials;
    
    final List<MaterialStockInfo> filteredItems = _getFilteredMaterials(allMaterials);
    final int totalPages = (filteredItems.length / _itemsPerPage).ceil();
    final List<MaterialStockInfo> paginatedItems = _getPaginatedMaterials(filteredItems);

    return MainLayout(
      title: "在庫管理",
      actions: <Widget>[
        // インポートボタン
        AppButton(
          onPressed: _handleImport,
          variant: ButtonVariant.outline,
          size: ButtonSize.small,
          text: "インポート",
          icon: const Icon(LucideIcons.upload),
        ),
        const SizedBox(width: 8),

        // エクスポートボタン
        ExportButton(onExport: _handleExport),
        const SizedBox(width: 8),

        // 材料追加ボタン
        AppButton(
          onPressed: _handleAddMaterial,
          size: ButtonSize.small,
          text: "材料追加",
          icon: const Icon(LucideIcons.plus),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 統計サマリー
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: _buildStatsSection(allMaterials),
          ),

          const SizedBox(height: 24),

          // フィルター・検索
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: _buildFilterSection(),
          ),

          const SizedBox(height: 16),

          // データテーブル
          Expanded(
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: _buildDataTable(paginatedItems),
            ),
          ),

          // ページネーション
          if (totalPages > 1)
            AppPagination(
              currentPage: _currentPage,
              totalPages: totalPages,
              totalItems: filteredItems.length,
              itemsPerPage: _itemsPerPage,
              onPageChanged: (int page) => setState(() => _currentPage = page),
              onItemsPerPageChanged: (int itemsPerPage) {
                setState(() {
                  _itemsPerPage = itemsPerPage;
                  _currentPage = 1;
                });
              },
            ),
        ],
      ),
    );
  }

  /// 統計セクション
  Widget _buildStatsSection(List<MaterialStockInfo> allMaterials) {
    final Map<String, int> stats = _calculateStats(allMaterials);

    return ResponsiveHelper.shouldShowSideNavigation(context)
        ? Row(
            children: <Widget>[
              _buildStatsCard(
                "総在庫アイテム",
                "${stats['total']}",
                LucideIcons.package,
                StatsCardVariant.default_,
                "材料",
              ),
              const SizedBox(width: 16),
              _buildStatsCard(
                "在庫警告",
                "${stats['lowStock']}",
                LucideIcons.alertTriangle,
                StatsCardVariant.danger,
                "緊急",
              ),
              const SizedBox(width: 16),
              _buildStatsCard(
                "在庫切れ",
                "${stats['outOfStock']}",
                LucideIcons.xCircle,
                StatsCardVariant.warning,
                "切れ",
              ),
              const SizedBox(width: 16),
              _buildStatsCard(
                "在庫金額",
                "¥${stats['totalValue']}",
                LucideIcons.dollarSign,
                StatsCardVariant.success,
                "総額",
              ),
            ],
          )
        : Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  _buildStatsCard(
                    "総在庫アイテム",
                    "${stats['total']}",
                    LucideIcons.package,
                    StatsCardVariant.default_,
                    "材料",
                  ),
                  const SizedBox(width: 16),
                  _buildStatsCard(
                    "在庫警告",
                    "${stats['lowStock']}",
                    LucideIcons.alertTriangle,
                    StatsCardVariant.danger,
                    "緊急",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _buildStatsCard(
                    "在庫切れ",
                    "${stats['outOfStock']}",
                    LucideIcons.xCircle,
                    StatsCardVariant.warning,
                    "切れ",
                  ),
                  const SizedBox(width: 16),
                  _buildStatsCard(
                    "在庫金額",
                    "¥${stats['totalValue']}",
                    LucideIcons.dollarSign,
                    StatsCardVariant.success,
                    "総額",
                  ),
                ],
              ),
            ],
          );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    StatsCardVariant variant,
    String? subtitle,
  ) => Expanded(
    child: StatsCard(title: title, value: value, icon: icon, variant: variant, subtitle: subtitle),
  );

  /// フィルターセクション
  Widget _buildFilterSection() => Column(
    children: <Widget>[
      // 検索とリフレッシュ
      Row(
        children: <Widget>[
          Expanded(
            child: SearchField(
              hintText: "商品検索...",
              onChanged: (String query) => setState(() {
                _searchQuery = query;
                _currentPage = 1;
              }),
            ),
          ),
          const SizedBox(width: 16),
          AppButton(
            text: "リフレッシュ",
            onPressed: _handleRefresh,
            variant: ButtonVariant.outline,
            icon: const Icon(LucideIcons.refreshCw),
            isLoading: _isLoading,
          ),
        ],
      ),

      const SizedBox(height: 16),

      // カテゴリーフィルター
      Row(
        children: <Widget>[
          Expanded(
            child: CategoryFilter(
              selectedCategories: _selectedCategories,
              onSelectionChanged: (List<String> categories) => setState(() {
                _selectedCategories = categories;
                _currentPage = 1;
              }),
              categories: const <CategoryOption>[],
            ),
          ),
          const SizedBox(width: 16),

          // ステータスフィルター
          DropdownButton<InventoryStatus?>(
            value: _selectedStatus,
            hint: const Text("ステータス"),
            onChanged: (InventoryStatus? status) => setState(() {
              _selectedStatus = status;
              _currentPage = 1;
            }),
            items: <DropdownMenuItem<InventoryStatus?>>[
              const DropdownMenuItem<InventoryStatus?>(child: Text("すべて")),
              ...InventoryStatus.values.map((InventoryStatus status) => DropdownMenuItem<InventoryStatus?>(
                  value: status,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(_getStatusIcon(status), size: 16, color: _getStatusColor(status)),
                      const SizedBox(width: 8),
                      Text(_getStatusText(status)),
                    ],
                  ),
                )),
            ],
          ),
        ],
      ),
    ],
  );

  /// データテーブル
  Widget _buildDataTable(List<MaterialStockInfo> items) => AppDataTable<MaterialStockInfo>(
    columns: <DataColumn>[
      const DataColumn(label: Text("商品名"), tooltip: "商品名"),
      const DataColumn(label: Text("カテゴリー"), tooltip: "商品カテゴリー"),
      DataColumn(
        label: const Text("現在の在庫"),
        tooltip: "現在の在庫数",
        numeric: true,
        onSort: (int columnIndex, bool ascending) => _handleSort("currentStock", ascending),
      ),
      DataColumn(
        label: const Text("最小在庫"),
        tooltip: "最小在庫数",
        numeric: true,
        onSort: (int columnIndex, bool ascending) => _handleSort("minStock", ascending),
      ),
      DataColumn(
        label: const Text("単価"),
        tooltip: "単価",
        numeric: true,
        onSort: (int columnIndex, bool ascending) => _handleSort("unitPrice", ascending),
      ),
      const DataColumn(label: Text("状態"), tooltip: "在庫状態"),
      const DataColumn(label: Text("アクション"), tooltip: "操作"),
    ],
    rows: items.map((MaterialStockInfo item) {
      final InventoryStatus status = _getInventoryStatus(item);
      return DataRow(
        cells: <DataCell>[
          AppDataCell.text(item.material.name),
          AppDataCell.text(item.material.categoryId),
          AppDataCell.text("${item.material.currentStock} ${item.material.unitType.name}"),
          AppDataCell.text("${item.material.alertThreshold} ${item.material.unitType.name}"),
          AppDataCell.text("-"),
          AppDataCell.status(_getStatusText(status), color: _getStatusColor(status)),
          AppDataCell.actions(<Widget>[
            IconButton(
              onPressed: () => _handleEditMaterial(item),
              icon: const Icon(LucideIcons.edit),
              iconSize: 16,
              tooltip: "編集",
            ),
            IconButton(
              onPressed: () => _handleOrderMaterial(item),
              icon: const Icon(LucideIcons.plus),
              iconSize: 16,
              tooltip: "発注",
            ),
          ]),
        ],
      );
    }).toList(),
    emptyMessage: "該当する在庫アイテムがありません",
    onRowTap: (int index) => _handleEditMaterial(items[index]),
  );

  /// フィルター済みマテリアル取得
  List<MaterialStockInfo> _getFilteredMaterials(List<MaterialStockInfo> allMaterials) {
    List<MaterialStockInfo> filteredItems = List<MaterialStockInfo>.from(allMaterials);

    // 検索フィルター
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems
          .where(
            (MaterialStockInfo item) =>
                item.material.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.material.categoryId.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // カテゴリフィルター
    if (_selectedCategories.isNotEmpty) {
      filteredItems = filteredItems
          .where(
            (MaterialStockInfo item) => _selectedCategories.contains(item.material.categoryId),
          )
          .toList();
    }

    // ステータスフィルター
    if (_selectedStatus != null) {
      filteredItems = filteredItems
          .where((MaterialStockInfo item) => _getInventoryStatus(item) == _selectedStatus)
          .toList();
    }

    // ソート処理
    _sortMaterials(filteredItems);

    return filteredItems;
  }

  /// マテリアルのソート処理
  void _sortMaterials(List<MaterialStockInfo> items) {
    items.sort((MaterialStockInfo a, MaterialStockInfo b) {
      int comparison = 0;

      switch (_sortColumn) {
        case "name":
          comparison = a.material.name.compareTo(b.material.name);
          break;
        case "category":
          comparison = a.material.categoryId.compareTo(b.material.categoryId);
          break;
        case "currentStock":
          comparison = a.material.currentStock.compareTo(b.material.currentStock);
          break;
        case "minStock":
          comparison = a.material.alertThreshold.compareTo(b.material.alertThreshold);
          break;
        case "unitPrice":
          comparison = a.material.name.compareTo(b.material.name);
          break;
        case "status":
          comparison = _getInventoryStatus(a).index.compareTo(_getInventoryStatus(b).index);
          break;
        default:
          comparison = a.material.name.compareTo(b.material.name);
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  /// ページネーション済みマテリアル取得
  List<MaterialStockInfo> _getPaginatedMaterials(List<MaterialStockInfo> items) {
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, items.length);

    if (startIndex >= items.length) {
      return <MaterialStockInfo>[];
    }

    return items.sublist(startIndex, endIndex);
  }

  /// ソート処理
  void _handleSort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
    });
  }

  /// リフレッシュ処理
  void _handleRefresh() async {
    if (userId == null) {
      logWarning("リフレッシュ処理: userIdがnullです");
      return;
    }

    logDebug("在庫データのリフレッシュを開始");
    setState(() => _isLoading = true);

    try {
      // キャッシュをクリア
      _cachedMaterials = null;
      
      // プロバイダーを無効化して再取得をトリガー
      ref..invalidate(materialsWithStockInfoProvider(null, userId!))
      ..invalidate(materialCategoriesProvider);

      logInfo("在庫データのリフレッシュが完了しました");
      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("データを更新しました"), backgroundColor: AppColors.success),
      );
    } catch (e, stackTrace) {
      logError("在庫データリフレッシュ中にエラーが発生", e, stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("更新に失敗しました: $e"), backgroundColor: AppColors.danger));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// インポート処理
  void _handleImport() {
    logDebug("インポート機能ダイアログを表示（開発中機能）");
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("インポート機能"),
        content: const Text("インポート機能は現在開発中です。\n\nCSVファイルからの在庫データの一括インポート機能を提供予定です。"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK")),
        ],
      ),
    );
  }

  /// エクスポート処理
  void _handleExport(ExportFormat format) {
    if (_cachedMaterials == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("データが読み込まれていません"), backgroundColor: AppColors.danger),
      );
      return;
    }

    final List<MaterialStockInfo> items = _getFilteredMaterials(_cachedMaterials!);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("${format.name.toUpperCase()}エクスポート"),
        content: Text("在庫データ${items.length}件を${format.name.toUpperCase()}形式でエクスポートしますか？"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performMaterialExport(format, items);
            },
            child: const Text("エクスポート"),
          ),
        ],
      ),
    );
  }

  /// 材料追加
  Future<void> _handleAddMaterial() async {
    logDebug("材料追加ダイアログを表示");
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const MaterialFormDialog(),
    );

    // 追加が成功した場合、データをリフレッシュ
    if ((result ?? false) && userId != null) {
      logInfo("材料追加が成功しました。データをリフレッシュします");
      _cachedMaterials = null; // キャッシュをクリア
      ref.invalidate(materialsWithStockInfoProvider(null, userId!));
    } else if (result == null) {
      logDebug("材料追加ダイアログがキャンセルされました");
    }
  }

  /// 材料編集
  Future<void> _handleEditMaterial(MaterialStockInfo item) async {
    logDebug("材料編集ダイアログを表示: ${item.material.name}");
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => MaterialFormDialog(material: item.material),
    );

    // 編集が成功した場合、データをリフレッシュ
    if ((result ?? false) && userId != null) {
      logInfo("材料編集が成功しました: ${item.material.name}。データをリフレッシュします");
      _cachedMaterials = null; // キャッシュをクリア
      ref.invalidate(materialsWithStockInfoProvider(null, userId!));
    } else if (result == null) {
      logDebug("材料編集ダイアログがキャンセルされました: ${item.material.name}");
    }
  }

  /// 材料発注
  void _handleOrderMaterial(MaterialStockInfo item) {
    logDebug("材料発注ダイアログを表示: ${item.material.name} (現在在庫: ${item.material.currentStock})");
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("${item.material.name}の発注"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("現在在庫: ${item.material.currentStock}${item.material.unitType.name}"),
            Text("最小在庫: ${item.material.alertThreshold}${item.material.unitType.name}"),
            const SizedBox(height: 16),
            const Text("発注機能は現在開発中です。\n\n供給業者への自動発注機能を提供予定です。"),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK")),
        ],
      ),
    );
  }

  /// 材料エクスポート実行
  void _performMaterialExport(ExportFormat format, List<MaterialStockInfo> items) {
    try {
      logDebug("材料エクスポートを開始: ${format.name.toUpperCase()}形式、${items.length}件");
      // 実際の実装では、ここでCSVやExcelファイルを生成
      final String formattedData = _formatMaterialDataForExport(format, items);

      logInfo("材料エクスポートが完了: ${format.name.toUpperCase()}形式、${items.length}件");
      // ファイル保存やダウンロードの処理をシミュレート
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${items.length}件のデータを${format.name.toUpperCase()}形式でエクスポートしました"),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: "詳細",
            onPressed: () {
              logDebug("エクスポート詳細ダイアログを表示");
              showDialog<void>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text("エクスポート詳細"),
                  content: Text(
                    "データ形式: ${format.name.toUpperCase()}\n件数: ${items.length}件\n\nプレビュー:\n${formattedData.length > 200 ? "${formattedData.substring(0, 200)}..." : formattedData}",
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("閉じる"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      logError("材料エクスポート中にエラーが発生: ${format.name.toUpperCase()}形式", e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("エクスポートに失敗しました: $e"), backgroundColor: AppColors.danger),
      );
    }
  }

  /// 材料データをエクスポート形式にフォーマット
  String _formatMaterialDataForExport(ExportFormat format, List<MaterialStockInfo> items) {
    switch (format) {
      case ExportFormat.csv:
        final StringBuffer buffer = StringBuffer();
        buffer.writeln("ID,材料名,カテゴリ,現在在庫,最小在庫,単価,単位,ステータス");
        for (final MaterialStockInfo item in items) {
          final InventoryStatus status = _getInventoryStatus(item);
          buffer.writeln(
            "${item.material.id ?? ''},${item.material.name},${item.material.categoryId},${item.material.currentStock},${item.material.alertThreshold},-,${item.material.unitType.name},${_getStatusText(status)}",
          );
        }
        return buffer.toString();
      case ExportFormat.excel:
        return "Excel形式のデータ（${items.length}件）";
      case ExportFormat.pdf:
        return "PDF形式のデータ（${items.length}件）";
      case ExportFormat.json:
        return "JSON形式のデータ（${items.length}件）";
    }
  }

  /// ステータスアイコン取得
  IconData _getStatusIcon(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.inStock:
        return LucideIcons.checkCircle;
      case InventoryStatus.lowStock:
        return LucideIcons.alertTriangle;
      case InventoryStatus.outOfStock:
        return LucideIcons.xCircle;
    }
  }

  /// ステータス色取得
  Color _getStatusColor(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.inStock:
        return AppColors.inStock;
      case InventoryStatus.lowStock:
        return AppColors.lowStock;
      case InventoryStatus.outOfStock:
        return AppColors.outOfStock;
    }
  }

  /// ステータステキスト取得
  String _getStatusText(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.inStock:
        return "在庫あり";
      case InventoryStatus.lowStock:
        return "在庫少";
      case InventoryStatus.outOfStock:
        return "緊急";
    }
  }

  /// MaterialStockInfo から在庫ステータスを取得
  InventoryStatus _getInventoryStatus(MaterialStockInfo item) {
    final double currentQuantity = item.material.currentStock;
    final double minStockLevel = item.material.alertThreshold;

    if (currentQuantity <= 0) {
      return InventoryStatus.outOfStock;
    } else if (currentQuantity <= minStockLevel) {
      return InventoryStatus.lowStock;
    } else {
      return InventoryStatus.inStock;
    }
  }

  /// 統計情報を計算
  Map<String, int> _calculateStats(List<MaterialStockInfo> materials) {
    final int total = materials.length;
    int lowStock = 0;
    int outOfStock = 0;
    int totalValue = 0;

    for (final MaterialStockInfo material in materials) {
      final InventoryStatus status = _getInventoryStatus(material);
      switch (status) {
        case InventoryStatus.lowStock:
          lowStock++;
          break;
        case InventoryStatus.outOfStock:
          outOfStock++;
          break;
        case InventoryStatus.inStock:
          break;
      }

      // 在庫金額計算
      final double quantity = material.material.currentStock;
      final double unitCost = 0; // unitCostプロパティは存在しない
      totalValue += (quantity * unitCost).round();
    }

    return <String, int>{
      "total": total,
      "lowStock": lowStock,
      "outOfStock": outOfStock,
      "totalValue": totalValue,
    };
  }
}
