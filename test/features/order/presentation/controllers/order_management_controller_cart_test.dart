import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/app/wiring/provider.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/core/contracts/logging/logger.dart" as log_contract;
import "package:yata/core/logging/levels.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/auth/services/auth_service.dart";
import "package:yata/features/menu/models/menu_model.dart";
import "package:yata/features/menu/services/menu_service.dart";
import "package:yata/features/order/models/order_model.dart";
import "package:yata/features/order/presentation/controllers/order_management_controller.dart";
import "package:yata/features/order/presentation/controllers/order_management_state.dart";
import "package:yata/features/order/services/cart_management_service.dart";
import "package:yata/features/order/services/models/cart_snapshot.dart";
import "package:yata/features/order/services/order_service.dart";

final DateTime _testDate = DateTime.parse("2025-01-01T00:00:00Z");

class _MockMenuService extends Mock implements MenuService {}

class _MockCartManagementService extends Mock implements CartManagementService {}

class _MockOrderService extends Mock implements OrderService {}

class _MockAuthService extends Mock implements AuthService {}

class _NoopLogger extends log_contract.LoggerContract {
  @override
  void clearFatalHandlers() {}

  @override
  Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)}) async {}

  @override
  void log(
    Level level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  }) {}

  @override
  void registerFatalHandler(log_contract.FatalHandler handler) {}

  @override
  void removeFatalHandler(log_contract.FatalHandler handler) {}
}

Order _buildOrder({required String id}) => Order(
      id: id,
      userId: "user-123",
      totalAmount: 0,
      status: OrderStatus.inProgress,
      paymentMethod: PaymentMethod.cash,
      discountAmount: 0,
  orderedAt: _testDate,
      isCart: true,
      orderNumber: "ORDER-1",
    );

OrderItem _buildOrderItem({
  required String id,
  required String orderId,
  required String menuItemId,
  required int quantity,
  required int unitPrice,
}) => OrderItem(
      id: id,
      orderId: orderId,
      menuItemId: menuItemId,
      quantity: quantity,
      unitPrice: unitPrice,
      subtotal: unitPrice * quantity,
  createdAt: _testDate,
      userId: "user-123",
    );

MenuItem _buildMenuItem({
  required String id,
  required String name,
  required String categoryId,
  required int price,
}) => MenuItem(
      id: id,
      name: name,
      categoryId: categoryId,
      price: price,
      isAvailable: true,
      displayOrder: 0,
      userId: "user-123",
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late OrderManagementController controller;
  late _MockMenuService menuService;
  late _MockCartManagementService cartService;
  late _MockOrderService orderService;
  late _MockAuthService authService;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() async {
    menuService = _MockMenuService();
    cartService = _MockCartManagementService();
    orderService = _MockOrderService();
    authService = _MockAuthService();

    when(() => menuService.getMenuCategories()).thenAnswer((Invocation _) async => <MenuCategory>[]);
  when(() => menuService.getMenuItemsByCategory(any<String?>()))
        .thenAnswer((Invocation _) async => <MenuItem>[]);
  when(() => cartService.getActiveCart(any<String>()))
        .thenAnswer((Invocation _) async => null);
    when(() => authService.ensureSupabaseSessionReady(timeout: any(named: "timeout")))
        .thenAnswer((Invocation _) async {});
    when(() => authService.isSupabaseSessionReady).thenReturn(true);

    container = ProviderContainer(overrides: <Override>[
      currentUserIdProvider.overrideWith((Ref _) => "user-123"),
      menuServiceProvider.overrideWithValue(menuService),
      cartManagementServiceProvider.overrideWithValue(cartService),
      orderServiceProvider.overrideWithValue(orderService),
      authServiceProvider.overrideWithValue(authService),
      loggerProvider.overrideWithValue(_NoopLogger()),
    ]);
    addTearDown(container.dispose);

    controller = container.read(orderManagementControllerProvider.notifier);
    await pumpEventQueue();
  });

  test("updateItemQuantity removes item when quantity is zero", () async {
    const MenuItemViewData viewData = MenuItemViewData(
      id: "menu-takoyaki",
      name: "たこ焼き",
      categoryId: "cat-street",
      price: 600,
    );
    final CartItemViewData cartView = CartItemViewData(
      menuItem: viewData,
      quantity: 2,
      orderItemId: "order-item-1",
    );

    controller.state = OrderManagementState(
      categories: const <MenuCategoryViewData>[],
      menuItems: const <MenuItemViewData>[viewData],
      cartItems: <CartItemViewData>[cartView],
      cartId: "cart-1",
      highlightedItemId: "menu-takoyaki",
    );

    final CartMutationResult removalResult = CartMutationResult(
      kind: CartMutationKind.remove,
      snapshot: CartSnapshotData(
        order: _buildOrder(id: "cart-1"),
        orderItems: const <OrderItem>[],
        menuItems: <MenuItem>[_buildMenuItem(
          id: "menu-takoyaki",
          name: "たこ焼き",
          categoryId: "cat-street",
          price: 600,
        )],
      ),
    );

    when(() => cartService.removeItemFromCart("cart-1", "order-item-1", "user-123"))
        .thenAnswer((Invocation _) async => removalResult);

    clearInteractions(cartService);

    controller.updateItemQuantity("menu-takoyaki", 0);
    await pumpEventQueue();

    expect(controller.state.cartItems, isEmpty);
    expect(controller.state.highlightedItemId, isNull);
    verify(() => cartService.removeItemFromCart("cart-1", "order-item-1", "user-123"))
        .called(1);
  });

  test("updateItemQuantity surfaces stock warning from service", () async {
    const MenuItemViewData viewData = MenuItemViewData(
      id: "menu-ramen",
      name: "ラーメン",
      categoryId: "cat-street",
      price: 800,
    );
    final CartItemViewData cartView = CartItemViewData(
      menuItem: viewData,
      quantity: 1,
      orderItemId: "order-item-2",
    );

    controller.state = OrderManagementState(
      categories: const <MenuCategoryViewData>[],
      menuItems: const <MenuItemViewData>[viewData],
      cartItems: <CartItemViewData>[cartView],
      cartId: "cart-1",
    );

    final CartMutationResult mutationResult = CartMutationResult(
      kind: CartMutationKind.update,
      snapshot: CartSnapshotData(
        order: _buildOrder(id: "cart-1"),
        orderItems: <OrderItem>[
          _buildOrderItem(
            id: "order-item-2",
            orderId: "cart-1",
            menuItemId: "menu-ramen",
            quantity: 5,
            unitPrice: 800,
          ),
        ],
        menuItems: <MenuItem>[_buildMenuItem(
          id: "menu-ramen",
          name: "ラーメン",
          categoryId: "cat-street",
          price: 800,
        )],
      ),
      stockStatus: const <String, bool>{"menu-ramen": false},
    );

    when(() => cartService.updateCartItemQuantity("cart-1", "order-item-2", 5, "user-123"))
        .thenAnswer((Invocation _) async => mutationResult);

    clearInteractions(cartService);

    controller.updateItemQuantity("menu-ramen", 5);
    await pumpEventQueue();

    expect(controller.state.cartItems.single.quantity, 5);
    expect(
      controller.state.errorMessage,
      "在庫が不足している商品があります。数量を調整して再度お試しください。",
    );
    verify(() => cartService.updateCartItemQuantity("cart-1", "order-item-2", 5, "user-123"))
        .called(1);
  });
}
