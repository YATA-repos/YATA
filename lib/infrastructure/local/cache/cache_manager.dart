import "dart:async";

import "../../../core/logging/logger_mixin.dart";
import "cache_config.dart";
import "cache_strategy.dart";
import "memory_cache.dart";
import "ttl_cache.dart";

/// YATAアーキテクチャ準拠キャッシュマネージャー
/// 
/// **重要**: このクラスはRepository層でのみ使用可能
/// 直線的依存関係維持のため、UI層・Service層からの直接アクセスは禁止
class CacheManager with LoggerMixin {
  /// ファクトリーコンストラクタ
  /// Repository層専用 - 他の層からのアクセスは設計違反
  factory CacheManager() => _instance;
  
  CacheManager._internal() {
    _memoryCache = MemoryCache();
    _ttlCache = TTLCache();
    _initializeCleanupTimer();
  }

  // シングルトンパターン - Repository層からのみアクセス可能
  static final CacheManager _instance = CacheManager._internal();

  late final MemoryCache _memoryCache;
  late final TTLCache _ttlCache;
  Timer? _cleanupTimer;

  @override
  String get loggerComponent => "CacheManager";

  /// 初期化 - アプリ起動時に一度だけ実行
  void initialize() {
    logInfo("CacheManager initialized");
  }

  /// キャッシュ取得
  /// Repository層専用メソッド
  Future<T?> get<T>(String key, CacheConfig config) async {
    try {
      switch (config.strategy) {
        case CacheStrategy.noCache:
          return null;
          
        case CacheStrategy.memoryOnly:
        case CacheStrategy.shortTerm:
        case CacheStrategy.longTerm:
          return _memoryCache.get<T>(key);
          
        case CacheStrategy.persistent:
          // TTLキャッシュから取得（永続化対応）
          return _ttlCache.get<T>(key);
      }
    } catch (e) {
      logError("Failed to get cache for key: $key", e);
      return null;
    }
  }

  /// キャッシュ設定
  /// Repository層専用メソッド
  Future<void> set<T>(String key, T value, CacheConfig config) async {
    try {
      switch (config.strategy) {
        case CacheStrategy.noCache:
          return; // キャッシュしない
          
        case CacheStrategy.memoryOnly:
        case CacheStrategy.shortTerm:
        case CacheStrategy.longTerm:
          _memoryCache.set(key, value, config.ttl);
          logDebug("Cached to memory: $key (TTL: ${config.ttl})");
          break;
          
        case CacheStrategy.persistent:
          await _ttlCache.set(key, value, config.ttl);
          logDebug("Cached persistently: $key (TTL: ${config.ttl})");
          break;
      }
    } catch (e) {
      logError("Failed to set cache for key: $key", e);
    }
  }

  /// 単一キーの無効化
  /// Repository層専用メソッド
  Future<void> invalidate(String key) async {
    try {
      _memoryCache.remove(key);
      await _ttlCache.remove(key);
      logDebug("Invalidated cache: $key");
    } catch (e) {
      logError("Failed to invalidate cache for key: $key", e);
    }
  }

  /// パターンベース無効化（関連データ連動）
  /// Repository層専用メソッド
  Future<void> invalidatePattern(String pattern) async {
    try {
      _memoryCache.removePattern(pattern);
      await _ttlCache.removePattern(pattern);
      logDebug("Invalidated cache pattern: $pattern");
    } catch (e) {
      logError("Failed to invalidate cache pattern: $pattern", e);
    }
  }

  /// ユーザー固有キャッシュの無効化
  /// 認証状態変更時に使用
  Future<void> invalidateUserData(String userId) async {
    await invalidatePattern("user:$userId:*");
    logInfo("Invalidated user data cache: $userId");
  }

  /// 全キャッシュクリア
  /// 緊急時・デバッグ用途
  Future<void> clearAll() async {
    try {
      _memoryCache.clear();
      await _ttlCache.clear();
      logInfo("All cache cleared");
    } catch (e) {
      logError("Failed to clear all cache", e);
    }
  }

  /// キャッシュ統計情報取得
  Map<String, dynamic> getStats() => <String, dynamic>{
    "memory_items": _memoryCache.itemCount,
    "memory_size_mb": _memoryCache.estimatedSizeMB,
    "ttl_items": _ttlCache.itemCount,
  };

  /// クリーンアップタイマー初期化
  void _initializeCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (Timer timer) => _performCleanup());
  }

  /// 定期クリーンアップ実行
  void _performCleanup() {
    try {
      _memoryCache.cleanup();
      _ttlCache.cleanup();
      logDebug("Cache cleanup completed");
    } catch (e) {
      logError("Failed to perform cache cleanup", e);
    }
  }

  /// リソース解放
  void dispose() {
    _cleanupTimer?.cancel();
    _memoryCache.clear();
    logInfo("CacheManager disposed");
  }
}