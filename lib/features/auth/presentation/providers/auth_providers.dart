import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/utils/provider_logger.dart";
import "../../models/auth_config.dart";
import "../../models/auth_state.dart";
import "../../models/user_profile.dart";
import "../../repositories/auth_repository.dart";
import "../../services/auth_service.dart";

part "auth_providers.g.dart";

// =================================================================
// 基盤プロバイダ
// =================================================================

/// 認証設定プロバイダ
/// プラットフォーム別の認証設定を提供
@riverpod
AuthConfig authConfig(Ref ref) => AuthConfig.forCurrentPlatform();

/// 認証リポジトリプロバイダ
/// Supabase Authとの通信を管理
@riverpod
AuthRepository authRepository(Ref ref) {
  final AuthConfig config = ref.watch(authConfigProvider);
  return AuthRepository(config: config);
}

/// 認証サービスプロバイダ
/// 認証のビジネスロジックを管理
@riverpod
AuthService authService(Ref ref) {
  final AuthRepository repository = ref.watch(authRepositoryProvider);
  final AuthConfig config = ref.watch(authConfigProvider);
  return AuthService(authRepository: repository, config: config);
}

// =================================================================
// 認証状態管理プロバイダ
// =================================================================

/// 認証状態Notifier
/// AuthServiceの状態変更を監視し、Riverpodで管理
@riverpod
class AuthStateNotifier extends _$AuthStateNotifier with ProviderLoggerMixin {
  @override
  String get providerComponent => "AuthStateNotifier";
  late AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    
    // AuthServiceの状態変更をStreamで監視
    ref.listen<AuthService>(authServiceProvider, (AuthService? previous, AuthService current) {
      _authService = current;
    });
    
    // 初期化時にセッション復元を試行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });

    // 初期状態を返す
    return _authService.currentState;
  }
  
  /// 認証システムを初期化
  Future<void> _initializeAuth() async {
    try {
      logDebug("認証システムの初期化を開始");
      await _authService.restoreSession();
      // 状態が変更された場合、Notifierに反映
      state = _authService.currentState;
      logInfo("セッション復元が完了しました");
    } catch (e, stackTrace) {
      // セッション復元エラーをログに記録（未認証状態として扱う）
      logSessionRestoreFailed(e, stackTrace);
      // 状態を明示的に初期状態に設定
      state = _authService.currentState;
    }
  }

  /// Google OAuth認証を開始
  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
    state = _authService.currentState;
  }

  /// OAuth認証のコールバックを処理
  Future<void> handleOAuthCallback(String callbackUrl) async {
    await _authService.handleOAuthCallback(callbackUrl);
    state = _authService.currentState;
  }

  /// セッションを復元
  Future<void> restoreSession() async {
    await _authService.restoreSession();
    state = _authService.currentState;
  }

  /// セッションを更新
  Future<void> refreshSession() async {
    await _authService.refreshSession();
    state = _authService.currentState;
  }

  /// ログアウト
  Future<void> signOut({bool allDevices = false}) async {
    await _authService.signOut(allDevices: allDevices);
    state = _authService.currentState;
  }

  /// 自動セッション更新を開始
  void startAutoRefresh() {
    _authService.startAutoRefresh();
  }

  /// 自動セッション更新を停止
  void stopAutoRefresh() {
    _authService.stopAutoRefresh();
  }

  /// エラー状態をクリア
  void clearError() {
    if (state.hasError) {
      state = AuthState.initial();
    }
  }
}

// =================================================================
// 認証情報プロバイダ（computed）
// =================================================================

/// 認証済みかどうか
@riverpod
bool isAuthenticated(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.isAuthenticated;
}

/// 認証中かどうか
@riverpod
bool isAuthenticating(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.isAuthenticating;
}

/// 認証エラーがあるかどうか
@riverpod
bool hasAuthError(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.hasError;
}

