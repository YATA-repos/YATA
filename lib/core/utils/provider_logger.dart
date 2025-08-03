import "package:logger/logger.dart";

import "../base/base_error_msg.dart";
import "../constants/enums.dart";
import "../logging/yata_logger.dart";

/// Riverpod Provider専用ログユーティリティクラス
///
/// Providerクラス内でLoggerMixinが使用できない場合に、
/// 統一されたログ機能を提供するユーティリティクラス
/// 
/// YataLoggerの機能をProvider向けに最適化し、
/// 簡潔なAPIでログ出力を可能にする
/// 
/// 使用例:
/// ```dart
/// @riverpod
/// class AuthStateNotifier extends _$AuthStateNotifier {
///   @override
///   AuthState build() {
///     // エラー時のログ出力
///     ProviderLogger.error("AuthStateNotifier", "セッション復元に失敗", error);
///     return AuthState.initial();
///   }
/// }
/// ```
class ProviderLogger {
  ProviderLogger._(); // プライベートコンストラクタ（インスタンス化を防ぐ）

  // =================================================================
  // 基本ログ機能（logger パッケージ全レベル対応）
  // =================================================================

  /// トレースレベルログ（最も詳細なデバッグ情報）
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [message] ログメッセージ
  static void trace(String component, String message) {
    YataLogger.trace(component, message);
  }

  /// デバッグレベルログ（開発時のデバッグ情報）
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [message] ログメッセージ
  static void debug(String component, String message) {
    YataLogger.debug(component, message);
  }

  /// 情報レベルログ（通常の情報）
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [message] ログメッセージ
  static void info(String component, String message) {
    YataLogger.info(component, message);
  }

  /// 警告レベルログ（注意が必要な情報）
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [message] ログメッセージ
  static void warning(String component, String message) {
    YataLogger.warning(component, message);
  }

  /// エラーレベルログ（処理可能なエラー）
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [message] ログメッセージ
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  static void error(
    String component,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    YataLogger.error(component, message, error, stackTrace);
  }

  /// ファタルレベルログ（致命的なエラー）
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [message] ログメッセージ
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  static void fatal(
    String component,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    YataLogger.fatal(component, message, error, stackTrace);
  }

  // =================================================================
  // Provider専用便利メソッド
  // =================================================================

  /// Provider初期化時のログ
  /// 
  /// [component] プロバイダークラス名
  /// [message] 初期化メッセージ（オプション）
  static void initProvider(String component, [String? message]) {
    final String msg = message ?? "プロバイダーを初期化しました";
    info(component, msg);
  }

  /// Provider状態変更時のログ
  /// 
  /// [component] プロバイダークラス名
  /// [oldState] 変更前の状態
  /// [newState] 変更後の状態
  static void stateChanged(String component, dynamic oldState, dynamic newState) {
    debug(component, "状態変更: $oldState → $newState");
  }

  /// Provider非同期処理開始のログ
  /// 
  /// [component] プロバイダークラス名
  /// [operation] 実行する操作名
  static void asyncOperationStart(String component, String operation) {
    debug(component, "非同期処理開始: $operation");
  }

  /// Provider非同期処理完了のログ
  /// 
  /// [component] プロバイダークラス名
  /// [operation] 完了した操作名
  /// [duration] 処理時間（オプション）
  static void asyncOperationCompleted(
    String component,
    String operation, [
    Duration? duration,
  ]) {
    final String durationStr = duration != null ? " (${duration.inMilliseconds}ms)" : "";
    info(component, "非同期処理完了: $operation$durationStr");
  }

  /// Provider非同期処理失敗のログ
  /// 
  /// [component] プロバイダークラス名
  /// [operation] 失敗した操作名
  /// [error] エラーオブジェクト
  /// [stackTrace] スタックトレース（オプション）
  static void asyncOperationFailed(
    String component,
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    ProviderLogger.error(
      component,
      "非同期処理失敗: $operation - ${error.toString()}",
      error,
      stackTrace,
    );
  }

  // =================================================================
  // 認証関連専用メソッド（Phase 1で追加する特定用途）
  // =================================================================

  /// セッション復元失敗時のログ
  /// 
  /// [component] プロバイダークラス名
  /// [error] エラーオブジェクト
  /// [stackTrace] スタックトレース（オプション）
  static void sessionRestoreFailed(
    String component,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    ProviderLogger.error(
      component,
      "セッション復元に失敗しました: ${error.toString()}",
      error,
      stackTrace,
    );
  }

