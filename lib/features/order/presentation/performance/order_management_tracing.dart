import "dart:async";
import "dart:developer";

import "package:flutter/foundation.dart";
import "../../../../core/validation/env_validator.dart";
import "../../../../infra/config/runtime_overrides.dart";
import "../../../../infra/logging/context_utils.dart" as log_ctx;
import "../../../../infra/logging/logger.dart" as log;

typedef TraceCallback<T> = T Function();
typedef AsyncTraceCallback<T> = Future<T> Function();
typedef TraceArgumentsBuilder = Map<String, dynamic> Function();
typedef LazyLogMessageBuilder = String Function();

/// 注文管理パフォーマンス計測のデフォルト有効状態。
///
/// 必要に応じて開発時に `true` へ変更するか、`OrderManagementTracer.overrideForDebug`
/// を使用してセッション単位で切り替える。
const String kOrderManagementPerformanceTracingEnvKey = "ORDER_MANAGEMENT_PERF_TRACING";

/// 注文管理画面向けのパフォーマンス計測ユーティリティ。
class OrderManagementTracer {
  OrderManagementTracer._();

  static const String _timelineCategory = "OrderManagement";
  static const String _logTag = "omperf";
  static const String _logPrefix = "[OMPerf]";
  static const Duration _defaultLogThreshold = Duration(milliseconds: 8);
  static const int _defaultSampleModulo = 20;
  static const String _runtimeToggleKey = kOrderManagementPerformanceTracingEnvKey;
  static const String _sampleModuloKey = "ORDER_MANAGEMENT_PERF_SAMPLE_MODULO";

  static final log.Logger _logger = log.withTag(_logTag);

  static bool? _environmentEnabled;
  static bool? _runtimeOverride;
  static int? _environmentSampleModulo;
  static int? _runtimeSampleModulo;
  static bool? _lastLoggerEnabled;

  /// 現在のトレーシング有効状態。
  static bool get isEnabled {
    final bool enabled = _computeIsEnabled();
    if (_lastLoggerEnabled == null) {
      // 以前に設定されたタグレベルをクリア
      log.clearTagLevel(_logTag);
    }
    return enabled;
  }

  /// `debug` モード動作中のみセッション単位で有効/無効を切り替える。
  static void overrideForDebug(bool? enabled) {
    if (!kDebugMode) {
      return;
    }
    applyRuntimeOverride(enabled: enabled);
  }

  /// 環境変数からトレーシング設定を初期化する。
  static void configureFromEnvironment({Map<String, String>? env}) {
    final Map<String, String> source = env ?? EnvValidator.env;
    _environmentEnabled = _parseBool(source[_runtimeToggleKey]);
    _environmentSampleModulo = _parsePositiveInt(source[_sampleModuloKey]);
    _syncLoggerTagLevel();
  }

  /// 実行中にトレーシング設定を上書きする。
  static void applyRuntimeOverride({bool? enabled, int? sampleModulo}) {
    if (enabled != null) {
      _runtimeOverride = enabled;
      RuntimeOverrides.setBool(_runtimeToggleKey, value: enabled);
    } else {
      _runtimeOverride = null;
      RuntimeOverrides.clear(_runtimeToggleKey);
    }

    final int? normalizedSample = _normalizeSampleModulo(sampleModulo);
    if (normalizedSample != null) {
      _runtimeSampleModulo = normalizedSample;
      RuntimeOverrides.setInt(_sampleModuloKey, value: normalizedSample);
    } else {
      _runtimeSampleModulo = null;
      RuntimeOverrides.clear(_sampleModuloKey);
    }

    _syncLoggerTagLevel();
  }

