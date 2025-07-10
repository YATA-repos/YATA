import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/analytics_model.dart";

class DailySummaryRepository extends BaseRepository<DailySummary, String> {
  DailySummaryRepository() : super(tableName: "daily_summaries");

  @override
  DailySummary fromJson(Map<String, dynamic> json) => DailySummary.fromJson(json);

  /// 指定日の集計を取得
  Future<DailySummary?> findByDate(DateTime targetDate, String userId) async {
    // 日付を日の開始時刻に正規化（h,m,sをゼロに）
    final DateTime targetDateNormalized = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // ユーザーIDと日付でフィルタ
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("summary_date", targetDateNormalized.toIso8601String()),
    ];

    final List<DailySummary> results = await find(filters: filters, limit: 1);
    return results.isNotEmpty ? results[0] : null;
  }

  /// 期間指定で集計一覧を取得
  Future<List<DailySummary>> findByDateRange(
    DateTime dateFrom,
    DateTime dateTo,
    String userId,
  ) async {
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

    // ユーザーIDと日付範囲でフィルタ
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte("summary_date", dateFromNormalized.toIso8601String()),
      QueryConditionBuilder.lte("summary_date", dateToNormalized.toIso8601String()),
    ];

    // 日付順でソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "summary_date"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }
}
