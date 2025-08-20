import "../../core/constants/app_constants.dart";

/// リアルタイム機能列挙型
enum RealtimeFeature {
  /// 在庫管理
  inventory,
  
  /// 注文管理  
  orders,
  
  /// メニュー管理
  menu,
  
  /// 分析データ
  analytics,
}

/// リアルタイム設定クラス
class RealtimeConfig {
  const RealtimeConfig({
    required this.feature,
    required this.tableName,
    this.filters,
    this.eventTypes = AppConstants.defaultRealtimeEventTypes,
    this.autoReconnect = true,
    this.maxReconnectAttempts = AppConstants.maxReconnectAttempts,
    this.reconnectDelay = const Duration(seconds: AppConstants.reconnectDelaySeconds),
  });

  /// リアルタイム機能種別
  final RealtimeFeature feature;
  
  /// 監視するテーブル名
  final String tableName;
  
  /// フィルター条件（ユーザーID等）
  final Map<String, dynamic>? filters;
  
  /// 監視するイベントタイプ
  final List<String> eventTypes;
  
  /// 自動再接続フラグ
  final bool autoReconnect;
  
  /// 最大再接続試行回数
  final int maxReconnectAttempts;
  
  /// 再接続遅延時間
  final Duration reconnectDelay;

  /// デバッグ用文字列表現
  @override
  String toString() => "RealtimeConfig(${feature.name}:$tableName)";

  /// 設定の等価性確認
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealtimeConfig &&
          runtimeType == other.runtimeType &&
          feature == other.feature &&
          tableName == other.tableName;

  @override
  int get hashCode => feature.hashCode ^ tableName.hashCode;
}