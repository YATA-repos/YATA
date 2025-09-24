import "dart:async";

import "package:supabase_flutter/supabase_flutter.dart";

// Using final logging API directly
import "../../infra/logging/logger.dart" as log;
import "../supabase/supabase_client.dart";
import "realtime_config.dart";

/// 接続状態列挙型
enum ConnectionStatus {
  /// 未接続
  disconnected,

  /// 接続中
  connecting,

  /// 接続済み
  connected,

  /// 再接続中
  reconnecting,

  /// エラー状態
  error,
}

/// Supabase Realtimeの接続管理クラス
/// RealtimeManagerから使用される内部クラス
class ConnectionManager {
  ConnectionManager();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  DateTime? _lastReconnect;
  int _reconnectAttempts = 0;
  final Map<String, RealtimeChannel> _activeChannels = <String, RealtimeChannel>{};

  // String get loggerComponent => "ConnectionManager"; // deprecated

  /// 現在の接続状態
  ConnectionStatus get status => _status;

  /// 最終再接続日時
  DateTime? get lastReconnect => _lastReconnect;

  /// アクティブチャンネル数
  int get activeChannelCount => _activeChannels.length;

  /// Supabaseクライアント取得
  SupabaseClient get _client => SupabaseClientService.client;

  /// リアルタイムチャンネル作成
  Future<RealtimeChannel> createChannel(RealtimeConfig config) async {
    try {
      _status = ConnectionStatus.connecting;
      log.i("Creating realtime channel for ${config.feature.name}");

      // チャンネル名生成（機能とテーブル名から）
      final String channelName = "${config.feature.name}_${config.tableName}";

      // 既存チャンネルがあれば再利用
      if (_activeChannels.containsKey(channelName)) {
        log.d("Reusing existing channel: $channelName");
        return _activeChannels[channelName]!;
      }

      // 新しいチャンネル作成
      final RealtimeChannel channel = _client.channel(channelName);

      // チャンネル設定
      await _configureChannel(channel, config);

      // チャンネル登録
      _activeChannels[channelName] = channel;

      _status = ConnectionStatus.connected;
      _reconnectAttempts = 0;

      log.i("Realtime channel created: $channelName");
      return channel;
    } catch (e) {
      _status = ConnectionStatus.error;
      log.e("Failed to create realtime channel for ${config.feature.name}", error: e);
      rethrow;
    }
  }

  /// チャンネル設定
  Future<void> _configureChannel(RealtimeChannel channel, RealtimeConfig config) async {
    log.d("Configuring channel for ${config.tableName}");

    // 基本的なPostgres変更リスナーを追加
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: "public",
      table: config.tableName,
      callback: (PostgresChangePayload payload) {
        log.d("Received realtime event: ${payload.eventType} on ${config.tableName}");
        // ここで実際のデータ処理は行わず、ログのみ出力
      },
    );

    log.d("Channel configured for ${config.tableName}");
  }

  /// チャンネル閉鎖
  Future<void> closeChannel(RealtimeChannel channel) async {
    try {
      log.i("Closing realtime channel");

      // チャンネル登録から削除
      _activeChannels.removeWhere((String key, RealtimeChannel value) => value == channel);

      // チャンネル解除
      await channel.unsubscribe();

      // 全チャンネルが閉鎖された場合
      if (_activeChannels.isEmpty) {
        _status = ConnectionStatus.disconnected;
        log.i("All channels closed - disconnected");
      }
    } catch (e) {
      log.e("Failed to close realtime channel", error: e);
      rethrow;
    }
  }

  /// 全チャンネル閉鎖
  Future<void> closeAllChannels() async {
    final List<RealtimeChannel> channels = _activeChannels.values.toList();

    for (final RealtimeChannel channel in channels) {
      await closeChannel(channel);
    }

    _activeChannels.clear();
    _status = ConnectionStatus.disconnected;
    log.i("All realtime channels closed");
  }

  /// 接続統計情報取得
  Map<String, dynamic> getConnectionStats() => <String, dynamic>{
    "status": status.name,
    "active_channels": activeChannelCount,
    "reconnect_attempts": _reconnectAttempts,
    "last_reconnect": lastReconnect?.toIso8601String(),
  };

  /// リソース解放
  Future<void> dispose() async {
    await closeAllChannels();
    log.i("ConnectionManager disposed");
  }
}
