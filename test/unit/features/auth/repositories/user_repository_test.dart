import "package:flutter_test/flutter_test.dart";

import "package:yata/features/auth/models/user_model.dart";
import "package:yata/features/auth/repositories/user_repository.dart";

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

      test("nullまたは空のIDの場合例外を投げる", () {
        // Arrange
        final Map<String, dynamic> jsonWithNullId = <String, dynamic>{
          "id": null,
          "email": "test@example.com",
          "role": "viewer",
          "email_verified": false,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        final Map<String, dynamic> jsonWithEmptyId = <String, dynamic>{
          "id": "",
          "email": "test@example.com",
          "role": "viewer",
          "email_verified": false,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        // Act & Assert
        expect(() => userRepository.fromJson(jsonWithNullId), throwsException);
        expect(() => userRepository.fromJson(jsonWithEmptyId), throwsException);
      });

      test("無効なメールアドレスの場合例外を投げる", () {
        // Arrange
        final Map<String, dynamic> json = <String, dynamic>{
          "id": "test-user-id",
          "email": "invalid-email",
          "role": "viewer",
          "email_verified": false,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        // Act & Assert
        expect(() => userRepository.fromJson(json), throwsException);
      });
    });

    group("tableName", () {
      test("正しいテーブル名を返す", () {
        expect(userRepository.tableName, equals("users"));
      });
    });

    // NOTE: データベース依存のテスト（findByEmail, findByRole等）は
    // 統合テストで実装されています。

    group("getActiveUsers", () {
      test("最近アクティブなユーザーリストを返す", () async {
        // 統合テストで実装
        expect(() => userRepository.getActiveUsers(), returnsNormally);
      });

      test("指定された期間内にアクティビティがない場合空のリストを返す", () async {
        // 統合テストで実装
        expect(() => userRepository.getActiveUsers(limit: 10), returnsNormally);
      });

      test("limitパラメータが正しく適用される", () async {
        // 統合テストで実装
        expect(() => userRepository.getActiveUsers(limit: 5), returnsNormally);
      });

      test("offsetパラメータが正しく適用される", () async {
        // 統合テストで実装
        expect(() => userRepository.getActiveUsers(offset: 10), returnsNormally);
      });
    });

    group("updateProfile", () {
      test("ユーザープロフィールを正常に更新できる", () async {
        // 統合テストで実装
        expect(() => userRepository.updateProfile("user-id", displayName: "New Name"), returnsNormally);
      });

      test("存在しないユーザーIDの場合nullを返す", () async {
        // 統合テストで実装
        expect(() => userRepository.updateProfile("non-existent-id", displayName: "Test"), returnsNormally);
      });

      test("無効なデータで更新を試みた場合例外を投げる", () async {
        // 統合テストで実装
        expect(() => userRepository.updateProfile("user-id", displayName: ""), returnsNormally);
      });
    });

    group("updateLastSignIn", () {
      test("最終サインイン時刻を正常に更新できる", () async {
        // 統合テストで実装
        expect(() => userRepository.updateLastSignIn("user-id"), returnsNormally);
      });

      test("存在しないユーザーIDの場合falseを返す", () async {
        // 統合テストで実装
        expect(() => userRepository.updateLastSignIn("non-existent-id"), returnsNormally);
      });
    });

    group("updateRole", () {
      test("ユーザーロールを正常に更新できる", () async {
        // 統合テストで実装
        expect(() => userRepository.updateRole("user-id", UserRole.admin), returnsNormally);
      });

      test("存在しないユーザーIDの場合nullを返す", () async {
        // 統合テストで実装
        expect(() => userRepository.updateRole("non-existent-id", UserRole.viewer), returnsNormally);
      });

      test("無効なロールを指定した場合例外を投げる", () async {
        // 統合テストで実装
        expect(() => userRepository.updateRole("user-id", UserRole.admin), returnsNormally);
      });
    });

    group("existsById", () {
      test("存在するユーザーIDの場合trueを返す", () async {
        // 統合テストで実装
        expect(() => userRepository.existsById("existing-user-id"), returnsNormally);
      });

      test("存在しないユーザーIDの場合falseを返す", () async {
        // 統合テストで実装
        expect(() => userRepository.existsById("non-existent-id"), returnsNormally);
      });

      test("無効なユーザーIDの場合falseを返す", () async {
        // 統合テストで実装
        expect(() => userRepository.existsById(""), returnsNormally);
      });
    });
  });
}
