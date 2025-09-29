import "package:flutter_test/flutter_test.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/features/order/models/order_model.dart";

void main() {
  group("Order", () {
    test("defaults isCart to false when field is absent", () {
      final Map<String, dynamic> json = <String, dynamic>{
        "id": "order-1",
        "user_id": "user-1",
        "total_amount": 5000,
        "status": OrderStatus.inProgress.value,
        "payment_method": PaymentMethod.cash.value,
        "discount_amount": 0,
        "ordered_at": DateTime(2025, 1, 1).toIso8601String(),
      };

      final Order order = Order.fromJson(json);

      expect(order.isCart, isFalse);
    });

    test("serializes and deserializes isCart flag", () {
      final Order order = Order(
        id: "order-2",
        userId: "user-1",
        totalAmount: 3200,
        status: OrderStatus.inProgress,
        paymentMethod: PaymentMethod.card,
        discountAmount: 0,
        orderedAt: DateTime(2025, 2, 2),
        isCart: true,
      );

      final Map<String, dynamic> json = order.toJson();

      expect(json["is_cart"], isTrue);
      final Order roundTrip = Order.fromJson(json);
      expect(roundTrip.isCart, isTrue);
    });
  });
}
