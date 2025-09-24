import "dart:async";

import "../../core/contracts/logging/logger.dart" as contract;
import "../../core/logging/levels.dart";
import "logger.dart" as impl; // infra logging global facade

/// infra/logging 実装を core 契約にブリッジするアダプタ
class InfraLoggerAdapter implements contract.LoggerContract {
  const InfraLoggerAdapter();

  @override
  void log(
    Level level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  }) {
    switch (level) {
      case Level.trace:
        impl.t(msgOrThunk, tag: tag, fields: fields);
        break;
      case Level.debug:
        impl.d(msgOrThunk, tag: tag, fields: fields);
        break;
      case Level.info:
        impl.i(msgOrThunk, tag: tag, fields: fields);
        break;
      case Level.warn:
        impl.w(msgOrThunk, tag: tag, fields: fields);
        break;
      case Level.error:
        impl.e(msgOrThunk, tag: tag, fields: fields, error: error, st: st);
        break;
      case Level.fatal:
        impl.f(msgOrThunk, tag: tag, fields: fields, error: error, st: st);
        break;
    }
  }

  @override
  Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)}) =>
      impl.flushAndClose(timeout: timeout);

  // 明示的なショートハンド実装（Analyzerの誤検知回避のため）
  @override
  void t(Object msgOrThunk, {String? tag, Object? fields}) =>
      impl.t(msgOrThunk, tag: tag, fields: fields);

  @override
  void d(Object msgOrThunk, {String? tag, Object? fields}) =>
      impl.d(msgOrThunk, tag: tag, fields: fields);

  @override
  void i(Object msgOrThunk, {String? tag, Object? fields}) =>
      impl.i(msgOrThunk, tag: tag, fields: fields);

  @override
  void w(Object msgOrThunk, {String? tag, Object? fields}) =>
      impl.w(msgOrThunk, tag: tag, fields: fields);

  @override
  void e(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
      impl.e(msgOrThunk, tag: tag, fields: fields, error: error, st: st);

  @override
  void f(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
      impl.f(msgOrThunk, tag: tag, fields: fields, error: error, st: st);
}
