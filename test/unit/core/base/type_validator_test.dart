import "package:flutter_test/flutter_test.dart";
import "package:yata/core/constants/exceptions.dart";
import "package:yata/core/utils/type_validator.dart";

void main() {
  group("TypeValidator", () {
    group("isValidIdType", () {
      test("文字列IDは有効", () {
        expect(TypeValidator.isValidIdType("test-id"), true);
        expect(TypeValidator.isValidIdType(""), true);
      });

      test("数値IDは有効", () {
        expect(TypeValidator.isValidIdType(123), true);
        expect(TypeValidator.isValidIdType(0), true);
        expect(TypeValidator.isValidIdType(-1), true);
      });

      test("Map型IDは有効", () {
        expect(TypeValidator.isValidIdType(<String, dynamic>{"id": "test"}), true);
        expect(TypeValidator.isValidIdType(<String, dynamic>{}), true);
      });

      test("無効な型は拒否される", () {
        expect(TypeValidator.isValidIdType(12.34), false); // double
        expect(TypeValidator.isValidIdType(true), false); // bool
        expect(TypeValidator.isValidIdType(<String>["test"]), false); // List
        expect(TypeValidator.isValidIdType(null), false); // null
      });
    });

    group("validateId", () {
      test("有効なIDは例外を投げない", () {
        expect(() => TypeValidator.validateId("test"), returnsNormally);
        expect(() => TypeValidator.validateId(123), returnsNormally);
        expect(() => TypeValidator.validateId(<String, dynamic>{"id": "test"}), returnsNormally);
      });

      test("無効なIDはInvalidIdTypeExceptionを投げる", () {
        expect(() => TypeValidator.validateId(12.34), throwsA(isA<InvalidIdTypeException>()));

        expect(() => TypeValidator.validateId(true), throwsA(isA<InvalidIdTypeException>()));

        expect(
          () => TypeValidator.validateId(<String>["test"]),
          throwsA(isA<InvalidIdTypeException>()),
        );
      });

      test("InvalidIdTypeExceptionに正しい型情報が含まれる", () {
        try {
          TypeValidator.validateId(12.34);
          fail("例外が発生するはずです");
        } catch (e) {
          expect(e, isA<InvalidIdTypeException>());
          final InvalidIdTypeException exception = e as InvalidIdTypeException;
          expect(exception.providedType, double);
          expect(exception.expectedTypes, contains(String));
          expect(exception.expectedTypes, contains(int));
          expect(exception.expectedTypes, contains(Map));
        }
      });
    });

    group("getValidatedId", () {
      test("有効なIDを型安全に取得できる", () {
        final String stringId = TypeValidator.getValidatedId<String>("test-id");
        expect(stringId, "test-id");

        final int intId = TypeValidator.getValidatedId<int>(123);
        expect(intId, 123);

        final Map<String, dynamic> mapId = TypeValidator.getValidatedId<Map<String, dynamic>>(
          <String, dynamic>{"id": "test"},
        );
        expect(mapId["id"], "test");
      });

      test("無効なIDはInvalidIdTypeExceptionを投げる", () {
        expect(
          () => TypeValidator.getValidatedId<String>(12.34),
          throwsA(isA<InvalidIdTypeException>()),
        );
      });
    });
  });

  group("InvalidIdTypeException", () {
    test("適切なエラーメッセージを生成する", () {
      const InvalidIdTypeException exception = InvalidIdTypeException(double, <Type>[
        String,
        int,
        Map,
      ]);

      final String message = exception.toString();
      expect(message, contains("InvalidIdTypeException"));
      expect(message, contains("String"));
      expect(message, contains("int"));
      expect(message, contains("Map"));
      expect(message, contains("double"));
    });
  });
}
