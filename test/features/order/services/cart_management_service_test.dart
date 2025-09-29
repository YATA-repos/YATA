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
  }) => Order(
    id: id,
    userId: userId,
    totalAmount: 0,
    status: OrderStatus.inProgress,
    paymentMethod: paymentMethod,
    discountAmount: 0,
    orderedAt: DateTime(2025),
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
}
