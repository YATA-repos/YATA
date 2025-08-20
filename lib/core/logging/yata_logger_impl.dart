import 'dart:io';

import 'package:flutter/foundation.dart';

import '../base/base_error_msg.dart';
import '../constants/app_strings/app_strings.dart';
import 'config.dart';
import 'levels.dart';
import 'logger.dart';

/// YATAアプリケーション用統一ログ管理クラス
/// 
/// アプリケーション全体で統一されたログ出力を提供します。
/// 内部でLoggerクラスのインスタンスを管理し、適切な設定で
/// ログ出力を行います。
class YataLogger {
  YataLogger._();

  static Logger? _instance;
  static bool _isInitialized = false;

  /// ログシステムを初期化
  /// 
  /// アプリケーション開始時に一度だけ呼び出してください。
  static Future<void> initialize({LoggerConfig? config}) async {
    if (_isInitialized) return;

    try {
      final LoggerConfig loggerConfig = config ?? LoggerConfig.fromDotEnv();
      _instance = await _createLogger(loggerConfig);
      _isInitialized = true;
      
      if (kDebugMode) {
        print('[YataLogger] ログシステムが初期化されました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[YataLogger] ログシステムの初期化に失敗しました: $e');
      }
      rethrow;
    }
  }

  /// ログインスタンスを取得
  static Logger? get _logger {
    if (!_isInitialized || _instance == null) {
      // フォールバック: nullを返して、呼び出し側でフォールバック処理
      return null;
    }
    return _instance!;
  }

  /// Loggerインスタンスを作成
  static Future<Logger> _createLogger(LoggerConfig config) async {
    return await Logger.configure(
      config: config,
      redactor: Redactor(),
      runtime: RuntimeInfo(),
    );
  }

