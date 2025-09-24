import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/inventory/purchase_repository_contract.dart";
import "../models/transaction_model.dart";

class PurchaseRepository implements PurchaseRepositoryContract<Purchase> {
  PurchaseRepository({required repo_contract.CrudRepository<Purchase, String> delegate})
    : _delegate = delegate;

  final repo_contract.CrudRepository<Purchase, String> _delegate;

  /// 最近の仕入れ一覧を取得
  @override
  Future<List<Purchase>> findRecent(int days) async {
    // 過去N日間の開始日を計算
    final DateTime startDate = DateTime.now().subtract(Duration(days: days));
    final DateTime startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.gte("purchase_date", startDateNormalized.toIso8601String()),
    ];

    // 仕入れ日で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "purchase_date", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 期間指定で仕入れ一覧を取得
  @override
  Future<List<Purchase>> findByDateRange(DateTime dateFrom, DateTime dateTo) async {
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
      QueryConditionBuilder.gte("purchase_date", dateFromNormalized.toIso8601String()),
      QueryConditionBuilder.lte("purchase_date", dateToNormalized.toIso8601String()),
    ];

    // 仕入れ日で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "purchase_date", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<Purchase?> create(Purchase entity) => _delegate.create(entity);

  @override
  Future<List<Purchase>> bulkCreate(List<Purchase> entities) => _delegate.bulkCreate(entities);

  @override
  Future<Purchase?> getById(String id) => _delegate.getById(id);

  @override
  Future<Purchase?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<Purchase?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<Purchase?> updateByPrimaryKey(Map<String, dynamic> keyMap, Map<String, dynamic> updates) =>
      _delegate.updateByPrimaryKey(keyMap, updates);

  @override
  Future<void> deleteById(String id) => _delegate.deleteById(id);

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.deleteByPrimaryKey(keyMap);

  @override
  Future<void> bulkDelete(List<String> keys) => _delegate.bulkDelete(keys);

  @override
  Future<List<Purchase>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
