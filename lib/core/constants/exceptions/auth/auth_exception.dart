import "../../log_enums/log_enums.dart";
import "../base/base_context_exception.dart";
import "../base/exception_types.dart";
import "../base/yata_exception.dart";

/// 認証関連の例外クラス
///
/// 認証プロセス中に発生するエラーを管理します。
/// AuthErrorまたはAuthInfoと連携して、型安全なエラーハンドリングを提供します。
class AuthException extends BaseContextException<AuthError> {
  /// AuthErrorを使用したコンストラクタ
  AuthException(super.error, {super.params, super.code});

  /// 認証タイムアウト例外の作成
  factory AuthException.timeout() => AuthException(AuthError.googleAuthTimeout);

  /// Google認証失敗例外の作成
  factory AuthException.googleAuthFailed(String message) =>
      AuthException(AuthError.googleAuthFailed, params: <String, String>{"message": message});

  /// Supabase初期化失敗例外の作成
  factory AuthException.initializationFailed(String error) =>
      AuthException(AuthError.initializationFailed, params: <String, String>{"error": error});

  /// セッション更新失敗例外の作成
  factory AuthException.sessionRefreshFailed(String error) =>
      AuthException(AuthError.sessionRefreshFailed, params: <String, String>{"error": error});

  /// コールバック処理失敗例外の作成
  factory AuthException.callbackProcessingFailed(String message) => AuthException(
    AuthError.callbackProcessingFailed,
    params: <String, String>{"message": message},
  );

  /// 認証コード未発見例外の作成
  factory AuthException.authorizationCodeNotFound() =>
      AuthException(AuthError.authorizationCodeNotFound);

  /// ユーザー情報取得失敗例外の作成
  factory AuthException.userRetrievalFailed() => AuthException(AuthError.userRetrievalFailed);

  /// サインアウト失敗例外の作成
  factory AuthException.signOutFailed(String message) =>
      AuthException(AuthError.signOutFailed, params: <String, String>{"message": message});

  /// サインアウト時例外の作成
  factory AuthException.signOutException(String error) =>
      AuthException(AuthError.signOutException, params: <String, String>{"error": error});

  /// Google認証例外の作成
  factory AuthException.googleAuthException(String error) =>
      AuthException(AuthError.googleAuthException, params: <String, String>{"error": error});

  /// 例外タイプ
  ExceptionType get type => ExceptionType.authentication;

  /// エラーの重要度を取得
  ExceptionSeverity get severity {
    switch (error) {
      case AuthError.initializationFailed:
      case AuthError.sessionRefreshFailed:
        return ExceptionSeverity.critical;
      case AuthError.googleAuthTimeout:
      case AuthError.googleAuthFailed:
      case AuthError.callbackProcessingFailed:
      case AuthError.userRetrievalFailed:
        return ExceptionSeverity.high;
      case AuthError.googleAuthException:
      case AuthError.authorizationCodeNotFound:
      case AuthError.signOutFailed:
      case AuthError.signOutException:
        return ExceptionSeverity.medium;
    }
  }
}

/// 認証例外
class AuthenticationException extends YataException {
  const AuthenticationException(super.message, {super.code});
}

/// 権限例外
class PermissionException extends YataException {
  const PermissionException(super.message, {super.code});
}
