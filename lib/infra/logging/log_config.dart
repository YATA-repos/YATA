import "dart:io";
import "package:flutter/foundation.dart";

import "log_level.dart";
import "policies.dart";

/// Masking mode for PII.
sealed class MaskMode {
  const MaskMode();

  factory MaskMode.redact() = MaskModeRedact;
  factory MaskMode.hash() = MaskModeHash;
  factory MaskMode.partial({int keepTail = 4}) => MaskModePartial(keepTail: keepTail);
}

class MaskModeRedact extends MaskMode {
  const MaskModeRedact();
}

class MaskModeHash extends MaskMode {
  const MaskModeHash();
}

class MaskModePartial extends MaskMode {
  const MaskModePartial({this.keepTail = 4});
  final int keepTail;
}

class LogConfig {
  LogConfig({
    required this.globalLevel,
    required this.consoleEnabled,
    required this.fileEnabled,
    required this.consoleUseColor,
    required this.consoleUseEmojiFallback,
    required this.fileDirPath,
    required this.fileBaseName,
    required this.rotation,
    required this.retention,
    required this.flushEveryLines,
    required this.flushEveryMs,
    required this.queueCapacity,
    required this.piiMaskingEnabled,
    required this.maskMode,
    required this.enableContext,
    required this.enableFieldsThunk,
    required this.rate,
    required this.callsite,
    required this.overflowPolicy,
    required this.overflowBlockTimeout,
    required this.crashCaptureEnabled,
    required this.crashDedupWindow,
    required this.crashSummaryInterval,
    List<RegExp>? customPatterns,
    Map<String, LogLevel>? tagLevels,
    List<String>? allowListKeys,
  }) : customPatterns = customPatterns ?? <RegExp>[],
       tagLevels = tagLevels ?? <String, LogLevel>{},
       allowListKeys = allowListKeys ?? <String>[];

  LogLevel globalLevel; // debug: DEBUG, release: INFO
  bool consoleEnabled; // true
  bool fileEnabled; // true
  bool consoleUseColor; // auto-detected
  bool consoleUseEmojiFallback; // auto-detected
  String fileDirPath; // resolved via path_provider
  String fileBaseName; // 'app'
  RotationPolicy rotation; // DailyRotation('UTC') by default
  RetentionPolicy retention; // MaxFiles(7) by default
  int flushEveryLines; // 20
  int flushEveryMs; // 500
  int queueCapacity; // 500
  bool piiMaskingEnabled; // true
  MaskMode maskMode; // redact/hash/partial(4)
  final List<RegExp> customPatterns; // []
  final Map<String, LogLevel> tagLevels; // {}
  final List<String> allowListKeys; // []
  bool enableContext; // true
  bool enableFieldsThunk; // true
  RateConfig rate; // Phase 3
  CallsiteConfig callsite; // Phase 3
  OverflowPolicy overflowPolicy; // Phase 3
  Duration overflowBlockTimeout; // Phase 3
  bool crashCaptureEnabled; // Phase 3
  Duration crashDedupWindow; // Phase 3
  Duration crashSummaryInterval; // Phase 3

  LogConfig copyWith({
    LogLevel? globalLevel,
    bool? consoleEnabled,
    bool? fileEnabled,
    bool? consoleUseColor,
    bool? consoleUseEmojiFallback,
    String? fileDirPath,
    String? fileBaseName,
    RotationPolicy? rotation,
    RetentionPolicy? retention,
    int? flushEveryLines,
    int? flushEveryMs,
    int? queueCapacity,
    bool? piiMaskingEnabled,
    MaskMode? maskMode,
    List<RegExp>? customPatterns,
    Map<String, LogLevel>? tagLevels,
    List<String>? allowListKeys,
    bool? enableContext,
    bool? enableFieldsThunk,
    RateConfig? rate,
    CallsiteConfig? callsite,
    OverflowPolicy? overflowPolicy,
    Duration? overflowBlockTimeout,
    bool? crashCaptureEnabled,
    Duration? crashDedupWindow,
    Duration? crashSummaryInterval,
  }) {
    final LogConfig c = LogConfig(
      globalLevel: globalLevel ?? this.globalLevel,
      consoleEnabled: consoleEnabled ?? this.consoleEnabled,
      fileEnabled: fileEnabled ?? this.fileEnabled,
      consoleUseColor: consoleUseColor ?? this.consoleUseColor,
      consoleUseEmojiFallback: consoleUseEmojiFallback ?? this.consoleUseEmojiFallback,
      fileDirPath: fileDirPath ?? this.fileDirPath,
      fileBaseName: fileBaseName ?? this.fileBaseName,
      rotation: rotation ?? this.rotation,
      retention: retention ?? this.retention,
      flushEveryLines: flushEveryLines ?? this.flushEveryLines,
      flushEveryMs: flushEveryMs ?? this.flushEveryMs,
      queueCapacity: queueCapacity ?? this.queueCapacity,
      piiMaskingEnabled: piiMaskingEnabled ?? this.piiMaskingEnabled,
      maskMode: maskMode ?? this.maskMode,
      customPatterns: customPatterns ?? this.customPatterns,
      tagLevels: tagLevels ?? this.tagLevels,
      allowListKeys: allowListKeys ?? this.allowListKeys,
      enableContext: enableContext ?? this.enableContext,
      enableFieldsThunk: enableFieldsThunk ?? this.enableFieldsThunk,
      rate: rate ?? this.rate,
      callsite: callsite ?? this.callsite,
      overflowPolicy: overflowPolicy ?? this.overflowPolicy,
      overflowBlockTimeout: overflowBlockTimeout ?? this.overflowBlockTimeout,
      crashCaptureEnabled: crashCaptureEnabled ?? this.crashCaptureEnabled,
      crashDedupWindow: crashDedupWindow ?? this.crashDedupWindow,
      crashSummaryInterval: crashSummaryInterval ?? this.crashSummaryInterval,
    );
    return c;
  }

