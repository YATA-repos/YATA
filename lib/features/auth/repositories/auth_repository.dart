import "dart:async";

import "package:supabase_flutter/supabase_flutter.dart" hide AuthException;

import "../../../core/constants/exceptions/auth/auth_exception.dart";
import "../../../core/contracts/auth/auth_repository_contract.dart" as contract;
import "../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../infra/supabase/supabase_client.dart";
import "../dto/auth_request.dart";
import "../dto/auth_response.dart" as local;
import "../models/auth_config.dart";
import "../models/user_profile.dart";
import "desktop_oauth_redirect_server.dart";

/// 認証リポジトリ
///
/// Supabase Authとの通信を管理します。
/// OAuth認証、セッション管理、ユーザー情報取得を提供します。
class AuthRepository implements contract.AuthRepositoryContract<UserProfile, local.AuthResponse> {
  AuthRepository({required log_contract.LoggerContract logger, AuthConfig? config})
    : _logger = logger,
      _config = config ?? AuthConfig.forCurrentPlatform();

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  /// 認証設定
  final AuthConfig _config;

  SupabaseClient? get _clientOrNull =>
      SupabaseClientService.isInitialized ? SupabaseClientService.client : null;

  /// 現在のセッション取得
  Session? get currentSession => _clientOrNull?.auth.currentSession;

  /// 現在のユーザー取得
  User? get currentUser => _clientOrNull?.auth.currentUser;

  /// 認証状態の変更を監視
  Stream<AuthState> get authStateChanges =>
      _clientOrNull?.auth.onAuthStateChange ?? Stream<AuthState>.empty();

  Future<SupabaseClient> _obtainClient({required String operation}) async {
    if (SupabaseClientService.isInSafeMode) {
      final String reason = SupabaseClientService.safeModeReason ?? "unknown";
      final String message =
          "Supabase safe mode is active ($reason); cannot execute $operation";
      log.e(message, tag: "AuthRepository");
      throw AuthException.initializationFailed(message);
    }

    if (!SupabaseClientService.isInitialized) {
      log.w(
        "Supabase client is not initialized; attempting auto-initialization for $operation",
        tag: "AuthRepository",
      );
      try {
        await SupabaseClientService.initialize();
      } on AuthException catch (error, stackTrace) {
        log.e(
          "Supabase initialization failed during $operation: ${error.message}",
          tag: "AuthRepository",
          error: error,
          st: stackTrace,
        );
        rethrow;
      } catch (error, stackTrace) {
        log.e(
          "Unexpected error during Supabase initialization for $operation: $error",
          tag: "AuthRepository",
          error: error,
          st: stackTrace,
        );
        throw AuthException.initializationFailed(error.toString());
      }
    }

    return SupabaseClientService.client;
  }

  // =================================================================
  // OAuth認証
  // =================================================================

