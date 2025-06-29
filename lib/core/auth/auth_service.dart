import "dart:async";

import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../constants/log_enums/auth.dart";
import "../utils/log_service.dart";

/// Supabaseクライアントを管理するシングルトンサービス
///
/// OAuth認証とユーザー管理機能を提供します。
/// 詳細なドキュメントは docs/auth-*.md を参照してください。
class SupabaseClientService {
  // プライベートコンストラクタ
  SupabaseClientService._();
  static SupabaseClientService? _instance;
  static SupabaseClient? _client;

  /// シングルトンインスタンスを取得
  static SupabaseClientService get instance {
    _instance ??= SupabaseClientService._();
    return _instance!;
  }

  /// Supabaseクライアントを取得
  ///
  /// 初期化されていない場合は自動的に初期化を実行します。
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError("Supabase client is not initialized. Call initialize() first.");
    }
    return _client!;
  }

  /// 環境変数設定
  static String get _supabaseUrl {
    final String? url = dotenv.env["SUPABASE_URL"];
    if (url == null || url.isEmpty) {
      throw StateError("SUPABASE_URL is not set in environment variables");
    }
    return url;
  }

  static String get _supabaseAnonKey {
    final String? key = dotenv.env["SUPABASE_ANON_KEY"];
    if (key == null || key.isEmpty) {
      throw StateError("SUPABASE_ANON_KEY is not set in environment variables");
    }
    return key;
  }

  static String get _redirectUrl =>
      dotenv.env["REDIRECT_URL"] ?? "io.supabase.flutterquickstart://login-callback/";

  /// Supabaseクライアントの初期化
  ///
  /// アプリケーション起動時に一度だけ呼び出してください。
  static Future<void> initialize() async {
    if (_client != null) {
      return; // 既に初期化済み
    }

    try {
      // .envファイルの読み込み
      await dotenv.load();

      // Supabase Flutterクライアントの初期化
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

      _client = Supabase.instance.client;
      LogService.infoWithMessage("SupabaseClientService", AuthInfo.clientInitialized);
    } catch (e) {
      LogService.errorWithMessage(
        "SupabaseClientService",
        AuthError.initializationFailed,
        <String, String>{"error": e.toString()},
        e,
      );
      throw SupabaseClientException("Failed to initialize Supabase client: ${e.toString()}");
    }
  }

  /// Google OAuth認証を開始
  ///
  /// Returns: 認証が開始された場合はtrue
  Future<bool> signInWithGoogle() async {
    try {
      LogService.infoWithMessage("SupabaseClientService", AuthInfo.googleAuthStarted);

      final Completer<bool> completer = Completer<bool>();
      Timer? timeoutTimer;

      // 30秒でタイムアウト
      timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          LogService.warningWithMessage("SupabaseClientService", AuthError.googleAuthTimeout);
          completer.complete(false);
        }
      });

      final bool response = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      timeoutTimer.cancel();

      if (!completer.isCompleted) {
        final bool success = response;
        LogService.infoWithMessage(
          "SupabaseClientService",
          AuthInfo.googleOAuthResponse,
          <String, String>{"response": success.toString()},
        );
        completer.complete(success);
      }

      return await completer.future;
    } on AuthException catch (e) {
      LogService.warningWithMessage(
        "SupabaseClientService",
        AuthError.googleAuthFailed,
        <String, String>{"message": e.message},
      );
      throw SupabaseAuthException("Google authentication failed: ${e.message}");
    } catch (e) {
      LogService.errorWithMessage(
        "SupabaseClientService",
        AuthError.googleAuthException,
        <String, String>{"error": e.toString()},
        e,
      );
      throw SupabaseClientException("Failed to initiate Google authentication: ${e.toString()}");
    }
  }

  /// 認証コールバックからセッションを復元
  ///
  /// [callbackUrl] OAuth認証後のコールバックURL
  /// Returns: 認証されたユーザー情報、失敗時はnull
  Future<User?> handleAuthCallback(String callbackUrl) async {
    try {
      LogService.infoWithMessage(
        "SupabaseClientService",
        AuthInfo.callbackProcessing,
        <String, String>{"url": callbackUrl},
      );

      final Uri uri = Uri.parse(callbackUrl);

      // URLからauthorization codeを抽出
      final String? code = _extractParamValue(callbackUrl, "code");
      if (code == null) {
        LogService.warningWithMessage("SupabaseClientService", AuthError.authorizationCodeNotFound);
        throw AuthException("Authorization code not found in callback URL");
      }

      // セッションの復元（Supabase Flutter SDKが自動的に処理）
      // コールバックURLをSupabaseに渡すことで自動的にセッションが設定される
      await client.auth.getSessionFromUrl(uri);

      // 現在のユーザー情報を取得
      final User? currentUser = client.auth.currentUser;
      if (currentUser == null) {
        LogService.warningWithMessage("SupabaseClientService", AuthError.userRetrievalFailed);
        throw AuthException("Failed to retrieve user after authentication");
      }

      LogService.infoWithMessage(
        "SupabaseClientService",
        AuthInfo.callbackProcessed,
        <String, String>{"userId": currentUser.id},
      );
      return currentUser;
    } on AuthException catch (e) {
      LogService.warningWithMessage(
        "SupabaseClientService",
        AuthError.callbackProcessingFailed,
        <String, String>{"message": e.message},
      );
      throw SupabaseAuthException("Failed to handle authentication callback: ${e.message}");
    } catch (e) {
      LogService.errorWithMessage(
        "SupabaseClientService",
        AuthError.callbackProcessingFailed,
        <String, String>{"message": e.toString()},
        e,
      );
      throw SupabaseClientException("Error processing authentication callback: ${e.toString()}");
    }
  }

  /// 現在のユーザー情報を取得
  User? get currentUser => client.auth.currentUser;

  /// ユーザーがログインしているかチェック（セッション有効性含む）
  bool get isSignedIn => _isSessionValid();

  /// 現在のセッション情報を取得
  Session? get currentSession => client.auth.currentSession;

  /// セッションの有効性をチェック
  bool _isSessionValid() {
    final Session? session = currentSession;
    if (session == null) {
      return false;
    }

    // セッションの有効期限をチェック
    final DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    final DateTime now = DateTime.now();

    // 5分前にリフレッシュを試行
    final bool shouldRefresh = expiresAt.isBefore(now.add(const Duration(minutes: 5)));

    if (shouldRefresh) {
      _refreshSessionIfNeeded();
    }

    return expiresAt.isAfter(now);
  }

  /// 必要に応じてセッションをリフレッシュ
  Future<void> _refreshSessionIfNeeded() async {
    try {
      LogService.infoWithMessage("SupabaseClientService", AuthInfo.sessionRefreshing);
      await client.auth.refreshSession();
      LogService.infoWithMessage("SupabaseClientService", AuthInfo.sessionRefreshed);
    } catch (e) {
      LogService.warningWithMessage(
        "SupabaseClientService",
        AuthError.sessionRefreshFailed,
        <String, String>{"error": e.toString()},
      );
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      LogService.infoWithMessage("SupabaseClientService", AuthInfo.userSigningOut);
      await client.auth.signOut();
      LogService.infoWithMessage("SupabaseClientService", AuthInfo.userSignedOut);
    } on AuthException catch (e) {
      LogService.warningWithMessage(
        "SupabaseClientService",
        AuthError.signOutFailed,
        <String, String>{"message": e.message},
      );
      throw SupabaseAuthException("Failed to sign out: ${e.message}");
    } catch (e) {
      LogService.errorWithMessage(
        "SupabaseClientService",
        AuthError.signOutException,
        <String, String>{"error": e.toString()},
        e,
      );
      throw SupabaseClientException("Error during sign out: ${e.toString()}");
    }
  }

  /// 認証状態の変更を監視するStream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// URLパラメータから指定した値を取得するヘルパーメソッド
  String? _extractParamValue(String url, String paramName) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    return uri.queryParameters[paramName];
  }
}

/// Supabaseクライアント関連の汎用例外
class SupabaseClientException implements Exception {
  /// コンストラクタ
  const SupabaseClientException(this.message);

  /// エラーメッセージ
  final String message;

  @override
  String toString() => "SupabaseClientException: $message";
}

/// Supabase認証関連の例外
class SupabaseAuthException implements Exception {
  /// コンストラクタ
  const SupabaseAuthException(this.message);

  /// エラーメッセージ
  final String message;

  @override
  String toString() => "SupabaseAuthException: $message";
}
