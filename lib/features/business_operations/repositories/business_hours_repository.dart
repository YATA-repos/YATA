import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../dto/business_hours_dto.dart";
import "../models/business_hours_model.dart";

/// 営業時間リポジトリ
///
/// 営業時間データのCRUD操作を提供します。
class BusinessHoursRepository extends BaseRepository<BusinessHoursModel, String> {
  BusinessHoursRepository() : super(tableName: "business_hours");

  @override
  BusinessHoursModel fromJson(Map<String, dynamic> json) => BusinessHoursModel.fromJson(json);

  /// 現在の営業時間を取得
  Future<BusinessHoursModel?> getCurrentBusinessHours({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.isNull("day_of_week"),
      QueryConditionBuilder.eq("special_hours", false),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "updated_at", ascending: false),
    ];

    final List<BusinessHoursModel> results = await find(
      filters: filters,
      orderBy: orderBy,
      limit: 1,
    );

    return results.isNotEmpty ? results[0] : null;
  }

  /// 曜日別営業時間を取得
  Future<BusinessHoursModel?> getBusinessHoursByDay(int dayOfWeek, {String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("day_of_week", dayOfWeek),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "updated_at", ascending: false),
    ];

    final List<BusinessHoursModel> results = await find(
      filters: filters,
      orderBy: orderBy,
      limit: 1,
    );

    return results.isNotEmpty ? results[0] : null;
  }

  /// 全曜日の営業時間を取得
  Future<Map<int, BusinessHoursModel>> getAllDayBusinessHours({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.isNotNull("day_of_week"),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "day_of_week"),
      const OrderByCondition(column: "updated_at", ascending: false),
    ];

    final List<BusinessHoursModel> results = await find(filters: filters, orderBy: orderBy);

    final Map<int, BusinessHoursModel> dayHours = <int, BusinessHoursModel>{};
    for (final BusinessHoursModel hours in results) {
      if (hours.dayOfWeek != null && !dayHours.containsKey(hours.dayOfWeek)) {
        dayHours[hours.dayOfWeek!] = hours;
      }
    }

    return dayHours;
  }

  /// 営業時間を作成または更新（Upsert）
  Future<BusinessHoursModel> upsertBusinessHours(BusinessHoursModel businessHours) async {
    BusinessHoursModel? existing;

    // 既存の営業時間を検索
    if (businessHours.dayOfWeek != null) {
      existing = await getBusinessHoursByDay(
        businessHours.dayOfWeek!,
        userId: businessHours.userId,
      );
    } else {
      existing = await getCurrentBusinessHours(userId: businessHours.userId);
    }

    if (existing != null) {
      // 更新
      final Map<String, dynamic> updates = businessHours
          .copyWith(id: existing.id, updatedAt: DateTime.now())
          .toJson();

      final BusinessHoursModel? updated = await updateById(existing.id!, updates);
      return updated ?? businessHours;
    } else {
      // 新規作成
      final BusinessHoursModel? created = await create(
        businessHours.copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      return created ?? businessHours;
    }
  }

  /// 営業状態を更新
  Future<BusinessHoursModel?> updateOperationStatus(bool isOpen, {String? userId}) async {
    final BusinessHoursModel? current = await getCurrentBusinessHours(userId: userId);

    if (current != null) {
      final Map<String, dynamic> updates = <String, dynamic>{
        "is_open": isOpen,
        "updated_at": DateTime.now().toIso8601String(),
      };

      return updateById(current.id!, updates);
    }

    return null;
  }

  /// 特別営業時間を取得
  Future<List<BusinessHoursModel>> getSpecialBusinessHours({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("special_hours", true),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "created_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 営業中の時間設定を取得
  Future<List<BusinessHoursModel>> getOpenBusinessHours({String? userId}) async {
    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("is_open", true),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "day_of_week"),
      const OrderByCondition(column: "updated_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// フィルター条件で営業時間を検索
  Future<List<BusinessHoursModel>> searchBusinessHours(BusinessHoursFilterDto filter) async {
    final Map<String, dynamic> queryMap = filter.toQueryMap();
    final List<QueryFilter> filters = <QueryFilter>[];

    queryMap.forEach((String key, dynamic value) {
      filters.add(QueryConditionBuilder.eq(key, value));
    });

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "day_of_week"),
      const OrderByCondition(column: "updated_at", ascending: false),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 曜日別営業時間を一括更新
  Future<List<BusinessHoursModel>> bulkUpdateDayBusinessHours(
    Map<int, BusinessHoursDto> dayHours,
    String userId,
  ) async {
    final List<BusinessHoursModel> results = <BusinessHoursModel>[];

    for (final MapEntry<int, BusinessHoursDto> entry in dayHours.entries) {
      final BusinessHoursModel model = entry.value
          .toModel(userId: userId)
          .copyWith(dayOfWeek: entry.key);

      final BusinessHoursModel result = await upsertBusinessHours(model);
      results.add(result);
    }

    return results;
  }

  /// デフォルト営業時間を作成
  Future<BusinessHoursModel> createDefaultBusinessHours(String userId) async {
    final BusinessHoursModel defaultHours = BusinessHoursDto.defaultHours(
      userId: userId,
    ).toModel(userId: userId);

    return upsertBusinessHours(defaultHours);
  }

  /// 古い特別営業時間を削除
  Future<void> deleteOldSpecialHours(int retentionDays, {String? userId}) async {
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    final List<QueryFilter> filters = <QueryFilter>[
      if (userId != null) QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("special_hours", true),
      QueryConditionBuilder.lt("created_at", cutoffDate.toIso8601String()),
    ];

    final List<BusinessHoursModel> oldHours = await find(filters: filters);
    final List<String> oldHoursIds = oldHours.map((BusinessHoursModel hours) => hours.id!).toList();

    if (oldHoursIds.isNotEmpty) {
      await bulkDelete(oldHoursIds);
    }
  }

  /// 営業時間の有効性を検証
  Future<Map<String, dynamic>> validateBusinessHours(BusinessHoursDto dto) async {
    final Map<String, dynamic> validation = <String, dynamic>{
      "is_valid": true,
      "errors": <String>[],
    };

    if (!dto.isValid) {
      validation["is_valid"] = false;
      validation["errors"].add("無効な時間形式です");
    }

    // 重複チェック
    if (dto.dayOfWeek != null) {
      final BusinessHoursModel? existing = await getBusinessHoursByDay(
        dto.dayOfWeek!,
        userId: dto.userId,
      );
      if (existing != null) {
        validation["warnings"] = <String>["既存の設定が上書きされます"];
      }
    }

    return validation;
  }
}
