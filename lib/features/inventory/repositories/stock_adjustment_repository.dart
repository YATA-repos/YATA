import "../../../core/constants/query_types.dart";
import "../../../data/repositories/base_repository.dart";
import "../models/transaction_model.dart";

class StockAdjustmentRepository extends BaseRepository<StockAdjustment, String> {
  StockAdjustmentRepository() : super(tableName: "stock_adjustments");

  @override
  StockAdjustment fromJson(Map<String, dynamic> json) => StockAdjustment.fromJson(json);

  /// 材料IDで調整履歴を取得
  Future<List<StockAdjustment>> findByMaterialId(String materialId, String userId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
      QueryConditionBuilder.eq("user_id", userId),
    ];

    // 調整日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "adjusted_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 最近の調整履歴を取得
  Future<List<StockAdjustment>> findRecent(int days, String userId) async {
    // 過去N日間の開始日を計算
    final DateTime startDate = DateTime.now().subtract(Duration(days: days));
    final DateTime startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte("adjusted_at", startDateNormalized.toIso8601String()),
    ];

    // 調整日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "adjusted_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }
}
