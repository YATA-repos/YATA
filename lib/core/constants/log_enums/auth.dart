import "../../base/base_error_msg.dart";

/// 認証関連のエラーメッセージ定義
enum AuthError implements LogMessage {
  /// 認証初期化に失敗
  initializationFailed,

  /// OAuth認証に失敗
  oauthFailed,

  /// ユーザーセッションが無効
  invalidSession,

  /// ユーザー情報の取得に失敗
  userInfoFetchFailed,

  /// ログアウトに失敗
  logoutFailed,

  /// 認証プロバイダーが無効
  invalidProvider,

  /// 認証トークンが期限切れ
  tokenExpired,

  /// 認証トークンが無効
  invalidToken,

  /// 認証がキャンセルされた
  authenticationCancelled,

  /// ネットワークエラー
  networkError,

  /// 認証サービスが利用不可
  serviceUnavailable;

  @override
  String get message {
    switch (this) {
      case AuthError.initializationFailed:
        return "Authentication initialization failed: {error}";
      case AuthError.oauthFailed:
        return "OAuth authentication failed: {error}";
      case AuthError.invalidSession:
        return "Invalid user session: {session}";
      case AuthError.userInfoFetchFailed:
        return "Failed to fetch user information: {error}";
      case AuthError.logoutFailed:
        return "Logout failed: {error}";
      case AuthError.invalidProvider:
        return "Invalid authentication provider: {provider}";
      case AuthError.tokenExpired:
        return "Authentication token has expired: {token}";
      case AuthError.invalidToken:
        return "Invalid authentication token: {token}";
      case AuthError.authenticationCancelled:
        return "Authentication was cancelled by user";
      case AuthError.networkError:
        return "Network error during authentication: {error}";
      case AuthError.serviceUnavailable:
        return "Authentication service is unavailable: {service}";
    }
  }
}

/// 認証関連の情報メッセージ定義
enum AuthInfo implements LogMessage {
  /// 認証クライアント初期化完了
  clientInitialized,

  /// 認証成功
  authenticationSuccess,

  /// ログアウト成功
  logoutSuccess,

  /// セッション更新成功
  sessionRefreshed,

  /// ユーザー情報取得成功
  userInfoFetched;

  @override
  String get message {
    switch (this) {
      case AuthInfo.clientInitialized:
        return "Authentication client initialized successfully";
      case AuthInfo.authenticationSuccess:
        return "User authentication successful: {user}";
      case AuthInfo.logoutSuccess:
        return "User logout successful: {user}";
      case AuthInfo.sessionRefreshed:
        return "User session refreshed successfully: {user}";
      case AuthInfo.userInfoFetched:
        return "User information fetched successfully: {user}";
    }
  }
}

/// 認証関連の警告メッセージ定義
enum AuthWarning implements LogMessage {
  /// セッション期限が近い
  sessionExpiringSoon,

  /// 認証プロバイダーの変更
  providerChanged,

  /// 複数セッション検出
  multipleSessionsDetected;

  @override
  String get message {
    switch (this) {
      case AuthWarning.sessionExpiringSoon:
        return "User session will expire soon: {expires_at}";
      case AuthWarning.providerChanged:
        return "Authentication provider changed: {old_provider} -> {new_provider}";
      case AuthWarning.multipleSessionsDetected:
        return "Multiple active sessions detected for user: {user}";
    }
  }
}