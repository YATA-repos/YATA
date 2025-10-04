import "../../core/validation/env_validator.dart";
import "log_config.dart";
import "log_level.dart";
import "logger.dart";

/// `.env` によるロガー設定のオーバーライド内容を保持するモデル。
class LogRuntimeConfig {
  const LogRuntimeConfig({
    this.level,
    this.flushIntervalMs,
    this.queueCapacity,
    this.overflowPolicy,
  });

  final LogLevel? level;
  final int? flushIntervalMs;
  final int? queueCapacity;
  final OverflowPolicy? overflowPolicy;

  bool get hasOverrides =>
      level != null ||
      flushIntervalMs != null ||
      queueCapacity != null ||
      overflowPolicy != null;

  LogConfig applyTo(LogConfig base) {
    LogConfig next = base;
    if (flushIntervalMs != null) {
      next = next.copyWith(flushEveryMs: flushIntervalMs);
    }
    if (queueCapacity != null) {
      next = next.copyWith(queueCapacity: queueCapacity);
    }
    if (overflowPolicy != null) {
      next = next.copyWith(overflowPolicy: overflowPolicy);
    }
    return next;
  }

  List<String> describe() {
    final List<String> statements = <String>[];
    if (level != null) {
      statements.add("level=${level!.name}");
    }
    if (flushIntervalMs != null) {
      statements.add("flushIntervalMs=$flushIntervalMs");
    }
    if (queueCapacity != null) {
      statements.add("queueCapacity=$queueCapacity");
    }
    if (overflowPolicy != null) {
      statements.add("overflowPolicy=${overflowPolicy!.name}");
    }
    return statements;
  }
}

typedef _WarnEmitter = void Function(String message);
typedef _InfoEmitter = void Function(String message);

/// 環境変数からロガー設定オーバーライドを構築するローダー。
class LogRuntimeConfigLoader {
  const LogRuntimeConfigLoader({this.warn});

  final _WarnEmitter? warn;

  LogRuntimeConfig load(Map<String, String> env) {
    final String? rawLevel = env["LOG_LEVEL"];
    final String? rawFlushMs = env["LOG_FLUSH_INTERVAL_MS"];
    final String? rawQueue = env["LOG_MAX_QUEUE"];
    final String? rawBackpressure = env["LOG_BACKPRESSURE"];

    final LogLevel? level = _parseLevel(rawLevel);
    final int? flushMs = _parsePositiveInt("LOG_FLUSH_INTERVAL_MS", rawFlushMs);
    final int? queueCapacity = _parsePositiveInt("LOG_MAX_QUEUE", rawQueue);
    final OverflowPolicy? overflowPolicy = _parseOverflowPolicy(rawBackpressure);

    return LogRuntimeConfig(
      level: level,
      flushIntervalMs: flushMs,
      queueCapacity: queueCapacity,
      overflowPolicy: overflowPolicy,
    );
  }

  LogLevel? _parseLevel(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final String normalized = raw.trim().toLowerCase();
    for (final LogLevel level in LogLevel.values) {
      if (level.name == normalized) {
        return level;
      }
    }
    warn?.call("LOG_LEVEL='${raw.trim()}' は無効な値です。info にフォールバックします。");
    return LogLevel.info;
  }

  int? _parsePositiveInt(String key, String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final int? value = int.tryParse(raw.trim());
    if (value == null || value <= 0) {
      warn?.call("$key='${raw.trim()}' は正の整数である必要があります。既定値を使用します。");
      return null;
    }
    return value;
  }

  OverflowPolicy? _parseOverflowPolicy(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    switch (raw.trim().toLowerCase()) {
      case "drop-oldest":
        return OverflowPolicy.dropOld;
      case "drop-newest":
        return OverflowPolicy.dropNew;
      case "block":
        return OverflowPolicy.blockWithTimeout;
      default:
        warn?.call("LOG_BACKPRESSURE='${raw.trim()}' は無効な値です。drop-new にフォールバックします。");
        return OverflowPolicy.dropNew;
    }
  }
}

/// 環境変数からロガー設定を読み取り適用するヘルパー。
void applyLogRuntimeConfig({Map<String, String>? env, _WarnEmitter? warn, _InfoEmitter? info}) {
  final Map<String, String> source = env ?? EnvValidator.env;
  final _WarnEmitter warnEmitter =
      warn ?? (String message) => w(message, tag: "logger");
  final _InfoEmitter infoEmitter =
      info ?? (String message) => i(message, tag: "logger");

  final LogRuntimeConfig config = LogRuntimeConfigLoader(warn: warnEmitter).load(source);
  if (!config.hasOverrides) {
    return;
  }

  final List<String> description = config.describe();
  if (description.isNotEmpty) {
    infoEmitter(
      "環境変数からロガー設定を適用します: ${description.join(", ")}",
    );
  }

  if (config.level != null) {
    setGlobalLevel(config.level!);
  }

  if (config.flushIntervalMs != null ||
      config.queueCapacity != null ||
      config.overflowPolicy != null) {
    updateLoggerConfig(config.applyTo);
  }
}
