import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base.dart";

part "menu_model.g.dart";

/// メニューカテゴリ
@JsonSerializable()
class MenuCategory extends BaseModel {
  MenuCategory({
    required this.name,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// JSONからインスタンスを作成
  factory MenuCategory.fromJson(Map<String, dynamic> json) => _$MenuCategoryFromJson(json);

  /// カテゴリ名（メイン料理、サイドメニュー、ドリンク、デザート）
  String name;

  /// 表示順序
  int displayOrder;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "menu_categories";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$MenuCategoryToJson(this);
}

/// メニュー（販売商品）
@JsonSerializable()
class MenuItem extends BaseModel {
  MenuItem({
    required this.name,
    required this.categoryId,
    required this.price,
    required this.isAvailable,
    required this.estimatedPrepTimeMinutes,
    required this.displayOrder,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// JSONからインスタンスを作成
  factory MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);

  /// 商品名
  String name;

  /// メニューカテゴリID
  String categoryId;

  /// 販売価格（円）
  int price;

  /// 商品説明
  String? description;

  /// 販売可能フラグ
  bool isAvailable;

  /// 推定調理時間（分）
  int estimatedPrepTimeMinutes;

  /// 表示順序
  int displayOrder;

  /// 商品画像URL
  String? imageUrl;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "menu_items";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$MenuItemToJson(this);
}

/// メニューオプション（トッピングなど）
@JsonSerializable()
class MenuItemOption extends BaseModel {
  MenuItemOption({
    required this.menuItemId,
    required this.optionName,
    required this.optionValues,
    required this.isRequired,
    required this.additionalPrice,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// JSONからインスタンスを作成
  factory MenuItemOption.fromJson(Map<String, dynamic> json) => _$MenuItemOptionFromJson(json);

  /// メニューID
  String menuItemId;

  /// オプション名（例：「ソース」）
  String optionName;

  /// 選択肢（例：["あり", "なし"]）
  List<String> optionValues;

  /// 必須選択かどうか
  bool isRequired;

  /// 追加料金
  int additionalPrice;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "menu_item_options";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$MenuItemOptionToJson(this);
}
