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

  /// サーバーを起動します
  Future<void> start() async {
    final Router app = Router();

    app.get("/", (Request request) async {
      final String? code = request.url.queryParameters["code"];
      final String? error = request.url.queryParameters["error_description"];

      if (error != null) {
        LogService.error("LocalAuthServer", "OAuth Error: $error");
        onAuthFailure(error);
        return Response.internalServerError(body: "Authentication failed: $error");
      }

      if (code == null) {
        const String errorMessage = "Authorization code not found.";
        LogService.error("LocalAuthServer", errorMessage);
        onAuthFailure(errorMessage);
        return Response.badRequest(body: errorMessage);
      }

      try {
        // 認証コードを使用してセッションを取得
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
        LogService.info("LocalAuthServer", "Successfully exchanged code for session.");
        onAuthSuccess();
        return Response.ok(
          "Authentication successful! You can close this window.",
          headers: <String, String>{"content-type": "text/html"},
        );
      } catch (e) {
        final String errorMessage = "Failed to exchange code for session: $e";
        LogService.error("LocalAuthServer", errorMessage, e);
        onAuthFailure(errorMessage);
        return Response.internalServerError(body: errorMessage);
      } finally {
        // サーバーを停止
        stop();
      }
    });

    try {
      _server = await io.serve(app.call, "localhost", 3000);
      LogService.info("LocalAuthServer", "Listening on http://localhost:3000");
    } catch (e) {
      LogService.error("LocalAuthServer", "Failed to start server: $e", e);
      rethrow;
    }
  }

  /// サーバーを停止します
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    LogService.info("LocalAuthServer", "Server stopped.");
  }
}
