import "dart:async";

import "../../core/contracts/realtime/realtime_manager.dart" as contract;
import "realtime_config.dart";
import "realtime_manager.dart" as impl;

/// infra/realtime の実装を core 契約にブリッジするアダプタ
class RealtimeManagerAdapter implements contract.RealtimeManagerContract {
  RealtimeManagerAdapter() : _impl = impl.RealtimeManager();

  final impl.RealtimeManager _impl;

  @override
  Future<void> startMonitoring(
    contract.RealtimeSubscriptionConfig config,
    String subscriptionId,
    contract.RealtimeDataCallback onData,
  ) {
    // 契約設定から infra 設定へ変換
    final RealtimeConfig cfg = RealtimeConfig(
      feature: _toFeature(config.featureName),
      tableName: config.tableName,
      filters: config.filters,
      eventTypes: config.eventTypes,
      autoReconnect: config.autoReconnect,
      maxReconnectAttempts: config.maxReconnectAttempts,
      reconnectDelay: config.reconnectDelay,
    );

    return _impl.startMonitoring(cfg, subscriptionId, onData);
  }

  @override
  Future<void> stopMonitoring(String subscriptionId) => _impl.stopMonitoring(subscriptionId);

  @override
  Future<void> stopAllMonitoring() => _impl.stopAllMonitoring();

  @override
  bool isMonitoring(String subscriptionId) => _impl.isMonitoring(subscriptionId);

  @override
  List<String> getActiveSubscriptions() => _impl.getActiveSubscriptions();

  @override
  Map<String, dynamic> getStats() => _impl.getStats();

  // 契約の featureName を既存の enum にマップ（既知の値のみを対応）
  RealtimeFeature _toFeature(String name) {
    switch (name) {
      case "inventory":
        return RealtimeFeature.inventory;
      case "orders":
        return RealtimeFeature.orders;
      case "menu":
        return RealtimeFeature.menu;
      case "analytics":
        return RealtimeFeature.analytics;
      default:
        // 既定は analytics とする（契約側は自由文字列のため）
        return RealtimeFeature.analytics;
    }
  }
}
