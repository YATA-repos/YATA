import "dart:convert";

import "log_level.dart";

/// Immutable log event traveling through the pipeline.
class LogEvent {
  LogEvent({
    required this.ts,
    required this.lvl,
    required this.msg,
    required this.eventId,
    this.tag,
    this.fields,
    this.err,
    this.st,
    this.ctx,
  });

  final DateTime ts; // UTC
  final LogLevel lvl;
  final String? tag;
  final String msg;
  final Map<String, dynamic>? fields;
  final Map<String, String>? err; // {type, message}
  final String? st; // stack trace string (possibly truncated)
  final Map<String, dynamic>? ctx;
  final String eventId; // short UUID

  LogEvent copyWith({
    DateTime? ts,
    LogLevel? lvl,
    String? tag,
    String? msg,
    Map<String, dynamic>? fields,
    Map<String, String>? err,
    String? st,
    Map<String, dynamic>? ctx,
    String? eventId,
  }) => LogEvent(
      ts: ts ?? this.ts,
      lvl: lvl ?? this.lvl,
      tag: tag ?? this.tag,
      msg: msg ?? this.msg,
      fields: fields ?? this.fields,
      err: err ?? this.err,
      st: st ?? this.st,
      ctx: ctx ?? this.ctx,
      eventId: eventId ?? this.eventId,
    );

  Map<String, dynamic> toJson() => <String, dynamic>{
      "ts": ts.toUtc().toIso8601String(),
      "lvl": lvl.name,
      if (tag != null) "tag": tag,
      "msg": msg,
      if (fields != null) "fields": fields,
      if (err != null) "err": err,
      if (st != null) "st": st,
      if (ctx != null) "ctx": ctx,
      "eventId": eventId,
    };

  String toNdjson() => jsonEncode(toJson());
}
