import 'dart:convert';

import '../levels.dart';

class LogRecord {
  LogRecord({
    required this.ts,
    required this.level,
    required this.message,
    this.component,
    this.error,
    this.stackTrace,
    Map<String, Object?>? fields,
    Map<String, Object?>? ctxEnv,
    Map<String, Object?>? ctxDevice,
    String? sessionId,
    String? requestId,
    String? pseudoUserId,
    int? uidVersion,
  })  : fields = fields ?? {},
        ctxEnv = ctxEnv ?? {},
        ctxDevice = ctxDevice ?? {},
        sessionId = sessionId ?? '',
        requestId = requestId ?? '',
        pseudoUserId = pseudoUserId ?? '',
        uidVersion = uidVersion ?? 1;

  final DateTime ts;
  final Level level;
  final String message;
  final String? component;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, Object?> fields;
  final Map<String, Object?> ctxEnv;
  final Map<String, Object?> ctxDevice;
  final String sessionId;
  final String requestId;
  final String pseudoUserId;
  final int uidVersion;

  Map<String, Object?> toJson({int stackMaxLines = 20}) {
    String? st;
    if (stackTrace != null) {
      final raw = stackTrace.toString().split('\n');
      final cut = raw.take(stackMaxLines).join('\n');
      st = cut;
    }
    Map<String, Object?>? errObj;
    if (error != null) {
      errObj = {
        'type': error.runtimeType.toString(),
        'msg': error.toString(),
      };
    }
    return {
      'ts': ts.toUtc().toIso8601String(),
      'lvl': level.toString(),
      'sev': level.severity,
      'msg': message,
      if (component != null) 'cmp': component,
      if (errObj != null) 'err': errObj,
      if (st != null) 'st': st,
      if (fields.isNotEmpty) 'fields': fields,
      'ctx': {
        'sessionId': sessionId,
        'requestId': requestId,
        'user': {'pseudoId': pseudoUserId, 'uid_ver': uidVersion},
        'env': ctxEnv,
        'device': ctxDevice,
      },
    };
  }

  String toJsonLine({int stackMaxLines = 20}) => jsonEncode(toJson(stackMaxLines: stackMaxLines)) + '\n';
}