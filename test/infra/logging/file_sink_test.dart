import "dart:io";

import "package:flutter_test/flutter_test.dart";

import "package:yata/infra/logging/log_config.dart";
import "package:yata/infra/logging/sinks.dart";

void main() {
  group("FileSink", () {
    late Directory tempDir;
    late LogConfig config;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp("yata_file_sink_test");
      config = LogConfig.defaults(
        fileDirPath: tempDir.path,
      ).copyWith(flushEveryLines: 1, flushEveryMs: 10);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test("writes without disabling when flush overlaps", () async {
      final FileSink sink = FileSink(config);

      await sink.add("first");
      final Future<void> firstFlush = sink.flush();
      await Future<void>.delayed(const Duration(milliseconds: 1));
      await sink.add("second");
      await firstFlush;
      await sink.flush();
      await sink.close();

      final List<File> logFiles = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith(".log"))
          .toList();
      expect(logFiles, isNotEmpty);
      logFiles.sort((File a, File b) => a.statSync().modified.compareTo(b.statSync().modified));
      final File latest = logFiles.last;
      final String contents = await latest.readAsString();
      expect(contents, contains("first"));
      expect(contents, contains("second"));
    });

    test("handles concurrent add calls without dropping logs", () async {
      final FileSink sink = FileSink(config);

      final List<Future<void>> writes = <Future<void>>[
        for (int i = 0; i < 5; i++) sink.add("line-$i"),
      ];

      await Future.wait(writes);
      await sink.flush();
      await sink.close();

      final List<File> logFiles = tempDir
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith(".log"))
          .toList();
      expect(logFiles, isNotEmpty);
      logFiles.sort((File a, File b) => a.statSync().modified.compareTo(b.statSync().modified));
      final File latest = logFiles.last;
      final List<String> lines = await latest.readAsLines();
      final Iterable<String> loggedLines = lines.where((String line) => line.contains("line-"));
      expect(loggedLines.length, 5);
    });
  });
}
