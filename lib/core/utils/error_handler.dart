import "package:flutter/material.dart";

import "../constants/app_constants.dart";
import "../constants/exceptions/exceptions.dart";
import "../logging/logger_binding.dart";

/// エラーハンドリングユーティリティクラス
///
/// アプリケーション全体で一貫したエラーハンドリングを提供します。
class ErrorHandler {
  ErrorHandler._();

  static final ErrorHandler _instance = ErrorHandler._();
  static ErrorHandler get instance => _instance;

  // String get loggerComponent => "ErrorHandler"; // deprecated

  /// エラーをハンドリングしてユーザーフレンドリーなメッセージを生成
  String handleError(dynamic error, {String? fallbackMessage}) {
    LoggerBinding.instance.e("Handling error", error: error);

    if (error is RepositoryException) {
      return error.userMessage;
    }

    if (error is BaseContextException) {
      // 他の例外タイプも将来的に対応
      return fallbackMessage ?? "処理中にエラーが発生しました。";
    }

    // 一般的なエラー
    return fallbackMessage ?? "予期しないエラーが発生しました。もう一度お試しください。";
  }

  /// SnackBarでエラーメッセージを表示
  void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    String? fallbackMessage,
    Duration? duration,
  }) {
    if (!context.mounted) {
      return;
    }

    final String message = handleError(error, fallbackMessage: fallbackMessage);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration ?? const Duration(seconds: AppConstants.defaultSnackBarDurationSeconds),
        action: SnackBarAction(
          label: "閉じる",
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// 再試行可能なエラーの場合、再試行ボタン付きSnackBarを表示
  void showRetryableErrorSnackBar(
    BuildContext context,
    dynamic error, {
    required VoidCallback onRetry,
    String? fallbackMessage,
  }) {
    if (!context.mounted) {
      return;
    }

    final String message = handleError(error, fallbackMessage: fallbackMessage);
    final bool isRetryable = error is RepositoryException && error.isTemporary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: AppConstants.retryableErrorSnackBarDurationSeconds),
        action: SnackBarAction(
          label: isRetryable ? "再試行" : "閉じる",
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: isRetryable
              ? onRetry
              : () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// エラーダイアログを表示
  Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    String? fallbackMessage,
    List<Widget>? actions,
  }) async {
    if (!context.mounted) {
      return;
    }

    final String message = handleError(error, fallbackMessage: fallbackMessage);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title ?? "エラー"),
        content: Text(message),
        actions:
            actions ??
            <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK")),
            ],
      ),
    );
  }

  /// サービス層用のエラーハンドリング
  /// ログ記録とエラー再スローを行う
  Never handleServiceError(String operation, dynamic error, [StackTrace? stackTrace]) {
    LoggerBinding.instance.e("Service error in $operation", error: error, st: stackTrace);

    if (error is BaseContextException) {
      throw error; // 既知の例外はそのまま再スロー
    }

    // 未知のエラーは汎用的なサービス例外として包む
    throw ServiceException(
      ServiceError.operationFailed,
      params: <String, String>{"operation": operation, "error": error.toString()},
    );
  }
}
