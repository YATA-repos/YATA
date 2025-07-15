import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base_model.dart";

part "alert_model.g.dart";

/// アラートモデル
///
/// システムアラートの管理を行います。
@JsonSerializable()
class AlertModel extends BaseModel {
  AlertModel({
    required this.type,
    required this.title,
    required this.message,
    this.severity = AlertSeverity.info,
    this.actionUrl,
    this.isRead = false,
    this.isActive = true,
    super.id,
    super.userId,
    this.createdAt,
    this.updatedAt,
  });

  /// JSONからAlertModelを作成
  factory AlertModel.fromJson(Map<String, dynamic> json) => _$AlertModelFromJson(json);

  @override
  String get tableName => "alerts";

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

  /// 既読フラグ
  final bool isRead;

  /// アクティブフラグ
  final bool isActive;

  /// 作成日時
  final DateTime? createdAt;

  /// 更新日時
  final DateTime? updatedAt;

  @override
  Map<String, dynamic> toJson() => _$AlertModelToJson(this);

  /// 既読にする
  AlertModel markAsRead() => copyWith(isRead: true, updatedAt: DateTime.now());

  /// 非アクティブにする
  AlertModel deactivate() => copyWith(isActive: false, updatedAt: DateTime.now());

  /// コピーメソッド
  AlertModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    AlertSeverity? severity,
    String? actionUrl,
    bool? isRead,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AlertModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    title: title ?? this.title,
    message: message ?? this.message,
    severity: severity ?? this.severity,
    actionUrl: actionUrl ?? this.actionUrl,
    isRead: isRead ?? this.isRead,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() => "AlertModel(id: $id, type: $type, title: $title, severity: $severity)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(id, type, title, severity);
}

/// アラート重要度列挙型
@JsonEnum()
enum AlertSeverity {
  /// 情報
  @JsonValue("info")
  info,

  /// 警告
  @JsonValue("warning")
  warning,

  /// エラー
  @JsonValue("error")
  error,

  /// 重大
  @JsonValue("critical")
  critical,
}

/// トレンド方向列挙型
@JsonEnum()
enum TrendDirection {
  /// 上昇
  @JsonValue("up")
  up,

  /// 下降
  @JsonValue("down")
  down,

  /// 横ばい
  @JsonValue("stable")
  stable,
}
