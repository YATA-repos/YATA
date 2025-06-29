// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  totalAmount: (json['totalAmount'] as num).toInt(),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['paymentMethod']),
  discountAmount: (json['discountAmount'] as num).toInt(),
  orderedAt: DateTime.parse(json['orderedAt'] as String),
  customerName: json['customerName'] as String?,
  notes: json['notes'] as String?,
  startedPreparingAt: json['startedPreparingAt'] == null
      ? null
      : DateTime.parse(json['startedPreparingAt'] as String),
  readyAt: json['readyAt'] == null ? null : DateTime.parse(json['readyAt'] as String),
  completedAt: json['completedAt'] == null ? null : DateTime.parse(json['completedAt'] as String),
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'totalAmount': instance.totalAmount,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
  'discountAmount': instance.discountAmount,
  'customerName': instance.customerName,
  'notes': instance.notes,
  'orderedAt': instance.orderedAt.toIso8601String(),
  'startedPreparingAt': instance.startedPreparingAt?.toIso8601String(),
  'readyAt': instance.readyAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.preparing: 'preparing',
  OrderStatus.completed: 'completed',
  OrderStatus.canceled: 'canceled',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.card: 'card',
  PaymentMethod.other: 'other',
};

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  orderId: json['orderId'] as String,
  menuItemId: json['menuItemId'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unitPrice'] as num).toInt(),
  subtotal: (json['subtotal'] as num).toInt(),
  selectedOptions: (json['selectedOptions'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  specialRequest: json['specialRequest'] as String?,
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'orderId': instance.orderId,
  'menuItemId': instance.menuItemId,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
  'subtotal': instance.subtotal,
  'selectedOptions': instance.selectedOptions,
  'specialRequest': instance.specialRequest,
  'createdAt': instance.createdAt?.toIso8601String(),
};
