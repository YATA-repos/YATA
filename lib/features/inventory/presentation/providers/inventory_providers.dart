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
/// **ライフサイクル**: keepAlive（サービスクラスは永続化）
@riverpod
InventoryService inventoryService(Ref ref) {
  ref.keepAlive(); // サービスインスタンスは永続化
  return InventoryService(ref: ref);
}

/// MaterialManagementService プロバイダー
/// 既存の材料管理サービスをRiverpodで利用可能にする
/// **ライフサイクル**: keepAlive（サービスクラスは永続化）
@riverpod
MaterialManagementService materialManagementService(Ref ref) {
  ref.keepAlive();
  return MaterialManagementService(ref: ref);
}

/// StockLevelService プロバイダー
/// 既存の在庫レベルサービスをRiverpodで利用可能にする
/// **ライフサイクル**: keepAlive（サービスクラスは永続化）
@riverpod
StockLevelService stockLevelService(Ref ref) {
  ref.keepAlive();
  return StockLevelService(ref: ref);
}

/// UsageAnalysisService プロバイダー
/// 既存の使用量分析サービスをRiverpodで利用可能にする
/// **ライフサイクル**: keepAlive（サービスクラスは永続化）
@riverpod
UsageAnalysisService usageAnalysisService(Ref ref) {
  ref.keepAlive();
  return UsageAnalysisService(ref: ref);
}

/// 材料カテゴリー一覧プロバイダー
/// 既存のInventoryService.getMaterialCategoriesを直接活用
/// **ライフサイクル**: keepAlive（マスターデータ・高頻度アクセス）
/// **データ性質**: masterData, **アクセス頻度**: high
@riverpod
Future<List<MaterialCategory>> materialCategories(Ref ref) async {
  ref.keepAlive(); // マスターデータは永続キャッシュ
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getMaterialCategories();
}

/// カテゴリー別材料一覧プロバイダー
/// 既存のInventoryService.getMaterialsByCategoryを直接活用
/// **ライフサイクル**: keepAlive（マスターデータ・中頻度アクセス）
/// **データ性質**: masterData, **アクセス頻度**: medium
@riverpod
Future<List<Material>> materials(Ref ref, String? categoryId) async {
  ref.keepAlive(); // マスターデータは永続キャッシュ（リアルタイム更新で無効化）
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getMaterialsByCategory(categoryId);
}

/// 在庫情報付き材料一覧プロバイダー
/// 既存のInventoryService.getMaterialsWithStockInfoを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・高頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: high
@riverpod
Future<List<MaterialStockInfo>> materialsWithStockInfo(
  Ref ref,
  String? categoryId,
  String userId,
) async {
  // userDynamicデータは自動破棄（リアルタイム更新で再取得）
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getMaterialsWithStockInfo(categoryId, userId);
}

/// 在庫アラート（レベル別）プロバイダー
/// 既存のInventoryService.getStockAlertsByLevelを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・高頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: high
@riverpod
Future<Map<StockLevel, List<Material>>> stockAlertsByLevel(Ref ref) async {
  // 在庫アラートは頻繁に変わるため自動破棄
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getStockAlertsByLevel();
}

/// 緊急在庫材料プロバイダー
/// 既存のInventoryService.getCriticalStockMaterialsを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・高頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: high
@riverpod
Future<List<Material>> criticalStockMaterials(Ref ref) async {
  // 緊急在庫は緊急性のため自動破棄で常に最新データを取得
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getCriticalStockMaterials();
}

/// 材料使用可能日数一括計算プロバイダー
/// 既存のUsageAnalysisService.bulkCalculateUsageDaysを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・中頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: medium
@riverpod
Future<Map<String, int?>> bulkUsageDays(Ref ref, String userId) async {
  // 使用分析データは計算コストが高いが変動するため自動破棄
  final UsageAnalysisService service = ref.watch(usageAnalysisServiceProvider);
  return service.bulkCalculateUsageDays(userId);
}

/// 日間使用率一括計算プロバイダー
/// 既存のUsageAnalysisService.bulkCalculateDailyUsageRatesを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・中頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: medium
@riverpod
Future<Map<String, double?>> bulkDailyUsageRates(Ref ref, String userId) async {
  // 使用率分析データは計算コストが高いが変動するため自動破棄
  final UsageAnalysisService service = ref.watch(usageAnalysisServiceProvider);
  return service.bulkCalculateDailyUsageRates(userId);
}

/// UI状態管理：選択中材料カテゴリー
/// **ライフサイクル**: keepAlive（UI状態は永続化）
/// **データ性質**: uiState, **アクセス頻度**: high
@riverpod
class SelectedMaterialCategory extends _$SelectedMaterialCategory {
  @override
  String build() {
    ref.keepAlive(); // UI状態は画面使用中は永続化
    return "all"; // デフォルトは全カテゴリー
  }

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
/// **ライフサイクル**: keepAlive（UI状態は永続化）
/// **データ性質**: uiState, **アクセス頻度**: medium
@riverpod
class StockAlertFilter extends _$StockAlertFilter {
  @override
  StockLevel? build() {
    ref.keepAlive(); // UI状態は画面使用中は永続化
    return null; // デフォルトは全レベル
  }

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
/// **ライフサイクル**: keepAlive（UI状態は永続化）
/// **データ性質**: uiState, **アクセス頻度**: high
@riverpod
class MaterialSearchQuery extends _$MaterialSearchQuery {
  @override
  String build() {
    ref.keepAlive(); // UI状態は画面使用中は永続化
    return "";
  }

  /// 検索クエリを更新
  void updateQuery(String query) {
    state = query;
  }

  /// 検索クエリをクリア
  void clearQuery() {
    state = "";
  }
}

/// UI状態管理：在庫表示モード
/// **ライフサイクル**: keepAlive（UI状態は永続化）
/// **データ性質**: uiState, **アクセス頻度**: medium
@riverpod
class StockDisplayModeNotifier extends _$StockDisplayModeNotifier {
  @override
  StockDisplayMode build() {
    ref.keepAlive(); // UI状態は画面使用中は永続化
    return StockDisplayMode.grid;
  }

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
