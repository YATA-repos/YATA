import "../../log_enums/auth.dart";
import "../base/base_context_exception.dart";
import "../base/exception_types.dart";

/// 認証関連の例外クラス
///
/// 認証システムで発生するエラーを管理します。
/// AuthErrorと連携して、型安全なエラーハンドリングを提供します。
class AuthException extends BaseContextException<AuthError> {
  /// AuthErrorを使用したコンストラクタ
  AuthException(super.error, {super.params, super.code});

  /// 認証初期化失敗例外の作成
  factory AuthException.initializationFailed(String error) =>
      AuthException(AuthError.initializationFailed, params: <String, String>{"error": error});

  /// OAuth認証失敗例外の作成
  factory AuthException.oauthFailed(String error, {String? provider}) => AuthException(
    AuthError.oauthFailed,
    params: <String, String>{"error": error, if (provider != null) "provider": provider},
  );

  /// 無効セッション例外の作成
  factory AuthException.invalidSession({String? session}) => AuthException(
    AuthError.invalidSession,
    params: <String, String>{if (session != null) "session": session},
  );

  /// ユーザー情報取得失敗例外の作成
  factory AuthException.userInfoFetchFailed(String error) =>
      AuthException(AuthError.userInfoFetchFailed, params: <String, String>{"error": error});

  /// ログアウト失敗例外の作成
  factory AuthException.logoutFailed(String error) =>
      AuthException(AuthError.logoutFailed, params: <String, String>{"error": error});

  /// 無効プロバイダー例外の作成
  factory AuthException.invalidProvider(String provider) =>
      AuthException(AuthError.invalidProvider, params: <String, String>{"provider": provider});

  /// トークン期限切れ例外の作成
  factory AuthException.tokenExpired({String? token}) => AuthException(
    AuthError.tokenExpired,
    params: <String, String>{if (token != null) "token": token},
  );

  /// 無効トークン例外の作成
  factory AuthException.invalidToken({String? token}) => AuthException(
    AuthError.invalidToken,
    params: <String, String>{if (token != null) "token": token},
  );

  /// 認証キャンセル例外の作成
  factory AuthException.authenticationCancelled() =>
      AuthException(AuthError.authenticationCancelled);

  /// ネットワークエラー例外の作成
  factory AuthException.networkError(String error) =>
      AuthException(AuthError.networkError, params: <String, String>{"error": error});

  /// サービス利用不可例外の作成
  factory AuthException.serviceUnavailable({String? service}) => AuthException(
    AuthError.serviceUnavailable,
    params: <String, String>{if (service != null) "service": service},
  );

  /// 例外タイプ
  ExceptionType get type => ExceptionType.authentication;

  /// エラーの重要度を取得
  ExceptionSeverity get severity {
    switch (error) {
      case AuthError.initializationFailed:
      case AuthError.serviceUnavailable:
        return ExceptionSeverity.critical;
      case AuthError.oauthFailed:
      case AuthError.invalidSession:
      case AuthError.userInfoFetchFailed:
      case AuthError.logoutFailed:
      case AuthError.networkError:
        return ExceptionSeverity.high;
      case AuthError.tokenExpired:
      case AuthError.invalidToken:
      case AuthError.invalidProvider:
        return ExceptionSeverity.medium;
      case AuthError.authenticationCancelled:
        return ExceptionSeverity.low;
    }
  }
}
