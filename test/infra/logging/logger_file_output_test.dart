import "dart:io";

import "package:flutter_test/flutter_test.dart";

import "package:yata/infra/logging/log_config.dart";
import "package:yata/infra/logging/logger.dart";

void main() {
  group("Logger file output", () {
    late LogConfig original;

    setUp(() {
      original = config.copyWith();
    });

    tearDown(() {
      updateLoggerConfig((_) => original);
    });

    test("updates file sink when fileDirPath changes", () async {
      final Directory tmp = await Directory.systemTemp.createTemp("yata-logger-file-output");
      addTearDown(() async {
        if (await tmp.exists()) {
          await tmp.delete(recursive: true);
        }
      });

      updateLoggerConfig(
        (LogConfig c) => c.copyWith(
          fileDirPath: tmp.path,
          fileBaseName: "test-log",
          flushEveryLines: 1,
          flushEveryMs: 10,
          fileEnabled: true,
        ),
      );

      d("logger file output test", tag: "test");

      String? activePath;
      for (int i = 0; i < 50; i++) {
        final LoggerStats snapshot = stats;
        if (snapshot.queueLength == 0 && snapshot.activeLogFile != null) {
          activePath = snapshot.activeLogFile;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(activePath, isNotNull);

      final File logFile = File(activePath!);
      expect(await logFile.exists(), isTrue);

      final String contents = await logFile.readAsString();
      expect(contents, contains("logger file output test"));
    });
  });
}
