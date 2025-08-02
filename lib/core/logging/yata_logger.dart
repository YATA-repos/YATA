import "dart:async";
import "dart:developer" as developer;

import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:logger/logger.dart";

import "../base/base_error_msg.dart";
import "../constants/enums.dart";
import "logger_components.dart";
import "logger_configuration.dart";

/// YATA統一ログサービス (logger パッケージベース)
///
/// 既存の複数のログ実装を統合した
/// logger パッケージ完全準拠の統一ログシステム
/// 
/// 特徴:
/// - logger パッケージのアーキテクチャを完全活用
/// - シングルトンLoggerインスタンス管理
/// - 開発時: 全レベルをconsole出力
/// - リリース時: warning/error以上をファイル出力
/// - 既存API完全互換
class YataLogger {
  YataLogger._();
  
  static YataLogger? _instance;
  static Logger? _logger;
  static UnifiedYataLogFilter? _filter;
  static UnifiedBufferedFileOutput? _fileOutput;
  static bool _initialized = false;
  
  /// シングルトンインスタンス取得
  static YataLogger get instance {
    _instance ??= YataLogger._();
    return _instance!;
  }

  /// logger パッケージのLoggerインスタンス取得
  static Logger get logger {
    if (_logger == null || !_initialized) {
      throw StateError("YataLogger is not initialized. Call initialize() first.");
    }
    return _logger!;
  }

  /// 初期化済みかチェック
  static bool get isInitialized => _initialized;
  
  /// 現在の最小ログレベル取得
  static LogLevel? get currentMinimumLevel => _filter?.minimumLevel;

  /// ログサービスを初期化
  /// 
  /// [minimumLevel] 最小ログレベル（環境に応じて自動選択）
  static Future<void> initialize({LogLevel? minimumLevel}) async {
    if (_initialized) {
      return;
    }

    try {
      // パフォーマンス統計の初期化時刻を記録
      LoggerPerformanceStats.markInitialization();
      
      // 環境変数から設定を読み込み
      LoggerConfig.loadFromEnvironment();
      
      // 環境別最適ログレベル設定
      final LogLevel effectiveLevel = minimumLevel ?? _getOptimalLogLevel();
      _filter = UnifiedYataLogFilter(effectiveLevel);
      
      // ファイル出力用コンポーネント（リリース時のみ）
      if (kReleaseMode) {
        _fileOutput = UnifiedBufferedFileOutput.fromConfig();
        await _fileOutput!.initialize();
      }
      
      // Loggerインスタンス作成（logger パッケージのアーキテクチャ活用）
      final List<LogOutput> outputs = <LogOutput>[];
      
      // デバッグ時はコンソール出力を追加
      if (kDebugMode) {
        outputs.add(ConsoleOutput());
      }
      
      // リリース時はファイル出力を追加
      if (kReleaseMode && _fileOutput != null) {
        outputs.add(_fileOutput!);
      }
      
      _logger = Logger(
        filter: _filter!,
        printer: kDebugMode 
            ? UnifiedYataLogPrinter.development()
            : UnifiedYataLogPrinter.production(),
        output: outputs.length == 1 ? outputs.first : MultiOutput(outputs),
      );
      
      _initialized = true;
      _logger!.i("[YataLogger] Logger service initialized successfully");
      _logger!.d("[YataLogger] Configuration: ${LoggerConfig.toDebugString()}");
    } catch (e, stackTrace) {
      developer.log(
        "Failed to initialize YataLogger: ${e.toString()}",
        level: 1000,
        name: "YataLogger",
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 最小ログレベルを動的に変更
  /// 
  /// [level] 新しい最小ログレベル
  static void setMinimumLevel(LogLevel level) {
    if (!_initialized || _filter == null) {
      developer.log("YataLogger not initialized", name: "YataLogger");
      return;
    }
    
    _filter!.setMinimumLevel(level);
    _logger!.i("[YataLogger] Minimum log level changed to ${level.value}");
  }

  /// ログサービスの終了処理
  static Future<void> dispose() async {
    if (!_initialized) return;
    
    if (_fileOutput != null) {
      await _fileOutput!.dispose();
    }
    
    _logger = null;
    _filter = null;
    _fileOutput = null;
    _initialized = false;
  }

  // =================================================================
  // logger パッケージ直接活用メソッド（基本API）
  // =================================================================

  /// トレースレベルログ（logger パッケージ t()）
  static void trace(String component, String message) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    _logger!.t("[$component] $message");
  }

  /// デバッグレベルログ（logger パッケージ d()）
  static void debug(String component, String message) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    _logger!.d("[$component] $message");
  }

  /// 情報レベルログ（logger パッケージ i()）
  static void info(String component, String message) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    _logger!.i("[$component] $message");
  }

