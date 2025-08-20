import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'config.dart';
import 'health.dart';
import 'levels.dart';
import 'metrics.dart';
import 'privacy.dart';
import 'runtime.dart';
import 'internals/record.dart';
import 'transports/console_transport.dart';
import 'transports/file_transport.dart';

class Logger {
  Logger._(this._cfg, this._redactor, this._runtime,
      {PseudoIdProvider? pseudoIdProvider})
      : _pseudo = pseudoIdProvider,
        _console = ConsoleTransport(),
        _immediateFlushThreshold = _cfg.immediateFlushAtOrAbove.severity;

  final LoggerConfig _cfg;
  final Redactor _redactor;
  final RuntimeInfo _runtime;
  final PseudoIdProvider? _pseudo;
  final ConsoleTransport _console;
  final int _immediateFlushThreshold;

  final _counters = LoggerCounters();
  final _gauges = LoggerGauges();
  final _timers = LoggerTimers();

  late final FileTransport _file;
  bool _started = false;
  final _queue = ListQueue<_QueuedItem>();

  Level get minLevel => _cfg.minLevel ?? _autoByBuild();

  static Level _autoByBuild() {
    // 簡易: 環境変数や dart.vm.product で判断（Flutter では --dart-define 等で伝達を推奨）
    final prod = bool.fromEnvironment('dart.vm.product');
    if (prod) return Level.warn; // release
    // 治具的に profile を INFO としたい場合は .env LOG_LEVEL で上書き
    return Level.debug; // debug
  }

  static Future<Logger> configure({
    required LoggerConfig config,
    required Redactor redactor,
    required RuntimeInfo runtime,
    PseudoIdProvider? pseudoId,
  }) async {
    final logger = Logger._(config, redactor, runtime, pseudoIdProvider: pseudoId);
    await logger._start();
    return logger;
  }

  Future<void> _start() async {
    // resolve log dir
    final Directory dir = _cfg.logDir ?? _resolveDefaultDir();
    _file = FileTransport(
      dir: dir,
      maxFileSizeBytes: _cfg.maxFileSizeMB * 1024 * 1024,
      maxDiskMB: _cfg.maxDiskMB,
      retentionDays: _cfg.retentionDays,
      flushInterval: Duration(milliseconds: _cfg.flushIntervalMs),
    );
    await _file.start();
    _started = true;
    _housekeeper = Timer.periodic(
        Duration(milliseconds: _cfg.flushIntervalMs), (_) => _drain());
  }

  Directory _resolveDefaultDir() {
    final os = Platform.operatingSystem;
    if (os == 'windows') {
      final base = Platform.environment['LOCALAPPDATA'] ??
          (Platform.environment['USERPROFILE'] != null
              ? '${Platform.environment['USERPROFILE']}\\AppData\\Local'
              : Directory.current.path);
      return Directory('$base\\YATA\\logs');
    } else if (os == 'linux') {
      final xdg = Platform.environment['XDG_STATE_HOME'] ??
          '${Platform.environment['HOME']}/.local/state';
      return Directory('$xdg/YATA/logs');
    } else if (os == 'android') {
      // 注意: Android ではアプリ専用領域の解決はアプリ側から LOG_DIR を渡すことを推奨
      final tmp = Directory.systemTemp.path;
      return Directory('$tmp/YATA/logs');
    }
    return Directory('${Directory.current.path}/YATA/logs');
  }

  Timer? _housekeeper;
  bool _draining = false;

