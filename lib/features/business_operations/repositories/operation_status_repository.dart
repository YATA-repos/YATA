import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../dto/operation_status_dto.dart";
import "../models/operation_status_model.dart";

/// 営業状態リポジトリ
///
/// 営業状態データのCRUD操作を提供します。
class OperationStatusRepository extends BaseRepository<OperationStatusModel, String> {
  OperationStatusRepository() : super(tableName: "operation_status");

  @override
  OperationStatusModel fromJson(Map<String, dynamic> json) => OperationStatusModel.fromJson(json);

  /// 現在の営業状態を取得
  Future<OperationStatusModel?> getCurrentOperationStatus({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "updated_at", ascending: false),
    ];

    final List<OperationStatusModel> results = await find(
      filters: filters,
      orderBy: orderBy,
      limit: 1,
    );

    return results.isNotEmpty ? results[0] : null;
  }

  /// 営業状態を作成または更新（Upsert）
  Future<OperationStatusModel> upsertOperationStatus(OperationStatusModel status) async {
    final OperationStatusModel? existing = await getCurrentOperationStatus(userId: status.userId);

    if (existing != null) {
      // 更新
      final Map<String, dynamic> updates = status
          .copyWith(id: existing.id, updatedAt: DateTime.now())
          .toJson();

      final OperationStatusModel? updated = await updateById(existing.id!, updates);
      return updated ?? status;
    } else {
      // 新規作成
      final OperationStatusModel? created = await create(
        status.copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      return created ?? status;
    }
  }

  /// 営業状態を更新
  Future<OperationStatusModel?> updateStatus(
    OperationStatusUpdateDto updateDto,
    String userId,
  ) async {
    final OperationStatusModel? current = await getCurrentOperationStatus(userId: userId);

    if (current != null) {
      final Map<String, dynamic> updates = updateDto.toUpdateMap();
      return updateById(current.id!, updates);
    }

    return null;
  }

  /// 手動オーバーライドを設定
  Future<OperationStatusModel?> setManualOverride(
    bool isOpen,
    String? reason,
    String userId, {
    DateTime? estimatedReopenTime,
  }) async {
    final OperationStatusUpdateDto updateDto = OperationStatusUpdateDto(
      isCurrentlyOpen: isOpen,
      manualOverride: true,
      overrideReason: reason,
      estimatedReopenTime: estimatedReopenTime,
    );

    return updateStatus(updateDto, userId);
  }

  /// 手動オーバーライドを解除
  Future<OperationStatusModel?> clearManualOverride(String userId) async {
    final OperationStatusUpdateDto updateDto = OperationStatusUpdateDto(clearOverride: true);

    return updateStatus(updateDto, userId);
  }

  /// 営業状態履歴を取得
  Future<List<OperationStatusModel>> getStatusHistory({String? userId, int limit = 50}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "last_status_change", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy, limit: limit);
  }

  /// 手動オーバーライド中の状態を取得
  Future<List<OperationStatusModel>> getManualOverrideStatuses({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("manual_override", true),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "last_status_change", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 期間指定で営業状態を取得
  Future<List<OperationStatusModel>> getStatusByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? userId,
  }) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.gte("last_status_change", startDate.toIso8601String()),
      QueryConditionBuilder.lte("last_status_change", endDate.toIso8601String()),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "last_status_change"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 営業時間外の強制営業状態を取得
  Future<List<OperationStatusModel>> getAfterHoursOperations({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("is_currently_open", true),
      QueryConditionBuilder.eq("manual_override", true),
    ];

    return find(filters: filters);
  }

  /// 予定された営業再開がある状態を取得
  Future<List<OperationStatusModel>> getScheduledReopenings({String? userId}) async {
    final DateTime now = DateTime.now();

    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("is_currently_open", false),
      QueryConditionBuilder.isNotNull("estimated_reopen_time"),
      QueryConditionBuilder.gte("estimated_reopen_time", now.toIso8601String()),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "estimated_reopen_time"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 営業状態統計を取得
  Future<Map<String, dynamic>> getOperationStatistics(String userId, {int days = 30}) async {
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(Duration(days: days));

    final List<OperationStatusModel> statuses = await getStatusByDateRange(
      startDate,
      endDate,
      userId: userId,
    );

    int manualOverrideCount = 0;
    final int statusChangeCount = statuses.length;

    for (final OperationStatusModel status in statuses) {
      if (status.manualOverride) {
        manualOverrideCount++;
      }
    }

    return <String, dynamic>{
      "period_days": days,
      "total_status_changes": statusChangeCount,
      "manual_override_count": manualOverrideCount,
      "manual_override_rate": statusChangeCount > 0 ? manualOverrideCount / statusChangeCount : 0.0,
      "avg_changes_per_day": statusChangeCount / days,
    };
  }

  /// 長期間のオーバーライド状態を検出
  Future<List<OperationStatusModel>> detectLongTermOverrides({
    String? userId,
    int hoursThreshold = 24,
  }) async {
    final DateTime cutoffTime = DateTime.now().subtract(Duration(hours: hoursThreshold));

    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("manual_override", true),
      QueryConditionBuilder.lt("last_status_change", cutoffTime.toIso8601String()),
    ];

    return find(filters: filters);
  }

  /// 営業状態の整合性チェック
  Future<Map<String, dynamic>> validateOperationStatus(String userId) async {
    final OperationStatusModel? current = await getCurrentOperationStatus(userId: userId);
    final Map<String, dynamic> validation = <String, dynamic>{
      "is_valid": true,
      "issues": <String>[],
      "warnings": <String>[],
    };

    if (current == null) {
      validation["is_valid"] = false;
      validation["issues"].add("営業状態が設定されていません");
      return validation;
    }

    // 長期間のオーバーライドチェック
    final List<OperationStatusModel> longTermOverrides = await detectLongTermOverrides(
      userId: userId,
    );
    if (longTermOverrides.isNotEmpty) {
      validation["warnings"].add("24時間以上の手動オーバーライドが設定されています");
    }

    // 過去の再開予定時刻チェック
    if (current.estimatedReopenTime != null &&
        current.estimatedReopenTime!.isBefore(DateTime.now())) {
      validation["warnings"].add("再開予定時刻が過去になっています");
    }

    return validation;
  }

  /// 古い営業状態履歴を削除
  Future<void> deleteOldStatusHistory(int retentionDays, {String? userId}) async {
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.lt("last_status_change", cutoffDate.toIso8601String()),
    ];

    final List<OperationStatusModel> oldStatuses = await find(filters: filters);

    // 最新の状態は保持
    if (oldStatuses.length > 1) {
      final List<String> oldStatusIds = oldStatuses.sublist(1).map((OperationStatusModel status) => status.id!).toList();
      if (oldStatusIds.isNotEmpty) {
        await bulkDelete(oldStatusIds);
      }
    }
  }
}
