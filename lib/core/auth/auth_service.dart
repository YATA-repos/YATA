import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:mutex/mutex.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../constants/app_config.dart";
import "../constants/log_enums/auth.dart";
import "../utils/log_service.dart";
import "../utils/logger_mixin.dart";
import "../utils/stream_manager_mixin.dart";
import "local_auth_server.dart";

// * 静的メソッドはLoggerMixinを使用できないため、一部ではLogServiceを直接使用
class SupabaseClientService with LoggerMixin, StreamManagerMixin {
  SupabaseClientService._();
  static SupabaseClientService? _instance;
  static SupabaseClient? _client;

  // セッション更新の排他制御用Mutex
  final Mutex _sessionRefreshMutex = Mutex();
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;
  Timer? _sessionMonitorTimer;
  LocalAuthServer? _localAuthServer;

  // 認証プロセスの排他制御用
  final Mutex _authMutex = Mutex();
  bool _isAuthenticating = false;
  Completer<bool>? _authCompleter;

  // タイムアウト設定
  static const Duration _authTimeout = Duration(minutes: 2);
  static const Duration _connectionTestTimeout = Duration(seconds: 10);
  static const Duration _callbackTimeout = Duration(seconds: 30);

  // シングルトンインスタンスの取得
  static SupabaseClientService get instance {
    _instance ??= SupabaseClientService._();
    return _instance!;
  }

  // Supabaseクライアントの取得
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

  /// エラーメッセージをユーザー向けの分かりやすいメッセージに変換
  static String _convertToUserFriendlyMessage(String originalError) {
    final String lowerError = originalError.toLowerCase();
    
    if (lowerError.contains("network") || lowerError.contains("connection")) {
      return "ネットワーク接続に問題があります。インターネット接続を確認してください。";
    } else if (lowerError.contains("timeout") || lowerError.contains("タイムアウト") || lowerError.contains("制限時間")) {
      return "認証処理がタイムアウトしました。しばらく待ってから再度お試しください。";
    } else if (lowerError.contains("authorization code")) {
      return "認証プロセスでエラーが発生しました。ブラウザを閉じて再度お試しください。";
    } else if (lowerError.contains("invalid") && lowerError.contains("code")) {
      return "認証コードが無効です。再度ログインをお試しください。";
    } else if (lowerError.contains("session")) {
      return "セッションの作成に失敗しました。再度ログインをお試しください。";
    } else if (lowerError.contains("supabase") && lowerError.contains("接続")) {
      return "認証サーバーへの接続に失敗しました。ネットワーク接続を確認してください。";
    } else if (lowerError.contains("server")) {
      return "サーバーで一時的な問題が発生しています。しばらく待ってから再試行してください。";
    } else if (lowerError.contains("rate limit")) {
      return "リクエストが多すぎます。しばらく待ってから再試行してください。";
    } else {
      return "認証に失敗しました。しばらく待ってから再度お試しください。";
    }
  }

  /// Supabaseクライアントの初期化
  ///
  /// アプリケーション起動時に一度だけ呼び出してください。
  static Future<void> initialize() async {
    if (_client != null) {
      LogService.info("SupabaseClientService", "DEBUG: Client already initialized, skipping");
      return; // 既に初期化済み
    }

    try {
      LogService.info("SupabaseClientService", "DEBUG: Starting Supabase client initialization");
      LogService.info("SupabaseClientService", "DEBUG: URL configured: ${_supabaseUrl.substring(0, 20)}...");
      LogService.info("SupabaseClientService", "DEBUG: ANON_KEY configured: ${_supabaseAnonKey.substring(0, 20)}...");

      // Supabaseクライアントの初期化
      LogService.info("SupabaseClientService", "DEBUG: Calling Supabase.initialize()");
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

      _client = Supabase.instance.client;
      LogService.info("SupabaseClientService", "DEBUG: Supabase client instance created successfully");

      // 初期化直後の状態確認
      LogService.info("SupabaseClientService", "DEBUG: Current user after init: ${_client?.auth.currentUser?.id ?? 'none'}");
      LogService.info("SupabaseClientService", "DEBUG: Current session after init: ${_client?.auth.currentSession != null}");

      // セッション監視を開始
      LogService.info("SupabaseClientService", "DEBUG: Starting session monitoring");
      instance._startSessionMonitoring();

      LogService.infoWithMessage("SupabaseClientService", AuthInfo.clientInitialized);
      LogService.info("SupabaseClientService", "DEBUG: Supabase client initialization completed successfully");
    } catch (e) {
      LogService.error("SupabaseClientService", "DEBUG: Failed to initialize Supabase client: ${e.runtimeType} - $e");
      LogService.errorWithMessage(
        "SupabaseClientService",
        AuthError.initializationFailed,
        <String, String>{"error": e.toString()},
        e,
      );
      throw SupabaseClientException("Failed to initialize Supabase client: ${e.toString()}");
    }
  }

