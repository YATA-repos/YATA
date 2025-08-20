import "../../../core/constants/enums.dart";
import "../../../core/constants/query_types.dart";
import "../../../data/repositories/base_repository.dart";
import "../models/order_model.dart";

/// 注文リポジトリ
class OrderRepository extends BaseRepository<Order, String> {
  OrderRepository({required super.ref}) : super(tableName: "orders", enableMultiTenant: true);

  @override
  Order fromJson(Map<String, dynamic> json) => Order.fromJson(json);

  /// ユーザーのアクティブな下書き注文（カート）を取得
  Future<Order?> findActiveDraftByUser() async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("status", OrderStatus.preparing.value),
    ];

    // 最新のものを取得
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    final List<Order> results = await find(filters: filters, orderBy: orderBy, limit: 1);
    return results.isNotEmpty ? results[0] : null;
  }

  /// 指定ステータスリストの注文一覧を取得
  Future<List<Order>> findByStatusList(List<OrderStatus> statusList) async {
    if (statusList.isEmpty) {
      return <Order>[];
    }

    final List<String> statusValues = statusList.map((OrderStatus status) => status.value).toList();

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.inList("status", statusValues),
    ];

    // 注文日時で降順
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "ordered_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 注文を検索（戻り値: (注文一覧, 総件数)）
  Future<(List<Order>, int)> searchWithPagination(
    List<QueryFilter> filters,
    int page,
    int limit,
  ) async {
    // 総件数を取得
    final int totalCount = await count(filters: filters);

    // ページネーション計算
    final int offset = (page - 1) * limit;

    // 注文日時で降順
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "ordered_at", ascending: false),
    ];

    // データを取得
    final List<Order> orders = await find(
      filters: filters,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return (orders, totalCount);
  }

  /// 期間指定で注文一覧を取得
  Future<List<Order>> findByDateRange(DateTime dateFrom, DateTime dateTo) async {
    // 日付を正規化（日の開始と終了時刻に設定）
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
      QueryConditionBuilder.gte("ordered_at", dateFromNormalized.toIso8601String()),
      QueryConditionBuilder.lte("ordered_at", dateToNormalized.toIso8601String()),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "ordered_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 指定日の完了注文を取得
  Future<List<Order>> findCompletedByDate(DateTime targetDate) async {
    // 日付を正規化（日の開始と終了時刻に設定）
    final DateTime dateStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final DateTime dateEnd = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      23,
      59,
      59,
      999,
    );

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("status", OrderStatus.completed.value),
      QueryConditionBuilder.gte("completed_at", dateStart.toIso8601String()),
      QueryConditionBuilder.lte("completed_at", dateEnd.toIso8601String()),
    ];

    // 完了日時で降順
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "completed_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 指定日のステータス別注文数を取得
  Future<Map<OrderStatus, int>> countByStatusAndDate(DateTime targetDate) async {
    // 日付を正規化（日の開始と終了時刻に設定）
    final DateTime dateStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final DateTime dateEnd = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      23,
      59,
      59,
      999,
    );

    // 指定日のユーザー注文を取得
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.gte("ordered_at", dateStart.toIso8601String()),
      QueryConditionBuilder.lte("ordered_at", dateEnd.toIso8601String()),
    ];

    final List<Order> targetDateOrders = await find(filters: filters);

    // ステータス別に集計
    final Map<OrderStatus, int> statusCounts = <OrderStatus, int>{
      for (final OrderStatus status in OrderStatus.values) status: 0,
    };

    for (final Order order in targetDateOrders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }

    return statusCounts;
  }

  /// 次の注文番号を生成
  Future<String> generateNextOrderNumber() async {
    // 今日の日付を取得
    final DateTime today = DateTime.now();
    final String todayPrefix =
        "${today.year.toString().padLeft(4, '0')}"
        "${today.month.toString().padLeft(2, '0')}"
        "${today.day.toString().padLeft(2, '0')}";

    // 今日のユーザー注文を取得
    final DateTime todayStart = DateTime(today.year, today.month, today.day);
    final DateTime todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.gte("ordered_at", todayStart.toIso8601String()),
      QueryConditionBuilder.lte("ordered_at", todayEnd.toIso8601String()),
    ];

    final List<Order> todayOrders = await find(filters: filters);

    // 今日の注文数を基に次の番号を生成
    final int nextNumber = todayOrders.length + 1;

    return "$todayPrefix-${nextNumber.toString().padLeft(3, '0')}";
  }

  /// 完了時間範囲で注文を取得（調理時間分析用）
  Future<List<Order>> findOrdersByCompletionTimeRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("status", OrderStatus.completed.value),
      QueryConditionBuilder.gte("completed_at", startTime.toIso8601String()),
      QueryConditionBuilder.lte("completed_at", endTime.toIso8601String()),
    ];

    // 完了時間で昇順ソート（分析用）
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "completed_at"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// アクティブな注文を取得
  Future<List<Order>> findActiveOrders() async {
    final List<OrderStatus> activeStatuses = <OrderStatus>[
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
    ];

    return findByStatusList(activeStatuses);
  }

  /// 最近の注文を取得
  Future<List<Order>> findRecentOrders({int limit = 10}) async {
    // 注文日時で降順
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "ordered_at", ascending: false),
    ];

    return find(orderBy: orderBy, limit: limit);
  }

  /// 期間指定で完了注文を取得
  Future<List<Order>> findCompletedByDateRange(DateTime start, DateTime end) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("status", OrderStatus.completed.value),
      QueryConditionBuilder.gte("completed_at", start.toIso8601String()),
      QueryConditionBuilder.lte("completed_at", end.toIso8601String()),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "completed_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 期間とステータス別の注文数を取得
  Future<Map<OrderStatus, Map<DateTime, int>>> countByStatusAndDateRange(
    DateTime start, 
    DateTime end,
  ) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.gte("ordered_at", start.toIso8601String()),
      QueryConditionBuilder.lte("ordered_at", end.toIso8601String()),
    ];

    final List<Order> orders = await find(filters: filters);

    // ステータス別・日別に集計
    final Map<OrderStatus, Map<DateTime, int>> result = <OrderStatus, Map<DateTime, int>>{};
    
    for (final Order order in orders) {
      final DateTime orderDate = DateTime(
        order.orderedAt.year,
        order.orderedAt.month,
        order.orderedAt.day,
      );
      
      result[order.status] ??= <DateTime, int>{};
      result[order.status]![orderDate] = (result[order.status]![orderDate] ?? 0) + 1;
    }

    return result;
  }

  /// アクティブ注文をステータス別に取得
  Future<Map<OrderStatus, List<Order>>> getActiveOrdersByStatus() async {
    final List<OrderStatus> activeStatuses = <OrderStatus>[
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
    ];

    final List<Order> activeOrders = await findByStatusList(activeStatuses);
    
    // ステータス別にグループ化
    final Map<OrderStatus, List<Order>> result = <OrderStatus, List<Order>>{};
    
    for (final OrderStatus status in activeStatuses) {
      result[status] = activeOrders
          .where((Order order) => order.status == status)
          .toList();
    }

    return result;
  }
}
