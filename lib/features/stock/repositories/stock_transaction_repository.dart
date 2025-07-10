import "../../../core/base/base_repository.dart";
import "../../../core/constants/enums.dart";
import "../../../core/constants/query_types.dart";
import "../models/stock_model.dart";

/// 在庫取引リポジトリ
class StockTransactionRepository extends BaseRepository<StockTransaction, String> {
  /// コンストラクタ
  StockTransactionRepository() : super(tableName: "stock_transactions");

  @override
  StockTransaction fromJson(Map<String, dynamic> json) => StockTransaction.fromJson(json);

  /// 在庫取引を一括作成
  Future<List<StockTransaction>> createBatch(List<StockTransaction> transactions) async =>
      bulkCreate(transactions);

  /// 参照タイプ・IDで取引履歴を取得
  Future<List<StockTransaction>> findByReference(
    ReferenceType referenceType,
    String referenceId,
    String userId,
  ) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("reference_type", referenceType.value),
      QueryConditionBuilder.eq("reference_id", referenceId),
      QueryConditionBuilder.eq("user_id", userId),
    ];

    // 作成日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 材料IDと期間で取引履歴を取得
  Future<List<StockTransaction>> findByMaterialAndDateRange(
    String materialId,
    DateTime dateFrom,
    DateTime dateTo,
    String userId,
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
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte("created_at", dateFromNormalized.toIso8601String()),
      QueryConditionBuilder.lte("created_at", dateToNormalized.toIso8601String()),
    ];

    // 作成日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 期間内の消費取引（負の値）を取得
  Future<List<StockTransaction>> findConsumptionTransactions(
    DateTime dateFrom,
    DateTime dateTo,
    String userId,
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
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte("created_at", dateFromNormalized.toIso8601String()),
      QueryConditionBuilder.lte("created_at", dateToNormalized.toIso8601String()),
      QueryConditionBuilder.lt("change_amount", 0),
    ];

    // 作成日時で降順ソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }
}
