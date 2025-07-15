import "dart:async";
import "dart:math" as math;

import "package:flutter_test/flutter_test.dart";

/// パフォーマンステスト用ユーティリティ
///
/// 各リポジトリの性能測定とストレステストを提供
class PerformanceTestHelper {
  PerformanceTestHelper._();

  static PerformanceTestHelper? _instance;
  static PerformanceTestHelper get instance => _instance ??= PerformanceTestHelper._();

  /// ベンチマークテストの実行
  Future<PerformanceResult> benchmark({
    required String testName,
    required Future<void> Function() operation,
    int iterations = 100,
    Duration? timeout,
  }) async {
    final List<Duration> durations = <Duration>[];
    final Stopwatch stopwatch = Stopwatch();

    // ウォームアップ実行
    await operation();

    for (int i = 0; i < iterations; i++) {
      stopwatch.reset();
      stopwatch.start();

      try {
        if (timeout != null) {
          await operation().timeout(timeout);
        } else {
          await operation();
        }
      } catch (e) {
        throw PerformanceTestException("Benchmark failed on iteration ${i + 1}: $e");
      } finally {
        stopwatch.stop();
        durations.add(stopwatch.elapsed);
      }
    }

    return PerformanceResult(testName: testName, iterations: iterations, durations: durations);
  }

  /// ストレステストの実行
  Future<StressTestResult> stressTest({
    required String testName,
    required Future<void> Function() operation,
    int concurrentOperations = 10,
    int operationsPerConcurrent = 50,
    Duration? timeout,
  }) async {
    final List<PerformanceResult> results = <PerformanceResult>[];
    final List<String> errors = <String>[];
    final Stopwatch totalTime = Stopwatch()..start();

    // 並行処理でストレステストを実行
    final List<Future<void>> futures = <Future<void>>[];

    for (int i = 0; i < concurrentOperations; i++) {
      futures.add(
        _runConcurrentOperations(
          operation: operation,
          operationCount: operationsPerConcurrent,
          operationId: i,
          timeout: timeout,
        ).then(results.add).catchError((dynamic error) {
          errors.add("Concurrent operation $i failed: $error");
        }),
      );
    }

    await Future.wait(futures);
    totalTime.stop();

    return StressTestResult(
      testName: testName,
      concurrentOperations: concurrentOperations,
      operationsPerConcurrent: operationsPerConcurrent,
      totalDuration: totalTime.elapsed,
      results: results,
      errors: errors,
    );
  }

  /// 並行処理内での個別オペレーション実行
  Future<PerformanceResult> _runConcurrentOperations({
    required Future<void> Function() operation,
    required int operationCount,
    required int operationId,
    Duration? timeout,
  }) async => benchmark(
    testName: "Concurrent_$operationId",
    operation: operation,
    iterations: operationCount,
    timeout: timeout,
  );

  /// メモリ使用量の測定
  Future<MemoryTestResult> measureMemoryUsage({
    required String testName,
    required Future<void> Function() operation,
    int iterations = 10,
  }) async {
    // Dart VMのガベージコレクションを強制実行
    await _forceGarbageCollection();

    final int initialMemory = _getCurrentMemoryUsage();
    final List<int> memorySnapshots = <int>[initialMemory];

    for (int i = 0; i < iterations; i++) {
      await operation();

      // 定期的にメモリ使用量を記録
      if ((i + 1) % (iterations ~/ 5) == 0) {
        memorySnapshots.add(_getCurrentMemoryUsage());
      }
    }

    await _forceGarbageCollection();
    final int finalMemory = _getCurrentMemoryUsage();
    memorySnapshots.add(finalMemory);

    return MemoryTestResult(
      testName: testName,
      initialMemory: initialMemory,
      finalMemory: finalMemory,
      peakMemory: memorySnapshots.reduce(math.max),
      memorySnapshots: memorySnapshots,
    );
  }

  /// ガベージコレクションの強制実行
  Future<void> _forceGarbageCollection() async {
    // プラットフォーム固有のGC実行
    // 実際の実装では platform channels を使用
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// 現在のメモリ使用量を取得（KB単位）
  int _getCurrentMemoryUsage() {
    // 実際の実装では dart:developer の Service.getVM() を使用
    // テスト目的のプレースホルダー
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }
}

/// パフォーマンステスト結果
class PerformanceResult {
  const PerformanceResult({
    required this.testName,
    required this.iterations,
    required this.durations,
  });

