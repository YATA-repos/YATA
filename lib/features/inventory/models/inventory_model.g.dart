// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Material _$MaterialFromJson(Map<String, dynamic> json) => Material(
  name: json['name'] as String,
  categoryId: json['categoryId'] as String,
  unitType: $enumDecode(_$UnitTypeEnumMap, json['unitType']),
  currentStock: (json['currentStock'] as num).toDouble(),
  alertThreshold: (json['alertThreshold'] as num).toDouble(),
  criticalThreshold: (json['criticalThreshold'] as num).toDouble(),
  notes: json['notes'] as String?,
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$MaterialToJson(Material instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'categoryId': instance.categoryId,
  'unitType': _$UnitTypeEnumMap[instance.unitType]!,
  'currentStock': instance.currentStock,
  'alertThreshold': instance.alertThreshold,
  'criticalThreshold': instance.criticalThreshold,
  'notes': instance.notes,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$UnitTypeEnumMap = {UnitType.piece: 'piece', UnitType.gram: 'gram'};

MaterialCategory _$MaterialCategoryFromJson(Map<String, dynamic> json) => MaterialCategory(
  name: json['name'] as String,
  displayOrder: (json['displayOrder'] as num).toInt(),
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$MaterialCategoryToJson(MaterialCategory instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'displayOrder': instance.displayOrder,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

Recipe _$RecipeFromJson(Map<String, dynamic> json) => Recipe(
  menuItemId: json['menuItemId'] as String,
  materialId: json['materialId'] as String,
  requiredAmount: (json['requiredAmount'] as num).toDouble(),
  isOptional: json['isOptional'] as bool,
  notes: json['notes'] as String?,
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$RecipeToJson(Recipe instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'menuItemId': instance.menuItemId,
  'materialId': instance.materialId,
  'requiredAmount': instance.requiredAmount,
  'isOptional': instance.isOptional,
  'notes': instance.notes,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
