import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/inventory/purchase_repository_contract.dart";
import "../models/transaction_model.dart";

class PurchaseItemRepository implements PurchaseItemRepositoryContract<PurchaseItem> {
  PurchaseItemRepository({required repo_contract.CrudRepository<PurchaseItem, String> delegate})
    : _delegate = delegate;

  final repo_contract.CrudRepository<PurchaseItem, String> _delegate;

  /// 仕入れIDで明細一覧を取得
  @override
  Future<List<PurchaseItem>> findByPurchaseId(String purchaseId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("purchase_id", purchaseId),
    ];

    // 作成順でソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at"),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 仕入れ明細を一括作成
  @override
  Future<List<PurchaseItem>> createBatch(List<PurchaseItem> purchaseItems) async =>
      _delegate.bulkCreate(purchaseItems);

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<PurchaseItem?> create(PurchaseItem entity) => _delegate.create(entity);

  @override
  Future<List<PurchaseItem>> bulkCreate(List<PurchaseItem> entities) =>
      _delegate.bulkCreate(entities);

  @override
  Future<PurchaseItem?> getById(String id) => _delegate.getById(id);

  @override
  Future<PurchaseItem?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<PurchaseItem?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<PurchaseItem?> updateByPrimaryKey(
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
  Future<List<PurchaseItem>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
