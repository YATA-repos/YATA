import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/utils/provider_logger.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/cards/app_card.dart";

/// パフォーマンス監視ダッシュボードカード
/// 
/// パフォーマンステストの結果表示、
/// 回帰検出アラート、ベースライン管理機能を提供する
class PerformanceMonitoringCard extends ConsumerStatefulWidget {
  const PerformanceMonitoringCard({super.key});

  @override
  ConsumerState<PerformanceMonitoringCard> createState() => _PerformanceMonitoringCardState();
}

class _PerformanceMonitoringCardState extends ConsumerState<PerformanceMonitoringCard> {
  PerformanceTestData? _latestResults;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  // =================================================================
  // データ読み込み
  // =================================================================

  /// パフォーマンステストデータを読み込み
  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final PerformanceTestData? data = await _readPerformanceResults();
      setState(() {
        _latestResults = data;
        _isLoading = false;
      });

      ProviderLogger.info("PerformanceMonitoringCard", "パフォーマンスデータ読み込み完了");
    } catch (e, stackTrace) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ProviderLogger.error("PerformanceMonitoringCard", "パフォーマンスデータ読み込み失敗", e, stackTrace);
    }
  }

  /// パフォーマンス結果ファイルを読み込み
  Future<PerformanceTestData?> _readPerformanceResults() async {
    final File reportFile = File("performance_detailed_report.json");
    
    if (!await reportFile.exists()) {
      return null;
    }

    final String content = await reportFile.readAsString();
    final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;
    
    return PerformanceTestData.fromJson(json);
  }

  // =================================================================
  // UI アクション
  // =================================================================

  /// パフォーマンステストを実行
  Future<void> _runPerformanceTest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      ProviderLogger.info("PerformanceMonitoringCard", "パフォーマンステスト実行開始");
      
      // パフォーマンステスト実行コマンド
      final ProcessResult result = await Process.run(
        "dart",
        <String>["test/performance/run_performance_tests.dart", "--no-update-baseline"],
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode == 0) {
        // 成功時は結果を再読み込み
        await _loadPerformanceData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ パフォーマンステスト実行完了"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("パフォーマンステスト実行失敗: ${result.stderr}");
      }
    } catch (e, stackTrace) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ProviderLogger.error("PerformanceMonitoringCard", "パフォーマンステスト実行失敗", e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ パフォーマンステスト実行失敗: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ベースラインを更新
  Future<void> _updateBaseline() async {
    // 確認ダイアログ
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("⚠️ ベースライン更新"),
        content: const Text(
          "現在のパフォーマンス値をベースラインとして設定しますか？\n\n"
          "この操作により、今後の回帰検出基準が更新されます。",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("更新する"),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      ProviderLogger.info("PerformanceMonitoringCard", "ベースライン更新開始");
      
      final ProcessResult result = await Process.run(
        "dart",
        <String>["test/performance/run_performance_tests.dart", "--update-baseline"],
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode == 0) {
        await _loadPerformanceData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ ベースライン更新完了"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("ベースライン更新失敗: ${result.stderr}");
      }
    } catch (e, stackTrace) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ProviderLogger.error("PerformanceMonitoringCard", "ベースライン更新失敗", e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ベースライン更新失敗: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =================================================================
  // UI構築
  // =================================================================

  @override
  Widget build(BuildContext context) => AppCard(
      title: "📊 パフォーマンス監視",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 操作ボタン行
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  text: "テスト実行",
                  onPressed: _isLoading ? null : _runPerformanceTest,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: "ベースライン更新",
                  onPressed: _isLoading ? null : _updateBaseline,
                  variant: ButtonVariant.outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // エラー表示
          if (_error != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.error, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "エラー: $_error",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 結果表示
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_latestResults != null)
            _buildResultsSection(_latestResults!)
          else
            _buildNoDataSection(),
        ],
      ),
    );

  /// 結果表示セクション
  Widget _buildResultsSection(PerformanceTestData data) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // サマリー行
        Row(
          children: <Widget>[
            Expanded(
              child: _buildMetricCard(
                "総テスト",
                data.totalTests.toString(),
                Icons.assignment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                "成功",
                data.passedTests.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                "失敗",
                data.failedTests.toString(),
                Icons.error,
                data.failedTests > 0 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 回帰検出アラート
        if (data.regressionCount > 0) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "🚨 パフォーマンス回帰検出: ${data.regressionCount}件",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...data.regressions.map((RegressionInfo regression) => Padding(
                  padding: const EdgeInsets.only(left: 28, bottom: 4),
                  child: Text(
                    "• ${regression.testName}: ${regression.reason}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 実行時間と最終更新
        Row(
          children: <Widget>[
            Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              "実行時間: ${data.executionTimeMs}ms",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              "更新: ${_formatDateTime(data.timestamp)}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ステータス表示
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: data.success ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    data.success ? Icons.check : Icons.close,
                    size: 16,
                    color: data.success ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data.success ? "正常" : "異常",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: data.success ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

  /// データなし表示セクション
  Widget _buildNoDataSection() => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "パフォーマンステスト結果がありません",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "「テスト実行」ボタンをクリックして\nパフォーマンステストを開始してください",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );

  /// メトリクスカード
  Widget _buildMetricCard(String label, String value, IconData icon, Color color) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withAlpha(204),
            ),
          ),
        ],
      ),
    );

  /// 日時フォーマット
  String _formatDateTime(DateTime dateTime) => '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

// =================================================================
// データクラス
// =================================================================

/// パフォーマンステストデータ
class PerformanceTestData {
  const PerformanceTestData({
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.regressionCount,
    required this.executionTimeMs,
    required this.success,
    required this.timestamp,
    required this.regressions,
  });

  /// JSONからのデシリアライズ
  factory PerformanceTestData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> regressionsJson = json["regressions"] as List<dynamic>? ?? <dynamic>[];
    final List<RegressionInfo> regressions = regressionsJson
        .map((r) => RegressionInfo.fromJson(r as Map<String, dynamic>))
        .toList();

    return PerformanceTestData(
      totalTests: json["totalTests"] as int? ?? 0,
      passedTests: json["passedTests"] as int? ?? 0,
      failedTests: json["failedTests"] as int? ?? 0,
      regressionCount: json["regressionCount"] as int? ?? 0,
      executionTimeMs: json["executionTimeMs"] as int? ?? 0,
      success: json["success"] as bool? ?? false,
      timestamp: DateTime.tryParse(json["timestamp"] as String? ?? "") ?? DateTime.now(),
      regressions: regressions,
    );
  }

  final int totalTests;
  final int passedTests;
  final int failedTests;
  final int regressionCount;
  final int executionTimeMs;
  final bool success;
  final DateTime timestamp;
  final List<RegressionInfo> regressions;
}

/// 回帰情報
class RegressionInfo {
  const RegressionInfo({
    required this.testName,
    required this.reason,
  });

  /// JSONからのデシリアライズ
  factory RegressionInfo.fromJson(Map<String, dynamic> json) => RegressionInfo(
      testName: json["testName"] as String? ?? "",
      reason: json["reason"] as String? ?? "",
    );

  final String testName;
  final String reason;
}