  /// Supabaseへの接続をテスト
  ///
  /// Returns: 接続が成功した場合は`true`
  static Future<bool> testConnection() async {
    try {
      LogService.info("SupabaseClientService", "Testing connection to Supabase with timeout of ${_connectionTestTimeout.inSeconds}s...");
      
      // タイムアウト付きで基本的な接続テスト - anon keyで認証なしのAPIコールを試行
      final PostgrestList? response = await _client?.from("non_existent_table").select().limit(1).timeout(
        _connectionTestTimeout,
        onTimeout: () {
          LogService.error("SupabaseClientService", "Connection test timed out after ${_connectionTestTimeout.inSeconds}s");
          throw TimeoutException("Connection test timed out", _connectionTestTimeout);
        },
      );
      
      // テーブルが存在しないエラーでも、接続自体は成功している
      LogService.info("SupabaseClientService", "Connection test completed - Supabase is reachable");
      return true;
    } on PostgrestException catch (e) {
      // PostgreSQL関連のエラーは接続は成功している証拠
      if (e.code == "PGRST116" || e.message.contains("relation") || e.message.contains("does not exist")) {
        LogService.info("SupabaseClientService", "Connection test successful (table not found error is expected)");
        return true;
      }
      LogService.error("SupabaseClientService", "Connection test failed with PostgrestException: ${e.code} - ${e.message}");
      return false;
    } on AuthException catch (e) {
      // 認証エラーも接続は成功している証拠（サーバーと通信できている）
      LogService.info("SupabaseClientService", "Connection test successful (auth error indicates server communication: ${e.message})");
      return true;
    } catch (e) {
      LogService.error("SupabaseClientService", "Connection test failed with unexpected error: ${e.runtimeType} - $e");
      return false;
    }
  }

  /// Supabase接続の詳細情報を取得
  static Future<Map<String, dynamic>> getConnectionInfo() async {
    try {
      LogService.info("SupabaseClientService", "DEBUG: Gathering connection information");
      final Map<String, dynamic> info = <String, dynamic>{};
      
      // 基本情報
      info["supabase_url"] = _supabaseUrl;
      info["has_anon_key"] = _supabaseAnonKey.isNotEmpty;
      info["client_initialized"] = _client != null;
      LogService.info("SupabaseClientService", "DEBUG: Basic info - client_initialized: ${_client != null}");
      
      // 接続テスト
      LogService.info("SupabaseClientService", "DEBUG: Performing connection test for diagnostic");
      final bool isConnected = await testConnection();
      info["connection_status"] = isConnected ? "connected" : "failed";
      LogService.info("SupabaseClientService", "DEBUG: Connection test result: $isConnected");
      
      // 現在の認証状態
      final String? currentUserId = _client?.auth.currentUser?.id;
      final bool sessionExists = _client?.auth.currentSession != null;
      info["current_user"] = currentUserId ?? "none";
      info["session_exists"] = sessionExists;
      
      LogService.info("SupabaseClientService", "DEBUG: Auth state - user: ${currentUserId ?? 'none'}, session: $sessionExists");
      
      // セッション詳細（存在する場合）
      if (sessionExists) {
        final Session session = _client!.auth.currentSession!;
        info["session_expires_at"] = session.expiresAt;
        info["session_token_type"] = session.tokenType;
        LogService.info("SupabaseClientService", "DEBUG: Session details - expires_at: ${session.expiresAt}, token_type: ${session.tokenType}");
      }
      
      LogService.info("SupabaseClientService", "DEBUG: Complete connection info: $info");
      return info;
    } catch (e) {
      LogService.error("SupabaseClientService", "DEBUG: Failed to get connection info: ${e.runtimeType} - $e");
      return <String, dynamic>{"error": e.toString()};
    }
  }