  /// 同期ブロックを計測する。
  static T traceSync<T>(
    String name,
    TraceCallback<T> action, {
    TraceArgumentsBuilder? startArguments,
    TraceArgumentsBuilder? finishArguments,
    Duration? logThreshold,
  }) {
    if (!isEnabled) {
      return action();
    }

    return log_ctx.traceSync<T>(
      name,
      (log_ctx.LogTrace trace) {
        final Duration threshold = logThreshold ?? _defaultLogThreshold;
        final Stopwatch stopwatch = Stopwatch()..start();
        final TimelineTask task = TimelineTask(filterKey: _timelineCategory);
        final Map<String, dynamic>? startArgs = _buildArguments(startArguments, trace: trace);
        task.start(name, arguments: startArgs);
        try {
          return action();
        } finally {
          stopwatch.stop();
          final Map<String, dynamic>? endArgs = _buildArguments(finishArguments, trace: trace);
          final Map<String, dynamic> timelineArgs = <String, dynamic>{
            if (startArgs != null) ...startArgs,
            if (endArgs != null) ...endArgs,
            "elapsedMs": _elapsedMs(stopwatch.elapsed),
          };
          task.finish(arguments: timelineArgs);
          final Map<String, dynamic>? logArgs = _mergeArguments(startArgs, endArgs);
          _logElapsed(name, stopwatch.elapsed, logArgs, threshold);
        }
      },
      attributes: <String, Object?>{
        log_ctx.LogContextKeys.source: _logTag,
        log_ctx.LogContextKeys.operation: name,
      },
    );
  }

  /// 非同期ブロックを計測する。
  static Future<T> traceAsync<T>(
    String name,
    AsyncTraceCallback<T> action, {
    TraceArgumentsBuilder? startArguments,
    TraceArgumentsBuilder? finishArguments,
    Duration? logThreshold,
  }) async {
    if (!isEnabled) {
      return action();
    }

    return log_ctx.traceAsync<T>(
      name,
      (log_ctx.LogTrace trace) async {
        final Duration threshold = logThreshold ?? _defaultLogThreshold;
        final Stopwatch stopwatch = Stopwatch()..start();
        final TimelineTask task = TimelineTask(filterKey: _timelineCategory);
        final Map<String, dynamic>? startArgs = _buildArguments(startArguments, trace: trace);
        task.start(name, arguments: startArgs);
        try {
          return await action();
        } finally {
          stopwatch.stop();
          final Map<String, dynamic>? endArgs = _buildArguments(finishArguments, trace: trace);
          final Map<String, dynamic> timelineArgs = <String, dynamic>{
            if (startArgs != null) ...startArgs,
            if (endArgs != null) ...endArgs,
            "elapsedMs": _elapsedMs(stopwatch.elapsed),
          };
          task.finish(arguments: timelineArgs);
          final Map<String, dynamic>? logArgs = _mergeArguments(startArgs, endArgs);
          _logElapsed(name, stopwatch.elapsed, logArgs, threshold);
        }
      },
      attributes: <String, Object?>{
        log_ctx.LogContextKeys.source: _logTag,
        log_ctx.LogContextKeys.operation: name,
      },
    );
  }

  /// ログメッセージを出力する。実際に使用されるのはトレーシングが有効なときのみ。
  static void logMessage(String message) {
    if (!isEnabled) {
      return;
    }
    _logger.d(() => "$_logPrefix $message");
  }

  /// ログメッセージを遅延生成して出力する。
  static void logLazy(LazyLogMessageBuilder builder) {
    if (!isEnabled) {
      return;
    }
    _logger.d(() => "$_logPrefix ${builder()}");
  }

  /// Grid のビルドなどでサンプリング計測が必要な場合のヘルパー。
  static bool shouldSample(int index, {int? sampleModulo}) {
    if (!isEnabled) {
      return false;
    }
    final int modulo = _resolveSampleModulo(sampleModulo);
    if (modulo <= 0) {
      return false;
    }
    return index % modulo == 0;
  }

  static Map<String, dynamic>? _buildArguments(
    TraceArgumentsBuilder? builder, {
    required log_ctx.LogTrace trace,
  }) {
    if (!isEnabled) {
      return _attachTraceIdentifiers(null, trace);
    }
    if (builder == null) {
      return _attachTraceIdentifiers(null, trace);
    }
    final Map<String, dynamic> result = builder();
    final Map<String, dynamic>? normalized = result.isEmpty
        ? null
        : Map<String, dynamic>.from(result);
    return _attachTraceIdentifiers(normalized, trace);
  }

  static Map<String, dynamic>? _attachTraceIdentifiers(
    Map<String, dynamic>? source,
    log_ctx.LogTrace trace,
  ) {
    final Map<String, dynamic> combined = <String, dynamic>{
      if (source != null) ...source,
      ..._traceIdentifiers(trace),
    };
    return combined.isEmpty ? null : combined;
  }

