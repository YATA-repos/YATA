import "dart:async";
import "dart:io";

import "package:shelf/shelf.dart";
import "package:shelf/shelf_io.dart" as io;
import "package:shelf_router/shelf_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../utils/log_service.dart";

/// OAuthコールバックを処理するためのローカルサーバー
class LocalAuthServer {
  LocalAuthServer({required this.onAuthSuccess, required this.onAuthFailure});

  final void Function() onAuthSuccess;
  final void Function(String error) onAuthFailure;

  HttpServer? _server;
  bool _isStarting = false;
  bool _isStopping = false;
  
  /// サーバーが実行中かどうか
  bool get isRunning => _server != null && !_isStopping;
  
  /// サーバーが開始処理中かどうか
  bool get isStarting => _isStarting;
  
  /// サーバーが停止処理中かどうか
  bool get isStopping => _isStopping;

  /// サーバーを起動します
  Future<void> start() async {
    // 既に実行中の場合は何もしない
    if (isRunning) {
      LogService.warning("LocalAuthServer", "Server is already running. Ignoring start request.");
      return;
    }
    
    // 既に開始処理中の場合は何もしない
    if (_isStarting) {
      LogService.warning("LocalAuthServer", "Server start is already in progress. Ignoring start request.");
      return;
    }
    
    _isStarting = true;
    
    try {
      // 既存のサーバーがあれば停止
      await _forceStop();
      
      LogService.info("LocalAuthServer", "Starting local auth server...");
      
      final Router app = Router()
      ..get("/", (Request request) async {
        LogService.info("LocalAuthServer", "DEBUG: === OAuth Callback Received ===");
        LogService.info("LocalAuthServer", "DEBUG: Timestamp: ${DateTime.now().toIso8601String()}");
        LogService.info("LocalAuthServer", "DEBUG: Full request URL: ${request.url}");
        LogService.info("LocalAuthServer", "DEBUG: Request method: ${request.method}");
        LogService.info("LocalAuthServer", "DEBUG: Query parameters: ${request.url.queryParameters}");
        LogService.info("LocalAuthServer", "DEBUG: Request headers: ${request.headers}");
        LogService.info("LocalAuthServer", "DEBUG: Remote address: ${request.headers['x-forwarded-for'] ?? 'not provided'}");
        LogService.info("LocalAuthServer", "DEBUG: User-Agent: ${request.headers['user-agent'] ?? 'not provided'}");

        // パラメータ解析
        final String? code = request.url.queryParameters["code"];
        final String? error = request.url.queryParameters["error_description"];
        final String? errorCode = request.url.queryParameters["error"];
        final String? state = request.url.queryParameters["state"];

        LogService.info("LocalAuthServer", "DEBUG: Parsing OAuth callback parameters:");
        LogService.info("LocalAuthServer", "DEBUG: - code: ${code != null ? '${code.substring(0, code.length.clamp(0, 8))}... (${code.length} chars)' : 'null'}");
        LogService.info("LocalAuthServer", "DEBUG: - error_description: ${error ?? 'null'}");
        LogService.info("LocalAuthServer", "DEBUG: - error: ${errorCode ?? 'null'}");
        LogService.info("LocalAuthServer", "DEBUG: - state: ${state ?? 'null'}");

        // エラーパラメータの詳細ログ
        if (error != null || errorCode != null) {
          LogService.error("LocalAuthServer", "DEBUG: ❌ OAuth Error detected in callback");
          LogService.error("LocalAuthServer", "DEBUG: - error_description: $error");
          LogService.error("LocalAuthServer", "DEBUG: - error: $errorCode");
          LogService.error("LocalAuthServer", "DEBUG: This indicates Google OAuth failed before reaching our server");
          
          final String fullError = error ?? errorCode ?? "Unknown OAuth error";
          LogService.error("LocalAuthServer", "DEBUG: Calling onAuthFailure callback with: $fullError");
          onAuthFailure(fullError);
          return Response.internalServerError(body: "Authentication failed: $fullError");
        }

        if (code == null) {
          const String errorMessage = "Authorization code not found in callback URL";
          LogService.error("LocalAuthServer", "DEBUG: ❌ No authorization code in callback");
          LogService.error("LocalAuthServer", "DEBUG: Available parameters: ${request.url.queryParameters.keys.join(', ')}");
          LogService.error("LocalAuthServer", "DEBUG: This indicates the OAuth flow did not complete successfully");
          LogService.error("LocalAuthServer", "DEBUG: Calling onAuthFailure callback");
          onAuthFailure(errorMessage);
          return Response.badRequest(body: errorMessage);
        }

        // 認証コードの詳細ログ（セキュリティのため最初の数文字のみ）
        LogService.info("LocalAuthServer", "DEBUG: ✅ Valid authorization code received");
        LogService.info("LocalAuthServer", "DEBUG: Code preview: ${code.substring(0, code.length.clamp(0, 8))}...");
        LogService.info("LocalAuthServer", "DEBUG: Code length: ${code.length} characters");

        try {
          // 認証コードを使用してセッションを取得
          LogService.info("LocalAuthServer", "DEBUG: === Starting code exchange process ===");
          LogService.info("LocalAuthServer", "DEBUG: Calling Supabase.instance.client.auth.exchangeCodeForSession()...");
          LogService.info("LocalAuthServer", "DEBUG: Supabase client status: ${Supabase.instance.client != null ? 'initialized' : 'not initialized'}");
          
          final AuthSessionUrlResponse response = await Supabase.instance.client.auth.exchangeCodeForSession(code);
          
          LogService.info("LocalAuthServer", "DEBUG: ✅ exchangeCodeForSession() completed");
          LogService.info("LocalAuthServer", "DEBUG: Response analysis:");
          LogService.info("LocalAuthServer", "DEBUG: - Session present: ${response.session != null}");
          
          final Session session = response.session;
          LogService.info("LocalAuthServer", "DEBUG: Session details:");
          LogService.info("LocalAuthServer", "DEBUG: - Expires at: ${session.expiresAt}");
          LogService.info("LocalAuthServer", "DEBUG: - Access token present: ${session.accessToken.isNotEmpty}");
          LogService.info("LocalAuthServer", "DEBUG: - Refresh token present: ${session.refreshToken?.isNotEmpty ?? false}");
          LogService.info("LocalAuthServer", "DEBUG: - Token type: ${session.tokenType}");
          
          // 現在のユーザー情報を取得
          final User? currentUser = Supabase.instance.client.auth.currentUser;
          LogService.info("LocalAuthServer", "DEBUG: Current user after exchange: ${currentUser?.id ?? 'none'}");
          
          if (currentUser != null) {
            LogService.info("LocalAuthServer", "DEBUG: User details:");
            LogService.info("LocalAuthServer", "DEBUG: - Email: ${currentUser.email}");
            LogService.info("LocalAuthServer", "DEBUG: - Created at: ${currentUser.createdAt}");
            LogService.info("LocalAuthServer", "DEBUG: - Last sign in: ${currentUser.lastSignInAt}");
          }
                  
          LogService.info("LocalAuthServer", "DEBUG: ✅ Code exchange successful - calling onAuthSuccess callback");
          onAuthSuccess();
          
          return Response.ok(
            "Authentication successful! You can close this window.",
            headers: <String, String>{"content-type": "text/html"},
          );
        } catch (e) {
          final String errorMessage = "Failed to exchange code for session";
          final String errorCategory = _categorizeError(e);
          
          // より詳細なエラー情報をログ出力
          LogService.error("LocalAuthServer", "$errorMessage: ${e.runtimeType} - $e");
          LogService.error("LocalAuthServer", "Error category: $errorCategory");
          
          if (e is AuthException) {
            LogService.error("LocalAuthServer", "AuthException details - message: ${e.message}, statusCode: ${e.statusCode}");
            
            // 具体的なエラーコードに基づく詳細分析
            final String specificError = _analyzeAuthException(e);
            LogService.error("LocalAuthServer", "Specific error analysis: $specificError");
          }
          
          final String userErrorMessage = "$errorMessage ($errorCategory): ${e.toString()}";
          onAuthFailure(userErrorMessage);
          return Response.internalServerError(body: userErrorMessage);
        } finally {
          // サーバーを停止
          LogService.info("LocalAuthServer", "Stopping local auth server...");
          await stop();
        }
      });

      try {
        _server = await io.serve(app.call, "localhost", 3000);
        LogService.info("LocalAuthServer", "Listening on http://localhost:3000");
      } catch (e) {
        LogService.error("LocalAuthServer", "Failed to start server: $e", e);
        throw Exception("ローカル認証サーバーの起動に失敗しました: $e");
      }
    } catch (e) {
      LogService.error("LocalAuthServer", "Error during server startup: $e", e);
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  /// サーバーを停止します
  Future<void> stop() async {
    // 既に停止中の場合は何もしない
    if (_isStopping) {
      LogService.warning("LocalAuthServer", "Server stop is already in progress. Ignoring stop request.");
      return;
    }
    
    // サーバーが実行中でない場合は何もしない
    if (_server == null) {
      LogService.info("LocalAuthServer", "Server is not running. Nothing to stop.");
      return;
    }
    
    _isStopping = true;
    
    try {
      LogService.info("LocalAuthServer", "Stopping local auth server...");
      await _server!.close(force: true);
      _server = null;
      LogService.info("LocalAuthServer", "Server stopped successfully.");
    } catch (e) {
      LogService.error("LocalAuthServer", "Error during server stop: $e", e);
      // エラーが発生してもサーバー参照をクリア
      _server = null;
    } finally {
      _isStopping = false;
    }
  }

  /// 強制的にサーバーを停止（内部使用）
  Future<void> _forceStop() async {
    if (_server != null) {
      try {
        LogService.info("LocalAuthServer", "Force stopping existing server...");
        await _server!.close(force: true);
        _server = null;
        LogService.info("LocalAuthServer", "Existing server force stopped.");
      } catch (e) {
        LogService.error("LocalAuthServer", "Error during force stop: $e", e);
        _server = null; // エラーが発生してもクリア
      }
    }
    _isStopping = false; // 強制停止後は停止フラグをリセット
  }

  /// エラーをカテゴリ分類
  String _categorizeError(Object error) {
    if (error is AuthException) {
      return "認証エラー";
    } else if (error is SocketException) {
      return "ネットワーク接続エラー";
    } else if (error is TimeoutException) {
      return "タイムアウトエラー";
    } else if (error is FormatException) {
      return "データ形式エラー";
    } else {
      return "予期しないエラー";
    }
  }

  /// AuthExceptionの詳細分析
  String _analyzeAuthException(AuthException e) {
    final String? statusCode = e.statusCode;
    final String message = e.message.toLowerCase();

    if (statusCode == "400") {
      return "不正なリクエスト - 認証コードが無効または期限切れの可能性";
    } else if (statusCode == "401") {
      return "認証失敗 - APIキーまたは認証情報が無効";
    } else if (statusCode == "403") {
      return "アクセス拒否 - 権限不足";
    } else if (statusCode == "429") {
      return "レート制限 - リクエスト頻度が高すぎます";
    } else if (statusCode == "500") {
      return "サーバーエラー - Supabaseサーバー側の問題";
    } else if (message.contains("network")) {
      return "ネットワーク関連の問題";
    } else if (message.contains("timeout")) {
      return "タイムアウト - サーバー応答が遅延";
    } else if (message.contains("code")) {
      return "認証コード関連の問題";
    } else {
      return "その他の認証エラー: ${e.message}";
    }
  }
}
