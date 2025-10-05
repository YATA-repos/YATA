import "dart:async";

import "../../logging/levels.dart";

/// ログレコード（契約用の最小表現）
class LogRecord {
  LogRecord({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.fields,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final Level level;
  final String message;
  final String? tag;
  final Map<String, dynamic>? fields;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Fatal ログ発生時にハンドラーへ渡されるコンテキスト情報。
class FatalLogContext {
  FatalLogContext({
    required this.record,
    this.error,
    this.stackTrace,
    required this.defaultFlushTimeout,
    required this.flush,
    required this.shutdown,
    this.willShutdownAfterHandlers = false,
  });

  /// マスク済みのログレコード。
  final LogRecord record;

  /// 原因となったエラーオブジェクト（存在する場合）。
  final Object? error;

  /// 原因となったスタックトレース（存在する場合）。
  final StackTrace? stackTrace;

  /// 既定のフラッシュ待機時間。
  final Duration defaultFlushTimeout;

  /// ログシンクをフラッシュするハンドラ。timeout 未指定時は [defaultFlushTimeout] を使用。
  final Future<void> Function({Duration? timeout}) flush;

  /// ロガーを安全に停止するハンドラ。timeout 未指定時は [defaultFlushTimeout] を使用。
  final Future<void> Function({Duration? timeout}) shutdown;

  /// ハンドラー実行後に自動停止が予定されているかどうか。
  final bool willShutdownAfterHandlers;
}

/// Fatal ログのハンドラー定義。
typedef FatalHandler = FutureOr<void> Function(FatalLogContext context);

/// ロガー契約
/// 実装例: `infra/logging/logger.dart`
abstract class LoggerContract {
  void log(
    Level level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  });

  // 省略記法
  void t(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(Level.trace, msgOrThunk, tag: tag, fields: fields);
  void d(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(Level.debug, msgOrThunk, tag: tag, fields: fields);
  void i(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(Level.info, msgOrThunk, tag: tag, fields: fields);
  void w(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(Level.warn, msgOrThunk, tag: tag, fields: fields);
  void e(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
      log(Level.error, msgOrThunk, tag: tag, fields: fields, error: error, st: st);
  void f(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
      log(Level.fatal, msgOrThunk, tag: tag, fields: fields, error: error, st: st);

  /// バッファのフラッシュとクローズ
  Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)});

  /// Fatal レベル発生時のハンドラーを登録する。
  void registerFatalHandler(FatalHandler handler);

  /// 登録済みの Fatal ハンドラーを削除する。
  void removeFatalHandler(FatalHandler handler);

  /// 登録済みの Fatal ハンドラーをすべて削除する。
  void clearFatalHandlers();
}
