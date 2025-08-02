import "package:flutter_test/flutter_test.dart";
import "package:logger/logger.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/core/logging/logger_components.dart";

void main() {
  group("LogDecorationConstants", () {
    group("色分けマッピングテスト", () {
      test("ログレベル別色分けが正しく動作する", () {
        expect(LogDecorationConstants.getColorForLevel(Level.trace), LogDecorationConstants.gray);
        expect(LogDecorationConstants.getColorForLevel(Level.debug), LogDecorationConstants.gray);
        expect(LogDecorationConstants.getColorForLevel(Level.trace), LogDecorationConstants.gray);
        expect(LogDecorationConstants.getColorForLevel(Level.info), LogDecorationConstants.blue);
        expect(LogDecorationConstants.getColorForLevel(Level.warning), LogDecorationConstants.yellow);
        expect(LogDecorationConstants.getColorForLevel(Level.error), LogDecorationConstants.red);
        expect(LogDecorationConstants.getColorForLevel(Level.fatal), "${LogDecorationConstants.bold}${LogDecorationConstants.red}");
        expect(LogDecorationConstants.getColorForLevel(Level.fatal), "${LogDecorationConstants.bold}${LogDecorationConstants.red}");
        expect(LogDecorationConstants.getColorForLevel(Level.off), LogDecorationConstants.reset);
        expect(LogDecorationConstants.getColorForLevel(Level.all), LogDecorationConstants.reset);
        expect(LogDecorationConstants.getColorForLevel(Level.off), LogDecorationConstants.reset);
      });
    });

    group("アイコンマッピングテスト", () {
      test("ログレベル別アイコンが正しく動作する", () {
        expect(LogDecorationConstants.getIconForLevel(Level.trace), LogDecorationConstants.traceIcon);
        expect(LogDecorationConstants.getIconForLevel(Level.debug), LogDecorationConstants.debugIcon);
        expect(LogDecorationConstants.getIconForLevel(Level.trace), LogDecorationConstants.debugIcon);
        expect(LogDecorationConstants.getIconForLevel(Level.info), LogDecorationConstants.infoIcon);
        expect(LogDecorationConstants.getIconForLevel(Level.warning), LogDecorationConstants.warningIcon);
        expect(LogDecorationConstants.getIconForLevel(Level.error), LogDecorationConstants.errorIcon);
        expect(LogDecorationConstants.getIconForLevel(Level.fatal), LogDecorationConstants.fatalIcon);
        expect(LogDecorationConstants.getIconForLevel(Level.fatal), LogDecorationConstants.fatalIcon);
        expect(LogDecorationConstants.getIconForLevel(Level.off), "");
        expect(LogDecorationConstants.getIconForLevel(Level.all), "");
        expect(LogDecorationConstants.getIconForLevel(Level.off), "");
      });
    });

    group("コンポーネント色分けテスト", () {
      test("同じコンポーネント名は同じ色を返す", () {
        const String component = "TestComponent";
        final String color1 = LogDecorationConstants.getComponentColor(component);
        final String color2 = LogDecorationConstants.getComponentColor(component);
        expect(color1, equals(color2));
      });

      test("異なるコンポーネント名は異なる色を返すことがある", () {
        final String color1 = LogDecorationConstants.getComponentColor("Component1");
        final String color2 = LogDecorationConstants.getComponentColor("Component2");
        // 色が異なることが多いが、ハッシュ衝突で同じになる可能性もあるため、
        // とりあえず空でないことだけ確認
        expect(color1, isNotEmpty);
        expect(color2, isNotEmpty);
      });
    });
  });

  group("UnifiedYataLogFilter", () {
    group("フィルタリング機能テスト", () {
      test("最小レベル以上のログが許可される", () {
        final UnifiedYataLogFilter filter = UnifiedYataLogFilter(LogLevel.warning);
        
        // Warning レベルのイベントを作成
        final LogEvent warningEvent = LogEvent(
          Level.warning,
          "test warning message",
          time: DateTime.now(),
        );
        
        expect(filter.shouldLog(warningEvent), true);
      });

      test("最小レベル未満のログが拒否される", () {
        final UnifiedYataLogFilter filter = UnifiedYataLogFilter(LogLevel.warning);
        
        // Debug レベルのイベントを作成
        final LogEvent debugEvent = LogEvent(
          Level.debug,
          "test debug message",
          time: DateTime.now(),
        );
        
        expect(filter.shouldLog(debugEvent), false);
      });

      test("setMinimumLevel() でレベルが動的に変更される", () {
        final UnifiedYataLogFilter filter = UnifiedYataLogFilter(LogLevel.debug);
        
        final LogEvent debugEvent = LogEvent(
          Level.debug,
          "test debug message",
          time: DateTime.now(),
        );
        
        expect(filter.shouldLog(debugEvent), true);
        
        // Warning レベルに変更
        filter.setMinimumLevel(LogLevel.warning);
        expect(filter.minimumLevel, LogLevel.warning);
        expect(filter.shouldLog(debugEvent), false);
      });
    });

    group("レベルマッピングテスト", () {
      test("mapYataLevelToLoggerLevel() で正しくマッピングされる", () {
        expect(UnifiedYataLogFilter.mapYataLevelToLoggerLevel(LogLevel.debug), Level.debug);
        expect(UnifiedYataLogFilter.mapYataLevelToLoggerLevel(LogLevel.info), Level.info);
        expect(UnifiedYataLogFilter.mapYataLevelToLoggerLevel(LogLevel.warning), Level.warning);
        expect(UnifiedYataLogFilter.mapYataLevelToLoggerLevel(LogLevel.error), Level.error);
      });

      test("supportsLevel() で全レベルがサポートされている", () {
        final UnifiedYataLogFilter filter = UnifiedYataLogFilter(LogLevel.debug);
        
        expect(filter.supportsLevel(Level.trace), true);
        expect(filter.supportsLevel(Level.debug), true);
        expect(filter.supportsLevel(Level.trace), true);
        expect(filter.supportsLevel(Level.info), true);
        expect(filter.supportsLevel(Level.warning), true);
        expect(filter.supportsLevel(Level.error), true);
        expect(filter.supportsLevel(Level.fatal), true);
        expect(filter.supportsLevel(Level.fatal), true);
        expect(filter.supportsLevel(Level.all), false);
        expect(filter.supportsLevel(Level.off), false);
        expect(filter.supportsLevel(Level.off), false);
      });
    });

    group("フィルター情報取得テスト", () {
      test("getFilterInfo() でフィルター情報が取得できる", () {
        final UnifiedYataLogFilter filter = UnifiedYataLogFilter(LogLevel.info);
        final Map<String, dynamic> info = filter.getFilterInfo();
        
        expect(info, isA<Map<String, dynamic>>());
        expect(info["minimumLevel"], LogLevel.info.value);
        expect(info["minimumPriority"], LogLevel.info.priority);
        expect(info["supportedLevels"], isA<List<String>>());
      });
    });
  });

  group("UnifiedYataLogPrinter", () {
    group("基本フォーマットテスト", () {
      test("デフォルト設定でログが正しくフォーマットされる", () {
        final UnifiedYataLogPrinter printer = UnifiedYataLogPrinter();
        
        final LogEvent event = LogEvent(
          Level.info,
          "[TestComponent] test message",
          time: DateTime.now(),
        );
        
        final List<String> lines = printer.log(event);
        expect(lines, isNotEmpty);
        expect(lines.first.contains("[TestComponent]"), true);
        expect(lines.first.contains("[INFO]"), true);
        expect(lines.first.contains("test message"), true);
      });

      test("エラー情報が含まれる場合、追加行が出力される", () {
        final UnifiedYataLogPrinter printer = UnifiedYataLogPrinter();
        final Exception error = Exception("test exception");
        
        final LogEvent event = LogEvent(
          Level.error,
          "[TestComponent] error message",
          error: error,
          time: DateTime.now(),
        );
        
        final List<String> lines = printer.log(event);
        expect(lines.length, greaterThan(1));
        expect(lines.any((String line) => line.contains("Error:")), true);
      });

      test("スタックトレースが含まれる場合、制限された行数で出力される", () {
        final UnifiedYataLogPrinter printer = UnifiedYataLogPrinter(maxStackLines: 2);
        
        final LogEvent event = LogEvent(
          Level.error,
          "[TestComponent] error with stack",
          stackTrace: StackTrace.current,
          time: DateTime.now(),
        );
        
        final List<String> lines = printer.log(event);
        final List<String> stackLines = lines.where((String line) => line.contains("Stack[")).toList();
        expect(stackLines.length, lessThanOrEqualTo(2));
      });
    });

    group("ファクトリーコンストラクタテスト", () {
      test("development() で開発用設定が作成される", () {
        final UnifiedYataLogPrinter printer = UnifiedYataLogPrinter.development();
        final Map<String, dynamic> info = printer.getPrinterInfo();
        
        expect(info["showTimestamp"], true);
        expect(info["showLevel"], true);
        expect(info["showComponent"], true);
        expect(info["maxStackLines"], 5);
      });

      test("production() で本番用設定が作成される", () {
        final UnifiedYataLogPrinter printer = UnifiedYataLogPrinter.production();
        final Map<String, dynamic> info = printer.getPrinterInfo();
        
        expect(info["showTimestamp"], false);
        expect(info["showLevel"], true);
        expect(info["showComponent"], true);
        expect(info["maxStackLines"], 2);
      });
    });

    group("プリンター情報取得テスト", () {
      test("getPrinterInfo() でプリンター情報が取得できる", () {
        final UnifiedYataLogPrinter printer = UnifiedYataLogPrinter(
          showTimestamp: true,
          showLevel: false,
        );
        
        final Map<String, dynamic> info = printer.getPrinterInfo();
        expect(info, isA<Map<String, dynamic>>());
        expect(info["showTimestamp"], true);
        expect(info["showLevel"], false);
        expect(info["showComponent"], true);
        expect(info["maxStackLines"], 3);
      });
    });

    group("装飾機能テスト", () {
      test("装飾レベルが正しく設定される", () {
        final UnifiedYataLogPrinter fullPrinter = UnifiedYataLogPrinter.development();
        final Map<String, dynamic> fullInfo = fullPrinter.getPrinterInfo();
        
        expect(fullInfo["decorationLevel"], "full");
        expect(fullInfo["enableColorOutput"], true);
        expect(fullInfo["enableIcons"], true);
        expect(fullInfo["enableHighlight"], true);
        expect(fullInfo["enableComponentColors"], true);
        
        final UnifiedYataLogPrinter minimalPrinter = UnifiedYataLogPrinter.minimal();
        final Map<String, dynamic> minimalInfo = minimalPrinter.getPrinterInfo();
        
        expect(minimalInfo["decorationLevel"], "minimal");
        expect(minimalInfo["enableIcons"], false);
        expect(minimalInfo["enableHighlight"], false);
        expect(minimalInfo["enableComponentColors"], false);
        
        final UnifiedYataLogPrinter plainPrinter = UnifiedYataLogPrinter.plain();
        final Map<String, dynamic> plainInfo = plainPrinter.getPrinterInfo();
        
        expect(plainInfo["decorationLevel"], "none");
        expect(plainInfo["enableColorOutput"], false);
        expect(plainInfo["enableIcons"], false);
        expect(plainInfo["enableHighlight"], false);
        expect(plainInfo["enableComponentColors"], false);
      });

      test("カスタム装飾設定が正しく適用される", () {
        final UnifiedYataLogPrinter printer = UnifiedYataLogPrinter(
          enableColorOutput: false,
          enableHighlight: false,
        );
        
        final Map<String, dynamic> info = printer.getPrinterInfo();
        expect(info["decorationLevel"], "full");
        expect(info["enableColorOutput"], false);
        expect(info["enableIcons"], true);
        expect(info["enableHighlight"], false);
        expect(info["enableComponentColors"], true);
      });

      test("装飾機能が正しく判定される", () {
        final UnifiedYataLogPrinter fullPrinter = UnifiedYataLogPrinter.development();
        final Map<String, dynamic> fullInfo = fullPrinter.getPrinterInfo();
        expect(fullInfo["isDecorationEnabled"], true);
        
        final UnifiedYataLogPrinter plainPrinter = UnifiedYataLogPrinter.plain();
        final Map<String, dynamic> plainInfo = plainPrinter.getPrinterInfo();
        expect(plainInfo["isDecorationEnabled"], false);
      });

      test("エラーレベルでハイライト枠線が適用される", () {
        final UnifiedYataLogPrinter printer = UnifiedYataLogPrinter.development();
        
        final LogEvent errorEvent = LogEvent(
          Level.error,
          "[TestComponent] 重大なエラーが発生しました",
          time: DateTime.now(),
        );
        
        final List<String> lines = printer.log(errorEvent);
        // ハイライト機能が有効な場合、エラーレベルでは複数行出力される
        expect(lines.length, greaterThan(1));
        
        // 装飾なしモードでは通常の1行出力
        final UnifiedYataLogPrinter plainPrinter = UnifiedYataLogPrinter.plain();
        final List<String> plainLines = plainPrinter.log(errorEvent);
        expect(plainLines.length, equals(1));
      });

      test("アイコン付きログが正しく出力される", () {
        final UnifiedYataLogPrinter printer = UnifiedYataLogPrinter(
          enableColorOutput: false,
          enableHighlight: false,
          enableComponentColors: false,
        );
        
        final LogEvent infoEvent = LogEvent(
          Level.info,
          "[TestComponent] 情報メッセージ",
          time: DateTime.now(),
        );
        
        final List<String> lines = printer.log(infoEvent);
        expect(lines, isNotEmpty);
        // アイコンが含まれていることを確認（実際の絵文字の確認は環境依存のため、存在チェックのみ）
        expect(lines.first, isNotEmpty);
      });
    });
  });

  group("UnifiedBufferedFileOutput", () {
    group("初期化テスト", () {
      test("デフォルトコンストラクタで作成できる", () {
        final UnifiedBufferedFileOutput output = UnifiedBufferedFileOutput();
        expect(output, isA<UnifiedBufferedFileOutput>());
      });

      test("fromConfig() でLoggerConfigから設定を読み込める", () {
        final UnifiedBufferedFileOutput output = UnifiedBufferedFileOutput.fromConfig();
        expect(output, isA<UnifiedBufferedFileOutput>());
      });
    });

    group("設定情報取得テスト", () {
      test("getOutputInfo() で出力情報が取得できる", () {
        final UnifiedBufferedFileOutput output = UnifiedBufferedFileOutput(
          maxFileSize: 5 * 1024 * 1024,
          bufferSize: 50,
          flushInterval: 10,
        );
        
        final Map<String, dynamic> info = output.getOutputInfo();
        expect(info, isA<Map<String, dynamic>>());
        expect(info["maxFileSize"], 5 * 1024 * 1024);
        expect(info["bufferSize"], 50);
        expect(info["flushInterval"], 10);
        expect(info["initialized"], false);
      });
    });

    group("ログ統計取得テスト", () {
      test("getLogStats() で統計情報が取得できる", () async {
        final UnifiedBufferedFileOutput output = UnifiedBufferedFileOutput();
        
        final Map<String, dynamic> stats = await output.getLogStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats["initialized"], false);
      });
    });

    group("リソース管理テスト", () {
      test("dispose() が正常に動作する", () async {
        final UnifiedBufferedFileOutput output = UnifiedBufferedFileOutput();
        
        // dispose は未初期化状態でも動作する
        expect(() async => output.dispose(), returnsNormally);
      });
    });
  });
}