  /// システム初期化失敗時のログ
  /// 
  /// [component] プロバイダークラス名
  /// [initComponent] 失敗した初期化コンポーネント名
  /// [error] エラーオブジェクト
  /// [stackTrace] スタックトレース（オプション）
  static void systemInitializationFailed(
    String component,
    String initComponent,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    ProviderLogger.error(
      component,
      "システム初期化失敗 ($initComponent): ${error.toString()}",
      error,
      stackTrace,
    );
  }

  /// カート操作失敗時のログ
  /// 
  /// [component] プロバイダークラス名
  /// [operation] 失敗した操作名
  /// [error] エラーオブジェクト
  /// [stackTrace] スタックトレース（オプション）
  static void cartOperationFailed(
    String component,
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    ProviderLogger.error(
      component,
      "カート操作失敗 ($operation): ${error.toString()}",
      error,
      stackTrace,
    );
  }

  /// 認証失敗時のログ
  /// 
  /// [component] コンポーネント名（通常はScreen名）
  /// [authMethod] 認証方法（例: "Google OAuth"）
  /// [error] エラーオブジェクト
  /// [stackTrace] スタックトレース（オプション）
  static void authenticationFailed(
    String component,
    String authMethod,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    ProviderLogger.error(
      component,
      "認証失敗 ($authMethod): ${error.toString()}",
      error,
      stackTrace,
    );
  }

  // =================================================================
  // 事前定義メッセージ対応
  // =================================================================

  /// 情報レベルログ（事前定義メッセージ使用）
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  static void infoWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    YataLogger.infoWithMessage(component, logMessage, params);
  }

  /// 警告レベルログ（事前定義メッセージ使用）
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [logMessage] 事前定義されたLogMessage
  /// [params] 埋め込みするパラメータ
  static void warningWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    YataLogger.warningWithMessage(component, logMessage, params);
  }

  /// エラーレベルログ（事前定義メッセージ使用）
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
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
    YataLogger.errorWithMessage(component, logMessage, params, error, stackTrace);
  }

  // =================================================================
  // 高度機能
  // =================================================================

  /// 任意レベルでのログ出力
  /// 
  /// [level] ログレベル
  /// [component] プロバイダークラス名やコンポーネント名
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
    YataLogger.logWithLevel(level, component, message, error, stackTrace);
  }

  /// 複雑なオブジェクトのログ出力
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [message] ログメッセージ
  /// [object] ログ出力するオブジェクト
  static void logObject(String component, String message, Object object) {
    YataLogger.logObject(component, message, object);
  }

  /// 構造化ログ出力
  /// 
  /// [level] ログレベル
  /// [component] プロバイダークラス名やコンポーネント名
  /// [data] 構造化データ
  static void structured(LogLevel level, String component, Map<String, dynamic> data) {
    YataLogger.structured(level, component, data);
  }

  // =================================================================
  // パフォーマンス監視
  // =================================================================

  /// パフォーマンス計測開始
  /// 
  /// [component] プロバイダークラス名やコンポーネント名
  /// [operation] 計測する操作名
  /// 戻り値: 開始時刻
  static DateTime startPerformanceTimer(String component, String operation) =>
      YataLogger.startPerformanceTimer(component, operation);

  /// パフォーマンス計測終了・ログ出力
  /// 
  /// [startTime] 開始時刻
  /// [component] プロバイダークラス名やコンポーネント名
  /// [operation] 計測した操作名
  /// [thresholdMs] 閾値（ミリ秒）。この値を超えた場合のみログ出力
  static void endPerformanceTimer(
    DateTime startTime,
    String component,
    String operation, {
    int? thresholdMs,
  }) {
    YataLogger.endPerformanceTimer(startTime, component, operation, thresholdMs: thresholdMs);
  }

  /// パフォーマンス計測付きProvider操作実行
  /// 
  /// [component] プロバイダークラス名
  /// [operation] 操作名
  /// [method] 実行するメソッド
  /// [thresholdMs] パフォーマンス警告の閾値（ミリ秒）
  /// 戻り値: メソッドの実行結果
  static Future<T> withPerformanceTimer<T>(
    String component,
    String operation,
    Future<T> Function() method, {
    int? thresholdMs,
  }) async {
    final DateTime startTime = startPerformanceTimer(component, operation);
    try {
      final T result = await method();
      endPerformanceTimer(startTime, component, operation, thresholdMs: thresholdMs);
      return result;
    } catch (e, stackTrace) {
      endPerformanceTimer(startTime, component, "$operation (FAILED)", thresholdMs: thresholdMs);
      error(component, "計測中の処理で例外が発生", e, stackTrace);
      rethrow;
    }
  }

  // =================================================================
  // ビジネスメトリクス・監視
  // =================================================================

  /// クリティカルパス用ログ
  /// 
  /// [component] プロバイダークラス名
  /// [message] クリティカルなメッセージ
  static void critical(String component, String message) {
    YataLogger.critical(component, message);
  }

  /// ビジネスメトリクス記録
  /// 
  /// [component] プロバイダークラス名
  /// [metric] メトリクス名
  /// [data] メトリクスデータ
  static void businessMetric(String component, String metric, Map<String, dynamic> data) {
    YataLogger.businessMetric(component, metric, data);
  }

  /// ユーザーアクション記録
  /// 
  /// [component] プロバイダークラス名
  /// [action] アクション名
  /// [context] コンテキスト情報（オプション）
  static void userAction(String component, String action, {Map<String, String>? context}) {
    YataLogger.userAction(component, action, context: context);
  }

  /// システムヘルス監視
  /// 
  /// [component] プロバイダークラス名
  /// [healthMetric] ヘルスメトリクス名
  /// [value] メトリクス値
  /// [unit] 単位（オプション）
  static void systemHealth(String component, String healthMetric, dynamic value, {String? unit}) {
    YataLogger.systemHealth(component, healthMetric, value, unit: unit);
  }
}

