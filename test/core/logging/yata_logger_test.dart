import "package:flutter_test/flutter_test.dart";
import "package:logger/logger.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/core/logging/yata_logger.dart";

void main() {
  group("YataLogger", () {
    setUp(() async {
      // 各テスト前にloggerを初期化
      if (!YataLogger.isInitialized) {
        await YataLogger.initialize(minimumLevel: LogLevel.debug);
      }
    });

    tearDown(() async {
      // 各テスト後にリソースをクリーンアップ
      await YataLogger.dispose();
    });

    group("初期化テスト", () {
      test("initialize() でloggerが初期化される", () async {
        await YataLogger.dispose(); // 一度リセット
        expect(YataLogger.isInitialized, false);
        
        await YataLogger.initialize();
        expect(YataLogger.isInitialized, true);
      });

      test("重複初期化は無視される", () async {
        expect(YataLogger.isInitialized, true);
        
        // 再度初期化してもエラーにならない
        await YataLogger.initialize();
        expect(YataLogger.isInitialized, true);
      });

      test("未初期化状態でloggerアクセスするとエラー", () async {
        await YataLogger.dispose();
        
        expect(() => YataLogger.logger, throwsStateError);
      });
    });

    group("基本ログ出力テスト", () {
      test("debug() でログが出力される", () {
        expect(() => YataLogger.debug("TestComponent", "debug message"), 
               returnsNormally);
      });

      test("info() でログが出力される", () {
        expect(() => YataLogger.info("TestComponent", "info message"), 
               returnsNormally);
      });

      test("warning() でログが出力される", () {
        expect(() => YataLogger.warning("TestComponent", "warning message"), 
               returnsNormally);
      });

      test("error() でログが出力される", () {
        expect(() => YataLogger.error("TestComponent", "error message"), 
               returnsNormally);
      });

      test("fatal() でログが出力される", () {
        expect(() => YataLogger.fatal("TestComponent", "fatal message"), 
               returnsNormally);
      });

      test("trace() でログが出力される", () {
        expect(() => YataLogger.trace("TestComponent", "trace message"), 
               returnsNormally);
      });
    });

    group("エラー情報付きログテスト", () {
      test("error() でエラーオブジェクトとスタックトレースが処理される", () {
        final Exception error = Exception("test exception");
        final StackTrace stackTrace = StackTrace.current;
        
        expect(() => YataLogger.error("TestComponent", "error with details", error, stackTrace), 
               returnsNormally);
      });

      test("fatal() でエラーオブジェクトが処理される", () {
        final Exception error = Exception("fatal exception");
        
        expect(() => YataLogger.fatal("TestComponent", "fatal error", error), 
               returnsNormally);
      });
    });

    group("レベル設定テスト", () {
      test("setMinimumLevel() でレベルが変更される", () {
        expect(() => YataLogger.setMinimumLevel(LogLevel.warning), 
               returnsNormally);
        
        expect(YataLogger.currentMinimumLevel, LogLevel.warning);
      });

      test("未初期化状態でsetMinimumLevel()を呼んでもエラーにならない", () async {
        await YataLogger.dispose();
        
        expect(() => YataLogger.setMinimumLevel(LogLevel.error), 
               returnsNormally);
      });
    });

    group("高度な機能テスト", () {
      test("logWithLevel() で任意レベルのログが出力される", () {
        expect(() => YataLogger.logWithLevel(Level.info, "TestComponent", "custom level"), 
               returnsNormally);
      });

      test("logObject() でオブジェクトログが出力される", () {
        final Map<String, Object> testObject = <String, Object>{"key": "value", "number": 42};
        
        expect(() => YataLogger.logObject("TestComponent", "test object", testObject), 
               returnsNormally);
      });

      test("structured() で構造化ログが出力される", () {
        final Map<String, String> data = <String, String>{"event": "test", "timestamp": DateTime.now().toString()};
        
        expect(() => YataLogger.structured(LogLevel.info, "TestComponent", data), 
               returnsNormally);
      });
    });

    group("設定・統計機能テスト", () {
      test("getConfig() で設定情報が取得できる", () {
        final Map<String, dynamic> config = YataLogger.getConfig();
        expect(config, isA<Map<String, dynamic>>());
        expect(config.containsKey("bufferSize"), true);
      });

      test("getPerformanceStats() で統計情報が取得できる", () {
        final Map<String, dynamic> stats = YataLogger.getPerformanceStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey("basic"), true);
        expect(stats.containsKey("performance"), true);
      });

      test("getHealthCheck() で健康状態が取得できる", () {
        final Map<String, dynamic> health = YataLogger.getHealthCheck();
        expect(health, isA<Map<String, dynamic>>());
        expect(health.containsKey("overallHealthy"), true);
      });

      test("getLogStats() でログ統計が取得できる", () async {
        final Map<String, dynamic> stats = await YataLogger.getLogStats();
        expect(stats, isA<Map<String, dynamic>>());
      });
    });

    group("下位互換性テスト", () {
      test("log系メソッドが動作する", () {
        expect(() => YataLogger.logDebug("TestComponent", "debug"), returnsNormally);
        expect(() => YataLogger.logInfo("TestComponent", "info"), returnsNormally);
        expect(() => YataLogger.logWarning("TestComponent", "warning"), returnsNormally);
        expect(() => YataLogger.logError("TestComponent", "error"), returnsNormally);
      });

      test("verbose() が動作する", () {
        expect(() => YataLogger.verbose("verbose message"), returnsNormally);
      });
    });

    group("クリーンアップ機能テスト", () {
      test("cleanupOldLogs() が正常に動作する", () async {
        expect(() async => YataLogger.cleanupOldLogs(daysToKeep: 7), 
               returnsNormally);
      });

      test("dispose() でリソースが解放される", () async {
        expect(YataLogger.isInitialized, true);
        
        await YataLogger.dispose();
        expect(YataLogger.isInitialized, false);
      });
    });
  });
}