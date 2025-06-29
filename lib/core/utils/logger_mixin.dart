import "../base/base_error_msg.dart";
import "log_service.dart";

/// LoggerComponentアノテーション
///
/// クラスがLoggerMixinを使用することを明示するマーカー
/// 可読性向上と開発者への意図伝達が目的
class LoggerComponent {
  /// LoggerComponentアノテーション
  ///
  /// [name] オプションのコンポーネント名（ドキュメント目的）
  const LoggerComponent([this.name]);

  /// コンポーネント名（ドキュメント目的）
  final String? name;
}

/// LoggerComponentアノテーションのインスタンス
const LoggerComponent loggerComponent = LoggerComponent();

/// ログ機能を提供するMixin
///
/// 既存のLogServiceをラップし、簡潔なログ記録を可能にする
/// 各クラスでloggerComponentを実装することで、適切なコンポーネント名を設定
mixin LoggerMixin {
  /// ログコンポーネント名
  String get loggerComponent => runtimeType.toString();

  /// デバッグレベルログ（開発時のみ）
  ///
  /// [message] ログメッセージ
  void logDebug(String message) {
    LogService.debug(loggerComponent, message);
  }

  /// 情報レベルログ
  ///
  /// [message] ログメッセージ
  void logInfo(String message) {
    LogService.info(loggerComponent, message);
  }

  /// 警告レベルログ（リリース時もファイル保存）
  ///
  /// [message] ログメッセージ
  void logWarning(String message) {
    LogService.warning(loggerComponent, message);
  }

  /// エラーレベルログ（リリース時もファイル保存）
  ///
  /// [message] ログメッセージ
  /// [error] エラーオブジェクト
  /// [stackTrace] スタックトレース
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    LogService.error(loggerComponent, message, error, stackTrace);
  }

  // --- 事前定義メッセージを使った便利メソッド ---

  /// 情報レベルログ（事前定義メッセージ使用）
  ///
  /// [logMessage] 事前定義されたLogMessage
  /// [params] メッセージパラメータ
  void logInfoMessage(LogMessage logMessage, [Map<String, String>? params]) {
    LogService.infoWithMessage(loggerComponent, logMessage, params);
  }

  /// 警告レベルログ（事前定義メッセージ使用）
  ///
  /// [logMessage] 事前定義されたLogMessage
  /// [params] メッセージパラメータ
  void logWarningMessage(LogMessage logMessage, [Map<String, String>? params]) {
    LogService.warningWithMessage(loggerComponent, logMessage, params);
  }

  /// エラーレベルログ（事前定義メッセージ使用）
  ///
  /// [logMessage] 事前定義されたLogMessage
  /// [params] メッセージパラメータ
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
