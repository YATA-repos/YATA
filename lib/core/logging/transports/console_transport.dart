import 'dart:io';

import '../levels.dart';

class ConsoleTransport {
  ConsoleTransport({this.enableColors})
      : enableColors = enableColors ?? stdout.supportsAnsiEscapes;

  final bool enableColors;

  void write(Level level, String line) {
    if (!enableColors) {
      stdout.write(line);
      return;
    }
    final color = _colorFor(level);
    stdout.write('$color$line\x1B[0m');
  }

  String _colorFor(Level lvl) {
    switch (lvl) {
      case Level.trace:
        return '\x1B[90m'; // gray
      case Level.debug:
        return '\x1B[36m'; // cyan
      case Level.info:
        return '\x1B[32m'; // green
      case Level.warn:
        return '\x1B[33m'; // yellow
      case Level.error:
        return '\x1B[31m'; // red
      case Level.fatal:
        return '\x1B[35m'; // magenta
    }
  }
}