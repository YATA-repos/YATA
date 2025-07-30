import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/logging/logger_mixin.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "../repositories/order_item_repository.dart";

/// 注文金額計算サービス
class OrderCalculationService with LoggerMixin {
  OrderCalculationService({
    required Ref ref,
    OrderItemRepository? orderItemRepository,
  }) : _orderItemRepository = orderItemRepository ?? OrderItemRepository(ref: ref);

  final OrderItemRepository _orderItemRepository;

  @override
  String get loggerComponent => "OrderCalculationService";

  /// 注文の金額を計算
  Future<OrderCalculationResult> calculateOrderTotal(
    String orderId, {
    int discountAmount = 0,
  }) async {
    logDebug("Calculating order total for order: $orderId, discount: $discountAmount");

    try {
      final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);

      logDebug("Retrieved ${orderItems.length} items for calculation");

      // 小計の計算
      final int subtotal = orderItems.fold(0, (int sum, OrderItem item) => sum + item.subtotal);

      // 税率（8%と仮定）
      const double taxRate = 0.08;
      final int taxAmount = (subtotal * taxRate).round();

      // 合計金額の計算
      final int totalAmount = subtotal + taxAmount - discountAmount;

      logDebug("Order total calculated: subtotal=$subtotal, tax=$taxAmount, total=$totalAmount");

      return OrderCalculationResult(
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount > 0 ? totalAmount : 0, // マイナスにならないように
      );
    } catch (e, stackTrace) {
      logError("Failed to calculate order total", e, stackTrace);
      rethrow;
    }
  }

  /// カートの金額を計算（注文計算と同じロジック）
  Future<OrderCalculationResult> calculateCartTotal(String cartId, {int discountAmount = 0}) async {
    logDebug("Calculating cart total with discount: $discountAmount");
    return calculateOrderTotal(cartId, discountAmount: discountAmount);
  }

  /// カートの合計金額を更新（DBに保存）
  Future<int> updateCartTotal(String cartId) async {
    logDebug("Updating cart total in database");

    try {
      final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);
      final int totalAmount = cartItems.fold(0, (int sum, OrderItem item) => sum + item.subtotal);

      logDebug("Cart total updated: $totalAmount");
      return totalAmount;
    } catch (e, stackTrace) {
      logError("Failed to update cart total", e, stackTrace);
      rethrow;
    }
  }

  /// アイテムの小計を計算
  int calculateItemSubtotal(int unitPrice, int quantity) {
    final int subtotal = unitPrice * quantity;
    logDebug(
      "Item subtotal calculated: unitPrice=$unitPrice, quantity=$quantity, subtotal=$subtotal",
    );
    return subtotal;
  }

  /// 税額を計算
  int calculateTaxAmount(int subtotal, {double taxRate = 0.08}) {
    final int taxAmount = (subtotal * taxRate).round();
    logDebug("Tax amount calculated: subtotal=$subtotal, rate=$taxRate, tax=$taxAmount");
    return taxAmount;
  }
}
