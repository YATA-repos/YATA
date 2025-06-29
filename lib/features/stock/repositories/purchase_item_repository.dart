import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/stock_model.dart";

/// 仕入れ明細リポジトリ
class PurchaseItemRepository extends BaseRepository<PurchaseItem, String> {
  /// コンストラクタ
  PurchaseItemRepository() : super(tableName: "purchase_items");

  @override
  PurchaseItem Function(Map<String, dynamic> json) get fromJson => PurchaseItem.fromJson;

  /// 仕入れIDで明細一覧を取得
  Future<List<PurchaseItem>> findByPurchaseId(String purchaseId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("purchase_id", purchaseId),
    ];

    // 作成順でソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 仕入れ明細を一括作成
  Future<List<PurchaseItem>> createBatch(List<PurchaseItem> purchaseItems) async =>
      bulkCreate(purchaseItems);
}
