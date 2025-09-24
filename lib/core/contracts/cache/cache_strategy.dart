/// キャッシュ戦略（契約）
enum CacheStrategy { noCache, memoryOnly, persistent, shortTerm, longTerm }

/// キャッシュ設定（契約）
class CacheConfig {
  const CacheConfig({
    required this.strategy,
    this.customTtl,
    this.maxItems,
    this.invalidateOnNetworkChange = true,
    this.invalidateOnUserChange = true,
  });

  final CacheStrategy strategy;
  final Duration? customTtl;
  final int? maxItems;
  final bool invalidateOnNetworkChange;
  final bool invalidateOnUserChange;

  static const CacheConfig defaultConfig = CacheConfig(
    strategy: CacheStrategy.memoryOnly,
    maxItems: 50,
  );

  Duration get ttl {
    if (customTtl != null) {
      return customTtl!;
    }
    switch (strategy) {
      case CacheStrategy.noCache:
        return Duration.zero;
      case CacheStrategy.memoryOnly:
        return const Duration(minutes: 10);
      case CacheStrategy.persistent:
        return const Duration(hours: 2);
      case CacheStrategy.shortTerm:
        return const Duration(minutes: 5);
      case CacheStrategy.longTerm:
        return const Duration(minutes: 30);
    }
  }
}
