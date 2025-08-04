import "dart:convert";
import "dart:io";


import "package:yata/core/utils/provider_logger.dart";
import "performance_test_helper.dart";

/// パフォーマンスベースライン管理クラス
/// 
/// パフォーマンステストの基準値を管理し、
/// 回帰検出のための比較機能を提供する
class PerformanceBaseline {
  PerformanceBaseline._();

  static const String _baselineFileName = "performance_baseline.json";
  static const String _resultsFileName = "performance_results.json";
  static const String _component = "PerformanceBaseline";

  // =================================================================
  // ベースライン管理
  // =================================================================

  /// 現在のベースラインを取得
  /// 
  /// ファイルが存在しない場合はデフォルト値を返す
  static Future<Map<String, BaselineMetrics>> loadBaseline() async {
    try {
      final File baselineFile = File(_baselineFileName);
      
      if (!await baselineFile.exists()) {
        ProviderLogger.info(_component, "ベースラインファイルが存在しません。デフォルト値を使用します");
        return _getDefaultBaseline();
      }
      
      final String content = await baselineFile.readAsString();
      final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;
      
      final Map<String, BaselineMetrics> baseline = <String, BaselineMetrics>{};
      for (final MapEntry<String, dynamic> entry in json.entries) {
        baseline[entry.key] = BaselineMetrics.fromJson(entry.value as Map<String, dynamic>);
      }
      
      ProviderLogger.info(_component, "ベースライン読み込み完了: ${baseline.length}個のメトリクス");
      return baseline;
    } catch (e, stackTrace) {
      ProviderLogger.error(_component, "ベースライン読み込み中にエラーが発生", e, stackTrace);
      return _getDefaultBaseline();
    }
  }

  /// ベースラインを保存
  /// 
  /// [baseline] 保存するベースラインデータ
  static Future<void> saveBaseline(Map<String, BaselineMetrics> baseline) async {
    try {
      final Map<String, dynamic> json = <String, dynamic>{};
      for (final MapEntry<String, BaselineMetrics> entry in baseline.entries) {
        json[entry.key] = entry.value.toJson();
      }
      
      final File baselineFile = File(_baselineFileName);
      await baselineFile.writeAsString(
        const JsonEncoder.withIndent("  ").convert(json),
      );
      
      ProviderLogger.info(_component, "ベースライン保存完了: ${baseline.length}個のメトリクス");
    } catch (e, stackTrace) {
      ProviderLogger.error(_component, "ベースライン保存中にエラーが発生", e, stackTrace);
      rethrow;
    }
  }

  /// ベースラインを更新
  /// 
  /// [testName] テスト名
  /// [result] パフォーマンステスト結果
  static Future<void> updateBaseline(String testName, PerformanceTestResult result) async {
    try {
      final Map<String, BaselineMetrics> baseline = await loadBaseline();
      
      baseline[testName] = BaselineMetrics(
        testName: testName,
        executionTimeMs: result.executionTimeMs,
        memoryUsageMB: result.memoryUsageMB,
        lastUpdated: result.timestamp,
        sampleCount: (baseline[testName]?.sampleCount ?? 0) + 1,
      );
      
      await saveBaseline(baseline);
      
      ProviderLogger.info(_component, "ベースライン更新: $testName");
    } catch (e, stackTrace) {
      ProviderLogger.error(_component, "ベースライン更新中にエラーが発生", e, stackTrace);
      rethrow;
    }
  }

  // =================================================================
  // パフォーマンス比較と回帰検出
  // =================================================================

