import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:supabase_flutter/supabase_flutter.dart" as supabase;

import "package:yata/core/auth/auth_service.dart";
import "package:yata/features/auth/models/user_model.dart";
import "package:yata/features/auth/repositories/user_repository.dart";
import "package:yata/features/auth/services/auth_service.dart";

import "auth_service_test.mocks.dart";

// Mockitoでモックを生成
@GenerateMocks(<Type>[SupabaseClientService, UserRepository, supabase.User, supabase.Session])
void main() {
  group("AuthService 単体テスト", () {
    late AuthService authService;
    late MockSupabaseClientService mockSupabaseAuthService;
    late MockUserRepository mockUserRepository;
    late MockUser mockSupabaseUser;

    setUp(() {
      mockSupabaseAuthService = MockSupabaseClientService();
      mockUserRepository = MockUserRepository();
      mockSupabaseUser = MockUser();

      authService = AuthService(
        supabaseAuthService: mockSupabaseAuthService,
        userRepository: mockUserRepository,
      );
    });

    group("ログイン状態の確認", () {
      test("isSignedIn - ログイン済みの場合trueを返す", () {
        // Arrange
        when(mockSupabaseAuthService.isSignedIn).thenReturn(true);

        // Act
        final bool result = authService.isSignedIn;

        // Assert
        expect(result, isTrue);
        verify(mockSupabaseAuthService.isSignedIn).called(1);
      });

      test("isSignedIn - 未ログインの場合falseを返す", () {
        // Arrange
        when(mockSupabaseAuthService.isSignedIn).thenReturn(false);

        // Act
        final bool result = authService.isSignedIn;

        // Assert
        expect(result, isFalse);
        verify(mockSupabaseAuthService.isSignedIn).called(1);
      });
    });

    group("現在のユーザー取得", () {
      test("getCurrentUser - ユーザーが存在する場合、ユーザー情報を返す", () async {
        // Arrange
        const String userId = "test-user-id";
        final UserModel expectedUser = UserModel(
          id: userId,
          userId: userId,
          email: "test@example.com",
          displayName: "Test User",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockSupabaseAuthService.currentUser).thenReturn(mockSupabaseUser);
        when(mockSupabaseUser.id).thenReturn(userId);
        when(mockUserRepository.getById(userId)).thenAnswer((_) async => expectedUser);

        // Act
        final UserModel? result = await authService.getCurrentUser();

        // Assert
        expect(result, equals(expectedUser));
        verify(mockSupabaseAuthService.currentUser).called(1);
        verify(mockUserRepository.getById(userId)).called(1);
      });

      test("getCurrentUser - Supabaseユーザーが存在しない場合、nullを返す", () async {
        // Arrange
        when(mockSupabaseAuthService.currentUser).thenReturn(null);

        // Act
        final UserModel? result = await authService.getCurrentUser();

        // Assert
        expect(result, isNull);
        verify(mockSupabaseAuthService.currentUser).called(1);
        verifyNever(mockUserRepository.getById(any));
      });

      test("getCurrentUser - データベースにユーザーが存在しない場合、新規作成する", () async {
        // Arrange
        const String userId = "test-user-id";
        const String email = "test@example.com";
        final UserModel createdUser = UserModel(
          id: userId,
          userId: userId,
          email: email,
          displayName: "Test User",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockSupabaseAuthService.currentUser).thenReturn(mockSupabaseUser);
        when(mockSupabaseUser.id).thenReturn(userId);
        when(mockSupabaseUser.email).thenReturn(email);
        when(mockSupabaseUser.userMetadata).thenReturn(<String, dynamic>{"full_name": "Test User"});
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(DateTime.now().toIso8601String());
        when(mockSupabaseUser.phone).thenReturn(null);

        when(mockUserRepository.getById(userId)).thenAnswer((_) async => null);
        when(mockUserRepository.create(any)).thenAnswer((_) async => createdUser);

        // Act
        final UserModel? result = await authService.getCurrentUser();

        // Assert
        expect(result, equals(createdUser));
        verify(mockSupabaseAuthService.currentUser).called(1);
        verify(mockUserRepository.getById(userId)).called(1);
        verify(mockUserRepository.create(any)).called(1);
      });
    });

    group("プロフィール更新", () {
      test("updateProfile - 有効な入力で正常に更新される", () async {
        // Arrange
        const String userId = "test-user-id";
        const String displayName = "Updated Name";
        const String avatarUrl = "https://example.com/avatar.jpg";
        const String phoneNumber = "090-1234-5678";

        final UserModel currentUser = UserModel(
          id: userId,
          userId: userId,
          email: "test@example.com",
          displayName: "Old Name",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final UserModel updatedUser = UserModel(
          id: userId,
          userId: userId,
          email: "test@example.com",
          displayName: displayName,
          avatarUrl: avatarUrl,
          phoneNumber: phoneNumber,
          createdAt: currentUser.createdAt,
          updatedAt: DateTime.now(),
        );

        when(mockSupabaseAuthService.currentUser).thenReturn(mockSupabaseUser);
        when(mockSupabaseUser.id).thenReturn(userId);
        when(mockUserRepository.getById(userId)).thenAnswer((_) async => currentUser);
        when(
          mockUserRepository.updateProfile(
            userId,
            displayName: displayName,
            avatarUrl: avatarUrl,
            phoneNumber: phoneNumber,
          ),
        ).thenAnswer((_) async => updatedUser);

        // Act
        final UserModel? result = await authService.updateProfile(
          displayName: displayName,
          avatarUrl: avatarUrl,
          phoneNumber: phoneNumber,
        );

        // Assert
        expect(result, equals(updatedUser));
        verify(
          mockUserRepository.updateProfile(
            userId,
            displayName: displayName,
            avatarUrl: avatarUrl,
            phoneNumber: phoneNumber,
          ),
        ).called(1);
      });

      test("updateProfile - 無効な表示名で例外が発生する", () async {
        // Arrange
        const String invalidDisplayName = ""; // 空文字列は無効

        when(mockSupabaseAuthService.currentUser).thenReturn(mockSupabaseUser);

        // Act & Assert
        expect(
          () async => authService.updateProfile(displayName: invalidDisplayName),
          throwsA(isA<ArgumentError>()),
        );
      });

      test("updateProfile - 無効なURLで例外が発生する", () async {
        // Arrange
        const String invalidUrl = "invalid-url"; // 無効なURL形式

        when(mockSupabaseAuthService.currentUser).thenReturn(mockSupabaseUser);

        // Act & Assert
        expect(
          () async => authService.updateProfile(avatarUrl: invalidUrl),
          throwsA(isA<ArgumentError>()),
        );
      });

      test("updateProfile - 現在のユーザーが存在しない場合nullを返す", () async {
        // Arrange
        when(mockSupabaseAuthService.currentUser).thenReturn(null);

        // Act
        final UserModel? result = await authService.updateProfile(displayName: "Test");

        // Assert
        expect(result, isNull);
        verifyNever(mockUserRepository.updateProfile(any, displayName: anyNamed("displayName")));
      });
    });

    group("メールアドレスによるユーザー検索", () {
      test("findUserByEmail - 有効なメールアドレスでユーザーを検索する", () async {
        // Arrange
        const String email = "test@example.com";
        final UserModel expectedUser = UserModel(
          id: "user-id",
          userId: "user-id",
          email: email,
          displayName: "Test User",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockUserRepository.findByEmail(email)).thenAnswer((_) async => expectedUser);

        // Act
        final UserModel? result = await authService.findUserByEmail(email);

        // Assert
        expect(result, equals(expectedUser));
        verify(mockUserRepository.findByEmail(email)).called(1);
      });

      test("findUserByEmail - 無効なメールアドレスで例外が発生する", () async {
        // Arrange
        const String invalidEmail = "invalid-email"; // 無効なメール形式

        // Act & Assert
        expect(
          () async => authService.findUserByEmail(invalidEmail),
          throwsA(isA<ArgumentError>()),
        );
        verifyNever(mockUserRepository.findByEmail(any));
      });

      test("findUserByEmail - 空のメールアドレスで例外が発生する", () async {
        // Arrange
        const String emptyEmail = "";

        // Act & Assert
        expect(() async => authService.findUserByEmail(emptyEmail), throwsA(isA<ArgumentError>()));
        verifyNever(mockUserRepository.findByEmail(any));
      });
    });

    group("ロール管理", () {
      test("getUserRole - ユーザーのロールを正常に取得する", () async {
        // Arrange
        const String userId = "test-user-id";
        final UserModel user = UserModel(
          id: userId,
          userId: userId,
          email: "test@example.com",
          displayName: "Test User",
          role: UserRole.admin,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockSupabaseAuthService.currentUser).thenReturn(mockSupabaseUser);
        when(mockSupabaseUser.id).thenReturn(userId);
        when(mockUserRepository.getById(userId)).thenAnswer((_) async => user);

        // Act
        final UserRole? result = await authService.getUserRole();

        // Assert
        expect(result, equals(UserRole.admin));
      });

      test("isAdmin - 管理者ユーザーの場合trueを返す", () async {
        // Arrange
        const String userId = "test-user-id";
        final UserModel adminUser = UserModel(
          id: userId,
          userId: userId,
          email: "admin@example.com",
          displayName: "Admin User",
          role: UserRole.admin,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockSupabaseAuthService.currentUser).thenReturn(mockSupabaseUser);
        when(mockSupabaseUser.id).thenReturn(userId);
        when(mockUserRepository.getById(userId)).thenAnswer((_) async => adminUser);

        // Act
        final bool result = await authService.isAdmin();

        // Assert
        expect(result, isTrue);
      });

      test("isAdmin - 一般ユーザーの場合falseを返す", () async {
        // Arrange
        const String userId = "test-user-id";
        final UserModel normalUser = UserModel(
          id: userId,
          userId: userId,
          email: "user@example.com",
          displayName: "Normal User",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockSupabaseAuthService.currentUser).thenReturn(mockSupabaseUser);
        when(mockSupabaseUser.id).thenReturn(userId);
        when(mockUserRepository.getById(userId)).thenAnswer((_) async => normalUser);

        // Act
        final bool result = await authService.isAdmin();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