  /// 警告レベルログ（logger パッケージ w()）
  static void warning(String component, String message) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    _logger!.w("[$component] $message");
  }

  /// エラーレベルログ（logger パッケージ e()）
  static void error(String component, String message, [Object? error, StackTrace? stackTrace]) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    _logger!.e("[$component] $message", error: error, stackTrace: stackTrace);
  }

  /// ファタルレベルログ（logger パッケージ f()）
  static void fatal(String component, String message, [Object? error, StackTrace? stackTrace]) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    _logger!.f("[$component] $message", error: error, stackTrace: stackTrace);
  }

  // =================================================================
  // 事前定義メッセージ対応（既存API互換）
  // =================================================================

  /// 情報レベルログ（事前定義メッセージ使用）
  static void infoWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    final String message = params != null ? logMessage.withParams(params) : logMessage.message;
    _logger!.i("[$component] $message");
  }

  /// 警告レベルログ（事前定義メッセージ使用）
  static void warningWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    final String message = params != null ? logMessage.withParams(params) : logMessage.message;
    _logger!.w("[$component] $message");
  }

  /// エラーレベルログ（事前定義メッセージ使用）
  static void errorWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    final String message = params != null ? logMessage.withParams(params) : logMessage.message;
    _logger!.e("[$component] $message", error: error, stackTrace: stackTrace);
  }

  // =================================================================
  // logger パッケージ高度機能活用
  // =================================================================

  /// logger パッケージのログレベル指定出力
  static void logWithLevel(Level level, String component, String message, [Object? error, StackTrace? stackTrace]) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    _logger!.log(level, "[$component] $message", error: error, stackTrace: stackTrace);
  }

  /// 複雑なオブジェクトのログ出力（logger パッケージの機能活用）
  static void logObject(String component, String message, Object object) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    _logger!.d("[$component] $message\\n$object");
  }

  /// 構造化ログ出力（logger パッケージの機能活用）
  static void structured(LogLevel level, String component, Map<String, dynamic> data) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    
    final String message = "[$component] ${data.toString()}";
    switch (level) {
      case LogLevel.debug:
        _logger!.d(message);
        break;
      case LogLevel.info:
        _logger!.i(message);
        break;
      case LogLevel.warning:
        _logger!.w(message);
        break;
      case LogLevel.error:
        _logger!.e(message);
        break;
    }
  }

  // =================================================================
  // ファイル出力・統計機能
  // =================================================================

  /// ログファイル統計情報を取得
  static Future<Map<String, dynamic>> getLogStats() async {
    if (!_initialized) {
      return <String, dynamic>{"error": "YataLogger is not initialized"};
    }

    if (_fileOutput != null) {
      final Map<String, dynamic> fileStats = await _fileOutput!.getLogStats();
      
      // 追加の運用統計情報を含める
      fileStats.addAll(<String, dynamic>{
        "systemInfo": _getSystemInfo(),
        "performanceSummary": _getPerformanceSummary(),
        "healthStatus": _getOverallHealthStatus(),
      });
      
      return fileStats;
    }

    return <String, dynamic>{
      "mode": "debug",
      "minimumLevel": _filter?.minimumLevel.value ?? "unknown",
      "fileOutputEnabled": false,
      "systemInfo": _getSystemInfo(),
      "performanceSummary": _getPerformanceSummary(),
      "healthStatus": _getOverallHealthStatus(),
    };
  }

  /// システム情報を取得
  static Map<String, dynamic> _getSystemInfo() => <String, dynamic>{
      "initialized": _initialized,
      "loggerVersion": "2.0.0", // バージョン管理
      "initializationTime": LoggerPerformanceStats.getAllStats()["basic"]["initializationTime"] ?? "unknown",
      "currentTime": DateTime.now().toIso8601String(),
      "runtimeMode": kDebugMode ? "debug" : (kProfileMode ? "profile" : "release"),
    };

  /// パフォーマンス概要を取得
  static Map<String, dynamic> _getPerformanceSummary() {
    final Map<String, dynamic> allStats = LoggerPerformanceStats.getAllStats();
    final Map<String, dynamic> performanceStats = allStats["performance"] as Map<String, dynamic>? ?? <String, dynamic>{};
    
    return <String, dynamic>{
      "logsPerSecond": _calculateLogsPerSecond(),
      "averageFlushTime": performanceStats["averageFlushTimeMs"] ?? "0",
      "failureRate": performanceStats["failureRatePercent"] ?? "0",
      "healthScore": _calculateHealthScore(performanceStats),
    };
  }

  /// 全体的な健康状態を取得
  static String _getOverallHealthStatus() {
    final Map<String, dynamic> health = LoggerPerformanceStats.getHealthCheck();
    final bool isHealthy = health["overallHealthy"] as bool? ?? false;
    
    if (isHealthy) {
      return "healthy";
    } else if (health["flushHealthy"] == false) {
      return "warning_flush_issues";
    } else if (health["performanceHealthy"] == false) {
      return "warning_performance_issues";
    } else {
      return "warning_general_issues";
    }
  }

  /// 1秒あたりのログ処理数を計算
  static double _calculateLogsPerSecond() {
    final Map<String, dynamic> basicStats = LoggerPerformanceStats.getBasicStats();
    final int totalLogs = basicStats["totalLogsProcessed"] as int? ?? 0;
    
    if (totalLogs == 0) return 0.0;
    
    final String? initTimeStr = basicStats["initializationTime"] as String?;
    if (initTimeStr == null) return 0.0;
    
    try {
      final DateTime initTime = DateTime.parse(initTimeStr);
      final Duration uptime = DateTime.now().difference(initTime);
      final double uptimeSeconds = uptime.inSeconds.toDouble();
      
      return uptimeSeconds > 0 ? totalLogs / uptimeSeconds : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// ヘルススコアを計算（0-100）
  static int _calculateHealthScore(Map<String, dynamic> performanceStats) {
    int score = 100;
    
    // フラッシュ失敗率によるスコア減算
    final String failureRateStr = performanceStats["failureRatePercent"] as String? ?? "0";
    final double failureRate = double.tryParse(failureRateStr) ?? 0.0;
    score -= (failureRate * 2).round(); // 失敗率1%につき2点減点
    
    // フラッシュ時間によるスコア減算
    final String avgFlushTimeStr = performanceStats["averageFlushTimeMs"] as String? ?? "0";
    final double avgFlushTime = double.tryParse(avgFlushTimeStr) ?? 0.0;
    if (avgFlushTime > 1000) { // 1秒以上
      score -= ((avgFlushTime - 1000) / 100).round(); // 100ms超過につき1点減点
    }
    
    return score.clamp(0, 100);
  }

  /// 古いログファイルをクリーンアップする
  /// 
  /// [daysToKeep] 保持する日数（デフォルト: 30日）
  /// [dryRun] trueの場合、削除対象の特定のみで実際の削除は行わない
  /// [maxFilesToDelete] 一度に削除するファイル数の上限（安全性のため）
  /// 戻り値: クリーンアップ統計情報
  static Future<Map<String, dynamic>> cleanupOldLogs({
    int daysToKeep = 30,
    bool dryRun = false,
    int maxFilesToDelete = 100,
  }) async {
    if (_fileOutput != null) {
      return _fileOutput!.cleanupOldLogs(
        daysToKeep: daysToKeep,
        dryRun: dryRun,
        maxFilesToDelete: maxFilesToDelete,
      );
    } else {
      return <String, dynamic>{
        "error": "File output not initialized - cleanup not available",
        "fileOutputEnabled": false,
        "completed": false,
      };
    }
  }

  /// バッファの内容をファイルに書き込み
  static Future<void> flushBuffer() async {
    if (_fileOutput != null) {
      await _fileOutput!.flushBuffer();
    }
  }

  // =================================================================
  // 設定・パフォーマンス管理機能
  // =================================================================

  /// 現在のLogger設定を取得
  static Map<String, dynamic> getConfig() => LoggerConfig.toMap();

  /// 設定をデバッグ形式で表示
  static String getConfigDebugString() => LoggerConfig.toDebugString();

  /// パフォーマンス統計を取得
  static Map<String, dynamic> getPerformanceStats() => LoggerPerformanceStats.getAllStats();

  /// パフォーマンス統計をデバッグ形式で表示
  static String getPerformanceStatsDebugString() => LoggerPerformanceStats.toDebugString();

  /// Logger健康状態をチェック
  static Map<String, dynamic> getHealthCheck() => LoggerPerformanceStats.getHealthCheck();

  // =================================================================
  // 既存API互換メソッド（下位互換性維持）
  // =================================================================

  /// verbose レベルログ（既存APIとの互換性）
  static void verbose(String message) {
    if (_initialized) {
      _logger!.t(message); // trace level
    }
  }

  /// シンプルなlog系メソッド（互換性維持）
  static void logDebug(String component, String message) => debug(component, message);
  static void logInfo(String component, String message) => info(component, message);
  static void logWarning(String component, String message) => warning(component, message);
  static void logError(String component, String message, [Object? errorObj, StackTrace? stackTrace]) {
    error(component, message, errorObj, stackTrace);
  }

  // =================================================================
  // 環境別最適化設定
  // =================================================================

  /// 実行環境に応じた最適なログレベルを取得
  /// 
  /// ログレベル決定の優先順位：
  /// 1. 環境変数 LOG_LEVEL (.envファイル経由)
  /// 2. コンパイル時環境変数 LOG_LEVEL
  /// 3. 実行環境による自動選択
  /// 
  /// サポートされるレベル：
  /// - TRACE: 詳細トレースログ
  /// - DEBUG: デバッグレベル（詳細ログ）
  /// - INFO: 情報レベル（一般的な動作）
  /// - WARNING: 警告レベル（問題の可能性）
  /// - ERROR: エラーレベル（エラーのみ）
  /// 
  /// 実行環境による自動選択：
  /// - Debug Mode: DEBUG（開発効率重視）
  /// - Profile Mode: INFO（パフォーマンス考慮）
  /// - Release Mode: WARNING（ストレージ節約）
  static LogLevel _getOptimalLogLevel() {
    // 1. 実行時環境変数による明示的指定を最優先 (.envファイル経由)
    try {
      final String? runtimeLogLevel = dotenv.env["LOG_LEVEL"];
      if (runtimeLogLevel != null && runtimeLogLevel.isNotEmpty) {
        switch (runtimeLogLevel.toUpperCase()) {
          case "TRACE":
            return LogLevel.debug; // YATAではtraceをdebugにマッピング
          case "DEBUG":
            return LogLevel.debug;
          case "INFO":
            return LogLevel.info;
          case "WARNING":
          case "WARN":
            return LogLevel.warning;
          case "ERROR":
            return LogLevel.error;
        }
      }
    } catch (e) {
      // .envファイルが読み込まれていない場合は続行
      developer.log(
        "Failed to read runtime LOG_LEVEL from .env: ${e.toString()}",
        name: "YataLogger",
      );
    }

    // 2. コンパイル時環境変数による指定
    final String compileTimeLogLevel = const String.fromEnvironment("LOG_LEVEL");
    if (compileTimeLogLevel.isNotEmpty) {
      switch (compileTimeLogLevel.toUpperCase()) {
        case "TRACE":
          return LogLevel.debug;
        case "DEBUG":
          return LogLevel.debug;
        case "INFO":
          return LogLevel.info;
        case "WARNING":
        case "WARN":
          return LogLevel.warning;
        case "ERROR":
          return LogLevel.error;
      }
    }
  
    // 3. 実行環境による自動選択（最適化された設定）
    if (kDebugMode) {
      // 開発環境: デバッグ効率重視、詳細ログで問題解析をサポート
      return LogLevel.debug;
    } else if (kProfileMode) {
      // プロファイル環境: パフォーマンス重視、重要な情報のみ記録
      return LogLevel.info;
    } else {
      // リリース環境: 運用効率重視、問題追跡に必要な情報のみ記録
      return LogLevel.warning;
    }
  }

  /// 現在有効なログレベル設定の詳細情報を取得
  static Map<String, dynamic> getLogLevelInfo() {
    // 実行時とコンパイル時の環境変数を取得
    String? runtimeLogLevel;
    try {
      runtimeLogLevel = dotenv.env["LOG_LEVEL"];
    } catch (e) {
      runtimeLogLevel = null;
    }
    
    final String compileTimeLogLevel = const String.fromEnvironment("LOG_LEVEL", defaultValue: "not_set");
    
    return <String, dynamic>{
      "currentLevel": _filter?.minimumLevel.value ?? "not_initialized",
      "currentPriority": _filter?.minimumLevel.priority ?? -1,
      "debugMode": kDebugMode,
      "profileMode": kProfileMode,
      "releaseMode": kReleaseMode,
      "runtimeEnvironmentVariable": runtimeLogLevel ?? "not_set",
      "compileTimeEnvironmentVariable": compileTimeLogLevel,
      "optimalLevel": _getOptimalLogLevel().value,
      "configurationSource": _getConfigurationSource(),
      "supportedLevels": <String>["TRACE", "DEBUG", "INFO", "WARNING", "ERROR"],
    };
  }

  /// ログレベル設定のソースを特定
  static String _getConfigurationSource() {
    try {
      final String? runtimeLogLevel = dotenv.env["LOG_LEVEL"];
      if (runtimeLogLevel != null && runtimeLogLevel.isNotEmpty) {
        return "runtime_env_variable"; // .envファイル
      }
    } catch (e) {
      // .envファイル読み込み失敗時は続行
    }

    final String compileTimeLogLevel = const String.fromEnvironment("LOG_LEVEL");
    if (compileTimeLogLevel.isNotEmpty) {
      return "compile_time_env_variable";
    }

    if (kDebugMode) {
      return "auto_debug_mode";
    } else if (kProfileMode) {
      return "auto_profile_mode";
    } else {
      return "auto_release_mode";
    }
  }

  // =================================================================
  // パフォーマンス監視・ベンチマーク機能
  // =================================================================

  /// パフォーマンス計測開始（ベンチマーク用）
  /// 
  /// [operation] 操作名
  /// [component] コンポーネント名
  /// 戻り値：計測開始時刻（ストップウォッチとして使用）
  static DateTime startPerformanceTimer(String component, String operation) {
    final DateTime startTime = DateTime.now();
    if (_initialized && _filter!.minimumLevel.priority <= LogLevel.debug.priority) {
      _logger!.d("[$component] ⏱️ Performance timer started: $operation");
    }
    return startTime;
  }

  /// パフォーマンス計測終了・ログ出力
  /// 
  /// [startTime] startPerformanceTimer()の戻り値
  /// [operation] 操作名
  /// [component] コンポーネント名
  /// [threshold] 警告を出すしきい値（ミリ秒）
  static void endPerformanceTimer(
    DateTime startTime, 
    String component, 
    String operation, {
    int? thresholdMs,
  }) {
    if (!_initialized) return;

    final DateTime endTime = DateTime.now();
    final Duration elapsed = endTime.difference(startTime);
    final int elapsedMs = elapsed.inMilliseconds;
    
    // しきい値チェック
    final int threshold = thresholdMs ?? 1000; // デフォルト1秒
    final bool isSlow = elapsedMs > threshold;
    
    LoggerPerformanceStats.incrementLogsProcessed();
    
    if (isSlow) {
      _logger!.w("[$component] ⚠️ Slow operation detected: $operation took ${elapsedMs}ms (threshold: ${threshold}ms)");
    } else if (_filter!.minimumLevel.priority <= LogLevel.debug.priority) {
      _logger!.d("[$component] ✅ Performance timer ended: $operation took ${elapsedMs}ms");
    }
  }

  /// クリティカルパス用ログ（常に記録される重要ログ）
  /// 
  /// レベルフィルターを無視して必ず記録される
  /// サービス開始・終了、重要なビジネスロジック等で使用
  static void critical(String component, String message) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    _logger!.f("[$component] 🔥 CRITICAL: $message");
  }

  /// ビジネスメトリクス記録用ログ
  /// 
  /// 売上、注文数、在庫変動等のビジネス指標を記録
  /// 分析・レポート生成時の参照用
  static void businessMetric(String component, String metric, Map<String, dynamic> data) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    final String dataStr = data.entries.map((MapEntry<String, dynamic> e) => "${e.key}=${e.value}").join(", ");
    _logger!.i("[$component] 📊 METRIC[$metric]: $dataStr");
  }

  /// ユーザーアクション記録用ログ
  /// 
  /// ユーザーの操作履歴を記録（UI分析・UX改善用）
  static void userAction(String component, String action, {Map<String, String>? context}) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    final String contextStr = context != null ? " | ${context.toString()}" : "";
    _logger!.i("[$component] 👤 USER_ACTION: $action$contextStr");
  }

  /// システムヘルス監視用ログ
  /// 
  /// メモリ使用量、レスポンス時間等のシステム状態を記録
  static void systemHealth(String component, String healthMetric, dynamic value, {String? unit}) {
    if (!_initialized) return;
    LoggerPerformanceStats.incrementLogsProcessed();
    final String unitStr = unit != null ? " $unit" : "";
    _logger!.i("[$component] 🏥 HEALTH[$healthMetric]: $value$unitStr");
  }
}