  static bool _isRelease() => kReleaseMode;

  static LogConfig defaults({required String fileDirPath}) {
    final bool release = _isRelease();
    final bool supportsColor = stdout.supportsAnsiEscapes;
    return LogConfig(
      globalLevel: release ? LogLevel.info : LogLevel.debug,
      consoleEnabled: true,
      fileEnabled: true,
      consoleUseColor: supportsColor,
      consoleUseEmojiFallback: !supportsColor,
      fileDirPath: fileDirPath,
      fileBaseName: "app",
      rotation: DailyRotation(),
      retention: MaxFiles(),
      flushEveryLines: 20,
      flushEveryMs: 500,
      queueCapacity: 500,
      piiMaskingEnabled: true,
      maskMode: MaskMode.redact(),
      enableContext: true,
      enableFieldsThunk: true,
      rate: RateConfig.defaults(),
      callsite: CallsiteConfig.defaults(),
      overflowPolicy: OverflowPolicy.dropNew,
      overflowBlockTimeout: const Duration(milliseconds: 50),
      crashCaptureEnabled: true,
      crashDedupWindow: const Duration(seconds: 30),
      crashSummaryInterval: const Duration(seconds: 60),
    );
  }
}

/// Config hub to allow atomic updates and predicate checks.
class LogConfigHub {
  LogConfigHub(this._config);

  LogConfig _config;

  // Immutable snapshot exposure (by convention: treat LogConfig as immutable outside)
  LogConfig get snapshot => _config;
  LogConfig get value => _config; // backward compatibility for existing uses

  // Atomic update by replacing the whole instance.
  void update(LogConfig Function(LogConfig) mutate) {
    _config = mutate(_config);
  }

  bool shouldLog(LogLevel level, {String? tag}) {
    final LogLevel? tagLevel = (tag != null) ? _config.tagLevels[tag] : null;
    final LogLevel threshold = tagLevel ?? _config.globalLevel;
    return level.index >= threshold.index;
  }

  // Convenience dynamic setters
  void setGlobalLevel(LogLevel level) => update((LogConfig c) => c.copyWith(globalLevel: level));
  void setTagLevel(String tag, LogLevel level) => update(
    (LogConfig c) => c.copyWith(tagLevels: <String, LogLevel>{...c.tagLevels, tag: level}),
  );
  void clearTagLevel(String tag) => update((LogConfig c) {
    final Map<String, LogLevel> m = <String, LogLevel>{...c.tagLevels}..remove(tag);
    return c.copyWith(tagLevels: m);
  });
}

// ----------------------
// Phase 3: Rate limiting
// ----------------------

class TokenBucket {
  TokenBucket({required this.capacity, required this.refillPerSec})
    : _tokens = capacity.toDouble(),
      _lastRefill = DateTime.now();

  int capacity;
  int refillPerSec;

  double _tokens;
  DateTime _lastRefill;

  void _refill() {
    final DateTime now = DateTime.now();
    final double elapsedSec = now.difference(_lastRefill).inMilliseconds / 1000.0;
    if (elapsedSec <= 0) {
      return;
    }
    _tokens = (_tokens + elapsedSec * refillPerSec).clamp(0, capacity).toDouble();
    _lastRefill = now;
  }

  bool tryConsume([int n = 1]) {
    _refill();
    if (_tokens >= n) {
      _tokens -= n;
      return true;
    }
    return false;
  }
}

typedef TagLevel = (String, LogLevel);

class RateConfig {
  RateConfig({
    required this.enabled,
    required this.global,
    Map<String, TokenBucket>? perTag,
    Map<TagLevel, TokenBucket>? perTagLevel,
    Map<TagLevel, int>? sampling,
    Duration? summaryInterval,
    bool? summaryToConsole,
    bool? summaryToFile,
  }) : perTag = perTag ?? <String, TokenBucket>{},
       perTagLevel = perTagLevel ?? <TagLevel, TokenBucket>{},
       sampling = sampling ?? <TagLevel, int>{},
       summaryInterval = summaryInterval ?? const Duration(seconds: 60),
       summaryToConsole = summaryToConsole ?? true,
       summaryToFile = summaryToFile ?? true;

  bool enabled; // default true
  TokenBucket global; // default 200/s
  final Map<String, TokenBucket> perTag; // {}
  final Map<TagLevel, TokenBucket> perTagLevel; // {}
  final Map<TagLevel, int> sampling; // percentage 0..100
  Duration summaryInterval; // default 60s
  bool summaryToConsole; // follow consoleEnabled when true
  bool summaryToFile; // follow fileEnabled when true

  static RateConfig defaults() =>
      RateConfig(enabled: true, global: TokenBucket(capacity: 200, refillPerSec: 200));
}

// ----------------------
// Phase 3: Callsite info
// ----------------------

class CallsiteConfig {
  CallsiteConfig({
    required this.enabled,
    this.skipFrames,
    this.basenameOnly = true,
    this.cacheSize = 256,
  });
  bool enabled; // default false
  int? skipFrames; // autodetect if null
  bool basenameOnly; // default true
  int cacheSize; // default 256

  static CallsiteConfig defaults() => CallsiteConfig(enabled: false);
}

// ----------------------
// Phase 3: Overflow policy
// ----------------------

enum OverflowPolicy { dropNew, dropOld, blockWithTimeout }
