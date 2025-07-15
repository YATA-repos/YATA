import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/dashboard_stats_model.dart";

/// ダッシュボード統計リポジトリ
///
/// ダッシュボード統計データのCRUD操作を提供します。
class DashboardRepository extends BaseRepository<DashboardStatsModel, String> {
  DashboardRepository() : super(tableName: "dashboard_stats");

  @override
  DashboardStatsModel fromJson(Map<String, dynamic> json) => DashboardStatsModel.fromJson(json);

  /// 今日の統計を取得
  Future<DashboardStatsModel?> getTodayStats({String? userId}) async {
    final DateTime today = DateTime.now();
    final DateTime todayStart = DateTime(today.year, today.month, today.day);

    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte("date", todayStart.toIso8601String()),
      QueryConditionBuilder.lt("date", todayStart.add(const Duration(days: 1)).toIso8601String()),
    ];

    final List<DashboardStatsModel> results = await find(filters: filters, limit: 1);
    return results.isNotEmpty ? results[0] : null;
  }

  /// 指定日の統計を取得
  Future<DashboardStatsModel?> getStatsByDate(DateTime date, {String? userId}) async {
    final DateTime dateStart = DateTime(date.year, date.month, date.day);

    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte("date", dateStart.toIso8601String()),
      QueryConditionBuilder.lt("date", dateStart.add(const Duration(days: 1)).toIso8601String()),
    ];

    final List<DashboardStatsModel> results = await find(filters: filters, limit: 1);
    return results.isNotEmpty ? results[0] : null;
  }

  /// 統計を作成または更新（Upsert）
  Future<DashboardStatsModel> upsertStats(DashboardStatsModel stats) async {
    final DashboardStatsModel? existing = await getTodayStats(userId: stats.userId);

    if (existing != null) {
      // 更新
      final Map<String, dynamic> updates = stats
          .copyWith(id: existing.id, updatedAt: DateTime.now())
          .toJson();

      final DashboardStatsModel? updated = await updateById(existing.id!, updates);
      return updated ?? stats;
    } else {
      // 新規作成
      final DashboardStatsModel? created = await create(
        stats.copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      return created ?? stats;
    }
  }

  /// 期間指定で統計一覧を取得
  Future<List<DashboardStatsModel>> getStatsByDateRange(
    DateTime dateFrom,
    DateTime dateTo, {
    String? userId,
  }) async {
    final DateTime dateFromStart = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
    final DateTime dateToEnd = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);

    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte("date", dateFromStart.toIso8601String()),
      QueryConditionBuilder.lte("date", dateToEnd.toIso8601String()),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "date", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// ユーザーの最新統計を取得
  Future<DashboardStatsModel?> getLatestStats({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    final List<DashboardStatsModel> results = await find(
      filters: filters,
      orderBy: orderBy,
      limit: 1,
    );

    return results.isNotEmpty ? results[0] : null;
  }

  /// 古い統計データを削除（保持期間を過ぎたもの）
  Future<void> deleteOldStats(int retentionDays, {String? userId}) async {
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.lt("date", cutoffDate.toIso8601String()),
    ];

    final List<DashboardStatsModel> oldStats = await find(filters: filters);
    final List<String> oldStatsIds = oldStats.map((DashboardStatsModel stat) => stat.id!).toList();

    if (oldStatsIds.isNotEmpty) {
      await bulkDelete(oldStatsIds);
    }
  }
}
