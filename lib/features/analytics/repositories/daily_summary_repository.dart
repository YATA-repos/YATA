import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/analytics/daily_summary_repository_contract.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../models/analytics_model.dart";

class DailySummaryRepository implements DailySummaryRepositoryContract<DailySummary> {
  DailySummaryRepository({required repo_contract.CrudRepository<DailySummary, String> delegate})
    : _delegate = delegate;

  final repo_contract.CrudRepository<DailySummary, String> _delegate;

  /// 指定日の集計を取得
  @override
  Future<DailySummary?> findByDate(DateTime targetDate) async {
    // 日付を日の開始時刻に正規化（h,m,sをゼロに）
    final DateTime targetDateNormalized = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // 日付でフィルタ
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("summary_date", targetDateNormalized.toIso8601String()),
    ];

    final List<DailySummary> results = await _delegate.find(filters: filters, limit: 1);
    return results.isNotEmpty ? results[0] : null;
  }

  /// 期間指定で集計一覧を取得
  @override
  Future<List<DailySummary>> findByDateRange(DateTime dateFrom, DateTime dateTo) async {
    // 開始日を日の開始時刻に、終了日を日の終了時刻に正規化
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

    // 日付範囲でフィルタ
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.gte("summary_date", dateFromNormalized.toIso8601String()),
      QueryConditionBuilder.lte("summary_date", dateToNormalized.toIso8601String()),
    ];

    // 日付順でソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "summary_date"),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<DailySummary?> create(DailySummary entity) => _delegate.create(entity);

  @override
  Future<List<DailySummary>> bulkCreate(List<DailySummary> entities) =>
      _delegate.bulkCreate(entities);

  @override
  Future<DailySummary?> getById(String id) => _delegate.getById(id);

  @override
  Future<DailySummary?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<DailySummary?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<DailySummary?> updateByPrimaryKey(
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
  Future<List<DailySummary>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
