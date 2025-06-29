import "base.dart";

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

  /// 英語エラーメッセージを取得
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

  /// 日本語エラーメッセージを取得
  @override
  String get messageJa {
    switch (this) {
      case RepositoryError.databaseConnectionFailed:
        return "データベース接続失敗: {error}";
      case RepositoryError.recordNotFound:
        return "レコードが見つかりません: {id}";
      case RepositoryError.insertFailed:
        return "データ挿入失敗: {error}";
      case RepositoryError.updateFailed:
        return "データ更新失敗: {error}";
      case RepositoryError.deleteFailed:
        return "データ削除失敗: {error}";
      case RepositoryError.validationFailed:
        return "データ検証失敗: {field}";
      case RepositoryError.concurrencyConflict:
        return "データ競合状態検出: {entity}";
      case RepositoryError.invalidQueryParameters:
        return "無効なクエリパラメータ: {params}";
      case RepositoryError.transactionFailed:
        return "データベーストランザクション失敗: {error}";
    }
  }

  /// 組み合わせメッセージ（英語 + 日本語）を取得
  @override
  String get combinedMessage => "$message ($messageJa)";
}

/// リポジトリ関連の例外
class RepositoryException implements Exception {
  /// コンストラクタ
  const RepositoryException(this.error, {this.params = const <String, String>{}});

  /// エラー種別
  final RepositoryError error;

  /// エラーメッセージのパラメータ
  final Map<String, String> params;

  /// エラーメッセージを取得
  String get message => error.withParams(params);

  @override
  String toString() => "RepositoryException: $message";
}
