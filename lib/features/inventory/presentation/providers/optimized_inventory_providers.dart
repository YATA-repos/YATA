import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/cache/cache_strategy.dart";
import "../../../../core/cache/enhanced_cache_strategy.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/providers/intelligent_cache_providers.dart";
import "../../dto/inventory_dto.dart";
import "../../models/inventory_model.dart";
import "../../services/inventory_service.dart";
import "../../services/usage_analysis_service.dart";

part "optimized_inventory_providers.g.dart";

/// 最適化されたInventoryService プロバイダー
/// インテリジェントキャッシュシステムを使用
@riverpod
class OptimizedInventoryService extends _$OptimizedInventoryService with SmartCacheMixin {
  @override
  InventoryService build() {
    // サービスインスタンスは重要なため高優先度で永続化
    registerWithSmartCache(
      ref,
      "inventory_service",
      DataType.globalStaticData,
      customConfig: const EnhancedCacheConfig(
        strategy: CacheStrategy.persistent,
        dataType: DataType.globalStaticData,
        priority: CachePriority.critical,
        customTtl: Duration(hours: 24),
      ),
    );
    
    return InventoryService(ref: ref);
  }
}

/// 最適化された材料カテゴリー一覧プロバイダー
/// マスターデータとして長期キャッシュ
@riverpod
class OptimizedMaterialCategories extends _$OptimizedMaterialCategories with SmartCacheMixin {
  @override
  Future<List<MaterialCategory>> build() async {
    const String providerId = "material_categories";
    
    // マスターデータとして長期キャッシュ
    registerWithSmartCache(ref, providerId, DataType.userSemiStaticData);
    recordCacheAccess(ref, providerId);
    
    final InventoryService service = ref.watch(optimizedInventoryServiceProvider);
    return service.getMaterialCategories();
  }

  /// カテゴリーを追加（キャッシュ無効化付き）
  Future<void> addCategory(String name, String description) async {
    // 実際の追加処理（仮実装）
    
    // 関連キャッシュを無効化
    ref.invalidateSelf();
    
    final IntelligentCacheManager cacheManager = 
        ref.read(intelligentCacheManagerProvider.notifier);
    cacheManager.invalidateWithDependencies("material_categories");
  }
}

/// 最適化されたカテゴリー別材料一覧プロバイダー
/// セミスタティックデータとして中期キャッシュ
@riverpod
class OptimizedMaterials extends _$OptimizedMaterials with SmartCacheMixin {
  @override
  Future<List<Material>> build(String? categoryId) async {
    final String providerId = "materials_${categoryId ?? 'all'}";
    
    // セミスタティックデータとして中期キャッシュ
    registerWithSmartCache(
      ref, 
      providerId, 
      DataType.userSemiStaticData,
      customConfig: EnhancedCacheConfig(
        strategy: CacheStrategy.longTerm,
        dataType: DataType.userSemiStaticData,
        priority: CachePriority.high,
        dependsOn: const <String>["material_categories"],
        customTtl: const Duration(minutes: 30),
      ),
    );
    recordCacheAccess(ref, providerId);
    
    final InventoryService service = ref.watch(optimizedInventoryServiceProvider);
    return service.getMaterialsByCategory(categoryId);
  }
}

/// 最適化された在庫情報付き材料一覧プロバイダー
/// ユーザー動的データとして短期キャッシュ
@riverpod
class OptimizedMaterialsWithStockInfo extends _$OptimizedMaterialsWithStockInfo with SmartCacheMixin {
  @override
  Future<List<MaterialStockInfo>> build(String? categoryId, String userId) async {
    final String providerId = "materials_stock_${categoryId ?? 'all'}_$userId";
    
    // ユーザー動的データとして短期キャッシュ + 自動リフレッシュ
    registerWithSmartCache(
      ref, 
      providerId, 
      DataType.userDynamicData,
      customConfig: EnhancedCacheConfig(
        strategy: CacheStrategy.shortTerm,
        dataType: DataType.userDynamicData,
        autoRefresh: true,
        refreshInterval: const Duration(seconds: 30),
        dependsOn: <String>["materials_${categoryId ?? 'all'}"],
        customTtl: const Duration(minutes: 2),
      ),
    );
    recordCacheAccess(ref, providerId);
    
    final InventoryService service = ref.watch(optimizedInventoryServiceProvider);
    return service.getMaterialsWithStockInfo(categoryId, userId);
  }
}

