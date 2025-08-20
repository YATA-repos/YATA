import "package:supabase_flutter/supabase_flutter.dart" hide AuthException;

import "../../../core/constants/exceptions/auth/auth_exception.dart";
import "../../../core/logging/logger_mixin.dart";
import "../../../infrastructure/supabase/supabase_client.dart";
import "../dto/auth_request.dart";
import "../dto/auth_response.dart" as local;
import "../models/auth_config.dart";
import "../models/user_profile.dart";

/// 認証リポジトリ
/// 
/// Supabase Authとの通信を管理します。
/// OAuth認証、セッション管理、ユーザー情報取得を提供します。
class AuthRepository with LoggerMixin {
  AuthRepository({AuthConfig? config}) : _config = config ?? AuthConfig.forCurrentPlatform();

  /// 認証設定
  final AuthConfig _config;

  /// Supabaseクライアント取得
  SupabaseClient get _client => SupabaseClientService.client;

  /// 現在のセッション取得
  Session? get currentSession => _client.auth.currentSession;

  /// 現在のユーザー取得
  User? get currentUser => _client.auth.currentUser;

  /// 認証状態の変更を監視
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // =================================================================
  // OAuth認証
  // =================================================================

  /// Google OAuth認証を開始
  Future<local.AuthResponse> signInWithGoogle() async {
    try {
      logDebug("Starting Google OAuth authentication");
      
      final AuthRequest request = AuthRequest.google(
        redirectTo: _config.callbackUrl,
        scopes: _config.scopes,
      );

      logDebug("OAuth request: ${request.toString()}");

      // Supabaseで認証開始
      final bool success = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: request.redirectTo,
        scopes: request.scopes.join(" "),
        queryParams: request.queryParams,
      );

      if (!success) {
        throw AuthException.oauthFailed("Failed to initiate OAuth flow", provider: "google");
      }

      logInfo("Google OAuth authentication started successfully");
      
      // OAuth開始成功を示すレスポンスを返す（実際のユーザー情報はコールバックで取得）
      return local.AuthResponse.success(
        user: UserProfile(email: "oauth_pending"), // 仮のユーザー情報
      );
    } catch (e) {
      logError("Google OAuth authentication failed: $e", e);
      
      if (e is AuthException) {
        rethrow;
      } else {
        throw AuthException.oauthFailed(e.toString(), provider: "google");
      }
    }
  }

  /// OAuth認証のコールバックを処理
  Future<local.AuthResponse> handleOAuthCallback(String callbackUrl) async {
    try {
      logDebug("Handling OAuth callback: $callbackUrl");

      // URLからセッション情報を抽出
      final Uri uri = Uri.parse(callbackUrl);
      final Map<String, String> params = uri.queryParameters;

      // エラーチェック
      if (params.containsKey("error")) {
        final String error = params["error"] ?? "unknown_error";
        final String? errorDescription = params["error_description"];
        
        logError("OAuth callback error: $error${errorDescription != null ? ' - $errorDescription' : ''}");

        return local.AuthResponse.failure(
          error: error,
          errorDescription: errorDescription,
        );
      }

      // セッション情報の取得
      final Session? session = currentSession;
      if (session == null) {
        throw AuthException.invalidSession();
      }

      final User? user = currentUser;
      if (user == null) {
        throw AuthException.userInfoFetchFailed("No user data found in session");
      }

      final UserProfile userProfile = UserProfile.fromSupabaseUser(user);
      
      logInfo("OAuth authentication successful for user: ${userProfile.email}");

      return local.AuthResponse.success(
        user: userProfile,
        session: local.AuthSession.fromSupabase(session),
      );
    } catch (e) {
      logError("OAuth callback handling failed: $e", e);
      
      if (e is AuthException) {
        rethrow;
      } else {
        throw AuthException.oauthFailed(e.toString());
      }
    }
  }

  // =================================================================
  // セッション管理
  // =================================================================

  /// 現在のセッションからユーザー情報を取得
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final User? user = currentUser;
      if (user == null) {
        logDebug("No current user found");
        return null;
      }

      final UserProfile profile = UserProfile.fromSupabaseUser(user);
      
      logInfo("User profile fetched for: ${profile.email}");

      return profile;
    } catch (e) {
      logError("Failed to fetch user profile: $e", e);
      throw AuthException.userInfoFetchFailed(e.toString());
    }
  }

  /// セッションの有効性をチェック
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
  Future<local.AuthResponse> refreshSession() async {
    try {
      logDebug("Refreshing authentication session");

      final AuthResponse response = await _client.auth.refreshSession();
      
      if (response.session == null) {
        throw AuthException.invalidSession();
      }

      final User? user = response.session?.user;
      if (user == null) {
        throw AuthException.userInfoFetchFailed("No user data in refreshed session");
      }

      final UserProfile userProfile = UserProfile.fromSupabaseUser(user);
      
      logInfo("Session refreshed for user: ${userProfile.email}");

      return local.AuthResponse.success(
        user: userProfile,
        session: local.AuthSession.fromSupabase(response.session!),
      );
    } catch (e) {
      logError("Session refresh failed: $e", e);
      
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
  Future<void> signOut({bool allDevices = false}) async {
    try {
      final String? userEmail = currentUser?.email;
      
      logDebug("Signing out user: ${userEmail ?? 'unknown'}");

      await _client.auth.signOut(
        scope: allDevices ? SignOutScope.global : SignOutScope.local,
      );

      logInfo("User signed out successfully: ${userEmail ?? 'unknown'}");
    } catch (e) {
      logError("Sign out failed: $e", e);
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