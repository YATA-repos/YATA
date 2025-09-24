import "../../log_enums/log_enums.dart";
import "../base/base_context_exception.dart";
import "../base/exception_types.dart";

/// リポジトリ関連の例外クラス
///
/// データアクセス層で発生するエラーを管理します。
/// RepositoryErrorと連携して、型安全なエラーハンドリングを提供します。
class RepositoryException extends BaseContextException<RepositoryError> {
  /// RepositoryErrorを使用したコンストラクタ
  RepositoryException(super.error, {super.params, super.code});

  /// データ更新失敗例外の作成
  factory RepositoryException.updateFailed(String error, {String? id, String? table}) =>
      RepositoryException(
        RepositoryError.updateFailed,
        params: <String, String>{
          "error": error,
          if (id != null) "id": id,
          if (table != null) "table": table,
        },
      );

  /// データベース接続失敗例外の作成
  factory RepositoryException.databaseConnectionFailed(String error) => RepositoryException(
    RepositoryError.databaseConnectionFailed,
    params: <String, String>{"error": error},
  );

  /// レコード未発見例外の作成
  factory RepositoryException.recordNotFound(String id, {String? table}) => RepositoryException(
    RepositoryError.recordNotFound,
    params: <String, String>{"id": id, if (table != null) "table": table},
  );

  /// データ挿入失敗例外の作成
  factory RepositoryException.insertFailed(String error, {String? table}) => RepositoryException(
    RepositoryError.insertFailed,
    params: <String, String>{"error": error, if (table != null) "table": table},
  );

  /// データ削除失敗例外の作成
  factory RepositoryException.deleteFailed(String error, {String? id, String? table}) =>
      RepositoryException(
        RepositoryError.deleteFailed,
        params: <String, String>{
          "error": error,
          if (id != null) "id": id,
          if (table != null) "table": table,
        },
      );

  /// データ検証失敗例外の作成
  factory RepositoryException.validationFailed(String field, {String? value}) =>
      RepositoryException(
        RepositoryError.validationFailed,
        params: <String, String>{"field": field, if (value != null) "value": value},
      );

  /// 競合状態検出例外の作成
  factory RepositoryException.concurrencyConflict(String entity, {String? id}) =>
      RepositoryException(
        RepositoryError.concurrencyConflict,
        params: <String, String>{"entity": entity, if (id != null) "id": id},
      );

  /// 無効なクエリパラメータ例外の作成
  factory RepositoryException.invalidQueryParameters(String params) => RepositoryException(
    RepositoryError.invalidQueryParameters,
    params: <String, String>{"params": params},
  );

  /// トランザクション失敗例外の作成
  factory RepositoryException.transactionFailed(String error) => RepositoryException(
    RepositoryError.transactionFailed,
    params: <String, String>{"error": error},
  );

  /// 例外タイプ
  ExceptionType get type => ExceptionType.repository;

  /// エラーの重要度を取得
  ExceptionSeverity get severity {
    switch (error) {
      case RepositoryError.databaseConnectionFailed:
      case RepositoryError.transactionFailed:
        return ExceptionSeverity.critical;
      case RepositoryError.insertFailed:
      case RepositoryError.updateFailed:
      case RepositoryError.deleteFailed:
        return ExceptionSeverity.high;
      case RepositoryError.recordNotFound:
      case RepositoryError.concurrencyConflict:
        return ExceptionSeverity.medium;
      case RepositoryError.validationFailed:
      case RepositoryError.invalidQueryParameters:
        return ExceptionSeverity.low;
    }
  }

  /// ユーザーフレンドリーなエラーメッセージを取得
  String get userMessage => error.userMessage;

  /// エラーが一時的なものかどうかを判定
  bool get isTemporary => error.isTemporary;

  /// エラーハンドリング用のSnackBarメッセージを生成
  String getSnackBarMessage({bool includeRetryHint = true}) {
    final String baseMessage = userMessage;
    if (includeRetryHint && isTemporary) {
      return "$baseMessage\n（再試行可能）";
    }
    return baseMessage;
  }
}
