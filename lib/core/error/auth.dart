import "base.dart";

/// 認証関連のエラーメッセージ定義
enum AuthError implements LogMessage {
  initializationFailed,
  googleAuthTimeout,
  googleAuthFailed,
  googleAuthException,
  callbackProcessingFailed,
  authorizationCodeNotFound,
  userRetrievalFailed,
  sessionRefreshFailed,
  signOutFailed,
  signOutException;

  /// 英語エラーメッセージを取得
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

  /// 日本語エラーメッセージを取得
  @override
  String get messageJa {
    switch (this) {
      case AuthError.initializationFailed:
        return "Supabaseクライアント初期化失敗: {error}";
      case AuthError.googleAuthTimeout:
        return "Google認証タイムアウト";
      case AuthError.googleAuthFailed:
        return "Google認証失敗: {message}";
      case AuthError.googleAuthException:
        return "Google認証例外: {error}";
      case AuthError.callbackProcessingFailed:
        return "認証コールバック処理失敗: {message}";
      case AuthError.authorizationCodeNotFound:
        return "コールバックURLに認証コードが見つかりません";
      case AuthError.userRetrievalFailed:
        return "認証後のユーザー取得に失敗しました";
      case AuthError.sessionRefreshFailed:
        return "セッション更新失敗: {error}";
      case AuthError.signOutFailed:
        return "サインアウト失敗: {message}";
      case AuthError.signOutException:
        return "サインアウトエラー: {error}";
    }
  }

  /// 組み合わせメッセージ（英語 + 日本語）を取得
  @override
  String get combinedMessage => "$message ($messageJa)";
}

/// 認証関連の情報メッセージ定義
enum AuthInfo implements LogMessage {
  clientInitialized,
  googleAuthStarted,
  googleOAuthResponse,
  callbackProcessing,
  callbackProcessed,
  sessionRefreshing,
  sessionRefreshed,
  userSigningOut,
  userSignedOut;

  /// 英語情報メッセージを取得
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

  /// 日本語情報メッセージを取得
  @override
  String get messageJa {
    switch (this) {
      case AuthInfo.clientInitialized:
        return "Supabaseクライアント初期化成功";
      case AuthInfo.googleAuthStarted:
        return "Google OAuth認証開始";
      case AuthInfo.googleOAuthResponse:
        return "Google OAuth応答受信: {response}";
      case AuthInfo.callbackProcessing:
        return "認証コールバック処理: {url}";
      case AuthInfo.callbackProcessed:
        return "認証コールバック処理成功 ユーザー: {userId}";
      case AuthInfo.sessionRefreshing:
        return "セッション更新中";
      case AuthInfo.sessionRefreshed:
        return "セッション更新成功";
      case AuthInfo.userSigningOut:
        return "ユーザーサインアウト";
      case AuthInfo.userSignedOut:
        return "ユーザーサインアウト成功";
    }
  }

  /// 組み合わせメッセージ（英語 + 日本語）を取得
  @override
  String get combinedMessage => "$message ($messageJa)";
}
