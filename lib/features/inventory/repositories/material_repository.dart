import "../../../core/base/base_multitenant_repository.dart";
import "../../../core/cache/cache_strategy.dart";
import "../../../core/cache/repository_cache_mixin.dart";
import "../../../core/constants/query_types.dart";
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
}
