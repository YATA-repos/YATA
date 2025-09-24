import "dart:async";

/// データ更新コールバック（契約）
typedef RealtimeDataCallback = void Function(Map<String, dynamic> data);

/// リアルタイム購読設定（契約）
class RealtimeSubscriptionConfig {
  const RealtimeSubscriptionConfig({
    required this.featureName,
    required this.tableName,
    this.filters,
    this.eventTypes = const <String>["INSERT", "UPDATE", "DELETE"],
    this.autoReconnect = true,
    this.maxReconnectAttempts = 5,
    this.reconnectDelay = const Duration(seconds: 3),
  });

  final String featureName;
  final String tableName;
  final Map<String, dynamic>? filters;
  final List<String> eventTypes;
  final bool autoReconnect;
  final int maxReconnectAttempts;
  final Duration reconnectDelay;
}

/// リアルタイムマネージャー契約
abstract class RealtimeManagerContract {
  Future<void> startMonitoring(
    RealtimeSubscriptionConfig config,
    String subscriptionId,
    RealtimeDataCallback onData,
  );

  Future<void> stopMonitoring(String subscriptionId);
  Future<void> stopAllMonitoring();

  bool isMonitoring(String subscriptionId);
  List<String> getActiveSubscriptions();

  /// 実装固有の統計情報（キーは実装依存）
  Map<String, dynamic> getStats();
}