  /// Google OAuth認証を開始
  ///
  /// Returns: 認証が開始された場合は`true`
  Future<bool> signInWithGoogle() async {
    LogService.info("SupabaseClientService", "Starting Google sign-in with overall timeout of ${_authTimeout.inMinutes} minutes");
    
    // 排他制御：認証が既に進行中の場合は待機
    await _authMutex.acquire();
    try {
      // 既に認証が進行中の場合は、その結果を待つ
      if (_isAuthenticating && _authCompleter != null) {
        LogService.info("SupabaseClientService", "Authentication already in progress, waiting for completion...");
        _authMutex.release(); // Mutexを解放してから待機
        return await _authCompleter!.future;
      }
      
      // 認証プロセス開始
      _isAuthenticating = true;
      _authCompleter = Completer<bool>();
      
      try {
        final bool result = await _signInWithGoogleInternal().timeout(
          _authTimeout,
          onTimeout: () {
            LogService.error("SupabaseClientService", "Google sign-in timed out after ${_authTimeout.inMinutes} minutes");
            _localAuthServer?.stop();
            throw TimeoutException("認証処理が制限時間を超過しました。再度お試しください。", _authTimeout);
          },
        );
        
        // 成功時にCompleterを完了
        if (!_authCompleter!.isCompleted) {
          _authCompleter!.complete(result);
        }
        
        return result;
      } catch (e) {
        // エラー時にCompleterを完了
        if (!_authCompleter!.isCompleted) {
          _authCompleter!.completeError(e);
        }
        rethrow;
      } finally {
        _isAuthenticating = false;
        _authCompleter = null;
      }
    } finally {
      if (_authMutex.isLocked) {
        _authMutex.release();
      }
    }
  }

