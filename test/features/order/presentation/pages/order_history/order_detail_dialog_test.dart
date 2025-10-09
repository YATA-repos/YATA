import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/features/order/presentation/controllers/order_history_controller.dart";
import "package:yata/features/order/presentation/pages/order_history_page.dart";

OrderHistoryViewData _buildSampleOrder() => OrderHistoryViewData(
  id: "order-1",
  orderNumber: "A001",
  status: OrderStatus.inProgress,
  customerName: "山田太郎",
  totalAmount: 1200,
  discountAmount: 100,
  paymentMethod: PaymentMethod.cash,
  orderedAt: DateTime(2025, 10, 9, 12, 30),
  completedAt: null,
  notes: "辛め",
  items: const <OrderItemViewData>[
    OrderItemViewData(
      menuItemId: "menu-1",
      menuItemName: "焼きそば",
      quantity: 2,
      unitPrice: 500,
      subtotal: 1000,
    ),
  ],
);

Future<void> _pumpDialog(WidgetTester tester, {required VoidCallback onClose}) async {
  final OrderHistoryViewData order = _buildSampleOrder();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: createOrderDetailDialog(order: order, onClose: onClose),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group("_OrderDetailDialog", () {
    testWidgets("背景タップでonCloseが呼ばれる", (WidgetTester tester) async {
      int closeCount = 0;

      await _pumpDialog(
        tester,
        onClose: () {
          closeCount += 1;
        },
      );

      final Offset outsidePoint =
          tester.getTopLeft(find.byKey(const Key("orderDetailOverlay"))) + const Offset(10, 10);

      await tester.tapAt(outsidePoint);
      await tester.pumpAndSettle();

      expect(closeCount, 1);
    });

    testWidgets("ダイアログ本体のタップではonCloseが呼ばれない", (WidgetTester tester) async {
      int closeCount = 0;

      await _pumpDialog(
        tester,
        onClose: () {
          closeCount += 1;
        },
      );

      final Offset dialogCenter = tester.getCenter(
        find.byKey(const Key("orderDetailDialogSurface")),
      );

      await tester.tapAt(dialogCenter);
      await tester.pumpAndSettle();

      expect(closeCount, 0);
    });
  });
}
