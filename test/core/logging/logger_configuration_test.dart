import "package:flutter_test/flutter_test.dart";

import "package:yata/core/logging/logger_configuration.dart";

void main() {
  group("LoggerConfig", () {
    setUp(() {
      // 各テスト前に設定をリセット
      LoggerConfig.setBufferSize(100);
      LoggerConfig.setFlushInterval(5);
      LoggerConfig.setMaxFileSize(10);
      LoggerConfig.setMaxRetryAttempts(3);
      LoggerConfig.setDefaultCleanupDays(30);
    });

    group("デフォルト設定テスト", () {
      test("デフォルト値が正しく設定されている", () {
        expect(LoggerConfig.bufferSize, 100);
        expect(LoggerConfig.flushIntervalSeconds, 5);
        expect(LoggerConfig.maxFileSizeMB, 10);
        expect(LoggerConfig.maxRetryAttempts, 3);
        expect(LoggerConfig.defaultCleanupDays, 30);
      });

      test("maxFileSizeBytesが正しく計算されている", () {
        expect(LoggerConfig.maxFileSizeBytes, 10 * 1024 * 1024);
      });
    });

    group("設定変更テスト", () {
      test("setBufferSize() で有効な値が設定される", () {
        LoggerConfig.setBufferSize(200);
        expect(LoggerConfig.bufferSize, 200);
      });

      test("setBufferSize() で無効な値は無視される", () {
        LoggerConfig.setBufferSize(0); // 無効
        expect(LoggerConfig.bufferSize, 100); // 変更されない
        
        LoggerConfig.setBufferSize(1001); // 無効（上限超過）
        expect(LoggerConfig.bufferSize, 100); // 変更されない
      });

      test("setFlushInterval() で有効な値が設定される", () {
        LoggerConfig.setFlushInterval(10);
        expect(LoggerConfig.flushIntervalSeconds, 10);
      });

      test("setFlushInterval() で無効な値は無視される", () {
        LoggerConfig.setFlushInterval(0); // 無効
        expect(LoggerConfig.flushIntervalSeconds, 5); // 変更されない
        
        LoggerConfig.setFlushInterval(61); // 無効（上限超過）
        expect(LoggerConfig.flushIntervalSeconds, 5); // 変更されない
      });

      test("setMaxFileSize() で有効な値が設定される", () {
        LoggerConfig.setMaxFileSize(20);
        expect(LoggerConfig.maxFileSizeMB, 20);
        expect(LoggerConfig.maxFileSizeBytes, 20 * 1024 * 1024);
      });

      test("setMaxFileSize() で無効な値は無視される", () {
        LoggerConfig.setMaxFileSize(0); // 無効
        expect(LoggerConfig.maxFileSizeMB, 10); // 変更されない
        
        LoggerConfig.setMaxFileSize(101); // 無効（上限超過）
        expect(LoggerConfig.maxFileSizeMB, 10); // 変更されない
      });

      test("setMaxRetryAttempts() で有効な値が設定される", () {
        LoggerConfig.setMaxRetryAttempts(5);
        expect(LoggerConfig.maxRetryAttempts, 5);
      });

      test("setMaxRetryAttempts() で無効な値は無視される", () {
        LoggerConfig.setMaxRetryAttempts(0); // 無効
        expect(LoggerConfig.maxRetryAttempts, 3); // 変更されない
        
        LoggerConfig.setMaxRetryAttempts(11); // 無効（上限超過）
        expect(LoggerConfig.maxRetryAttempts, 3); // 変更されない
      });

      test("setDefaultCleanupDays() で有効な値が設定される", () {
        LoggerConfig.setDefaultCleanupDays(60);
        expect(LoggerConfig.defaultCleanupDays, 60);
      });

      test("setDefaultCleanupDays() で無効な値は無視される", () {
        LoggerConfig.setDefaultCleanupDays(0); // 無効
        expect(LoggerConfig.defaultCleanupDays, 30); // 変更されない
        
        LoggerConfig.setDefaultCleanupDays(366); // 無効（上限超過）
        expect(LoggerConfig.defaultCleanupDays, 30); // 変更されない
      });
    });

    group("設定出力テスト", () {
      test("toMap() で設定情報が取得できる", () {
        final Map<String, dynamic> config = LoggerConfig.toMap();
        
        expect(config, isA<Map<String, dynamic>>());
        expect(config["bufferSize"], 100);
        expect(config["flushIntervalSeconds"], 5);
        expect(config["maxFileSizeMB"], 10);
        expect(config["maxRetryAttempts"], 3);
        expect(config["defaultCleanupDays"], 30);
        expect(config["maxFileSizeBytes"], 10 * 1024 * 1024);
      });

      test("toDebugString() でデバッグ文字列が取得できる", () {
        final String debugString = LoggerConfig.toDebugString();
        
        expect(debugString, isA<String>());
        expect(debugString.contains("LoggerConfig:"), true);
        expect(debugString.contains("bufferSize: 100"), true);
        expect(debugString.contains("flushIntervalSeconds: 5"), true);
      });
    });
  });

  group("LoggerPerformanceStats", () {
    setUp(LoggerPerformanceStats.reset);

    group("統計更新テスト", () {
      test("incrementLogsProcessed() でログ処理数が増加する", () {
        final Map<String, dynamic> before = LoggerPerformanceStats.getBasicStats();
        expect(before["totalLogsProcessed"], 0);
        
        LoggerPerformanceStats.incrementLogsProcessed();
        
        final Map<String, dynamic> after = LoggerPerformanceStats.getBasicStats();
        expect(after["totalLogsProcessed"], 1);
      });

      test("markFlushComplete() でフラッシュ統計が更新される", () {
        final DateTime startTime = LoggerPerformanceStats.markFlushStart();
        
        // 短い待機時間をシミュレート
        
        LoggerPerformanceStats.markFlushComplete(startTime);
        
        final Map<String, dynamic> stats = LoggerPerformanceStats.getBasicStats();
        expect(stats["totalFlushOperations"], 1);
        expect(stats["totalFailedFlushes"], 0);
      });

      test("markFlushComplete() で失敗フラッシュが記録される", () {
        final DateTime startTime = LoggerPerformanceStats.markFlushStart();
        
        LoggerPerformanceStats.markFlushComplete(startTime, success: false);
        
        final Map<String, dynamic> stats = LoggerPerformanceStats.getBasicStats();
        expect(stats["totalFailedFlushes"], 1);
      });

      test("incrementRetryAttempts() でリトライ回数が増加する", () {
        LoggerPerformanceStats.incrementRetryAttempts();
        
        final Map<String, dynamic> stats = LoggerPerformanceStats.getBasicStats();
        expect(stats["totalRetryAttempts"], 1);
      });

      test("markInitialization() で初期化時刻が記録される", () {
        LoggerPerformanceStats.markInitialization();
        
        final Map<String, dynamic> stats = LoggerPerformanceStats.getBasicStats();
        expect(stats["initializationTime"], isNotNull);
      });
    });

    group("統計取得テスト", () {
      test("getBasicStats() で基本統計が取得できる", () {
        final Map<String, dynamic> stats = LoggerPerformanceStats.getBasicStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey("totalLogsProcessed"), true);
        expect(stats.containsKey("totalFlushOperations"), true);
        expect(stats.containsKey("totalFailedFlushes"), true);
        expect(stats.containsKey("totalRetryAttempts"), true);
      });

      test("getPerformanceStats() でパフォーマンス統計が取得できる", () {
        final Map<String, dynamic> stats = LoggerPerformanceStats.getPerformanceStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey("averageFlushTimeMs"), true);
        expect(stats.containsKey("failureRatePercent"), true);
        expect(stats.containsKey("retryRatePercent"), true);
      });

      test("getAllStats() で全統計が取得できる", () {
        final Map<String, dynamic> stats = LoggerPerformanceStats.getAllStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey("basic"), true);
        expect(stats.containsKey("performance"), true);
        expect(stats.containsKey("timestamp"), true);
      });

      test("getHealthCheck() で健康状態が取得できる", () {
        final Map<String, dynamic> health = LoggerPerformanceStats.getHealthCheck();
        
        expect(health, isA<Map<String, dynamic>>());
        expect(health.containsKey("flushHealthy"), true);
        expect(health.containsKey("performanceHealthy"), true);
        expect(health.containsKey("overallHealthy"), true);
      });
    });

    group("統計リセットテスト", () {
      test("reset() で全統計がリセットされる", () {
        // 統計を蓄積
        LoggerPerformanceStats.incrementLogsProcessed();
        LoggerPerformanceStats.incrementRetryAttempts();
        LoggerPerformanceStats.markInitialization();
        
        final Map<String, dynamic> beforeReset = LoggerPerformanceStats.getBasicStats();
        expect(beforeReset["totalLogsProcessed"], 1);
        
        // リセット
        LoggerPerformanceStats.reset();
        
        final Map<String, dynamic> afterReset = LoggerPerformanceStats.getBasicStats();
        expect(afterReset["totalLogsProcessed"], 0);
        expect(afterReset["totalRetryAttempts"], 0);
        expect(afterReset["initializationTime"], null);
      });
    });

    group("デバッグ出力テスト", () {
      test("toDebugString() でデバッグ文字列が取得できる", () {
        LoggerPerformanceStats.incrementLogsProcessed();
        
        final String debugString = LoggerPerformanceStats.toDebugString();
        
        expect(debugString, isA<String>());
        expect(debugString.contains("LoggerPerformanceStats:"), true);
        expect(debugString.contains("Basic Stats"), true);
        expect(debugString.contains("Performance Stats"), true);
        expect(debugString.contains("Health Check"), true);
      });
    });
  });
}