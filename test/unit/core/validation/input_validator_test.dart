import "package:flutter_test/flutter_test.dart";
import "package:yata/core/validation/input_validator.dart";

void main() {
  group("InputValidator", () {
    group("validateString", () {
      test("必須フィールドでnullの場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateString(
          null,
          required: true,
          fieldName: "テストフィールド",
        );

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "テストフィールドは必須です");
      });

      test("必須フィールドで空文字の場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateString(
          "",
          required: true,
          fieldName: "テストフィールド",
        );

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "テストフィールドは必須です");
      });

      test("任意フィールドでnullの場合は成功を返す", () {
        // Act
        final ValidationResult result = InputValidator.validateString(null, fieldName: "テストフィールド");

        // Assert
        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
      });

      test("最小文字数未満の場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateString(
          "abc",
          minLength: 5,
          fieldName: "テストフィールド",
        );

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "テストフィールドは5文字以上で入力してください");
      });

      test("最大文字数を超える場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateString(
          "abcdefghijk",
          maxLength: 5,
          fieldName: "テストフィールド",
        );

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "テストフィールドは5文字以下で入力してください");
      });

      test("正常な文字列の場合は成功を返す", () {
        // Act
        final ValidationResult result = InputValidator.validateString(
          "test",
          required: true,
          minLength: 2,
          maxLength: 10,
          fieldName: "テストフィールド",
        );

        // Assert
        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
      });
    });

    group("validateNumber", () {
      test("必須フィールドでnullの場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateNumber(
          null,
          required: true,
          fieldName: "数値フィールド",
        );

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "数値フィールドは必須です");
      });

      test("数値型の値で正常に検証される", () {
        // Act
        final ValidationResult result = InputValidator.validateNumber(
          42,
          min: 0,
          max: 100,
          fieldName: "数値フィールド",
        );

        // Assert
        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
      });

      test("文字列の数値で正常に検証される", () {
        // Act
        final ValidationResult result = InputValidator.validateNumber(
          "42",
          min: 0,
          max: 100,
          fieldName: "数値フィールド",
        );

        // Assert
        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
      });

      test("数値でない文字列の場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateNumber("abc", fieldName: "数値フィールド");

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "数値フィールドは数値で入力してください");
      });

      test("最小値未満の場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateNumber(
          5,
          min: 10,
          fieldName: "数値フィールド",
        );

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "数値フィールドは10以上で入力してください");
      });

      test("最大値を超える場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateNumber(
          15,
          max: 10,
          fieldName: "数値フィールド",
        );

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "数値フィールドは10以下で入力してください");
      });
    });

    group("validateEmail", () {
      test("正常なメールアドレスの場合は成功を返す", () {
        // Act
        final ValidationResult result = InputValidator.validateEmail("test@example.com");

        // Assert
        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
      });

      test("無効なメールアドレスの場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateEmail("invalid-email");

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "メールアドレスの形式が正しくありません");
      });

      test("必須フィールドでnullの場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validateEmail(null, required: true);

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "メールアドレスは必須です");
      });
    });

    group("validatePassword", () {
      test("正常なパスワードの場合は成功を返す", () {
        // Act
        final ValidationResult result = InputValidator.validatePassword("Password123");

        // Assert
        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
      });

      test("8文字未満の場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validatePassword("Pass1");

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "パスワードは8文字以上で入力してください");
      });

      test("大文字小文字数字が含まれない場合はエラーを返す", () {
        // Act
        final ValidationResult result = InputValidator.validatePassword("password");

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, "パスワードは大文字、小文字、数字を含む必要があります");
      });
    });

    group("validateAll", () {
      test("すべての検証が成功する場合は空のリストを返す", () {
        // Arrange
        final List<ValidationResult> results = <ValidationResult>[
          ValidationResult.success(),
          ValidationResult.success(),
          ValidationResult.success(),
        ];

        // Act
        final List<ValidationResult> errors = InputValidator.validateAll(results);

        // Assert
        expect(errors, isEmpty);
      });

      test("一部の検証が失敗する場合はエラーのみを返す", () {
        // Arrange
        final List<ValidationResult> results = <ValidationResult>[
          ValidationResult.success(),
          ValidationResult.error("エラー1"),
          ValidationResult.success(),
          ValidationResult.error("エラー2"),
        ];

        // Act
        final List<ValidationResult> errors = InputValidator.validateAll(results);

        // Assert
        expect(errors, hasLength(2));
        expect(errors[0].errorMessage, "エラー1");
        expect(errors[1].errorMessage, "エラー2");
      });
    });

    group("getErrorMessages", () {
      test("エラーメッセージのリストを正常に取得できる", () {
        // Arrange
        final List<ValidationResult> results = <ValidationResult>[
          ValidationResult.success(),
          ValidationResult.error("エラー1"),
          ValidationResult.error("エラー2"),
        ];

        // Act
        final List<String> messages = InputValidator.getErrorMessages(results);

        // Assert
        expect(messages, hasLength(2));
        expect(messages, contains("エラー1"));
        expect(messages, contains("エラー2"));
      });
    });
  });
}
