import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/inventory_model.dart";

/// 材料リポジトリ
class MaterialRepository extends BaseRepository<Material, String> {
  /// コンストラクタ
  MaterialRepository() : super(tableName: "materials");

  @override
  Material Function(Map<String, dynamic> json) get fromJson => Material.fromJson;

  /// カテゴリIDで材料を取得（None時は全件）
  Future<List<Material>> findByCategoryId(String? categoryId, String userId) async {
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.eq("user_id", userId)];

    if (categoryId != null) {
      filters.add(QueryConditionBuilder.eq("category_id", categoryId));
    }

    return find(filters: filters);
  }

  /// アラート閾値を下回る材料を取得
  Future<List<Material>> findBelowAlertThreshold(String userId) async {
    // ユーザーIDでフィルタして全材料を取得
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.eq("user_id", userId)];
    final List<Material> allMaterials = await find(filters: filters);

    // アラート閾値以下の材料をフィルタ
    return allMaterials
        .where((Material material) => material.currentStock <= material.alertThreshold)
        .toList();
  }

  /// 緊急閾値を下回る材料を取得
  Future<List<Material>> findBelowCriticalThreshold(String userId) async {
    // ユーザーIDでフィルタして全材料を取得
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.eq("user_id", userId)];
    final List<Material> allMaterials = await find(filters: filters);

    // 緊急閾値以下の材料をフィルタ
    return allMaterials
        .where((Material material) => material.currentStock <= material.criticalThreshold)
        .toList();
  }

  /// IDリストで材料を取得
  Future<List<Material>> findByIds(List<String> materialIds, String userId) async {
    if (materialIds.isEmpty) {
      return <Material>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.inList("id", materialIds),
    ];

    return find(filters: filters);
  }

  /// 材料の在庫量を更新
  Future<Material?> updateStockAmount(String materialId, double newAmount, String userId) async {
    // 対象材料を取得
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("id", materialId),
      QueryConditionBuilder.eq("user_id", userId),
    ];

    final List<Material> materials = await find(filters: filters, limit: 1);
    if (materials.isEmpty) {
      return null;
    }

    // 在庫量を更新
    final Map<String, dynamic> updateData = <String, dynamic>{"current_stock": newAmount};
    final Material? updatedMaterial = await updateById(materialId, updateData);

    return updatedMaterial;
  }
}
