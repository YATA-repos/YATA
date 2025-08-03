import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../data/realtime/realtime_manager.dart";

part "realtime_providers.g.dart";

/// リアルタイム関連プロバイダー

/// グローバルリアルタイム制御プロバイダー
@riverpod
class GlobalRealtimeControl extends _$GlobalRealtimeControl {
  @override
  bool build() {
    ref.keepAlive(); // リアルタイム設定は永続化
    return false; // デフォルトで無効（ユーザー選択）
  }

  Future<void> enableRealtime() async {
    // 全Serviceのリアルタイム機能を有効化
    // Service層経由で制御
    state = true;
  }

  Future<void> disableRealtime() async {
    // 全Serviceのリアルタイム機能を無効化
    final RealtimeManager realtimeManager = RealtimeManager();
    await realtimeManager.stopAllMonitoring();
    state = false;
  }
}

/// リアルタイム接続統計プロバイダー
@riverpod
class RealtimeConnectionStats extends _$RealtimeConnectionStats {
  @override
  ConnectionStatsInfo build() {
    ref.keepAlive();
    
    // 定期的な統計更新
    _startStatsUpdate();
    
    return const ConnectionStatsInfo();
  }

  void _startStatsUpdate() {
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (ref.read(globalRealtimeControlProvider)) {
        _updateStats();
      }
    });
  }

  void _updateStats() {
    final RealtimeManager realtimeManager = RealtimeManager();
    final Map<String, dynamic> stats = realtimeManager.getStats();
    
    state = ConnectionStatsInfo(
      activeConnections: stats["active_subscriptions"] as int,
      connectionStatus: stats["status"] as String,
      lastReconnect: stats["last_reconnect"] as String?,
      lastUpdated: DateTime.now(),
    );
  }
}

class ConnectionStatsInfo {
  const ConnectionStatsInfo({
    this.activeConnections = 0,
    this.connectionStatus = "disconnected",
    this.lastReconnect,
    this.lastUpdated,
  });

  final int activeConnections;
  final String connectionStatus;
  final String? lastReconnect;
  final DateTime? lastUpdated;

  bool get isConnected => connectionStatus == "connected";

  ConnectionStatsInfo copyWith({
    int? activeConnections,
    String? connectionStatus,
    String? lastReconnect,
    DateTime? lastUpdated,
  }) => ConnectionStatsInfo(
    activeConnections: activeConnections ?? this.activeConnections,
    connectionStatus: connectionStatus ?? this.connectionStatus,
    lastReconnect: lastReconnect ?? this.lastReconnect,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}