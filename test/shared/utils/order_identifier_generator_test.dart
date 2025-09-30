import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/shared/utils/order_identifier_generator.dart";

class _MockRandom extends Mock implements Random {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(0);
  });

  group("OrderIdentifierGenerator", () {
    test("generateJstTimestampString returns JST formatted string", () {
      final OrderIdentifierGenerator generator = OrderIdentifierGenerator(
        nowProvider: () => DateTime.utc(2025, 9, 30, 6, 30, 15, 987),
      );

      final String timestamp = generator.generateJstTimestampString();

      expect(timestamp, equals("20250930T153015+0900"));
    });

    test("generateBase62Slug produces expected characters", () {
      final _MockRandom random = _MockRandom();
      final List<int> indices = <int>[0, 10, 35, 36, 61, 1, 11, 37, 2, 12, 38];
      when(() => random.nextInt(any<int>())).thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments.single, equals(62));
        return indices.removeAt(0);
      });

      final OrderIdentifierGenerator generator = OrderIdentifierGenerator(
        nowProvider: () => DateTime.utc(2025, 9, 30),
        random: random,
      );

      final String slug = generator.generateBase62Slug();

  expect(slug, equals("0AZaz1Bb2Cc"));
      expect(slug.length, equals(OrderIdentifierGenerator.defaultSlugLength));
  expect(slug, matches(RegExp(r"^[0-9A-Za-z]{11}$")));
    });

    test("generateOrderNumber combines timestamp and slug", () {
      final _MockRandom random = _MockRandom();
      final List<int> indices = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      when(() => random.nextInt(any<int>())).thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments.single, equals(62));
        return indices.removeAt(0);
      });

      final OrderIdentifierGenerator generator = OrderIdentifierGenerator(
        nowProvider: () => DateTime.utc(2025, 9, 29, 21, 59, 59, 123),
        random: random,
      );

      final String orderNumber = generator.generateOrderNumber();

  expect(orderNumber, equals("20250930T065959+0900-0123456789A"));
  expect(orderNumber, matches(RegExp(r"^[0-9]{8}T[0-9]{6}\+0900-[0-9A-Za-z]{11}$")));
    });
  });
}
