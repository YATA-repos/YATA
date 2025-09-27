import "dart:async";
import "dart:io";

import "../../../core/constants/exceptions/auth/auth_exception.dart";
import "../../../core/logging/compat.dart" as log;

/// デスクトップ環境向けのローカルOAuthコールバックサーバーを管理する。
///
/// SupabaseのOAuthリダイレクトを `http://localhost` で受け取り、
/// アプリケーションへコールバックURLを通知する。
class DesktopOAuthRedirectServer {
  DesktopOAuthRedirectServer({
    this.timeout = const Duration(minutes: 5),
    String? callbackPath,
    Uri? callbackUri,
  }) : _initialCallbackUri = callbackUri,
       callbackPath = callbackUri != null && callbackUri.path.isNotEmpty
           ? callbackUri.path
           : (callbackPath ?? "/auth/callback");

  final Duration timeout;
  final String callbackPath;
  final Uri? _initialCallbackUri;

  HttpServer? _server;
  Completer<Uri>? _callbackCompleter;
  Timer? _timeoutTimer;
  Uri? _callbackUri;

  /// コールバックURLを返す。
  ///
  /// サーバー起動後に利用する必要がある。
  Uri get callbackUri {
    final Uri? uri = _callbackUri;
    if (uri == null) {
      throw AuthException.initializationFailed("OAuthリダイレクトサーバーが初期化されていません");
    }
    return uri;
  }

  /// OAuthコールバックの完了を待機する。
  Future<Uri> waitForCallback() {
    final Completer<Uri>? completer = _callbackCompleter;
    if (completer == null) {
      throw AuthException.initializationFailed("OAuthリダイレクトサーバーが初期化されていません");
    }
    return completer.future;
  }

  /// サーバーを起動する。
  Future<void> start() async {
    if (_server != null) {
      return;
    }

    final Uri? initial = _initialCallbackUri;
    final InternetAddress bindAddress = InternetAddress.loopbackIPv4;
    final int bindPort = initial != null && initial.hasPort ? initial.port : 0;
    final String scheme = initial != null && initial.scheme.isNotEmpty ? initial.scheme : "http";
    final String host = initial != null && initial.host.isNotEmpty
        ? initial.host
        : bindAddress.address;
    final String normalizedPath = callbackPath.startsWith("/") ? callbackPath : "/$callbackPath";

    try {
      _server = await HttpServer.bind(bindAddress, bindPort);
      _callbackUri = Uri(scheme: scheme, host: host, port: _server!.port, path: normalizedPath);

      log.i(
        "OAuthコールバックサーバーを起動しました: ${_callbackUri!.toString()}",
        tag: "DesktopOAuthRedirectServer",
      );

      _callbackCompleter = Completer<Uri>();
      _timeoutTimer = Timer(timeout, () {
        if (!(_callbackCompleter?.isCompleted ?? true)) {
          _callbackCompleter?.completeError(AuthException.oauthFailed("OAuthコールバックがタイムアウトしました"));
          unawaited(stop());
        }
      });

      _server!.listen(
        _handleRequest,
        onError: (Object error, StackTrace stackTrace) {
          log.e(
            "OAuthコールバックサーバーでエラーが発生しました: $error",
            error: error,
            st: stackTrace,
            tag: "DesktopOAuthRedirectServer",
          );
          if (!(_callbackCompleter?.isCompleted ?? true)) {
            _callbackCompleter?.completeError(error, stackTrace);
          }
          unawaited(stop());
        },
      );
    } on Object catch (error, stackTrace) {
      log.e(
        "OAuthコールバックサーバーの起動に失敗しました: $error",
        error: error,
        st: stackTrace,
        tag: "DesktopOAuthRedirectServer",
      );
      await stop();
      rethrow;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final String expectedPath = _callbackUri?.path ?? callbackPath;
      if (request.uri.path != expectedPath) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write("404 Not Found");
        await request.response.close();
        return;
      }

      _timeoutTimer?.cancel();

      final Uri callback = request.requestedUri;
      _writeSuccessResponse(request);
      await request.response.close();

      if (!(_callbackCompleter?.isCompleted ?? true)) {
        _callbackCompleter?.complete(callback);
      }
    } on Object catch (error, stackTrace) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write("OAuth callback handling failed");
      await request.response.close();

      if (!(_callbackCompleter?.isCompleted ?? true)) {
        _callbackCompleter?.completeError(error, stackTrace);
      }
      rethrow;
    } finally {
      unawaited(stop());
    }
  }

  void _writeSuccessResponse(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write("""
<!DOCTYPE html>
<html lang='ja'>
  <head>
    <meta charset='utf-8' />
    <title>ログイン完了</title>
    <style>
      body { font-family: sans-serif; text-align: center; padding: 48px; background: #f6f6f8; color: #333; }
      main { display: inline-block; max-width: 480px; background: #fff; padding: 32px; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.08); }
      h1 { margin-bottom: 16px; font-size: 1.6rem; }
      p { margin: 0; font-size: 1rem; line-height: 1.6; }
      button { margin-top: 24px; padding: 12px 24px; border: none; border-radius: 8px; background: #2563eb; color: #fff; font-size: 1rem; cursor: pointer; }
      button:hover { background: #1e4fd9; }
    </style>
  </head>
  <body>
    <main>
      <h1>ログイン処理が完了しました</h1>
      <p>アプリに戻って処理を続けてください。このウィンドウは閉じて構いません。</p>
      <button onclick='window.close();'>ウィンドウを閉じる</button>
    </main>
  </body>
</html>
        """);
  }

  /// サーバーを停止し、関連リソースを解放する。
  Future<void> stop() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    if (!(_callbackCompleter?.isCompleted ?? true)) {
      _callbackCompleter?.completeError(AuthException.oauthFailed("OAuthコールバックサーバーが停止しました"));
    }

    await _server?.close(force: true);
    _server = null;
  }
}
