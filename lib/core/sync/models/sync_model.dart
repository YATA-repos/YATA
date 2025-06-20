import "../../base/base.dart";

/// 同期記録
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
}