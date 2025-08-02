import "package:logger/logger.dart";

import "../base/base_error_msg.dart";
import "../constants/enums.dart";
import "yata_logger.dart";

/// 統一ログ機能Mixin (logger パッケージベース)
///
/// 既存の複数のログMixin実装を統合し、委譲チェーンを削除して最適化
/// YataLoggerを直接使用して、簡潔なログ出力APIを提供
/// logger パッケージの全機能を透過的に活用
/// 
/// 特徴:
/// - YataLoggerの統一実装を直接使用
/// - logger パッケージの全レベル対応
/// - 委譲チェーンなしでパフォーマンス向上
/// - 事前定義メッセージ対応
/// - 構造化ログ対応
mixin LoggerMixin {
  /// ログコンポーネント名（クラス名を自動取得）
  String get loggerComponent => runtimeType.toString();
  
  /// logger パッケージのLoggerインスタンス取得（直接アクセス）
  Logger get logger => YataLogger.logger;

  // =================================================================
  // logger パッケージ全レベル対応（完全活用）
  // =================================================================

  /// トレースレベルログ（logger パッケージ t()）
  void logTrace(String message) {
    YataLogger.trace(loggerComponent, message);
  }

  /// デバッグレベルログ（logger パッケージ d()）
  void logDebug(String message) {
    YataLogger.debug(loggerComponent, message);
  }

  /// 情報レベルログ（logger パッケージ i()）
  void logInfo(String message) {
    YataLogger.info(loggerComponent, message);
  }

  /// 警告レベルログ（logger パッケージ w()）
  void logWarning(String message) {
    YataLogger.warning(loggerComponent, message);
  }

  /// エラーレベルログ（logger パッケージ e()）
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    YataLogger.error(loggerComponent, message, error, stackTrace);
  }

  /// ファタルレベルログ（logger パッケージ f()）
  void logFatal(String message, [Object? error, StackTrace? stackTrace]) {
    YataLogger.fatal(loggerComponent, message, error, stackTrace);
  }

  // =================================================================
  // 事前定義メッセージ対応メソッド（既存API互換）
  // =================================================================

  /// 情報レベルログ（事前定義メッセージ使用）
  ///
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  void logInfoMessage(LogMessage logMessage, [Map<String, String>? params]) {
    YataLogger.infoWithMessage(loggerComponent, logMessage, params);
  }

  /// 警告レベルログ（事前定義メッセージ使用）
  ///
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  void logWarningMessage(LogMessage logMessage, [Map<String, String>? params]) {
    YataLogger.warningWithMessage(loggerComponent, logMessage, params);
  }

  /// エラーレベルログ（事前定義メッセージ使用）
  ///
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  /// [error] エラーオブジェクト
  /// [stackTrace] スタックトレース
  void logErrorMessage(
    LogMessage logMessage, [
    Map<String, String>? params,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    YataLogger.errorWithMessage(loggerComponent, logMessage, params, error, stackTrace);
  }

  // =================================================================
  // logger パッケージ高度機能活用
  // =================================================================

  /// logger パッケージのログレベル指定出力（汎用メソッド）
  void logWithLevel(Level level, String message, [Object? error, StackTrace? stackTrace]) {
    YataLogger.logWithLevel(level, loggerComponent, message, error, stackTrace);
  }

  /// 複雑なオブジェクトのログ出力（logger パッケージの機能活用）
  void logObject(String message, Object object) {
    YataLogger.logObject(loggerComponent, message, object);
  }

  /// 構造化ログ出力（logger パッケージの機能活用）
  void logStructured(LogLevel level, Map<String, dynamic> data) {
    YataLogger.structured(level, loggerComponent, data);
  }

  /// verbose レベルログ（開発時詳細デバッグ用）
  void logVerbose(String message) {
    YataLogger.trace(loggerComponent, message);
  }

  // =================================================================
  // logger パッケージ直接アクセス（高度なユーザー向け）
  // =================================================================

  /// logger パッケージの機能を直接活用したい場合のヘルパー
  /// 
  /// 使用例:
  /// ```dart
  /// withLogger((logger) => logger.d("Direct logger access"));
  /// ```
  void withLogger(void Function(Logger logger) action) {
    try {
      action(YataLogger.logger);
    } catch (e, stackTrace) {
      YataLogger.error(
        loggerComponent, 
        "Error in withLogger callback",
        e, 
        stackTrace,
      );
    }
  }

  /// logger パッケージの任意レベルでの構造化ログ出力
  void logMap(Level level, Map<String, dynamic> data) {
    withLogger((Logger logger) => logger.log(level, "[$loggerComponent] ${data.toString()}"));
  }

  /// logger パッケージの任意レベルでのリスト形式ログ出力
  void logList(Level level, String message, List<dynamic> items) {
    withLogger((Logger logger) {
      logger.log(level, "[$loggerComponent] $message");
      for (int i = 0; i < items.length; i++) {
        logger.log(level, "  [$i] ${items[i]}");
      }
    });
  }

  // =================================================================
  // 既存API互換メソッド（完全下位互換性）
  // =================================================================

  /// 旧NewLoggerMixin互換
  void logWithComponent(String component, String message) {
    YataLogger.info(component, message);
  }

  // =================================================================
  // パフォーマンス監視・ベンチマーク機能
  // =================================================================

  /// パフォーマンス計測開始（クラス専用）
  DateTime startPerformanceTimer(String operation) => YataLogger.startPerformanceTimer(loggerComponent, operation);

  /// パフォーマンス計測終了・ログ出力（クラス専用）
  void endPerformanceTimer(DateTime startTime, String operation, {int? thresholdMs}) {
    YataLogger.endPerformanceTimer(startTime, loggerComponent, operation, thresholdMs: thresholdMs);
  }

  /// クリティカルパス用ログ（クラス専用）
  void logCritical(String message) {
    YataLogger.critical(loggerComponent, message);
  }

  /// ビジネスメトリクス記録（クラス専用）
  void logBusinessMetric(String metric, Map<String, dynamic> data) {
    YataLogger.businessMetric(loggerComponent, metric, data);
  }

  /// ユーザーアクション記録（クラス専用）
  void logUserAction(String action, {Map<String, String>? context}) {
    YataLogger.userAction(loggerComponent, action, context: context);
  }

  /// システムヘルス監視（クラス専用）
  void logSystemHealth(String healthMetric, dynamic value, {String? unit}) {
    YataLogger.systemHealth(loggerComponent, healthMetric, value, unit: unit);
  }

  /// パフォーマンス計測付きメソッド実行
  /// 
  /// 指定されたメソッドを実行し、実行時間を自動計測・ログ出力
  Future<T> withPerformanceTimer<T>(
    String operation,
    Future<T> Function() method, {
    int? thresholdMs,
  }) async {
    final DateTime startTime = startPerformanceTimer(operation);
    try {
      final T result = await method();
      endPerformanceTimer(startTime, operation, thresholdMs: thresholdMs);
      return result;
    } catch (e) {
      endPerformanceTimer(startTime, "$operation (FAILED)", thresholdMs: thresholdMs);
      rethrow;
    }
  }
}