import "package:flutter/material.dart";
import "package:json_annotation/json_annotation.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../core/base/base.dart";
import "business_hours_model.dart";

part "operation_status_model.g.dart";

/// 営業状態モデル
///
/// レストランの現在の営業状態を管理します。
/// 自動的な営業時間判定と手動オーバーライド機能を提供します。
@JsonSerializable()
class OperationStatusModel extends BaseModel {
  /// コンストラクタ
  OperationStatusModel({
    required this.isCurrentlyOpen,
    required this.businessHours,
    this.manualOverride = false,
    this.overrideReason,
    this.estimatedReopenTime,
    this.lastStatusChange,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// デフォルト営業状態を生成
  factory OperationStatusModel.defaultStatus({
    required BusinessHoursModel businessHours,
    String? userId,
  }) {
    final bool automaticStatus = businessHours.isWithinOperatingHours();

    return OperationStatusModel(
      isCurrentlyOpen: automaticStatus,
      businessHours: businessHours,
      userId: userId,
      lastStatusChange: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 臨時休業状態を生成
  factory OperationStatusModel.temporaryClose({
    required BusinessHoursModel businessHours,
    required DateTime reopenTime,
    String? reason,
    String? userId,
  }) => OperationStatusModel(
    isCurrentlyOpen: false,
    businessHours: businessHours,
    manualOverride: true,
    overrideReason: reason ?? "臨時休業",
    estimatedReopenTime: reopenTime,
    userId: userId,
    lastStatusChange: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// 緊急営業状態を生成
  factory OperationStatusModel.emergencyOpen({
    required BusinessHoursModel businessHours,
    String? reason,
    String? userId,
  }) => OperationStatusModel(
    isCurrentlyOpen: true,
    businessHours: businessHours,
    manualOverride: true,
    overrideReason: reason ?? "緊急営業",
    userId: userId,
    lastStatusChange: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// JSONからインスタンスを作成
  factory OperationStatusModel.fromJson(Map<String, dynamic> json) =>
      _$OperationStatusModelFromJson(json);

  /// 現在営業中フラグ
  bool isCurrentlyOpen;

  /// 営業時間設定
  BusinessHoursModel businessHours;

  /// 手動オーバーライドフラグ
  bool manualOverride;

  /// オーバーライド理由
  String? overrideReason;

  /// 再開予定時刻（臨時休業時）
  DateTime? estimatedReopenTime;

  /// 最終状態変更日時
  DateTime? lastStatusChange;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "operation_status";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$OperationStatusModelToJson(this);

  /// コピーを作成（プロパティ更新用）
  OperationStatusModel copyWith({
    String? id,
    String? userId,
    bool? isCurrentlyOpen,
    BusinessHoursModel? businessHours,
    bool? manualOverride,
    String? overrideReason,
    DateTime? estimatedReopenTime,
    DateTime? lastStatusChange,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OperationStatusModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    isCurrentlyOpen: isCurrentlyOpen ?? this.isCurrentlyOpen,
    businessHours: businessHours ?? this.businessHours,
    manualOverride: manualOverride ?? this.manualOverride,
    overrideReason: overrideReason ?? this.overrideReason,
    estimatedReopenTime: estimatedReopenTime ?? this.estimatedReopenTime,
    lastStatusChange: lastStatusChange ?? this.lastStatusChange,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// 営業時間に基づく自動的な営業状態を更新
  OperationStatusModel updateAutomaticStatus([DateTime? currentTime]) {
    if (manualOverride) {
      return this;
    }

    final bool automaticStatus = businessHours.isWithinOperatingHours(currentTime);
    if (automaticStatus == isCurrentlyOpen) {
      return this;
    }

    return copyWith(
      isCurrentlyOpen: automaticStatus,
      lastStatusChange: currentTime ?? DateTime.now(),
      updatedAt: currentTime ?? DateTime.now(),
    );
  }

  /// 手動オーバーライドを切り替え
  OperationStatusModel toggleManualOverride({
    required bool status,
    String? reason,
    DateTime? reopenTime,
  }) => copyWith(
    isCurrentlyOpen: status,
    manualOverride: true,
    overrideReason: reason,
    estimatedReopenTime: reopenTime,
    lastStatusChange: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// 手動オーバーライドを解除して自動状態に戻す
  OperationStatusModel clearManualOverride([DateTime? currentTime]) {
    final DateTime now = currentTime ?? DateTime.now();
    final bool automaticStatus = businessHours.isWithinOperatingHours(now);

    return copyWith(
      isCurrentlyOpen: automaticStatus,
      manualOverride: false,
      lastStatusChange: now,
      updatedAt: now,
    );
  }

  /// 営業状態の表示用文字列を取得
  String get displayStatus {
    if (manualOverride) {
      if (isCurrentlyOpen) {
        return overrideReason ?? "臨時営業";
      } else {
        return overrideReason ?? "臨時休業";
      }
    }

    return isCurrentlyOpen ? "営業中" : "営業時間外";
  }

  /// UIコンポーネントとの互換性のためのプロパティ
  /// 営業中かどうか（isCurrentlyOpenのエイリアス）
  bool get isOpen => isCurrentlyOpen;

  /// 手動オーバーライドが設定されているかどうか
  bool get hasManualOverride => manualOverride;

  /// 手動オーバーライドの理由（overrideReasonのエイリアス）
  String? get manualOverrideReason => overrideReason;

  /// 最終更新日時（lastStatusChangeのエイリアス）
  DateTime? get lastUpdated => lastStatusChange;

  /// 営業時間の表示用文字列を取得
  String get displayHours => businessHours.displayHours;

  /// 営業状態に応じた色を取得（UI用）
  Color get statusColor {
    if (manualOverride) {
      return isCurrentlyOpen ? Colors.orange : Colors.red;
    }

    return isCurrentlyOpen ? Colors.green : Colors.grey;
  }

  /// 閉店までの分数を取得（営業中の場合）
  int? get minutesUntilClose {
    if (!isCurrentlyOpen) {
      return null;
    }

    try {
      final DateTime now = DateTime.now();
      final List<String> closeParts = businessHours.closeTime.split(":");
      final int closeHour = int.parse(closeParts[0]);
      final int closeMinute = int.parse(closeParts[1]);

      final DateTime closeTime = DateTime(now.year, now.month, now.day, closeHour, closeMinute);

      // 翌日の閉店時間の場合
      final DateTime adjustedCloseTime = closeTime.isBefore(now)
          ? closeTime.add(const Duration(days: 1))
          : closeTime;

      final Duration difference = adjustedCloseTime.difference(now);
      return difference.inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// 開店までの分数を取得（営業時間外の場合）
  int? get minutesUntilOpen {
    if (isCurrentlyOpen) {
      return null;
    }

    try {
      final DateTime now = DateTime.now();
      final List<String> openParts = businessHours.openTime.split(":");
      final int openHour = int.parse(openParts[0]);
      final int openMinute = int.parse(openParts[1]);

      DateTime openTime = DateTime(now.year, now.month, now.day, openHour, openMinute);

      // 過去の時間の場合は翌日の開店時間
      if (openTime.isBefore(now)) {
        openTime = openTime.add(const Duration(days: 1));
      }

      final Duration difference = openTime.difference(now);
      return difference.inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// 詳細な営業状態説明を取得
  String get detailedStatusDescription {
    if (manualOverride) {
      if (isCurrentlyOpen) {
        final String reason = overrideReason ?? "臨時営業";
        return "🟠 $reason中";
      } else {
        final String reason = overrideReason ?? "臨時休業";
        String description = "🔴 $reason中";

        if (estimatedReopenTime != null) {
          final String reopenTimeStr =
              "${estimatedReopenTime!.hour.toString().padLeft(2, '0')}:${estimatedReopenTime!.minute.toString().padLeft(2, '0')}";
          description += " (再開予定: $reopenTimeStr)";
        }

        return description;
      }
    }

    if (isCurrentlyOpen) {
      final int? minutesLeft = minutesUntilClose;
      if (minutesLeft != null) {
        if (minutesLeft <= 30) {
          return "🟡 営業中 (閉店まで$minutesLeft分)";
        } else {
          return "🟢 営業中 (${businessHours.displayHours})";
        }
      }
      return "🟢 営業中";
    } else {
      final int? minutesUntilOpenTime = minutesUntilOpen;
      if (minutesUntilOpenTime != null) {
        final int hours = minutesUntilOpenTime ~/ 60;
        final int minutes = minutesUntilOpenTime % 60;

        if (hours > 0) {
          return "⚪ 営業時間外 (開店まで$hours時間$minutes分)";
        } else {
          return "⚪ 営業時間外 (開店まで$minutes分)";
        }
      }
      return "⚪ 営業時間外";
    }
  }

  /// 営業状態に応じたアイコンを取得
  IconData get statusIcon {
    if (manualOverride) {
      return isCurrentlyOpen ? LucideIcons.zap : LucideIcons.alertTriangle;
    }
    return isCurrentlyOpen ? LucideIcons.checkCircle : LucideIcons.clock;
  }

  @override
  String toString() =>
      "OperationStatusModel(id: $id, isCurrentlyOpen: $isCurrentlyOpen, manualOverride: $manualOverride)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationStatusModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isCurrentlyOpen == other.isCurrentlyOpen &&
          manualOverride == other.manualOverride &&
          businessHours == other.businessHours;

  @override
  int get hashCode => Object.hash(id, isCurrentlyOpen, manualOverride, businessHours);
}
