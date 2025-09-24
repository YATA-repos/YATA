import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
import "../models/order_model.dart";

/// 注文明細リポジトリ
class OrderItemRepository implements OrderItemRepositoryContract<OrderItem> {
  OrderItemRepository({required repo_contract.CrudRepository<OrderItem, String> delegate})
    : _delegate = delegate;

  final repo_contract.CrudRepository<OrderItem, String> _delegate;

  /// 注文IDに紐づく明細一覧を取得
  @override
  Future<List<OrderItem>> findByOrderId(String orderId) async {
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.eq("order_id", orderId)];

    // 作成順でソート
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at"),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 注文内の既存アイテムを取得（重複チェック用）
  @override
  Future<OrderItem?> findExistingItem(String orderId, String menuItemId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("order_id", orderId),
      QueryConditionBuilder.eq("menu_item_id", menuItemId),
    ];

    final List<OrderItem> results = await _delegate.find(filters: filters, limit: 1);
    return results.isNotEmpty ? results[0] : null;
  }

  /// 注文IDに紐づく明細を全削除
  @override
  Future<bool> deleteByOrderId(String orderId) async {
    try {
      // 対象の明細を取得
      final List<QueryFilter> filters = <QueryFilter>[
        QueryConditionBuilder.eq("order_id", orderId),
      ];
      final List<OrderItem> orderItems = await _delegate.find(filters: filters);

      if (orderItems.isEmpty) {
        return true; // 削除対象がなければ成功とみなす
      }

      // 一括削除でパフォーマンス向上
      final List<String> itemIds = orderItems
          .where((OrderItem item) => item.id != null)
          .map((OrderItem item) => item.id!)
          .toList();

      if (itemIds.isNotEmpty) {
        await _delegate.bulkDelete(itemIds);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 期間内の特定メニューアイテムの注文明細を取得
  @override
  Future<List<OrderItem>> findByMenuItemAndDateRange(
    String menuItemId,
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

    // 指定メニューアイテムでフィルタ
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("menu_item_id", menuItemId),
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
  @override
  Future<List<Map<String, dynamic>>> getMenuItemSalesSummary(int days) async {
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

    // 全注文明細を取得
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.gte("created_at", startDateNormalized.toIso8601String()),
      QueryConditionBuilder.lte("created_at", endDateNormalized.toIso8601String()),
    ];

    final List<OrderItem> filteredItems = await _delegate.find(filters: filters);

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

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<OrderItem?> create(OrderItem entity) => _delegate.create(entity);

  @override
  Future<List<OrderItem>> bulkCreate(List<OrderItem> entities) => _delegate.bulkCreate(entities);

  @override
  Future<OrderItem?> getById(String id) => _delegate.getById(id);

  @override
  Future<OrderItem?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<OrderItem?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<OrderItem?> updateByPrimaryKey(
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
  Future<List<OrderItem>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
