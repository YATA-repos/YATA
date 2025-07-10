import "../../base/base_error_msg.dart";

/// リポジトリ関連のエラーメッセージ定義
enum RepositoryError implements LogMessage {
  /// データベース接続に失敗
  databaseConnectionFailed,

  /// レコードが見つからない
  recordNotFound,

  /// データの挿入に失敗
  insertFailed,

  /// データの更新に失敗
  updateFailed,

  /// データの削除に失敗
  deleteFailed,

  /// データの検証に失敗
  validationFailed,

  /// データの競合状態を検出
  concurrencyConflict,

  /// 無効なクエリパラメータ
  invalidQueryParameters,

  /// データベーストランザクションが失敗
  transactionFailed;

  @override
  String get message {
    switch (this) {
      case RepositoryError.databaseConnectionFailed:
        return "Database connection failed: {error}";
      case RepositoryError.recordNotFound:
        return "Record not found: {id}";
      case RepositoryError.insertFailed:
        return "Failed to insert data: {error}";
      case RepositoryError.updateFailed:
        return "Failed to update data: {error}";
      case RepositoryError.deleteFailed:
        return "Failed to delete data: {error}";
      case RepositoryError.validationFailed:
        return "Data validation failed: {field}";
      case RepositoryError.concurrencyConflict:
        return "Concurrency conflict detected: {entity}";
      case RepositoryError.invalidQueryParameters:
        return "Invalid query parameters: {params}";
      case RepositoryError.transactionFailed:
        return "Database transaction failed: {error}";
    }
  }
}

/// リポジトリ関連の例外
class RepositoryException implements Exception {
  const RepositoryException(this.error, {this.params = const <String, String>{}});

  /// エラー種別
  final RepositoryError error;

  /// エラーメッセージのパラメータ
  final Map<String, String> params;

  String get message => error.withParams(params);

  @override
  String toString() => "RepositoryException: $message";
}
