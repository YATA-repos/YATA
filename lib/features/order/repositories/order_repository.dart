import "../../../core/constants/enums.dart";
import "../../../core/constants/exceptions/repository/repository_exception.dart";
import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
import "../../../core/logging/compat.dart" as log;
import "../../../shared/utils/order_identifier_generator.dart";
import "../models/order_model.dart";
import "../shared/order_status_mapper.dart";

/// 注文リポジトリ
class OrderRepository implements OrderRepositoryContract<Order> {
  OrderRepository({
    required repo_contract.CrudRepository<Order, String> delegate,
    OrderIdentifierGenerator? identifierGenerator,
  })  : _delegate = delegate,
        _identifierGenerator = identifierGenerator ?? OrderIdentifierGenerator();

  final repo_contract.CrudRepository<Order, String> _delegate;
  final OrderIdentifierGenerator _identifierGenerator;

  /// ユーザーのアクティブな下書き注文（カート）を取得
  @override
  Future<Order?> findActiveDraftByUser(String userId) async {
    Future<Order?> runQuery(List<String> statusValues) async {
      final List<QueryFilter> filters = <QueryFilter>[
        QueryConditionBuilder.eq("user_id", userId),
        QueryConditionBuilder.eq("is_cart", true),
        QueryConditionBuilder.inList("status", statusValues),
        QueryConditionBuilder.or(<QueryFilter>[
          QueryConditionBuilder.eq("total_amount", 0),
          QueryConditionBuilder.isNull("total_amount"),
        ]),
        QueryConditionBuilder.isNull("order_number"),
      ];

      // 最新のものを取得
      final List<OrderByCondition> orderBy = <OrderByCondition>[
        const OrderByCondition(column: "created_at", ascending: false),
      ];

      final List<Order> results = await _delegate.find(
        filters: filters,
        orderBy: orderBy,
        limit: 1,
      );
      return results.isNotEmpty ? results[0] : null;
    }

    final List<String> primaryStatusValues = OrderStatusMapper.queryValues(OrderStatus.inProgress);

    try {
      return await runQuery(primaryStatusValues);
    } on RepositoryException catch (error, stackTrace) {
      final String? unsupportedValue = _extractUnsupportedOrderStatusValue(error);
      if (unsupportedValue != null) {
        OrderStatusMapper.markBackendValueUnsupported(unsupportedValue);
        final List<String> fallbackValues = OrderStatusMapper.queryValues(OrderStatus.inProgress);

        if (_didStatusValuesChange(primaryStatusValues, fallbackValues)) {
          log.w(
            "order_status_enum が '$unsupportedValue' を受け付けなかったため、レガシー値で再試行します",
            tag: "OrderRepository",
            fields: <String, Object?>{
              "userId": userId,
              "unsupportedValue": unsupportedValue,
              "fallbackStatuses": fallbackValues,
              "originalError": error.params["error"],
              "stackTrace": stackTrace.toString(),
            },
          );
          return runQuery(fallbackValues);
        }
      }
      rethrow;
    }
  }

  /// 指定ステータスリストの注文一覧を取得
  @override
  Future<List<Order>> findByStatusList(List<OrderStatus> statusList) async {
    if (statusList.isEmpty) {
      return <Order>[];
    }

    Future<List<Order>> runQuery(List<String> values) async {
      final List<QueryFilter> filters = <QueryFilter>[
        QueryConditionBuilder.eq("is_cart", false),
        QueryConditionBuilder.inList("status", values),
      ];

      // 注文日時で降順
      final List<OrderByCondition> orderBy = <OrderByCondition>[
        const OrderByCondition(column: "ordered_at", ascending: false),
      ];

      return _delegate.find(filters: filters, orderBy: orderBy);
    }

    final List<String> primaryStatusValues = OrderStatusMapper.queryValuesFromList(statusList);

    try {
      return await runQuery(primaryStatusValues);
    } on RepositoryException catch (error, stackTrace) {
      final String? unsupportedValue = _extractUnsupportedOrderStatusValue(error);
      if (unsupportedValue != null) {
        OrderStatusMapper.markBackendValueUnsupported(unsupportedValue);
        final List<String> fallbackValues = OrderStatusMapper.queryValuesFromList(statusList);

        if (_didStatusValuesChange(primaryStatusValues, fallbackValues)) {
          log.w(
            "order_status_enum が '$unsupportedValue' を受け付けないため、互換モードで再取得します",
            tag: "OrderRepository",
            fields: <String, Object?>{
              "statusList": statusList.map((OrderStatus status) => status.value).toList(),
              "unsupportedValue": unsupportedValue,
              "fallbackStatuses": fallbackValues,
              "originalError": error.params["error"],
              "stackTrace": stackTrace.toString(),
            },
          );
          return runQuery(fallbackValues);
        }
      }
      rethrow;
    }
  }