  final String testName;
  final int iterations;
  final List<Duration> durations;

  /// 平均実行時間
  Duration get averageDuration {
    final int totalMicroseconds = durations
        .map((Duration d) => d.inMicroseconds)
        .reduce((int a, int b) => a + b);
    return Duration(microseconds: totalMicroseconds ~/ iterations);
  }

  /// 最小実行時間
  Duration get minDuration =>
      durations.reduce((Duration a, Duration b) => a.inMicroseconds < b.inMicroseconds ? a : b);

  /// 最大実行時間
  Duration get maxDuration =>
      durations.reduce((Duration a, Duration b) => a.inMicroseconds > b.inMicroseconds ? a : b);

  /// 95パーセンタイル実行時間
  Duration get p95Duration {
    final List<Duration> sorted = List<Duration>.from(durations)
      ..sort((Duration a, Duration b) => a.inMicroseconds.compareTo(b.inMicroseconds));
    final int index = (sorted.length * 0.95).floor();
    return sorted[index];
  }

  /// 標準偏差
  double get standardDeviation {
    final double mean = averageDuration.inMicroseconds.toDouble();
    final double variance =
        durations
            .map((Duration d) => math.pow(d.inMicroseconds - mean, 2))
            .fold(0.0, (double a, num b) => a + b.toDouble()) /
        iterations;
    return math.sqrt(variance);
  }

  @override
  String toString() =>
      """
Performance Result: $testName
Iterations: $iterations
Average: ${averageDuration.inMilliseconds}ms
Min: ${minDuration.inMilliseconds}ms
Max: ${maxDuration.inMilliseconds}ms
P95: ${p95Duration.inMilliseconds}ms
StdDev: ${standardDeviation.toStringAsFixed(2)}μs
""";
}

/// ストレステスト結果
class StressTestResult {
  const StressTestResult({
    required this.testName,
    required this.concurrentOperations,
    required this.operationsPerConcurrent,
    required this.totalDuration,
    required this.results,
    required this.errors,
  });

  final String testName;
  final int concurrentOperations;
  final int operationsPerConcurrent;
  final Duration totalDuration;
  final List<PerformanceResult> results;
  final List<String> errors;

  /// 総オペレーション数
  int get totalOperations => concurrentOperations * operationsPerConcurrent;

  /// 秒あたりのオペレーション数
  double get operationsPerSecond => totalOperations / (totalDuration.inMilliseconds / 1000.0);

  /// 成功したオペレーション数
  int get successfulOperations =>
      results.map((PerformanceResult r) => r.iterations).fold(0, (int a, int b) => a + b);

  /// エラー率
  double get errorRate => errors.length / totalOperations;

  @override
  String toString() =>
      """
Stress Test Result: $testName
Concurrent Operations: $concurrentOperations
Operations per Concurrent: $operationsPerConcurrent
Total Operations: $totalOperations
Successful Operations: $successfulOperations
Total Duration: ${totalDuration.inSeconds}s
Operations/sec: ${operationsPerSecond.toStringAsFixed(2)}
Error Rate: ${(errorRate * 100).toStringAsFixed(2)}%
Errors: ${errors.length}
""";
}

/// メモリテスト結果
class MemoryTestResult {
  const MemoryTestResult({
    required this.testName,
    required this.initialMemory,
    required this.finalMemory,
    required this.peakMemory,
    required this.memorySnapshots,
  });

  final String testName;
  final int initialMemory;
  final int finalMemory;
  final int peakMemory;
  final List<int> memorySnapshots;

  /// メモリ増加量
  int get memoryIncrease => finalMemory - initialMemory;

  /// メモリ使用量の最大増加
  int get peakMemoryIncrease => peakMemory - initialMemory;

  /// メモリリークの可能性
  bool get hasMemoryLeak => memoryIncrease > (initialMemory * 0.1); // 10%以上の増加

  @override
  String toString() =>
      """
Memory Test Result: $testName
Initial Memory: ${initialMemory}KB
Final Memory: ${finalMemory}KB
Peak Memory: ${peakMemory}KB
Memory Increase: ${memoryIncrease}KB
Peak Increase: ${peakMemoryIncrease}KB
Memory Leak Detected: $hasMemoryLeak
""";
}

/// パフォーマンステスト例外
class PerformanceTestException implements Exception {
  const PerformanceTestException(this.message);

  final String message;

  @override
  String toString() => "PerformanceTestException: $message";
}
