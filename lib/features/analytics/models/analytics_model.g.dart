// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailySummary _$DailySummaryFromJson(Map<String, dynamic> json) => DailySummary(
  summaryDate: DateTime.parse(json['summaryDate'] as String),
  totalOrders: (json['totalOrders'] as num).toInt(),
  completedOrders: (json['completedOrders'] as num).toInt(),
  pendingOrders: (json['pendingOrders'] as num).toInt(),
  totalRevenue: (json['totalRevenue'] as num).toInt(),
  mostPopularItemCount: (json['mostPopularItemCount'] as num).toInt(),
  averagePrepTimeMinutes: (json['averagePrepTimeMinutes'] as num?)?.toInt(),
  mostPopularItemId: json['mostPopularItemId'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$DailySummaryToJson(DailySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'summaryDate': instance.summaryDate.toIso8601String(),
      'totalOrders': instance.totalOrders,
      'completedOrders': instance.completedOrders,
      'pendingOrders': instance.pendingOrders,
      'totalRevenue': instance.totalRevenue,
      'averagePrepTimeMinutes': instance.averagePrepTimeMinutes,
      'mostPopularItemId': instance.mostPopularItemId,
      'mostPopularItemCount': instance.mostPopularItemCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
