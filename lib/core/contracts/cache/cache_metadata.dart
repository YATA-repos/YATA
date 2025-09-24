/// キャッシュ対象のデータタイプ（契約）
enum CacheDataType {
  userDynamicData,
  userSemiStaticData,
  globalStaticData,
  realtimeData,
  analyticsData,
  uiStateData,
}

/// キャッシュメタデータ（契約）
class CacheMetadata {
  const CacheMetadata({
    required this.key,
    required this.dataType,
    required this.createdAt,
    required this.lastAccessed,
    required this.accessCount,
    this.expiresAt,
    this.size,
  });

  final String key;
  final CacheDataType dataType;
  final DateTime createdAt;
  final DateTime lastAccessed;
  final int accessCount;
  final DateTime? expiresAt;
  final int? size;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  Duration get timeSinceLastAccess => DateTime.now().difference(lastAccessed);
}

/// キャッシュ統計情報（契約）
class CacheStatistics {
  const CacheStatistics({
    required this.totalEntries,
    required this.totalSize,
    required this.hitCount,
    required this.missCount,
    required this.evictionCount,
    required this.typeDistribution,
  });

  final int totalEntries;
  final int totalSize;
  final int hitCount;
  final int missCount;
  final int evictionCount;
  final Map<CacheDataType, int> typeDistribution;

  double get hitRate => (hitCount + missCount) > 0 ? hitCount / (hitCount + missCount) : 0.0;
  double get averageEntrySize => totalEntries > 0 ? totalSize / totalEntries : 0.0;
}
