import "dart:io";

import "log_event.dart";
import "log_level.dart";

abstract class Formatter<T> {
  String get name;

  T format(LogEvent event);
}

class ConsolePrettyFormatter implements Formatter<String> {
  ConsolePrettyFormatter({required this.useColor, required this.useEmojiFallback});

  final bool useColor;
  final bool useEmojiFallback;

  @override
  String get name => "console_pretty";

  static const Map<LogLevel, String> _ansi = <LogLevel, String>{
    LogLevel.trace: "\x1B[90m",
    LogLevel.debug: "\x1B[34m",
    LogLevel.info: "\x1B[32m",
    LogLevel.warn: "\x1B[33m",
    LogLevel.error: "\x1B[31m",
    LogLevel.fatal: "\x1B[97;41m",
  };

  static const Map<LogLevel, String> _emoji = <LogLevel, String>{
    LogLevel.trace: "🔎",
    LogLevel.debug: "🐛",
    LogLevel.info: "ℹ️",
    LogLevel.warn: "⚠️",
    LogLevel.error: "❌",
    LogLevel.fatal: "💥",
  };

  @override
  String format(LogEvent event) {
    final String ts = _fmtTime(event.ts);
    final String lvl = event.lvl.labelUpper.padRight(5);
    final String tag = event.tag != null ? " (${event.tag})" : "";
    final String fields = _fmtFields(event.fields);
    final String eventId = event.eventId;
    final String base = "$ts [$lvl]$tag ${event.msg}$fields #$eventId";

    final String withErr = _appendErrorAndStack(base, event);

    if (useColor && stdout.supportsAnsiEscapes) {
      final String color = _ansi[event.lvl] ?? "";
      const String reset = "\x1B[0m";
      return "$color$withErr$reset";
    }
    if (useEmojiFallback) {
      final String emoji = _emoji[event.lvl] ?? "";
      return "$emoji $withErr";
    }
    return withErr;
  }

  static String _fmtTime(DateTime dt) {
    final DateTime l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, "0");
    String three(int n) => n.toString().padLeft(3, "0");
    return "${two(l.hour)}:${two(l.minute)}:${two(l.second)}.${three(l.millisecond)}";
  }

  static String _fmtFields(Map<String, dynamic>? fields) {
    if (fields == null || fields.isEmpty) {
      return "";
    }
    final String kv = fields.entries
        .map((MapEntry<String, dynamic> e) => "${e.key}:${_short(e.value)}")
        .join(", ");
    return " {$kv}";
  }

  static String _appendErrorAndStack(String base, LogEvent e) {
    String s = base;
    if (e.err != null) {
      final String type = e.err!["type"] ?? "Error";
      final String msg = e.err!["message"] ?? "";
      s = "$s\n  error: $type: $msg";
    }
    if (e.st != null && e.st!.isNotEmpty) {
      final String st = _truncate(e.st!, 1200);
      s = "$s\n  stack: $st";
    }
    return s;
  }

  static String _truncate(String s, int max) {
    if (s.length <= max) {
      return s;
    }
    final int more = s.length - max;
    return "${s.substring(0, max)}…($more more)";
  }

  static Object _short(Object? v) {
    if (v == null) {
      return "null";
    }
    final String s = v.toString();
    if (s.length > 120) {
      return "${s.substring(0, 117)}…";
    }
    return s;
  }
}

class NdjsonFormatter implements Formatter<String> {
  @override
  String get name => "ndjson";

  @override
  String format(LogEvent event) => event.toNdjson();
}
