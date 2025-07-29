import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../core/constants/enums.dart";
import "../../../shared/themes/app_colors.dart";
import "order_model.dart";

/// OrderモデルのUI拡張
/// MockOrderで使用されていた便利なプロパティとメソッドを提供
extension OrderUIExtensions on Order {
  /// 注文時からの経過時間を取得
  Duration get elapsedTime => DateTime.now().difference(orderedAt);

  /// 調理開始からの経過時間を取得
  Duration? get preparingTime =>
      startedPreparingAt != null ? DateTime.now().difference(startedPreparingAt!) : null;

  /// 準備完了からの経過時間を取得
  Duration? get readyTime => readyAt != null ? DateTime.now().difference(readyAt!) : null;

  /// 注文ステータスに応じた色を取得
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

  /// 注文ステータスのテキストを取得
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return "待機中";
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

  /// ステータスアイコンを取得
  IconData get statusIcon {
    switch (status) {
      case OrderStatus.pending:
        return LucideIcons.clock;
      case OrderStatus.confirmed:
        return LucideIcons.checkCircle;
      case OrderStatus.preparing:
        return LucideIcons.chefHat;
      case OrderStatus.ready:
        return LucideIcons.bellRing;
      case OrderStatus.delivered:
        return LucideIcons.check;
      case OrderStatus.completed:
        return LucideIcons.checkCircle2;
      case OrderStatus.cancelled:
        return LucideIcons.x;
      case OrderStatus.refunded:
        return LucideIcons.arrowLeft;
    }
  }

  /// 優先度を取得（時間経過に基づく）
  int get priority {
    final int elapsed = elapsedTime.inMinutes;
    if (elapsed > 20) {
      return 3; // 高優先度
    }
    if (elapsed > 10) {
      return 2; // 中優先度
    }
    return 1; // 通常優先度
  }

  /// 注文番号を表示用にフォーマット
  String get displayOrderNumber => orderNumber ?? id ?? "???";

  /// 顧客名を表示用にフォーマット（未設定の場合はデフォルト値）
  String get displayCustomerName => customerName ?? "お客様";

  /// 合計金額を表示用にフォーマット
  String get formattedTotalAmount => "¥${totalAmount.toStringAsFixed(0)}";

  /// 時刻をフォーマット（HH:mm形式）
  String formatTime(DateTime dateTime) =>
      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

  /// 経過時間をフォーマット
  String formatElapsedTime(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
    } else {
      return "${duration.inMinutes}分経過";
    }
  }

  /// 経過時間の色を取得
  Color getElapsedTimeColor(Duration duration) {
    if (duration.inMinutes > 20) {
      return AppColors.danger; // 20分超過: 赤
    } else if (duration.inMinutes > 10) {
      return AppColors.warning; // 10分超過: 黄
    } else {
      return AppColors.mutedForeground; // 通常: グレー
    }
  }

  /// ステータスが進行中かどうかを判定
  bool get isActive => status.isActive;

  /// ステータスが完了しているかどうかを判定
  bool get isFinished => status.isFinished;
}

/// OrderItemの表示用拡張
extension OrderItemUIExtensions on OrderItem {
  /// 特別リクエストがあるかどうか
  bool get hasSpecialRequest => specialRequest != null && specialRequest!.isNotEmpty;

  /// オプションがあるかどうか
  bool get hasOptions => selectedOptions != null && selectedOptions!.isNotEmpty;

  /// 小計を表示用にフォーマット
  String get formattedSubtotal => "¥${subtotal.toStringAsFixed(0)}";

  /// 単価を表示用にフォーマット
  String get formattedUnitPrice => "¥${unitPrice.toStringAsFixed(0)}";
}

/// 注文一覧の表示用データクラス
class OrderWithItems {
  const OrderWithItems({required this.order, required this.items});

  final Order order;
  final List<OrderItem> items;

  /// 注文アイテムの名前リスト（MockOrderとの互換性のため）
  List<String> get itemNames => items.map((OrderItem item) => "アイテム${item.menuItemId}").toList();

  /// 注文アイテム数
  int get itemCount => items.length;

  /// 総数量
  int get totalQuantity => items.fold(0, (int sum, OrderItem item) => sum + item.quantity);
}