  /// 注文を検索（戻り値: (注文一覧, 総件数)）
  @override
  Future<(List<Order>, int)> searchWithPagination(
    List<QueryFilter> filters,
    int page,
    int limit,
  ) async {
    final List<QueryFilter> effectiveFilters = <QueryFilter>[...filters, QueryConditionBuilder.eq("is_cart", false)];
    // 総件数を取得
    final int totalCount = await _delegate.count(filters: effectiveFilters);

    // ページネーション計算
    final int offset = (page - 1) * limit;

    // 注文日時で降順
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "ordered_at", ascending: false),
    ];

    // データを取得
    final List<Order> orders = await _delegate.find(
      filters: effectiveFilters,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return (orders, totalCount);
  }

  /// 期間指定で注文一覧を取得
  @override
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
      QueryConditionBuilder.eq("is_cart", false),
      QueryConditionBuilder.gte("ordered_at", dateFromNormalized.toIso8601String()),
      QueryConditionBuilder.lte("ordered_at", dateToNormalized.toIso8601String()),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "ordered_at", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 指定日の完了注文を取得
  @override
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
      QueryConditionBuilder.eq("is_cart", false),
      QueryConditionBuilder.eq("status", OrderStatus.completed.value),
      QueryConditionBuilder.gte("completed_at", dateStart.toIso8601String()),
      QueryConditionBuilder.lte("completed_at", dateEnd.toIso8601String()),
    ];

    // 完了日時で降順
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "completed_at", ascending: false),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
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
      QueryConditionBuilder.eq("is_cart", false),
      QueryConditionBuilder.gte("ordered_at", dateStart.toIso8601String()),
      QueryConditionBuilder.lte("ordered_at", dateEnd.toIso8601String()),
    ];

    final List<Order> targetDateOrders = await _delegate.find(filters: filters);

    // ステータス別に集計
    final Map<OrderStatus, int> statusCounts = <OrderStatus, int>{
      for (final OrderStatus status in OrderStatus.primaryStatuses) status: 0,
    };

    for (final Order order in targetDateOrders) {
      final OrderStatus normalizedStatus = OrderStatusMapper.normalize(order.status);
      statusCounts[normalizedStatus] = (statusCounts[normalizedStatus] ?? 0) + 1;
    }

    return statusCounts;
  }

  /// 次の注文番号を生成
  @override
  Future<String> generateNextOrderNumber() async {
    const int maxAttempts = 5;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final String candidate = _identifierGenerator.generateOrderNumber();

      try {
        final List<Order> existingOrders = await _delegate.find(
          filters: <QueryFilter>[QueryConditionBuilder.eq("order_number", candidate)],
          limit: 1,
        );

        if (existingOrders.isEmpty) {
          log.d(
            "Generated next order number using timestamp+slug strategy",
            tag: "OrderRepository",
            fields: <String, Object?>{
              "orderNumber": candidate,
              "attempt": attempt + 1,
            },
          );
          return candidate;
        }

        log.w(
          "Order number collision detected, regenerating",
          tag: "OrderRepository",
          fields: <String, Object?>{
            "orderNumber": candidate,
            "attempt": attempt + 1,
          },
        );
      } catch (error, stackTrace) {
        log.e(
          "Failed to verify order number uniqueness",
          tag: "OrderRepository",
          error: error,
          st: stackTrace,
          fields: <String, Object?>{
            "orderNumber": candidate,
            "attempt": attempt + 1,
          },
        );
        rethrow;
      }
    }

    final Exception generationError =
        Exception("Failed to generate a unique order number after $maxAttempts attempts");
    log.e(
      "Failed to generate a unique order number",
      tag: "OrderRepository",
      error: generationError,
      fields: <String, Object?>{"maxAttempts": maxAttempts},
    );
    throw generationError;
  }

  /// 完了時間範囲で注文を取得（調理時間分析用）
  @override
  Future<List<Order>> findOrdersByCompletionTimeRange(DateTime startTime, DateTime endTime) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("is_cart", false),
      QueryConditionBuilder.eq("status", OrderStatus.completed.value),
      QueryConditionBuilder.gte("completed_at", startTime.toIso8601String()),
      QueryConditionBuilder.lte("completed_at", endTime.toIso8601String()),
    ];

    // 完了時間で昇順ソート（分析用）
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "completed_at"),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// アクティブな注文を取得
  @override
  Future<List<Order>> findActiveOrders() =>
      findByStatusList(const <OrderStatus>[OrderStatus.inProgress]);

  /// 最近の注文を取得
  @override
  Future<List<Order>> findRecentOrders({int limit = 10}) async {
    // 注文日時で降順
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "ordered_at", ascending: false),
    ];

    return find(
      filters: <QueryFilter>[QueryConditionBuilder.eq("is_cart", false)],
      orderBy: orderBy,
      limit: limit,
    );
  }

  /// 期間指定で完了注文を取得
  @override
  Future<List<Order>> findCompletedByDateRange(DateTime start, DateTime end) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("is_cart", false),
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
  @override
  Future<Map<OrderStatus, Map<DateTime, int>>> countByStatusAndDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("is_cart", false),
      QueryConditionBuilder.gte("ordered_at", start.toIso8601String()),
      QueryConditionBuilder.lte("ordered_at", end.toIso8601String()),
    ];

    final List<Order> orders = await _delegate.find(filters: filters);

    // ステータス別・日別に集計
    final Map<OrderStatus, Map<DateTime, int>> result = <OrderStatus, Map<DateTime, int>>{
      for (final OrderStatus status in OrderStatus.primaryStatuses) status: <DateTime, int>{},
    };

    for (final Order order in orders) {
      final DateTime orderDate = DateTime(
        order.orderedAt.year,
        order.orderedAt.month,
        order.orderedAt.day,
      );

      final OrderStatus normalizedStatus = OrderStatusMapper.normalize(order.status);
      final Map<DateTime, int> dateMap = result[normalizedStatus] ??= <DateTime, int>{};
      dateMap[orderDate] = (dateMap[orderDate] ?? 0) + 1;
    }

    return result;
  }

  /// アクティブ注文をステータス別に取得
  @override
  Future<Map<OrderStatus, List<Order>>> getActiveOrdersByStatus() async {
    final List<OrderStatus> statuses = OrderStatus.primaryStatuses;
    final List<Order> orders = await findByStatusList(statuses);

    // ステータス別にグループ化
    final Map<OrderStatus, List<Order>> result = <OrderStatus, List<Order>>{
      for (final OrderStatus status in statuses) status: <Order>[],
    };

    for (final Order order in orders) {
      final OrderStatus normalizedStatus = OrderStatusMapper.normalize(order.status);
      result[normalizedStatus]!.add(order);
    }

    return result;
  }

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<Order?> create(Order entity) => _delegate.create(entity);

  @override
  Future<List<Order>> bulkCreate(List<Order> entities) => _delegate.bulkCreate(entities);

  @override
  Future<Order?> getById(String id) => _delegate.getById(id);

  @override
  Future<Order?> getByPrimaryKey(Map<String, dynamic> keyMap) => _delegate.getByPrimaryKey(keyMap);

  @override
  Future<Order?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<Order?> updateByPrimaryKey(Map<String, dynamic> keyMap, Map<String, dynamic> updates) =>
      _delegate.updateByPrimaryKey(keyMap, updates);

  @override
  Future<void> deleteById(String id) => _delegate.deleteById(id);

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.deleteByPrimaryKey(keyMap);

  @override
  Future<void> bulkDelete(List<String> keys) => _delegate.bulkDelete(keys);

  @override
  Future<List<Order>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}

/// Supabase/Postgrest が返した `order_status_enum` の無効値を抽出する。
///
/// エラーメッセージから最初に検出された値を返し、該当しなければ `null` を返す。
String? _extractUnsupportedOrderStatusValue(RepositoryException error) {
  final String? raw = error.params["error"];
  if (raw == null) {
    return null;
  }
  final Match? match = _orderStatusInvalidEnumRegex.firstMatch(raw);
  return match?.group(1)?.trim();
}

final RegExp _orderStatusInvalidEnumRegex = RegExp(
  r'invalid input value for enum [\w.]+:\s*"([^"]+)"',
  caseSensitive: false,
);

bool _didStatusValuesChange(List<String> original, List<String> next) {
  if (original.length != next.length) {
    return true;
  }
  final Set<String> originalSet = original.map((String value) => value.toLowerCase()).toSet();
  final Set<String> nextSet = next.map((String value) => value.toLowerCase()).toSet();
  if (originalSet.length != nextSet.length) {
    return true;
  }
  return !originalSet.containsAll(nextSet);
}
