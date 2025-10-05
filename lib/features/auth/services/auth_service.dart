import "dart:async";

import "package:supabase_flutter/supabase_flutter.dart" as supabase
  show AuthChangeEvent, AuthState, Session;

import "../../../core/constants/exceptions/auth/auth_exception.dart";
import "../../../core/contracts/auth/auth_repository_contract.dart" as contract;
import "../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../core/utils/stream_manager_mixin.dart";
import "../../../infra/supabase/supabase_client.dart";
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
enum _SupabaseSessionLifecycleState {
  idle,
  warmingUp,
  ready,
  failed,
}

const Duration _defaultSessionWarmupTimeout = Duration(seconds: 4);

class AuthService with StreamControllerManagerMixin {
  AuthService({
    required log_contract.LoggerContract logger,
    contract.AuthRepositoryContract<UserProfile, local.AuthResponse>? authRepository,
    AuthConfig? config,
  }) : _logger = logger,
       _authRepository = authRepository ?? AuthRepository(logger: logger, config: config),
       _config = config ?? AuthConfig.forCurrentPlatform() {
    // StreamControllerを管理対象に追加
    addController(_stateController, debugName: "auth_state_controller", source: "AuthService");
    _attachSupabaseAuthListener();
  }

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final contract.AuthRepositoryContract<UserProfile, local.AuthResponse> _authRepository;
  final AuthConfig _config;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  /// 現在の認証状態
  AuthState _currentState = AuthState.initial();

  /// 認証状態の変更を通知するStreamController
  final StreamController<AuthState> _stateController = StreamController<AuthState>.broadcast();

  String get loggerComponent => "AuthService";

  _SupabaseSessionLifecycleState _sessionLifecycleState = _SupabaseSessionLifecycleState.idle;
  Completer<void>? _sessionReadyCompleter;
  Timer? _sessionWarmupTimeoutTimer;
  DateTime? _lastSupabaseSessionSyncedAt;

  bool get isSupabaseSessionReady =>
      _sessionLifecycleState == _SupabaseSessionLifecycleState.ready &&
      _lastSupabaseSessionSyncedAt != null &&
      isSessionValid();

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

  Future<void> ensureSupabaseSessionReady({Duration timeout = _defaultSessionWarmupTimeout}) async {
    if (isSupabaseSessionReady) {
      return;
    }

    if (_sessionLifecycleState == _SupabaseSessionLifecycleState.failed) {
      _sessionLifecycleState = _SupabaseSessionLifecycleState.idle;
    }

    final Completer<void> completer = _prepareSessionWarmupCompleter(timeout);

    try {
      if (!isAuthenticated || !isSessionValid()) {
        await refreshSession();
      } else {
        _markSessionReady(source: "ensure.cached");
      }
    } catch (error, stackTrace) {
      _sessionLifecycleState = _SupabaseSessionLifecycleState.failed;
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }

    await completer.future;
  }

  Completer<void> _prepareSessionWarmupCompleter(Duration timeout) {
    if (_sessionReadyCompleter != null && !_sessionReadyCompleter!.isCompleted) {
      return _sessionReadyCompleter!;
    }

    _sessionLifecycleState = _SupabaseSessionLifecycleState.warmingUp;
    _sessionWarmupTimeoutTimer?.cancel();

    final Completer<void> completer = Completer<void>();
    _sessionReadyCompleter = completer;
    _sessionWarmupTimeoutTimer = Timer(timeout, () {
      if (completer.isCompleted) {
        return;
      }
      final TimeoutException error = TimeoutException(
        "Supabase session warm-up timed out after ${timeout.inMilliseconds}ms",
      );
      _sessionLifecycleState = _SupabaseSessionLifecycleState.failed;
      completer.completeError(error, StackTrace.current);
      log.e(
        "Supabase session warm-up timed out",
        tag: loggerComponent,
        fields: <String, Object?>{"timeoutMs": timeout.inMilliseconds},
        error: error,
      );
    });

    log.d(
      "Supabase session warm-up started",
      tag: loggerComponent,
      fields: <String, Object?>{"timeoutMs": timeout.inMilliseconds},
    );

    return completer;
  }

