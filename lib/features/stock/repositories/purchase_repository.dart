import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/stock_model.dart";

/// 仕入れリポジトリ
class PurchaseRepository extends BaseRepository<Purchase, String> {
  /// コンストラクタ
  PurchaseRepository() : super(tableName: "purchases");

  @override
  Purchase Function(Map<String, dynamic> json) get fromJson =>
      Purchase.fromJson;

  /// 最近の仕入れ一覧を取得
  Future<List<Purchase>> findRecent(int days, String userId) async {
    // 過去N日間の開始日を計算
    final DateTime startDate = DateTime.now().subtract(Duration(days: days));
    final DateTime startDateNormalized = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte(
        "purchase_date",
        startDateNormalized.toIso8601String(),
      ),
    ];

    // 仕入れ日で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "purchase_date", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 期間指定で仕入れ一覧を取得
  Future<List<Purchase>> findByDateRange(
    DateTime dateFrom,
    DateTime dateTo,
    String userId,
  ) async {
    // 日付を正規化
    final DateTime dateFromNormalized = DateTime(
      dateFrom.year,
      dateFrom.month,
      dateFrom.day,
    );
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
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte(
        "purchase_date",
        dateFromNormalized.toIso8601String(),
      ),
      QueryConditionBuilder.lte(
        "purchase_date",
        dateToNormalized.toIso8601String(),
      ),
    ];

    // 仕入れ日で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "purchase_date", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }
}
