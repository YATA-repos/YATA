import "logger.dart";

/// ログ整形器の契約
abstract class LogFormatterContract {
  /// フォーマッタの識別名。
  String get name;

  String format(LogRecord record);
}
