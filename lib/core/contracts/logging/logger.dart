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
}