  void _markSessionReady({required String source}) {
    _sessionWarmupTimeoutTimer?.cancel();
    _sessionWarmupTimeoutTimer = null;
    _sessionLifecycleState = _SupabaseSessionLifecycleState.ready;
    _lastSupabaseSessionSyncedAt = DateTime.now();

    final Completer<void>? completer = _sessionReadyCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _sessionReadyCompleter = null;

    log.d(
      "Supabase session ready",
      tag: loggerComponent,
      fields: <String, Object?>{
        "source": source,
        "syncedAt": _lastSupabaseSessionSyncedAt?.toIso8601String(),
      },
    );
  }

  void _resetSessionWarmup({String reason = "reset", Object? error, StackTrace? stackTrace}) {
    _sessionWarmupTimeoutTimer?.cancel();
    _sessionWarmupTimeoutTimer = null;

    final Completer<void>? completer = _sessionReadyCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        error ?? AuthException.invalidSession(),
        stackTrace ?? StackTrace.current,
      );
    }
    _sessionReadyCompleter = null;
    _sessionLifecycleState = _SupabaseSessionLifecycleState.idle;
    _lastSupabaseSessionSyncedAt = null;

    final Map<String, Object?> fields = <String, Object?>{
      "reason": reason,
      if (error != null) "error": error.toString(),
    };

    if (error != null) {
      log.e(
        "Supabase session warm-up reset due to error",
        tag: loggerComponent,
        fields: fields,
        error: error,
        st: stackTrace,
      );
    } else {
      log.d(
        "Supabase session warm-up reset",
        tag: loggerComponent,
        fields: fields,
      );
    }
  }

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

    if (!SupabaseClientService.isInitialized) {
      log.w(
        "Supabase client is not initialized; auth state listener will not start",
        tag: loggerComponent,
      );
      return;
    }

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
          await _synchronizeSessionFromSupabase(
            supabaseState.session,
            source: "supabase.${supabaseState.event.name}",
          );
          break;
        case supabase.AuthChangeEvent.initialSession:
          if (supabaseState.session != null) {
            await _synchronizeSessionFromSupabase(
              supabaseState.session,
              source: "supabase.${supabaseState.event.name}",
            );
          } else {
            _resetSessionWarmup(reason: "supabase.initialSession.empty");
            _updateState(AuthState.initial());
          }
          break;
        case supabase.AuthChangeEvent.signedOut:
          _resetSessionWarmup(reason: "supabase.signedOut");
          _updateState(AuthState.initial());
          break;
        // ignore: deprecated_member_use
        case supabase.AuthChangeEvent.userDeleted:
          _resetSessionWarmup(reason: "supabase.userDeleted");
          _updateState(AuthState.initial());
          break;
        case supabase.AuthChangeEvent.passwordRecovery:
        case supabase.AuthChangeEvent.mfaChallengeVerified:
          log.d(
            "Supabase auth event '${supabaseState.event.name}' received; no state transition",
            tag: loggerComponent,
          );
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

  Future<void> _synchronizeSessionFromSupabase(
    supabase.Session? session, {
    String source = "supabase.event",
  }) async {
    if (session == null) {
      log.w("Supabase session is null during synchronization", tag: loggerComponent);
      _resetSessionWarmup(reason: "$source.nullSession");
      _updateState(AuthState.initial());
      return;
    }

    final UserProfile? userProfile = await _resolveUserProfile(session);
    if (userProfile == null) {
      log.w("User profile could not be resolved from Supabase session", tag: loggerComponent);
      _resetSessionWarmup(reason: "$source.profileUnavailable");
      _updateState(AuthState.initial());
      return;
    }

    _updateState(AuthState.authenticated(userProfile));
    _markSessionReady(source: source);
    log.i(
      "Supabase session synchronized for user: ${userProfile.email}",
      tag: loggerComponent,
      fields: <String, Object?>{"source": source},
    );
  }

  Future<UserProfile?> _resolveUserProfile(supabase.Session session) async => UserProfile.fromSupabaseUser(session.user);

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
        await ensureSupabaseSessionReady(timeout: const Duration(seconds: 6));
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
    } catch (e, stackTrace) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      _resetSessionWarmup(reason: "signInWithGoogle.error", error: e, stackTrace: stackTrace);
      log.e(
        "Google OAuth authentication error: $errorMessage",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
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
        await ensureSupabaseSessionReady(timeout: const Duration(seconds: 6));
      } else {
        final String error = response.error ?? "OAuth callback failed";
        _updateState(AuthState.error(error));
        log.e("OAuth callback failed: $error", tag: loggerComponent);
      }
    } catch (e, stackTrace) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      _resetSessionWarmup(reason: "handleOAuthCallback.error", error: e, stackTrace: stackTrace);
      log.e(
        "OAuth callback error: $errorMessage",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
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
        if (isSessionValid()) {
          _markSessionReady(source: "restoreSession");
        }
        log.i("Session restored successfully: ${userProfile.email}", tag: loggerComponent);
      } else {
        _resetSessionWarmup(reason: "restoreSession.noSession");
        _updateState(AuthState.initial());
        log.d("No valid session found", tag: loggerComponent);
      }
    } catch (e, stackTrace) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _updateState(AuthState.error(errorMessage));
      _resetSessionWarmup(reason: "restoreSession.error", error: e, stackTrace: stackTrace);
      log.e(
        "Session restoration failed: $errorMessage",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
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
        _markSessionReady(source: "refreshSession");
        log.i(
          "Session refreshed successfully: ${user.email}",
          tag: loggerComponent,
          fields: <String, Object?>{
            "expiresAt": response.session?.expiresAt.toIso8601String(),
          },
        );
        return;
      }

      final String errorMessage = response.error ?? "Session refresh failed";
      final AuthException exception = AuthException.invalidSession(session: "refresh_failed");
      _updateState(AuthState.error(errorMessage));
      _updateState(AuthState.initial());
      _resetSessionWarmup(reason: "refreshSession.invalid", error: exception);
      log.e(
        "Session refresh failed: $errorMessage",
        tag: loggerComponent,
        error: exception,
        fields: <String, Object?>{"errorCode": response.error},
      );
      throw exception;
    } catch (e, stackTrace) {
      final AuthException exception = e is AuthException ? e : AuthException.invalidSession();
      final String errorMessage = exception.message;
      _updateState(AuthState.error(errorMessage));
      _updateState(AuthState.initial());
      _resetSessionWarmup(
        reason: "refreshSession.exception",
        error: exception,
        stackTrace: stackTrace,
      );
      log.e(
        "Session refresh error: $errorMessage",
        tag: loggerComponent,
        error: exception,
        st: stackTrace,
      );
      throw exception;
    }
  }

  /// ログアウト
  Future<void> signOut({bool allDevices = false}) async {
    try {
      final String? userEmail = currentUser?.email;
      log.i("Signing out user: ${userEmail ?? 'unknown'}", tag: loggerComponent);

      await _authRepository.signOut(allDevices: allDevices);

      _updateState(AuthState.initial());
      _resetSessionWarmup(reason: "signOut.success");
      log.i("User signed out successfully: ${userEmail ?? 'unknown'}", tag: loggerComponent);
    } catch (e, stackTrace) {
      final String errorMessage = e is AuthException ? e.message : e.toString();
      _resetSessionWarmup(reason: "signOut.error", error: e, stackTrace: stackTrace);
      log.e(
        "Sign out failed: $errorMessage",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );

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
  _sessionWarmupTimeoutTimer?.cancel();
  _sessionWarmupTimeoutTimer = null;

    // StreamControllerManagerMixinを使用してStreamControllerを安全に破棄
    disposeControllers();

    log.d("AuthService disposed", tag: loggerComponent);
  }
}
