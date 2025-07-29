import "package:flutter/material.dart";

import "../../core/constants/enums.dart";
import "../../features/order/models/order_model.dart";
import "../themes/app_colors.dart";

/// Order UI拡張
/// 既存のOrderモデルにUI表示用の拡張メソッドを追加
/// 注文状況画面やダッシュボードでの表示に特化
extension OrderUIExtensions on Order {
  /// ステータス表示文字列
  /// 日本語での注文ステータス表示
  String get statusDisplayText {
    switch (status) {
      case OrderStatus.pending:
        return "受付中";
      case OrderStatus.confirmed:
        return "確認済み";
      case OrderStatus.preparing:
        return "調理中";
      case OrderStatus.ready:
        return "提供準備完了";
      case OrderStatus.delivered:
        return "提供済み";
      case OrderStatus.completed:
        return "完了";
      case OrderStatus.cancelled:
        return "キャンセル";
      case OrderStatus.refunded:
        return "返金済み";
    }
  }

  /// ステータスに応じた色
  /// 注文状況に対応した視覚的フィードバック
  Color get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.preparing:
        return AppColors.cooking;
      case OrderStatus.ready:
        return AppColors.complete;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.danger;
      case OrderStatus.refunded:
        return AppColors.mutedForeground;
    }
  }

  /// ステータスアイコン
  /// 各注文状況に対応したアイコン
  IconData get statusIcon {
    switch (status) {
      case OrderStatus.pending:
        return Icons.access_time;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.kitchen;
      case OrderStatus.ready:
        return Icons.notifications_active;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.refunded:
        return Icons.money_off;
    }
  }

  /// 注文からの経過時間
  /// 現在時刻との差分を計算
  Duration get elapsedTime => DateTime.now().difference(orderedAt);

  /// 調理開始からの経過時間
  /// 調理開始時刻が設定されている場合のみ
  Duration? get preparingElapsedTime => startedPreparingAt != null ? DateTime.now().difference(startedPreparingAt!) : null;

  /// 提供準備完了からの経過時間
  /// 完成時刻が設定されている場合のみ
  Duration? get readyElapsedTime => readyAt != null ? DateTime.now().difference(readyAt!) : null;

  /// 経過時間の表示文字列
  /// 時間と分で表示（例：「1時間30分経過」）
  String get elapsedTimeDisplay {
    final Duration elapsed = elapsedTime;
    if (elapsed.inHours > 0) {
      return "${elapsed.inHours}時間${elapsed.inMinutes.remainder(60)}分経過";
    } else {
      return "${elapsed.inMinutes}分経過";
    }
  }

  /// 経過時間に応じた警告色
  /// 時間経過に応じた視覚的警告
  Color get elapsedTimeColor {
    final int minutes = elapsedTime.inMinutes;
    if (minutes > 30) {
      return AppColors.danger; // 30分超過：赤
    } else if (minutes > 20) {
      return AppColors.warning; // 20分超過：黄色
    } else {
      return AppColors.mutedForeground; // 通常：グレー
    }
  }

  /// 表示用合計金額
  /// 日本円表記でカンマ区切り
  String get formattedTotal {
    final String formattedNumber = totalAmount.toString().replaceAllMapped(
      RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
      (Match match) => "${match[1]},",
    );
    return "¥$formattedNumber";
  }

  /// 割引後金額の表示
  /// 割引額が0より大きい場合のみ表示
  String? get formattedDiscountedTotal {
    if (discountAmount > 0) {
      final int discountedTotal = totalAmount - discountAmount;
      final String formattedNumber = discountedTotal.toString().replaceAllMapped(
        RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
        (Match match) => "${match[1]},",
      );
      return "¥$formattedNumber";
    }
    return null;
  }

  /// 割引額の表示
  /// 割引が適用されている場合の表示文字列
  String? get formattedDiscount {
    if (discountAmount > 0) {
      final String formattedNumber = discountAmount.toString().replaceAllMapped(
        RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
        (Match match) => "${match[1]},",
      );
      return "-¥$formattedNumber";
    }
    return null;
  }

  /// 支払い方法の日本語表示
  /// PaymentMethodの日本語変換
  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return "現金";
      case PaymentMethod.card:
        return "カード";
      case PaymentMethod.other:
        return "その他";
    }
  }

  /// 支払い方法のアイコン
  /// 各支払い方法に対応したアイコン
  IconData get paymentMethodIcon {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return Icons.attach_money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.other:
        return Icons.payment;
    }
  }

  /// 優先度レベル
  /// 経過時間と注文状況から算出
  int get priorityLevel {
    final int minutes = elapsedTime.inMinutes;

    // キャンセル・完了済みは優先度なし
    if (status == OrderStatus.cancelled ||
        status == OrderStatus.completed ||
        status == OrderStatus.delivered) {
      return 0;
    }

    // 時間経過による優先度
    if (minutes > 30) return 3; // 高優先度
    if (minutes > 20) return 2; // 中優先度
    return 1; // 通常優先度
  }

  /// 優先度に応じた色
  /// 優先度レベルに対応した色分け
  Color get priorityColor {
    switch (priorityLevel) {
      case 3:
        return AppColors.danger;
      case 2:
        return AppColors.warning;
      case 1:
        return AppColors.primary;
      case 0:
      default:
        return AppColors.mutedForeground;
    }
  }

  /// 注文時刻の表示
  /// 時:分形式での表示
  String get orderedTimeDisplay => "${orderedAt.hour.toString().padLeft(2, "0")}:${orderedAt.minute.toString().padLeft(2, "0")}";

  /// 顧客名の表示
  /// nullの場合のフォールバック処理
  String get customerDisplayName => customerName ?? "お客様";

  /// カード表示用のサブタイトル
  /// 時刻と経過時間を組み合わせた表示
  String get cardSubtitle => "$orderedTimeDisplay • $elapsedTimeDisplay";

  /// リスト表示用の詳細情報
  /// より詳細な情報を1行で表示
  String get listDetailText => "$customerDisplayName • $formattedTotal • $orderedTimeDisplay";

  /// 進行状況の割合（0.0-1.0）
  /// 注文状況の進捗を数値で表現
  double get progressPercentage {
    switch (status) {
      case OrderStatus.pending:
        return 0.2;
      case OrderStatus.confirmed:
        return 0.4;
      case OrderStatus.preparing:
        return 0.6;
      case OrderStatus.ready:
        return 0.8;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 1.0;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return 0.0;
    }
  }

  /// アクセシビリティ用のセマンティクスラベル
  /// スクリーンリーダー対応の詳細説明
  String get semanticsLabel => "注文番号: ${orderNumber ?? "未設定"}, "
        "顧客: $customerDisplayName, "
        "状態: $statusDisplayText, "
        "金額: $formattedTotal, "
        "経過時間: $elapsedTimeDisplay";

  /// 緊急度の判定
  /// 長時間経過した注文の判定
  bool get isUrgent => priorityLevel >= 3;

  /// アクション可能かどうか
  /// 現在の状況でステータス変更可能かの判定
  bool get canTakeAction => status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready;
}
