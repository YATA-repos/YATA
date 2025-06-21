// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuCategory _$MenuCategoryFromJson(Map<String, dynamic> json) => MenuCategory(
  name: json['name'] as String,
  displayOrder: (json['displayOrder'] as num).toInt(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$MenuCategoryToJson(MenuCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'displayOrder': instance.displayOrder,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => MenuItem(
  name: json['name'] as String,
  categoryId: json['categoryId'] as String,
  price: (json['price'] as num).toInt(),
  isAvailable: json['isAvailable'] as bool,
  estimatedPrepTimeMinutes: (json['estimatedPrepTimeMinutes'] as num).toInt(),
  displayOrder: (json['displayOrder'] as num).toInt(),
  description: json['description'] as String?,
  imageUrl: json['imageUrl'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$MenuItemToJson(MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'categoryId': instance.categoryId,
  'price': instance.price,
  'description': instance.description,
  'isAvailable': instance.isAvailable,
  'estimatedPrepTimeMinutes': instance.estimatedPrepTimeMinutes,
  'displayOrder': instance.displayOrder,
  'imageUrl': instance.imageUrl,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

MenuItemOption _$MenuItemOptionFromJson(Map<String, dynamic> json) =>
    MenuItemOption(
      menuItemId: json['menuItemId'] as String,
      optionName: json['optionName'] as String,
      optionValues: (json['optionValues'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isRequired: json['isRequired'] as bool,
      additionalPrice: (json['additionalPrice'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      id: json['id'] as String?,
      userId: json['userId'] as String?,
    );

Map<String, dynamic> _$MenuItemOptionToJson(MenuItemOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'menuItemId': instance.menuItemId,
      'optionName': instance.optionName,
      'optionValues': instance.optionValues,
      'isRequired': instance.isRequired,
      'additionalPrice': instance.additionalPrice,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
