import "dart:async";
import "dart:developer";

import "package:flutter/foundation.dart";
import "../../../../core/validation/env_validator.dart";
import "../../../../infra/logging/context_utils.dart" as log_ctx;

typedef TraceCallback<T> = T Function();
typedef AsyncTraceCallback<T> = Future<T> Function();
typedef TraceArgumentsBuilder = Map<String, dynamic> Function();
typedef LazyLogMessageBuilder = String Function();

/// 注文管理パフォーマンス計測のデフォルト有効状態。
///
/// 必要に応じて開発時に `true` へ変更するか、`OrderManagementTracer.overrideForDebug`
/// を使用してセッション単位で切り替える。
const String kOrderManagementPerformanceTracingEnvKey = "ORDER_MANAGEMENT_PERF_TRACING";

const bool kOrderManagementPerformanceTracingEnabled = bool.fromEnvironment(
  kOrderManagementPerformanceTracingEnvKey,
);

/// 注文管理画面向けのパフォーマンス計測ユーティリティ。
class OrderManagementTracer {
  OrderManagementTracer._();

  static const String _timelineCategory = "OrderManagement";
  static const String _logPrefix = "[OMPerf]";
  static const Duration _defaultLogThreshold = Duration(milliseconds: 8);
  static const int _defaultSampleModulo = 20;
  static const String _runtimeToggleKey = kOrderManagementPerformanceTracingEnvKey;

  static bool? _runtimeOverride;

  /// 現在のトレーシング有効状態。
  static bool get isEnabled {
    if (!kDebugMode) {
      return false;
    }
    bool enabled = kOrderManagementPerformanceTracingEnabled;
    assert(() {
      if (_runtimeOverride != null) {
        enabled = _runtimeOverride!;
      }
      return true;
    }());
    return enabled;
  }

  /// `debug` モード動作中のみセッション単位で有効/無効を切り替える。
  static void overrideForDebug(bool? enabled) {
    assert(() {
      _runtimeOverride = enabled;
      return true;
    }());
  }

  /// 環境変数からトレーシングの有効状態を初期化する。
  static void configureFromEnvironment({Map<String, String>? env}) {
    assert(() {
      final Map<String, String> source = env ?? EnvValidator.env;
      if (source.containsKey(_runtimeToggleKey)) {
        final bool enabled = EnvValidator.orderManagementPerfTracing;
        overrideForDebug(enabled);
      }
      return true;
    }());
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
        log_ctx.LogContextKeys.source: _logPrefix,
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
        log_ctx.LogContextKeys.source: _logPrefix,
        log_ctx.LogContextKeys.operation: name,
      },
    );
  }

  /// ログメッセージを出力する。実際に使用されるのはトレーシングが有効なときのみ。
  static void logMessage(String message) {
    if (!isEnabled) {
      return;
    }
    debugPrint("$_logPrefix $message");
  }

  /// ログメッセージを遅延生成して出力する。
  static void logLazy(LazyLogMessageBuilder builder) {
    if (!isEnabled) {
      return;
    }
    debugPrint("$_logPrefix ${builder()}");
  }

  /// Grid のビルドなどでサンプリング計測が必要な場合のヘルパー。
  static bool shouldSample(int index, {int sampleModulo = _defaultSampleModulo}) {
    if (!isEnabled || sampleModulo <= 0) {
      return false;
    }
    return index % sampleModulo == 0;
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

  static void _logElapsed(
    String name,
    Duration elapsed,
    Map<String, dynamic>? arguments,
    Duration threshold,
  ) {
    if (elapsed < threshold) {
      return;
    }
    final StringBuffer buffer = StringBuffer()
      ..write(_logPrefix)
      ..write(" $name ")
      ..write(_elapsedFormat(elapsed));
    if (arguments != null && arguments.isNotEmpty) {
      buffer
        ..write(" ")
        ..write(_formatArguments(arguments));
    }
    debugPrint(buffer.toString());
  }

  static String _elapsedFormat(Duration duration) => "${_elapsedMs(duration).toStringAsFixed(2)}ms";

  static String _formatArguments(Map<String, dynamic> arguments) => arguments.entries
      .map((MapEntry<String, dynamic> entry) => "${entry.key}=${entry.value}")
      .join(", ");
}
