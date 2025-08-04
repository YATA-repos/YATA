import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../data/local/cache/enhanced_cache_strategy.dart";
import "../../features/auth/presentation/providers/auth_providers.dart";
import "common_providers.dart";

part "intelligent_cache_providers.g.dart";

/// インテリジェントキャッシュ管理プロバイダー
@riverpod
class IntelligentCacheManager extends _$IntelligentCacheManager {
  final Map<String, Timer> _refreshTimers = <String, Timer>{};
  final Map<String, DateTime> _lastAccess = <String, DateTime>{};
  final Map<String, EnhancedCacheConfig> _cacheConfigs = <String, EnhancedCacheConfig>{};

  @override
  Map<String, CacheEntry> build() => <String, CacheEntry>{};

  /// プロバイダーのキャッシュ戦略を登録
  void registerProvider(
    String providerId,
    DataType dataType, {
    EnhancedCacheConfig? customConfig,
  }) {
    final EnhancedCacheConfig config = customConfig ?? 
        EnhancedCacheConfig.forDataType(dataType);
    
    _cacheConfigs[providerId] = config;
    
    // 自動リフレッシュの設定
    if (config.autoRefresh && config.refreshInterval != null) {
      _scheduleAutoRefresh(providerId, config.refreshInterval!);
    }
  }

  /// プロバイダーのアクセス記録
  void recordAccess(String providerId) {
    _lastAccess[providerId] = DateTime.now();
    
    final CacheEntry? entry = state[providerId];
    if (entry != null) {
      state = <String, CacheEntry>{
        ...state,
        providerId: entry.copyWith(
          accessCount: entry.accessCount + 1,
          lastAccessed: DateTime.now(),
        ),
      };
    } else {
      state = <String, CacheEntry>{
        ...state,
        providerId: CacheEntry(
          providerId: providerId,
          dataType: _cacheConfigs[providerId]?.dataType ?? DataType.userDynamicData,
          accessCount: 1,
          lastAccessed: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      };
    }
  }

  /// 使用頻度の低いキャッシュを無効化
  void evictUnusedCache({Duration unusedThreshold = const Duration(minutes: 10)}) {
    final DateTime cutoff = DateTime.now().subtract(unusedThreshold);
    final List<String> toEvict = <String>[];

    for (final MapEntry<String, DateTime> entry in _lastAccess.entries) {
      if (entry.value.isBefore(cutoff)) {
        final EnhancedCacheConfig? config = _cacheConfigs[entry.key];
        if (config != null && config.priority != CachePriority.critical) {
          toEvict.add(entry.key);
        }
      }
    }

    for (final String providerId in toEvict) {
      invalidateProvider(providerId);
    }
  }

  /// 特定プロバイダーの無効化
  void invalidateProvider(String providerId) {
    // タイマーをクリーンアップ
    _refreshTimers[providerId]?.cancel();
    _refreshTimers.remove(providerId);
    
    // アクセス記録を削除
    _lastAccess.remove(providerId);
    
    // 状態から削除
    final Map<String, CacheEntry> newState = Map<String, CacheEntry>.from(state)
      ..remove(providerId);
    state = newState;

    // 実際のプロバイダー無効化は外部で実装
    // 成功メッセージの通知
    ref.read(successMessageProvider.notifier).setMessage(
      "キャッシュを無効化しました: $providerId"
    );
  }

  /// データタイプ別の一括無効化
  void invalidateByDataType(DataType dataType) {
    final List<String> toInvalidate = state.entries
        .where((MapEntry<String, CacheEntry> entry) => entry.value.dataType == dataType)
        .map((MapEntry<String, CacheEntry> entry) => entry.key)
        .toList();

    for (final String providerId in toInvalidate) {
      invalidateProvider(providerId);
    }
  }

  /// 依存関係による連動無効化
  void invalidateWithDependencies(String sourceProviderId) {
    final EnhancedCacheConfig? sourceConfig = _cacheConfigs[sourceProviderId];
    if (sourceConfig == null) {
      return;
    }

    // 直接の依存関係を無効化
    for (final String dependentId in sourceConfig.dependsOn) {
      invalidateProvider(dependentId);
    }

    // データタイプ間の連動無効化
    for (final MapEntry<String, EnhancedCacheConfig> entry in _cacheConfigs.entries) {
      if (CacheInvalidationRules.shouldInvalidateTogether(
        sourceConfig.dataType,
        entry.value.dataType,
      )) {
        invalidateProvider(entry.key);
      }
    }
  }

  /// メモリ使用量に基づく最適化
  void optimizeForMemory(double availableMemoryMB) {
    final List<MapEntry<String, CacheEntry>> sortedByPriority = state.entries.toList()
      ..sort((MapEntry<String, CacheEntry> a, MapEntry<String, CacheEntry> b) {
        final EnhancedCacheConfig? configA = _cacheConfigs[a.key];
        final EnhancedCacheConfig? configB = _cacheConfigs[b.key];
        
        final int priorityA = configA?.priority.index ?? CachePriority.normal.index;
        final int priorityB = configB?.priority.index ?? CachePriority.normal.index;
        
        return priorityB.compareTo(priorityA); // 高優先度が先
      });

    // メモリ不足の場合は低優先度から削除
    if (availableMemoryMB < 20.0) {
      for (final MapEntry<String, CacheEntry> entry in sortedByPriority.reversed) {
        final EnhancedCacheConfig? config = _cacheConfigs[entry.key];
        if (config != null && config.priority == CachePriority.low) {
          invalidateProvider(entry.key);
        }
      }
    }
  }

  /// キャッシュ統計の取得
  CacheStats getStats() {
    final Map<DataType, int> countsByType = <DataType, int>{};
    final Map<CachePriority, int> countsByPriority = <CachePriority, int>{};
    int totalAccess = 0;

    for (final CacheEntry entry in state.values) {
      countsByType[entry.dataType] = (countsByType[entry.dataType] ?? 0) + 1;
      
      final EnhancedCacheConfig? config = _cacheConfigs[entry.providerId];
      if (config != null) {
        countsByPriority[config.priority] = (countsByPriority[config.priority] ?? 0) + 1;
      }
      
      totalAccess += entry.accessCount;
    }

    return CacheStats(
      totalEntries: state.length,
      totalAccess: totalAccess,
      countsByType: countsByType,
      countsByPriority: countsByPriority,
      activeTimers: _refreshTimers.length,
    );
  }

  /// 自動リフレッシュのスケジュール
  void _scheduleAutoRefresh(String providerId, Duration interval) {
    _refreshTimers[providerId]?.cancel();
    
    _refreshTimers[providerId] = Timer.periodic(interval, (Timer timer) {
      // 最近アクセスされていない場合はリフレッシュをスキップ
      final DateTime? lastAccess = _lastAccess[providerId];
      if (lastAccess != null && 
          DateTime.now().difference(lastAccess) > const Duration(minutes: 30)) {
        return;
      }

      // プロバイダーの無効化でリフレッシュをトリガー
      invalidateProvider(providerId);
    });
  }

  /// リソースのクリーンアップ
  void dispose() {
    for (final Timer timer in _refreshTimers.values) {
      timer.cancel();
    }
    _refreshTimers.clear();
    _lastAccess.clear();
    _cacheConfigs.clear();
  }
}

/// キャッシュエントリー
class CacheEntry {
  const CacheEntry({
    required this.providerId,
    required this.dataType,
    required this.accessCount,
    required this.lastAccessed,
    required this.createdAt,
  });

