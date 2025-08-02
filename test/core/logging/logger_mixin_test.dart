import "package:flutter_test/flutter_test.dart";
import "package:logger/logger.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/core/logging/logger_mixin.dart";
import "package:yata/core/logging/yata_logger.dart";

/// テスト用のクラス（LoggerMixinを使用）
class TestService with LoggerMixin {
  void performAction() {
    logInfo("Action performed");
  }
  
  void performActionWithError() {
    try {
      throw Exception("Test exception");
    } catch (e, stackTrace) {
      logError("Action failed", e, stackTrace);
    }
  }
  
  void performDebugAction() {
    logDebug("Debug action");
  }
  
  void performWarningAction() {
    logWarning("Warning action");
  }
  
  void performTraceAction() {
    logTrace("Trace action");
  }
  
  void performFatalAction() {
    logFatal("Fatal action");
  }
}

void main() {
  group("LoggerMixin", () {
    late TestService testService;

    setUp(() async {
      testService = TestService();
      
      // YataLoggerを初期化
      if (!YataLogger.isInitialized) {
        await YataLogger.initialize(minimumLevel: LogLevel.debug);
      }
    });

    tearDown(() async {
      await YataLogger.dispose();
    });

    group("基本機能テスト", () {
      test("loggerComponent がクラス名を返す", () {
        expect(testService.loggerComponent, "TestService");
      });

      test("logger プロパティがLoggerインスタンスを返す", () {
        expect(testService.logger, isA<Logger>());
      });
    });

    group("基本ログ出力テスト", () {
      test("logInfo() でログが出力される", () {
        expect(() => testService.performAction(), returnsNormally);
      });

      test("logDebug() でログが出力される", () {
        expect(() => testService.performDebugAction(), returnsNormally);
      });

      test("logWarning() でログが出力される", () {
        expect(() => testService.performWarningAction(), returnsNormally);
      });

      test("logError() でエラーログが出力される", () {
        expect(() => testService.performActionWithError(), returnsNormally);
      });

      test("logTrace() でトレースログが出力される", () {
        expect(() => testService.performTraceAction(), returnsNormally);
      });

      test("logFatal() でファタルログが出力される", () {
        expect(() => testService.performFatalAction(), returnsNormally);
      });
    });

    group("事前定義メッセージテスト", () {
      test("logInfoMessage() で事前定義メッセージログが出力される", () {
        // 実際のLogMessageインスタンスを使用する場合はここで作成
        // この例では簡単なテストとして、メソッドが存在することを確認
        expect(testService.logInfoMessage, isA<Function>());
      });

      test("logWarningMessage() で事前定義メッセージログが出力される", () {
        expect(testService.logWarningMessage, isA<Function>());
      });

      test("logErrorMessage() で事前定義メッセージログが出力される", () {
        expect(testService.logErrorMessage, isA<Function>());
      });
    });

    group("高度な機能テスト", () {
      test("logWithLevel() で任意レベルのログが出力される", () {
        expect(() => testService.logWithLevel(Level.info, "custom level message"), 
               returnsNormally);
      });

      test("logObject() でオブジェクトログが出力される", () {
        final Map<String, String> testObject = <String, String>{"test": "value"};
        expect(() => testService.logObject("Test object", testObject), 
               returnsNormally);
      });

      test("logStructured() で構造化ログが出力される", () {
        final Map<String, String> data = <String, String>{"action": "test", "result": "success"};
        expect(() => testService.logStructured(LogLevel.info, data), 
               returnsNormally);
      });

      test("logVerbose() でverboseログが出力される", () {
        expect(() => testService.logVerbose("verbose message"), 
               returnsNormally);
      });
    });

    group("logger直接アクセステスト", () {
      test("withLogger() でLoggerインスタンスに直接アクセスできる", () {
        expect(() => testService.withLogger((Logger logger) {
          logger.d("Direct logger access test");
        }), returnsNormally);
      });

      test("withLogger() でエラーが発生してもハンドリングされる", () {
        expect(() => testService.withLogger((Logger logger) {
          throw Exception("Test exception in callback");
        }), returnsNormally);
      });

      test("logMap() でMapログが出力される", () {
        final Map<String, Object> data = <String, Object>{"key1": "value1", "key2": 42};
        expect(() => testService.logMap(Level.info, data), 
               returnsNormally);
      });

      test("logList() でリストログが出力される", () {
        final List<String> items = <String>["item1", "item2", "item3"];
        expect(() => testService.logList(Level.info, "Test list", items), 
               returnsNormally);
      });
    });

    group("下位互換性テスト", () {
      test("logWithComponent() で互換ログが出力される", () {
        expect(() => testService.logWithComponent("CustomComponent", "custom message"), 
               returnsNormally);
      });
    });

    group("複数インスタンステスト", () {
      test("複数のインスタンスが独立してログ出力できる", () {
        final TestService service1 = TestService();
        final TestService service2 = TestService();
        
        expect(() {
          service1.logInfo("Message from service1");
          service2.logInfo("Message from service2");
        }, returnsNormally);
        
        expect(service1.loggerComponent, "TestService");
        expect(service2.loggerComponent, "TestService");
      });
    });
  });
}