import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/inventory/stock_adjustment_repository_contract.dart";
import "../models/transaction_model.dart";

class StockAdjustmentRepository implements StockAdjustmentRepositoryContract<StockAdjustment> {
  StockAdjustmentRepository({
    required repo_contract.CrudRepository<StockAdjustment, String> delegate,
  }) : _delegate = delegate;

  final repo_contract.CrudRepository<StockAdjustment, String> _delegate;

  /// 材料IDで調整履歴を取得
  @override
  Future<List<StockAdjustment>> findByMaterialId(String materialId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
    ];

    // 調整日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "adjusted_at", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 最近の調整履歴を取得
  @override
  Future<List<StockAdjustment>> findRecent(int days) async {
    // 過去N日間の開始日を計算
    final DateTime startDate = DateTime.now().subtract(Duration(days: days));
    final DateTime startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.gte("adjusted_at", startDateNormalized.toIso8601String()),
    ];

    // 調整日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "adjusted_at", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<StockAdjustment?> create(StockAdjustment entity) => _delegate.create(entity);

  @override
  Future<List<StockAdjustment>> bulkCreate(List<StockAdjustment> entities) =>
      _delegate.bulkCreate(entities);

  @override
  Future<StockAdjustment?> getById(String id) => _delegate.getById(id);

  @override
  Future<StockAdjustment?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<StockAdjustment?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<StockAdjustment?> updateByPrimaryKey(
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
  Future<List<StockAdjustment>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