  /// Google OAuth認証の内部実装
  Future<bool> _signInWithGoogleInternal() async {
    final Completer<bool> completer = Completer<bool>();
    try {
      LogService.info("SupabaseClientService", "DEBUG: === Starting Google OAuth Authentication Internal Implementation ===");
      logInfoMessage(AuthInfo.googleAuthStarted);
      
      // プラットフォーム詳細情報
      LogService.info("SupabaseClientService", "DEBUG: Platform details - OS: ${Platform.operatingSystem}, isWeb: $kIsWeb");
      LogService.info("SupabaseClientService", "DEBUG: Platform environment variables:");
      LogService.info("SupabaseClientService", "DEBUG: - DISPLAY: ${Platform.environment['DISPLAY'] ?? 'not set'}");
      LogService.info("SupabaseClientService", "DEBUG: - WAYLAND_DISPLAY: ${Platform.environment['WAYLAND_DISPLAY'] ?? 'not set'}");
      LogService.info("SupabaseClientService", "DEBUG: - XDG_SESSION_TYPE: ${Platform.environment['XDG_SESSION_TYPE'] ?? 'not set'}");
      
      // 認証前の状態確認
      final User? currentUser = client.auth.currentUser;
      final Session? currentSession = client.auth.currentSession;
      LogService.info("SupabaseClientService", "DEBUG: Auth state before OAuth - user: ${currentUser?.id ?? 'none'}, session: ${currentSession != null}");
      
      if (currentUser != null) {
        LogService.info("SupabaseClientService", "DEBUG: Current user details - email: ${currentUser.email}, created_at: ${currentUser.createdAt}");
      }
      
      if (currentSession != null) {
        LogService.info("SupabaseClientService", "DEBUG: Current session details - expires_at: ${currentSession.expiresAt}");
      }

      // 接続テストを実行
      LogService.info("SupabaseClientService", "Performing pre-auth connection test...");
      final bool isConnected = await testConnection();
      if (!isConnected) {
        LogService.error("SupabaseClientService", "Pre-auth connection test failed - cannot proceed with authentication");
        throw SupabaseClientException("Supabaseへの接続に失敗しました。ネットワーク接続を確認してください。");
      }
      LogService.info("SupabaseClientService", "Pre-auth connection test passed");

      // 接続情報をログ出力
      final Map<String, dynamic> connectionInfo = await getConnectionInfo();
      LogService.info("SupabaseClientService", "Connection info before auth: $connectionInfo");

      // Linuxの場合、ローカルサーバーを起動してコールバックを待つ
      if (Platform.isLinux) {
        LogService.info("SupabaseClientService", "DEBUG: === Setting up LocalAuthServer for Linux platform ===");
        LogService.info("SupabaseClientService", "DEBUG: Creating LocalAuthServer instance with callbacks");
        
        _localAuthServer = LocalAuthServer(
          onAuthSuccess: () {
            LogService.info("SupabaseClientService", "DEBUG: ✅ LocalAuthServer SUCCESS callback triggered");
            LogService.info("SupabaseClientService", "DEBUG: Completer status - isCompleted: ${completer.isCompleted}");
            if (!completer.isCompleted) {
              LogService.info("SupabaseClientService", "DEBUG: Completing OAuth process with success=true");
              completer.complete(true);
            } else {
              LogService.warning("SupabaseClientService", "DEBUG: ⚠️  SUCCESS callback called but completer already completed");
            }
          },
          onAuthFailure: (String error) {
            LogService.error("SupabaseClientService", "DEBUG: ❌ LocalAuthServer FAILURE callback triggered");
            LogService.error("SupabaseClientService", "DEBUG: Failure reason: $error");
            LogService.info("SupabaseClientService", "DEBUG: Completer status - isCompleted: ${completer.isCompleted}");
            if (!completer.isCompleted) {
              LogService.info("SupabaseClientService", "DEBUG: Completing OAuth process with success=false");
              logWarningMessage(AuthError.googleAuthFailed, <String, String>{"error": error});
              completer.complete(false);
            } else {
              LogService.warning("SupabaseClientService", "DEBUG: ⚠️  FAILURE callback called but completer already completed");
            }
          },
        );
        
        LogService.info("SupabaseClientService", "DEBUG: LocalAuthServer instance created, attempting to start server");
        
        try {
          await _localAuthServer!.start();
          LogService.info("SupabaseClientService", "DEBUG: ✅ LocalAuthServer started successfully on localhost:3000");
          
          // サーバー状態の確認
          LogService.info("SupabaseClientService", "DEBUG: Server state - isRunning: ${_localAuthServer!.isRunning}");
        } catch (e) {
          LogService.error("SupabaseClientService", "DEBUG: ❌ Failed to start LocalAuthServer: ${e.runtimeType} - $e");
          rethrow;
        }
      } else {
        LogService.info("SupabaseClientService", "DEBUG: Non-Linux platform detected, skipping LocalAuthServer setup");
      }

      // プロバイダgoogle指定でOAuthを開始
      LogService.info("SupabaseClientService", "DEBUG: === Initiating OAuth with Google provider ===");
      final String redirectUrl = kIsWeb ? "null (web default)" : "http://localhost:3000/";
      LogService.info("SupabaseClientService", "DEBUG: OAuth parameters:");
      LogService.info("SupabaseClientService", "DEBUG: - Provider: Google");
      LogService.info("SupabaseClientService", "DEBUG: - Redirect URL: $redirectUrl");
      LogService.info("SupabaseClientService", "DEBUG: - Launch Mode: externalApplication");
      LogService.info("SupabaseClientService", "DEBUG: - Is Web: $kIsWeb");
      
      LogService.info("SupabaseClientService", "DEBUG: Calling client.auth.signInWithOAuth()...");
      
      bool oauthResponse = false;
      
      try {
        oauthResponse = await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : "http://localhost:3000/",
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
        LogService.info("SupabaseClientService", "DEBUG: ✅ signInWithOAuth() completed successfully with result: $oauthResponse");
      } catch (e) {
        LogService.error("SupabaseClientService", "DEBUG: ❌ signInWithOAuth() failed: ${e.runtimeType} - $e");
        
        // WSL2などでブラウザ起動に失敗した場合、環境設定を試行
        if (e.toString().contains("Launch Error") || e.toString().contains("Failed to launch URL")) {
          LogService.info("SupabaseClientService", "DEBUG: Browser launch failed - attempting WSL2 browser fix...");
          
          // WSL2環境でのブラウザ起動修正を試行
          try {
            await _fixWSL2BrowserLaunch();
            
            // 修正後に再度OAuth試行
            LogService.info("SupabaseClientService", "DEBUG: Retrying OAuth after WSL2 browser fix...");
            oauthResponse = await client.auth.signInWithOAuth(
              OAuthProvider.google,
              redirectTo: kIsWeb ? null : "http://localhost:3000/",
              authScreenLaunchMode: LaunchMode.externalApplication,
            );
            LogService.info("SupabaseClientService", "DEBUG: ✅ OAuth retry successful after WSL2 fix: $oauthResponse");
          } catch (retryError) {
            LogService.error("SupabaseClientService", "DEBUG: OAuth retry failed, providing fallback instructions");
            
            debugPrint("========================================");
            debugPrint("🔧 WSL2 BROWSER SETUP REQUIRED");
            debugPrint("========================================");
            debugPrint("WSL2 browser launch failed. Please run this command in your WSL2 terminal:");
            debugPrint("");
            debugPrint("export BROWSER='/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'");
            debugPrint("");
            debugPrint("Then restart the app and try login again.");
            debugPrint("Alternatively, ensure 'wsl-open' or 'wslu' is installed.");
            debugPrint("========================================");
            
            throw SupabaseClientException("WSL2ブラウザ起動の設定が必要です。上記の手順に従って設定してください。");
          }
        } else {
          rethrow; // 他のエラーは再スロー
        }
      }

      LogService.info("SupabaseClientService", "OAuth initiation response: $oauthResponse");

      // Web以外のプラットフォームで、かつローカルサーバーを使用していない場合
      if (!Platform.isLinux && !kIsWeb) {
        LogService.info("SupabaseClientService", "Non-Linux, non-web platform - returning OAuth response directly");
        return oauthResponse;
      }

      // Linuxの場合、ローカルサーバーからの結果を待つ（タイムアウト付き）
      if (Platform.isLinux) {
        LogService.info("SupabaseClientService", "DEBUG: === Linux platform - waiting for LocalAuthServer callback ===");
        LogService.info("SupabaseClientService", "DEBUG: Callback timeout: ${_callbackTimeout.inSeconds}s");
        LogService.info("SupabaseClientService", "DEBUG: Expected process: Browser -> Google OAuth -> http://localhost:3000/ -> LocalAuthServer -> Callback");
        
        LogService.info("SupabaseClientService", "DEBUG: Current completer state before waiting:");
        LogService.info("SupabaseClientService", "DEBUG: - isCompleted: ${completer.isCompleted}");
        LogService.info("SupabaseClientService", "DEBUG: - LocalAuthServer running: ${_localAuthServer?.isRunning ?? false}");
        
        try {
          LogService.info("SupabaseClientService", "DEBUG: 🔄 Starting to wait for completer.future with timeout...");
          final bool result = await completer.future.timeout(
            _callbackTimeout,
            onTimeout: () {
              LogService.error("SupabaseClientService", "DEBUG: ⏰ LocalAuthServer callback TIMED OUT after ${_callbackTimeout.inSeconds}s");
              LogService.error("SupabaseClientService", "DEBUG: This indicates that the browser->Google->localhost:3000 flow did not complete");
              LogService.error("SupabaseClientService", "DEBUG: Possible causes:");
              LogService.error("SupabaseClientService", "DEBUG: 1. User closed browser without completing OAuth");
              LogService.error("SupabaseClientService", "DEBUG: 2. Network connectivity issues");
              LogService.error("SupabaseClientService", "DEBUG: 3. Firewall blocking localhost:3000");
              LogService.error("SupabaseClientService", "DEBUG: 4. LocalAuthServer crashed or stopped responding");
              throw TimeoutException("認証プロセスがタイムアウトしました。再度お試しください。", _callbackTimeout);
            },
          );
          
          LogService.info("SupabaseClientService", "DEBUG: ✅ LocalAuthServer callback completed successfully!");
          LogService.info("SupabaseClientService", "DEBUG: Authentication result: $result");
          
          // 認証後の状態確認
          final User? userAfterAuth = client.auth.currentUser;
          final Session? sessionAfterAuth = client.auth.currentSession;
          LogService.info("SupabaseClientService", "DEBUG: Auth state after callback - user: ${userAfterAuth?.id ?? 'none'}, session: ${sessionAfterAuth != null}");
          
          return result;
        } catch (e) {
          LogService.error("SupabaseClientService", "DEBUG: ❌ Error during callback waiting: ${e.runtimeType} - $e");
          LogService.info("SupabaseClientService", "DEBUG: Attempting to stop LocalAuthServer due to error...");
          
          try {
            await _localAuthServer?.stop();
            LogService.info("SupabaseClientService", "DEBUG: LocalAuthServer stopped successfully");
          } catch (stopError) {
            LogService.error("SupabaseClientService", "DEBUG: Error stopping LocalAuthServer: $stopError");
          }
          
          rethrow;
        }
      }

      LogService.info("SupabaseClientService", "Default path - returning OAuth response: $oauthResponse");
      return oauthResponse;

      // 認証失敗の場合
    } on AuthException catch (e, stackTrace) {
      LogService.error("SupabaseClientService", "DEBUG: === AuthException caught during Google sign-in ===");
      LogService.error("SupabaseClientService", "DEBUG: AuthException details:");
      LogService.error("SupabaseClientService", "DEBUG: - Message: ${e.message}");
      LogService.error("SupabaseClientService", "DEBUG: - StatusCode: ${e.statusCode}");
      LogService.error("SupabaseClientService", "DEBUG: - Stack trace: $stackTrace");
      
      logWarningMessage(AuthError.googleAuthFailed, <String, String>{"message": e.message});
      
      LogService.info("SupabaseClientService", "DEBUG: Stopping LocalAuthServer due to AuthException...");
      try {
        await _localAuthServer?.stop();
        LogService.info("SupabaseClientService", "DEBUG: LocalAuthServer stopped successfully");
      } catch (stopError) {
        LogService.error("SupabaseClientService", "DEBUG: Error stopping LocalAuthServer: $stopError");
      }
      
      final String userFriendlyMessage = _convertToUserFriendlyMessage(e.message);
      LogService.info("SupabaseClientService", "DEBUG: Converted to user-friendly message: $userFriendlyMessage");
      
      // ユーザー向けエラーメッセージを設定（UI側でキャッチする）
      throw SupabaseAuthException(userFriendlyMessage);
      // その他の例外発生時
    } catch (e, stackTrace) {
      LogService.error("SupabaseClientService", "DEBUG: === Unexpected exception caught during Google sign-in ===");
      LogService.error("SupabaseClientService", "DEBUG: Exception details:");
      LogService.error("SupabaseClientService", "DEBUG: - Type: ${e.runtimeType}");
      LogService.error("SupabaseClientService", "DEBUG: - Message: $e");
      LogService.error("SupabaseClientService", "DEBUG: - Stack trace: $stackTrace");
      
      logErrorMessage(AuthError.googleAuthException, <String, String>{"error": e.toString()}, e);
      
      LogService.info("SupabaseClientService", "DEBUG: Stopping LocalAuthServer due to unexpected exception...");
      try {
        await _localAuthServer?.stop();
        LogService.info("SupabaseClientService", "DEBUG: LocalAuthServer stopped successfully");
      } catch (stopError) {
        LogService.error("SupabaseClientService", "DEBUG: Error stopping LocalAuthServer: $stopError");
      }
      
      final String userFriendlyMessage = _convertToUserFriendlyMessage(e.toString());
      LogService.info("SupabaseClientService", "DEBUG: Converted to user-friendly message: $userFriendlyMessage");
      
      // ユーザー向けエラーメッセージを設定
      throw SupabaseClientException(userFriendlyMessage);
    }
  }