  /// フォールバック時のログ出力
  static void _fallbackLog(String level, String component, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode || level == 'WARN' || level == 'ERROR' || level == 'FATAL') {
      print('[$level${component.isNotEmpty ? ':$component' : ''}] $message');
      if (error != null) print('  Error: $error');
      if (stackTrace != null) print('  StackTrace: $stackTrace');
    }
  }

  // =================================================================
  // 基本ログ機能
  // =================================================================

  /// トレースレベルログ（最も詳細なデバッグ情報）
  /// 
  /// [component] コンポーネント名（通常はクラス名）
  /// [message] ログメッセージ
  static void trace(String component, String message) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.trace(message, component: component);
    } else {
      _fallbackLog('TRACE', component, message);
    }
  }

  /// デバッグレベルログ（開発時のデバッグ情報）
  /// 
  /// [component] コンポーネント名（通常はクラス名）
  /// [message] ログメッセージ
  static void debug(String component, String message) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.debug(message, component: component);
    } else {
      _fallbackLog('DEBUG', component, message);
    }
  }

  /// 情報レベルログ（通常の情報）
  /// 
  /// [component] コンポーネント名（通常はクラス名）
  /// [message] ログメッセージ
  static void info(String component, String message) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.info(message, component: component);
    } else {
      _fallbackLog('INFO', component, message);
    }
  }

  /// 警告レベルログ（注意が必要な情報）
  /// 
  /// [component] コンポーネント名（通常はクラス名）
  /// [message] ログメッセージ
  static void warning(String component, String message) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.warn(message, component: component);
    } else {
      _fallbackLog('WARN', component, message);
    }
  }

  /// エラーレベルログ（処理可能なエラー）
  /// 
  /// [component] コンポーネント名（通常はクラス名）
  /// [message] ログメッセージ
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  static void error(
    String component,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.error(message, error: error, stackTrace: stackTrace, component: component);
    } else {
      _fallbackLog('ERROR', component, message, error, stackTrace);
    }
  }

  /// ファタルレベルログ（致命的なエラー）
  /// 
  /// [component] コンポーネント名（通常はクラス名）
  /// [message] ログメッセージ
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  static void fatal(
    String component,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.fatal(message, error: error, stackTrace: stackTrace, component: component);
    } else {
      _fallbackLog('FATAL', component, message, error, stackTrace);
    }
  }

  // =================================================================
  // 事前定義メッセージ対応
  // =================================================================

  /// 情報レベルログ（事前定義メッセージ使用）
  /// 
  /// [component] コンポーネント名
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  static void infoWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    final String message = _buildMessageWithParams(logMessage, params);
    info(component, message);
  }

  /// 警告レベルログ（事前定義メッセージ使用）
  /// 
  /// [component] コンポーネント名
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  static void warningWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    final String message = _buildMessageWithParams(logMessage, params);
    warning(component, message);
  }

  /// エラーレベルログ（事前定義メッセージ使用）
  /// 
  /// [component] コンポーネント名
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  /// [error] エラーオブジェクト
  /// [stackTrace] スタックトレース
  static void errorWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final String message = _buildMessageWithParams(logMessage, params);
    YataLogger.error(component, message, error, stackTrace);
  }

  /// メッセージテンプレートにパラメータを埋め込み
  static String _buildMessageWithParams(
    LogMessage logMessage,
    Map<String, String>? params,
  ) {
    String message = logMessage.message;
    if (params != null) {
      params.forEach((String key, String value) {
        message = message.replaceAll('{$key}', value);
      });
    }
    return message;
  }

  // =================================================================
  // 高度機能
  // =================================================================

  /// 任意レベルでのログ出力
  /// 
  /// [level] ログレベル
  /// [component] コンポーネント名
  /// [message] ログメッセージ
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  static void logWithLevel(
    Level level,
    String component,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.log(level, component, message, error, stackTrace);
  }

  /// 複雑なオブジェクトのログ出力
  /// 
  /// [component] コンポーネント名
  /// [message] ログメッセージ
  /// [object] ログ出力するオブジェクト
  static void logObject(String component, String message, Object object) {
    _logger.logObject(component, message, object);
  }

  /// 構造化ログ出力
  /// 
  /// [level] ログレベル
  /// [component] コンポーネント名
  /// [data] 構造化データ
  static void structured(Level level, String component, Map<String, dynamic> data) {
    _logger.structured(level, component, data);
  }

  // =================================================================
  // パフォーマンス監視
  // =================================================================

  /// パフォーマンス計測開始
  /// 
  /// [component] コンポーネント名
  /// [operation] 計測する操作名
  /// 戻り値: 開始時刻
  static DateTime startPerformanceTimer(String component, String operation) {
    return _logger.startPerformanceTimer(component, operation);
  }

  /// パフォーマンス計測終了・ログ出力
  /// 
  /// [startTime] 開始時刻
  /// [component] コンポーネント名
  /// [operation] 計測した操作名
  /// [thresholdMs] 閾値（ミリ秒）。この値を超えた場合のみログ出力
  static void endPerformanceTimer(
    DateTime startTime,
    String component,
    String operation, {
    int? thresholdMs,
  }) {
    _logger.endPerformanceTimer(startTime, component, operation, thresholdMs: thresholdMs);
  }

  // =================================================================
  // ビジネスメトリクス・監視
  // =================================================================

  /// クリティカルパス用ログ
  /// 
  /// [component] コンポーネント名
  /// [message] クリティカルなメッセージ
  static void critical(String component, String message) {
    _logger.critical(component, message);
  }

  /// ビジネスメトリクス記録
  /// 
  /// [component] コンポーネント名
  /// [metric] メトリクス名
  /// [data] メトリクスデータ
  static void businessMetric(String component, String metric, Map<String, dynamic> data) {
    _logger.businessMetric(component, metric, data);
  }

  /// ユーザーアクション記録
  /// 
  /// [component] コンポーネント名
  /// [action] アクション名
  /// [context] コンテキスト情報（オプション）
  static void userAction(String component, String action, {Map<String, String>? context}) {
    _logger.userAction(component, action, context: context);
  }

  /// システムヘルス監視
  /// 
  /// [component] コンポーネント名
  /// [healthMetric] ヘルスメトリクス名
  /// [value] メトリクス値
  /// [unit] 単位（オプション）
  static void systemHealth(String component, String healthMetric, dynamic value, {String? unit}) {
    _logger.systemHealth(component, healthMetric, value, unit: unit);
  }

  /// パフォーマンス計測開始
  /// 
  /// [component] コンポーネント名
  /// [operation] 計測する操作名
  /// 戻り値: 開始時刻
  static DateTime startPerformanceTimer(String component, String operation) {
    final Logger? logger = _logger;
    if (logger != null) {
      return logger.startPerformanceTimer(component, operation);
    } else {
      final DateTime start = DateTime.now();
      if (kDebugMode) {
        print('[PERF:$component] Starting $operation');
      }
      return start;
    }
  }

  /// パフォーマンス計測終了・ログ出力
  /// 
  /// [startTime] 開始時刻
  /// [component] コンポーネント名
  /// [operation] 計測した操作名
  /// [thresholdMs] 閾値（ミリ秒）。この値を超えた場合のみログ出力
  static void endPerformanceTimer(
    DateTime startTime,
    String component,
    String operation, {
    int? thresholdMs,
  }) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.endPerformanceTimer(startTime, component, operation, thresholdMs: thresholdMs);
    } else {
      final DateTime end = DateTime.now();
      final int durationMs = end.difference(startTime).inMilliseconds;
      
      if (thresholdMs == null || durationMs >= thresholdMs) {
        if (kDebugMode) {
          print('[PERF:$component] Completed $operation in ${durationMs}ms');
        }
      }
    }
  }

  /// 複雑なオブジェクトのログ出力
  /// 
  /// [component] コンポーネント名
  /// [message] ログメッセージ
  /// [object] ログ出力するオブジェクト
  static void logObject(String component, String message, Object object) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.logObject(component, message, object);
    } else {
      if (kDebugMode) {
        print('[OBJECT:$component] $message: $object');
      }
    }
  }

  /// 構造化ログ出力
  /// 
  /// [level] ログレベル
  /// [component] コンポーネント名
  /// [data] 構造化データ
  static void structured(Level level, String component, Map<String, dynamic> data) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.structured(level, component, data);
    } else {
      if (kDebugMode) {
        print('[STRUCT:$component:${level.name}] $data');
      }
    }
  }

  /// クリティカルパス用ログ
  /// 
  /// [component] コンポーネント名
  /// [message] クリティカルなメッセージ
  static void critical(String component, String message) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.critical(component, message);
    } else {
      print('[CRITICAL:$component] $message');
    }
  }

  /// ビジネスメトリクス記録
  /// 
  /// [component] コンポーネント名
  /// [metric] メトリクス名
  /// [data] メトリクスデータ
  static void businessMetric(String component, String metric, Map<String, dynamic> data) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.businessMetric(component, metric, data);
    } else {
      if (kDebugMode) {
        print('[METRIC:$component] $metric: $data');
      }
    }
  }

  /// ユーザーアクション記録
  /// 
  /// [component] コンポーネント名
  /// [action] アクション名
  /// [context] コンテキスト情報（オプション）
  static void userAction(String component, String action, {Map<String, String>? context}) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.userAction(component, action, context: context);
    } else {
      if (kDebugMode) {
        final String contextStr = context != null ? ' ($context)' : '';
        print('[ACTION:$component] $action$contextStr');
      }
    }
  }

  /// システムヘルス監視
  /// 
  /// [component] コンポーネント名
  /// [healthMetric] ヘルスメトリクス名
  /// [value] メトリクス値
  /// [unit] 単位（オプション）
  static void systemHealth(String component, String healthMetric, dynamic value, {String? unit}) {
    final Logger? logger = _logger;
    if (logger != null) {
      logger.systemHealth(component, healthMetric, value, unit: unit);
    } else {
      if (kDebugMode) {
        final String unitStr = unit != null ? ' $unit' : '';
        print('[HEALTH:$component] $healthMetric: $value$unitStr');
      }
    }
  }

  /// ログシステムの統計情報を取得
  static Map<String, dynamic> getStatistics() {
    final Logger? logger = _logger;
    if (logger != null) {
      return logger.getStatistics();
    } else {
      return <String, dynamic>{
        'type': 'fallback',
        'emitted': 0,
        'written': 0,
        'failed': 0,
        'dropped': 0,
      };
    }
  }

  /// ログシステムを停止（アプリケーション終了時）
  static Future<void> shutdown() async {
    if (_instance != null) {
      await _instance!.shutdown();
      _instance = null;
      _isInitialized = false;
    }
  }
}