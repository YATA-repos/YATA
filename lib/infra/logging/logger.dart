import "dart:async";
import "dart:io";
import "dart:math";
// PlatformDispatcher is available via flutter foundation exports
import "package:flutter/foundation.dart";

import "context.dart";
import "formatters.dart";
import "log_config.dart";
import "log_event.dart";
import "log_level.dart";
import "pii_masker.dart";
import "sinks.dart";

typedef MsgThunk = String Function();
typedef FieldsThunk = Map<String, dynamic> Function();

class Logger {
  const Logger._(this._core, this._tag);

  final _LoggerCore _core;
  final String? _tag;

  Logger withTag(String tag) => Logger._(_core, tag);

  void log(
    LogLevel level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  }) {
    _core.log(level, msgOrThunk, tag: tag ?? _tag, fields: fields, error: error, st: st);
  }

  // Shorthand helpers
  void t(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(LogLevel.trace, msgOrThunk, tag: tag, fields: fields);
  void d(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(LogLevel.debug, msgOrThunk, tag: tag, fields: fields);
  void i(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(LogLevel.info, msgOrThunk, tag: tag, fields: fields);
  void w(Object msgOrThunk, {String? tag, Object? fields}) =>
      log(LogLevel.warn, msgOrThunk, tag: tag, fields: fields);
  void e(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
      log(LogLevel.error, msgOrThunk, tag: tag, fields: fields, error: error, st: st);
  void f(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
      log(LogLevel.fatal, msgOrThunk, tag: tag, fields: fields, error: error, st: st);

  // Phase 3 additions
  Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)}) =>
      _core.flushAndClose(timeout: timeout);
  Stream<LoggerStats> onStats() => _core.onStats;
  LoggerStats get stats => _core.stats;
  void installCrashCapture({bool? rethrowOnError}) =>
      _core.installCrashCapture(rethrowOnError: rethrowOnError);

  // Dynamic config exposure (Fix Plan 02)
  LogConfig get config => _core.config;
  void setGlobalLevel(LogLevel level) =>
      _core.updateConfig((LogConfig c) => c.copyWith(globalLevel: level));
  void setTagLevel(String tag, LogLevel level) => _core.updateConfig(
    (LogConfig c) => c.copyWith(tagLevels: <String, LogLevel>{...c.tagLevels, tag: level}),
  );
  void clearTagLevel(String tag) => _core.updateConfig((LogConfig c) {
    final Map<String, LogLevel> m = <String, LogLevel>{...c.tagLevels}..remove(tag);
    return c.copyWith(tagLevels: m);
  });

  /// ロガーの構成全体を更新するユーティリティ。
  void updateConfig(LogConfig Function(LogConfig) mutate) => _core.updateConfig(mutate);
  T withTempConfig<T>(T Function() body, LogConfig Function(LogConfig) mutate) {
    final LogConfig prev = _core.config;
    _core.updateConfig((_) => mutate(prev));
    try {
      return body();
    } finally {
      _core.updateConfig((_) => prev);
    }
  }
}

// Global facade per spec
final Logger _globalLogger = Logger._(_LoggerCore.instance, null);

Logger withTag(String tag) => _globalLogger.withTag(tag);

/// Traceログを出力する。
void t(Object msgOrThunk, {String? tag, Object? fields}) =>
    _globalLogger.t(msgOrThunk, tag: tag, fields: fields);

/// Debugログを出力する。
void d(Object msgOrThunk, {String? tag, Object? fields}) =>
    _globalLogger.d(msgOrThunk, tag: tag, fields: fields);

/// Infoログを出力する。
void i(Object msgOrThunk, {String? tag, Object? fields}) =>
    _globalLogger.i(msgOrThunk, tag: tag, fields: fields);

/// Warnログを出力する。
void w(Object msgOrThunk, {String? tag, Object? fields}) =>
    _globalLogger.w(msgOrThunk, tag: tag, fields: fields);
// Top-level API (named parameters; supports error/st + tag/fields)
/// Errorログを出力する。
void e(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
    _globalLogger.log(LogLevel.error, msgOrThunk, tag: tag, fields: fields, error: error, st: st);

/// Fatalログを出力する。
void f(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) =>
    _globalLogger.log(LogLevel.fatal, msgOrThunk, tag: tag, fields: fields, error: error, st: st);

// Phase 3 globals
Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)}) =>
    _globalLogger.flushAndClose(timeout: timeout);