  /// WSL2環境でのブラウザ起動を修正
  Future<void> _fixWSL2BrowserLaunch() async {
    LogService.info("SupabaseClientService", "DEBUG: Attempting WSL2 browser launch fix...");
    
    try {
      // WSL2環境を検出
      final bool isWSL2 = Platform.environment.containsKey('WSL_DISTRO_NAME') || 
                         Platform.environment.containsKey('WSLENV');
      
      if (!isWSL2) {
        LogService.info("SupabaseClientService", "DEBUG: Not WSL2 environment, skipping WSL2 fix");
        return;
      }
      
      LogService.info("SupabaseClientService", "DEBUG: WSL2 environment detected, attempting browser fix");
      
      // Chrome.exeのパスを試行
      final List<String> possibleChromePaths = [
        '/mnt/c/Program Files/Google/Chrome/Application/chrome.exe',
        '/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe',
        '/mnt/c/Users/${Platform.environment['USER']}/AppData/Local/Google/Chrome/Application/chrome.exe',
        '/mnt/c/Users/penne/AppData/Local/Vivaldi/Application/vivaldi.exe',
      ];
      
      String? workingChromePath;
      for (final String path in possibleChromePaths) {
        final File chromeFile = File(path);
        if (await chromeFile.exists()) {
          workingChromePath = path;
          LogService.info("SupabaseClientService", "DEBUG: Found Chrome at: $path");
          break;
        }
      }
      
      if (workingChromePath != null) {
        LogService.info("SupabaseClientService", "DEBUG: Found working Chrome path: $workingChromePath");
        
        // WSL2環境でWindowsブラウザを直接起動するテストを実行
        try {
          LogService.info("SupabaseClientService", "DEBUG: Testing Windows browser launch via PowerShell");
          final ProcessResult result = await Process.run(
            "powershell.exe",
            ["-Command", "Start-Process", "chrome", "-ArgumentList", "\"https://www.google.com\""],
          ).timeout(const Duration(seconds: 10));
          
          if (result.exitCode == 0) {
            LogService.info("SupabaseClientService", "DEBUG: ✅ PowerShell browser launch test successful");
          } else {
            LogService.warning("SupabaseClientService", "DEBUG: PowerShell browser launch test failed: ${result.stderr}");
            throw Exception("PowerShell browser launch test failed");
          }
        } catch (e) {
          LogService.error("SupabaseClientService", "DEBUG: PowerShell test failed, trying cmd.exe approach: $e");
          
          // 代替手段: cmd.exe を使用
          try {
            final ProcessResult cmdResult = await Process.run(
              "cmd.exe",
              <String>["/c", "start", "chrome", "https://www.google.com"],
            ).timeout(const Duration(seconds: 10));
            
            if (cmdResult.exitCode == 0) {
              LogService.info("SupabaseClientService", "DEBUG: ✅ cmd.exe browser launch test successful");
            } else {
              throw Exception("cmd.exe browser launch also failed");
            }
          } catch (cmdError) {
            LogService.error("SupabaseClientService", "DEBUG: Both PowerShell and cmd.exe failed: $cmdError");
            throw Exception("All WSL2 browser launch methods failed");
          }
        }
      } else {
        LogService.warning("SupabaseClientService", "DEBUG: Chrome not found in common WSL2 paths");
        throw Exception("Chrome browser not found in WSL2 environment");
      }
      
    } catch (e) {
      LogService.error("SupabaseClientService", "DEBUG: WSL2 browser fix failed: $e");
      rethrow;
    }
  }


