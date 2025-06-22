import "package:json_annotation/json_annotation.dart";

import "../../base/base.dart";

part "sync_model.g.dart";

/// 同期記録
@JsonSerializable()
class SyncRecord extends BaseModel {
  /// コンストラクタ
  SyncRecord({
    required this.recordType,
    required this.payload,
    required this.synced,
    required this.timestamp,
    this.completedAt,
    super.id,
    super.userId,
  });

  /// JSONからインスタンスを作成
  factory SyncRecord.fromJson(Map<String, dynamic> json) =>
      _$SyncRecordFromJson(json);

  /// 対象テーブル名
  String recordType;

  /// ペイロード
  Map<String, dynamic> payload;

  /// 同期済みフラグ
  bool synced;

  /// タイムスタンプ
  DateTime timestamp;

  /// 完了日時
  DateTime? completedAt;

  @override
  String get tableName => "sync_records";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$SyncRecordToJson(this);
}
