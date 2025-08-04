import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";

import "package:yata/core/utils/provider_logger.dart";

/// パフォーマンステスト用ヘルパークラス
/// 
/// 既存のProviderLoggerとPerformanceMonitorと連携して
/// パフォーマンス回帰テストの基盤機能を提供する
class PerformanceTestHelper {
  PerformanceTestHelper._();

  // =================================================================
  // ベースライン値とパフォーマンス閾値
  // =================================================================

  /// メモリ使用量の警告閾値（MB）
  static const double memoryWarningThreshold = 50.0;
  
  /// メモリ使用量の危険閾値（MB）
  static const double memoryCriticalThreshold = 100.0;
  
  /// 応答時間の警告閾値（ミリ秒）
  static const int responseTimeWarningThreshold = 1000;
  
  /// 応答時間の危険閾値（ミリ秒）
  static const int responseTimeCriticalThreshold = 3000;
  
  /// UI描画時間の警告閾値（ミリ秒）
  static const int uiRenderWarningThreshold = 16; // 60FPS基準
  
  /// UI描画時間の危険閾値（ミリ秒）
  static const int uiRenderCriticalThreshold = 33; // 30FPS基準
  
  /// プロバイダー初期化時間の警告閾値（ミリ秒）
  static const int providerInitWarningThreshold = 500;
  
  /// プロバイダー初期化時間の危険閾値（ミリ秒）
  static const int providerInitCriticalThreshold = 1500;

  // =================================================================
  // パフォーマンス測定メソッド
  // =================================================================

  /// パフォーマンス計測付きでテストを実行
  /// 
  /// [testName] テスト名
  /// [testFunction] 実行するテスト関数
  /// [expectedMaxDuration] 期待する最大実行時間（ミリ秒）
  /// [memoryThreshold] メモリ使用量の閾値（MB）
  /// 戻り値: パフォーマンス計測結果
  static Future<PerformanceTestResult> measurePerformance(
    String testName,
    Future<void> Function() testFunction, {
    int? expectedMaxDuration,
    double? memoryThreshold,
  }) async {
    final String component = "PerformanceTestHelper";
    
    // 初期メモリ状態の記録
    final int initialMemory = _getMemoryUsage();
    
    // パフォーマンス計測開始
    final DateTime startTime = ProviderLogger.startPerformanceTimer(component, testName);
    
    Exception? testException;
    StackTrace? testStackTrace;
    
    try {
      // テスト実行
      await testFunction();
    } catch (e, stackTrace) {
      testException = e is Exception ? e : Exception(e.toString());
      testStackTrace = stackTrace;
      ProviderLogger.error(component, "パフォーマンステスト中にエラーが発生", e, stackTrace);
    }
    
    // パフォーマンス計測終了
    ProviderLogger.endPerformanceTimer(
      startTime,
      component,
      testName,
      thresholdMs: expectedMaxDuration,
    );
    
    // 最終メモリ状態の記録
    final int finalMemory = _getMemoryUsage();
    final Duration executionTime = DateTime.now().difference(startTime);
    
    // 結果の分析
    final PerformanceTestResult result = PerformanceTestResult(
      testName: testName,
      executionTimeMs: executionTime.inMilliseconds,
      memoryUsageMB: (finalMemory - initialMemory) / 1024 / 1024,
      initialMemoryMB: initialMemory / 1024 / 1024,
      finalMemoryMB: finalMemory / 1024 / 1024,
      success: testException == null,
      exception: testException,
      stackTrace: testStackTrace,
      timestamp: DateTime.now(),
    );
    
    // 閾値チェックとログ出力
    _analyzePerformanceResult(result, expectedMaxDuration, memoryThreshold);
    
    return result;
  }

