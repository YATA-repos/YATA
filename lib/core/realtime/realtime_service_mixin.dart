import "../contracts/realtime/realtime_manager.dart" as contract;
import "../logging/compat.dart" as log;

/// Service層で契約ベースのリアルタイム機能を提供するMixin
mixin RealtimeServiceContractMixin {
  /// Realtimeマネージャ契約（実装はアプリ側DIで注入）
  contract.RealtimeManagerContract get realtimeManager;

  /// 現在のユーザーID（マルチテナント用）
  String? get currentUserId;

  /// サービス名（サブスクリプション識別・ログ用）
  String get serviceName => runtimeType.toString();

  /// リアルタイム監視開始（機能名ベース）
  Future<void> startFeatureMonitoring(
    String featureName,
    String tableName,
    contract.RealtimeDataCallback onData, {
    Map<String, dynamic>? filters,
    List<String>? eventTypes,
  }) async {
    final contract.RealtimeSubscriptionConfig cfg = contract.RealtimeSubscriptionConfig(
      featureName: featureName,
      tableName: tableName,
      filters: _buildFilters(filters),
      eventTypes: eventTypes ?? const <String>["INSERT", "UPDATE", "DELETE"],
    );

    final String subscriptionId = generateSubscriptionId(featureName);
    await realtimeManager.startMonitoring(cfg, subscriptionId, (Map<String, dynamic> data) {
      try {
        log.d("$serviceName: Received $featureName update", tag: serviceName);
        onData(data);
      } catch (e) {
        log.e("$serviceName: Error processing $featureName update", error: e, tag: serviceName);
      }
    });

    log.i("$serviceName: Started monitoring $featureName", tag: serviceName);
  }

  /// リアルタイム監視停止
  Future<void> stopFeatureMonitoring(String featureName) async {
    final String subscriptionId = generateSubscriptionId(featureName);
    await realtimeManager.stopMonitoring(subscriptionId);
    log.i("$serviceName: Stopped monitoring $featureName", tag: serviceName);
  }

  /// 監視状態確認
  bool isMonitoringFeature(String featureName) {
    final String subscriptionId = generateSubscriptionId(featureName);
    return realtimeManager.isMonitoring(subscriptionId);
  }

  /// 全監視停止（当該サービスが開始したもののみ）
  Future<void> stopAllMonitoring() async {
    final List<String> active = realtimeManager.getActiveSubscriptions();
    final String prefix = serviceName.toLowerCase();
    for (final String id in active) {
      if (id.startsWith(prefix)) {
        await realtimeManager.stopMonitoring(id);
      }
    }
    log.i("$serviceName: Stopped all monitoring", tag: serviceName);
  }

  /// 統計情報取得
  Map<String, dynamic> getRealtimeStats() => realtimeManager.getStats();

  /// 健全性確認
  bool isRealtimeHealthy() {
    final String status = realtimeManager.getStats()["status"] as String? ?? "unknown";
    return status == "connected";
  }

  /// サブスクリプションID生成（機能名 + ユーザー + サービス名）
  String generateSubscriptionId(String featureName) {
    final String userPart = currentUserId ?? "anonymous";
    final String servicePart = serviceName.toLowerCase();
    return "${servicePart}_${featureName}_$userPart";
  }

  Map<String, dynamic>? _buildFilters(Map<String, dynamic>? additional) {
    final Map<String, dynamic> f = <String, dynamic>{};
    if (currentUserId != null) {
      f["user_id"] = currentUserId!;
    }
    if (additional != null) {
      f.addAll(additional);
    }
    return f.isEmpty ? null : f;
  }
}

/// UI→Serviceの制御用契約インターフェース
abstract interface class RealtimeServiceControl {
  Future<void> enableRealtimeFeatures();
  Future<void> disableRealtimeFeatures();
  bool isFeatureRealtimeEnabled(String featureName);
  bool isRealtimeConnected();
  Map<String, dynamic> getRealtimeInfo();
}