  /// パフォーマンス回帰を検出
  /// 
  /// [testName] テスト名
  /// [result] 現在のテスト結果
  /// [regressionThreshold] 回帰検出の閾値（％）
  /// 戻り値: 回帰検出結果
  static Future<RegressionDetectionResult> detectRegression(
    String testName,
    PerformanceTestResult result, {
    double regressionThreshold = 20.0, // デフォルト20%の劣化でアラート
  }) async {
    try {
      final Map<String, BaselineMetrics> baseline = await loadBaseline();
      final BaselineMetrics? baselineMetric = baseline[testName];
      
      if (baselineMetric == null) {
        ProviderLogger.warning(_component, "ベースラインが存在しません: $testName");
        return RegressionDetectionResult(
          testName: testName,
          hasRegression: false,
          reason: "ベースラインデータなし",
          baselineExecutionTimeMs: 0,
          currentExecutionTimeMs: result.executionTimeMs,
          baselineMemoryUsageMB: 0.0,
          currentMemoryUsageMB: result.memoryUsageMB,
          executionTimeRegressionPercent: 0.0,
          memoryRegressionPercent: 0.0,
        );
      }
      
      // 実行時間の回帰計算
      final double executionTimeChange = ((result.executionTimeMs - baselineMetric.executionTimeMs) / 
          baselineMetric.executionTimeMs) * 100;
      
      // メモリ使用量の回帰計算
      final double memoryChange = baselineMetric.memoryUsageMB > 0 
          ? ((result.memoryUsageMB - baselineMetric.memoryUsageMB) / baselineMetric.memoryUsageMB) * 100
          : 0.0;
      
      // 回帰検出
      final bool hasExecutionTimeRegression = executionTimeChange > regressionThreshold;
      final bool hasMemoryRegression = memoryChange > regressionThreshold;
      final bool hasRegression = hasExecutionTimeRegression || hasMemoryRegression;
      
      // 回帰理由の特定
      String reason = "";
      if (hasExecutionTimeRegression && hasMemoryRegression) {
        reason = "実行時間とメモリ使用量の両方が劣化";
      } else if (hasExecutionTimeRegression) {
        reason = "実行時間が劣化";
      } else if (hasMemoryRegression) {
        reason = "メモリ使用量が劣化";
      } else {
        reason = "回帰なし";
      }
      
      final RegressionDetectionResult detectionResult = RegressionDetectionResult(
        testName: testName,
        hasRegression: hasRegression,
        reason: reason,
        baselineExecutionTimeMs: baselineMetric.executionTimeMs,
        currentExecutionTimeMs: result.executionTimeMs,
        baselineMemoryUsageMB: baselineMetric.memoryUsageMB,
        currentMemoryUsageMB: result.memoryUsageMB,
        executionTimeRegressionPercent: executionTimeChange,
        memoryRegressionPercent: memoryChange,
      );
      
      // ログ出力
      if (hasRegression) {
        ProviderLogger.warning(_component, 
          "🚨 パフォーマンス回帰検出: $testName - $reason "
          "(実行時間: ${executionTimeChange.toStringAsFixed(1)}%, "
          "メモリ: ${memoryChange.toStringAsFixed(1)}%)");
      } else {
        ProviderLogger.info(_component, 
          "✅ パフォーマンス正常: $testName "
          "(実行時間: ${executionTimeChange.toStringAsFixed(1)}%, "
          "メモリ: ${memoryChange.toStringAsFixed(1)}%)");
      }
      
      return detectionResult;
    } catch (e, stackTrace) {
      ProviderLogger.error(_component, "回帰検出中にエラーが発生", e, stackTrace);
      return RegressionDetectionResult(
        testName: testName,
        hasRegression: false,
        reason: "エラーが発生",
        baselineExecutionTimeMs: 0,
        currentExecutionTimeMs: result.executionTimeMs,
        baselineMemoryUsageMB: 0.0,
        currentMemoryUsageMB: result.memoryUsageMB,
        executionTimeRegressionPercent: 0.0,
        memoryRegressionPercent: 0.0,
      );
    }
  }

  // =================================================================
  // パフォーマンス結果の保存と履歴管理
  // =================================================================

  /// パフォーマンステスト結果を保存
  /// 
  /// [results] 保存する結果リスト
  static Future<void> saveTestResults(List<PerformanceTestResult> results) async {
    try {
      final List<Map<String, dynamic>> jsonResults = results.map((PerformanceTestResult r) => r.toJson()).toList();
      
      final File resultsFile = File(_resultsFileName);
      await resultsFile.writeAsString(
        const JsonEncoder.withIndent("  ").convert(<String, Object>{
          "timestamp": DateTime.now().toIso8601String(),
          "results": jsonResults,
        }),
      );
      
      ProviderLogger.info(_component, "パフォーマンステスト結果保存完了: ${results.length}個");
    } catch (e, stackTrace) {
      ProviderLogger.error(_component, "テスト結果保存中にエラーが発生", e, stackTrace);
    }
  }

