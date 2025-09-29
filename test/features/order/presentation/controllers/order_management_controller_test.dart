import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/app/wiring/provider.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/menu/models/menu_model.dart";
import "package:yata/features/menu/services/menu_service.dart";
import "package:yata/features/order/models/order_model.dart";
import "package:yata/features/order/presentation/controllers/order_management_controller.dart";
import "package:yata/features/order/services/cart_service.dart";
import "package:yata/features/order/services/order_service.dart";

class _MockMenuService extends Mock implements MenuService {}

class _MockCartService extends Mock implements CartService {}

class _MockOrderService extends Mock implements OrderService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockMenuService menuService;
  late _MockCartService cartService;
  late _MockOrderService orderService;
  late ProviderContainer container;
  late Order orderUser123;
  late Order orderUser456;
  late String? testUserId;

  setUpAll(() {
    registerFallbackValue(MenuCategory(name: "", displayOrder: 0));
  });

  setUp(() {
    menuService = _MockMenuService();
    cartService = _MockCartService();
    orderService = _MockOrderService();
    testUserId = "user-123";

    orderUser123 = Order(
      id: "order-1",
      userId: "user-123",
      totalAmount: 0,
      status: OrderStatus.inProgress,
      paymentMethod: PaymentMethod.card,
      discountAmount: 0,
      orderedAt: DateTime(2025),
    );

    orderUser456 = Order(
      id: "order-2",
      userId: "user-456",
      totalAmount: 0,
      status: OrderStatus.inProgress,
      paymentMethod: PaymentMethod.cash,
      discountAmount: 0,
      orderedAt: DateTime(2025, 6, 15),
    );

    when(() => menuService.getMenuCategories()).thenAnswer((_) async => <MenuCategory>[]);
    when(() => menuService.getMenuItemsByCategory(any())).thenAnswer((_) async => <MenuItem>[]);
    when(() => cartService.getActiveCart(any()))
        .thenAnswer((Invocation invocation) async {
      final String userId = invocation.positionalArguments.first as String;
      if (userId == "user-123") {
        return orderUser123;
      }
      if (userId == "user-456") {
        return orderUser456;
      }
      return null;
    });
    when(() => cartService.getOrCreateActiveCart(any()))
        .thenAnswer((Invocation invocation) async {
      final String userId = invocation.positionalArguments.first as String;
      if (userId == "user-123") {
        return orderUser123;
      }
      if (userId == "user-456") {
        return orderUser456;
      }
      return null;
    });
    when(() => orderService.getOrderWithItems(any(), any())).thenAnswer(
      (Invocation invocation) async {
        final String orderId = invocation.positionalArguments[0] as String;
        final String userId = invocation.positionalArguments[1] as String;
        if (userId == "user-123" && orderId == orderUser123.id) {
          return <String, dynamic>{
            "order": orderUser123,
            "items": <Map<String, dynamic>>[],
          };
        }
        if (userId == "user-456" && orderId == orderUser456.id) {
          return <String, dynamic>{
            "order": orderUser456,
            "items": <Map<String, dynamic>>[],
          };
        }
        return null;
      },
    );

    container = ProviderContainer(overrides: <Override>[
      currentUserIdProvider.overrideWith((Ref ref) => testUserId),
      menuServiceProvider.overrideWith((Ref ref) => menuService),
      cartServiceProvider.overrideWith((Ref ref) => cartService),
      orderServiceProvider.overrideWith((Ref ref) => orderService),
    ]);
  });

  tearDown(() => container.dispose());

  Future<OrderManagementController> createController() async {
    final OrderManagementController controller =
        container.read(orderManagementControllerProvider.notifier);
    await controller.loadInitialData();
    return controller;
  }

  group("updatePaymentMethod", () {
    test("updates state and persists selection", () async {
      when(
        () => cartService.updateCartPaymentMethod(
          orderUser123.id!,
          PaymentMethod.other,
          orderUser123.userId!,
        ),
      ).thenAnswer((_) async => orderUser123);

      final OrderManagementController controller = await createController();

      expect(controller.state.currentPaymentMethod, PaymentMethod.card);

      await controller.updatePaymentMethod(PaymentMethod.other);

      expect(controller.state.currentPaymentMethod, PaymentMethod.other);
      expect(controller.state.errorMessage, isNull);
      verify(
        () => cartService.updateCartPaymentMethod(
          orderUser123.id!,
          PaymentMethod.other,
          orderUser123.userId!,
        ),
      ).called(1);
    });

    test("reverts selection and surfaces error on failure", () async {
      when(
        () => cartService.updateCartPaymentMethod(
          orderUser123.id!,
          PaymentMethod.other,
          orderUser123.userId!,
        ),
      ).thenThrow(Exception("network failure"));

      final OrderManagementController controller = await createController();
      final PaymentMethod previous = controller.state.currentPaymentMethod;

      await controller.updatePaymentMethod(PaymentMethod.other);

      expect(controller.state.currentPaymentMethod, previous);
      expect(controller.state.errorMessage, isNotNull);
      verify(
        () => cartService.updateCartPaymentMethod(
          orderUser123.id!,
          PaymentMethod.other,
          orderUser123.userId!,
        ),
      ).called(1);
    });
  });

  group("user context transitions", () {
    test("clears local state when user logs out", () async {
      final OrderManagementController controller = await createController();

      controller.state = controller.state.copyWith(
        cartItems: <CartItemViewData>[
          CartItemViewData(
            menuItem: const MenuItemViewData(
              id: "menu-1",
              name: "テスト商品",
              categoryId: "cat-1",
              price: 500,
            ),
            quantity: 2,
          ),
        ],
        isLoading: false,
      );

      expect(controller.state.cartItems, isNotEmpty);

      testUserId = null;
      container.refresh(currentUserIdProvider);
      await pumpEventQueue();

      expect(controller.state.cartItems, isEmpty);
      expect(controller.state.isLoading, isTrue);
    });

    test("reloads cart when a different user signs in", () async {
      final OrderManagementController controller = await createController();

      testUserId = null;
      container.refresh(currentUserIdProvider);
      await pumpEventQueue();

      testUserId = "user-456";
      container.refresh(currentUserIdProvider);
      await pumpEventQueue(times: 5);

      expect(controller.state.cartId, orderUser456.id);
      expect(controller.state.currentPaymentMethod, orderUser456.paymentMethod);
      verify(() => cartService.getActiveCart("user-456")).called(greaterThanOrEqualTo(1));
    });
  });
}
