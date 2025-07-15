import "package:json_annotation/json_annotation.dart";

import "../models/alert_model.dart";

part "alert_dto.g.dart";

/// アラートDTO
///
/// アラート作成・更新用のデータ転送オブジェクト。
@JsonSerializable()
class AlertDto {
  const AlertDto({
    required this.type,
    required this.title,
    required this.message,
    this.severity = AlertSeverity.info,
    this.actionUrl,
    this.userId,
  });

  /// JSONからAlertDtoを作成
  factory AlertDto.fromJson(Map<String, dynamic> json) => _$AlertDtoFromJson(json);

  /// アラートタイプ
  final String type;

  /// タイトル
  final String title;

  /// メッセージ
  final String message;

  /// 重要度
  final AlertSeverity severity;

  /// アクション先URL
  final String? actionUrl;

  /// ユーザーID
  final String? userId;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$AlertDtoToJson(this);

  /// AlertModelに変換
  AlertModel toModel({String? id, String? userId}) => AlertModel(
    id: id,
    userId: userId ?? this.userId,
    type: type,
    title: title,
    message: message,
    severity: severity,
    actionUrl: actionUrl,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  String toString() => "AlertDto(type: $type, title: $title, severity: $severity)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertDto &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          title == other.title &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(type, title, severity);
}

/// アラート検索フィルターDTO
@JsonSerializable()
class AlertFilterDto {
  const AlertFilterDto({
    this.severity,
    this.type,
    this.isRead,
    this.isActive,
    this.userId,
    this.dateFrom,
    this.dateTo,
  });

  /// JSONからAlertFilterDtoを作成
  factory AlertFilterDto.fromJson(Map<String, dynamic> json) => _$AlertFilterDtoFromJson(json);

  /// 重要度フィルター
  final AlertSeverity? severity;

  /// タイプフィルター
  final String? type;

  /// 既読フィルター
  final bool? isRead;

  /// アクティブフィルター
  final bool? isActive;

  /// ユーザーIDフィルター
  final String? userId;

  /// 開始日フィルター
  final DateTime? dateFrom;

  /// 終了日フィルター
  final DateTime? dateTo;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$AlertFilterDtoToJson(this);

  /// クエリマップに変換
  Map<String, dynamic> toQueryMap() {
    final Map<String, dynamic> query = <String, dynamic>{};

    if (severity != null) {
      query["severity"] = severity!.name;
    }
    if (type != null) {
      query["type"] = type;
    }
    if (isRead != null) {
      query["is_read"] = isRead;
    }
    if (isActive != null) {
      query["is_active"] = isActive;
    }
    if (userId != null) {
      query["user_id"] = userId;
    }
    if (dateFrom != null) {
      query["created_at.gte"] = dateFrom!.toIso8601String();
    }
    if (dateTo != null) {
      query["created_at.lte"] = dateTo!.toIso8601String();
    }

    return query;
  }

  @override
  String toString() => "AlertFilterDto(severity: $severity, type: $type, isRead: $isRead)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertFilterDto &&
          runtimeType == other.runtimeType &&
          severity == other.severity &&
          type == other.type &&
          isRead == other.isRead;

  @override
  int get hashCode => Object.hash(severity, type, isRead);
}
