import "dart:async";

import "package:test/test.dart";

import "package:yata/core/constants/exceptions/auth/auth_exception.dart";
import "package:yata/core/contracts/auth/auth_repository_contract.dart" as auth_contract;
import "package:yata/core/contracts/logging/logger.dart" as log_contract;
import "package:yata/core/logging/levels.dart";
import "package:yata/features/auth/dto/auth_response.dart";
import "package:yata/features/auth/models/user_profile.dart";
import "package:yata/features/auth/services/auth_service.dart";

void main() {
  group("AuthService.ensureSupabaseSessionReady", () {
    late _TestLogger logger;
    late _FakeAuthRepository repository;
    late AuthService authService;

    setUp(() {
      logger = _TestLogger();
      repository = _FakeAuthRepository();
      authService = AuthService(logger: logger, authRepository: repository);
    });

    tearDown(() {
      authService.dispose();
    });

    test("returns immediately when session already valid", () async {
      repository
        ..currentUserProfile = _testUser()
        ..sessionValid = true
        ..remainingSeconds = 3600;

      await authService.restoreSession();

      expect(repository.refreshCalls, 0);

      await authService.ensureSupabaseSessionReady();

      expect(repository.refreshCalls, 0);
      expect(authService.isSupabaseSessionReady, isTrue);
    });

    test("performs refresh when session not yet ready", () async {
      repository
        ..nextRefreshResponse = _successResponse()
        ..sessionValid = false
        ..remainingSeconds = 0;

      await authService.ensureSupabaseSessionReady();

      expect(repository.refreshCalls, 1);
      expect(authService.isSupabaseSessionReady, isTrue);
      expect(authService.isAuthenticated, isTrue);
    });

    test("throws when refresh fails", () async {
      repository
        ..nextRefreshError = AuthException.invalidSession()
        ..sessionValid = false;

      await expectLater(
        authService.ensureSupabaseSessionReady(timeout: const Duration(milliseconds: 100)),
        throwsA(isA<AuthException>()),
      );

      expect(repository.refreshCalls, 1);
      expect(authService.isSupabaseSessionReady, isFalse);
    });
  });
}

class _FakeAuthRepository
    implements auth_contract.AuthRepositoryContract<UserProfile, AuthResponse> {
  UserProfile? currentUserProfile;
  bool sessionValid = false;
  int remainingSeconds = 0;
  int refreshCalls = 0;
  AuthResponse? nextRefreshResponse;
  Object? nextRefreshError;

  @override
  Future<AuthResponse> handleOAuthCallback(String callbackUrl) async =>
      AuthResponse.failure(error: "not_supported");

  @override
  Future<UserProfile?> getCurrentUserProfile() async => currentUserProfile;

  @override
  int getSessionRemainingSeconds() => remainingSeconds;

  @override
  bool isSessionValid() => sessionValid;

  @override
  Future<AuthResponse> refreshSession() async {
    refreshCalls += 1;

    if (nextRefreshError != null) {
      throw nextRefreshError!;
    }

    final AuthResponse? response = nextRefreshResponse;
    if (response == null) {
      throw AuthException.invalidSession();
    }

    sessionValid = response.session?.isValid ?? false;
    currentUserProfile = response.user;
    remainingSeconds = response.session?.remainingSeconds ?? 0;
    return response;
  }

  @override
  Future<AuthResponse> signInWithGoogle() async => AuthResponse.failure(error: "not_supported");

  @override
  Future<void> signOut({bool allDevices = false}) async {}
}

class _TestLogger implements log_contract.LoggerContract {
  @override
  void log(
    Level level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  }) {}

  @override
  void t(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(Level.trace, msgOrThunk, tag: tag, fields: fields);

  @override
  void d(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(Level.debug, msgOrThunk, tag: tag, fields: fields);

  @override
  void i(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(Level.info, msgOrThunk, tag: tag, fields: fields);

  @override
  void w(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(Level.warn, msgOrThunk, tag: tag, fields: fields);

  @override
  void e(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
      log(Level.error, msgOrThunk, tag: tag, fields: fields, error: error, st: st);

  @override
  void f(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
      log(Level.fatal, msgOrThunk, tag: tag, fields: fields, error: error, st: st);

  @override
  void clearFatalHandlers() {}

  @override
  Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)}) async {}

  @override
  void registerFatalHandler(log_contract.FatalHandler handler) {}

  @override
  void removeFatalHandler(log_contract.FatalHandler handler) {}
}

AuthResponse _successResponse() => AuthResponse.success(
  user: _testUser(),
  session: AuthSession(
    accessToken: "token",
    tokenType: "bearer",
    expiresIn: 3600,
    expiresAt: DateTime.now().add(const Duration(minutes: 45)),
    refreshToken: "refresh",
  ),
);

UserProfile _testUser() =>
    UserProfile(email: "tester@yata.dev", id: "user-1", userId: "user-1", displayName: "Tester");
