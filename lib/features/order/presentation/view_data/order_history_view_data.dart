import "package:flutter/material.dart";

import "../../../../core/constants/enums.dart";

/// 注文履歴画面や詳細表示で使用する注文の表示用データ。
@immutable
class OrderHistoryViewData {
  /// [OrderHistoryViewData]を生成する。
  const OrderHistoryViewData({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.totalAmount,
    required this.discountAmount,
    required this.paymentMethod,
    required this.orderedAt,
    required this.items,
    this.notes,
    this.completedAt,
  });

  /// 注文ID。
  final String id;

  /// 注文番号。
  final String? orderNumber;

  /// 注文ステータス。
  final OrderStatus status;

  /// 顧客名。
  final String? customerName;

  /// 合計金額。
  final int totalAmount;

  /// 割引額。
  final int discountAmount;

  /// 支払い方法。
  final PaymentMethod paymentMethod;

  /// 注文日時。
  final DateTime orderedAt;

  /// 注文明細。
  final List<OrderItemViewData> items;

  /// 備考。
  final String? notes;

  /// 完了日時。
  final DateTime? completedAt;

  /// 小計金額（割引前）。
  int get subtotal => totalAmount - discountAmount;

  /// 実際の支払い金額。
  int get actualAmount => totalAmount - discountAmount;
}

/// 注文明細の表示用データ。
@immutable
class OrderItemViewData {
  /// [OrderItemViewData]を生成する。
  const OrderItemViewData({
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.selectedOptions,
    this.specialRequest,
  });

  /// メニューアイテムID。
  final String menuItemId;

  /// メニューアイテム名。
  final String menuItemName;

  /// 数量。
  final int quantity;

  /// 単価。
  final int unitPrice;

  /// 小計。
  final int subtotal;

  /// 選択されたオプション。
  final Map<String, String>? selectedOptions;

  /// 特別リクエスト。
  final String? specialRequest;
}
