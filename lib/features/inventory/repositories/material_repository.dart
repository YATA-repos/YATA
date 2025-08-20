import "../../../core/constants/enums.dart";
import "../../../core/constants/query_types.dart";
import "../../../infrastructure/local/cache/cache_strategy.dart";
import "../../../infrastructure/local/cache/repository_cache_mixin.dart";
import "../../../data/repositories/base_multitenant_repository.dart";
import "../dto/inventory_dto.dart";
import "../models/inventory_model.dart";

/// 材料リポジトリ（キャッシュ対応）
class MaterialRepository extends BaseMultiTenantRepository<Material, String> 
    with RepositoryCacheMixin<Material, String> {
  MaterialRepository({required super.ref}) : super(tableName: "materials");

  @override
  Material fromJson(Map<String, dynamic> json) => Material.fromJson(json);

  /// RepositoryCacheMixin用のcurrentUserId実装
  /// (BaseMultiTenantRepositoryのcurrentUserIdを使用)

  /// キャッシュ設定（マスターデータなので長期キャッシュ）
  @override
  CacheConfig get cacheConfig => const CacheConfig(
    strategy: CacheStrategy.longTerm,
    maxItems: 200,
  );

  /// カテゴリIDで材料を取得（None時は全件）
  /// キャッシュ対応版（マスターデータなので長期キャッシュが効果的）
  Future<List<Material>> findByCategoryId(String? categoryId) async {
    if (categoryId == null) {
      return findCached(); // キャッシュ付きの全件取得
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("category_id", categoryId),
    ];

    return findCached(filters: filters); // キャッシュ付きのフィルタ取得
  }

  /// アラート閾値を下回る材料を取得
  Future<List<Material>> findBelowAlertThreshold() async {
    // 全材料を取得
    final List<Material> allMaterials = await findCached(); // キャッシュから取得

    // アラート閾値以下の材料をフィルタ
    return allMaterials
        .where((Material material) => material.currentStock <= material.alertThreshold)
        .toList();
  }

  /// 緊急閾値を下回る材料を取得
  Future<List<Material>> findBelowCriticalThreshold() async {
    // 全材料を取得
    final List<Material> allMaterials = await findCached(); // キャッシュから取得

    // 緊急閾値以下の材料をフィルタ
    return allMaterials
        .where((Material material) => material.currentStock <= material.criticalThreshold)
        .toList();
  }

  /// IDリストで材料を取得
  Future<List<Material>> findByIds(List<String> materialIds) async {
    if (materialIds.isEmpty) {
      return <Material>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.inList("id", materialIds),
    ];

    return findCached(filters: filters); // キャッシュ付きフィルタ検索
  }

  /// 材料の在庫量を更新（キャッシュ無効化付き）
  Future<Material?> updateStockAmount(String materialId, double newAmount) async {
    // 在庫量を更新（マルチテナント対応により自動的にuser_idチェック）
    final Map<String, dynamic> updateData = <String, dynamic>{"current_stock": newAmount};
    
    // キャッシュ無効化付き更新（在庫変更は関連データに影響）
    final Material? updatedMaterial = await updateWithCacheInvalidation(materialId, updateData);

    return updatedMaterial;
  }

  /// 在庫情報付きの材料リストを取得
  Future<List<MaterialStockInfo>> getMaterialsWithStockInfo(
    List<String>? materialIds,
    String userId,
  ) async {
    List<Material> materials;

    if (materialIds != null && materialIds.isNotEmpty) {
      // 指定IDの材料を取得
      materials = await findByIds(materialIds);
    } else {
      // 全材料を取得
      materials = await findCached();
    }

    // MaterialStockInfoに変換
    final List<MaterialStockInfo> stockInfoList = <MaterialStockInfo>[];
    
    for (final Material material in materials) {
      final StockLevel stockLevel = _calculateStockLevel(material);
      final MaterialStockInfo stockInfo = MaterialStockInfo(
        material: material,
        stockLevel: stockLevel,
        estimatedUsageDays: _calculateEstimatedUsageDays(material),
        dailyUsageRate: _calculateDailyUsageRate(material),
      );
      stockInfoList.add(stockInfo);
    }

    return stockInfoList;
  }

  /// 在庫レベルを計算
  StockLevel _calculateStockLevel(Material material) {
    final double currentStock = material.currentStock;
    final double criticalThreshold = material.criticalThreshold;
    final double alertThreshold = material.alertThreshold;

    if (currentStock <= criticalThreshold) {
      return StockLevel.critical;
    } else if (currentStock <= alertThreshold) {
      return StockLevel.low;
    } else {
      return StockLevel.sufficient;
    }
  }

  /// 推定使用日数を計算（簡易版）
  int? _calculateEstimatedUsageDays(Material material) {
    // 簡易計算：現在の在庫÷平均使用量（仮定値）
    const double averageDailyUsage = 1.0; // 仮の値
    if (material.currentStock > 0) {
      return (material.currentStock / averageDailyUsage).ceil();
    }
    return null;
  }

  /// 日間使用率を計算（簡易版）
  double? _calculateDailyUsageRate(Material material) {
    // 簡易計算：固定値を返す（実際はログデータから計算）
    return 1.0; // 仮の値
  }
}
