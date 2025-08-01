import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../cache/cache_manager.dart";

part "cache_providers.g.dart";

/// キャッシュ関連プロバイダー

/// グローバルキャッシュ制御プロバイダー
@riverpod
class GlobalCacheControl extends _$GlobalCacheControl {
  @override
  bool build() {
    ref.keepAlive(); // キャッシュ設定は永続化
    return true; // デフォルトでキャッシュ有効
  }

  /// 全キャッシュクリア
  Future<void> clearAllCache() async {
    final CacheManager cacheManager = CacheManager();
    await cacheManager.clearAll();
    
    // 統計プロバイダーに通知
    ref.read(cacheStatusProvider.notifier).notifyCacheCleared();
  }

  /// キャッシュ有効化
  void enableCache() {
    state = true;
  }

  /// キャッシュ無効化
  void disableCache() {
    state = false;
  }
}

/// キャッシュ状態プロバイダー（既存のcommon_providers.dartから移動予定）
/// 一時的に基本実装を提供
@riverpod
class CacheStatus extends _$CacheStatus {
  @override
  CacheStatusInfo build() {
    ref.keepAlive();
    return const CacheStatusInfo();
  }

  /// キャッシュクリア完了通知
  void notifyCacheCleared() {
    state = state.copyWith(
      memoryItems: 0,
      ttlItems: 0,
      lastCleared: DateTime.now(),
    );
  }

  /// キャッシュ統計更新
  void updateStats(Map<String, dynamic> stats) {
    state = state.copyWith(
      memoryItems: stats["memory_items"] as int? ?? 0,
      memorySizeMB: stats["memory_size_mb"] as double? ?? 0.0,
      ttlItems: stats["ttl_items"] as int? ?? 0,
      lastUpdated: DateTime.now(),
    );
  }
}

class CacheStatusInfo {
  const CacheStatusInfo({
    this.enabled = true,
    this.memoryItems = 0,
    this.memorySizeMB = 0.0,
    this.ttlItems = 0,
    this.lastUpdated,
    this.lastCleared,
  });

  final bool enabled;
  final int memoryItems;
  final double memorySizeMB;
  final int ttlItems;
  final DateTime? lastUpdated;
  final DateTime? lastCleared;

  CacheStatusInfo copyWith({
    bool? enabled,
    int? memoryItems,
    double? memorySizeMB,
    int? ttlItems,
    DateTime? lastUpdated,
    DateTime? lastCleared,
  }) => CacheStatusInfo(
    enabled: enabled ?? this.enabled,
    memoryItems: memoryItems ?? this.memoryItems,
    memorySizeMB: memorySizeMB ?? this.memorySizeMB,
    ttlItems: ttlItems ?? this.ttlItems,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    lastCleared: lastCleared ?? this.lastCleared,
  );
}

/// キャッシュサイズ監視プロバイダー
@riverpod
class CacheSizeMonitor extends _$CacheSizeMonitor {
  @override
  CacheSizeInfo build() {
    ref.keepAlive();
    
    // 定期的なサイズ監視開始
    _startSizeMonitoring();
    
    return const CacheSizeInfo();
  }

  void _startSizeMonitoring() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      _updateCacheSize();
    });
  }

  Future<void> _updateCacheSize() async {
    final CacheManager cacheManager = CacheManager();
    final Map<String, dynamic> stats = cacheManager.getStats();
    
    state = CacheSizeInfo(
      memoryItems: stats["memory_items"] as int,
      memorySizeMB: stats["memory_size_mb"] as double,
      ttlItems: stats["ttl_items"] as int,
      lastUpdated: DateTime.now(),
    );

    // サイズ制限チェック
    if (state.memorySizeMB > 50.0) { // 50MB制限
      // ignore: unawaited_futures
      _handleCacheSizeLimit();
    }
  }

  Future<void> _handleCacheSizeLimit() async {
    // キャッシュサイズ制限に達した場合の処理
    // 1. 警告ログ
    // 2. 古いキャッシュの削除
    // 3. ユーザー通知（必要に応じて）
    // 実装は後続のフェーズで追加
  }
}

class CacheSizeInfo {
  const CacheSizeInfo({
    this.memoryItems = 0,
    this.memorySizeMB = 0.0,
    this.ttlItems = 0,
    this.lastUpdated,
  });

  final int memoryItems;
  final double memorySizeMB;
  final int ttlItems;
  final DateTime? lastUpdated;

  bool get isOverLimit => memorySizeMB > 50.0;

  CacheSizeInfo copyWith({
    int? memoryItems,
    double? memorySizeMB,
    int? ttlItems,
    DateTime? lastUpdated,
  }) => CacheSizeInfo(
    memoryItems: memoryItems ?? this.memoryItems,
    memorySizeMB: memorySizeMB ?? this.memorySizeMB,
    ttlItems: ttlItems ?? this.ttlItems,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}