import "package:flutter_test/flutter_test.dart";

import "package:yata/features/order/presentation/controllers/order_management_state.dart";

void main() {
  group("OrderManagementState cart lookup", () {
    const MenuItemViewData takoyaki = MenuItemViewData(
      id: "menu-takoyaki",
      name: "たこ焼き",
      categoryId: "cat-street",
      price: 600,
    );
    const MenuItemViewData ramen = MenuItemViewData(
      id: "menu-ramen",
      name: "ラーメン",
      categoryId: "cat-street",
      price: 800,
    );

    final CartItemViewData takoyakiCart = CartItemViewData(
      menuItem: takoyaki,
      quantity: 2,
      orderItemId: "order-item-1",
    );
    final CartItemViewData ramenCart = CartItemViewData(
      menuItem: ramen,
      quantity: 3,
      orderItemId: "order-item-2",
    );

    test("isInCart returns true only for existing menu ids", () {
      final OrderManagementState state = OrderManagementState(
        categories: const <MenuCategoryViewData>[],
        menuItems: const <MenuItemViewData>[takoyaki, ramen],
        cartItems: <CartItemViewData>[takoyakiCart, ramenCart],
      );

      expect(state.isInCart("menu-takoyaki"), isTrue);
      expect(state.isInCart("menu-ramen"), isTrue);
      expect(state.isInCart("menu-udon"), isFalse);
    });

    test("quantityFor returns quantity from cache and null when missing", () {
      final OrderManagementState state = OrderManagementState(
        categories: const <MenuCategoryViewData>[],
        menuItems: const <MenuItemViewData>[takoyaki, ramen],
        cartItems: <CartItemViewData>[takoyakiCart, ramenCart],
      );

      expect(state.quantityFor("menu-takoyaki"), equals(2));
      expect(state.quantityFor("menu-ramen"), equals(3));
      expect(state.quantityFor("menu-udon"), isNull);
    });

    test("copyWith updates lookup map when cartItems change", () {
      final OrderManagementState baseState = OrderManagementState(
        categories: const <MenuCategoryViewData>[],
        menuItems: const <MenuItemViewData>[takoyaki, ramen],
        cartItems: <CartItemViewData>[takoyakiCart, ramenCart],
      );

      final OrderManagementState nextState = baseState.copyWith(
        cartItems: <CartItemViewData>[takoyakiCart.copyWith(quantity: 5)],
      );

      expect(nextState.isInCart("menu-takoyaki"), isTrue);
      expect(nextState.quantityFor("menu-takoyaki"), equals(5));
      expect(nextState.isInCart("menu-ramen"), isFalse);
    });
  });
}
