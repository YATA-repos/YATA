import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../dto/alert_dto.dart";
import "../models/alert_model.dart";

/// アラートリポジトリ
///
/// アラートデータのCRUD操作を提供します。
class AlertRepository extends BaseRepository<AlertModel, String> {
  AlertRepository() : super(tableName: "alerts");

  @override
  AlertModel fromJson(Map<String, dynamic> json) => AlertModel.fromJson(json);

  /// アクティブなアラートを取得
  Future<List<AlertModel>> getActiveAlerts({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("is_active", true),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 未読アラートを取得
  Future<List<AlertModel>> getUnreadAlerts({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("is_active", true),
      QueryConditionBuilder.eq("is_read", false),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 重要度別でアラートを取得
  Future<List<AlertModel>> getAlertsBySeverity(
    AlertSeverity severity, {
    String? userId,
    bool? isActive,
  }) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("severity", severity.name),
      if (isActive != null) QueryConditionBuilder.eq("is_active", isActive),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// タイプ別でアラートを取得
  Future<List<AlertModel>> getAlertsByType(String type, {String? userId, bool? isActive}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("type", type),
      if (isActive != null) QueryConditionBuilder.eq("is_active", isActive),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// フィルター条件でアラートを検索
  Future<List<AlertModel>> searchAlerts(AlertFilterDto filter) async {
    final Map<String, dynamic> queryMap = filter.toQueryMap();
    final List<QueryFilter> filters = <QueryFilter>[];

    queryMap.forEach((String key, dynamic value) {
      if (key.contains(".")) {
        // 範囲条件の処理
        final List<String> parts = key.split(".");
        final String column = parts[0];
        final String operator = parts[1];

        switch (operator) {
          case "gte":
            filters.add(QueryConditionBuilder.gte(column, value));
            break;
          case "lte":
            filters.add(QueryConditionBuilder.lte(column, value));
            break;
          case "gt":
            filters.add(QueryConditionBuilder.gt(column, value));
            break;
          case "lt":
            filters.add(QueryConditionBuilder.lt(column, value));
            break;
        }
      } else {
        // 等価条件
        filters.add(QueryConditionBuilder.eq(key, value));
      }
    });

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// アラートを既読にマーク
  Future<AlertModel?> markAsRead(String alertId) async {
    final Map<String, dynamic> updates = <String, dynamic>{
      "is_read": true,
      "updated_at": DateTime.now().toIso8601String(),
    };

    return updateById(alertId, updates);
  }

  /// 複数アラートを一括既読にマーク
  Future<List<AlertModel>> markMultipleAsRead(List<String> alertIds) async {
    final List<AlertModel> results = <AlertModel>[];

    for (final String alertId in alertIds) {
      final AlertModel? updated = await markAsRead(alertId);
      if (updated != null) {
        results.add(updated);
      }
    }

    return results;
  }

  /// アラートを非アクティブにする
  Future<AlertModel?> deactivateAlert(String alertId) async {
    final Map<String, dynamic> updates = <String, dynamic>{
      "is_active": false,
      "updated_at": DateTime.now().toIso8601String(),
    };

    return updateById(alertId, updates);
  }

  /// 重要度別のアラート数を取得
  Future<Map<AlertSeverity, int>> getAlertCountBySeverity({String? userId}) async {
    final Map<AlertSeverity, int> counts = <AlertSeverity, int>{
      AlertSeverity.info: 0,
      AlertSeverity.warning: 0,
      AlertSeverity.error: 0,
      AlertSeverity.critical: 0,
    };

    for (final AlertSeverity severity in AlertSeverity.values) {
      final List<AlertModel> alerts = await getAlertsBySeverity(
        severity,
        userId: userId,
        isActive: true,
      );
      counts[severity] = alerts.length;
    }

    return counts;
  }

  /// 古いアラートを削除（保持期間を過ぎたもの）
  Future<void> deleteOldAlerts(int retentionDays, {String? userId}) async {
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.lt("created_at", cutoffDate.toIso8601String()),
    ];

    final List<AlertModel> oldAlerts = await find(filters: filters);
    final List<String> oldAlertIds = oldAlerts.map((AlertModel alert) => alert.id!).toList();

    if (oldAlertIds.isNotEmpty) {
      await bulkDelete(oldAlertIds);
    }
  }

  /// 同じタイプの重複アラートを削除
  Future<void> removeDuplicateAlerts(String type, String userId) async {
    final List<AlertModel> existingAlerts = await getAlertsByType(
      type,
      userId: userId,
      isActive: true,
    );

    if (existingAlerts.length > 1) {
      // 最新のものを残して古いものを削除
      final List<AlertModel> duplicates = existingAlerts.sublist(1);
      final List<String> duplicateIds = duplicates.map((AlertModel alert) => alert.id!).toList();
      await bulkDelete(duplicateIds);
    }
  }
}