  /// URLからセッションを取得
  ///
  /// [callbackUrl] OAuth認証後のコールバックURL
  /// Returns: 認証されたユーザー情報、失敗時はnull
  Future<User?> handleAuthCallback(String callbackUrl) async {
    try {
      logInfoMessage(AuthInfo.callbackProcessing, <String, String>{"url": callbackUrl});

      // 返ってきたurlをパース
      final Uri uri = Uri.parse(callbackUrl);

      // パースしたのとは別に、codeパラメータを抽出
      final String? code = _extractParamValue(callbackUrl, "code");
      if (code == null) {
        logWarningMessage(AuthError.authorizationCodeNotFound);
        throw AuthException("Authorization code not found in callback URL");
      }

      // セッションの復元（Supabase Flutter SDKが自動的に処理）
      // callback URLをSupabaseに渡すことで自動的にセッションが設定される
      await client.auth.getSessionFromUrl(uri);

      // 現在のユーザー情報を取得
      final User? currentUser = client.auth.currentUser;
      if (currentUser == null) {
        logWarningMessage(AuthError.userRetrievalFailed);
        throw AuthException("Failed to retrieve user after authentication");
      }

      logInfoMessage(AuthInfo.callbackProcessed, <String, String>{"userId": currentUser.id});
      return currentUser;
      // 認証エラー発生時
    } on AuthException catch (e) {
      logWarningMessage(AuthError.callbackProcessingFailed, <String, String>{"message": e.message});
      throw SupabaseAuthException("Failed to handle authentication callback: ${e.message}");
      // その他の例外発生時
    } catch (e) {
      logErrorMessage(AuthError.callbackProcessingFailed, <String, String>{
        "message": e.toString(),
      }, e);
      throw SupabaseClientException("Error processing authentication callback: ${e.toString()}");
    }
  }

