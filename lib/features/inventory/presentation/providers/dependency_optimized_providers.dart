import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../data/local/cache/enhanced_cache_strategy.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/providers/dependency_optimizer.dart";
import "../../../../core/providers/intelligent_cache_providers.dart";
import "../../../../core/utils/provider_logger.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../dto/inventory_dto.dart";
import "../../models/inventory_model.dart";
import "../../services/inventory_service.dart";

part "dependency_optimized_providers.g.dart";

/// 依存関係最適化された在庫プロバイダー群
/// 不要な再計算を削減し、効率的な更新チェーンを構築

/// 基底在庫サービスプロバイダー（依存関係の起点）
@riverpod
class OptimizedInventoryServiceBase extends _$OptimizedInventoryServiceBase 
    with SmartCacheMixin, DependencyOptimizationMixin {
  @override
  InventoryService build() {
    const String providerId = "inventory_service_base";
    
    registerWithSmartCache(ref, providerId, DataType.globalStaticData);
    
    return InventoryService(ref: ref);
  }
}

/// 材料カテゴリープロバイダー（最適化版）
@riverpod
class OptimizedMaterialCategoriesV2 extends _$OptimizedMaterialCategoriesV2 
    with SmartCacheMixin, DependencyOptimizationMixin {
  @override
  Future<List<MaterialCategory>> build() async {
    const String providerId = "material_categories_v2";
    
    registerWithSmartCache(ref, providerId, DataType.userSemiStaticData);
    recordCacheAccess(ref, providerId);
    
    // サービス依存関係を登録（弱依存）
    registerOptimizedDependency(
      ref,
      "inventory_service_base",
      providerId,
      DependencyType.weak,
      priority: DependencyPriority.low,
      batchable: true,
    );
    
    final InventoryService service = ref.watch(optimizedInventoryServiceBaseProvider);
    final List<MaterialCategory> categories = await service.getMaterialCategories();
    
    // 依存先プロバイダーへの変更通知
    notifyProviderChange(ref, providerId, newValue: categories);
    
    return categories;
  }

  /// カテゴリー追加（最適化された無効化）
  Future<void> addCategory(String name, String description) async {
    // カテゴリー追加処理
    
    // 関連プロバイダーの選択的無効化
    notifyProviderChange(ref, "material_categories_v2");
  }
}

/// 材料一覧プロバイダー（最適化版）
@riverpod
class OptimizedMaterialsV2 extends _$OptimizedMaterialsV2 
    with SmartCacheMixin, DependencyOptimizationMixin {
  @override
  Future<List<Material>> build(String? categoryId) async {
    final String providerId = "materials_v2_${categoryId ?? 'all'}";
    
    registerWithSmartCache(ref, providerId, DataType.userSemiStaticData);
    recordCacheAccess(ref, providerId);
    
    // カテゴリー依存関係を登録（計算依存、デバウンス付き）
    registerOptimizedDependency(
      ref,
      "material_categories_v2",
      providerId,
      DependencyType.computed,
      debounceMs: 100, // 100msデバウンス
      batchable: true,
    );
    
    final InventoryService service = ref.watch(optimizedInventoryServiceBaseProvider);
    
    // カテゴリーが指定されている場合の条件付き依存
    if (categoryId != null) {
      final List<MaterialCategory> categories = await ref.watch(
        optimizedMaterialCategoriesV2Provider.future,
      );
      
      // カテゴリーが存在しない場合は空を返す
      if (!categories.any((MaterialCategory cat) => cat.id == categoryId)) {
        return <Material>[];
      }
    }
    
    final List<Material> materials = await service.getMaterialsByCategory(categoryId);
    
    // 変更通知
    notifyProviderChange(ref, providerId, newValue: materials);
    
    return materials;
  }
}