Stream<LoggerStats> onStats() => _globalLogger.onStats();
LoggerStats get stats => _globalLogger.stats;
void installCrashCapture({bool? rethrowOnError}) =>
    _globalLogger.installCrashCapture(rethrowOnError: rethrowOnError);

// Dynamic config exposure (top-level)
LogConfig get config => _globalLogger.config;
void setGlobalLevel(LogLevel level) => _globalLogger.setGlobalLevel(level);
void setTagLevel(String tag, LogLevel level) => _globalLogger.setTagLevel(tag, level);
void clearTagLevel(String tag) => _globalLogger.clearTagLevel(tag);

/// ロガー設定をアトミックに更新する。
void updateLoggerConfig(LogConfig Function(LogConfig) mutate) => _globalLogger.updateConfig(mutate);

// ------------------
// Core implementation
// ------------------

class _LoggerCore {
  _LoggerCore._() {
    // Deferred IO paths: file sink resolves directory lazily.
    _configHub = LogConfigHub(LogConfig.defaults(fileDirPath: ""));

    _consoleFormatter = ConsolePrettyFormatter(
      useColor: _configHub.value.consoleUseColor,
      useEmojiFallback: _configHub.value.consoleUseEmojiFallback,
    );

    _consoleSink = ConsoleSink();
    _fileSink = FileSink(_configHub.value);
    _pii = PiiMasker(
      enabled: _configHub.value.piiMaskingEnabled,
      mode: _configHub.value.maskMode,
      customPatterns: _configHub.value.customPatterns,
      allowListKeys: _configHub.value.allowListKeys,
    );

    // Initialize rate config snapshot to avoid late initialization errors.
    _rateConfig = _configHub.value.rate;
  }

  static final _LoggerCore instance = _LoggerCore._();

  late LogConfigHub _configHub;
  late ConsolePrettyFormatter _consoleFormatter;
  late ConsoleSink _consoleSink;
  late FileSink _fileSink;
  late PiiMasker _pii;
  late RateConfig _rateConfig;
  LogConfig get config => _configHub.value;

  // Ring buffer queue
  final List<_Pending> _queue = <_Pending>[];
  bool _draining = false;

  // Phase 3: stats and lifecycle
  final StreamController<LoggerStats> _statsCtrl = StreamController<LoggerStats>.broadcast();
  bool _closing = false;
  int _droppedSinceStart = 0;
  int _rateSuppressedSinceStart = 0;
  Object? _lastFileError;
  String? _activeLogFile;

  Stream<LoggerStats> get onStats => _statsCtrl.stream;
  LoggerStats get stats => LoggerStats(
    queueLength: _queue.length,
    queueCapacity: _configHub.value.queueCapacity,
    droppedSinceStart: _droppedSinceStart,
    rateSuppressedSinceStart: _rateSuppressedSinceStart,
    lastFileError: _lastFileError,
    activeLogFile: _activeLogFile,
  );

  void _emitStats() {
    if (_statsCtrl.hasListener) {
      _statsCtrl.add(stats);
    }
  }

  void updateConfig(LogConfig Function(LogConfig) updater) {
    final LogConfig previous = _configHub.value;
    _configHub.update(updater);
    final LogConfig current = _configHub.value;
    // Recreate formatters/sinks if required
    _consoleFormatter = ConsolePrettyFormatter(
      useColor: current.consoleUseColor,
      useEmojiFallback: current.consoleUseEmojiFallback,
    );
    _pii = PiiMasker(
      enabled: current.piiMaskingEnabled,
      mode: current.maskMode,
      customPatterns: current.customPatterns,
      allowListKeys: current.allowListKeys,
    );
    _rateConfig = current.rate;

    final bool fileConfigChanged =
        previous.fileDirPath != current.fileDirPath ||
        previous.fileBaseName != current.fileBaseName ||
        previous.rotation.runtimeType != current.rotation.runtimeType ||
        previous.retention.runtimeType != current.retention.runtimeType ||
        previous.flushEveryLines != current.flushEveryLines ||
        previous.flushEveryMs != current.flushEveryMs;

    if (fileConfigChanged) {
      final FileSink oldSink = _fileSink;
      _fileSink = FileSink(current);
      unawaited(oldSink.close());
    }
  }

