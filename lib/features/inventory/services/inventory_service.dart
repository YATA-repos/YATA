import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/constants/enums.dart";
import "../../../core/logging/logger_mixin.dart";
import "../../../data/realtime/realtime_config.dart";
import "../../../data/realtime/realtime_service_mixin.dart";
import "../../../core/utils/error_handler.dart";
import "../../auth/presentation/providers/auth_providers.dart";
import "../dto/inventory_dto.dart";
import "../dto/transaction_dto.dart";
import "../models/inventory_model.dart";
import "material_management_service.dart";
import "order_stock_service.dart";
import "stock_level_service.dart";
import "stock_operation_service.dart";
import "usage_analysis_service.dart";

/// 在庫管理統合サービス（リアルタイム対応）
/// 複数のサービスを組み合わせて在庫管理の全機能を提供
class InventoryService with LoggerMixin, RealtimeServiceMixin 
    implements RealtimeServiceControl {
  InventoryService({
    required Ref ref,
    MaterialManagementService? materialManagementService,
    StockLevelService? stockLevelService,
    StockOperationService? stockOperationService,
    UsageAnalysisService? usageAnalysisService,
    OrderStockService? orderStockService,
  }) : _ref = ref,
       _materialManagementService = materialManagementService ?? MaterialManagementService(ref: ref),
       _stockLevelService = stockLevelService ?? StockLevelService(ref: ref),
       _stockOperationService = stockOperationService ?? StockOperationService(ref: ref),
       _usageAnalysisService = usageAnalysisService ?? UsageAnalysisService(ref: ref),
       _orderStockService = orderStockService ?? OrderStockService(ref: ref);

  final Ref _ref;
  final MaterialManagementService _materialManagementService;
  final StockLevelService _stockLevelService;
  final StockOperationService _stockOperationService;
  final UsageAnalysisService _usageAnalysisService;
  final OrderStockService _orderStockService;

  @override
  String get loggerComponent => "InventoryService";

  // ===== RealtimeServiceMixin 必須実装 =====

  @override
  String? get currentUserId {
    try {
      return _ref.read(currentUserIdProvider);
    } catch (e) {
      ErrorHandler.instance.handleServiceError("get current user ID", e);
    }
  }

  @override
  String get serviceName => "InventoryService";

  @override
  Future<void> startRealtimeMonitoring() async {
    try {
      logInfo("Starting inventory realtime monitoring");

      // 材料テーブルの監視開始
      await startFeatureMonitoring(
        RealtimeFeature.inventory,
        "materials",
        _handleMaterialUpdate,
        eventTypes: const <String>["INSERT", "UPDATE", "DELETE"],
      );

      // 在庫テーブルの監視開始
      await startFeatureMonitoring(
        RealtimeFeature.inventory,
        "stock_levels", 
        _handleStockLevelUpdate,
        eventTypes: const <String>["UPDATE"], // 在庫レベル変更のみ
      );

      logInfo("Inventory realtime monitoring started");
    } catch (e) {
      logError("Failed to start inventory realtime monitoring", e);
      rethrow;
    }
  }

  @override
  Future<void> stopRealtimeMonitoring() async {
    try {
      logInfo("Stopping inventory realtime monitoring");
      await stopFeatureMonitoring(RealtimeFeature.inventory);
      logInfo("Inventory realtime monitoring stopped");
    } catch (e) {
      logError("Failed to stop inventory realtime monitoring", e);
      rethrow;
    }
  }

  // ===== RealtimeServiceControl実装 =====

  @override
  Future<void> enableRealtimeFeatures() async {
    await startRealtimeMonitoring();
  }

  @override
  Future<void> disableRealtimeFeatures() async {
    await stopRealtimeMonitoring();
  }

  @override
  bool isFeatureRealtimeEnabled(RealtimeFeature feature) => isMonitoringFeature(feature);

  @override
  bool isRealtimeConnected() => isRealtimeHealthy();

  @override
  Map<String, dynamic> getRealtimeInfo() => getRealtimeStats();

  // ===== リアルタイムイベントハンドラ =====

  void _handleMaterialUpdate(Map<String, dynamic> data) {
    try {
      final String eventType = data["event_type"] as String;
      final Map<String, dynamic>? newRecord = data["new_record"] as Map<String, dynamic>?;
      final Map<String, dynamic>? oldRecord = data["old_record"] as Map<String, dynamic>?;

      logDebug("Material update received: $eventType");

      switch (eventType) {
        case "INSERT":
          if (newRecord != null) {
            _handleMaterialCreated(newRecord);
          }
          break;
        case "UPDATE":
          if (newRecord != null && oldRecord != null) {
            _handleMaterialUpdated(newRecord, oldRecord);
          }
          break;
        case "DELETE":
          if (oldRecord != null) {
            _handleMaterialDeleted(oldRecord);
          }
          break;
      }
    } catch (e) {
      logError("Error processing material update - continuing operation", e);
      // リアルタイム更新の内部処理エラーは継続可能なため、エラーを記録して処理を継続
    }
  }

  void _handleStockLevelUpdate(Map<String, dynamic> data) {
    try {
      final Map<String, dynamic>? newRecord = data["new_record"] as Map<String, dynamic>?;
      final Map<String, dynamic>? oldRecord = data["old_record"] as Map<String, dynamic>?;

      if (newRecord != null && oldRecord != null) {
        _handleStockLevelChanged(newRecord, oldRecord);
      }
    } catch (e) {
      logError("Error processing stock level update - continuing operation", e);
      // リアルタイム更新の内部処理エラーは継続可能なため、エラーを記録して処理を継続
    }
  }

  void _handleMaterialCreated(Map<String, dynamic> data) {
    logInfo("New material created: ${data['name']}");
    _notifyInventoryChanged("material_created", data);
  }

  void _handleMaterialUpdated(Map<String, dynamic> newData, Map<String, dynamic> oldData) {
    logInfo("Material updated: ${newData['name']}");
    _notifyInventoryChanged("material_updated", <String, dynamic>{
      "new": newData,
      "old": oldData,
    });
  }

  void _handleMaterialDeleted(Map<String, dynamic> data) {
    logInfo("Material deleted: ${data['name']}");
    _notifyInventoryChanged("material_deleted", data);
  }

  void _handleStockLevelChanged(Map<String, dynamic> newData, Map<String, dynamic> oldData) {
    final double oldLevel = _parseToDouble(oldData["current_stock"]) ?? 0.0;
    final double newLevel = _parseToDouble(newData["current_stock"]) ?? 0.0;
    
    logInfo("Stock level changed: ${newData['material_id']} ($oldLevel -> $newLevel)");
    
    // 在庫アラートの確認
    _checkStockAlert(newData, oldLevel, newLevel);
    
    // UI層への間接通知
    _notifyInventoryChanged("stock_level_updated", <String, dynamic>{
      "material_id": newData["material_id"],
      "old_level": oldLevel,
      "new_level": newLevel,
      "change": newLevel - oldLevel,
    });
  }

  void _notifyInventoryChanged(String eventType, Map<String, dynamic> data) {
    // ログ経由でUI層に間接通知
    logInfo("INVENTORY_EVENT: $eventType - $data");
  }

  void _checkStockAlert(Map<String, dynamic> stockData, double oldLevel, double newLevel) {
    final double minThreshold = (stockData["min_threshold"] as num?)?.toDouble() ?? 0.0;
    final double criticalThreshold = (stockData["critical_threshold"] as num?)?.toDouble() ?? 0.0;

    if (newLevel <= criticalThreshold && oldLevel > criticalThreshold) {
      logWarning("CRITICAL STOCK ALERT: ${stockData["material_id"]} - $newLevel units remaining");
      _notifyInventoryChanged("critical_stock_alert", stockData);
    } else if (newLevel <= minThreshold && oldLevel > minThreshold) {
      logWarning("LOW STOCK ALERT: ${stockData["material_id"]} - $newLevel units remaining");
      _notifyInventoryChanged("low_stock_alert", stockData);
    }
  }

  /// Service終了時の処理
  Future<void> dispose() async {
    await stopAllMonitoring();
    logInfo("InventoryService disposed");
  }

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

  /// 安全なdouble変換ヘルパー
  double? _parseToDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
