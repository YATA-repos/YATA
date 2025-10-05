import "dart:async";

import "package:yata/core/contracts/logging/logger.dart" as contract;
import "package:yata/core/logging/levels.dart";

class CapturedLog {
  CapturedLog({
    required this.level,
    required this.message,
    this.tag,
    this.fields,
    this.error,
    this.stackTrace,
  });

  final Level level;
  final String message;
  final String? tag;
  final Map<String, dynamic>? fields;
  final Object? error;
  final StackTrace? stackTrace;
}

class FakeLogger implements contract.LoggerContract {
  final List<CapturedLog> entries = <CapturedLog>[];

  @override
  void log(
    Level level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  }) {
    final String message = _resolveMessage(msgOrThunk);
    entries.add(
      CapturedLog(
        level: level,
        message: message,
        tag: tag,
        fields: fields is Map<String, dynamic> ? Map<String, dynamic>.from(fields) : null,
        error: error,
        stackTrace: st,
      ),
    );
  }

  @override
  Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)}) async {}

  @override
  void t(Object msgOrThunk, {String? tag, Object? fields}) =>
    log(Level.trace, msgOrThunk, tag: tag, fields: fields);

  @override
  void d(Object msgOrThunk, {String? tag, Object? fields}) =>
    log(Level.debug, msgOrThunk, tag: tag, fields: fields);

  @override
  void i(Object msgOrThunk, {String? tag, Object? fields}) =>
    log(Level.info, msgOrThunk, tag: tag, fields: fields);

  @override
  void w(Object msgOrThunk, {String? tag, Object? fields}) =>
    log(Level.warn, msgOrThunk, tag: tag, fields: fields);

  @override
  void e(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
    log(Level.error, msgOrThunk, tag: tag, fields: fields, error: error, st: st);

  @override
  void f(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
    log(Level.fatal, msgOrThunk, tag: tag, fields: fields, error: error, st: st);

  void clear() => entries.clear();

  String _resolveMessage(Object msgOrThunk) {
    if (msgOrThunk is String) {
      return msgOrThunk;
    }
    if (msgOrThunk is String Function()) {
      return msgOrThunk();
    }
    return msgOrThunk.toString();
  }
}