/// 最適化された在庫アラートプロバイダー
/// リアルタイム性が重要なため軽量キャッシュ
@riverpod
class OptimizedStockAlerts extends _$OptimizedStockAlerts with SmartCacheMixin {
  @override
  Future<Map<StockLevel, List<Material>>> build() async {
    const String providerId = "stock_alerts";
    
    // 在庫アラートは頻繁に変わるため短期キャッシュ
    registerWithSmartCache(
      ref, 
      providerId, 
      DataType.userDynamicData,
      customConfig: const EnhancedCacheConfig(
        strategy: CacheStrategy.shortTerm,
        dataType: DataType.userDynamicData,
        priority: CachePriority.high,
        autoRefresh: true,
        refreshInterval: Duration(seconds: 15),
        customTtl: Duration(seconds: 30),
      ),
    );
    recordCacheAccess(ref, providerId);
    
    final InventoryService service = ref.watch(optimizedInventoryServiceProvider);
    return service.getStockAlertsByLevel();
  }

  /// アラート確認（一時的にキャッシュ無効化）
  void acknowledgeAlert() {
    ref.invalidateSelf();
  }
}

/// 最適化された緊急在庫プロバイダー
/// 緊急度が高いためリアルタイム
@riverpod
class OptimizedCriticalStockMaterials extends _$OptimizedCriticalStockMaterials with SmartCacheMixin {
  @override
  Future<List<Material>> build() async {
    const String providerId = "critical_stock_materials";
    
    // 緊急在庫は常に最新が必要なので軽量キャッシュ
    registerWithSmartCache(
      ref, 
      providerId, 
      DataType.realtimeData,
      customConfig: const EnhancedCacheConfig(
        strategy: CacheStrategy.shortTerm,
        dataType: DataType.realtimeData,
        priority: CachePriority.high,
        autoRefresh: true,
        refreshInterval: Duration(seconds: 10),
        customTtl: Duration(seconds: 15),
      ),
    );
    recordCacheAccess(ref, providerId);
    
    final InventoryService service = ref.watch(optimizedInventoryServiceProvider);
    return service.getCriticalStockMaterials();
  }
}

/// 最適化された使用日数計算プロバイダー
/// 分析データとして中期キャッシュ
@riverpod
class OptimizedBulkUsageDays extends _$OptimizedBulkUsageDays with SmartCacheMixin {
  @override
  Future<Map<String, int?>> build(String userId) async {
    final String providerId = "bulk_usage_days_$userId";
    
    // 分析データとして中期キャッシュ
    registerWithSmartCache(
      ref, 
      providerId, 
      DataType.analyticsData,
      customConfig: const EnhancedCacheConfig(
        strategy: CacheStrategy.longTerm,
        dataType: DataType.analyticsData,
        customTtl: Duration(minutes: 15),
      ),
    );
    recordCacheAccess(ref, providerId);
    
    final UsageAnalysisService service = UsageAnalysisService(ref: ref);
    return service.bulkCalculateUsageDays(userId);
  }
}

