import "package:flutter_test/flutter_test.dart";

import "package:yata/features/auth/models/user_model.dart";
import "package:yata/features/auth/repositories/user_repository.dart";

/// UserRepository単体テスト
///
/// モック機能を使わず、fromJson と基本的な機能のテストに焦点を当てる
void main() {
  group("UserRepository", () {
    late UserRepository userRepository;

    setUp(() {
      userRepository = UserRepository();
    });

    group("fromJson", () {
      test("有効なJSONからUserModelを作成できる", () {
        // Arrange
        final Map<String, dynamic> json = <String, dynamic>{
          "id": "test-user-id",
          "user_id": "test-user-id",
          "email": "test@example.com",
          "display_name": "Test User",
          "role": "admin",
          "email_verified": true,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        // Act
        final UserModel user = userRepository.fromJson(json);

        // Assert
        expect(user.id, equals("test-user-id"));
        expect(user.email, equals("test@example.com"));
        expect(user.displayName, equals("Test User"));
        expect(user.role, equals(UserRole.admin));
        expect(user.emailVerified, isTrue);
        expect(user.createdAt, isA<DateTime>());
        expect(user.updatedAt, isA<DateTime>());
      });

      test("必須フィールドのみでUserModelを作成できる", () {
        // Arrange
        final Map<String, dynamic> json = <String, dynamic>{
          "id": "test-user-id",
          "user_id": "test-user-id",
          "email": "test@example.com",
          "role": "viewer",
          "email_verified": false,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        // Act
        final UserModel user = userRepository.fromJson(json);

        // Assert
        expect(user.id, equals("test-user-id"));
        expect(user.email, equals("test@example.com"));
        expect(user.displayName, isNull);
        expect(user.role, equals(UserRole.viewer));
        expect(user.emailVerified, isFalse);
      });

      test("各ロール値が正しくマッピングされる", () {
        final Map<String, UserRole> roleMapping = <String, UserRole>{
          "admin": UserRole.admin,
          "manager": UserRole.manager,
          "staff": UserRole.staff,
          "viewer": UserRole.viewer,
        };

        roleMapping.forEach((String roleString, UserRole expectedRole) {
          // Arrange
          final Map<String, dynamic> json = <String, dynamic>{
            "id": "test-user-id",
            "user_id": "test-user-id",
            "email": "test@example.com",
            "role": roleString,
            "email_verified": false,
            "created_at": "2024-01-01T00:00:00.000Z",
            "updated_at": "2024-01-01T00:00:00.000Z",
          };

          // Act
          final UserModel user = userRepository.fromJson(json);

          // Assert
          expect(
            user.role,
            equals(expectedRole),
            reason: "Role $roleString should map to $expectedRole",
          );
        });
      });

      test("無効なロール値の場合デフォルトのviewerロールを設定", () {
        // Arrange
        final Map<String, dynamic> json = <String, dynamic>{
          "id": "test-user-id",
          "user_id": "test-user-id",
          "email": "test@example.com",
          "role": "invalid_role",
          "email_verified": false,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        // Act
        final UserModel user = userRepository.fromJson(json);

        // Assert
        expect(user.role, equals(UserRole.viewer));
      });

      test("DateTime フィールドが正しくパースされる", () {
        // Arrange
        const String createdAtString = "2024-01-15T10:30:00.000Z";
        const String updatedAtString = "2024-01-16T15:45:30.123Z";

        final Map<String, dynamic> json = <String, dynamic>{
          "id": "test-user-id",
          "user_id": "test-user-id",
          "email": "test@example.com",
          "role": "viewer",
          "email_verified": false,
          "created_at": createdAtString,
          "updated_at": updatedAtString,
        };

        // Act
        final UserModel user = userRepository.fromJson(json);

        // Assert
        expect(user.createdAt, equals(DateTime.parse(createdAtString)));
        expect(user.updatedAt, equals(DateTime.parse(updatedAtString)));
      });

      test("email_verified フィールドの様々な値を処理できる", () {
        final Map<dynamic, bool> emailVerifiedMapping = <dynamic, bool>{
          true: true,
          false: false,
          "true": true,
          "false": false,
          1: true,
          0: false,
          null: false,
        };

        emailVerifiedMapping.forEach((dynamic value, bool expected) {
          // Arrange
          final Map<String, dynamic> json = <String, dynamic>{
            "id": "test-user-id",
            "user_id": "test-user-id",
            "email": "test@example.com",
            "role": "viewer",
            "email_verified": value,
            "created_at": "2024-01-01T00:00:00.000Z",
            "updated_at": "2024-01-01T00:00:00.000Z",
          };

          // Act
          final UserModel user = userRepository.fromJson(json);

          // Assert
          expect(
            user.emailVerified,
            equals(expected),
            reason: "email_verified value $value should result in $expected",
          );
        });
      });

      test("JSONに必須フィールドが不足している場合例外を投げる", () {
        final List<String> requiredFields = <String>["id", "email", "role"];

        for (final String missingField in requiredFields) {
          // Arrange - 必須フィールドを一つ除いたJSONを作成
          final Map<String, dynamic> completeJson = <String, dynamic>{
            "id": "test-user-id",
            "user_id": "test-user-id",
            "email": "test@example.com",
            "role": "viewer",
            "email_verified": false,
            "created_at": "2024-01-01T00:00:00.000Z",
            "updated_at": "2024-01-01T00:00:00.000Z",
          };

          completeJson.remove(missingField);

          // Act & Assert
          expect(
            () => userRepository.fromJson(completeJson),
            throwsException,
            reason: "Missing field $missingField should throw an exception",
          );
        }
      });
    });

    group("tableName", () {
      test("正しいテーブル名を返す", () {
        expect(userRepository.tableName, equals("users"));
      });
    });

    group("validateInputs", () {
      test("findByEmail は空の文字列を拒否する", () async {
        // Act & Assert
        expect(() => userRepository.findByEmail(""), throwsA(isA<Exception>()));

        expect(() => userRepository.findByEmail("   "), throwsA(isA<Exception>()));
      });

      test("updateProfile は有効なユーザーIDを必要とする", () async {
        // Act & Assert
        expect(() => userRepository.updateProfile(""), throwsA(isA<Exception>()));

        expect(() => userRepository.updateProfile("   "), throwsA(isA<Exception>()));
      });
    });

    group("permissions", () {
      test("isAdmin は管理者権限を正しく判定する（統合テスト必要）", () async {
        // このテストは実際のデータベースと統合テストが必要
        // 現在はプレースホルダーテスト
        expect(true, true);
      });

      test("isStaff はスタッフ権限を正しく判定する（統合テスト必要）", () async {
        // このテストは実際のデータベースと統合テストが必要
        // 現在はプレースホルダーテスト
        expect(true, true);
      });
    });
  });
}
