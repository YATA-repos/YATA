import "dart:async";

import "logger.dart";

/// ログ出力先（コンソール、ファイル等）の契約
abstract class LogSinkContract {
  FutureOr<void> write(LogRecord record);
  FutureOr<void> flush();
  FutureOr<void> close();
}
