/// 接続状態（契約）
enum ConnectionStatusContract { disconnected, connecting, connected, reconnecting, error }

/// リアルタイム接続の契約（抽象）
abstract class RealtimeConnectionContract {
  ConnectionStatusContract get status;
  Future<void> connect();
  Future<void> disconnect();
}
