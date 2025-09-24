import "../../../core/constants/enums.dart";
import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/inventory/stock_transaction_repository_contract.dart";
import "../models/transaction_model.dart";

class StockTransactionRepository implements StockTransactionRepositoryContract<StockTransaction> {
  StockTransactionRepository({
    required repo_contract.CrudRepository<StockTransaction, String> delegate,
  }) : _delegate = delegate;

  final repo_contract.CrudRepository<StockTransaction, String> _delegate;

  /// 在庫取引を一括作成
  @override
  Future<List<StockTransaction>> createBatch(List<StockTransaction> transactions) async =>
      _delegate.bulkCreate(transactions);

  /// 参照タイプ・IDで取引履歴を取得
  @override
  Future<List<StockTransaction>> findByReference(
    ReferenceType referenceType,
    String referenceId,
  ) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("reference_type", referenceType.value),
      QueryConditionBuilder.eq("reference_id", referenceId),
    ];

    // 作成日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 材料IDと期間で取引履歴を取得
  @override
  Future<List<StockTransaction>> findByMaterialAndDateRange(
    String materialId,
    DateTime dateFrom,
    DateTime dateTo,
  ) async {
    // 日付を正規化
    final DateTime dateFromNormalized = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
    final DateTime dateToNormalized = DateTime(
      dateTo.year,
      dateTo.month,
      dateTo.day,
      23,
      59,
      59,
      999,
    );

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
      QueryConditionBuilder.gte("created_at", dateFromNormalized.toIso8601String()),
      QueryConditionBuilder.lte("created_at", dateToNormalized.toIso8601String()),
    ];

    // 作成日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 期間内の消費取引（負の値）を取得
  @override
  Future<List<StockTransaction>> findConsumptionTransactions(
    DateTime dateFrom,
    DateTime dateTo,
  ) async {
    // 日付を正規化
    final DateTime dateFromNormalized = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
    final DateTime dateToNormalized = DateTime(
      dateTo.year,
      dateTo.month,
      dateTo.day,
      23,
      59,
      59,
      999,
    );

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.gte("created_at", dateFromNormalized.toIso8601String()),
      QueryConditionBuilder.lte("created_at", dateToNormalized.toIso8601String()),
      QueryConditionBuilder.lt("change_amount", 0),
    ];

    // 作成日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<StockTransaction?> create(StockTransaction entity) => _delegate.create(entity);

  @override
  Future<List<StockTransaction>> bulkCreate(List<StockTransaction> entities) =>
      _delegate.bulkCreate(entities);

  @override
  Future<StockTransaction?> getById(String id) => _delegate.getById(id);

  @override
  Future<StockTransaction?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<StockTransaction?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<StockTransaction?> updateByPrimaryKey(
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
  Future<List<StockTransaction>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