  final String providerId;
  final DataType dataType;
  final int accessCount;
  final DateTime lastAccessed;
  final DateTime createdAt;

  CacheEntry copyWith({
    String? providerId,
    DataType? dataType,
    int? accessCount,
    DateTime? lastAccessed,
    DateTime? createdAt,
  }) => CacheEntry(
    providerId: providerId ?? this.providerId,
    dataType: dataType ?? this.dataType,
    accessCount: accessCount ?? this.accessCount,
    lastAccessed: lastAccessed ?? this.lastAccessed,
    createdAt: createdAt ?? this.createdAt,
  );
}

/// キャッシュ統計
class CacheStats {
  const CacheStats({
    required this.totalEntries,
    required this.totalAccess,
    required this.countsByType,
    required this.countsByPriority,
    required this.activeTimers,
  });

  final int totalEntries;
  final int totalAccess;
  final Map<DataType, int> countsByType;
  final Map<CachePriority, int> countsByPriority;
  final int activeTimers;

  double get averageAccessPerEntry => 
      totalEntries > 0 ? totalAccess / totalEntries : 0.0;
}

/// スマートキャッシュ制御プロバイダー
@riverpod
class SmartCacheController extends _$SmartCacheController {
  Timer? _optimizationTimer;

  @override
  bool build() {
    ref.keepAlive(); // コントローラーは永続化
    
    // 定期的な最適化を開始
    _startPeriodicOptimization();
    
    return true;
  }

  /// 定期最適化を開始
  void _startPeriodicOptimization() {
    _optimizationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performOptimization(),
    );
  }

  /// 最適化実行
  void _performOptimization() {
    // 使用されていないキャッシュを削除とメモリ最適化
    ref.read(intelligentCacheManagerProvider.notifier)
      ..evictUnusedCache()
      ..optimizeForMemory(30.0); // 30MB available と仮定
  }

  /// 手動最適化トリガー
  void triggerOptimization() {
    _performOptimization();
  }

  /// ユーザー変更時の全キャッシュクリア
  void clearUserCache() {
    ref.read(intelligentCacheManagerProvider.notifier)
      ..invalidateByDataType(DataType.userDynamicData)
      ..invalidateByDataType(DataType.userSemiStaticData);
  }

  void dispose() {
    _optimizationTimer?.cancel();
  }
}

/// プロバイダー登録用ミックスイン
mixin SmartCacheMixin {
  /// プロバイダーをスマートキャッシュに登録
  void registerWithSmartCache(
    Ref ref,
    String providerId,
    DataType dataType, {
    EnhancedCacheConfig? customConfig,
  }) {
    ref.read(intelligentCacheManagerProvider.notifier)
      .registerProvider(providerId, dataType, customConfig: customConfig);
  }

  /// アクセス記録
  void recordCacheAccess(Ref ref, String providerId) {
    ref.read(intelligentCacheManagerProvider.notifier)
      .recordAccess(providerId);
  }
}

/// ユーザー認証変更監視プロバイダー
@riverpod
class AuthChangeWatcher extends _$AuthChangeWatcher {
  @override
  String? build() {
    final String? currentUserId = ref.watch(currentUserIdProvider);
    
    // ユーザー変更時にキャッシュクリア
    ref.listen<String?>(currentUserIdProvider, (String? previous, String? current) {
      if (previous != null && previous != current) {
        ref.read(smartCacheControllerProvider.notifier)
          .clearUserCache();
      }
    });
    
    return currentUserId;
  }
}