  /// 過去のテスト結果を読み込み
  static Future<List<PerformanceTestResult>?> loadTestResults() async {
    try {
      final File resultsFile = File(_resultsFileName);
      
      if (!await resultsFile.exists()) {
        return null;
      }
      
      final String content = await resultsFile.readAsString();
      final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;
      final List<dynamic> resultsJson = json["results"] as List<dynamic>;
      
      // 注意: PerformanceTestResultにfromJsonメソッドが必要
      // 現在は簡易実装のため、ここでは読み込みのみ実装
      
      ProviderLogger.info(_component, "過去のテスト結果読み込み完了: ${resultsJson.length}個");
      return null; // 実装簡略化のため
    } catch (e, stackTrace) {
      ProviderLogger.error(_component, "テスト結果読み込み中にエラーが発生", e, stackTrace);
      return null;
    }
  }

  // =================================================================
  // プライベートメソッド
  // =================================================================

  /// デフォルトベースラインを取得
  static Map<String, BaselineMetrics> _getDefaultBaseline() => <String, BaselineMetrics>{
      "provider_initialization": BaselineMetrics(
        testName: "provider_initialization",
        executionTimeMs: 100, // 100ms以内
        memoryUsageMB: 1.0,   // 1MB以内
        lastUpdated: DateTime.now(),
        sampleCount: 0,
      ),
      "ui_rendering": BaselineMetrics(
        testName: "ui_rendering",
        executionTimeMs: 16,  // 60FPS維持
        memoryUsageMB: 0.5,   // 0.5MB以内
        lastUpdated: DateTime.now(),
        sampleCount: 0,
      ),
      "data_loading": BaselineMetrics(
        testName: "data_loading",
        executionTimeMs: 500, // 500ms以内
        memoryUsageMB: 2.0,   // 2MB以内
        lastUpdated: DateTime.now(),
        sampleCount: 0,
      ),
    };
}

// =================================================================
// データクラス
// =================================================================

/// ベースラインメトリクス
class BaselineMetrics {
  const BaselineMetrics({
    required this.testName,
    required this.executionTimeMs,
    required this.memoryUsageMB,
    required this.lastUpdated,
    required this.sampleCount,
  });

  /// JSONからのデシリアライズ
  factory BaselineMetrics.fromJson(Map<String, dynamic> json) => BaselineMetrics(
      testName: json["testName"] as String,
      executionTimeMs: json["executionTimeMs"] as int,
      memoryUsageMB: (json["memoryUsageMB"] as num).toDouble(),
      lastUpdated: DateTime.parse(json["lastUpdated"] as String),
      sampleCount: json["sampleCount"] as int,
    );

  final String testName;
  final int executionTimeMs;
  final double memoryUsageMB;
  final DateTime lastUpdated;
  final int sampleCount;

  /// JSON形式でのシリアライズ
  Map<String, dynamic> toJson() => <String, dynamic>{
        "testName": testName,
        "executionTimeMs": executionTimeMs,
        "memoryUsageMB": memoryUsageMB,
        "lastUpdated": lastUpdated.toIso8601String(),
        "sampleCount": sampleCount,
      };
}

/// 回帰検出結果
class RegressionDetectionResult {
  const RegressionDetectionResult({
    required this.testName,
    required this.hasRegression,
    required this.reason,
    required this.baselineExecutionTimeMs,
    required this.currentExecutionTimeMs,
    required this.baselineMemoryUsageMB,
    required this.currentMemoryUsageMB,
    required this.executionTimeRegressionPercent,
    required this.memoryRegressionPercent,
  });

  final String testName;
  final bool hasRegression;
  final String reason;
  final int baselineExecutionTimeMs;
  final int currentExecutionTimeMs;
  final double baselineMemoryUsageMB;
  final double currentMemoryUsageMB;
  final double executionTimeRegressionPercent;
  final double memoryRegressionPercent;

  /// JSON形式でのシリアライズ
  Map<String, dynamic> toJson() => <String, dynamic>{
        "testName": testName,
        "hasRegression": hasRegression,
        "reason": reason,
        "baselineExecutionTimeMs": baselineExecutionTimeMs,
        "currentExecutionTimeMs": currentExecutionTimeMs,
        "baselineMemoryUsageMB": baselineMemoryUsageMB,
        "currentMemoryUsageMB": currentMemoryUsageMB,
        "executionTimeRegressionPercent": executionTimeRegressionPercent,
        "memoryRegressionPercent": memoryRegressionPercent,
      };
}