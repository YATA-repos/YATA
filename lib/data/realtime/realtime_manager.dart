import "dart:async";

import "package:supabase_flutter/supabase_flutter.dart";

import "../../core/logging/logger_mixin.dart";
import "connection_manager.dart";
import "realtime_config.dart";

/// データ更新コールバック関数の型定義
typedef RealtimeDataCallback = void Function(Map<String, dynamic> data);

/// YATAアーキテクチャ準拠リアルタイムマネージャー
/// Service層からのみアクセス可能
/// 直線的依存関係維持のため、UI層・Provider層からの直接アクセスは禁止
class RealtimeManager with LoggerMixin {
  /// ファクトリーコンストラクタ
  /// Service層専用 - 他の層からのアクセスは設計違反
  factory RealtimeManager() => _instance;
  
  RealtimeManager._internal() {
    _connectionManager = ConnectionManager();
  }

  // シングルトンパターン - Service層からのみアクセス可能
  static final RealtimeManager _instance = RealtimeManager._internal();

  late final ConnectionManager _connectionManager;
  final Map<String, _SubscriptionInfo> _subscriptions = <String, _SubscriptionInfo>{};

  @override
  String get loggerComponent => "RealtimeManager";

  /// リアルタイム監視開始
  /// Service層から呼び出し
  Future<void> startMonitoring(
    RealtimeConfig config,
    String subscriptionId,
    RealtimeDataCallback onData,
  ) async {
    try {
      logInfo("Starting realtime monitoring: ${config.feature.name} ($subscriptionId)");
      
      // 既存サブスクリプションの確認
      if (_subscriptions.containsKey(subscriptionId)) {
        logWarning("Subscription already exists: $subscriptionId");
        return;
      }

      // チャンネル作成
      final RealtimeChannel channel = await _connectionManager.createChannel(config);
      
      // サブスクリプション情報を保存
      _subscriptions[subscriptionId] = _SubscriptionInfo(
        config: config,
        channel: channel,
        callback: onData,
      );

      // チャンネル購読開始
      await _subscribeToChannel(channel, config, onData);

      logInfo("Realtime monitoring started: $subscriptionId");
    } catch (e) {
      logError("Failed to start realtime monitoring: $subscriptionId", e);
      // エラー時はサブスクリプション情報を削除
      _subscriptions.remove(subscriptionId);
      rethrow;
    }
  }

  /// チャンネル購読処理
  Future<void> _subscribeToChannel(
    RealtimeChannel channel,
    RealtimeConfig config,
    RealtimeDataCallback onData,
  ) async {
    // Postgres変更イベントの監視とチャンネル購読
    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: "public",
        table: config.tableName,
        callback: (PostgresChangePayload payload) {
          try {
            logDebug("Received ${payload.eventType} event on ${config.tableName}");
            
            // イベントタイプのフィルタリング
            if (!config.eventTypes.contains(payload.eventType.name)) {
              logDebug("Event type ${payload.eventType.name} filtered out");
              return;
            }

            // データの構築
            final Map<String, dynamic> eventData = <String, dynamic>{
              "event_type": payload.eventType.name,
              "table": payload.table,
              "schema": payload.schema,
              "old_record": payload.oldRecord,
              "new_record": payload.newRecord,
              "timestamp": DateTime.now().toIso8601String(),
            };

            // コールバック実行
            onData(eventData);
          } catch (e) {
            logError("Error processing realtime event", e);
          }
        },
      )
      ..subscribe();
    
    logDebug("Subscribed to channel for ${config.tableName}");
  }

  /// リアルタイム監視停止
  Future<void> stopMonitoring(String subscriptionId) async {
    final _SubscriptionInfo? subscription = _subscriptions[subscriptionId];
    if (subscription == null) {
      logWarning("Subscription not found: $subscriptionId");
      return;
    }

    try {
      logInfo("Stopping realtime monitoring: $subscriptionId");
      
      // チャンネル閉鎖
      await _connectionManager.closeChannel(subscription.channel);
      
      // サブスクリプション削除
      _subscriptions.remove(subscriptionId);
      
      logInfo("Realtime monitoring stopped: $subscriptionId");
    } catch (e) {
      logError("Failed to stop realtime monitoring: $subscriptionId", e);
      rethrow;
    }
  }

  /// 全監視停止
  Future<void> stopAllMonitoring() async {
    logInfo("Stopping all realtime monitoring");
    
    final List<String> subscriptionIds = _subscriptions.keys.toList();
    
    for (final String subscriptionId in subscriptionIds) {
      try {
        await stopMonitoring(subscriptionId);
      } catch (e) {
        logError("Failed to stop monitoring: $subscriptionId", e);
      }
    }
    
    logInfo("All realtime monitoring stopped");
  }

  /// 監視状態確認
  bool isMonitoring(String subscriptionId) => _subscriptions.containsKey(subscriptionId);

  /// アクティブなサブスクリプション一覧取得
  List<String> getActiveSubscriptions() => _subscriptions.keys.toList();

  /// 特定機能の監視状態確認
  bool isFeatureMonitoring(RealtimeFeature feature) =>
      _subscriptions.values.any((_SubscriptionInfo info) => info.config.feature == feature);

  /// 統計情報取得
  Map<String, dynamic> getStats() {
    final Map<String, dynamic> connectionStats = _connectionManager.getConnectionStats();
    
    return <String, dynamic>{
      ...connectionStats,
      "active_subscriptions": _subscriptions.length,
      "subscriptions_by_feature": _getSubscriptionsByFeature(),
    };
  }

  /// 機能別サブスクリプション数取得
  Map<String, int> _getSubscriptionsByFeature() {
    final Map<String, int> counts = <String, int>{};
    
    for (final _SubscriptionInfo info in _subscriptions.values) {
      final String featureName = info.config.feature.name;
      counts[featureName] = (counts[featureName] ?? 0) + 1;
    }
    
    return counts;
  }

  /// リソース解放
  Future<void> dispose() async {
    await stopAllMonitoring();
    await _connectionManager.dispose();
    logInfo("RealtimeManager disposed");
  }
}

/// サブスクリプション情報内部クラス
class _SubscriptionInfo {
  _SubscriptionInfo({
    required this.config,
    required this.channel,
    required this.callback,
  });

  final RealtimeConfig config;
  final RealtimeChannel channel;
  final RealtimeDataCallback callback;

  @override
  String toString() => "SubscriptionInfo(${config.feature.name}:${config.tableName})";
}