import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/order_model.dart";

/// 注文明細リポジトリ
class OrderItemRepository extends BaseRepository<OrderItem, String> {
  /// コンストラクタ
  OrderItemRepository() : super(tableName: "order_items");

  @override
  OrderItem fromJson(Map<String, dynamic> json) => OrderItem.fromJson(json);

  /// 注文IDに紐づく明細一覧を取得
  Future<List<OrderItem>> findByOrderId(String orderId) async {
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.eq("order_id", orderId)];

    // 作成順でソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 注文内の既存アイテムを取得（重複チェック用）
  Future<OrderItem?> findExistingItem(String orderId, String menuItemId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("order_id", orderId),
      QueryConditionBuilder.eq("menu_item_id", menuItemId),
    ];

    final List<OrderItem> results = await find(filters: filters, limit: 1);
    return results.isNotEmpty ? results[0] : null;
  }

  /// 注文IDに紐づく明細を全削除
  Future<bool> deleteByOrderId(String orderId) async {
    try {
      // 対象の明細を取得
      final List<QueryFilter> filters = <QueryFilter>[
        QueryConditionBuilder.eq("order_id", orderId),
      ];
      final List<OrderItem> orderItems = await find(filters: filters);

      if (orderItems.isEmpty) {
        return true; // 削除対象がなければ成功とみなす
      }

      // 一括削除でパフォーマンス向上
      final List<String> itemIds = orderItems
          .where((OrderItem item) => item.id != null)
          .map((OrderItem item) => item.id!)
          .toList();

      if (itemIds.isNotEmpty) {
        await bulkDelete(itemIds);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 期間内の特定メニューアイテムの注文明細を取得
  Future<List<OrderItem>> findByMenuItemAndDateRange(
    String menuItemId,
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

    // 指定メニューアイテムとユーザーでフィルタ
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("menu_item_id", menuItemId),
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

  /// メニューアイテム別売上集計を取得
  Future<List<Map<String, dynamic>>> getMenuItemSalesSummary(int days, String userId) async {
    // 過去N日間の日付範囲を計算
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(Duration(days: days));

    // 日付を正規化
    final DateTime startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime endDateNormalized = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    // ユーザーの全注文明細を取得
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte("created_at", startDateNormalized.toIso8601String()),
      QueryConditionBuilder.lte("created_at", endDateNormalized.toIso8601String()),
    ];

    final List<OrderItem> filteredItems = await find(filters: filters);

    // メニューアイテム別に集計
    final Map<String, Map<String, int>> salesSummary = <String, Map<String, int>>{};

    for (final OrderItem item in filteredItems) {
      final String menuItemId = item.menuItemId;
      salesSummary[menuItemId] ??= <String, int>{"total_quantity": 0, "total_amount": 0};
      salesSummary[menuItemId]!["total_quantity"] =
          salesSummary[menuItemId]!["total_quantity"]! + item.quantity;
      salesSummary[menuItemId]!["total_amount"] =
          salesSummary[menuItemId]!["total_amount"]! + item.subtotal;
    }

    // 結果を辞書のリストに変換
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final MapEntry<String, Map<String, int>> entry in salesSummary.entries) {
      result.add(<String, dynamic>{
        "menu_item_id": entry.key,
        "total_quantity": entry.value["total_quantity"],
        "total_amount": entry.value["total_amount"],
      });
    }

    // 売上金額の降順でソート
    result.sort(
      (Map<String, dynamic> a, Map<String, dynamic> b) =>
          (b["total_amount"] as int).compareTo(a["total_amount"] as int),
    );

    return result;
  }
}