  // 現在のユーザー情報を取得
  User? get currentUser => client.auth.currentUser;

  // ログイン状況チェック（セッション有効性含む）
  bool get isSignedIn => _isSessionValid();

  // セッション情報を取得
  Session? get currentSession => client.auth.currentSession;

  // セッションの有効性チェック（同期処理）
  bool _isSessionValid() {
    final Session? session = currentSession;
    if (session == null) {
      return false;
    }

    final DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return expiresAt.isAfter(DateTime.now());
  }

  // セッション更新が必要かチェック（同期処理）
  bool _shouldRefreshSession() {
    final Session? session = currentSession;
    if (session == null) {
      return false;
    }

    final DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    final DateTime now = DateTime.now();

    // 5分前にリフレッシュ
    return expiresAt.isBefore(now.add(AppConfig.sessionExpiryBuffer));
  }

  /// セッション更新処理（非同期・競合状態を回避）
  Future<void> refreshSessionIfNeeded() async {
    await _sessionRefreshMutex.acquire();
    try {
      // リフレッシュが不要な場合は何もしない
      if (!_shouldRefreshSession()) {
        return;
      }

      // 既にリフレッシュ中の場合は、その完了を待つ
      if (_isRefreshing && _refreshCompleter != null) {
        return _refreshCompleter!.future;
      }

      // リフレッシュ開始
      _isRefreshing = true;
      _refreshCompleter = Completer<void>();

      try {
        logInfoMessage(AuthInfo.sessionRefreshing);
        await client.auth.refreshSession();
        logInfoMessage(AuthInfo.sessionRefreshed);

        // 成功時にCompleterを完了
        _refreshCompleter!.complete();
      } catch (e) {
        logErrorMessage(AuthError.sessionRefreshFailed, <String, String>{"error": e.toString()}, e);

        // エラー時にCompleterを完了（エラーとして）
        _refreshCompleter!.completeError(e);
        rethrow;
      } finally {
        _isRefreshing = false;
        _refreshCompleter = null;
      }
    } finally {
      _sessionRefreshMutex.release();
    }
  }

