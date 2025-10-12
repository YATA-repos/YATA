import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base.dart";
import "../../../core/constants/enums.dart";

part "inventory_model.g.dart";

/// 材料マスタ
@JsonSerializable(fieldRename: FieldRename.snake)
class Material extends BaseModel {
  Material({
    required this.name,
    required this.categoryId,
    required this.unitType,
    required this.currentStock,
    required this.alertThreshold,
    required this.criticalThreshold,
    this.notes,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// JSONからインスタンスを作成
  factory Material.fromJson(Map<String, dynamic> json) => _$MaterialFromJson(json);

  /// 材料名
  String name;

  /// 材料カテゴリID
  String categoryId;

  /// 管理単位（個数 or グラム）
  UnitType unitType;

  /// 現在在庫量
  double currentStock;

  /// アラート閾値
  double alertThreshold;

  /// 緊急閾値
  double criticalThreshold;

  /// メモ
  String? notes;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "materials";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$MaterialToJson(this);

  /// 在庫レベルを取得
  StockLevel getStockLevel() {
    if (currentStock <= criticalThreshold) {
      return StockLevel.critical;
    } else if (currentStock <= alertThreshold) {
      return StockLevel.low;
    } else {
      return StockLevel.sufficient;
    }
  }
}

/// 材料カテゴリ
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class MaterialCategory extends BaseModel {
  MaterialCategory({
    required this.name,
    required this.displayOrder,
    this.code,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// JSONからインスタンスを作成
  factory MaterialCategory.fromJson(Map<String, dynamic> json) => _$MaterialCategoryFromJson(json);

  /// カテゴリ名（肉類、野菜、調理済食品、果物）
  String name;

  /// 表示順序
  int displayOrder;

  /// カテゴリコード
  @JsonKey(includeIfNull: false)
  String? code;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "material_categories";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$MaterialCategoryToJson(this);
}

/// レシピ（メニューと材料の関係）
@JsonSerializable(fieldRename: FieldRename.snake)
class Recipe extends BaseModel {
  Recipe({
    required this.menuItemId,
    required this.materialId,
    required this.requiredAmount,
    required this.isOptional,
    this.notes,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// JSONからインスタンスを作成
  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

  /// メニューID
  String menuItemId;

  /// 材料ID
  String materialId;

  /// 必要量（材料の単位に依存）
  double requiredAmount;

  /// オプション材料かどうか
  bool isOptional;

  /// 備考
  String? notes;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "recipes";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$RecipeToJson(this);
}
