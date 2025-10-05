import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../core/contracts/logging/logger.dart" as log_contract;
import "../../models/auth_state.dart";
import "../../services/auth_service.dart";

/// 認証状態をRiverpodで管理するStateNotifier。
///
/// [AuthService]の状態更新ストリームを購読し、UI層へ反映する。
class AuthController extends StateNotifier<AuthState> {
  /// [AuthController]を生成する。
  AuthController({
    required log_contract.LoggerContract logger,
    required AuthService authService,
  })  : _logger = logger,
        _authService = authService,
      super(authService.currentState) {
    _subscription = _authService.authStateChanges.listen(
      _handleStateChange,
      onError: _handleStreamError,
    );
    _handleAutoRefresh(authService.currentState);
    unawaited(_restoreSession());
  }

  static const String _loggerTag = "AuthController";

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final AuthService _authService;
  StreamSubscription<AuthState>? _subscription;

  /// Google OAuthによるログイン/サインアップを開始する。
  Future<void> signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
    } catch (error, stackTrace) {
      log.e("Google OAuthサインインに失敗しました: $error", error: error, st: stackTrace, tag: _loggerTag);
      rethrow;
    }
  }

  /// OAuthリダイレクトのコールバックURLを処理する。
  Future<void> handleOAuthCallback(String callbackUrl) async {
    try {
      await _authService.handleOAuthCallback(callbackUrl);
    } catch (error, stackTrace) {
      log.e("OAuthコールバック処理に失敗しました: $error", error: error, st: stackTrace, tag: _loggerTag);
      rethrow;
    }
  }

  /// サインアウト処理を行う。
  Future<void> signOut({bool allDevices = false}) async {
    try {
      await _authService.signOut(allDevices: allDevices);
    } catch (error, stackTrace) {
      log.e("サインアウトに失敗しました: $error", error: error, st: stackTrace, tag: _loggerTag);
      rethrow;
    } finally {
      if (!state.isAuthenticated) {
        _authService.stopAutoRefresh();
      }
    }
  }

  /// ストリームから通知された認証状態を反映する。
  void _handleStateChange(AuthState newState) {
    state = newState;
    _handleAutoRefresh(newState);
  }

  /// ストリームエラーを処理する。
  void _handleStreamError(Object error, StackTrace stackTrace) {
    log.e("AuthStateストリームでエラーが発生しました: $error", error: error, st: stackTrace, tag: _loggerTag);
    state = AuthState.error(error.toString());
  }

  Future<void> _restoreSession() async {
    try {
      await _authService.restoreSession();
    } catch (error, stackTrace) {
      log.e("セッション復元に失敗しました: $error", error: error, st: stackTrace, tag: _loggerTag);
      state = AuthState.error(error.toString());
    }
  }

  void _handleAutoRefresh(AuthState newState) {
    if (newState.isAuthenticated) {
      _authService.startAutoRefresh();
    } else {
      _authService.stopAutoRefresh();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authService.stopAutoRefresh();
    super.dispose();
  }
}
