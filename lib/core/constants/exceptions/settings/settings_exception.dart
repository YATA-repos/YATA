import "../base/yata_exception.dart";

/// 設定機能で発生する例外を表す。
class SettingsException extends YataException {
  /// 一般的な設定例外を生成する。
  const SettingsException(String message, {String? code, this.cause})
    : super(message, code: code);

  /// 根本原因となった例外。
  final Object? cause;

  /// バリデーションに失敗したときの例外。
  factory SettingsException.validation(String field, String reason) =>
      SettingsException(
        "Invalid value for '$field': $reason",
        code: "settings.validation",
      );

  /// 永続化や読み書き時のエラー。
  factory SettingsException.persistence(String operation, Object error) =>
      SettingsException(
        "Failed to $operation settings",
        code: "settings.persistence",
        cause: error,
      );

  /// ログへの適用に失敗したときの例外。
  factory SettingsException.apply(String operation, Object error) => SettingsException(
    "Failed to apply settings for $operation",
    code: "settings.apply",
    cause: error,
  );
}
