import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/enums.dart";
import "../../dto/inventory_dto.dart";
import "../../models/inventory_model.dart";
import "../../services/inventory_service.dart";
import "../../services/material_management_service.dart";
import "../../services/stock_level_service.dart";
import "../../services/usage_analysis_service.dart";

part "inventory_providers.g.dart";

/// InventoryService プロバイダー
/// 既存の在庫管理統合サービスをRiverpodで利用可能にする
@riverpod
InventoryService inventoryService(Ref ref) => InventoryService(ref: ref);

/// MaterialManagementService プロバイダー
/// 既存の材料管理サービスをRiverpodで利用可能にする
@riverpod
MaterialManagementService materialManagementService(Ref ref) => MaterialManagementService(ref: ref);

/// StockLevelService プロバイダー
/// 既存の在庫レベルサービスをRiverpodで利用可能にする
@riverpod
StockLevelService stockLevelService(Ref ref) => StockLevelService(ref: ref);

/// UsageAnalysisService プロバイダー
/// 既存の使用量分析サービスをRiverpodで利用可能にする
@riverpod
UsageAnalysisService usageAnalysisService(Ref ref) => UsageAnalysisService(ref: ref);

/// 材料カテゴリー一覧プロバイダー
/// 既存のInventoryService.getMaterialCategoriesを直接活用
@riverpod
Future<List<MaterialCategory>> materialCategories(Ref ref) async {
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getMaterialCategories();
}

/// カテゴリー別材料一覧プロバイダー
/// 既存のInventoryService.getMaterialsByCategoryを直接活用
@riverpod
Future<List<Material>> materials(Ref ref, String? categoryId) async {
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getMaterialsByCategory(categoryId);
}

/// 在庫情報付き材料一覧プロバイダー
/// 既存のInventoryService.getMaterialsWithStockInfoを直接活用
@riverpod
Future<List<MaterialStockInfo>> materialsWithStockInfo(
  Ref ref,
  String? categoryId,
  String userId,
) async {
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getMaterialsWithStockInfo(categoryId, userId);
}

/// 在庫アラート（レベル別）プロバイダー
/// 既存のInventoryService.getStockAlertsByLevelを直接活用
@riverpod
Future<Map<StockLevel, List<Material>>> stockAlertsByLevel(Ref ref) async {
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getStockAlertsByLevel();
}

/// 緊急在庫材料プロバイダー
/// 既存のInventoryService.getCriticalStockMaterialsを直接活用
@riverpod
Future<List<Material>> criticalStockMaterials(Ref ref) async {
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getCriticalStockMaterials();
}

/// 材料使用可能日数一括計算プロバイダー
/// 既存のUsageAnalysisService.bulkCalculateUsageDaysを直接活用
@riverpod
Future<Map<String, int?>> bulkUsageDays(Ref ref, String userId) async {
  final UsageAnalysisService service = ref.watch(usageAnalysisServiceProvider);
  return service.bulkCalculateUsageDays(userId);
}

/// 日間使用率一括計算プロバイダー
/// 既存のUsageAnalysisService.bulkCalculateDailyUsageRatesを直接活用
@riverpod
Future<Map<String, double?>> bulkDailyUsageRates(Ref ref, String userId) async {
  final UsageAnalysisService service = ref.watch(usageAnalysisServiceProvider);
  return service.bulkCalculateDailyUsageRates(userId);
}

/// UI状態管理：選択中材料カテゴリー
@riverpod
class SelectedMaterialCategory extends _$SelectedMaterialCategory {
  @override
  String build() => "all"; // デフォルトは全カテゴリー

  /// カテゴリーを選択
  void selectCategory(String categoryId) {
    state = categoryId;
  }

  /// 全カテゴリーに戻す
  void selectAll() {
    state = "all";
  }
}

/// UI状態管理：在庫アラートフィルター
@riverpod
class StockAlertFilter extends _$StockAlertFilter {
  @override
  StockLevel? build() => null; // デフォルトは全レベル

  /// アラートレベルを選択
  void selectLevel(StockLevel level) {
    state = level;
  }

  /// フィルターをクリア
  void clearFilter() {
    state = null;
  }
}

/// UI状態管理：材料検索クエリ
@riverpod
class MaterialSearchQuery extends _$MaterialSearchQuery {
  @override
  String build() => "";

  /// 検索クエリを更新
  void updateQuery(String query) {
    state = query;
  }

  /// 検索クエリをクリア
  void clearQuery() {
    state = "";
  }
}

@riverpod
class StockDisplayModeNotifier extends _$StockDisplayModeNotifier {
  @override
  StockDisplayMode build() => StockDisplayMode.grid;

  /// 表示モードを設定
  void setMode(StockDisplayMode mode) {
    state = mode;
  }

  /// 次のモードに切り替え
  void nextMode() {
    switch (state) {
      case StockDisplayMode.grid:
        state = StockDisplayMode.list;
        break;
      case StockDisplayMode.list:
        state = StockDisplayMode.alert;
        break;
      case StockDisplayMode.alert:
        state = StockDisplayMode.grid;
        break;
    }
  }
}
