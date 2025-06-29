// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockTransaction _$StockTransactionFromJson(Map<String, dynamic> json) => StockTransaction(
  materialId: json['materialId'] as String,
  transactionType: $enumDecode(_$TransactionTypeEnumMap, json['transactionType']),
  changeAmount: (json['changeAmount'] as num).toDouble(),
  referenceType: $enumDecodeNullable(_$ReferenceTypeEnumMap, json['referenceType']),
  referenceId: json['referenceId'] as String?,
  notes: json['notes'] as String?,
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$StockTransactionToJson(StockTransaction instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'materialId': instance.materialId,
  'transactionType': _$TransactionTypeEnumMap[instance.transactionType]!,
  'changeAmount': instance.changeAmount,
  'referenceType': _$ReferenceTypeEnumMap[instance.referenceType],
  'referenceId': instance.referenceId,
  'notes': instance.notes,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$TransactionTypeEnumMap = {
  TransactionType.purchase: 'purchase',
  TransactionType.sale: 'sale',
  TransactionType.adjustment: 'adjustment',
  TransactionType.waste: 'waste',
};

const _$ReferenceTypeEnumMap = {
  ReferenceType.order: 'order',
  ReferenceType.purchase: 'purchase',
  ReferenceType.adjustment: 'adjustment',
};

Purchase _$PurchaseFromJson(Map<String, dynamic> json) => Purchase(
  purchaseDate: DateTime.parse(json['purchaseDate'] as String),
  notes: json['notes'] as String?,
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$PurchaseToJson(Purchase instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'purchaseDate': instance.purchaseDate.toIso8601String(),
  'notes': instance.notes,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

PurchaseItem _$PurchaseItemFromJson(Map<String, dynamic> json) => PurchaseItem(
  purchaseId: json['purchaseId'] as String,
  materialId: json['materialId'] as String,
  quantity: (json['quantity'] as num).toDouble(),
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$PurchaseItemToJson(PurchaseItem instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'purchaseId': instance.purchaseId,
  'materialId': instance.materialId,
  'quantity': instance.quantity,
  'createdAt': instance.createdAt?.toIso8601String(),
};

StockAdjustment _$StockAdjustmentFromJson(Map<String, dynamic> json) => StockAdjustment(
  materialId: json['materialId'] as String,
  adjustmentAmount: (json['adjustmentAmount'] as num).toDouble(),
  adjustedAt: DateTime.parse(json['adjustedAt'] as String),
  notes: json['notes'] as String?,
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$StockAdjustmentToJson(StockAdjustment instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'materialId': instance.materialId,
  'adjustmentAmount': instance.adjustmentAmount,
  'notes': instance.notes,
  'adjustedAt': instance.adjustedAt.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
