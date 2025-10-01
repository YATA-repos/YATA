import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/core/contracts/repositories/menu/menu_repository_contracts.dart";
import "package:yata/core/contracts/repositories/order/order_repository_contracts.dart";
import "package:yata/features/menu/models/menu_model.dart";
import "package:yata/features/order/dto/order_dto.dart";
import "package:yata/features/order/models/order_model.dart";
import "package:yata/features/order/services/cart_management_service.dart";
import "package:yata/features/order/services/order_calculation_service.dart";
import "package:yata/features/order/services/order_management_service.dart";
import "package:yata/features/order/services/order_stock_service.dart";

class _MockOrderRepository extends Mock implements OrderRepositoryContract<Order> {}

class _MockOrderItemRepository extends Mock implements OrderItemRepositoryContract<OrderItem> {}

class _MockMenuItemRepository extends Mock implements MenuItemRepositoryContract<MenuItem> {}

class _MockOrderCalculationService extends Mock implements OrderCalculationService {}

class _MockOrderStockService extends Mock implements OrderStockService {}

class _MockCartManagementService extends Mock implements CartManagementService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OrderManagementService service;
  late _MockOrderRepository orderRepository;
  late _MockOrderItemRepository orderItemRepository;
  late _MockMenuItemRepository menuItemRepository;
  late _MockOrderCalculationService calculationService;
  late _MockOrderStockService stockService;
  late _MockCartManagementService cartManagementService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<OrderItem>[]);
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
    orderItemRepository = _MockOrderItemRepository();
    menuItemRepository = _MockMenuItemRepository();
    calculationService = _MockOrderCalculationService();
    stockService = _MockOrderStockService();
    cartManagementService = _MockCartManagementService();

    service = OrderManagementService(
      orderRepository: orderRepository,
      orderItemRepository: orderItemRepository,
      menuItemRepository: menuItemRepository,
      orderCalculationService: calculationService,
      orderStockService: stockService,
      cartManagementService: cartManagementService,
    );
  });

  group("checkoutCart", () {
    test("marks cart as finalized during checkout", () async {
      final Order cart = Order(
        id: "cart-1",
        userId: "user-1",
        totalAmount: 0,
        status: OrderStatus.inProgress,
        paymentMethod: PaymentMethod.cash,
        discountAmount: 0,
        orderedAt: DateTime(2025),
        isCart: true,
      );

      final OrderItem item = OrderItem(
        id: "item-1",
        orderId: cart.id!,
        menuItemId: "menu-1",
        quantity: 1,
        unitPrice: 1200,
        subtotal: 1200,
      );

      final OrderCheckoutRequest request = OrderCheckoutRequest(
        paymentMethod: PaymentMethod.card,
        discountAmount: 0,
        customerName: "Guest",
      );

      final Order confirmedOrder = Order(
        id: cart.id,
        userId: cart.userId,
        totalAmount: 0,
        status: OrderStatus.inProgress,
        paymentMethod: request.paymentMethod,
        discountAmount: request.discountAmount,
        orderedAt: cart.orderedAt,
        orderNumber: "AB12",
      );

      final Order recalculatedOrder = Order(
        id: cart.id,
        userId: cart.userId,
        totalAmount: 1200,
        status: OrderStatus.inProgress,
        paymentMethod: request.paymentMethod,
        discountAmount: request.discountAmount,
        orderedAt: cart.orderedAt,
        orderNumber: "AB12",
      );

      final Order newCart = Order(
        id: "cart-2",
        userId: cart.userId,
        totalAmount: 0,
        status: OrderStatus.inProgress,
        paymentMethod: PaymentMethod.cash,
        discountAmount: 0,
        orderedAt: DateTime(2025, 1, 1, 0, 5),
        isCart: true,
      );

      final Map<String, bool> stockValidation = <String, bool>{item.id!: true};
      final OrderCalculationResult calculationResult = OrderCalculationResult(
        subtotal: 1200,
        taxAmount: 0,
        discountAmount: 0,
        totalAmount: 1200,
      );

      when(() => orderRepository.getById(cart.id!)).thenAnswer((_) async => cart);
      when(
        () => orderItemRepository.findByOrderId(cart.id!),
      ).thenAnswer((_) async => <OrderItem>[item]);
      when(
        () => stockService.validateCartStock(any<List<OrderItem>>()),
      ).thenAnswer((_) async => stockValidation);
      when(
        () => stockService.consumeMaterialsForOrder(any<List<OrderItem>>()),
      ).thenAnswer((_) async {});
      when(() => orderRepository.generateNextOrderNumber()).thenAnswer((_) async => "AB12");
      when(
        () => calculationService.calculateOrderTotal(
          cart.id!,
          discountAmount: request.discountAmount,
        ),
      ).thenAnswer((_) async => calculationResult);
      when(
        () => cartManagementService.getOrCreateActiveCart(cart.userId!),
      ).thenAnswer((_) async => newCart);

      final List<Map<String, dynamic>> capturedUpdates = <Map<String, dynamic>>[];
      when(() => orderRepository.updateById(cart.id!, any())).thenAnswer((
        Invocation invocation,
      ) async {
        final Map<String, dynamic> payload =
            invocation.positionalArguments[1] as Map<String, dynamic>;
        capturedUpdates.add(payload);
        if (payload.containsKey("order_number")) {
          return confirmedOrder;
        }
        return recalculatedOrder;
      });

      final OrderCheckoutResult result = await service.checkoutCart(
        cart.id!,
        request,
        cart.userId!,
      );

      expect(result.isSuccess, isTrue);
      expect(result.order.isCart, isFalse);
      expect(capturedUpdates, isNotEmpty);
      expect(capturedUpdates.first["is_cart"], isFalse);
      expect(capturedUpdates.first["order_number"], equals("AB12"));

      verify(() => orderRepository.getById(cart.id!)).called(1);
      verify(() => orderItemRepository.findByOrderId(cart.id!)).called(1);
      verify(() => stockService.validateCartStock(any<List<OrderItem>>())).called(1);
      verify(() => stockService.consumeMaterialsForOrder(any<List<OrderItem>>())).called(1);
      verify(() => orderRepository.generateNextOrderNumber()).called(1);
      verify(() => orderRepository.updateById(cart.id!, any())).called(2);
      verify(
        () => calculationService.calculateOrderTotal(
          cart.id!,
          discountAmount: request.discountAmount,
        ),
      ).called(1);
      verify(() => cartManagementService.getOrCreateActiveCart(cart.userId!)).called(1);
    });

    test("keeps existing display code during checkout", () async {
      final Order cart = Order(
        id: "cart-keep-code",
        userId: "user-keep",
        totalAmount: 0,
        status: OrderStatus.inProgress,
        paymentMethod: PaymentMethod.cash,
        discountAmount: 0,
        orderedAt: DateTime(2025, 4),
        isCart: true,
        orderNumber: "ZX99",
      );

      final OrderItem item = OrderItem(
        id: "item-keep",
        orderId: cart.id!,
        menuItemId: "menu-keep",
        quantity: 2,
        unitPrice: 800,
        subtotal: 1600,
      );

      final OrderCheckoutRequest request = OrderCheckoutRequest(
        paymentMethod: PaymentMethod.cash,
        discountAmount: 0,
        customerName: "Visitor",
      );

      final Map<String, bool> stockValidation = <String, bool>{item.id!: true};
      final OrderCalculationResult calculationResult = OrderCalculationResult(
        subtotal: 1600,
        taxAmount: 0,
        discountAmount: 0,
        totalAmount: 1600,
      );

      final Order updatedOrder = Order(
        id: cart.id,
        userId: cart.userId,
        totalAmount: 1600,
        status: OrderStatus.inProgress,
        paymentMethod: request.paymentMethod,
        discountAmount: request.discountAmount,
        orderedAt: cart.orderedAt,
        orderNumber: cart.orderNumber,
      );

      when(() => orderRepository.getById(cart.id!)).thenAnswer((_) async => cart);
      when(
        () => orderItemRepository.findByOrderId(cart.id!),
      ).thenAnswer((_) async => <OrderItem>[item]);
      when(
        () => stockService.validateCartStock(any<List<OrderItem>>()),
      ).thenAnswer((_) async => stockValidation);
      when(
        () => stockService.consumeMaterialsForOrder(any<List<OrderItem>>()),
      ).thenAnswer((_) async {});
      when(
        () => calculationService.calculateOrderTotal(
          cart.id!,
          discountAmount: request.discountAmount,
        ),
      ).thenAnswer((_) async => calculationResult);
      when(
        () => cartManagementService.getOrCreateActiveCart(cart.userId!),
      ).thenAnswer((_) async => null);

      final List<Map<String, dynamic>> capturedUpdates = <Map<String, dynamic>>[];
      when(() => orderRepository.updateById(cart.id!, any())).thenAnswer((
        Invocation invocation,
      ) async {
        final Map<String, dynamic> payload =
            invocation.positionalArguments[1] as Map<String, dynamic>;
        capturedUpdates.add(payload);
        return updatedOrder;
      });

      final OrderCheckoutResult result = await service.checkoutCart(
        cart.id!,
        request,
        cart.userId!,
      );

      expect(result.order.orderNumber, equals("ZX99"));
      verifyNever(() => orderRepository.generateNextOrderNumber());
      verify(() => orderRepository.updateById(cart.id!, any())).called(2);
      expect(capturedUpdates.first["order_number"], equals("ZX99"));
      expect(capturedUpdates.last.containsKey("order_number"), isFalse);
    });
  });

  group("getOrderHistory", () {
    test("excludes cart orders from result", () async {
      final Order cartOrder = Order(
        id: "cart-1",
        userId: "user-1",
        totalAmount: 0,
        status: OrderStatus.inProgress,
        paymentMethod: PaymentMethod.cash,
        discountAmount: 0,
        orderedAt: DateTime(2025, 3),
        isCart: true,
      );

      final Order finalizedOrder = Order(
        id: "order-2",
        userId: "user-1",
        totalAmount: 2200,
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.card,
        discountAmount: 0,
        orderedAt: DateTime(2025, 3, 2),
        completedAt: DateTime(2025, 3, 2, 12),
      );

      final OrderItem orderItem = OrderItem(
        id: "item-1",
        orderId: finalizedOrder.id!,
        menuItemId: "menu-1",
        quantity: 1,
        unitPrice: 2200,
        subtotal: 2200,
      );

      final MenuItem menuItem = MenuItem(
        id: "menu-1",
        userId: "user-1",
        name: "Special Ramen",
        categoryId: "cat-1",
        price: 2200,
        isAvailable: true,
        displayOrder: 1,
      );

      when(
        () => orderRepository.findByDateRange(any(), any()),
      ).thenAnswer((_) async => <Order>[cartOrder, finalizedOrder]);
      when(
        () => orderItemRepository.findByOrderId(cartOrder.id!),
      ).thenAnswer((_) async => <OrderItem>[]);
      when(
        () => orderItemRepository.findByOrderId(finalizedOrder.id!),
      ).thenAnswer((_) async => <OrderItem>[orderItem]);
      when(
        () => menuItemRepository.getById(orderItem.menuItemId),
      ).thenAnswer((_) async => menuItem);

      final Map<String, dynamic> result = await service.getOrderHistory(
        OrderSearchRequest(page: 1, limit: 20),
        "user-1",
      );

      final List<Order> orders = (result["orders"] as List<dynamic>).cast<Order>();

      expect(orders, hasLength(1));
      expect(orders.first.id, equals(finalizedOrder.id));
      expect(result["total_count"], equals(1));

      verify(() => orderRepository.findByDateRange(any<DateTime>(), any<DateTime>())).called(1);
    });
  });
}
