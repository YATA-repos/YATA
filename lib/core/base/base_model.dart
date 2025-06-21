import "package:json_annotation/json_annotation.dart";

part "base_model.g.dart";

/// ベースモデル抽象クラス
@JsonSerializable()
abstract class BaseModel {
  /// コンストラクタ
  BaseModel({this.id, this.userId});

  /// DBテーブル名
  String get tableName;

  /// ID
  String? id;

  /// ユーザーID
  String? userId;

  /// JSONに変換
  Map<String, dynamic> toJson();
}
