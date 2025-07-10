import "../base/base_error_msg.dart";
import "log_service.dart";

/// ログ機能を提供するMixin
///
/// LogServiceをラップして、簡単にログ出力をするためのMixin
mixin LoggerMixin {
  /// ログコンポーネント名
  String get loggerComponent => runtimeType.toString();

  void logDebug(String message) {
    LogService.debug(loggerComponent, message);
  }

  void logInfo(String message) {
    LogService.info(loggerComponent, message);
  }

  void logWarning(String message) {
    LogService.warning(loggerComponent, message);
  }

  /// エラーレベルログを出力
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    LogService.error(loggerComponent, message, error, stackTrace);
  }

  // --- 便利メソッドたち ---

  /// 情報レベルログ（事前定義メッセージ使用）
  ///
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  void logInfoMessage(LogMessage logMessage, [Map<String, String>? params]) {
    LogService.infoWithMessage(loggerComponent, logMessage, params);
  }

  /// 警告レベルログ（事前定義メッセージ使用）
  ///
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  void logWarningMessage(LogMessage logMessage, [Map<String, String>? params]) {
    LogService.warningWithMessage(loggerComponent, logMessage, params);
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
    LogService.errorWithMessage(loggerComponent, logMessage, params, error, stackTrace);
  }
}