  /// Google OAuth認証を開始
  @override
  Future<local.AuthResponse> signInWithGoogle() async {
    try {
      log.d("Starting Google OAuth authentication", tag: "AuthRepository");

      final AuthRequest request = AuthRequest.google(
        redirectTo: _config.callbackUrl,
        scopes: _config.scopes,
      );

      log.d("OAuth request: ${request.toString()}", tag: "AuthRepository");

      if (_config.platform == AuthPlatform.desktop) {
        return await _signInWithGoogleDesktop(request);
      }

  final SupabaseClient client =
      await _obtainClient(operation: "signInWithGoogle");

      final bool success = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: request.redirectTo,
        scopes: request.scopes.join(" "),
        queryParams: request.queryParams,
      );

      if (!success) {
        throw AuthException.oauthFailed("Failed to initiate OAuth flow", provider: "google");
      }

      log.i("Google OAuth authentication started successfully", tag: "AuthRepository");
      return local.AuthResponse.pending();
    } on Object catch (error) {
      log.e("Google OAuth authentication failed: $error", tag: "AuthRepository", error: error);

      if (error is AuthException) {
        rethrow;
      } else {
        throw AuthException.oauthFailed(error.toString(), provider: "google");
      }
    }
  }

  Future<local.AuthResponse> _signInWithGoogleDesktop(AuthRequest request) async {
    final Uri desktopCallbackUri = Uri.parse(request.redirectTo);
    final DesktopOAuthRedirectServer redirectServer = DesktopOAuthRedirectServer(
      logger: log,
      callbackUri: desktopCallbackUri,
    );

    await redirectServer.start();

    try {
      final SupabaseClient client =
          await _obtainClient(operation: "_signInWithGoogleDesktop");

      final bool success = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectServer.callbackUri.toString(),
        scopes: request.scopes.join(" "),
        queryParams: request.queryParams,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        throw AuthException.oauthFailed("Failed to launch OAuth flow", provider: "google");
      }

      log.i("デスクトップ向けGoogle OAuthコールバック待機を開始しました", tag: "AuthRepository");

      final Uri callbackUri = await redirectServer.waitForCallback();
      final local.AuthResponse response = await _handleOAuthRedirectUri(callbackUri);

      log.i("デスクトップ環境のOAuthフローが完了しました: ${response.user?.email}", tag: "AuthRepository");

      return response;
    } on TimeoutException catch (error, stackTrace) {
      log.e(
        "OAuth callback timed out: $error",
        tag: "AuthRepository",
        error: error,
        st: stackTrace,
      );
      throw AuthException.oauthFailed("OAuth callback timed out", provider: "google");
    } on Object catch (error, stackTrace) {
      log.e(
        "OAuth desktop flow failed: $error",
        tag: "AuthRepository",
        error: error,
        st: stackTrace,
      );
      if (error is AuthException) {
        rethrow;
      }
      throw AuthException.oauthFailed(error.toString(), provider: "google");
    } finally {
      await redirectServer.stop();
    }
  }

  /// OAuth認証のコールバックを処理
  @override
  Future<local.AuthResponse> handleOAuthCallback(String callbackUrl) async {
    try {
      log.d("Handling OAuth callback: $callbackUrl", tag: "AuthRepository");

      final Uri uri = Uri.parse(callbackUrl);
      return await _handleOAuthRedirectUri(uri);
    } on Object catch (error) {
      log.e("OAuth callback handling failed: $error", tag: "AuthRepository", error: error);

      if (error is AuthException) {
        rethrow;
      }
      throw AuthException.oauthFailed(error.toString());
    }
  }

  Future<local.AuthResponse> _handleOAuthRedirectUri(Uri uri) async {
    final Map<String, String> params = uri.queryParameters;

    if (params.containsKey("error")) {
      final String error = params["error"] ?? "unknown_error";
      final String? errorDescription = params["error_description"];

      log.e(
        "OAuth callback error: $error${errorDescription != null ? ' - $errorDescription' : ''}",
        tag: "AuthRepository",
      );

      return local.AuthResponse.failure(error: error, errorDescription: errorDescription);
    }

    final SupabaseClient client =
      await _obtainClient(operation: "_handleOAuthRedirectUri");

    final AuthSessionUrlResponse response = await client.auth.getSessionFromUrl(uri);
    final Session session = response.session;
    final User user = session.user;

    final UserProfile userProfile = UserProfile.fromSupabaseUser(user);

    log.i("OAuth authentication successful for user: ${userProfile.email}", tag: "AuthRepository");

    return local.AuthResponse.success(
      user: userProfile,
      session: local.AuthSession.fromSupabase(session),
    );
  }

  // =================================================================
  // セッション管理
  // =================================================================

  /// 現在のセッションからユーザー情報を取得
  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final User? user = currentUser;
      if (user == null) {
        log.d("No current user found", tag: "AuthRepository");
        return null;
      }

      final UserProfile profile = UserProfile.fromSupabaseUser(user);

      log.i("User profile fetched for: ${profile.email}", tag: "AuthRepository");

      return profile;
    } catch (e) {
      log.e("Failed to fetch user profile: $e", tag: "AuthRepository", error: e);
      throw AuthException.userInfoFetchFailed(e.toString());
    }
  }

  /// セッションの有効性をチェック
  @override
  bool isSessionValid() {
    final Session? session = currentSession;
    if (session == null) {
      return false;
    }

    // セッションの期限をチェック
    final DateTime? expiresAt = session.expiresAt != null
        ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
        : null;

    if (expiresAt == null) {
      return false;
    }

    return DateTime.now().isBefore(expiresAt);
  }

  /// セッションの残り時間（秒）を取得
  @override
  int getSessionRemainingSeconds() {
    final Session? session = currentSession;
    if (session == null) {
      return 0;
    }

    final DateTime? expiresAt = session.expiresAt != null
        ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
        : null;

    if (expiresAt == null) {
      return 0;
    }

    final int remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// セッションを更新
  @override
  Future<local.AuthResponse> refreshSession() async {
    try {
      log.d("Refreshing authentication session", tag: "AuthRepository");

      final SupabaseClient client =
          await _obtainClient(operation: "refreshSession");

      final AuthResponse response = await client.auth.refreshSession();

      if (response.session == null) {
        throw AuthException.invalidSession();
      }

      final User? user = response.session?.user;
      if (user == null) {
        throw AuthException.userInfoFetchFailed("No user data in refreshed session");
      }

      final UserProfile userProfile = UserProfile.fromSupabaseUser(user);

      log.i("Session refreshed for user: ${userProfile.email}", tag: "AuthRepository");

      return local.AuthResponse.success(
        user: userProfile,
        session: local.AuthSession.fromSupabase(response.session!),
      );
    } catch (e) {
      log.e("Session refresh failed: $e", tag: "AuthRepository", error: e);

      if (e is AuthException) {
        rethrow;
      } else {
        throw AuthException.invalidSession();
      }
    }
  }

  // =================================================================
  // ログアウト
  // =================================================================

  /// ログアウト
  @override
  Future<void> signOut({bool allDevices = false}) async {
    try {
      final String? userEmail = currentUser?.email;

    log.d("Signing out user: ${userEmail ?? 'unknown'}", tag: "AuthRepository");

    final SupabaseClient client =
      await _obtainClient(operation: "signOut");

    await client.auth
      .signOut(scope: allDevices ? SignOutScope.global : SignOutScope.local);

      log.i("User signed out successfully: ${userEmail ?? 'unknown'}", tag: "AuthRepository");
    } catch (e) {
      log.e("Sign out failed: $e", tag: "AuthRepository", error: e);
      throw AuthException.logoutFailed(e.toString());
    }
  }

  // =================================================================
  // ユーティリティ
  // =================================================================

  /// 認証設定を取得
  AuthConfig get config => _config;

  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() {
    final Session? session = currentSession;
    final User? user = currentUser;

    return <String, dynamic>{
      "config": _config.debugInfo,
      "session": <String, dynamic>{
        "exists": session != null,
        "isValid": isSessionValid(),
        "remainingSeconds": getSessionRemainingSeconds(),
        "hasRefreshToken": session?.refreshToken != null,
      },
      "user": <String, dynamic>{
        "exists": user != null,
        "email": user?.email,
        "provider": user?.appMetadata["provider"],
        "emailVerified": user?.emailConfirmedAt != null,
      },
    };
  }
}
