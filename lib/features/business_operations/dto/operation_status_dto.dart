import "package:json_annotation/json_annotation.dart";

import "../models/business_hours_model.dart";
import "../models/operation_status_model.dart";

part "operation_status_dto.g.dart";

/// 営業状態DTO
///
/// 営業状態の作成・更新用のデータ転送オブジェクト。
@JsonSerializable()
class OperationStatusDto {
  const OperationStatusDto({
    required this.isCurrentlyOpen,
    this.manualOverride = false,
    this.overrideReason,
    this.estimatedReopenTime,
    this.userId,
  });

  /// OperationStatusModelから作成
  factory OperationStatusDto.fromModel(OperationStatusModel model) => OperationStatusDto(
    isCurrentlyOpen: model.isCurrentlyOpen,
    manualOverride: model.manualOverride,
    overrideReason: model.overrideReason,
    estimatedReopenTime: model.estimatedReopenTime,
    userId: model.userId,
  );

  /// 営業状態切り替え用DTOを作成
  factory OperationStatusDto.toggle({
    required bool currentStatus,
    String? reason,
    DateTime? reopenTime,
    String? userId,
  }) => OperationStatusDto(
    isCurrentlyOpen: !currentStatus,
    manualOverride: true,
    overrideReason: reason,
    estimatedReopenTime: reopenTime,
    userId: userId,
  );

  /// 手動オーバーライド解除用DTOを作成
  factory OperationStatusDto.clearOverride({required bool automaticStatus, String? userId}) =>
      OperationStatusDto(isCurrentlyOpen: automaticStatus, userId: userId);

  /// 臨時休業用DTOを作成
  factory OperationStatusDto.temporaryClose({
    required DateTime reopenTime,
    String? reason,
    String? userId,
  }) => OperationStatusDto(
    isCurrentlyOpen: false,
    manualOverride: true,
    overrideReason: reason ?? "臨時休業",
    estimatedReopenTime: reopenTime,
    userId: userId,
  );

  /// 緊急営業用DTOを作成
  factory OperationStatusDto.emergencyOpen({String? reason, String? userId}) => OperationStatusDto(
    isCurrentlyOpen: true,
    manualOverride: true,
    overrideReason: reason ?? "緊急営業",
    userId: userId,
  );

  /// JSONからOperationStatusDtoを作成
  factory OperationStatusDto.fromJson(Map<String, dynamic> json) =>
      _$OperationStatusDtoFromJson(json);

  /// 現在営業中かどうか
  final bool isCurrentlyOpen;

  /// 手動オーバーライドフラグ
  final bool manualOverride;

  /// オーバーライドの理由
  final String? overrideReason;

  /// 再開予定時刻（臨時休業時）
  final DateTime? estimatedReopenTime;

  /// ユーザーID
  final String? userId;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$OperationStatusDtoToJson(this);

  /// OperationStatusModelに変換
  OperationStatusModel toModel({
    required BusinessHoursModel businessHours,
    String? id,
    String? userId,
  }) => OperationStatusModel(
    id: id,
    userId: userId ?? this.userId,
    isCurrentlyOpen: isCurrentlyOpen,
    businessHours: businessHours,
    manualOverride: manualOverride,
    overrideReason: overrideReason,
    estimatedReopenTime: estimatedReopenTime,
    lastStatusChange: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  String toString() =>
      "OperationStatusDto(isCurrentlyOpen: $isCurrentlyOpen, manualOverride: $manualOverride)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationStatusDto &&
          runtimeType == other.runtimeType &&
          isCurrentlyOpen == other.isCurrentlyOpen &&
          manualOverride == other.manualOverride &&
          overrideReason == other.overrideReason;

  @override
  int get hashCode => Object.hash(isCurrentlyOpen, manualOverride, overrideReason);
}

/// 営業状態更新リクエストDTO
@JsonSerializable()
class OperationStatusUpdateDto {
  const OperationStatusUpdateDto({
    this.isCurrentlyOpen,
    this.manualOverride,
    this.overrideReason,
    this.estimatedReopenTime,
    this.clearOverride = false,
  });

  /// JSONからOperationStatusUpdateDtoを作成
  factory OperationStatusUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$OperationStatusUpdateDtoFromJson(json);

  /// 営業中かどうか（nullの場合は変更なし）
  final bool? isCurrentlyOpen;

  /// 手動オーバーライドフラグ（nullの場合は変更なし）
  final bool? manualOverride;

  /// オーバーライドの理由
  final String? overrideReason;

  /// 再開予定時刻
  final DateTime? estimatedReopenTime;

  /// オーバーライドを解除するかどうか
  final bool clearOverride;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$OperationStatusUpdateDtoToJson(this);

  /// 更新用マップに変換
  Map<String, dynamic> toUpdateMap() {
    final Map<String, dynamic> updates = <String, dynamic>{};

    if (isCurrentlyOpen != null) {
      updates["is_currently_open"] = isCurrentlyOpen;
    }
    if (manualOverride != null) {
      updates["manual_override"] = manualOverride;
    }
    if (overrideReason != null) {
      updates["override_reason"] = overrideReason;
    }
    if (estimatedReopenTime != null) {
      updates["estimated_reopen_time"] = estimatedReopenTime!.toIso8601String();
    }
    if (clearOverride) {
      updates["manual_override"] = false;
      updates["override_reason"] = null;
      updates["estimated_reopen_time"] = null;
    }

    updates["last_status_change"] = DateTime.now().toIso8601String();
    updates["updated_at"] = DateTime.now().toIso8601String();

    return updates;
  }

  @override
  String toString() =>
      "OperationStatusUpdateDto(isCurrentlyOpen: $isCurrentlyOpen, manualOverride: $manualOverride, clearOverride: $clearOverride)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationStatusUpdateDto &&
          runtimeType == other.runtimeType &&
          isCurrentlyOpen == other.isCurrentlyOpen &&
          manualOverride == other.manualOverride &&
          clearOverride == other.clearOverride;

  @override
  int get hashCode => Object.hash(isCurrentlyOpen, manualOverride, clearOverride);
}