  /// メモリリークテスト
  /// 
  /// [testName] テスト名
  /// [setupFunction] セットアップ関数
  /// [cleanupFunction] クリーンアップ関数
  /// [iterations] 繰り返し回数
  /// [maxMemoryLeakMB] 許可される最大メモリリーク量（MB）
  static Future<MemoryLeakTestResult> testMemoryLeak(
    String testName,
    Future<void> Function() setupFunction,
    Future<void> Function() cleanupFunction, {
    int iterations = 10,
    double maxMemoryLeakMB = 5.0,
  }) async {
    final String component = "MemoryLeakTest";
    
    ProviderLogger.info(component, "メモリリークテスト開始: $testName (反復回数: $iterations)");
    
    final List<double> memorySnapshots = <double>[];
    
    // 初期状態の記録
    await _forceGarbageCollection();
    final double initialMemory = _getMemoryUsage() / 1024 / 1024;
    memorySnapshots.add(initialMemory);
    
    Exception? testException;
    
    try {
      // 指定回数繰り返し実行
      for (int i = 0; i < iterations; i++) {
        await setupFunction();
        await cleanupFunction();
        
        // ガベージコレクション強制実行
        await _forceGarbageCollection();
        
        // メモリ使用量記録
        final double currentMemory = _getMemoryUsage() / 1024 / 1024;
        memorySnapshots.add(currentMemory);
        
        ProviderLogger.debug(component, "反復 ${i + 1}/$iterations: メモリ使用量 ${currentMemory.toStringAsFixed(2)}MB");
      }
    } catch (e) {
      testException = e is Exception ? e : Exception(e.toString());
      ProviderLogger.error(component, "メモリリークテスト中にエラーが発生", e);
    }
    
    // 最終メモリ量とリーク量の計算
    final double finalMemory = memorySnapshots.last;
    final double memoryLeak = finalMemory - initialMemory;
    final bool passed = memoryLeak <= maxMemoryLeakMB && testException == null;
    
    final MemoryLeakTestResult result = MemoryLeakTestResult(
      testName: testName,
      initialMemoryMB: initialMemory,
      finalMemoryMB: finalMemory,
      memoryLeakMB: memoryLeak,
      maxAllowedLeakMB: maxMemoryLeakMB,
      iterations: iterations,
      memorySnapshots: memorySnapshots,
      passed: passed,
      exception: testException,
      timestamp: DateTime.now(),
    );
    
    // 結果ログ出力
    if (passed) {
      ProviderLogger.info(component, "✅ メモリリークテスト合格: $testName (リーク量: ${memoryLeak.toStringAsFixed(2)}MB)");
    } else {
      ProviderLogger.warning(component, "❌ メモリリークテスト失敗: $testName (リーク量: ${memoryLeak.toStringAsFixed(2)}MB, 上限: ${maxMemoryLeakMB}MB)");
    }
    
    return result;
  }

  /// UI描画パフォーマンステスト
  /// 
  /// [testName] テスト名
  /// [widgetBuilder] テスト対象ウィジェットのビルダー
  /// [interactions] UI操作のリスト
  /// [expectedMaxRenderTimeMs] 期待する最大描画時間（ミリ秒）
  static Future<UIPerformanceTestResult> testUIPerformance(
    String testName,
    WidgetTester Function() widgetTesterGetter,
    List<Future<void> Function(WidgetTester)> interactions, {
    int expectedMaxRenderTimeMs = uiRenderWarningThreshold,
  }) async {
    final String component = "UIPerformanceTest";
    
    ProviderLogger.info(component, "UI描画パフォーマンステスト開始: $testName");
    
    final List<int> renderTimes = <int>[];
    Exception? testException;
    
    try {
      final WidgetTester tester = widgetTesterGetter();
      
      // 各インタラクションの描画時間を測定
      for (int i = 0; i < interactions.length; i++) {
        final DateTime startTime = DateTime.now();
        
        await interactions[i](tester);
        await tester.pumpAndSettle();
        
        final int renderTime = DateTime.now().difference(startTime).inMilliseconds;
        renderTimes.add(renderTime);
        
        ProviderLogger.debug(component, "インタラクション ${i + 1}: 描画時間 ${renderTime}ms");
      }
    } catch (e) {
      testException = e is Exception ? e : Exception(e.toString());
      ProviderLogger.error(component, "UI描画パフォーマンステスト中にエラーが発生", e);
    }
    
    // 統計の計算
    final int maxRenderTime = renderTimes.isEmpty ? 0 : renderTimes.reduce((int a, int b) => a > b ? a : b);
    final double avgRenderTime = renderTimes.isEmpty ? 0.0 : renderTimes.reduce((int a, int b) => a + b) / renderTimes.length;
    final bool passed = maxRenderTime <= expectedMaxRenderTimeMs && testException == null;
    
    final UIPerformanceTestResult result = UIPerformanceTestResult(
      testName: testName,
      renderTimes: renderTimes,
      maxRenderTimeMs: maxRenderTime,
      avgRenderTimeMs: avgRenderTime,
      expectedMaxRenderTimeMs: expectedMaxRenderTimeMs,
      passed: passed,
      exception: testException,
      timestamp: DateTime.now(),
    );
    
    // 結果ログ出力
    if (passed) {
      ProviderLogger.info(component, "✅ UI描画パフォーマンステスト合格: $testName (最大描画時間: ${maxRenderTime}ms)");
    } else {
      ProviderLogger.warning(component, "❌ UI描画パフォーマンステスト失敗: $testName (最大描画時間: ${maxRenderTime}ms, 期待値: ${expectedMaxRenderTimeMs}ms)");
    }
    
    return result;
  }

  // =================================================================
  // ユーティリティメソッド
  // =================================================================

