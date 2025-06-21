import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base.dart";
import "../../../core/constants/enums.dart";

part "inventory_model.g.dart";

/// 材料マスタ
@JsonSerializable()
class Material extends BaseModel {
  /// コンストラクタ
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

  /// JSONからインスタンスを作成
  factory Material.fromJson(Map<String, dynamic> json) =>
      _$MaterialFromJson(json);

  /// JSONに変換
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
@JsonSerializable()
class MaterialCategory extends BaseModel {
  /// コンストラクタ
  MaterialCategory({
    required this.name,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// カテゴリ名（肉類、野菜、調理済食品、果物）
  String name;

  /// 表示順序
  int displayOrder;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "material_categories";

  /// JSONからインスタンスを作成
  factory MaterialCategory.fromJson(Map<String, dynamic> json) =>
      _$MaterialCategoryFromJson(json);

  /// JSONに変換
  Map<String, dynamic> toJson() => _$MaterialCategoryToJson(this);
}

/// レシピ（メニューと材料の関係）
@JsonSerializable()
class Recipe extends BaseModel {
  /// コンストラクタ
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

  /// JSONからインスタンスを作成
  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

  /// JSONに変換
  Map<String, dynamic> toJson() => _$RecipeToJson(this);
}