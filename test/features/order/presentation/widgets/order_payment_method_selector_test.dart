import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/features/order/presentation/widgets/order_payment_method_selector.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSelector(
    WidgetTester tester, {
    required PaymentMethod selected,
    required Future<void> Function(PaymentMethod) onChanged,
    bool isDisabled = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderPaymentMethodSelector(
            selected: selected,
            isDisabled: isDisabled,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  testWidgets("invokes callback when a different method is tapped", (WidgetTester tester) async {
    PaymentMethod? tapped;

    await pumpSelector(
      tester,
      selected: PaymentMethod.cash,
      onChanged: (PaymentMethod method) async {
        tapped = method;
      },
    );

    await tester.tap(find.text("カード"));
    await tester.pumpAndSettle();

    expect(tapped, PaymentMethod.card);
  });

  testWidgets("does not trigger callback when disabled", (WidgetTester tester) async {
    PaymentMethod? tapped;

    await pumpSelector(
      tester,
      selected: PaymentMethod.cash,
      isDisabled: true,
      onChanged: (PaymentMethod method) async {
        tapped = method;
      },
    );

    await tester.tap(find.text("カード"));
    await tester.pumpAndSettle();

    expect(tapped, isNull);
  });
}
