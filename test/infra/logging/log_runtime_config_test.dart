import "dart:io";

import "package:test/test.dart";

import "package:yata/infra/logging/log_config.dart";
import "package:yata/infra/logging/log_level.dart";
import "package:yata/infra/logging/log_runtime_config.dart";
import "package:yata/infra/logging/logger.dart";

void main() {
  group("LogRuntimeConfigLoader", () {
    test("LOG_LEVEL=warn を正しく解析する", () {
      final List<String> warnings = <String>[];
      final LogRuntimeConfigLoader loader =
          LogRuntimeConfigLoader(warn: warnings.add);

      final LogRuntimeConfig config =
          loader.load(<String, String>{"LOG_LEVEL": "warn"});

      expect(config.level, equals(LogLevel.warn));
      expect(warnings, isEmpty);
    });

    test("不正な LOG_LEVEL は info にフォールバックする", () {
      final List<String> warnings = <String>[];
      final LogRuntimeConfigLoader loader =
          LogRuntimeConfigLoader(warn: warnings.add);

      final LogRuntimeConfig config =
          loader.load(<String, String>{"LOG_LEVEL": "loud"});

      expect(config.level, equals(LogLevel.info));
      expect(warnings.single, contains("LOG_LEVEL"));
    });

    test("LOG_LEVEL 未指定の場合はオーバーライドしない", () {
      final List<String> warnings = <String>[];
      final LogRuntimeConfigLoader loader =
          LogRuntimeConfigLoader(warn: warnings.add);

      final LogRuntimeConfig config = loader.load(<String, String>{});

      expect(config.level, isNull);
      expect(warnings, isEmpty);
    });

    test("LOG_DIR を正規化して返す", () async {
      final Directory tmp = await Directory.systemTemp.createTemp("yata-log-dir-test");
      addTearDown(() async {
        if (await tmp.exists()) {
          await tmp.delete(recursive: true);
        }
      });

      final LogRuntimeConfigLoader loader = LogRuntimeConfigLoader();
      final LogRuntimeConfig config = loader.load(<String, String>{
        "LOG_DIR": tmp.path,
      });

      expect(config.directory, equals(tmp.path));
    });
  });

  group("applyLogRuntimeConfig", () {
    late LogConfig original;

    setUp(() {
      original = config.copyWith();
    });

    tearDown(() {
      updateLoggerConfig((_) => original);
    });

    test("有効な環境変数で Logger 設定を更新する", () {
      final List<String> infoMessages = <String>[];
      final List<String> warnMessages = <String>[];

      applyLogRuntimeConfig(
        env: <String, String>{
          "LOG_LEVEL": "warn",
          "LOG_MAX_QUEUE": "2048",
          "LOG_FLUSH_INTERVAL_MS": "1500",
          "LOG_BACKPRESSURE": "drop-oldest",
        },
        warn: warnMessages.add,
        info: infoMessages.add,
      );

      expect(config.globalLevel, equals(LogLevel.warn));
      expect(config.queueCapacity, equals(2048));
      expect(config.flushEveryMs, equals(1500));
      expect(config.overflowPolicy, equals(OverflowPolicy.dropOld));
      expect(warnMessages, isEmpty);
      expect(infoMessages.single, contains("ロガー設定"));
    });

    test("不正値はフォールバックし警告を記録する", () {
      final List<String> warnMessages = <String>[];

      applyLogRuntimeConfig(
        env: <String, String>{
          "LOG_LEVEL": "LOUD",
          "LOG_MAX_QUEUE": "-1",
          "LOG_FLUSH_INTERVAL_MS": "zero",
          "LOG_BACKPRESSURE": "panic",
        },
        warn: warnMessages.add,
        info: (_) {},
      );

      expect(config.globalLevel, equals(LogLevel.info));
      expect(config.queueCapacity, equals(original.queueCapacity));
      expect(config.flushEveryMs, equals(original.flushEveryMs));
      expect(config.overflowPolicy, equals(OverflowPolicy.dropNew));
      expect(warnMessages.length, equals(4));
    });

    test("LOG_DIR を設定すると fileDirPath を更新する", () async {
      final Directory tmp = await Directory.systemTemp.createTemp("yata-log-dir-config");
      addTearDown(() async {
        if (await tmp.exists()) {
          await tmp.delete(recursive: true);
        }
      });

      applyLogRuntimeConfig(
        env: <String, String>{
          "LOG_DIR": tmp.path,
        },
        warn: (_) {},
        info: (_) {},
      );

      expect(config.fileDirPath, equals(tmp.path));
    });
  });
}
