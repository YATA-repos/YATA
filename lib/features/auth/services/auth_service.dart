import "dart:async";

import "../../../core/constants/exceptions/auth/auth_exception.dart";
import "../../../core/logging/logger_mixin.dart";
import "../dto/auth_response.dart" as local;
import "../models/auth_config.dart";
import "../models/auth_state.dart";
import "../models/user_profile.dart";
import "../repositories/auth_repository.dart";

/// 認証サービス
/// 
/// 認証のビジネスロジックを管理します。
/// AuthRepositoryを使用してSupabase Authとやり取りし、
/// アプリケーション全体の認証状態を管理します。
class AuthService with LoggerMixin {
  AuthService({
    AuthRepository? authRepository,
    AuthConfig? config,
  }) : _authRepository = authRepository ?? AuthRepository(config: config),
       _config = config ?? AuthConfig.forCurrentPlatform();

  final AuthRepository _authRepository;
  final AuthConfig _config;

  /// 現在の認証状態
  AuthState _currentState = AuthState.initial();

  /// 認証状態の変更を通知するStreamController
  final StreamController<AuthState> _stateController = StreamController<AuthState>.broadcast();

  @override
  String get loggerComponent => "AuthService";

  // =================================================================
  // 認証状態管理
  // =================================================================

  /// 現在の認証状態を取得
  AuthState get currentState => _currentState;

  /// 認証状態の変更を監視
  Stream<AuthState> get authStateChanges => _stateController.stream;

  /// 認証状態を更新
  void _updateState(AuthState newState) {
    _currentState = newState;
    _stateController.add(newState);
    logDebug("Auth state updated: ${newState.status}");
  }

  /// 認証済みかどうか
  bool get isAuthenticated => _currentState.isAuthenticated;

  /// 認証中かどうか
  bool get isAuthenticating => _currentState.isAuthenticating;

  /// 現在のユーザー情報を取得
  UserProfile? get currentUser => _currentState.user;

  /// 現在のユーザーIDを取得
  String? get currentUserId => _currentState.userId;

  // =================================================================
  // 認証操作
  // =================================================================

  /// Google OAuth認証を開始
  Future<void> signInWithGoogle() async {
    try {
      logInfo("Starting Google OAuth authentication");
      _updateState(AuthState.loading());

      final local.AuthResponse response = await _authRepository.signInWithGoogle();

      if (response.isSuccess && response.user != null) {
        final UserProfile user = response.user!;
        _updateState(AuthState.authenticated(user));
        logInfo("Google OAuth authentication successful: ${user.email}");
      } else {
        final String error = response.error ?? "Authentication failed";
        _updateState(AuthState.error(error));
        logError("Google OAuth authentication failed: $error");
      }
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      logError("Google OAuth authentication error: $errorMessage", e);
      rethrow;
    }
  }

  /// OAuth認証のコールバックを処理
  Future<void> handleOAuthCallback(String callbackUrl) async {
    try {
      logDebug("Handling OAuth callback");
      _updateState(AuthState.loading());

      final local.AuthResponse response = await _authRepository.handleOAuthCallback(callbackUrl);

      if (response.isSuccess && response.user != null) {
        final UserProfile user = response.user!;
        _updateState(AuthState.authenticated(user));
        logInfo("OAuth callback processed successfully: ${user.email}");
      } else {
        final String error = response.error ?? "OAuth callback failed";
        _updateState(AuthState.error(error));
        logError("OAuth callback failed: $error");
      }
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      logError("OAuth callback error: $errorMessage", e);
      rethrow;
    }
  }

  /// 現在のセッションからユーザー情報を復元
  Future<void> restoreSession() async {
    try {
      logDebug("Attempting to restore user session");
      _updateState(AuthState.loading());

      final UserProfile? userProfile = await _authRepository.getCurrentUserProfile();

      if (userProfile != null) {
        _updateState(AuthState.authenticated(userProfile));
        logInfo("Session restored successfully: ${userProfile.email}");
      } else {
        _updateState(AuthState.initial());
        logDebug("No valid session found");
      }
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      logError("Session restoration failed: $errorMessage", e);
    }
  }

  /// セッションを更新
  Future<void> refreshSession() async {
    try {
      logInfo("Refreshing user session");

      final local.AuthResponse response = await _authRepository.refreshSession();

      if (response.isSuccess && response.user != null) {
        final UserProfile user = response.user!;
        _updateState(AuthState.authenticated(user));
        logInfo("Session refreshed successfully: ${user.email}");
      } else {
        final String error = response.error ?? "Session refresh failed";
        _updateState(AuthState.error(error));
        logError("Session refresh failed: $error");
      }
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      logError("Session refresh error: $errorMessage", e);
      
      // セッション更新に失敗した場合は未認証状態にする
      _updateState(AuthState.initial());
    }
  }

  /// ログアウト
  Future<void> signOut({bool allDevices = false}) async {
    try {
      final String? userEmail = currentUser?.email;
      logInfo("Signing out user: ${userEmail ?? 'unknown'}");

      await _authRepository.signOut(allDevices: allDevices);
      
      _updateState(AuthState.initial());
      logInfo("User signed out successfully: ${userEmail ?? 'unknown'}");
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      logError("Sign out failed: $errorMessage", e);
      
      // ログアウトに失敗しても状態は初期化する（安全のため）
      _updateState(AuthState.initial());
      rethrow;
    }
  }

  // =================================================================
  // セッション管理
  // =================================================================

  /// セッションの有効性をチェック
  bool isSessionValid() => _authRepository.isSessionValid();

  /// セッションの残り時間（秒）を取得
  int getSessionRemainingSeconds() => _authRepository.getSessionRemainingSeconds();

  /// セッションの期限が近いかどうかをチェック（5分以内）
  bool isSessionExpiringSoon() => getSessionRemainingSeconds() <= 300; // 5分 = 300秒

  /// 自動セッション更新を開始
  Timer? _refreshTimer;

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    
    // 5分ごとにセッションの有効性をチェック
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (Timer timer) async {
      if (isAuthenticated && isSessionExpiringSoon()) {
        try {
          await refreshSession();
          logDebug("Auto session refresh completed");
        } catch (e) {
          logError("Auto session refresh failed: $e", e);
          // 自動更新に失敗した場合はタイマーを停止
          stopAutoRefresh();
        }
      }
    });
    
    logDebug("Auto session refresh started");
  }

  /// 自動セッション更新を停止
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    logDebug("Auto session refresh stopped");
  }

  // =================================================================
  // ユーティリティ
  // =================================================================

  /// 認証設定を取得
  AuthConfig get config => _config;

  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() => <String, dynamic>{
      "state": <String, dynamic>{
        "status": _currentState.status.name,
        "isAuthenticated": isAuthenticated,
        "isAuthenticating": isAuthenticating,
        "hasError": _currentState.hasError,
        "error": _currentState.error,
        "userId": currentUserId,
        "userEmail": currentUser?.email,
      },
      "session": <String, dynamic>{
        "isValid": isSessionValid(),
        "remainingSeconds": getSessionRemainingSeconds(),
        "expiringSoon": isSessionExpiringSoon(),
        "autoRefreshActive": _refreshTimer != null,
      },
      "repository": _authRepository.getDebugInfo(),
    };

  /// サービスを破棄
  void dispose() {
    stopAutoRefresh();
    _stateController.close();
    logDebug("AuthService disposed");
  }
}