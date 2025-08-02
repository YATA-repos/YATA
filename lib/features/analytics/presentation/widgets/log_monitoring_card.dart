import "dart:async";

import "package:flutter/material.dart";

import "../../../../core/logging/yata_logger.dart";
import "../../../../shared/widgets/cards/app_card.dart";

/// ログ監視ダッシュボードカード
/// 
/// ログシステムの運用状況を表示し、
/// リアルタイムでの監視と統計情報を提供
class LogMonitoringCard extends StatefulWidget {
  const LogMonitoringCard({super.key});

  @override
  State<LogMonitoringCard> createState() => _LogMonitoringCardState();
}

class _LogMonitoringCardState extends State<LogMonitoringCard> {
  Map<String, dynamic>? _logStats;
  Map<String, dynamic>? _performanceStats;
  Map<String, dynamic>? _healthCheck;
  Map<String, dynamic>? _logLevelInfo;
  Map<String, dynamic>? _cleanupStats;
  bool _isLoading = true;
  bool _autoRefresh = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLogStats();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLogStats() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final Map<String, dynamic> stats = await YataLogger.getLogStats();
      final Map<String, dynamic> performance = YataLogger.getPerformanceStats();
      final Map<String, dynamic> health = YataLogger.getHealthCheck();
      final Map<String, dynamic> levelInfo = YataLogger.getLogLevelInfo();

