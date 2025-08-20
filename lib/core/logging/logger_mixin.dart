import '../base/base_error_msg.dart';
import 'yata_logger.dart';

/// 汎用ログ機能Mixin
/// 
/// クラスにログ機能を追加するためのMixin。
/// YataLoggerを通じて統一されたログ出力を提供します。
/// 
/// 使用例:
/// ```dart
/// class MyService with LoggerMixin {
///   void doSomething() {
///     logInfo("処理を開始します");
///     try {
///       // 何らかの処理
///       logDebug("処理の詳細情報");
///     } catch (e, stackTrace) {
///       logError("処理中にエラーが発生しました", e, stackTrace);
///     }
///   }
/// }
/// ```
mixin LoggerMixin {
  /// ログ出力で使用するコンポーネント名
  /// 
  /// サブクラスでオーバーライドして、独自のコンポーネント名を指定できます。
  /// デフォルトはクラス名が使用されます。
  String get loggerComponent => runtimeType.toString();

  /// トレースレベルログ（最も詳細なデバッグ情報）
  /// 
  /// [message] ログメッセージ
  void logTrace(String message) {
    YataLogger.trace(loggerComponent, message);
  }

  /// デバッグレベルログ（開発時のデバッグ情報）
  /// 
  /// [message] ログメッセージ
  void logDebug(String message) {
    YataLogger.debug(loggerComponent, message);
  }

  /// 情報レベルログ（通常の情報）
  /// 
  /// [message] ログメッセージ
  void logInfo(String message) {
    YataLogger.info(loggerComponent, message);
  }

  /// 警告レベルログ（注意が必要な情報）
  /// 
  /// [message] ログメッセージ
  void logWarning(String message) {
    YataLogger.warning(loggerComponent, message);
  }

  /// エラーレベルログ（処理可能なエラー）
  /// 
  /// [message] ログメッセージ
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  void logError(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    YataLogger.error(loggerComponent, message, error, stackTrace);
  }

  /// ファタルレベルログ（致命的なエラー）
  /// 
  /// [message] ログメッセージ
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  void logFatal(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    YataLogger.fatal(loggerComponent, message, error, stackTrace);
  }

  // =================================================================
  // 便利メソッド
  // =================================================================

  /// パフォーマンス計測開始
  /// 
  /// [operation] 計測する操作名
  /// 戻り値: 開始時刻
  DateTime logStartPerformanceTimer(String operation) {
    return YataLogger.startPerformanceTimer(loggerComponent, operation);
  }

  /// パフォーマンス計測終了・ログ出力
  /// 
  /// [startTime] 開始時刻
  /// [operation] 計測した操作名
  /// [thresholdMs] 閾値（ミリ秒）。この値を超えた場合のみログ出力
  void logEndPerformanceTimer(
    DateTime startTime,
    String operation, {
    int? thresholdMs,
  }) {
    YataLogger.endPerformanceTimer(
      startTime,
      loggerComponent,
      operation,
      thresholdMs: thresholdMs,
    );
  }

  /// パフォーマンス計測付きメソッド実行
  /// 
  /// [operation] 操作名
  /// [method] 実行するメソッド
  /// [thresholdMs] パフォーマンス警告の閾値（ミリ秒）
  /// 戻り値: メソッドの実行結果
  Future<T> logWithPerformanceTimer<T>(
    String operation,
    Future<T> Function() method, {
    int? thresholdMs,
  }) async {
    final DateTime startTime = logStartPerformanceTimer(operation);
    try {
      final T result = await method();
      logEndPerformanceTimer(startTime, operation, thresholdMs: thresholdMs);
      return result;
    } catch (e, stackTrace) {
      logEndPerformanceTimer(startTime, "$operation (FAILED)", thresholdMs: thresholdMs);
      logError("計測中の処理で例外が発生", e, stackTrace);
      rethrow;
    }
  }

  /// オブジェクトのログ出力（デバッグ用）
  /// 
  /// [message] ログメッセージ
  /// [object] ログ出力するオブジェクト
  void logObject(String message, Object object) {
    YataLogger.logObject(loggerComponent, message, object);
  }

  /// クリティカルパス用ログ
  /// 
  /// [message] クリティカルなメッセージ
  void logCritical(String message) {
    YataLogger.critical(loggerComponent, message);
  }

  /// ビジネスメトリクス記録
  /// 
  /// [metric] メトリクス名
  /// [data] メトリクスデータ
  void logBusinessMetric(String metric, Map<String, dynamic> data) {
    YataLogger.businessMetric(loggerComponent, metric, data);
  }

  /// ユーザーアクション記録
  /// 
  /// [action] アクション名
  /// [context] コンテキスト情報（オプション）
  void logUserAction(String action, {Map<String, String>? context}) {
    YataLogger.userAction(loggerComponent, action, context: context);
  }

  /// システムヘルス監視
  /// 
  /// [healthMetric] ヘルスメトリクス名
  /// [value] メトリクス値
  /// [unit] 単位（オプション）
  void logSystemHealth(String healthMetric, dynamic value, {String? unit}) {
    YataLogger.systemHealth(loggerComponent, healthMetric, value, unit: unit);
  }

  // =================================================================
  // 事前定義メッセージ対応
  // =================================================================

  /// 情報レベルログ（事前定義メッセージ使用）
  /// 
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  void logInfoMessage(
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    YataLogger.infoWithMessage(loggerComponent, logMessage, params);
  }

  /// デバッグレベルログ（事前定義メッセージ使用）
  /// 
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  void logDebugMessage(
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    final String message = _buildMessageWithParams(logMessage, params);
    logDebug(message);
  }

  /// 警告レベルログ（事前定義メッセージ使用）
  /// 
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  void logWarningMessage(
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
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

  /// メッセージテンプレートにパラメータを埋め込み
  String _buildMessageWithParams(
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
}