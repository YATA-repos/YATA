import "../base/base_error_msg.dart";

/// 認証関連のエラーメッセージ定義
enum AuthError implements LogMessage {
  /// Supabaseクライアントの初期化に失敗
  initializationFailed,

  /// Google認証がタイムアウト
  googleAuthTimeout,

  /// Google認証に失敗
  googleAuthFailed,

  /// Google認証で例外が発生
  googleAuthException,

  /// 認証コールバックの処理に失敗
  callbackProcessingFailed,

  /// コールバックURLに認証コードが見つからない
  authorizationCodeNotFound,

  /// 認証後のユーザー情報取得に失敗
  userRetrievalFailed,

  /// セッションの更新に失敗
  sessionRefreshFailed,

  /// サインアウトに失敗
  signOutFailed,

  /// サインアウト時に例外が発生
  signOutException;

  /// エラーメッセージを取得
  @override
  String get message {
    switch (this) {
      case AuthError.initializationFailed:
        return "Failed to initialize Supabase client: {error}";
      case AuthError.googleAuthTimeout:
        return "Google authentication timed out";
      case AuthError.googleAuthFailed:
        return "Google authentication failed: {message}";
      case AuthError.googleAuthException:
        return "Google auth exception: {error}";
      case AuthError.callbackProcessingFailed:
        return "Failed to handle authentication callback: {message}";
      case AuthError.authorizationCodeNotFound:
        return "Authorization code not found in callback URL";
      case AuthError.userRetrievalFailed:
        return "Failed to retrieve user after authentication";
      case AuthError.sessionRefreshFailed:
        return "Failed to refresh session: {error}";
      case AuthError.signOutFailed:
        return "Failed to sign out: {message}";
      case AuthError.signOutException:
        return "Error during sign out: {error}";
    }
  }
}

/// 認証関連の情報メッセージ定義
enum AuthInfo implements LogMessage {
  /// Supabaseクライアントが正常に初期化された
  clientInitialized,

  /// Google認証が開始された
  googleAuthStarted,

  /// Google OAuthの応答を受信
  googleOAuthResponse,

  /// 認証コールバックを処理中
  callbackProcessing,

  /// 認証コールバックの処理が完了
  callbackProcessed,

  /// セッションを更新中
  sessionRefreshing,

  /// セッションの更新が完了
  sessionRefreshed,

  /// ユーザーがサインアウト中
  userSigningOut,

  /// ユーザーのサインアウトが完了
  userSignedOut;

  /// 情報メッセージを取得
  @override
  String get message {
    switch (this) {
      case AuthInfo.clientInitialized:
        return "Supabase client initialized successfully";
      case AuthInfo.googleAuthStarted:
        return "Starting Google OAuth authentication";
      case AuthInfo.googleOAuthResponse:
        return "Google OAuth response received: {response}";
      case AuthInfo.callbackProcessing:
        return "Processing auth callback: {url}";
      case AuthInfo.callbackProcessed:
        return "Auth callback processed successfully for user: {userId}";
      case AuthInfo.sessionRefreshing:
        return "Refreshing auth session";
      case AuthInfo.sessionRefreshed:
        return "Session refreshed successfully";
      case AuthInfo.userSigningOut:
        return "Signing out user";
      case AuthInfo.userSignedOut:
        return "User signed out successfully";
    }
  }
}