  void _enqueue(_QueuedItem item) {
    // backpressure (drop-oldest only for v1.1)
    if (_queue.length >= _cfg.maxQueue) {
      if (_cfg.backpressure == BackpressurePolicy.dropOldest) {
        _queue.removeFirst();
        _counters.dropped++;
      } else if (_cfg.backpressure == BackpressurePolicy.dropNewest) {
        _counters.dropped++;
        return;
      } else {
        // block: not implemented for v1.1; fall back to drop-oldest
        _queue.removeFirst();
        _counters.dropped++;
      }
    }
    _queue.addLast(item);
    _gauges.queueDepth = _queue.length;
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        final it = _queue.removeFirst();
        _gauges.queueDepth = _queue.length;
        final ok = await _file.writeLine(it.line,
            levelSeverity: it.level.severity, flush: it.flush);
        if (ok) {
          _counters.written++;
        } else {
          _counters.failed++;
          // 失敗時は再投入（単純再試行: ここでは 1 回だけ。詳細は FileTransport 内の再試行に委譲可能）
          // v1.1 の要件: 失敗時は保持 → 本簡易実装では次周期で再送とする
          _queue.addFirst(it);
          _gauges.queueDepth = _queue.length;
          break; // 次周期に回す
        }
      }
      _gauges.diskUsageMB = await _file.diskUsageMB();
    } finally {
      _draining = false;
    }
  }

  // ============ Public API ============
  void log(Level level, String message,
      {Object? error,
      StackTrace? stackTrace,
      Map<String, Object?>? fields,
      String? component}) {
    if (level.severity < minLevel.severity) return;
    final ts = DateTime.now();

    // redact fields
    final safeFields = <String, Object?>{};
    if (fields != null) {
      for (final e in fields.entries) {
        safeFields[e.key] = _redactor.redactValue(e.key, e.value);
      }
    }

    final pseudo = _pseudo?.generate(safeFields['userId']?.toString() ?? '') ?? '';

    final rec = LogRecord(
      ts: ts,
      level: level,
      message: message,
      component: component,
      error: error,
      stackTrace: stackTrace,
      fields: safeFields,
      ctxEnv: _runtime.toCtx(),
      ctxDevice: _runtime.toDevice(),
      sessionId: _sessionId,
      requestId: _requestId,
      pseudoUserId: pseudo,
      uidVersion: _pseudo?.uidVersion ?? 1,
    );

    final line = rec.toJsonLine();
    final flushNow = level.severity >= _immediateFlushThreshold;
    _enqueue(_QueuedItem(level, line, flush: flushNow));

    // Also mirror to console in Debug/Profile (info and above default)
    if (_isConsoleEnabled) {
      _console.write(level, line);
    }

    _counters.emitted++;
  }

  void trace(String m, {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields, String? component}) =>
      log(Level.trace, m, error: error, stackTrace: stackTrace, fields: fields, component: component);
  void debug(String m, {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields, String? component}) =>
      log(Level.debug, m, error: error, stackTrace: stackTrace, fields: fields, component: component);
  void info(String m, {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields, String? component}) =>
      log(Level.info, m, error: error, stackTrace: stackTrace, fields: fields, component: component);
  void warn(String m, {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields, String? component}) =>
      log(Level.warn, m, error: error, stackTrace: stackTrace, fields: fields, component: component);
  void error(String m, {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields, String? component}) =>
      log(Level.error, m, error: error, stackTrace: stackTrace, fields: fields, component: component);
  void fatal(String m, {Object? error, StackTrace? stackTrace, Map<String, Object?>? fields, String? component}) =>
      log(Level.fatal, m, error: error, stackTrace: stackTrace, fields: fields, component: component);

  bool get _isConsoleEnabled => _runtime.build != 'release';

  String _sessionId = _uuidV4();
  String _requestId = _uuidV4();

  static String _uuidV4() {
    final rnd = Random.secure();
    String hex(int n) => List.generate(n, (_) => rnd.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final a = hex(4) + hex(2) + hex(2) + hex(2) + hex(6);
    // rudimentary UUID-like string (not RFC4122 exact)
    return a;
  }

  Future<void> flush() async {
    await _drain();
    await _file.flush();
  }

  Future<void> dispose() async {
    _housekeeper?.cancel();
    await flush();
    await _file.dispose();
  }

  LoggerStats stats() => LoggerStats(
        counters: _counters,
        gauges: _gauges,
        timers: _timers,
      );

  HealthStatus health() {
    // 簡易: 直近比率を持たないため累積で判定（v1.1 初期コミット）。
    final total = _counters.written + _counters.failed;
    if (total == 0) return HealthStatus.ok;
    final rate = _counters.failed / total;
    if (rate < 0.01) return HealthStatus.ok;
    if (rate < 0.05) return HealthStatus.warn;
    return HealthStatus.fail;
  }

  // =================================================================
  // 高度機能（YataLoggerImpl用拡張）
  // =================================================================

  /// パフォーマンス計測開始
  DateTime startPerformanceTimer(String component, String operation) {
    final DateTime startTime = DateTime.now();
    debug('Performance timer started: $operation', component: component);
    return startTime;
  }

  /// パフォーマンス計測終了・ログ出力
  void endPerformanceTimer(DateTime startTime, String component, String operation, {int? thresholdMs}) {
    final DateTime endTime = DateTime.now();
    final int durationMs = endTime.difference(startTime).inMilliseconds;
    
    if (thresholdMs == null || durationMs >= thresholdMs) {
      info('Performance timer completed: $operation (${durationMs}ms)', component: component);
    }
  }

  /// オブジェクトのログ出力
  void logObject(String component, String message, Object object) {
    debug('$message: $object', component: component);
  }

  /// 構造化ログ出力
  void structured(Level level, String component, Map<String, dynamic> data) {
    log(level, 'Structured data', fields: data, component: component);
  }

  /// クリティカルパス用ログ
  void critical(String component, String message) {
    fatal('CRITICAL: $message', component: component);
  }

  /// ビジネスメトリクス記録
  void businessMetric(String component, String metric, Map<String, dynamic> data) {
    log(Level.info, 'Business metric: $metric', fields: data, component: component);
  }

  /// ユーザーアクション記録
  void userAction(String component, String action, {Map<String, String>? context}) {
    final Map<String, Object?> fields = <String, Object?>{};
    if (context != null) {
      fields.addAll(context);
    }
    info('User action: $action', fields: fields, component: component);
  }

  /// システムヘルス監視
  void systemHealth(String component, String healthMetric, dynamic value, {String? unit}) {
    final String valueStr = unit != null ? '$value $unit' : '$value';
    info('Health metric: $healthMetric = $valueStr', component: component);
  }

  /// 統計情報取得（簡易版）
  Map<String, dynamic> getStatistics() {
    final LoggerStats loggerStats = stats();
    return <String, dynamic>{
      'emitted': loggerStats.counters.emitted,
      'written': loggerStats.counters.written,
      'failed': loggerStats.counters.failed,
      'dropped': loggerStats.counters.dropped,
      'queueDepth': loggerStats.gauges.queueDepth,
      'diskUsageMB': loggerStats.gauges.diskUsageMB,
    };
  }

  /// ログシステムのシャットダウン
  Future<void> shutdown() async {
    await dispose();
  }
}

class _QueuedItem {
  _QueuedItem(this.level, this.line, {this.flush = false});
  final Level level;
  final String line;
  final bool flush;
}