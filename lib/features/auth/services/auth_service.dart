import "dart:async";

import "package:supabase_flutter/supabase_flutter.dart" as supabase
    show AuthChangeEvent, AuthState, Session;

import "../../../core/constants/exceptions/auth/auth_exception.dart";
import "../../../core/contracts/auth/auth_repository_contract.dart" as contract;
// Removed LoggerComponent mixin; use local tag
import "../../../core/logging/compat.dart" as log;
import "../../../core/utils/stream_manager_mixin.dart";
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
class AuthService with StreamControllerManagerMixin {
  AuthService({
    contract.AuthRepositoryContract<UserProfile, local.AuthResponse>? authRepository,
    AuthConfig? config,
  }) : _authRepository = authRepository ?? AuthRepository(config: config),
       _config = config ?? AuthConfig.forCurrentPlatform() {
    // StreamControllerを管理対象に追加
    addController(_stateController, debugName: "auth_state_controller", source: "AuthService");
    _attachSupabaseAuthListener();
  }

  final contract.AuthRepositoryContract<UserProfile, local.AuthResponse> _authRepository;
  final AuthConfig _config;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  /// 現在の認証状態
  AuthState _currentState = AuthState.initial();

  /// 認証状態の変更を通知するStreamController
  final StreamController<AuthState> _stateController = StreamController<AuthState>.broadcast();

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
    log.d("Auth state updated: ${newState.status}", tag: loggerComponent);
  }

  /// 認証済みかどうか
  bool get isAuthenticated => _currentState.isAuthenticated;

  /// 認証中かどうか
  bool get isAuthenticating => _currentState.isAuthenticating;

  /// 現在のユーザー情報を取得
  UserProfile? get currentUser => _currentState.user;

  /// 現在のユーザーIDを取得
  String? get currentUserId => _currentState.userId;

  void _attachSupabaseAuthListener() {
    if (_authRepository is! AuthRepository) {
      log.w(
        "AuthRepository does not expose Supabase auth state changes; automatic session sync is disabled",
        tag: loggerComponent,
      );
      return;
    }

    _authStateSubscription?.cancel();
    final AuthRepository concreteRepository = _authRepository;
    _authStateSubscription = concreteRepository.authStateChanges.listen(
      (supabase.AuthState supabaseState) {
        log.d(
          "Received Supabase auth event: ${supabaseState.event.name}",
          tag: loggerComponent,
        );
        unawaited(_handleSupabaseAuthState(supabaseState));
      },
      onError: (Object error, StackTrace stackTrace) {
        log.e(
          "Supabase auth state stream error: $error",
          tag: loggerComponent,
          error: error,
          st: stackTrace,
        );
      },
    );
  }

  Future<void> _handleSupabaseAuthState(supabase.AuthState supabaseState) async {
    try {
      switch (supabaseState.event) {
        case supabase.AuthChangeEvent.signedIn:
        case supabase.AuthChangeEvent.tokenRefreshed:
        case supabase.AuthChangeEvent.userUpdated:
          await _synchronizeSessionFromSupabase(supabaseState.session);
          break;
        case supabase.AuthChangeEvent.initialSession:
          if (supabaseState.session != null) {
            await _synchronizeSessionFromSupabase(supabaseState.session);
          } else {
            _updateState(AuthState.initial());
          }
          break;
        case supabase.AuthChangeEvent.signedOut:
          _updateState(AuthState.initial());
          break;
        case supabase.AuthChangeEvent.passwordRecovery:
        case supabase.AuthChangeEvent.mfaChallengeVerified:
          log.d(
            "Supabase auth event '${supabaseState.event.name}' received; no state transition",
            tag: loggerComponent,
          );
          break;
        default:
          _updateState(AuthState.initial());
          break;
      }
    } on Object catch (error, stackTrace) {
      final String message = error is AuthException ? error.message : error.toString();
      _updateState(AuthState.error(message));
      log.e(
        "Failed to process Supabase auth event: $message",
        tag: loggerComponent,
        error: error,
        st: stackTrace,
      );
    }
  }

  Future<void> _synchronizeSessionFromSupabase(supabase.Session? session) async {
    if (session == null) {
      log.w("Supabase session is null during synchronization", tag: loggerComponent);
      _updateState(AuthState.initial());
      return;
    }

    final UserProfile? userProfile = await _resolveUserProfile(session);
    if (userProfile == null) {
      log.w("User profile could not be resolved from Supabase session", tag: loggerComponent);
      _updateState(AuthState.initial());
      return;
    }

    _updateState(AuthState.authenticated(userProfile));
    log.i("Supabase session synchronized for user: ${userProfile.email}", tag: loggerComponent);
  }

  Future<UserProfile?> _resolveUserProfile(supabase.Session session) async {
    return UserProfile.fromSupabaseUser(session.user);
  
    try {
      return await _authRepository.getCurrentUserProfile();
    } on Object catch (error, stackTrace) {
      log.e(
        "Failed to fetch user profile during session sync: $error",
        tag: loggerComponent,
        error: error,
        st: stackTrace,
      );
      return null;
    }
  }

  // =================================================================
  // 認証操作
  // =================================================================

  /// Google OAuth認証を開始
  Future<void> signInWithGoogle() async {
    try {
      log.i("Starting Google OAuth authentication", tag: loggerComponent);
      _updateState(AuthState.loading());

      final local.AuthResponse response = await _authRepository.signInWithGoogle();

      if (response.isSuccess && response.user != null) {
        final UserProfile user = response.user!;
        _updateState(AuthState.authenticated(user));
        log.i("Google OAuth authentication successful: ${user.email}", tag: loggerComponent);
      } else if (response.isPending) {
        log.i(
          "Google OAuth authentication pending: awaiting callback",
          tag: loggerComponent,
        );
        // 状態は引き続き認証処理中のままとする
      } else {
        final String error = response.error ?? "Authentication failed";
        _updateState(AuthState.error(error));
        log.e("Google OAuth authentication failed: $error", tag: loggerComponent);
      }
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      log.e("Google OAuth authentication error: $errorMessage", tag: loggerComponent, error: e);
      rethrow;
    }
  }

  /// OAuth認証のコールバックを処理
  Future<void> handleOAuthCallback(String callbackUrl) async {
    try {
      log.d("Handling OAuth callback", tag: loggerComponent);
      _updateState(AuthState.loading());

      final local.AuthResponse response = await _authRepository.handleOAuthCallback(callbackUrl);

      if (response.isSuccess && response.user != null) {
        final UserProfile user = response.user!;
        _updateState(AuthState.authenticated(user));
        log.i("OAuth callback processed successfully: ${user.email}", tag: loggerComponent);
      } else {
        final String error = response.error ?? "OAuth callback failed";
        _updateState(AuthState.error(error));
        log.e("OAuth callback failed: $error", tag: loggerComponent);
      }
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      log.e("OAuth callback error: $errorMessage", tag: loggerComponent, error: e);
      rethrow;
    }
  }

  /// 現在のセッションからユーザー情報を復元
  Future<void> restoreSession() async {
    try {
      log.d("Attempting to restore user session", tag: loggerComponent);
      _updateState(AuthState.loading());

      final UserProfile? userProfile = await _authRepository.getCurrentUserProfile();

      if (userProfile != null) {
        _updateState(AuthState.authenticated(userProfile));
        log.i("Session restored successfully: ${userProfile.email}", tag: loggerComponent);
      } else {
        _updateState(AuthState.initial());
        log.d("No valid session found", tag: loggerComponent);
      }
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      log.e("Session restoration failed: $errorMessage", tag: loggerComponent, error: e);
    }
  }

  /// セッションを更新
  Future<void> refreshSession() async {
    try {
      log.i("Refreshing user session", tag: loggerComponent);

      final local.AuthResponse response = await _authRepository.refreshSession();

      if (response.isSuccess && response.user != null) {
        final UserProfile user = response.user!;
        _updateState(AuthState.authenticated(user));
        log.i("Session refreshed successfully: ${user.email}", tag: loggerComponent);
      } else {
        final String error = response.error ?? "Session refresh failed";
        _updateState(AuthState.error(error));
        log.e("Session refresh failed: $error", tag: loggerComponent);
      }
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      log.e("Session refresh error: $errorMessage", tag: loggerComponent, error: e);

      // セッション更新に失敗した場合は未認証状態にする
      _updateState(AuthState.initial());
    }
  }

  /// ログアウト
  Future<void> signOut({bool allDevices = false}) async {
    try {
      final String? userEmail = currentUser?.email;
      log.i("Signing out user: ${userEmail ?? 'unknown'}", tag: loggerComponent);

      await _authRepository.signOut(allDevices: allDevices);

      _updateState(AuthState.initial());
      log.i("User signed out successfully: ${userEmail ?? 'unknown'}", tag: loggerComponent);
    } catch (e) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      log.e("Sign out failed: $errorMessage", tag: loggerComponent, error: e);

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
          log.d("Auto session refresh completed", tag: loggerComponent);
        } catch (e) {
          log.e("Auto session refresh failed: $e", tag: loggerComponent, error: e);
          // 自動更新に失敗した場合はタイマーを停止
          stopAutoRefresh();
        }
      }
    });

    log.d("Auto session refresh started", tag: loggerComponent);
  }

  /// 自動セッション更新を停止
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    log.d("Auto session refresh stopped", tag: loggerComponent);
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
    "stream_controllers": getControllerDebugInfo(),
    "repository": _repositoryDebugInfo(),
  };

  Map<String, dynamic>? _repositoryDebugInfo() {
    try {
      if (_authRepository is AuthRepository) {
        return _authRepository.getDebugInfo();
      }
      return <String, dynamic>{"type": _authRepository.runtimeType.toString()};
    } catch (_) {
      return null;
    }
  }

  /// サービスを破棄
  void dispose() {
    // メモリリーク警告をチェック
    if (hasControllerMemoryLeak) {
      final String? warning = controllerMemoryLeakWarningMessage;
      if (warning != null) {
        log.w("AuthService dispose時にメモリリーク警告: $warning", tag: loggerComponent);
      }
    }

    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    stopAutoRefresh();

    // StreamControllerManagerMixinを使用してStreamControllerを安全に破棄
    disposeControllers();

    log.d("AuthService disposed", tag: loggerComponent);
  }
}
