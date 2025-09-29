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
  late Order existingOrder;

  setUpAll(() {
    registerFallbackValue(MenuCategory(name: "", displayOrder: 0));
  });

  setUp(() {
    menuService = _MockMenuService();
    cartService = _MockCartService();
    orderService = _MockOrderService();

    existingOrder = Order(
      id: "order-1",
      userId: "user-123",
      totalAmount: 0,
      status: OrderStatus.inProgress,
      paymentMethod: PaymentMethod.card,
      discountAmount: 0,
      orderedAt: DateTime(2025),
    );

    when(() => menuService.getMenuCategories()).thenAnswer((_) async => <MenuCategory>[]);
    when(() => menuService.getMenuItemsByCategory(any())).thenAnswer((_) async => <MenuItem>[]);
    when(() => cartService.getActiveCart("user-123")).thenAnswer((_) async => existingOrder);
    when(() => cartService.getOrCreateActiveCart("user-123"))
        .thenAnswer((_) async => existingOrder);
    when(() => orderService.getOrderWithItems(existingOrder.id!, "user-123")).thenAnswer(
      (_) async => <String, dynamic>{
        "order": existingOrder,
        "items": <Map<String, dynamic>>[],
      },
    );

    container = ProviderContainer(overrides: <Override>[
      currentUserIdProvider.overrideWith((Ref ref) => "user-123"),
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
          existingOrder.id!,
          PaymentMethod.other,
          existingOrder.userId!,
        ),
      ).thenAnswer((_) async => existingOrder);

      final OrderManagementController controller = await createController();

      expect(controller.state.currentPaymentMethod, PaymentMethod.card);

      await controller.updatePaymentMethod(PaymentMethod.other);

      expect(controller.state.currentPaymentMethod, PaymentMethod.other);
      expect(controller.state.errorMessage, isNull);
      verify(
        () => cartService.updateCartPaymentMethod(
          existingOrder.id!,
          PaymentMethod.other,
          existingOrder.userId!,
        ),
      ).called(1);
    });

    test("reverts selection and surfaces error on failure", () async {
      when(
        () => cartService.updateCartPaymentMethod(
          existingOrder.id!,
          PaymentMethod.other,
          existingOrder.userId!,
        ),
      ).thenThrow(Exception("network failure"));

      final OrderManagementController controller = await createController();
      final PaymentMethod previous = controller.state.currentPaymentMethod;

      await controller.updatePaymentMethod(PaymentMethod.other);

      expect(controller.state.currentPaymentMethod, previous);
      expect(controller.state.errorMessage, isNotNull);
      verify(
        () => cartService.updateCartPaymentMethod(
          existingOrder.id!,
          PaymentMethod.other,
          existingOrder.userId!,
        ),
      ).called(1);
    });
  });
}