  static Map<String, dynamic> _traceIdentifiers(log_ctx.LogTrace trace) => <String, dynamic>{
    log_ctx.LogContextKeys.flowId: trace.flowId,
    log_ctx.LogContextKeys.spanId: trace.spanId,
    if (trace.parentSpanId != null) log_ctx.LogContextKeys.parentSpanId: trace.parentSpanId,
  };

  static double _elapsedMs(Duration duration) => duration.inMicroseconds / 1000;

  static Map<String, dynamic>? _mergeArguments(
    Map<String, dynamic>? first,
    Map<String, dynamic>? second,
  ) {
    if ((first == null || first.isEmpty) && (second == null || second.isEmpty)) {
      return null;
    }
    return <String, dynamic>{if (first != null) ...first, if (second != null) ...second};
  }

  static bool _computeIsEnabled() {
    bool? runtime = _runtimeOverride;
    if (runtime == null) {
      runtime = RuntimeOverrides.getBool(_runtimeToggleKey);
      if (runtime != null) {
        _runtimeOverride = runtime;
      }
    }
    if (runtime != null) {
      return runtime;
    }
    if (_environmentEnabled != null) {
      return _environmentEnabled!;
    }
    return !kReleaseMode;
  }

  static void _syncLoggerTagLevel() {
    final bool enabled = _computeIsEnabled();
    if (_lastLoggerEnabled == enabled) {
      return;
    }
    // タグレベルをクリアしてグローバルレベルに従う
    log.clearTagLevel(_logTag);
    _lastLoggerEnabled = enabled;
  }



  static int get _effectiveSampleModulo {
    int? runtime = _runtimeSampleModulo;
    if (runtime == null) {
      runtime = RuntimeOverrides.getInt(_sampleModuloKey);
      if (runtime != null && runtime > 0) {
        _runtimeSampleModulo = runtime;
      }
    }
    if (runtime != null && runtime > 0) {
      return runtime;
    }
    if (_environmentSampleModulo != null) {
      return _environmentSampleModulo!;
    }
    return _defaultSampleModulo;
  }

  static int _resolveSampleModulo(int? override) {
    final int? normalized = _normalizeSampleModulo(override);
    if (normalized != null) {
      return normalized;
    }
    return _effectiveSampleModulo;
  }

  static int? _normalizeSampleModulo(int? value) {
    if (value == null) {
      return null;
    }
    return value > 0 ? value : null;
  }

  static int? _parsePositiveInt(String? raw) {
    if (raw == null) {
      return null;
    }
    final String normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final int? parsed = int.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  static bool? _parseBool(String? raw) {
    if (raw == null) {
      return null;
    }
    final String normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    if (<String>{"1", "true", "yes", "on"}.contains(normalized)) {
      return true;
    }
    if (<String>{"0", "false", "no", "off"}.contains(normalized)) {
      return false;
    }
    return null;
  }

  @visibleForTesting
  static void debugReset() {
    _environmentEnabled = null;
    _runtimeOverride = null;
    _environmentSampleModulo = null;
    _runtimeSampleModulo = null;
    _lastLoggerEnabled = null;
    RuntimeOverrides.clear(_runtimeToggleKey);
    RuntimeOverrides.clear(_sampleModuloKey);
    _syncLoggerTagLevel();
  }

  static void _logElapsed(
    String name,
    Duration elapsed,
    Map<String, dynamic>? arguments,
    Duration threshold,
  ) {
    if (elapsed < threshold) {
      return;
    }
    final Map<String, dynamic> fields = <String, dynamic>{
      "operation": name,
      "elapsed_ms": _elapsedMs(elapsed),
      "threshold_ms": _elapsedMs(threshold),
      "threshold_exceeded": true,
      "sample_modulo": _effectiveSampleModulo,
    };
    if (arguments != null && arguments.isNotEmpty) {
      fields.addAll(arguments);
    }
    _logger.d(() => "$_logPrefix $name ${_elapsedFormat(elapsed)}", fields: () => fields);
  }

  static String _elapsedFormat(Duration duration) => "${_elapsedMs(duration).toStringAsFixed(2)}ms";
}
