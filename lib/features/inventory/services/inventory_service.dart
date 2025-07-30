import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/constants/enums.dart";
import "../../../core/logging/logger_mixin.dart";
import "../dto/inventory_dto.dart";
import "../dto/transaction_dto.dart";
import "../models/inventory_model.dart";
import "material_management_service.dart";
import "order_stock_service.dart";
import "stock_level_service.dart";
import "stock_operation_service.dart";
import "usage_analysis_service.dart";

/// 在庫管理統合サービス
/// 複数のサービスを組み合わせて在庫管理の全機能を提供
class InventoryService with LoggerMixin {
  InventoryService({
    required Ref ref,
    MaterialManagementService? materialManagementService,
    StockLevelService? stockLevelService,
    StockOperationService? stockOperationService,
    UsageAnalysisService? usageAnalysisService,
    OrderStockService? orderStockService,
  }) : _materialManagementService = materialManagementService ?? MaterialManagementService(ref: ref),
       _stockLevelService = stockLevelService ?? StockLevelService(ref: ref),
       _stockOperationService = stockOperationService ?? StockOperationService(ref: ref),
       _usageAnalysisService = usageAnalysisService ?? UsageAnalysisService(ref: ref),
       _orderStockService = orderStockService ?? OrderStockService(ref: ref);

  final MaterialManagementService _materialManagementService;
  final StockLevelService _stockLevelService;
  final StockOperationService _stockOperationService;
  final UsageAnalysisService _usageAnalysisService;
  final OrderStockService _orderStockService;

  @override
  String get loggerComponent => "InventoryService";

  // ===== 材料管理関連メソッド =====

  /// 材料を作成
  Future<Material?> createMaterial(Material material) async =>
      _materialManagementService.createMaterial(material);

  /// 材料カテゴリ一覧を取得
  Future<List<MaterialCategory>> getMaterialCategories() async =>
      _materialManagementService.getMaterialCategories();

  /// カテゴリ別材料一覧を取得
  Future<List<Material>> getMaterialsByCategory(String? categoryId) async =>
      _materialManagementService.getMaterialsByCategory(categoryId);

  /// 材料のアラート閾値を更新
  Future<Material?> updateMaterialThresholds(
    String materialId,
    double alertThreshold,
    double criticalThreshold,
  ) async => _materialManagementService.updateMaterialThresholds(
    materialId,
    alertThreshold,
    criticalThreshold,
  );

  // ===== 在庫レベル・アラート関連メソッド =====

  /// 在庫レベル別アラート材料を取得
  Future<Map<StockLevel, List<Material>>> getStockAlertsByLevel() async =>
      _stockLevelService.getStockAlertsByLevel();

  /// 緊急レベルの材料一覧を取得
  Future<List<Material>> getCriticalStockMaterials() async =>
      _stockLevelService.getCriticalStockMaterials();

  /// 材料一覧を在庫レベル・使用可能日数付きで取得
  Future<List<MaterialStockInfo>> getMaterialsWithStockInfo(
    String? categoryId,
    String userId,
  ) async {
    // 使用量分析データを取得
    final Map<String, int?> usageDays = await _usageAnalysisService.bulkCalculateUsageDays(userId);
    final Map<String, double?> dailyUsageRates = await _usageAnalysisService
        .bulkCalculateDailyUsageRates(userId);

    // 在庫レベルサービスで情報を組み立て
    return _stockLevelService.getMaterialsWithStockInfo(
      categoryId,
      usageDays: usageDays,
      dailyUsageRates: dailyUsageRates,
    );
  }

  /// 詳細な在庫アラート情報を取得（レベル別 + 詳細情報付き）
  Future<Map<String, List<MaterialStockInfo>>> getDetailedStockAlerts(String userId) async {
    // 使用量分析データを取得
    final Map<String, int?> usageDays = await _usageAnalysisService.bulkCalculateUsageDays(userId);
    final Map<String, double?> dailyUsageRates = await _usageAnalysisService
        .bulkCalculateDailyUsageRates(userId);

    // 在庫レベルサービスで詳細アラート情報を取得
    return _stockLevelService.getDetailedStockAlerts(
      usageDays: usageDays,
      dailyUsageRates: dailyUsageRates,
    );
  }

  // ===== 在庫操作関連メソッド =====

  /// 材料在庫を手動更新
  Future<Material?> updateMaterialStock(StockUpdateRequest request, String userId) async =>
      _stockOperationService.updateMaterialStock(request, userId);

  /// 仕入れを記録し、在庫を増加
  Future<String?> recordPurchase(PurchaseRequest request, String userId) async =>
      _stockOperationService.recordPurchase(request, userId);

  // ===== 使用量分析関連メソッド =====

  /// 材料の平均使用量を計算（日次）
  Future<double?> calculateMaterialUsageRate(String materialId, int days, String userId) async =>
      _usageAnalysisService.calculateMaterialUsageRate(materialId, days, userId);

  /// 推定使用可能日数を計算
  Future<int?> calculateEstimatedUsageDays(String materialId, String userId) async =>
      _usageAnalysisService.calculateEstimatedUsageDays(materialId, userId);

  /// 全材料の使用可能日数を一括計算
  Future<Map<String, int?>> bulkCalculateUsageDays(String userId) async =>
      _usageAnalysisService.bulkCalculateUsageDays(userId);

  // ===== 注文関連在庫操作メソッド =====

  /// 注文に対する材料を消費（在庫減算）
  Future<bool> consumeMaterialsForOrder(String orderId, String userId) async =>
      _orderStockService.consumeMaterialsForOrder(orderId, userId);

  /// 注文キャンセル時の材料を復元（在庫復旧）
  Future<bool> restoreMaterialsForOrder(String orderId, String userId) async =>
      _orderStockService.restoreMaterialsForOrder(orderId, userId);
}
