/// すべてのモデルクラスの基底クラス
///
/// すべてのモデルクラスは、このクラスを継承し、
/// 以下の実装を行う必要があります：
/// - fromJsonファクトリーコンストラクタ
/// - toJsonメソッド
/// - tableNameゲッター
abstract class BaseModel {
  BaseModel({this.id, this.userId});

  /// テーブル名を取得（サブクラスで実装）
  String get tableName;

  /// プライマリキー
  String? id;

  /// ユーザーID
  String? userId;

  /// JSONシリアライゼーション（サブクラスで実装）
  Map<String, dynamic> toJson();
}