/// 最適化されたUI状態：選択中材料カテゴリー
/// UI状態として軽量永続化
@riverpod
class OptimizedSelectedMaterialCategory extends _$OptimizedSelectedMaterialCategory with SmartCacheMixin {
  @override
  String build() {
    const String providerId = "selected_material_category";
    
    // UI状態として軽量永続化
    registerWithSmartCache(
      ref, 
      providerId, 
      DataType.uiStateData,
      customConfig: const EnhancedCacheConfig(
        strategy: CacheStrategy.memoryOnly,
        dataType: DataType.uiStateData,
        priority: CachePriority.low,
        customTtl: Duration(minutes: 5),
      ),
    );
    recordCacheAccess(ref, providerId);
    
    return "all"; // デフォルトは全カテゴリー
  }

  /// カテゴリーを選択
  void selectCategory(String categoryId) {
    state = categoryId;
    recordCacheAccess(ref, "selected_material_category");
  }

  /// 全カテゴリーに戻す
  void selectAll() {
    state = "all";
    recordCacheAccess(ref, "selected_material_category");
  }

  /// 選択をリセット
  void resetSelection() {
    state = "all";
  }
}

/// 最適化された在庫フィルター状態
/// UI状態として軽量永続化
@riverpod
class OptimizedInventoryFilter extends _$OptimizedInventoryFilter with SmartCacheMixin {
  @override
  InventoryFilterState build() {
    const String providerId = "inventory_filter";
    
    registerWithSmartCache(
      ref, 
      providerId, 
      DataType.uiStateData,
      customConfig: const EnhancedCacheConfig(
        strategy: CacheStrategy.memoryOnly,
        dataType: DataType.uiStateData,
        priority: CachePriority.low,
        customTtl: Duration(minutes: 10),
      ),
    );
    recordCacheAccess(ref, providerId);
    
    return const InventoryFilterState();
  }

  /// フィルターを更新
  void updateFilter({
    StockLevel? stockLevel,
    String? searchQuery,
    bool? showAlertsOnly,
  }) {
    state = state.copyWith(
      stockLevel: stockLevel,
      searchQuery: searchQuery,
      showAlertsOnly: showAlertsOnly,
    );
    recordCacheAccess(ref, "inventory_filter");
  }

  /// フィルターをクリア
  void clearFilter() {
    state = const InventoryFilterState();
  }
}

/// 在庫フィルター状態
class InventoryFilterState {
  const InventoryFilterState({
    this.stockLevel,
    this.searchQuery,
    this.showAlertsOnly = false,
  });

  final StockLevel? stockLevel;
  final String? searchQuery;
  final bool showAlertsOnly;

  InventoryFilterState copyWith({
    StockLevel? stockLevel,
    String? searchQuery,
    bool? showAlertsOnly,
  }) => InventoryFilterState(
    stockLevel: stockLevel ?? this.stockLevel,
    searchQuery: searchQuery ?? this.searchQuery,
    showAlertsOnly: showAlertsOnly ?? this.showAlertsOnly,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryFilterState &&
          runtimeType == other.runtimeType &&
          stockLevel == other.stockLevel &&
          searchQuery == other.searchQuery &&
          showAlertsOnly == other.showAlertsOnly;

  @override
  int get hashCode =>
      stockLevel.hashCode ^
      searchQuery.hashCode ^
      showAlertsOnly.hashCode;
}

/// キャッシュ統計表示プロバイダー
@riverpod
Future<Map<String, dynamic>> inventoryCacheStats(Ref ref) async {
  final IntelligentCacheManager cacheManager = 
      ref.watch(intelligentCacheManagerProvider.notifier);
  
  final CacheStats stats = cacheManager.getStats();
  
  return <String, dynamic>{
    "total_entries": stats.totalEntries,
    "total_access": stats.totalAccess,
    "average_access": stats.averageAccessPerEntry,
    "active_timers": stats.activeTimers,
    "counts_by_type": stats.countsByType.map(
      (DataType key, int value) => MapEntry<String, int>(key.name, value),
    ),
    "counts_by_priority": stats.countsByPriority.map(
      (CachePriority key, int value) => MapEntry<String, int>(key.name, value),
    ),
  };
}