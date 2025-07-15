import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base.dart";

part "business_hours_model.g.dart";

/// 営業時間モデル
///
/// レストランの営業時間情報を管理します。
/// 開店・閉店時間、営業状態、曜日別設定、特別営業時間などを含みます。
@JsonSerializable()
class BusinessHoursModel extends BaseModel {
  /// コンストラクタ
  BusinessHoursModel({
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    this.dayOfWeek,
    this.specialHours = false,
    this.note,
    this.timezone,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// デフォルト営業時間を生成
  factory BusinessHoursModel.defaultHours({String? userId}) => BusinessHoursModel(
    openTime: "11:00",
    closeTime: "22:00",
    isOpen: true,
    userId: userId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// 曜日別営業時間を生成
  factory BusinessHoursModel.forDay({
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isOpen = true,
    String? note,
    String? userId,
  }) => BusinessHoursModel(
    openTime: openTime,
    closeTime: closeTime,
    isOpen: isOpen,
    dayOfWeek: dayOfWeek,
    note: note,
    userId: userId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// JSONからインスタンスを作成
  factory BusinessHoursModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessHoursModelFromJson(json);

  /// 開店時間（HH:mm形式）
  String openTime;

  /// 閉店時間（HH:mm形式）
  String closeTime;

  /// 営業中フラグ
  bool isOpen;

  /// 曜日（0:日曜日、1:月曜日、...、6:土曜日）
  int? dayOfWeek;

  /// 特別営業時間フラグ
  bool specialHours;

  /// 備考
  String? note;

  /// タイムゾーン
  String? timezone;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "business_hours";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$BusinessHoursModelToJson(this);

  /// コピーを作成（プロパティ更新用）
  BusinessHoursModel copyWith({
    String? id,
    String? userId,
    String? openTime,
    String? closeTime,
    bool? isOpen,
    int? dayOfWeek,
    bool? specialHours,
    String? note,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BusinessHoursModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    openTime: openTime ?? this.openTime,
    closeTime: closeTime ?? this.closeTime,
    isOpen: isOpen ?? this.isOpen,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    specialHours: specialHours ?? this.specialHours,
    note: note ?? this.note,
    timezone: timezone ?? this.timezone,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// 現在時刻が営業時間内かどうかを判定
  bool isWithinOperatingHours([DateTime? currentTime]) {
    if (!isOpen) {
      return false;
    }

    final DateTime now = currentTime ?? DateTime.now();
    final String currentTimeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    try {
      final List<String> openParts = openTime.split(":");
      final List<String> closeParts = closeTime.split(":");
      final List<String> currentParts = currentTimeStr.split(":");

      final int openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final int closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      final int currentMinutes = int.parse(currentParts[0]) * 60 + int.parse(currentParts[1]);

      // 24時をまたぐ場合の処理
      if (closeMinutes <= openMinutes) {
        return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
      } else {
        return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
      }
    } catch (e) {
      return false;
    }
  }

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

  /// 営業時間の表示用文字列を取得
  String get displayHours => "$openTime - $closeTime";

  /// 曜日の日本語表示名を取得
  String get dayOfWeekDisplayName {
    if (dayOfWeek == null) {
      return "毎日";
    }

    const List<String> dayNames = <String>["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"];
    return dayNames[dayOfWeek!];
  }

  /// 営業状態の表示用文字列を取得
  String get statusDisplayName => isOpen ? "営業中" : "定休日";

  /// UIコンポーネントとの互換性のためのプロパティ
  /// 営業日のリスト（曜日別営業時間の場合）
  List<int>? get operatingDays => dayOfWeek != null ? <int>[dayOfWeek!] : null;

  /// 週間営業時間（現在は単一の営業時間のみサポート）
  Map<int, String>? get weeklyHours =>
      dayOfWeek != null ? <int, String>{dayOfWeek!: displayHours} : null;

  @override
  String toString() =>
      "BusinessHoursModel(id: $id, openTime: $openTime, closeTime: $closeTime, isOpen: $isOpen, dayOfWeek: $dayOfWeek)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessHoursModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          openTime == other.openTime &&
          closeTime == other.closeTime &&
          isOpen == other.isOpen &&
          dayOfWeek == other.dayOfWeek;

  @override
  int get hashCode => Object.hash(id, openTime, closeTime, isOpen, dayOfWeek);
}
