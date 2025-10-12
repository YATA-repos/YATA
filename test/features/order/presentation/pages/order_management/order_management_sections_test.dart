import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/features/order/presentation/controllers/order_management_controller.dart";
import "package:yata/features/order/presentation/controllers/order_management_state.dart";
import "package:yata/features/order/presentation/widgets/order_management/current_order_section.dart";
import "package:yata/features/order/presentation/widgets/order_management/menu_selection_section.dart";
import "package:yata/features/order/presentation/widgets/order_payment_method_selector.dart";
import "package:yata/shared/components/inputs/quantity_stepper.dart";

void main() {
  group("MenuSelectionSection", () {
    testWidgets("displays empty result message when no menu items", (WidgetTester tester) async {
      final TextEditingController searchController = TextEditingController();
      addTearDown(searchController.dispose);

      final OrderManagementState state = OrderManagementState(
        categories: const <MenuCategoryViewData>[MenuCategoryViewData(id: "all", label: "すべて")],
        menuItems: const <MenuItemViewData>[],
        cartItems: const <CartItemViewData>[],
      );

      String? capturedQuery;
      int? capturedCategoryIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuSelectionSection(
              state: state,
              searchController: searchController,
              onSearchQueryChanged: (String value) => capturedQuery = value,
              onSelectCategory: (int index) => capturedCategoryIndex = index,
              onUpdateItemQuantity: (_, __) {},
              onAddMenuItem: (_) {},
            ),
          ),
        ),
      );

      expect(find.text("メニューが見つかりません"), findsOneWidget);

      await tester.enterText(find.byType(TextField), "ラーメン");
      await tester.pump();
      expect(capturedQuery, "ラーメン");

      await tester.tap(find.text("すべて"));
      await tester.pump();
      expect(capturedCategoryIndex, 0);
    });
  });

  group("CurrentOrderSection", () {
    testWidgets("invokes callbacks for primary interactions", (WidgetTester tester) async {
      final MenuItemViewData menuItem = MenuItemViewData(
        id: "m1",
        name: "特製カレー",
        categoryId: "cat",
        price: 1200,
      );
      final CartItemViewData cartItem = CartItemViewData(menuItem: menuItem, quantity: 1);
      final OrderManagementState state = OrderManagementState(
        categories: const <MenuCategoryViewData>[MenuCategoryViewData(id: "all", label: "すべて")],
        menuItems: <MenuItemViewData>[menuItem],
        cartItems: <CartItemViewData>[cartItem],
        orderNumber: "A-10",
      );

      bool notesChanged = false;
      bool cartCleared = false;
      bool checkoutInvoked = false;
      bool quantityUpdated = false;
      bool itemRemoved = false;
      bool paymentChanged = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrderSection(
              state: state,
              onUpdateItemQuantity: (_, __) => quantityUpdated = true,
              onRemoveItem: (_) => itemRemoved = true,
              onPaymentMethodChanged: (PaymentMethod _) async {
                paymentChanged = true;
              },
              onOrderNotesChanged: (_) => notesChanged = true,
              onClearCart: () => cartCleared = true,
              onCheckout: () async {
                checkoutInvoked = true;
                return CheckoutActionResult.emptyCart(message: "empty");
              },
            ),
          ),
        ),
      );

      expect(find.text("特製カレー"), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, "メモ"), "辛さ普通");
      await tester.pump();
      expect(notesChanged, isTrue);

      await tester.tap(find.text("クリア"));
      await tester.pump();
      expect(cartCleared, isTrue);

      await tester.tap(find.byTooltip("削除"));
      await tester.pump();
      expect(itemRemoved, isTrue);

      final OrderPaymentMethodSelector selector = tester.widget<OrderPaymentMethodSelector>(
        find.byType(OrderPaymentMethodSelector),
      );
      await selector.onChanged(PaymentMethod.paypay);
      expect(paymentChanged, isTrue);

      await tester.tap(find.text("会計"));
      await tester.pump();
      expect(checkoutInvoked, isTrue);

      // Trigger quantity update via stepper interaction.
      final Finder incrementButton = find.descendant(
        of: find.byType(YataQuantityStepper),
        matching: find.byIcon(Icons.add),
      );
      if (incrementButton.evaluate().isNotEmpty) {
        await tester.tap(incrementButton);
        await tester.pump();
      }
      expect(quantityUpdated, isTrue);
    });
  });
}