  void log(
    LogLevel level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  }) {
    if (_closing) {
      return; // ignore during closing
    }
    // A. Level/Tag filtering (before evaluating msg/fields)
    if (!_configHub.shouldLog(level, tag: tag)) {
      return; // drop silently
    }

    if (_queue.length >= _configHub.value.queueCapacity) {
      switch (_configHub.value.overflowPolicy) {
        case OverflowPolicy.dropNew:
          _droppedSinceStart++;
          _emitStats();
          return;
        case OverflowPolicy.dropOld:
          if (_queue.isNotEmpty) {
            _queue.removeAt(0);
            _droppedSinceStart++;
          } else {
            _droppedSinceStart++;
            _emitStats();
            return;
          }
          break;
        case OverflowPolicy.blockWithTimeout:
          final Duration wait = _configHub.value.overflowBlockTimeout;
          Timer(wait, () {
            if (_queue.length >= _configHub.value.queueCapacity) {
              _droppedSinceStart++;
              _emitStats();
              return;
            }
            _queue.add(
              _Pending(
                lvl: level,
                tag: tag,
                msgOrThunk: msgOrThunk,
                fields: fields,
                error: error,
                st: st,
              ),
            );
            if (!_draining) {
              _draining = true;
              scheduleMicrotask(_drain);
            }
            _emitStats();
          });
          return;
      }
    }

    _queue.add(
      _Pending(lvl: level, tag: tag, msgOrThunk: msgOrThunk, fields: fields, error: error, st: st),
    );

    if (!_draining) {
      _draining = true;
      scheduleMicrotask(_drain);
    }
    _emitStats();
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty) {
      final _Pending p = _queue.removeAt(0);
      try {
        await _process(p);
      } catch (e, st) {
        // Last-resort: write minimal diagnostic to stderr; do not recurse into logger.
        stderr.writeln("Logger pipeline error: $e\n$st");
      }
    }
    _draining = false;
  }

  Future<void> _process(_Pending p) async {
    // B. Evaluate lazily msg -> fields
    final String msg = _evalMsg(p.msgOrThunk);
    final Map<String, dynamic>? fields = _evalFields(p.fields);

    // Build event
    final LogEvent ev = LogEvent(
      ts: DateTime.now().toUtc(),
      lvl: p.lvl,
      tag: p.tag,
      msg: msg,
      fields: fields,
      err: p.error == null
          ? null
          : <String, String>{"type": p.error.runtimeType.toString(), "message": p.error.toString()},
      st: _formatStack(p.st),
      ctx: _configHub.value.enableContext ? currentLogContext() : null,
      eventId: _shortId(),
    );

    // C. PII Masking
    final LogEvent masked = _pii.process(ev);

    // D. Rate limiting & sampling (skip for logger meta)
    if (masked.tag != "logger" && _rateConfig.enabled) {
      if (!_allowByRateAndSampling(masked)) {
        _rateSuppressedSinceStart++;
        _maybeEmitRateSummary(masked);
        _emitStats();
        return;
      }
    }

    // Optional callsite enrichment
    final LogEvent enriched = _maybeAttachCallsite(masked);

    // E. Format
    final String consoleLine = _consoleFormatter.format(enriched);
    final String ndjsonLine = NdjsonFormatter().format(enriched);

    // F. Sinks
    if (_configHub.value.consoleEnabled) {
      await _consoleSink.add(consoleLine);
    }
    if (_configHub.value.fileEnabled) {
      await _fileSink.add(ndjsonLine);
      _activeLogFile = _fileSink.activeFilePath;
      _lastFileError = _fileSink.lastError;
    }
  }

  static String _shortId() {
    final Random r = Random.secure();
    final List<int> bytes = List<int>.generate(6, (_) => r.nextInt(256));
    const String hex = "0123456789abcdef";
    return bytes.map((int b) => hex[b >> 4] + hex[b & 0x0f]).join();
  }

  static String _evalMsg(Object msgOrThunk) {
    if (msgOrThunk is String) {
      return msgOrThunk;
    }
    if (msgOrThunk is MsgThunk) {
      return msgOrThunk();
    }
    // Fallback: stringify
    return msgOrThunk.toString();
  }

  static String? _formatStack(StackTrace? st) {
    if (st == null) {
      return null;
    }
    final List<String> lines = st.toString().split("\n");
    if (lines.isEmpty) {
      return null;
    }
    final List<String> picked = <String>[];
    int count = 0;
    for (final String raw in lines) {
      final String l = raw.trimRight();
      if (l.isEmpty) {
        continue;
      }
      picked.add(l);
      count++;
      if (count >= 20) {
        break;
      }
    }
    if (lines.length > picked.length) {
      picked.add("...(truncated)");
    }
    return picked.join("\n");
  }

  static Map<String, dynamic>? _evalFields(Object? fieldsOrThunk) {
    if (fieldsOrThunk == null) {
      return null;
    }
    if (fieldsOrThunk is Map<String, dynamic>) {
      return fieldsOrThunk;
    }
    if (fieldsOrThunk is FieldsThunk) {
      return fieldsOrThunk();
    }
    return null;
  }

  // ----------------------
  // Phase 3: Rate limiting
  // ----------------------
  bool _allowByRateAndSampling(LogEvent e) {
    final TagLevel key = (e.tag ?? "", e.lvl);
    final int? pct = _rateConfig.sampling[key];
    if (pct != null) {
      if (pct <= 0) {
        return false;
      }
      if (pct < 100) {
        final int r = Random().nextInt(100);
        if (r >= pct) {
          return false;
        }
      }
    }

    final TokenBucket? tl = _rateConfig.perTagLevel[key];
    if (tl != null && tl.tryConsume()) {
      return true;
    }

    final String? tag = e.tag;
    if (tag != null) {
      final TokenBucket? t = _rateConfig.perTag[tag];
      if (t != null && t.tryConsume()) {
        return true;
      }
    }

    return _rateConfig.global.tryConsume();
  }

  final Map<String, _RateSummary> _rateSummaries = <String, _RateSummary>{};
  void _maybeEmitRateSummary(LogEvent e) {
    final String tag = e.tag ?? "";
    final String key = "$tag:${e.lvl.name}";
    final DateTime now = DateTime.now();
    final _RateSummary s = _rateSummaries.putIfAbsent(key, _RateSummary.new);
    s.suppressed++;
    if (s.lastSummaryAt == null ||
        now.difference(s.lastSummaryAt!) >= _rateConfig.summaryInterval) {
      s.lastSummaryAt = now;
      final LogEvent meta = LogEvent(
        ts: now.toUtc(),
        lvl: LogLevel.info,
        tag: "logger",
        msg: "rate_limited",
        fields: <String, dynamic>{"key": key, "suppressed": s.suppressed},
        eventId: _shortId(),
      );
      final String consoleLine = _consoleFormatter.format(meta);
      final String ndjsonLine = NdjsonFormatter().format(meta);
      if (_configHub.value.rate.summaryToConsole && _configHub.value.consoleEnabled) {
        unawaited(_consoleSink.add(consoleLine));
      }
      if (_configHub.value.rate.summaryToFile && _configHub.value.fileEnabled) {
        unawaited(_fileSink.add(ndjsonLine));
      }
      s.suppressed = 0;
    }
  }

  // ----------------------
  // Phase 3: Callsite info
  // ----------------------
  LogEvent _maybeAttachCallsite(LogEvent e) {
    final CallsiteConfig cfg = _configHub.value.callsite;
    if (!cfg.enabled) {
      return e;
    }
    try {
      final StackTrace st = StackTrace.current;
      final _Callsite? cs = _extractCallsite(st, cfg);
      if (cs == null) {
        return e;
      }
      final Map<String, dynamic> f = <String, dynamic>{...?(e.fields)};
      f["src"] = <String, dynamic>{"file": cs.file, "line": cs.line, "member": cs.member};
      return e.copyWith(fields: f);
    } catch (_) {
      return e;
    }
  }

  // LRU cache for callsites
  final Map<String, _Callsite> _callsiteCache = <String, _Callsite>{};

  _Callsite? _extractCallsite(StackTrace st, CallsiteConfig cfg) {
    final List<String> lines = st.toString().split("\n");
    int skipped = 0;
    for (final String line in lines) {
      final String t = line.trim();
      if (t.isEmpty) {
        continue;
      }
      if (t.contains("logger.dart") || t.contains("dart:async") || t.contains("dart:ui")) {
        continue;
      }
      if (cfg.skipFrames != null && skipped < (cfg.skipFrames ?? 0)) {
        skipped++;
        continue;
      }
      final _Callsite? cached = _callsiteCache[t];
      if (cached != null) {
        return cached;
      }
      final RegExp r = RegExp(r"^(.*) \((.*):(\d+):(\d+)\)");
      final Match? m = r.firstMatch(t);
      if (m != null) {
        String file = m.group(2) ?? "";
        if (cfg.basenameOnly) {
          final int idx = file.lastIndexOf("/");
          if (idx >= 0) {
            file = file.substring(idx + 1);
          }
        }
        final int lineNo = int.tryParse(m.group(3) ?? "") ?? 0;
        final String member = (m.group(1) ?? "").trim();
        final _Callsite cs = _Callsite(file: file, line: lineNo, member: member);
        // Simple LRU: cap size by removing first inserted entry
        if (_callsiteCache.length >= cfg.cacheSize) {
          _callsiteCache.remove(_callsiteCache.keys.first);
        }
        _callsiteCache[t] = cs;
        return cs;
      }
    }
    return null;
  }

  // ----------------------
  // Phase 3: Flush and close
  // ----------------------
  Future<void> flushAndClose({required Duration timeout}) async {
    _closing = true;
    final DateTime deadline = DateTime.now().add(timeout);
    while (_queue.isNotEmpty && DateTime.now().isBefore(deadline)) {
      if (!_draining) {
        _draining = true;
        await _drain();
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
    try {
      await _consoleSink.flush();
      await _fileSink.flush();
      await _consoleSink.close();
      await _fileSink.close();
    } catch (_) {}
  }

  // ----------------------
  // Phase 3: Crash capture
  // ----------------------
  final Map<int, _CrashBucket> _crashDedup = <int, _CrashBucket>{};
  void installCrashCapture({bool? rethrowOnError}) {
    if (!_configHub.value.crashCaptureEnabled) {
      return;
    }
    final bool rethrowErrors = rethrowOnError ?? true;
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleUnhandled(details.exception, details.stack, handledZone: true);
      if (rethrowErrors) {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _handleUnhandled(error, stack, handledZone: false);
      return !rethrowErrors;
    };
  }

  void _handleUnhandled(Object error, StackTrace? st, {required bool handledZone}) {
    final String message = error.toString();
    final List<String> frames = (st?.toString().split("\n") ?? <String>[])
        .where((String l) => l.trim().isNotEmpty)
        .take(5)
        .toList();
    final int h = Object.hashAll(<Object?>[message, ...frames]);
    final DateTime now = DateTime.now();
    final Duration window = _configHub.value.crashDedupWindow;
    final _CrashBucket bucket = _crashDedup.putIfAbsent(h, _CrashBucket.new);
    if (bucket.first == null || now.difference(bucket.first!) > window) {
      bucket
        ..first = now
        ..suppressed = 0
        ..lastSummaryAt = null;
      final LogLevel lvl = _inferUnhandledLevel(error);
      log(
        lvl,
        "Unhandled exception",
        tag: "crash",
        error: error,
        st: st,
        fields: () => <String, dynamic>{
          "crash": <String, dynamic>{"handled": "unhandled", "zone": handledZone},
        },
      );
    } else {
      bucket.suppressed++;
      final Duration interval = _configHub.value.crashSummaryInterval;
      if (bucket.lastSummaryAt == null || now.difference(bucket.lastSummaryAt!) >= interval) {
        bucket.lastSummaryAt = now;
        i(
          "crash_suppressed",
          tag: "crash",
          fields: () => <String, dynamic>{"hash": h, "suppressed": bucket.suppressed},
        );
        bucket.suppressed = 0;
      }
    }
  }

  LogLevel _inferUnhandledLevel(Object error) {
    if (error is AssertionError ||
        error is StateError ||
        error is FormatException ||
        error is ArgumentError ||
        error is RangeError) {
      return LogLevel.error;
    }
    return LogLevel.fatal;
  }
}

class _Pending {
  _Pending({
    required this.lvl,
    required this.tag,
    required this.msgOrThunk,
    required this.fields,
    required this.error,
    required this.st,
  });

  final LogLevel lvl;
  final String? tag;
  final Object msgOrThunk; // String | MsgThunk
  final Object? fields; // Map<String,dynamic> | FieldsThunk | null
  final Object? error;
  final StackTrace? st;
}

class LoggerStats {
  LoggerStats({
    required this.queueLength,
    required this.queueCapacity,
    required this.droppedSinceStart,
    required this.rateSuppressedSinceStart,
    required this.lastFileError,
    required this.activeLogFile,
  });
  final int queueLength;
  final int queueCapacity;
  final int droppedSinceStart;
  final int rateSuppressedSinceStart;
  final Object? lastFileError;
  final String? activeLogFile;
}

class _RateSummary {
  int suppressed = 0;
  DateTime? lastSummaryAt;
}

class _Callsite {
  _Callsite({required this.file, required this.line, required this.member});
  final String file;
  final int line;
  final String member;
}

class _CrashBucket {
  DateTime? first;
  int suppressed = 0;
  DateTime? lastSummaryAt;
}
