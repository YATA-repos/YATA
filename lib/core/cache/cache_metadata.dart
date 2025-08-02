import "enhanced_cache_strategy.dart";

/// キャッシュメタデータ
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

  /// JSONからオブジェクトを生成
  factory CacheMetadata.fromJson(Map<String, dynamic> json) => CacheMetadata(
    key: json["key"] as String,
    dataType: DataType.values.firstWhere(
      (DataType type) => type.name == json["data_type"] as String,
    ),
    createdAt: DateTime.parse(json["created_at"] as String),
    lastAccessed: DateTime.parse(json["last_accessed"] as String),
    accessCount: (json["access_count"] as num?)?.toInt() ?? 0,
    expiresAt: json["expires_at"] != null 
        ? DateTime.parse(json["expires_at"] as String) 
        : null,
    size: (json["size"] as num?)?.toInt(),
  );

  /// キャッシュキー
  final String key;

  /// データタイプ
  final DataType dataType;

  /// 作成日時
  final DateTime createdAt;

  /// 最終アクセス日時
  final DateTime lastAccessed;

  /// アクセス回数
  final int accessCount;

  /// 有効期限
  final DateTime? expiresAt;

  /// サイズ（バイト）
  final int? size;

  /// メタデータのコピーを作成
  CacheMetadata copyWith({
    String? key,
    DataType? dataType,
    DateTime? createdAt,
    DateTime? lastAccessed,
    int? accessCount,
    DateTime? expiresAt,
    int? size,
  }) => CacheMetadata(
    key: key ?? this.key,
    dataType: dataType ?? this.dataType,
    createdAt: createdAt ?? this.createdAt,
    lastAccessed: lastAccessed ?? this.lastAccessed,
    accessCount: accessCount ?? this.accessCount,
    expiresAt: expiresAt ?? this.expiresAt,
    size: size ?? this.size,
  );

  /// キャッシュが期限切れかどうか
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 最終アクセスからの経過時間
  Duration get timeSinceLastAccess => DateTime.now().difference(lastAccessed);

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "key": key,
    "data_type": dataType.name,
    "created_at": createdAt.toIso8601String(),
    "last_accessed": lastAccessed.toIso8601String(),
    "access_count": accessCount,
    "expires_at": expiresAt?.toIso8601String(),
    "size": size,
  };
}

/// キャッシュ統計情報
class CacheStatistics {
  const CacheStatistics({
    required this.totalEntries,
    required this.totalSize,
    required this.hitCount,
    required this.missCount,
    required this.evictionCount,
    required this.typeDistribution,
  });

  /// 総エントリー数
  final int totalEntries;

  /// 総サイズ（バイト）
  final int totalSize;

  /// ヒット数
  final int hitCount;

  /// ミス数
  final int missCount;

  /// 削除数
  final int evictionCount;

  /// データ型別分布
  final Map<DataType, int> typeDistribution;

  /// ヒット率
  double get hitRate {
    final int totalRequests = hitCount + missCount;
    return totalRequests > 0 ? hitCount / totalRequests : 0.0;
  }

  /// 平均エントリーサイズ
  double get averageEntrySize => totalEntries > 0 ? totalSize / totalEntries : 0.0;
}