/// 在庫情報付き材料プロバイダー（最適化版）
@riverpod
class OptimizedMaterialsWithStockInfoV2 extends _$OptimizedMaterialsWithStockInfoV2 
    with SmartCacheMixin, DependencyOptimizationMixin {
  @override
  Future<List<MaterialStockInfo>> build(String? categoryId, String userId) async {
    final String providerId = "materials_stock_v2_${categoryId ?? 'all'}_$userId";
    
    registerWithSmartCache(ref, providerId, DataType.userDynamicData);
    recordCacheAccess(ref, providerId);
    
    // 材料マスターへの弱依存（バッチ処理可能）
    registerOptimizedDependency(
      ref,
      "materials_v2_${categoryId ?? 'all'}",
      providerId,
      DependencyType.weak,
      priority: DependencyPriority.low,
      debounceMs: 50,
      batchable: true,
    );
    
    // ユーザー変更への強依存
    registerOptimizedDependency(
      ref,
      "current_user",
      providerId,
      DependencyType.strong,
      priority: DependencyPriority.high,
      condition: () => ref.read(currentUserIdProvider) == userId,
    );
    
    final InventoryService service = ref.watch(optimizedInventoryServiceBaseProvider);
    final List<MaterialStockInfo> stockInfo = await service.getMaterialsWithStockInfo(categoryId, userId);
    
    // 変更通知（在庫レベル別に分析）
    notifyProviderChange(ref, providerId, newValue: stockInfo);
    
    // 派生データの更新トリガー
    _triggerDerivedUpdates(stockInfo);
    
    return stockInfo;
  }

  /// 派生データの更新トリガー
  void _triggerDerivedUpdates(List<MaterialStockInfo> stockInfo) {
    // 緊急在庫材料の更新が必要かチェック
    final bool hasCritical = stockInfo.any(
      (MaterialStockInfo info) => info.material.currentStock <= info.material.criticalThreshold,
    );
    
    if (hasCritical) {
      notifyProviderChange(ref, "critical_stock_materials_v2", newValue: hasCritical);
    }
    
    // 在庫アラートの更新が必要かチェック
    final bool hasAlerts = stockInfo.any(
      (MaterialStockInfo info) => info.material.currentStock <= info.material.alertThreshold,
    );
    
    if (hasAlerts) {
      notifyProviderChange(ref, "stock_alerts_v2", newValue: hasAlerts);
    }
  }
}

/// 在庫アラートプロバイダー（最適化版）
@riverpod
class OptimizedStockAlertsV2 extends _$OptimizedStockAlertsV2 
    with SmartCacheMixin, DependencyOptimizationMixin {
  @override
  Future<Map<StockLevel, List<Material>>> build() async {
    const String providerId = "stock_alerts_v2";
    
    registerWithSmartCache(ref, providerId, DataType.userDynamicData);
    recordCacheAccess(ref, providerId);
    
    // 在庫情報への監視依存（条件付き更新）
    registerOptimizedDependency(
      ref,
      "materials_stock_v2_all",
      providerId,
      DependencyType.watch,
      priority: DependencyPriority.high,
      debounceMs: 200, // アラートは少し遅延許可
      condition: _shouldUpdateAlerts,
    );
    
    final InventoryService service = ref.watch(optimizedInventoryServiceBaseProvider);
    final Map<StockLevel, List<Material>> alerts = await service.getStockAlertsByLevel();
    
    notifyProviderChange(ref, providerId, newValue: alerts);
    
    return alerts;
  }

  /// アラート更新が必要かチェック
  bool _shouldUpdateAlerts() =>
      // 前回の更新から十分時間が経過している場合のみ更新
      // 実装では前回更新時間を記録して判定
      true; // 簡略化

  /// アラート確認
  void acknowledgeAlert() {
    // アラート確認処理
    notifyProviderChange(ref, "stock_alerts_v2");
  }
}

/// 緊急在庫材料プロバイダー（最適化版）
@riverpod
class OptimizedCriticalStockMaterialsV2 extends _$OptimizedCriticalStockMaterialsV2 
    with SmartCacheMixin, DependencyOptimizationMixin {
  @override
  Future<List<Material>> build() async {
    const String providerId = "critical_stock_materials_v2";
    
    registerWithSmartCache(ref, providerId, DataType.realtimeData);
    recordCacheAccess(ref, providerId);
    
    // 在庫アラートへの強依存（即座に更新が必要）
    registerOptimizedDependency(
      ref,
      "stock_alerts_v2",
      providerId,
      DependencyType.strong,
      priority: DependencyPriority.critical,
      condition: _hasCriticalChanges,
    );
    
    final InventoryService service = ref.watch(optimizedInventoryServiceBaseProvider);
    final List<Material> criticalMaterials = await service.getCriticalStockMaterials();
    
    notifyProviderChange(ref, providerId, newValue: criticalMaterials);
    
    return criticalMaterials;
  }

  /// 緊急レベルの変更があるかチェック
  bool _hasCriticalChanges() =>
      // 緊急在庫レベルの変更を検出
      true; // 簡略化
}

