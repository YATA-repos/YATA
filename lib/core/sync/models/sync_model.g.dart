// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncRecord _$SyncRecordFromJson(Map<String, dynamic> json) => SyncRecord(
  recordType: json['recordType'] as String,
  payload: json['payload'] as Map<String, dynamic>,
  synced: json['synced'] as bool,
  timestamp: DateTime.parse(json['timestamp'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  id: json['id'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$SyncRecordToJson(SyncRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'recordType': instance.recordType,
      'payload': instance.payload,
      'synced': instance.synced,
      'timestamp': instance.timestamp.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };
