import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/inventory/supplier_repository_contract.dart";
import "../models/supplier_model.dart";

/// 供給業者リポジトリ
class SupplierRepository implements SupplierRepositoryContract<Supplier> {
  SupplierRepository({required repo_contract.CrudRepository<Supplier, String> delegate})
    : _delegate = delegate;

  final repo_contract.CrudRepository<Supplier, String> _delegate;

  /// アクティブな供給業者一覧を取得
  @override
  Future<List<Supplier>> findActive() async {
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.eq("is_active", true)];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "name"),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 名前で供給業者を検索
  @override
  Future<List<Supplier>> findByName(String name) async {
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.ilike("name", "%$name%")];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "name"),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 供給業者を非アクティブ化（論理削除）
  @override
  Future<Supplier?> deactivate(String supplierId) async => _delegate.updateById(
    supplierId,
    <String, dynamic>{"is_active": false, "updated_at": DateTime.now().toIso8601String()},
  );

  /// 供給業者を再アクティブ化
  @override
  Future<Supplier?> reactivate(String supplierId) async => _delegate.updateById(
    supplierId,
    <String, dynamic>{"is_active": true, "updated_at": DateTime.now().toIso8601String()},
  );

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<Supplier?> create(Supplier entity) => _delegate.create(entity);

  @override
  Future<List<Supplier>> bulkCreate(List<Supplier> entities) => _delegate.bulkCreate(entities);

  @override
  Future<Supplier?> getById(String id) => _delegate.getById(id);

  @override
  Future<Supplier?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<Supplier?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<Supplier?> updateByPrimaryKey(Map<String, dynamic> keyMap, Map<String, dynamic> updates) =>
      _delegate.updateByPrimaryKey(keyMap, updates);

  @override
  Future<void> deleteById(String id) => _delegate.deleteById(id);

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.deleteByPrimaryKey(keyMap);

  @override
  Future<void> bulkDelete(List<String> keys) => _delegate.bulkDelete(keys);

  @override
  Future<List<Supplier>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}

/// 材料-供給業者関連リポジトリ
class MaterialSupplierRepository implements MaterialSupplierRepositoryContract<MaterialSupplier> {
  MaterialSupplierRepository({
    required repo_contract.CrudRepository<MaterialSupplier, String> delegate,
  }) : _delegate = delegate;

  final repo_contract.CrudRepository<MaterialSupplier, String> _delegate;

  /// 材料の供給業者一覧を取得
  @override
  Future<List<MaterialSupplier>> findByMaterialId(String materialId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "is_preferred", ascending: false),
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 供給業者が扱う材料一覧を取得
  @override
  Future<List<MaterialSupplier>> findBySupplierId(String supplierId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("supplier_id", supplierId),
    ];

    return _delegate.find(filters: filters);
  }

  /// 材料の優先供給業者を取得
  @override
  Future<MaterialSupplier?> findPreferredSupplier(String materialId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
      QueryConditionBuilder.eq("is_preferred", true),
    ];

    final List<MaterialSupplier> results = await _delegate.find(filters: filters);
    return results.isNotEmpty ? results.first : null;
  }

  /// 材料の優先供給業者を設定
  @override
  Future<void> setPreferredSupplier(String materialId, String supplierId) async {
    // 既存の優先設定を全て解除
    await _clearPreferredSuppliers(materialId);

    // 指定された供給業者を優先に設定
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
      QueryConditionBuilder.eq("supplier_id", supplierId),
    ];

    final List<MaterialSupplier> existing = await _delegate.find(filters: filters);
    if (existing.isNotEmpty) {
      await _delegate.updateById(existing.first.id!, <String, dynamic>{
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

    final List<MaterialSupplier> preferredSuppliers = await _delegate.find(filters: filters);

    // 現在は個別更新を使用（将来的にはバッチ更新で最適化可能）
    for (final MaterialSupplier supplier in preferredSuppliers) {
      await _delegate.updateById(supplier.id!, <String, dynamic>{
        "is_preferred": false,
        "updated_at": DateTime.now().toIso8601String(),
      });
    }
  }

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<MaterialSupplier?> create(MaterialSupplier entity) => _delegate.create(entity);

  @override
  Future<List<MaterialSupplier>> bulkCreate(List<MaterialSupplier> entities) =>
      _delegate.bulkCreate(entities);

  @override
  Future<MaterialSupplier?> getById(String id) => _delegate.getById(id);

  @override
  Future<MaterialSupplier?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<MaterialSupplier?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<MaterialSupplier?> updateByPrimaryKey(
    Map<String, dynamic> keyMap,
    Map<String, dynamic> updates,
  ) => _delegate.updateByPrimaryKey(keyMap, updates);

  @override
  Future<void> deleteById(String id) => _delegate.deleteById(id);

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.deleteByPrimaryKey(keyMap);

  @override
  Future<void> bulkDelete(List<String> keys) => _delegate.bulkDelete(keys);

  @override
  Future<List<MaterialSupplier>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