      if (mounted) {
        setState(() {
          _logStats = stats;
          _performanceStats = performance;
          _healthCheck = health;
          _logLevelInfo = levelInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
    });

    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        _loadLogStats();
      });
    } else {
      _refreshTimer?.cancel();
    }
  }

  Future<void> _performCleanup({bool dryRun = false}) async {
    try {
      final Map<String, dynamic> result = await YataLogger.cleanupOldLogs(dryRun: dryRun);
      setState(() {
        _cleanupStats = result;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dryRun 
              ? "クリーンアップ対象: ${result['deletedFiles']?.length ?? 0}ファイル"
              : "クリーンアップ完了: ${result['filesDeleted'] ?? 0}ファイル削除"),
            backgroundColor: dryRun ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("クリーンアップエラー: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHealthIndicator(String healthStatus) {
    Color color;
    String status;
    IconData icon;

    switch (healthStatus) {
      case "healthy":
        color = Colors.green;
        status = "正常";
        icon = Icons.check_circle;
        break;
      case "warning_flush_issues":
        color = Colors.orange;
        status = "フラッシュ警告";
        icon = Icons.warning;
        break;
      case "warning_performance_issues":
        color = Colors.orange;
        status = "パフォーマンス警告";
        icon = Icons.speed;
        break;
      default:
        color = Colors.red;
        status = "要注意";
        icon = Icons.error;
    }

    return Row(
      children: <Widget>[
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    final Map<String, dynamic>? summary = _logStats?["performanceSummary"] as Map<String, dynamic>?;
    if (summary == null) return const SizedBox.shrink();

    final double logsPerSecond = (summary["logsPerSecond"] as double?) ?? 0.0;
    final String avgFlushTime = (summary["averageFlushTime"] as String?) ?? "0";
    final String failureRate = (summary["failureRate"] as String?) ?? "0";
    final int healthScore = (summary["healthScore"] as int?) ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("パフォーマンス指標", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildMetricItem("ログ/秒", logsPerSecond.toStringAsFixed(1)),
                _buildMetricItem("平均フラッシュ", "${avgFlushTime}ms"),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildMetricItem("失敗率", "$failureRate%"),
                _buildMetricItem("ヘルススコア", "$healthScore/100"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppCard(
        title: "ログ監視",
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final String healthStatus = (_logStats?["healthStatus"] as String?) ?? "unknown";
    final Map<String, dynamic>? systemInfo = _logStats?["systemInfo"] as Map<String, dynamic>?;

    return AppCard(
      title: "ログ監視",
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text("ログ監視", style: Theme.of(context).textTheme.titleMedium),
          Row(
            children: <Widget>[
              _buildHealthIndicator(healthStatus),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
                onPressed: _toggleAutoRefresh,
                tooltip: _autoRefresh ? "自動更新を停止" : "自動更新を開始",
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadLogStats,
                tooltip: "統計情報を更新",
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String value) {
                  switch (value) {
                    case "dry_cleanup":
                      _performCleanup(dryRun: true);
                      break;
                    case "cleanup":
                      _performCleanup();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(
                    value: "dry_cleanup",
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text("クリーンアップ対象を確認"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: "cleanup",
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.cleaning_services),
                        SizedBox(width: 8),
                        Text("ログクリーンアップ実行"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // パフォーマンス指標カード
          _buildPerformanceMetrics(),
          const SizedBox(height: 8),

          // システム情報とログレベル設定
          Row(
            children: <Widget>[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text("システム情報", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("バージョン: ${systemInfo?['loggerVersion'] ?? 'Unknown'}"),
                        Text("モード: ${systemInfo?['runtimeMode'] ?? 'Unknown'}"),
                        Text("初期化済み: ${systemInfo?['initialized'] == true ? 'はい' : 'いいえ'}"),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text("ログレベル設定", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("現在: ${_logLevelInfo?['currentLevel'] ?? 'Unknown'}"),
                        Text("ソース: ${_getConfigSourceDisplay()}"),
                        Text("自動設定: ${_logLevelInfo?['optimalLevel'] ?? 'Unknown'}"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 統計情報詳細
          if (_performanceStats != null) ...<Widget>[
            Card(
              child: ExpansionTile(
                title: const Text("詳細統計情報"),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text("基本統計:", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("処理ログ数: ${_performanceStats!['basic']?['totalLogsProcessed'] ?? 0}"),
                        Text("フラッシュ回数: ${_performanceStats!['basic']?['totalFlushOperations'] ?? 0}"),
                        Text("失敗回数: ${_performanceStats!['basic']?['totalFailedFlushes'] ?? 0}"),
                        const SizedBox(height: 8),
                        Text("パフォーマンス:", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("平均フラッシュ時間: ${_performanceStats!['performance']?['averageFlushTimeMs'] ?? 0}ms"),
                        Text("失敗率: ${_performanceStats!['performance']?['failureRatePercent'] ?? 0}%"),
                        if (_performanceStats!["performance"]?["uptimeHours"] != null)
                          Text("稼働時間: ${_performanceStats!['performance']['uptimeHours']}時間"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // クリーンアップ結果（実行後のみ表示）
          if (_cleanupStats != null) ...<Widget>[
            const SizedBox(height: 8),
            Card(
              color: _cleanupStats!["dryRun"] == true ? Colors.orange.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          _cleanupStats!["dryRun"] == true ? Icons.search : Icons.check_circle,
                          color: _cleanupStats!["dryRun"] == true ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _cleanupStats!["dryRun"] == true ? "クリーンアップ対象" : "クリーンアップ結果",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("スキャンファイル数: ${_cleanupStats!['filesScanned'] ?? 0}"),
                    Text("${_cleanupStats!['dryRun'] == true ? '削除対象' : '削除済み'}ファイル数: ${_cleanupStats!['filesDeleted'] ?? 0}"),
                    if (_cleanupStats!["totalSizeDeleted"] != null)
                      Text("削除サイズ: ${(_cleanupStats!['totalSizeDeleted'] / 1024).toStringAsFixed(1)} KB"),
                    if (_cleanupStats!["duration"] != null)
                      Text("実行時間: ${_cleanupStats!['duration']}ms"),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getConfigSourceDisplay() {
    final String? source = _logLevelInfo?["configurationSource"] as String?;
    switch (source) {
      case "runtime_env_variable":
        return ".env ファイル";
      case "compile_time_env_variable":
        return "コンパイル時環境変数";
      case "auto_debug_mode":
        return "自動(デバッグ)";
      case "auto_profile_mode":
        return "自動(プロファイル)";
      case "auto_release_mode":
        return "自動(リリース)";
      default:
        return "不明";
    }
  }
}