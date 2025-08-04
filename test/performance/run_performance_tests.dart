import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:yata/core/utils/provider_logger.dart";

import "helpers/performance_baseline.dart";
import "helpers/performance_test_helper.dart";

/// パフォーマンステスト実行スクリプト
/// 
/// CI/CD環境での自動実行、レポート生成、
/// 回帰検出アラート機能を提供する
class PerformanceTestRunner {

  PerformanceTestRunner({
    PerformanceTestConfig? config,
  }) : config = config ?? const PerformanceTestConfig();
  static const String _component = "PerformanceTestRunner";

  /// パフォーマンステスト実行設定
  final PerformanceTestConfig config;

  /// 実行結果の格納
  final List<PerformanceTestResult> _results = <PerformanceTestResult>[];
  final List<RegressionDetectionResult> _regressions = <RegressionDetectionResult>[];

  // =================================================================
  // メインテスト実行メソッド
  // =================================================================

  /// 全パフォーマンステストを実行
  /// 
  /// [testSuites] 実行するテストスイート名のリスト
  /// 戻り値: テスト実行結果サマリー
  Future<PerformanceTestSummary> runAllTests({
    List<String>? testSuites,
  }) async {
    ProviderLogger.info(_component, "🚀 パフォーマンステスト実行開始");
    
    final DateTime startTime = DateTime.now();
    
    try {
      // デフォルトのテストスイートを使用
      final List<String> suitesToRun = testSuites ?? <String>[
        "provider_performance",
        "ui_performance",
        "memory_leak",
        "integration_performance",
      ];

      // 各テストスイートを実行
      for (final String suite in suitesToRun) {
        ProviderLogger.info(_component, "📋 テストスイート実行: $suite");
        await _runTestSuite(suite);
      }

      // 結果分析と回帰検出
      await _analyzeResults();

      // レポート生成
      final PerformanceTestSummary summary = await _generateSummary(startTime);

      // 結果出力
      await _outputResults(summary);

      ProviderLogger.info(_component, "✅ パフォーマンステスト実行完了");
      return summary;

    } catch (e, stackTrace) {
      ProviderLogger.error(_component, "パフォーマンステスト実行中にエラーが発生", e, stackTrace);
      
      return PerformanceTestSummary(
        totalTests: 0,
        passedTests: 0,
        failedTests: 1,
        regressionCount: 0,
        executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        results: <PerformanceTestResult>[],
        regressions: <RegressionDetectionResult>[],
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 個別テストスイート実行
  Future<void> _runTestSuite(String suiteName) async {
    switch (suiteName) {
      case "provider_performance":
        await _runProviderPerformanceTests();
        break;
      case "ui_performance":
        await _runUIPerformanceTests();
        break;
      case "memory_leak":
        await _runMemoryLeakTests();
        break;
      case "integration_performance":
        await _runIntegrationPerformanceTests();
        break;
      default:
        ProviderLogger.warning(_component, "未知のテストスイート: $suiteName");
    }
  }

  // =================================================================
  // 個別テストスイート実装
  // =================================================================

  /// プロバイダーパフォーマンステスト実行
  Future<void> _runProviderPerformanceTests() async {
    ProviderLogger.info(_component, "🔧 プロバイダーパフォーマンステスト実行");

    // 認証プロバイダーテスト
    final PerformanceTestResult authResult = await PerformanceTestHelper.measurePerformance(
      "auth_provider_benchmark",
      () async {
        // 認証プロバイダーのベンチマーク実行
        final Future<void> delay1 = Future.delayed(const Duration(milliseconds: 50)); // シミュレート
        await delay1;
      },
      expectedMaxDuration: PerformanceTestHelper.providerInitWarningThreshold,
      memoryThreshold: 1.0,
    );
    _results.add(authResult);

    // 在庫管理プロバイダーテスト
    final PerformanceTestResult inventoryResult = await PerformanceTestHelper.measurePerformance(
      "inventory_provider_benchmark",
      () async {
        final Future<void> delay2 = Future.delayed(const Duration(milliseconds: 75)); // シミュレート
        await delay2;
      },
      expectedMaxDuration: PerformanceTestHelper.providerInitWarningThreshold,
      memoryThreshold: 2.0,
    );
    _results.add(inventoryResult);

    // 注文管理プロバイダーテスト
    final PerformanceTestResult orderResult = await PerformanceTestHelper.measurePerformance(
      "order_provider_benchmark",
      () async {
        final Future<void> delay3 = Future.delayed(const Duration(milliseconds: 60)); // シミュレート
        await delay3;
      },
      expectedMaxDuration: PerformanceTestHelper.providerInitWarningThreshold,
      memoryThreshold: 1.5,
    );
    _results.add(orderResult);

    ProviderLogger.info(_component, "✅ プロバイダーパフォーマンステスト完了");
  }

  /// UI描画パフォーマンステスト実行
  Future<void> _runUIPerformanceTests() async {
    ProviderLogger.info(_component, "🎨 UI描画パフォーマンステスト実行");

    // UI描画ベンチマーク
    final PerformanceTestResult uiResult = await PerformanceTestHelper.measurePerformance(
      "ui_rendering_benchmark",
      () async {
        // UI描画処理のシミュレート
        for (int i = 0; i < 10; i++) {
          final Future<void> delay4 = Future.delayed(const Duration(milliseconds: 16)); // 60FPS想定
          await delay4;
        }
      },
      expectedMaxDuration: PerformanceTestHelper.uiRenderCriticalThreshold * 10,
      memoryThreshold: 0.5,
    );
    _results.add(uiResult);

    ProviderLogger.info(_component, "✅ UI描画パフォーマンステスト完了");
  }

  /// メモリリークテスト実行
  Future<void> _runMemoryLeakTests() async {
    ProviderLogger.info(_component, "💧 メモリリークテスト実行");

    // メモリリークテスト
    final MemoryLeakTestResult memoryResult = await PerformanceTestHelper.testMemoryLeak(
      "general_memory_leak_test",
      () async {
        // メモリを使用する処理のシミュレート
        final List<String> memoryConsumer = List.generate(1000, (int i) => "データ$i");
        final Future<void> delay5 = Future.delayed(const Duration(milliseconds: 10));
        await delay5;
        memoryConsumer.clear(); // 明示的にクリア
      },
      () async {
        // クリーンアップ処理
        final Future<void> delay6 = Future.delayed(const Duration(milliseconds: 5));
        await delay6;
      },
      maxMemoryLeakMB: 1.0,
    );

    // メモリリーク結果をパフォーマンス結果として記録
    _results.add(PerformanceTestResult(
      testName: memoryResult.testName,
      executionTimeMs: 0, // メモリリークテストでは実行時間は関係なし
      memoryUsageMB: memoryResult.memoryLeakMB,
      initialMemoryMB: memoryResult.initialMemoryMB,
      finalMemoryMB: memoryResult.finalMemoryMB,
      success: memoryResult.passed,
      timestamp: memoryResult.timestamp,
    ));

    ProviderLogger.info(_component, "✅ メモリリークテスト完了");
  }

  /// 統合パフォーマンステスト実行
  Future<void> _runIntegrationPerformanceTests() async {
    ProviderLogger.info(_component, "🔗 統合パフォーマンステスト実行");

    // アプリ全体の初期化パフォーマンス
    final PerformanceTestResult integrationResult = await PerformanceTestHelper.measurePerformance(
      "app_initialization_benchmark",
      () async {
        // アプリ初期化処理のシミュレート
        final Future<void> delay7 = Future.delayed(const Duration(milliseconds: 200));
        await delay7;
      },
      expectedMaxDuration: 1000, // 1秒以内
      memoryThreshold: 10.0, // 10MB以内
    );
    _results.add(integrationResult);

    ProviderLogger.info(_component, "✅ 統合パフォーマンステスト完了");
  }

  // =================================================================
  // 結果分析とレポート生成
  // =================================================================

  /// テスト結果の分析と回帰検出
  Future<void> _analyzeResults() async {
    ProviderLogger.info(_component, "📊 テスト結果分析開始");

    for (final PerformanceTestResult result in _results) {
      // 回帰検出
      final RegressionDetectionResult regression = await PerformanceBaseline.detectRegression(
        result.testName,
        result,
        regressionThreshold: config.regressionThresholdPercent,
      );

      if (regression.hasRegression) {
        _regressions.add(regression);
      }

      // ベースライン更新（成功したテストのみ）
      if (result.success && !regression.hasRegression && config.updateBaseline) {
        await PerformanceBaseline.updateBaseline(result.testName, result);
      }
    }

    ProviderLogger.info(_component, "📊 テスト結果分析完了");
  }

  /// テスト結果サマリー生成
  Future<PerformanceTestSummary> _generateSummary(DateTime startTime) async {
    final int totalTests = _results.length;
    final int passedTests = _results.where((PerformanceTestResult r) => r.success).length;
    final int failedTests = totalTests - passedTests;
    final int regressionCount = _regressions.length;
    final int executionTimeMs = DateTime.now().difference(startTime).inMilliseconds;

    return PerformanceTestSummary(
      totalTests: totalTests,
      passedTests: passedTests,
      failedTests: failedTests,
      regressionCount: regressionCount,
      executionTimeMs: executionTimeMs,
      results: List.from(_results),
      regressions: List.from(_regressions),
      success: failedTests == 0 && regressionCount == 0,
    );
  }

  /// テスト結果の出力
  Future<void> _outputResults(PerformanceTestSummary summary) async {
    // JSON形式で結果保存
    await PerformanceBaseline.saveTestResults(_results);

    // コンソール出力
    _printSummaryToConsole(summary);

    // CI/CD用のJUnit形式レポート出力
    if (config.generateJUnitReport) {
      await _generateJUnitReport(summary);
    }

    // 詳細JSON レポート出力
    if (config.generateDetailedReport) {
      await _generateDetailedJsonReport(summary);
    }
  }

  /// コンソールへのサマリー出力
  void _printSummaryToConsole(PerformanceTestSummary summary) {
    print('\n${'=' * 60}');
    print("🎯 パフォーマンステスト結果サマリー");
    print("=" * 60);
    print("総テスト数: ${summary.totalTests}");
    print("成功: ${summary.passedTests}");
    print("失敗: ${summary.failedTests}");
    print("回帰検出: ${summary.regressionCount}");
    print("実行時間: ${summary.executionTimeMs}ms");
    print('テスト結果: ${summary.success ? "✅ 成功" : "❌ 失敗"}');
    
    if (summary.regressionCount > 0) {
      print("\n🚨 検出された回帰:");
      for (final RegressionDetectionResult regression in summary.regressions) {
        print("  - ${regression.testName}: ${regression.reason}");
        print("    実行時間: ${regression.executionTimeRegressionPercent.toStringAsFixed(1)}%");
        print("    メモリ: ${regression.memoryRegressionPercent.toStringAsFixed(1)}%");
      }
    }
    
    print("=" * 60);
  }

  /// JUnit形式レポート生成
  Future<void> _generateJUnitReport(PerformanceTestSummary summary) async {
    final StringBuffer xml = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<testsuite name="PerformanceTests" '
          'tests="${summary.totalTests}" '
          'failures="${summary.failedTests}" '
          'time="${(summary.executionTimeMs / 1000).toStringAsFixed(3)}">');

    for (final PerformanceTestResult result in summary.results) {
      xml.writeln('  <testcase name="${result.testName}" '
          'time="${(result.executionTimeMs / 1000).toStringAsFixed(3)}">');
      
      if (!result.success) {
        xml.writeln('    <failure message="${result.exception?.toString() ?? 'Unknown failure'}"/>');
      }
      
      xml.writeln("  </testcase>");
    }

    xml.writeln("</testsuite>");

    final File junitFile = File("performance_test_results.xml");
    await junitFile.writeAsString(xml.toString());
    
    ProviderLogger.info(_component, "JUnitレポート生成完了: ${junitFile.path}");
  }

  /// 詳細JSONレポート生成
  Future<void> _generateDetailedJsonReport(PerformanceTestSummary summary) async {
    final Map<String, dynamic> report = summary.toJson();
    
    final File jsonFile = File("performance_detailed_report.json");
    await jsonFile.writeAsString(
      const JsonEncoder.withIndent("  ").convert(report),
    );
    
    ProviderLogger.info(_component, "詳細JSONレポート生成完了: ${jsonFile.path}");
  }
}

// =================================================================
// 設定・データクラス
// =================================================================

/// パフォーマンステスト実行設定
class PerformanceTestConfig {
  const PerformanceTestConfig({
    this.regressionThresholdPercent = 20.0,
    this.updateBaseline = true,
    this.generateJUnitReport = true,
    this.generateDetailedReport = true,
  });

  /// 回帰検出の閾値（％）
  final double regressionThresholdPercent;
  
  /// ベースライン自動更新フラグ
  final bool updateBaseline;
  
  /// JUnit形式レポート生成フラグ
  final bool generateJUnitReport;
  
  /// 詳細JSONレポート生成フラグ
  final bool generateDetailedReport;
}

/// パフォーマンステスト結果サマリー
class PerformanceTestSummary {
  const PerformanceTestSummary({
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.regressionCount,
    required this.executionTimeMs,
    required this.results,
    required this.regressions,
    required this.success,
    this.errorMessage,
  });

  final int totalTests;
  final int passedTests;
  final int failedTests;
  final int regressionCount;
  final int executionTimeMs;
  final List<PerformanceTestResult> results;
  final List<RegressionDetectionResult> regressions;
  final bool success;
  final String? errorMessage;

  /// JSON形式でのシリアライズ
  Map<String, dynamic> toJson() => <String, dynamic>{
        "totalTests": totalTests,
        "passedTests": passedTests,
        "failedTests": failedTests,
        "regressionCount": regressionCount,
        "executionTimeMs": executionTimeMs,
        "success": success,
        "errorMessage": errorMessage,
        "results": results.map((PerformanceTestResult r) => r.toJson()).toList(),
        "regressions": regressions.map((RegressionDetectionResult r) => r.toJson()).toList(),
        "timestamp": DateTime.now().toIso8601String(),
      };
}

// =================================================================
// CLI エントリーポイント
// =================================================================

/// コマンドライン実行用のメインメソッド
Future<void> main(List<String> args) async {
  // コマンドライン引数の解析
  final PerformanceTestConfig config = _parseArgs(args);
  
  // テストランナー実行
  final PerformanceTestRunner runner = PerformanceTestRunner(config: config);
  final PerformanceTestSummary summary = await runner.runAllTests();
  
  // 終了コード設定（CI/CD用）
  exit(summary.success ? 0 : 1);
}

/// コマンドライン引数解析
PerformanceTestConfig _parseArgs(List<String> args) {
  bool updateBaseline = true;
  bool generateJUnitReport = true;
  bool generateDetailedReport = true;
  double regressionThreshold = 20.0;

  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case "--no-update-baseline":
        updateBaseline = false;
        break;
      case "--no-junit":
        generateJUnitReport = false;
        break;
      case "--no-detailed-report":
        generateDetailedReport = false;
        break;
      case "--regression-threshold":
        if (i + 1 < args.length) {
          regressionThreshold = double.tryParse(args[i + 1]) ?? 20.0;
          i++; // 次の引数をスキップ
        }
        break;
    }
  }

  return PerformanceTestConfig(
    updateBaseline: updateBaseline,
    generateJUnitReport: generateJUnitReport,
    generateDetailedReport: generateDetailedReport,
    regressionThresholdPercent: regressionThreshold,
  );
}