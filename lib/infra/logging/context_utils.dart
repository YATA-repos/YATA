import "dart:async";
import "dart:math";

import "context.dart";

/// 標準的に利用する LogContext のキー定義。
abstract class LogContextKeys {
  static const String flowId = "flow_id";
  static const String requestId = "request_id";
  static const String userId = "user_id";
  static const String spanId = "span_id";
  static const String parentSpanId = "parent_span_id";
  static const String spanName = "span_name";
  static const String source = "source";
  static const String operation = "operation";
}

final Random _contextRandom = _createRandom();

Random _createRandom() {
  try {
    return Random.secure();
  } on UnsupportedError {
    return Random();
  }
}

const String _base36 = "0123456789abcdefghijklmnopqrstuvwxyz";

String _timestampBase36() => DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36);

String _randomBase36(int length) {
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < length; i++) {
    final int index = _contextRandom.nextInt(_base36.length);
    buffer.write(_base36[index]);
  }
  return buffer.toString();
}

String _generateContextId(String prefix, {int randomLength = 6}) {
  assert(randomLength > 0, "randomLength must be positive");
  final String ts = _timestampBase36();
  final String random = _randomBase36(randomLength);
  return "${prefix}_${ts}_$random";
}

/// 新しい flow ID を生成する。
String newFlowId() => _generateContextId("flow", randomLength: 8);

/// 新しい request ID を生成する。
String newRequestId() => _generateContextId("req");

/// 新しい span ID を生成する。
String newSpanId() => _generateContextId("span");

/// 標準的な LogContext のマップを生成する。
LogContext buildLogContext({
  String? flowId,
  String? requestId,
  String? userId,
  String? spanId,
  String? parentSpanId,
  String? spanName,
  Map<String, Object?> extras = const <String, Object?>{},
}) {
  final Map<String, Object?> ctx = <String, Object?>{
    if (flowId != null) LogContextKeys.flowId: flowId,
    if (requestId != null) LogContextKeys.requestId: requestId,
    if (userId != null) LogContextKeys.userId: userId,
    if (spanId != null) LogContextKeys.spanId: spanId,
    if (parentSpanId != null) LogContextKeys.parentSpanId: parentSpanId,
    if (spanName != null) LogContextKeys.spanName: spanName,
    ...extras,
  };
  return ctx;
}

/// 既存のコンテキストに新しい値をマージする。`null` で上書きするとキーを削除する。
LogContext mergeLogContext(LogContext? base, Map<String, Object?>? overlay) {
  final Map<String, Object?> result = base == null
      ? <String, Object?>{}
      : Map<String, Object?>.from(base);
  if (overlay == null || overlay.isEmpty) {
    return result;
  }
  overlay.forEach((String key, Object? value) {
    if (value == null) {
      result.remove(key);
    } else {
      result[key] = value;
    }
  });
  return result;
}

/// トレース情報を保持しつつ、子スパン生成の補助を行うヘルパー。
class LogTrace {
  LogTrace._({
    required this.spanName,
    required this.flowId,
    required this.spanId,
    required this.context,
    this.parentSpanId,
  });

  final String spanName;
  final String flowId;
  final String spanId;
  final String? parentSpanId;
  final LogContext context;

  /// 子スパン用の新しいコンテキストと LogTrace を生成する。
  LogTrace child({
    required String spanName,
    Map<String, Object?> extraContext = const <String, Object?>{},
  }) {
    final LogContext childOverlay = <String, Object?>{
      LogContextKeys.spanName: spanName,
      LogContextKeys.parentSpanId: spanId,
      LogContextKeys.spanId: newSpanId(),
      LogContextKeys.flowId: flowId,
      ...extraContext,
    };
    final LogContext childContext = mergeLogContext(context, childOverlay);
    return LogTrace._(
      spanName: spanName,
      flowId: flowId,
      spanId: childContext[LogContextKeys.spanId] as String,
      parentSpanId: spanId,
      context: Map<String, Object?>.unmodifiable(childContext),
    );
  }
}