/// Provider内でLoggerMixinのような機能を提供するインターフェースクラス
/// 
/// Riverpod Notifier等で直接Mixinが使用できない場合の代替手段
/// 使用例:
/// ```dart
/// @riverpod
/// class AuthStateNotifier extends _$AuthStateNotifier with ProviderLoggerMixin {
///   @override
///   String get providerComponent => "AuthStateNotifier";
///   
///   @override
///   AuthState build() {
///     logInfo("プロバイダーを初期化しました");
///     return AuthState.initial();
///   }
/// }
/// ```
mixin ProviderLoggerMixin {
  /// プロバイダーコンポーネント名（必須実装）
  String get providerComponent;

  /// トレースレベルログ
  void logTrace(String message) => ProviderLogger.trace(providerComponent, message);

  /// デバッグレベルログ
  void logDebug(String message) => ProviderLogger.debug(providerComponent, message);

  /// 情報レベルログ
  void logInfo(String message) => ProviderLogger.info(providerComponent, message);

  /// 警告レベルログ
  void logWarning(String message) => ProviderLogger.warning(providerComponent, message);

  /// エラーレベルログ
  void logError(String message, [Object? error, StackTrace? stackTrace]) =>
      ProviderLogger.error(providerComponent, message, error, stackTrace);

  /// ファタルレベルログ
  void logFatal(String message, [Object? error, StackTrace? stackTrace]) =>
      ProviderLogger.fatal(providerComponent, message, error, stackTrace);

  /// セッション復元失敗
  void logSessionRestoreFailed(Object error, [StackTrace? stackTrace]) =>
      ProviderLogger.sessionRestoreFailed(providerComponent, error, stackTrace);

  /// システム初期化失敗
  void logSystemInitializationFailed(String initComponent, Object error, [StackTrace? stackTrace]) =>
      ProviderLogger.systemInitializationFailed(providerComponent, initComponent, error, stackTrace);

  /// カート操作失敗
  void logCartOperationFailed(String operation, Object error, [StackTrace? stackTrace]) =>
      ProviderLogger.cartOperationFailed(providerComponent, operation, error, stackTrace);

  /// 認証失敗
  void logAuthenticationFailed(String authMethod, Object error, [StackTrace? stackTrace]) =>
      ProviderLogger.authenticationFailed(providerComponent, authMethod, error, stackTrace);

  /// 非同期処理開始
  void logAsyncOperationStart(String operation) =>
      ProviderLogger.asyncOperationStart(providerComponent, operation);

  /// 非同期処理完了
  void logAsyncOperationCompleted(String operation, [Duration? duration]) =>
      ProviderLogger.asyncOperationCompleted(providerComponent, operation, duration);

  /// 非同期処理失敗
  void logAsyncOperationFailed(String operation, Object error, [StackTrace? stackTrace]) =>
      ProviderLogger.asyncOperationFailed(providerComponent, operation, error, stackTrace);

  /// パフォーマンス計測付き実行
  Future<T> withPerformanceTimer<T>(
    String operation,
    Future<T> Function() method, {
    int? thresholdMs,
  }) =>
      ProviderLogger.withPerformanceTimer(providerComponent, operation, method, thresholdMs: thresholdMs);
}