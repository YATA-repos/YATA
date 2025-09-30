import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/core/constants/exceptions/repository/repository_exception.dart";
import "package:yata/core/constants/log_enums/repository.dart";
import "package:yata/core/constants/query_types.dart";
import "package:yata/core/contracts/repositories/crud_repository.dart" as repo_contract;
import "package:yata/features/order/models/order_model.dart";
import "package:yata/features/order/repositories/order_repository.dart";
import "package:yata/shared/utils/order_identifier_generator.dart";

class _MockCrudRepository extends Mock implements repo_contract.CrudRepository<Order, String> {}

class _MockOrderIdentifierGenerator extends Mock implements OrderIdentifierGenerator {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OrderRepository repository;
  late _MockCrudRepository delegate;
  late _MockOrderIdentifierGenerator identifierGenerator;

  setUpAll(() {
    registerFallbackValue(<QueryFilter>[]);
    registerFallbackValue(<OrderByCondition>[]);
  });

  setUp(() {
    delegate = _MockCrudRepository();
    identifierGenerator = _MockOrderIdentifierGenerator();
    repository = OrderRepository(delegate: delegate, identifierGenerator: identifierGenerator);
  });

  group("generateNextOrderNumber", () {
    test("returns short display code when candidate is unique", () async {
      const String expectedNumber = "AB12";

      when(() => identifierGenerator.generateOrderNumber()).thenReturn(expectedNumber);
      List<QueryFilter>? capturedFilters;
      int? capturedLimit;
      when(
        () => delegate.find(
          filters: any(named: "filters"),
          orderBy: any(named: "orderBy"),
          limit: any(named: "limit"),
          offset: any(named: "offset"),
        ),
      ).thenAnswer((Invocation invocation) async {
        capturedFilters = invocation.namedArguments[#filters] as List<QueryFilter>?;
        capturedLimit = invocation.namedArguments[#limit] as int?;
        return <Order>[];
      });

      final String orderNumber = await repository.generateNextOrderNumber();

      expect(orderNumber, expectedNumber);

      verify(
        () => delegate.find(
          filters: any(named: "filters"),
          orderBy: any(named: "orderBy"),
          limit: any(named: "limit"),
          offset: any(named: "offset"),
        ),
      ).called(1);

      final Iterable<FilterCondition> conditions = (capturedFilters ?? <QueryFilter>[])
          .whereType<FilterCondition>();
      expect(conditions, hasLength(1));

      final FilterCondition condition = conditions.first;
      expect(condition.column, equals("order_number"));
      expect(condition.operator, equals(FilterOperator.eq));
      expect(condition.value, equals(expectedNumber));
      expect(capturedLimit, equals(1));
    });

    test("retries when collision is detected", () async {
      final List<String> candidates = <String>["AB12", "CD34"];
  when(() => identifierGenerator.generateOrderNumber()).thenAnswer((Invocation _) => candidates.removeAt(0));

      int findCallCount = 0;
      when(
        () => delegate.find(
          filters: any(named: "filters"),
          orderBy: any(named: "orderBy"),
          limit: any(named: "limit"),
          offset: any(named: "offset"),
        ),
      ).thenAnswer((_) async {
        findCallCount += 1;
        if (findCallCount == 1) {
          return <Order>[
            Order(
              totalAmount: 0,
              status: OrderStatus.inProgress,
              paymentMethod: PaymentMethod.cash,
              discountAmount: 0,
              orderedAt: DateTime(2025, 9, 30),
            ),
          ];
        }
        return <Order>[];
      });

      final String orderNumber = await repository.generateNextOrderNumber();

  expect(orderNumber, equals("CD34"));
      expect(findCallCount, equals(2));
  verify(() => identifierGenerator.generateOrderNumber()).called(2);
    });

    test("rethrows repository exception from count", () async {
      when(() => identifierGenerator.generateOrderNumber()).thenReturn("AB12");
      when(
        () => delegate.find(
          filters: any(named: "filters"),
          orderBy: any(named: "orderBy"),
          limit: any(named: "limit"),
          offset: any(named: "offset"),
        ),
      ).thenThrow(
        RepositoryException(
          RepositoryError.databaseConnectionFailed,
          params: <String, String>{"error": "timeout"},
        ),
      );

      await expectLater(
        repository.generateNextOrderNumber,
        throwsA(isA<RepositoryException>()),
      );
    });

    test("throws after max attempts when collisions persist", () async {
      when(() => identifierGenerator.generateOrderNumber()).thenReturn("AB12");
      when(
        () => delegate.find(
          filters: any(named: "filters"),
          orderBy: any(named: "orderBy"),
          limit: any(named: "limit"),
          offset: any(named: "offset"),
        ),
      ).thenAnswer((_) async => <Order>[
            Order(
              totalAmount: 0,
              status: OrderStatus.inProgress,
              paymentMethod: PaymentMethod.cash,
              discountAmount: 0,
              orderedAt: DateTime(2025, 9, 30),
            ),
          ]);

      await expectLater(
        repository.generateNextOrderNumber,
        throwsA(isA<Exception>()),
      );

  verify(() => identifierGenerator.generateOrderNumber()).called(5);
    });
  });
}
