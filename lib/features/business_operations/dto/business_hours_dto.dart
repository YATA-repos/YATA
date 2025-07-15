import "package:json_annotation/json_annotation.dart";

import "../models/business_hours_model.dart";

part "business_hours_dto.g.dart";

/// 営業時間DTO
///
/// 営業時間の作成・更新用のデータ転送オブジェクト。
@JsonSerializable()
class BusinessHoursDto {
  const BusinessHoursDto({
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    this.dayOfWeek,
    this.specialHours = false,
    this.note,
    this.timezone,
    this.userId,
  });

  /// BusinessHoursModelから作成
  factory BusinessHoursDto.fromModel(BusinessHoursModel model) => BusinessHoursDto(
    openTime: model.openTime,
    closeTime: model.closeTime,
    isOpen: model.isOpen,
    dayOfWeek: model.dayOfWeek,
    specialHours: model.specialHours,
    note: model.note,
    timezone: model.timezone,
    userId: model.userId,
  );

  /// デフォルト営業時間を生成
  factory BusinessHoursDto.defaultHours({String? userId}) =>
      BusinessHoursDto(openTime: "11:00", closeTime: "22:00", isOpen: true, userId: userId);

  /// 曜日別営業時間を生成
  factory BusinessHoursDto.forDay({
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isOpen = true,
    String? note,
    String? userId,
  }) => BusinessHoursDto(
    openTime: openTime,
    closeTime: closeTime,
    isOpen: isOpen,
    dayOfWeek: dayOfWeek,
    note: note,
    userId: userId,
  );

  /// JSONからBusinessHoursDtoを作成
  factory BusinessHoursDto.fromJson(Map<String, dynamic> json) => _$BusinessHoursDtoFromJson(json);

  /// 開店時間（HH:mm形式）
  final String openTime;

  /// 閉店時間（HH:mm形式）
  final String closeTime;

  /// 営業中かどうか
  final bool isOpen;

  /// 曜日（0:日曜日、1:月曜日、...、6:土曜日）
  final int? dayOfWeek;

  /// 特別営業時間かどうか
  final bool specialHours;

  /// 備考
  final String? note;

  /// タイムゾーン
  final String? timezone;

  /// ユーザーID
  final String? userId;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$BusinessHoursDtoToJson(this);

  /// BusinessHoursModelに変換
  BusinessHoursModel toModel({String? id, String? userId}) => BusinessHoursModel(
    id: id,
    userId: userId ?? this.userId,
    openTime: openTime,
    closeTime: closeTime,
    isOpen: isOpen,
    dayOfWeek: dayOfWeek,
    specialHours: specialHours,
    note: note,
    timezone: timezone,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// 営業時間の妥当性を検証
  bool get isValid {
    try {
      // 時間形式の検証
      final List<String> openParts = openTime.split(":");
      final List<String> closeParts = closeTime.split(":");

      if (openParts.length != 2 || closeParts.length != 2) {
        return false;
      }

      final int openHour = int.parse(openParts[0]);
      final int openMinute = int.parse(openParts[1]);
      final int closeHour = int.parse(closeParts[0]);
      final int closeMinute = int.parse(closeParts[1]);

      // 時間の範囲チェック
      if (openHour < 0 || openHour > 23 || closeHour < 0 || closeHour > 23) {
        return false;
      }
      if (openMinute < 0 || openMinute > 59 || closeMinute < 0 || closeMinute > 59) {
        return false;
      }

      // 曜日の範囲チェック
      if (dayOfWeek != null && (dayOfWeek! < 0 || dayOfWeek! > 6)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String toString() =>
      "BusinessHoursDto(openTime: $openTime, closeTime: $closeTime, isOpen: $isOpen, dayOfWeek: $dayOfWeek)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessHoursDto &&
          runtimeType == other.runtimeType &&
          openTime == other.openTime &&
          closeTime == other.closeTime &&
          isOpen == other.isOpen &&
          dayOfWeek == other.dayOfWeek;

  @override
  int get hashCode => Object.hash(openTime, closeTime, isOpen, dayOfWeek);
}

/// 営業時間検索フィルターDTO
@JsonSerializable()
class BusinessHoursFilterDto {
  const BusinessHoursFilterDto({this.isOpen, this.dayOfWeek, this.specialHours, this.userId});

  /// JSONからBusinessHoursFilterDtoを作成
  factory BusinessHoursFilterDto.fromJson(Map<String, dynamic> json) =>
      _$BusinessHoursFilterDtoFromJson(json);

  /// 営業中フィルター
  final bool? isOpen;

  /// 曜日フィルター
  final int? dayOfWeek;

  /// 特別営業時間フィルター
  final bool? specialHours;

  /// ユーザーIDフィルター
  final String? userId;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$BusinessHoursFilterDtoToJson(this);

  /// クエリマップに変換
  Map<String, dynamic> toQueryMap() {
    final Map<String, dynamic> query = <String, dynamic>{};

    if (isOpen != null) {
      query["is_open"] = isOpen;
    }
    if (dayOfWeek != null) {
      query["day_of_week"] = dayOfWeek;
    }
    if (specialHours != null) {
      query["special_hours"] = specialHours;
    }
    if (userId != null) {
      query["user_id"] = userId;
    }

    return query;
  }

  @override
  String toString() =>
      "BusinessHoursFilterDto(isOpen: $isOpen, dayOfWeek: $dayOfWeek, specialHours: $specialHours)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessHoursFilterDto &&
          runtimeType == other.runtimeType &&
          isOpen == other.isOpen &&
          dayOfWeek == other.dayOfWeek &&
          specialHours == other.specialHours;

  @override
  int get hashCode => Object.hash(isOpen, dayOfWeek, specialHours);
}