/// UI状態プロバイダー（最適化版）
@riverpod
class OptimizedSelectedCategoryV2 extends _$OptimizedSelectedCategoryV2 
    with SmartCacheMixin, DependencyOptimizationMixin {
  @override
  String build() {
    const String providerId = "selected_category_v2";
    
    registerWithSmartCache(ref, providerId, DataType.uiStateData);
    recordCacheAccess(ref, providerId);
    
    return "all";
  }

  /// カテゴリー選択（最適化された更新）
  void selectCategory(String categoryId) {
    final String previousCategory = state;
    state = categoryId;
    
    // 関連プロバイダーへの効率的な通知
    if (previousCategory != categoryId) {
      notifyProviderChange(ref, "selected_category_v2", 
        newValue: categoryId, oldValue: previousCategory);
      
      // 材料リストプロバイダーの更新をトリガー
      notifyProviderChange(ref, "materials_v2_$categoryId");
      notifyProviderChange(ref, "materials_stock_v2_$categoryId");
    }
  }
}

/// 依存関係パフォーマンス監視プロバイダー
@riverpod
Future<Map<String, dynamic>> inventoryDependencyPerformance(Ref ref) async {
  final DependencyOptimizer optimizer = ref.watch(dependencyOptimizerProvider.notifier);
  final Map<String, DependencyStats> stats = ref.watch(dependencyOptimizerProvider);
  
  // 在庫関連プロバイダーの統計を集計
  final List<String> inventoryProviders = <String>[
    "material_categories_v2",
    "materials_v2_all",
    "materials_stock_v2_all",
    "stock_alerts_v2",
    "critical_stock_materials_v2",
  ];
  
  final Map<String, dynamic> performance = <String, dynamic>{};
  
  for (final String providerId in inventoryProviders) {
    final DependencyStats? providerStats = stats[providerId];
    if (providerStats != null) {
      performance[providerId] = <String, dynamic>{
        "dependency_count": providerStats.dependencyCount,
        "invalidation_count": providerStats.invalidationCount,
        "strong_dependencies": providerStats.strongDependencies,
        "weak_dependencies": providerStats.weakDependencies,
        "last_invalidated": providerStats.lastInvalidated?.toIso8601String(),
      };
    }
  }
  
  // 最適化推奨事項
  final List<OptimizationRecommendation> recommendations = optimizer.getOptimizationRecommendations();
  performance["recommendations"] = recommendations.map((OptimizationRecommendation rec) => <String, dynamic>{
    "type": rec.type.name,
    "message": rec.message,
    "severity": rec.severity.name,
    "provider_id": rec.providerId,
  }).toList();
  
  return performance;
}

/// 依存関係初期化プロバイダー
@riverpod
class InventoryDependencyInitializer extends _$InventoryDependencyInitializer {
  @override
  bool build() {
    // 在庫プロバイダー群の依存関係を一括登録
    _initializeInventoryDependencies();
    return true;
  }

  void _initializeInventoryDependencies() {
    final DependencyOptimizer optimizer = ref.read(dependencyOptimizerProvider.notifier);
    
    // 依存関係定義リスト
    final List<ProviderDependency> dependencies = <ProviderDependency>[
      // カテゴリー → 材料
      const ProviderDependency(
        sourceId: "material_categories_v2",
        targetId: "materials_v2_all",
        type: DependencyType.computed,
        priority: DependencyPriority.normal,
        debounceMs: 100,
        batchable: true,
      ),
      
      // 材料 → 在庫情報付き材料
      const ProviderDependency(
        sourceId: "materials_v2_all",
        targetId: "materials_stock_v2_all",
        type: DependencyType.weak,
        priority: DependencyPriority.low,
        debounceMs: 50,
        batchable: true,
      ),
      
      // 在庫情報 → アラート
      const ProviderDependency(
        sourceId: "materials_stock_v2_all",
        targetId: "stock_alerts_v2",
        type: DependencyType.watch,
        priority: DependencyPriority.high,
        debounceMs: 200,
      ),
      
      // アラート → 緊急在庫
      const ProviderDependency(
        sourceId: "stock_alerts_v2",
        targetId: "critical_stock_materials_v2",
        type: DependencyType.strong,
        priority: DependencyPriority.critical,
      ),
      
      // UI状態 → 材料表示
      const ProviderDependency(
        sourceId: "selected_category_v2",
        targetId: "materials_v2_selected",
        type: DependencyType.computed,
        priority: DependencyPriority.normal,
        debounceMs: 50,
      ),
    ];
    
    optimizer.registerMultipleDependencies(dependencies);
  }
}