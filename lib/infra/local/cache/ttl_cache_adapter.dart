import "dart:async";

import "../../../core/contracts/cache/cache.dart" as contract;
import "../../../core/contracts/cache/cache_metadata.dart";
import "ttl_cache.dart";

/// `TTLCache` を core 契約 `Cache<String, V>` にブリッジするアダプタ
class TTLCacheAdapter<V> implements contract.Cache<String, V> {
  TTLCacheAdapter() : _impl = TTLCache();

  final TTLCache _impl;

  @override
  Future<V?> get(String key) => _impl.get<V>(key);

  @override
  Future<void> set(String key, V value, Duration ttl) => _impl.set<V>(key, value, ttl);

  @override
  Future<void> remove(String key) => _impl.remove(key);

  @override
  Future<void> removePattern(String pattern) => _impl.removePattern(pattern);

  @override
  Future<void> clear() => _impl.clear();

  @override
  Future<CacheStatistics?> getStatistics() async => null; // TTLCacheは統計未収集
}
