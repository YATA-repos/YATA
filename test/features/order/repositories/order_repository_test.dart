import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/core/constants/exceptions/repository/repository_exception.dart";
import "package:yata/core/constants/log_enums/repository.dart";
import "package:yata/core/constants/query_types.dart";
import "package:yata/core/contracts/repositories/crud_repository.dart" as repo_contract;
import "package:yata/features/order/models/order_model.dart";
import "package:yata/features/order/repositories/order_repository.dart";

class _MockCrudRepository extends Mock implements repo_contract.CrudRepository<Order, String> {}

FilterCondition _findCondition(
  Iterable<FilterCondition> conditions,
  String column,
  FilterOperator operator,
) =>
    conditions.firstWhere(
      (FilterCondition condition) =>
          condition.column == column && condition.operator == operator,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OrderRepository repository;
  late _MockCrudRepository delegate;

  setUpAll(() {
    registerFallbackValue(<QueryFilter>[]);
  });

  setUp(() {
    delegate = _MockCrudRepository();
    repository = OrderRepository(delegate: delegate);
  });

  group("generateNextOrderNumber", () {
    test("uses count strategy and formats sequential number", () async {
      when(() => delegate.count(filters: any(named: "filters"))).thenAnswer((_) async => 5);

      final String orderNumber = await repository.generateNextOrderNumber();

      final List<String> parts = orderNumber.split("-");
      expect(parts, hasLength(2));
      expect(parts[1], equals("006"));

      final DateTime now = DateTime.now();
      final String expectedPrefix =
          "${now.year.toString().padLeft(4, '0')}"
          "${now.month.toString().padLeft(2, '0')}"
          "${now.day.toString().padLeft(2, '0')}";
      expect(parts.first, expectedPrefix);

      verify(() => delegate.count(filters: any(named: "filters"))).called(1);
      verifyNever(() => delegate.find());
    });

    test("applies finalized-order filters when counting", () async {
      final List<List<QueryFilter>?> capturedFilters = <List<QueryFilter>?>[];
      when(() => delegate.count(filters: any(named: "filters"))).thenAnswer((Invocation invocation) async {
        capturedFilters.add(invocation.namedArguments[#filters] as List<QueryFilter>?);
        return 0;
      });

      await repository.generateNextOrderNumber();

      expect(capturedFilters, hasLength(1));
      final List<QueryFilter> filters = capturedFilters.first!;
      final Iterable<FilterCondition> conditions =
          filters.whereType<FilterCondition>();

      final FilterCondition isCartCondition = _findCondition(
        conditions,
        "is_cart",
        FilterOperator.eq,
      );
      expect(isCartCondition.value, isFalse);

      final FilterCondition orderNumberCondition = _findCondition(
        conditions,
        "order_number",
        FilterOperator.isNotNull,
      );
      expect(orderNumberCondition.value, isNull);

      final FilterCondition gteCondition = _findCondition(
        conditions,
        "ordered_at",
        FilterOperator.gte,
      );
      final FilterCondition lteCondition = _findCondition(
        conditions,
        "ordered_at",
        FilterOperator.lte,
      );

      final DateTime gte = DateTime.parse(gteCondition.value as String);
      final DateTime lte = DateTime.parse(lteCondition.value as String);

      expect(gte.hour, equals(0));
      expect(gte.minute, equals(0));
      expect(gte.second, equals(0));
      expect(gte.millisecond, equals(0));
      expect(lte.hour, equals(23));
      expect(lte.minute, equals(59));
      expect(lte.second, equals(59));
      expect(lte.millisecond, equals(999));
    });

    test("rethrows repository exception from count", () async {
      when(() => delegate.count(filters: any(named: "filters"))).thenThrow(
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
  });
}
