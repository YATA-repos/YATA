import "../../../core/constants/query_types.dart";
import "../../../data/repositories/base_repository.dart";
import "../models/supplier_model.dart";

/// 供給業者リポジトリ
class SupplierRepository extends BaseRepository<Supplier, String> {
  SupplierRepository({required super.ref}) : super(tableName: "suppliers", enableMultiTenant: true);

  @override
  Supplier fromJson(Map<String, dynamic> json) => Supplier.fromJson(json);

  /// アクティブな供給業者一覧を取得
  Future<List<Supplier>> findActive() async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("is_active", true),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "name"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 名前で供給業者を検索
  Future<List<Supplier>> findByName(String name) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.ilike("name", "%$name%"),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "name"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 供給業者を非アクティブ化（論理削除）
  Future<Supplier?> deactivate(String supplierId) async => updateById(supplierId, <String, dynamic>{
      "is_active": false,
      "updated_at": DateTime.now().toIso8601String(),
    });

  /// 供給業者を再アクティブ化
  Future<Supplier?> reactivate(String supplierId) async => updateById(supplierId, <String, dynamic>{
      "is_active": true,
      "updated_at": DateTime.now().toIso8601String(),
    });
}

/// 材料-供給業者関連リポジトリ
class MaterialSupplierRepository extends BaseRepository<MaterialSupplier, String> {
  MaterialSupplierRepository({required super.ref}) : super(tableName: "material_suppliers", enableMultiTenant: true);

  @override
  MaterialSupplier fromJson(Map<String, dynamic> json) => MaterialSupplier.fromJson(json);

  /// 材料の供給業者一覧を取得
  Future<List<MaterialSupplier>> findByMaterialId(String materialId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "is_preferred", ascending: false),
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 供給業者が扱う材料一覧を取得
  Future<List<MaterialSupplier>> findBySupplierId(String supplierId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("supplier_id", supplierId),
    ];

    return find(filters: filters);
  }

  /// 材料の優先供給業者を取得
  Future<MaterialSupplier?> findPreferredSupplier(String materialId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
      QueryConditionBuilder.eq("is_preferred", true),
    ];

    final List<MaterialSupplier> results = await find(filters: filters);
    return results.isNotEmpty ? results.first : null;
  }

  /// 材料の優先供給業者を設定
  Future<void> setPreferredSupplier(
    String materialId,
    String supplierId,
  ) async {
    // 既存の優先設定を全て解除
    await _clearPreferredSuppliers(materialId);

    // 指定された供給業者を優先に設定
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
      QueryConditionBuilder.eq("supplier_id", supplierId),
    ];

    final List<MaterialSupplier> existing = await find(filters: filters);
    if (existing.isNotEmpty) {
      await updateById(existing.first.id!, <String, dynamic>{
        "is_preferred": true,
        "updated_at": DateTime.now().toIso8601String(),
      });
    }
  }

  /// 材料の優先供給業者設定を全て解除
  Future<void> _clearPreferredSuppliers(String materialId) async {
    // 注意: BaseRepositoryにバッチ更新機能が追加された時にパフォーマンス改善を検討
    // 現在の実装: 個別更新（小規模データでは許容範囲）
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
      QueryConditionBuilder.eq("is_preferred", true),
    ];

    final List<MaterialSupplier> preferredSuppliers = await find(filters: filters);
    
    // 現在は個別更新を使用（将来的にはバッチ更新で最適化可能）
    for (final MaterialSupplier supplier in preferredSuppliers) {
      await updateById(supplier.id!, <String, dynamic>{
        "is_preferred": false,
        "updated_at": DateTime.now().toIso8601String(),
      });
    }
  }
}