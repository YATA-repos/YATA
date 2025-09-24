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

  /// ユーザーフレンドリーな日本語エラーメッセージ
  String get userMessage {
    switch (this) {
      case RepositoryError.databaseConnectionFailed:
        return "データベースに接続できませんでした。ネットワーク接続を確認してください。";
      case RepositoryError.recordNotFound:
        return "指定されたデータが見つかりませんでした。";
      case RepositoryError.insertFailed:
        return "データの保存に失敗しました。もう一度お試しください。";
      case RepositoryError.updateFailed:
        return "データの更新に失敗しました。もう一度お試しください。";
      case RepositoryError.deleteFailed:
        return "データの削除に失敗しました。もう一度お試しください。";
      case RepositoryError.validationFailed:
        return "入力されたデータに問題があります。内容を確認してください。";
      case RepositoryError.concurrencyConflict:
        return "他のユーザーが同じデータを変更しています。画面を更新してやり直してください。";
      case RepositoryError.invalidQueryParameters:
        return "検索条件に問題があります。条件を見直してください。";
      case RepositoryError.transactionFailed:
        return "処理中にエラーが発生しました。もう一度お試しください。";
    }
  }

  /// エラーが一時的なものかどうかを判定
  bool get isTemporary {
    switch (this) {
      case RepositoryError.databaseConnectionFailed:
      case RepositoryError.transactionFailed:
        return true; // ネットワークやサーバーの問題は一時的
      case RepositoryError.concurrencyConflict:
        return true; // 競合は再試行で解決可能
      case RepositoryError.recordNotFound:
      case RepositoryError.insertFailed:
      case RepositoryError.updateFailed:
      case RepositoryError.deleteFailed:
      case RepositoryError.validationFailed:
      case RepositoryError.invalidQueryParameters:
        return false; // データや設定の問題は永続的
    }
  }
}