  /// パフォーマンス結果の分析とログ出力
  static void _analyzePerformanceResult(
    PerformanceTestResult result,
    int? expectedMaxDuration,
    double? memoryThreshold,
  ) {
    final String component = "PerformanceAnalyzer";
    
    // 実行時間分析
    if (expectedMaxDuration != null) {
      if (result.executionTimeMs > expectedMaxDuration) {
        ProviderLogger.warning(component, 
          "⚠️ パフォーマンス警告: ${result.testName} - 実行時間超過 (${result.executionTimeMs}ms > ${expectedMaxDuration}ms)");
      }
    }
    
    // メモリ使用量分析
    if (memoryThreshold != null) {
      if (result.memoryUsageMB > memoryThreshold) {
        ProviderLogger.warning(component,
          "⚠️ メモリ使用量警告: ${result.testName} - メモリ使用量超過 (${result.memoryUsageMB.toStringAsFixed(2)}MB > ${memoryThreshold.toStringAsFixed(2)}MB)");
      }
    }
    
    // 成功/失敗ログ
    if (result.success) {
      ProviderLogger.info(component, "✅ パフォーマンステスト合格: ${result.testName} (${result.executionTimeMs}ms)");
    } else {
      ProviderLogger.error(component, "❌ パフォーマンステスト失敗: ${result.testName}", result.exception);
    }
  }

  /// メモリ使用量取得（簡易実装）
  static int _getMemoryUsage() {
    if (kIsWeb) {
      // Web環境では簡易的な値を返す
      return 0;
    }
    
    try {
      // ProcessInfoを使用してメモリ使用量を取得
      return ProcessInfo.currentRss;
    } catch (e) {
      // エラー時は0を返す
      return 0;
    }
  }

  /// ガベージコレクション強制実行
  static Future<void> _forceGarbageCollection() async {
    // Dartにはガベージコレクションを強制実行する公式APIがないため、
    // 間接的な方法でメモリクリーンアップを促す
    for (int i = 0; i < 3; i++) {
      final Future<void> delay = Future.delayed(const Duration(milliseconds: 10));
      await delay;
    }
  }
}

// =================================================================
// パフォーマンステスト結果データクラス
// =================================================================

/// 基本パフォーマンステスト結果
class PerformanceTestResult {
  const PerformanceTestResult({
    required this.testName,
    required this.executionTimeMs,
    required this.memoryUsageMB,
    required this.initialMemoryMB,
    required this.finalMemoryMB,
    required this.success,
    required this.timestamp,
    this.exception,
    this.stackTrace,
  });

  final String testName;
  final int executionTimeMs;
  final double memoryUsageMB;
  final double initialMemoryMB;
  final double finalMemoryMB;
  final bool success;
  final Exception? exception;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  /// JSON形式でのシリアライズ
  Map<String, dynamic> toJson() => <String, dynamic>{
        "testName": testName,
        "executionTimeMs": executionTimeMs,
        "memoryUsageMB": memoryUsageMB,
        "initialMemoryMB": initialMemoryMB,
        "finalMemoryMB": finalMemoryMB,
        "success": success,
        "timestamp": timestamp.toIso8601String(),
        "exception": exception?.toString(),
      };
}

/// メモリリークテスト結果
class MemoryLeakTestResult {
  const MemoryLeakTestResult({
    required this.testName,
    required this.initialMemoryMB,
    required this.finalMemoryMB,
    required this.memoryLeakMB,
    required this.maxAllowedLeakMB,
    required this.iterations,
    required this.memorySnapshots,
    required this.passed,
    required this.timestamp,
    this.exception,
  });

  final String testName;
  final double initialMemoryMB;
  final double finalMemoryMB;
  final double memoryLeakMB;
  final double maxAllowedLeakMB;
  final int iterations;
  final List<double> memorySnapshots;
  final bool passed;
  final Exception? exception;
  final DateTime timestamp;

  /// JSON形式でのシリアライズ
  Map<String, dynamic> toJson() => <String, dynamic>{
        "testName": testName,
        "initialMemoryMB": initialMemoryMB,
        "finalMemoryMB": finalMemoryMB,
        "memoryLeakMB": memoryLeakMB,
        "maxAllowedLeakMB": maxAllowedLeakMB,
        "iterations": iterations,
        "memorySnapshots": memorySnapshots,
        "passed": passed,
        "timestamp": timestamp.toIso8601String(),
        "exception": exception?.toString(),
      };
}

/// UI描画パフォーマンステスト結果
class UIPerformanceTestResult {
  const UIPerformanceTestResult({
    required this.testName,
    required this.renderTimes,
    required this.maxRenderTimeMs,
    required this.avgRenderTimeMs,
    required this.expectedMaxRenderTimeMs,
    required this.passed,
    required this.timestamp,
    this.exception,
  });

  final String testName;
  final List<int> renderTimes;
  final int maxRenderTimeMs;
  final double avgRenderTimeMs;
  final int expectedMaxRenderTimeMs;
  final bool passed;
  final Exception? exception;
  final DateTime timestamp;

  /// JSON形式でのシリアライズ
  Map<String, dynamic> toJson() => <String, dynamic>{
        "testName": testName,
        "renderTimes": renderTimes,
        "maxRenderTimeMs": maxRenderTimeMs,
        "avgRenderTimeMs": avgRenderTimeMs,
        "expectedMaxRenderTimeMs": expectedMaxRenderTimeMs,
        "passed": passed,
        "timestamp": timestamp.toIso8601String(),
        "exception": exception?.toString(),
      };
}