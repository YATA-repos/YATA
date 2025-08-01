import "../logging/logger_mixin.dart";
import "realtime_config.dart";
import "realtime_manager.dart";

/// Service層でのリアルタイム機能統合Mixin
/// 
/// **重要**: このMixinはService層でのみ使用可能
/// 直線的依存関係維持のため、UI層・Provider層からの直接使用は禁止
/// 
/// **使用方法**:
/// ```dart
/// class InventoryService with RealtimeServiceMixin {
///   @override
///   String? get currentUserId => _authService.currentUserId;
///   
///   @override
///   Future<void> startRealtimeMonitoring() async {
///     // 実装
///   }
/// }
/// ```
mixin RealtimeServiceMixin on LoggerMixin {
  
  /// RealtimeManagerインスタンス（Service層専用アクセス）
  RealtimeManager get _realtimeManager => RealtimeManager();

  /// 現在のユーザーID取得（サブクラスで実装必須）
  /// マルチテナント対応のため
  String? get currentUserId;

  /// サービス名取得（サブクラスで実装推奨）
  /// ログとサブスクリプションIDの識別用
  String get serviceName => runtimeType.toString();

  /// リアルタイム監視開始
  /// 各Serviceクラスで特化した実装を行う抽象メソッド
  Future<void> startRealtimeMonitoring();

  /// リアルタイム監視停止
  /// 各Serviceクラスで特化した実装を行う抽象メソッド
  Future<void> stopRealtimeMonitoring();

  /// サブスクリプションID生成
  /// 機能とユーザーで一意性確保
  String generateSubscriptionId(RealtimeFeature feature) {
    final String userPart = currentUserId ?? "anonymous";
    final String servicePart = serviceName.toLowerCase();
    return "${servicePart}_${feature.name}_$userPart";
  }

  /// 機能別リアルタイム監視開始ヘルパー
  /// Service層での標準的な監視開始パターン
  Future<void> startFeatureMonitoring(
    RealtimeFeature feature,
    String tableName,
    void Function(Map<String, dynamic>) onData, {
    Map<String, dynamic>? filters,
    List<String>? eventTypes,
  }) async {
    try {
      final RealtimeConfig config = RealtimeConfig(
        feature: feature,
        tableName: tableName,
        filters: _buildFilters(filters),
        eventTypes: eventTypes ?? const <String>["INSERT", "UPDATE", "DELETE"],
      );

      final String subscriptionId = generateSubscriptionId(feature);

      await _realtimeManager.startMonitoring(
        config,
        subscriptionId,
        (Map<String, dynamic> data) {
          try {
            logDebug("$serviceName: Received ${feature.name} update");
            onData(data);
          } catch (e) {
            logError("$serviceName: Error processing ${feature.name} update", e);
          }
        },
      );

      logInfo("$serviceName: Started monitoring ${feature.name}");
    } catch (e) {
      logError("$serviceName: Failed to start ${feature.name} monitoring", e);
      rethrow;
    }
  }

  /// 機能別リアルタイム監視停止ヘルパー
  Future<void> stopFeatureMonitoring(RealtimeFeature feature) async {
    try {
      final String subscriptionId = generateSubscriptionId(feature);
      await _realtimeManager.stopMonitoring(subscriptionId);
      logInfo("$serviceName: Stopped monitoring ${feature.name}");
    } catch (e) {
      logError("$serviceName: Failed to stop ${feature.name} monitoring", e);
      rethrow;
    }
  }

  /// フィルター条件構築
  /// ユーザーIDを自動的に追加
  Map<String, dynamic>? _buildFilters(Map<String, dynamic>? additionalFilters) {
    final Map<String, dynamic> filters = <String, dynamic>{};

    // ユーザーIDフィルター（マルチテナント対応）
    if (currentUserId != null) {
      filters["user_id"] = currentUserId!;
    }

    // 追加フィルター
    if (additionalFilters != null) {
      filters.addAll(additionalFilters);
    }

    return filters.isEmpty ? null : filters;
  }

  /// リアルタイム監視状態確認
  bool isMonitoringFeature(RealtimeFeature feature) {
    final String subscriptionId = generateSubscriptionId(feature);
    return _realtimeManager.isMonitoring(subscriptionId);
  }

  /// 全機能の監視停止（Service終了時用）
  Future<void> stopAllMonitoring() async {
    try {
      // このServiceが作成した全サブスクリプションを停止
      final List<String> activeSubscriptions = _realtimeManager.getActiveSubscriptions();
      final String servicePrefix = serviceName.toLowerCase();
      
      for (final String subscriptionId in activeSubscriptions) {
        if (subscriptionId.startsWith(servicePrefix)) {
          await _realtimeManager.stopMonitoring(subscriptionId);
        }
      }
      
      logInfo("$serviceName: Stopped all monitoring");
    } catch (e) {
      logError("$serviceName: Failed to stop all monitoring", e);
      rethrow;
    }
  }

  /// リアルタイム統計情報取得（デバッグ用）
  Map<String, dynamic> getRealtimeStats() {
    final Map<String, dynamic> stats = _realtimeManager.getStats();
    logDebug("$serviceName: Realtime stats - $stats");
    return stats;
  }

  /// リアルタイム接続の健全性確認
  bool isRealtimeHealthy() {
    final Map<String, dynamic> stats = _realtimeManager.getStats();
    final String status = stats["status"] as String? ?? "unknown";
    return status == "connected";
  }
}

/// Service層でのリアルタイム機能制御インターフェース
/// UI層からService層へのリアルタイム制御要求用
abstract interface class RealtimeServiceControl {
  /// リアルタイム機能の有効化
  Future<void> enableRealtimeFeatures();

  /// リアルタイム機能の無効化
  Future<void> disableRealtimeFeatures();

  /// 特定機能のリアルタイム監視状態確認
  bool isFeatureRealtimeEnabled(RealtimeFeature feature);

  /// リアルタイム接続状態確認
  bool isRealtimeConnected();

  /// リアルタイム統計情報取得
  Map<String, dynamic> getRealtimeInfo();
}