/// 認証エラーメッセージ
@riverpod
String? authErrorMessage(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.error;
}

/// 現在のユーザー情報
@riverpod
UserProfile? currentUser(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.user;
}

/// 現在のユーザーID
@riverpod
String? currentUserId(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.userId;
}

/// 現在のユーザー名（表示用）
@riverpod
String? currentUserDisplayName(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.user?.effectiveDisplayName;
}

/// 現在のユーザーのメールアドレス
@riverpod
String? currentUserEmail(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.user?.email;
}

/// 現在のユーザーのアバターURL
@riverpod
String? currentUserAvatarUrl(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.user?.avatarUrl;
}

/// 現在のユーザーの初期化文字（アバター用）
@riverpod
String currentUserInitials(Ref ref) {
  final AuthState state = ref.watch(authStateNotifierProvider);
  return state.user?.initials ?? "U";
}

// =================================================================
// セッション管理プロバイダ
// =================================================================

/// セッションが有効かどうか
@riverpod
bool isSessionValid(Ref ref) {
  final AuthService service = ref.watch(authServiceProvider);
  return service.isSessionValid();
}

/// セッションの残り時間（秒）
@riverpod
int sessionRemainingSeconds(Ref ref) {
  final AuthService service = ref.watch(authServiceProvider);
  return service.getSessionRemainingSeconds();
}

/// セッションの期限が近いかどうか
@riverpod
bool isSessionExpiringSoon(Ref ref) {
  final AuthService service = ref.watch(authServiceProvider);
  return service.isSessionExpiringSoon();
}

// =================================================================
// UI状態管理プロバイダ
// =================================================================

/// ログイン画面表示状態
@riverpod
class LoginScreenState extends _$LoginScreenState {
  @override
  LoginScreenStateData build() => const LoginScreenStateData();

  /// ログイン処理中状態を设置
  void setLoggingIn(bool isLoggingIn) {
    state = state.copyWith(isLoggingIn: isLoggingIn);
  }

  /// エラーメッセージを設定
  void setError(String? error) {
    state = state.copyWith(error: error, clearError: error == null);
  }

  /// 成功メッセージを設定
  void setSuccess(String? success) {
    state = state.copyWith(success: success, clearSuccess: success == null);
  }

  /// 状態をリセット
  void reset() {
    state = const LoginScreenStateData();
  }
}

/// ログイン画面の状態データ
class LoginScreenStateData {
  const LoginScreenStateData({
    this.isLoggingIn = false,
    this.error,
    this.success,
  });

  /// ログイン処理中かどうか
  final bool isLoggingIn;

  /// エラーメッセージ
  final String? error;

  /// 成功メッセージ
  final String? success;

  /// エラーがあるかどうか
  bool get hasError => error != null;

  /// 成功メッセージがあるかどうか
  bool get hasSuccess => success != null;

  /// 状態をコピーして新しいインスタンスを作成
  LoginScreenStateData copyWith({
    bool? isLoggingIn,
    String? error,
    String? success,
    bool clearError = false,
    bool clearSuccess = false,
  }) => LoginScreenStateData(
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
      error: clearError ? null : (error ?? this.error),
      success: clearSuccess ? null : (success ?? this.success),
    );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is LoginScreenStateData &&
        other.isLoggingIn == isLoggingIn &&
        other.error == error &&
        other.success == success;
  }

  @override
  int get hashCode => Object.hash(isLoggingIn, error, success);

  @override
  String toString() => "LoginScreenStateData("
        "isLoggingIn: $isLoggingIn, "
        "hasError: $hasError, "
        "hasSuccess: $hasSuccess"
        ")";
}

// =================================================================
// デバッグ用プロバイダ
// =================================================================

/// 認証デバッグ情報
@riverpod
Map<String, dynamic> authDebugInfo(Ref ref) {
  final AuthService service = ref.watch(authServiceProvider);
  return service.getDebugInfo();
}