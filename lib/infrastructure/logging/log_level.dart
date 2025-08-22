/// Log levels in ascending order of severity.
enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error,
  fatal,
}

extension LogLevelX on LogLevel {
  String get name => switch (this) {
        LogLevel.trace => "trace",
        LogLevel.debug => "debug",
        LogLevel.info => "info",
        LogLevel.warn => "warn",
        LogLevel.error => "error",
        LogLevel.fatal => "fatal",
      };

  String get labelUpper => name.toUpperCase();
}
