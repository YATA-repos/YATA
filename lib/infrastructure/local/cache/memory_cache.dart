import "dart:collection";

/// メモリベースキャッシュ実装
/// セッション中のみデータを保持
class MemoryCache {
  MemoryCache();

  final Map<String, _CacheEntry> _cache = HashMap<String, _CacheEntry>();

  /// キャッシュからデータ取得
  T? get<T>(String key) {
    final _CacheEntry? entry = _cache[key];
    if (entry == null) {
      return null;
    }
    
    // TTL確認
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T?;
  }

  /// キャッシュにデータ設定
  void set<T>(String key, T value, Duration ttl) {
    final DateTime expiry = DateTime.now().add(ttl);
    _cache[key] = _CacheEntry(value, expiry);
  }

  /// キャッシュから削除
  void remove(String key) {
    _cache.remove(key);
  }

  /// パターンマッチで削除
  void removePattern(String pattern) {
    final RegExp regex = RegExp(pattern.replaceAll("*", ".*"));
    final List<String> keysToRemove = _cache.keys.where(regex.hasMatch).toList();
    
    for (final String key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// 全キャッシュクリア
  void clear() {
    _cache.clear();
  }

  /// 期限切れエントリのクリーンアップ
  void cleanup() {
    final List<String> expiredKeys = <String>[];
    
    for (final MapEntry<String, _CacheEntry> entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final String key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// 現在のアイテム数
  int get itemCount => _cache.length;

  /// 推定メモリサイズ（MB）
  double get estimatedSizeMB => _cache.length * 0.001; // 簡易推定
}

/// キャッシュエントリ内部クラス
class _CacheEntry {
  _CacheEntry(this.value, this.expiryTime);

  final dynamic value;
  final DateTime expiryTime;

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}