/// 非同期処理を LogContext 付きで実行する。
Future<T> traceAsync<T>(
  String spanName,
  Future<T> Function(LogTrace trace) action, {
  Map<String, Object?>? attributes,
  bool startNewFlow = false,
  bool inheritParent = true,
}) {
  final LogContext? parent = inheritParent ? currentLogContext() : null;
  final Map<String, Object?> overlay = attributes == null
      ? <String, Object?>{}
      : Map<String, Object?>.from(attributes);

  overlay[LogContextKeys.spanName] = overlay[LogContextKeys.spanName] ?? spanName;

  final String? parentFlowId = parent != null ? parent[LogContextKeys.flowId] as String? : null;
  final String flowId = overlay[LogContextKeys.flowId] is String && (overlay[LogContextKeys.flowId] as String).isNotEmpty
    ? overlay[LogContextKeys.flowId] as String
      : (startNewFlow ? newFlowId() : parentFlowId ?? newFlowId());
  overlay[LogContextKeys.flowId] = flowId;

  final String spanId = overlay[LogContextKeys.spanId] is String && (overlay[LogContextKeys.spanId] as String).isNotEmpty
    ? overlay[LogContextKeys.spanId] as String
      : newSpanId();
  overlay[LogContextKeys.spanId] = spanId;

  if (!overlay.containsKey(LogContextKeys.parentSpanId)) {
    if (inheritParent && !startNewFlow) {
      final String? parentSpanId = parent != null ? parent[LogContextKeys.spanId] as String? : null;
      if (parentSpanId != null) {
        overlay[LogContextKeys.parentSpanId] = parentSpanId;
      }
    }
  } else if (overlay[LogContextKeys.parentSpanId] == null) {
    overlay.remove(LogContextKeys.parentSpanId);
  }

  final LogContext resolved = inheritParent
      ? mergeLogContext(parent, overlay)
      : mergeLogContext(null, overlay);

  final LogTrace trace = LogTrace._(
    spanName: resolved[LogContextKeys.spanName] as String,
    flowId: flowId,
    spanId: spanId,
    parentSpanId: resolved[LogContextKeys.parentSpanId] as String?,
    context: Map<String, Object?>.unmodifiable(resolved),
  );

    Future<T> body() => action(trace);
  return runWithContext<Future<T>>(
    overlay,
    body,
    merge: inheritParent,
  );
}

/// 同期処理を LogContext 付きで実行する。
T traceSync<T>(
  String spanName,
  T Function(LogTrace trace) action, {
  Map<String, Object?>? attributes,
  bool startNewFlow = false,
  bool inheritParent = true,
}) {
  final LogContext? parent = inheritParent ? currentLogContext() : null;
  final Map<String, Object?> overlay = attributes == null
      ? <String, Object?>{}
      : Map<String, Object?>.from(attributes);

  overlay[LogContextKeys.spanName] = overlay[LogContextKeys.spanName] ?? spanName;

  final String? parentFlowId = parent != null ? parent[LogContextKeys.flowId] as String? : null;
  final String flowId = overlay[LogContextKeys.flowId] is String && (overlay[LogContextKeys.flowId] as String).isNotEmpty
    ? overlay[LogContextKeys.flowId] as String
      : (startNewFlow ? newFlowId() : parentFlowId ?? newFlowId());
  overlay[LogContextKeys.flowId] = flowId;

  final String spanId = overlay[LogContextKeys.spanId] is String && (overlay[LogContextKeys.spanId] as String).isNotEmpty
    ? overlay[LogContextKeys.spanId] as String
      : newSpanId();
  overlay[LogContextKeys.spanId] = spanId;

  if (!overlay.containsKey(LogContextKeys.parentSpanId)) {
    if (inheritParent && !startNewFlow) {
      final String? parentSpanId = parent != null ? parent[LogContextKeys.spanId] as String? : null;
      if (parentSpanId != null) {
        overlay[LogContextKeys.parentSpanId] = parentSpanId;
      }
    }
  } else if (overlay[LogContextKeys.parentSpanId] == null) {
    overlay.remove(LogContextKeys.parentSpanId);
  }

  final LogContext resolved = inheritParent
      ? mergeLogContext(parent, overlay)
      : mergeLogContext(null, overlay);

  final LogTrace trace = LogTrace._(
    spanName: resolved[LogContextKeys.spanName] as String,
    flowId: flowId,
    spanId: spanId,
    parentSpanId: resolved[LogContextKeys.parentSpanId] as String?,
    context: Map<String, Object?>.unmodifiable(resolved),
  );

  T body() => action(trace);
  return runWithContext<T>(
    overlay,
    body,
    merge: inheritParent,
  );
}
