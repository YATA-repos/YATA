import "cache_metadata.dart";

/// 汎用キャッシュ契約
abstract class Cache<K, V> {
  Future<V?> get(K key);
  Future<void> set(K key, V value, Duration ttl);
  Future<void> remove(K key);
  Future<void> removePattern(String pattern);
  Future<void> clear();

  /// 統計情報（実装によってサポートされない場合あり）
  Future<CacheStatistics?> getStatistics();
}
