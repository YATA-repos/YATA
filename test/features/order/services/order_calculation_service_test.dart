import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:yata/app/wiring/provider.dart";
import "package:yata/core/contracts/repositories/order/order_repository_contracts.dart";
import "package:yata/core/logging/levels.dart";
import "package:yata/core/logging/logger_binding.dart";
import "package:yata/features/order/dto/order_dto.dart";
import "package:yata/features/order/models/order_model.dart";
import "package:yata/features/order/services/order/order_calculation_service.dart";
import "package:yata/features/settings/domain/app_settings.dart";
import "package:yata/features/settings/services/settings_service.dart";

import "../../../support/logging/fake_logger.dart";
import "../../../support/logging/log_expectations.dart";

class _MockOrderItemRepository extends Mock implements OrderItemRepositoryContract<OrderItem> {}

class _MockSettingsService extends Mock implements SettingsService {}

void main() {
  late FakeLogger logger;
  late _MockOrderItemRepository repository;
  late _MockSettingsService settingsService;
  late AppSettings initialSettings;

  setUp(() {
    logger = FakeLogger();
    repository = _MockOrderItemRepository();
    settingsService = _MockSettingsService();
    initialSettings = AppSettings.defaults();

    when(() => settingsService.current).thenReturn(initialSettings);
    when(
      () => settingsService.watch(),
    ).thenAnswer((_) => Stream<AppSettings>.value(initialSettings));
  });

  test("calculateOrderTotal logs summary with debug level", () async {
    const String orderId = "order-1";
    final List<OrderItem> items = <OrderItem>[
      OrderItem(
        orderId: orderId,
        menuItemId: "menu-1",
        quantity: 2,
        unitPrice: 1200,
        subtotal: 2400,
      ),
      OrderItem(orderId: orderId, menuItemId: "menu-2", quantity: 1, unitPrice: 800, subtotal: 800),
    ];

    when(() => repository.findByOrderId(orderId)).thenAnswer((Invocation _) async => items);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        loggerProvider.overrideWith((Ref ref) {
          LoggerBinding.register(logger);
          ref.onDispose(LoggerBinding.clear);
          return logger;
        }),
        orderItemRepositoryProvider.overrideWithValue(repository),
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
    );
    addTearDown(container.dispose);

    final OrderCalculationService service = container.read(orderCalculationServiceProvider);
    expect(service.taxRate, moreOrLessEquals(initialSettings.taxRate, epsilon: 1e-4));

    final OrderCalculationResult result = await service.calculateOrderTotal(orderId);

    expect(result.subtotal, 3200);
    expect(result.taxAmount, 320);
    expect(result.totalAmount, 3520);

    final CapturedLog summaryLog = await expectLog(
      logger,
      level: Level.debug,
      tag: "OrderCalculationService",
      messageContains: "Order total calculated",
    );

    expect(summaryLog.message, contains("subtotal=3200"));

    await expectNoLog(logger, where: (CapturedLog entry) => entry.level == Level.error);
  });

  test("calculateOrderTotal logs error when repository throws", () async {
    const String orderId = "order-2";

    when(() => repository.findByOrderId(orderId)).thenThrow(Exception("db failure"));

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        loggerProvider.overrideWith((Ref ref) {
          LoggerBinding.register(logger);
          ref.onDispose(LoggerBinding.clear);
          return logger;
        }),
        orderItemRepositoryProvider.overrideWithValue(repository),
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
    );
    addTearDown(container.dispose);

    final OrderCalculationService service = container.read(orderCalculationServiceProvider);

    await expectLater(service.calculateOrderTotal(orderId), throwsA(isA<Exception>()));

    final CapturedLog errorLog = await expectLog(
      logger,
      level: Level.error,
      tag: "OrderCalculationService",
      messageContains: "Failed to calculate order total",
      errorWhere: (Object? error) => error is Exception && error.toString().contains("db failure"),
    );

    expect(errorLog.stackTrace, isNotNull);
  });

  test("orderCalculationServiceProvider updates tax rate when settings change", () async {
    final StreamController<AppSettings> controller = StreamController<AppSettings>.broadcast();
    when(() => settingsService.watch()).thenAnswer((_) => controller.stream);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        loggerProvider.overrideWith((Ref ref) {
          LoggerBinding.register(logger);
          ref.onDispose(LoggerBinding.clear);
          return logger;
        }),
        orderItemRepositoryProvider.overrideWithValue(repository),
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
    );
    addTearDown(() async {
      await controller.close();
      container.dispose();
    });

    final OrderCalculationService service = container.read(orderCalculationServiceProvider);
    expect(service.taxRate, closeTo(initialSettings.taxRate, 0.0001));

    final AppSettings updated = initialSettings.copyWith(taxRate: 0.05);
    controller.add(updated);
    await Future<void>.delayed(Duration.zero);

    expect(service.taxRate, moreOrLessEquals(0.05, epsilon: 1e-4));
  });

  test("setBaseTaxRate clamps negatives to zero", () {
    final OrderCalculationService service = OrderCalculationService(
      logger: logger,
      orderItemRepository: repository,
    );
    final void Function(double) setRate = service.setBaseTaxRate;

    setRate(-0.25);
    expect(service.taxRate, 0);
    expect(service.calculateTaxAmount(1000), 0);

    setRate(0.2);
    expect(service.taxRate, moreOrLessEquals(0.2, epsilon: 1e-4));
  });
}
