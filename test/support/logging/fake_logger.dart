import "dart:async";
import "dart:collection";

import "package:yata/core/contracts/logging/logger.dart" as contract;
import "package:yata/core/logging/levels.dart";

/// テストで検証可能な形に整えたログエントリ。
class CapturedLog {
  CapturedLog({
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

  /// メッセージに含まれるかを判定するユーティリティ。
  bool messageContains(Pattern pattern) => message.contains(pattern);

  /// ログの簡易サマリ（タイムアウト時のエラーメッセージなどで利用）。
  String summary() =>
    "[lvl=${level.name}, tag=${tag ?? '-'}, msg=$message, error=${error?.runtimeType}]";
}

/// ログ取得ユーティリティの共通インターフェース。
abstract class LogProbe {
  UnmodifiableListView<CapturedLog> get entries;

  Stream<CapturedLog> get stream;

  Future<CapturedLog> waitFor({
    Duration? timeout,
    bool Function(CapturedLog log)? where,
  });
}

/// `LoggerContract` を実装したテスト用ロガー。
///
/// - ログを `entries` に蓄積し、ストリーム経由で監視可能。
/// - `waitFor` で非同期に発生するログを待ち受けられる。
class FakeLogger implements contract.LoggerContract, LogProbe {
  FakeLogger({this.defaultTimeout = const Duration(milliseconds: 200)})
      : _controller = StreamController<CapturedLog>.broadcast(sync: true);

  final Duration defaultTimeout;
  final StreamController<CapturedLog> _controller;
  final List<CapturedLog> _entries = <CapturedLog>[];
  final List<contract.FatalHandler> _fatalHandlers = <contract.FatalHandler>[];

  @override
  UnmodifiableListView<CapturedLog> get entries => UnmodifiableListView<CapturedLog>(_entries);

  @override
  Stream<CapturedLog> get stream => _controller.stream;

  /// 直近のログをクリアする。
  void clear() => _entries.clear();

  /// ストリームをクローズする。明示的に不要であれば呼び出す必要はない。
  Future<void> dispose() async {
    await _controller.close();
  }

  /// 条件に一致するログが到着するまで待つ。
  @override
  Future<CapturedLog> waitFor({
    Duration? timeout,
    bool Function(CapturedLog log)? where,
  }) async {
    final bool Function(CapturedLog log) predicate = where ?? (_) => true;

    for (final CapturedLog log in _entries) {
      if (predicate(log)) {
        return log;
      }
    }

    final Completer<CapturedLog> completer = Completer<CapturedLog>();
    late final StreamSubscription<CapturedLog> sub;
    sub = stream.listen((CapturedLog log) {
      if (predicate(log) && !completer.isCompleted) {
        unawaited(sub.cancel());
        completer.complete(log);
      }
    });

    final Duration effectiveTimeout = timeout ?? defaultTimeout;
    try {
      return await completer.future.timeout(effectiveTimeout, onTimeout: () {
        throw TimeoutException(
          "No log matched predicate within ${effectiveTimeout.inMilliseconds}ms. "
          "Captured logs: ${_entries.map((CapturedLog e) => e.summary()).join(', ')}",
        );
      });
    } finally {
      if (!completer.isCompleted) {
        await sub.cancel();
      }
    }
  }

  /// 内部レコードを直接追加（SpyLogger などの合成向け）。
  void addCapturedLog(CapturedLog log) {
    _record(log);
    if (log.level == Level.fatal) {
      _emitFatalHandlers(log);
    }
  }

  @override
  void log(
    Level level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  }) {
    final CapturedLog logEntry = createCapturedLog(
      level,
      msgOrThunk,
      tag: tag,
      fields: fields,
      error: error,
      st: st,
    );
    _record(logEntry);
    if (level == Level.fatal) {
      _emitFatalHandlers(logEntry);
    }
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

  @override
  void registerFatalHandler(contract.FatalHandler handler) {
    _fatalHandlers.add(handler);
  }

  @override
  void removeFatalHandler(contract.FatalHandler handler) {
    _fatalHandlers.remove(handler);
  }

  @override
  void clearFatalHandlers() {
    _fatalHandlers.clear();
  }

  void _record(CapturedLog log) {
    _entries.add(log);
    if (!_controller.isClosed) {
      _controller.add(log);
    }
  }

  void _emitFatalHandlers(CapturedLog captured) {
    if (_fatalHandlers.isEmpty) {
      return;
    }
    final contract.LogRecord record = contract.LogRecord(
      timestamp: captured.timestamp,
      level: captured.level,
      message: captured.message,
      tag: captured.tag,
      fields: captured.fields,
      error: captured.error,
      stackTrace: captured.stackTrace,
    );
    final contract.FatalLogContext context = contract.FatalLogContext(
      record: record,
      error: captured.error,
      stackTrace: captured.stackTrace,
      defaultFlushTimeout: const Duration(milliseconds: 100),
      flush: ({Duration? timeout}) async {},
      shutdown: ({Duration? timeout}) async {},
    );
    for (final contract.FatalHandler handler in List<contract.FatalHandler>.from(_fatalHandlers)) {
      unawaited(Future<void>.microtask(() => handler(context)));
    }
  }
}

/// テスト側で使う共通ヘルパー：ログメッセージを評価して [CapturedLog] を生成する。
CapturedLog createCapturedLog(
  Level level,
  Object msgOrThunk, {
  String? tag,
  Object? fields,
  Object? error,
  StackTrace? st,
}) =>
    CapturedLog(
      timestamp: DateTime.now().toUtc(),
      level: level,
      message: resolveLogMessage(msgOrThunk),
      tag: tag,
      fields: resolveLogFields(fields),
      error: error,
      stackTrace: st,
    );

String resolveLogMessage(Object msgOrThunk) {
  if (msgOrThunk is String) {
    return msgOrThunk;
  }
  if (msgOrThunk is String Function()) {
    return msgOrThunk();
  }
  return msgOrThunk.toString();
}

Map<String, dynamic>? resolveLogFields(Object? fields) {
  Object? resolved = fields;
  if (fields is Map<String, dynamic> Function()) {
    resolved = fields();
  } else if (fields is Map<dynamic, dynamic> Function()) {
    resolved = fields();
  }
  if (resolved == null) {
    return null;
  }
  if (resolved is Map<String, dynamic>) {
    return Map<String, dynamic>.from(resolved);
  }
  if (resolved is Map) {
    return resolved.map((dynamic key, dynamic value) {
      if (key is! String) {
        throw ArgumentError("FakeLogger only supports string keys for fields, got $key");
      }
      return MapEntry<String, dynamic>(key, value);
    });
  }
  throw ArgumentError("FakeLogger only supports Map fields or Map-producing thunks, got $fields");
}
