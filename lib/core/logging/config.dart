import 'dart:io';

import '../validation/env_validator.dart';
import 'levels.dart';

enum BackpressurePolicy { dropOldest, dropNewest, block }

class LoggerConfig {
  LoggerConfig({
    this.minLevel,
    this.flushIntervalMs = 3000,
    this.maxQueue = 5000,
    this.maxFileSizeMB = 5,
    int? maxDiskMB,
    this.retentionDays = 10,
    this.immediateFlushAtOrAbove = Level.error,
    this.logDir,
    this.backpressure = BackpressurePolicy.dropOldest,
  })  : maxDiskMB = (maxDiskMB == null || maxDiskMB < 50) ? 50 : maxDiskMB;

  Level? minLevel; // null => auto by build
  int flushIntervalMs;
  int maxQueue;
  int maxFileSizeMB;
  int maxDiskMB; // enforced lower bound 50
  int retentionDays;
  Level immediateFlushAtOrAbove;
  Directory? logDir; // if null, resolve by OS/.env
  BackpressurePolicy backpressure;

  static LoggerConfig fromDotEnv({String? path}) {
    // 統合環境管理システム（EnvValidator）を使用
    final Map<String, String> env = path != null 
        ? EnvValidator.loadFromFile(path: path)
        : <String, String>{}; // 通常はflutter_dotenvから取得
    
    Level? lvl;
    final String logLevelStr = path != null 
        ? (env['LOG_LEVEL'] ?? '')
        : EnvValidator.logLevel;
    if (logLevelStr.isNotEmpty) {
      lvl = Level.fromString(logLevelStr);
    }
    
    Directory? dir;
    final String logDirStr = path != null 
        ? (env['LOG_DIR'] ?? '')
        : EnvValidator.logDir;
    if (logDirStr.isNotEmpty) {
      dir = Directory(logDirStr);
    }
    
    return LoggerConfig(
      minLevel: lvl,
      flushIntervalMs: path != null 
          ? (int.tryParse(env['LOG_FLUSH_INTERVAL_MS'] ?? '') ?? 3000)
          : EnvValidator.logFlushIntervalMs,
      maxQueue: path != null 
          ? (int.tryParse(env['LOG_MAX_QUEUE'] ?? '') ?? 5000)
          : EnvValidator.logMaxQueue,
      maxFileSizeMB: path != null 
          ? (int.tryParse(env['LOG_MAX_FILE_SIZE_MB'] ?? '') ?? 5)
          : EnvValidator.logMaxFileSizeMb,
      maxDiskMB: path != null 
          ? (int.tryParse(env['LOG_MAX_DISK_MB'] ?? '') ?? 50)
          : EnvValidator.logMaxDiskMb,
      retentionDays: path != null 
          ? (int.tryParse(env['LOG_RETENTION_DAYS'] ?? '') ?? 10)
          : EnvValidator.logRetentionDays,
      logDir: dir,
      backpressure: _parseBackpressure(path != null 
          ? env['LOG_BACKPRESSURE']
          : EnvValidator.logBackpressure),
    );
  }

  static BackpressurePolicy _parseBackpressure(String? v) {
    switch ((v ?? 'drop-oldest').toLowerCase()) {
      case 'drop-newest':
        return BackpressurePolicy.dropNewest;
      case 'block':
        return BackpressurePolicy.block;
      default:
        return BackpressurePolicy.dropOldest;
    }
  }
}