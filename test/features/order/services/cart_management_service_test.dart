import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/core/contracts/repositories/menu/menu_repository_contracts.dart";
import "package:yata/core/contracts/repositories/order/order_repository_contracts.dart";
import "package:yata/features/menu/models/menu_model.dart";
import "package:yata/features/order/models/order_model.dart";
import "package:yata/features/order/services/cart_management_service.dart";
import "package:yata/features/order/services/order_calculation_service.dart";
import "package:yata/features/order/services/order_stock_service.dart";

class _MockOrderRepository extends Mock implements OrderRepositoryContract<Order> {}

class _MockOrderItemRepository extends Mock implements OrderItemRepositoryContract<OrderItem> {}

class _MockMenuItemRepository extends Mock implements MenuItemRepositoryContract<MenuItem> {}

class _MockOrderCalculationService extends Mock implements OrderCalculationService {}

class _MockOrderStockService extends Mock implements OrderStockService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CartManagementService service;
  late _MockOrderRepository orderRepository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(
      Order(
        totalAmount: 0,
        status: OrderStatus.inProgress,
        paymentMethod: PaymentMethod.cash,
        discountAmount: 0,
        orderedAt: DateTime(2025),
      ),
    );
  });

  setUp(() {
    orderRepository = _MockOrderRepository();
    service = CartManagementService(
      orderRepository: orderRepository,
      orderItemRepository: _MockOrderItemRepository(),
      menuItemRepository: _MockMenuItemRepository(),
      orderCalculationService: _MockOrderCalculationService(),
      orderStockService: _MockOrderStockService(),
    );
  });

  Order buildOrder({
    String id = "order-1",
    String userId = "user-1",
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? orderNumber,
    bool isCart = true,
  }) => Order(
    id: id,
    userId: userId,
    totalAmount: 0,
    status: OrderStatus.inProgress,
    paymentMethod: paymentMethod,
    discountAmount: 0,
    orderedAt: DateTime(2025),
    isCart: isCart,
    orderNumber: orderNumber,
  );

  group("updateCartPaymentMethod", () {
    test("updates payment method and returns updated order", () async {
      final Order existing = buildOrder();
      final Order updated = buildOrder(paymentMethod: PaymentMethod.card);
      final Map<String, dynamic> capturedPayload = <String, dynamic>{};

      when(() => orderRepository.getById(existing.id!)).thenAnswer((_) async => existing);
      when(() => orderRepository.updateById(existing.id!, any())).thenAnswer((Invocation invocation) async {
        capturedPayload
          ..clear()
          ..addAll(invocation.positionalArguments[1] as Map<String, dynamic>);
        return updated;
      });

      final Order? result = await service.updateCartPaymentMethod(
        existing.id!,
        PaymentMethod.card,
        existing.userId!,
      );

      expect(result, equals(updated));
      expect(capturedPayload["payment_method"], equals(PaymentMethod.card.value));
      expect(capturedPayload.containsKey("updated_at"), isTrue);
      verify(() => orderRepository.getById(existing.id!)).called(1);
      verify(() => orderRepository.updateById(existing.id!, any())).called(1);
      verifyNoMoreInteractions(orderRepository);
    });

    test("throws when cart does not belong to user", () async {
  final Order existing = buildOrder(userId: "other-user");

      when(() => orderRepository.getById(existing.id!)).thenAnswer((_) async => existing);

      expect(
        () => service.updateCartPaymentMethod(existing.id!, PaymentMethod.card, "user-1"),
        throwsException,
      );
      verify(() => orderRepository.getById(existing.id!)).called(1);
      verifyNever(() => orderRepository.updateById(any(), any()));
    });
  });

  group("getActiveCart", () {
    test("assigns display code when active cart lacks code", () async {
      final Order cart = buildOrder(id: "cart-missing", orderNumber: null);

      when(() => orderRepository.findActiveDraftByUser("user-1")).thenAnswer((_) async => cart);
      when(() => orderRepository.generateNextOrderNumber()).thenAnswer((_) async => "CD34");

      final List<Map<String, dynamic>> capturedPayloads = <Map<String, dynamic>>[];
      when(() => orderRepository.updateById(cart.id!, any())).thenAnswer((Invocation invocation) async {
        final Map<String, dynamic> payload = invocation.positionalArguments[1] as Map<String, dynamic>;
        capturedPayloads.add(payload);
        return buildOrder(id: cart.id!, userId: cart.userId!, orderNumber: "CD34");
      });

      final Order? result = await service.getActiveCart("user-1");

      expect(result, isNotNull);
      expect(result!.orderNumber, equals("CD34"));
      expect(capturedPayloads, hasLength(1));
      expect(capturedPayloads.first["order_number"], equals("CD34"));
      verify(() => orderRepository.findActiveDraftByUser("user-1")).called(1);
      verify(() => orderRepository.generateNextOrderNumber()).called(1);
      verify(() => orderRepository.updateById(cart.id!, any())).called(1);
    });

    test("returns existing cart without regenerating code", () async {
      final Order cart = buildOrder(id: "cart-coded", orderNumber: "EF56");

      when(() => orderRepository.findActiveDraftByUser("user-1")).thenAnswer((_) async => cart);

      final Order? result = await service.getActiveCart("user-1");

      expect(result, isNotNull);
      expect(result!.orderNumber, equals("EF56"));
      verify(() => orderRepository.findActiveDraftByUser("user-1")).called(1);
      verifyNever(() => orderRepository.generateNextOrderNumber());
      verifyNever(() => orderRepository.updateById(any(), any()));
    });
  });

  group("getOrCreateActiveCart", () {
    test("creates new cart with isCart flag set", () async {
      when(() => orderRepository.findActiveDraftByUser("user-1")).thenAnswer((_) async => null);
      when(() => orderRepository.generateNextOrderNumber()).thenAnswer((_) async => "AB12");

      Order? capturedOrder;
      when(() => orderRepository.create(any())).thenAnswer((Invocation invocation) async {
        capturedOrder = invocation.positionalArguments[0] as Order;
        return capturedOrder;
      });

      final Order? result = await service.getOrCreateActiveCart("user-1");

      expect(result, isNotNull);
      expect(result!.isCart, isTrue);
      expect(result.orderNumber, equals("AB12"));
      expect(capturedOrder, isNotNull);
      expect(capturedOrder!.isCart, isTrue);
      expect(capturedOrder!.orderNumber, equals("AB12"));
      verify(() => orderRepository.findActiveDraftByUser("user-1")).called(1);
      verify(() => orderRepository.generateNextOrderNumber()).called(1);
      verify(() => orderRepository.create(any())).called(1);
      verifyNever(() => orderRepository.updateById(any(), any()));
    });
  });
}
