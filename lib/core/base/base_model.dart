/// ベースモデル抽象クラス
abstract class BaseModel {
  /// コンストラクタ
  BaseModel({
    this.id,
    this.userId,
  });

  /// DBテーブル名
  String get tableName;

  /// ID
  String? id;

  /// ユーザーID
  String? userId;
}
