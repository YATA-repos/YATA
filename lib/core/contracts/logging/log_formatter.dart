import "logger.dart";

/// ログ整形器の契約
abstract class LogFormatterContract {
  String format(LogRecord record);
}
