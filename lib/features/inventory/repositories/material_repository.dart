import "../../../core/base/base_multitenant_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/inventory_model.dart";

/// 材料リポジトリ
class MaterialRepository extends BaseMultiTenantRepository<Material, String> {
  MaterialRepository({required super.ref}) : super(tableName: "materials");

  @override
  Material fromJson(Map<String, dynamic> json) => Material.fromJson(json);

  /// カテゴリIDで材料を取得（None時は全件）
  Future<List<Material>> findByCategoryId(String? categoryId) async {
    if (categoryId == null) {
      return list();
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("category_id", categoryId),
    ];

    return find(filters: filters);
  }

  /// アラート閾値を下回る材料を取得
  Future<List<Material>> findBelowAlertThreshold() async {
    // 全材料を取得
    final List<Material> allMaterials = await list();

    // アラート閾値以下の材料をフィルタ
    return allMaterials
        .where((Material material) => material.currentStock <= material.alertThreshold)
        .toList();
  }

  /// 緊急閾値を下回る材料を取得
  Future<List<Material>> findBelowCriticalThreshold() async {
    // 全材料を取得
    final List<Material> allMaterials = await list();

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

    return find(filters: filters);
  }

  /// 材料の在庫量を更新
  Future<Material?> updateStockAmount(String materialId, double newAmount) async {
    // 在庫量を更新（マルチテナント対応により自動的にuser_idチェック）
    final Map<String, dynamic> updateData = <String, dynamic>{"current_stock": newAmount};
    final Material? updatedMaterial = await updateById(materialId, updateData);

    return updatedMaterial;
  }
}
