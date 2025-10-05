import "dart:async";
import "dart:collection";

import "package:yata/core/contracts/logging/logger.dart" as contract;
import "package:yata/core/logging/levels.dart";

import "fake_logger.dart";

/// 既存のロガー呼び出しを横取りして検証可能にするスパイロガー。
///
/// - すべてのログは [FakeLogger] と同じ API で参照できる。
/// - 任意で委譲先ロガーにフォワードできるため、テスト中でも実ログ出力を維持可能。
class SpyLogger implements contract.LoggerContract, LogProbe {
  SpyLogger({contract.LoggerContract? delegate, Duration defaultTimeout = const Duration(milliseconds: 200)})
      : _delegate = delegate,
        _fake = FakeLogger(defaultTimeout: defaultTimeout);

  final contract.LoggerContract? _delegate;
  final FakeLogger _fake;

  bool get hasDelegate => _delegate != null;

  @override
  UnmodifiableListView<CapturedLog> get entries => _fake.entries;

  @override
  Stream<CapturedLog> get stream => _fake.stream;

  @override
  Future<CapturedLog> waitFor({Duration? timeout, bool Function(CapturedLog log)? where}) =>
      _fake.waitFor(timeout: timeout, where: where);

  /// 蓄積したログを全てクリアする。
  void clear() => _fake.clear();

  /// [FakeLogger] のリソースを解放する。
  Future<void> dispose() => _fake.dispose();

  @override
  void log(
    Level level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  }) {
    final CapturedLog captured = createCapturedLog(
      level,
      msgOrThunk,
      tag: tag,
      fields: fields,
      error: error,
      st: st,
    );
    _fake.addCapturedLog(captured);
    _delegate?.log(
      level,
      captured.message,
      tag: captured.tag,
      fields: captured.fields,
      error: captured.error,
      st: captured.stackTrace,
    );
  }

  @override
  Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)}) async {
    final contract.LoggerContract? delegate = _delegate;
    if (delegate != null) {
      await delegate.flushAndClose(timeout: timeout);
    }
  }

  @override
  void registerFatalHandler(contract.FatalHandler handler) {
    _fake.registerFatalHandler(handler);
    _delegate?.registerFatalHandler(handler);
  }

  @override
  void removeFatalHandler(contract.FatalHandler handler) {
    _fake.removeFatalHandler(handler);
    _delegate?.removeFatalHandler(handler);
  }

  @override
  void clearFatalHandlers() {
    _fake.clearFatalHandlers();
    _delegate?.clearFatalHandlers();
  }

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
}
