import "dart:async";

import "../../../core/contracts/cache/cache.dart" as contract;
import "../../../core/contracts/cache/cache_metadata.dart";
import "memory_cache.dart";

/// `MemoryCache` を core 契約 `Cache<String, V>` にブリッジするアダプタ
class MemoryCacheAdapter<V> implements contract.Cache<String, V> {
  MemoryCacheAdapter() : _impl = MemoryCache();

  final MemoryCache _impl;

  @override
  Future<V?> get(String key) async => _impl.get<V>(key);

  @override
  Future<void> set(String key, V value, Duration ttl) async => _impl.set<V>(key, value, ttl);

  @override
  Future<void> remove(String key) async => _impl.remove(key);

  @override
  Future<void> removePattern(String pattern) async => _impl.removePattern(pattern);

  @override
  Future<void> clear() async => _impl.clear();

  @override
  Future<CacheStatistics?> getStatistics() async => null;
}