  /// 定期的なセッション監視を開始
  void _startSessionMonitoring() {
    _sessionMonitorTimer?.cancel();
    _sessionMonitorTimer = Timer.periodic(AppConfig.sessionCheckInterval, (Timer timer) {
      if (_shouldRefreshSession()) {
        refreshSessionIfNeeded();
      }
    });
  }

  /// セッション監視を停止
  void _stopSessionMonitoring() {
    _sessionMonitorTimer?.cancel();
    _sessionMonitorTimer = null;
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      logInfoMessage(AuthInfo.userSigningOut);

      // 認証プロセスのクリーンアップ
      await _authMutex.acquire();
      try {
        if (_isAuthenticating && _authCompleter != null && !_authCompleter!.isCompleted) {
          _authCompleter!.completeError(Exception("Sign out initiated during authentication"));
        }
        _isAuthenticating = false;
        _authCompleter = null;
      } finally {
        _authMutex.release();
      }

      // セッション監視を停止
      _stopSessionMonitoring();

      // すべてのStreamリソースを破棄
      disposeStreams();

      await client.auth.signOut();
      logInfoMessage(AuthInfo.userSignedOut);
      // 認証失敗の場合
    } on AuthException catch (e) {
      logWarningMessage(AuthError.signOutFailed, <String, String>{"message": e.message});
      throw SupabaseAuthException("Failed to sign out: ${e.message}");
      // その他の例外発生時
    } catch (e) {
      logErrorMessage(AuthError.signOutException, <String, String>{"error": e.toString()}, e);
      throw SupabaseClientException("Error during sign out: ${e.toString()}");
    } finally {
      await _localAuthServer?.stop();
    }
  }

  /// 現在のセッションをリフレッシュ
  Future<void> refreshSession() async {
    await _sessionRefreshMutex.acquire();
    try {
      // リフレッシュ処理
      await client.auth.refreshSession();
    } catch (e) {
      logErrorMessage(AuthError.sessionRefreshFailed, <String, String>{"error": e.toString()}, e);
      throw SupabaseClientException("Failed to refresh session: ${e.toString()}");
    } finally {
      _sessionRefreshMutex.release();
    }
  }

  /// 認証状態の変更を監視するStream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// URLパラメータから指定した値を取得する内部ヘルパ
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
  const SupabaseClientException(this.message);

  /// エラーメッセージ
  final String message;

  @override
  String toString() => "SupabaseClientException: $message";
}

/// Supabase認証関連の例外
class SupabaseAuthException implements Exception {
  const SupabaseAuthException(this.message);

  /// エラーメッセージ
  final String message;

  @override
  String toString() => "SupabaseAuthException: $message";
}
