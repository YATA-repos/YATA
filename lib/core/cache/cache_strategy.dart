/// キャッシュ戦略定義
/// YATAアーキテクチャに準拠したキャッシュ戦略の列挙型
enum CacheStrategy {
  /// キャッシュしない（リアルタイム性重視）
  noCache,
  
  /// メモリのみ（セッション中のみ保持）
  memoryOnly,
  
  /// 永続化（アプリ再起動後も保持）
  persistent,
  
  /// 短期間キャッシュ（5分、頻繁に変更されるデータ）
  shortTerm,
  
  /// 長期間キャッシュ（30分、あまり変更されないデータ）
  longTerm,
}

/// キャッシュ設定クラス
/// Repository層でキャッシュ動作を制御
class CacheConfig {
  const CacheConfig({
    required this.strategy,
    this.customTtl,
    this.maxItems,
    this.invalidateOnNetworkChange = true,
    this.invalidateOnUserChange = true,
  });

  /// キャッシュ戦略
  final CacheStrategy strategy;
  
  /// カスタムTTL（Time To Live）
  final Duration? customTtl;
  
  /// 最大アイテム数
  final int? maxItems;
  
  /// ネットワーク状態変更時に無効化するか
  final bool invalidateOnNetworkChange;
  
  /// ユーザー変更時に無効化するか  
  final bool invalidateOnUserChange;

  /// デフォルト設定
  static const CacheConfig defaultConfig = CacheConfig(
    strategy: CacheStrategy.memoryOnly,
    maxItems: 50,
  );

  /// 戦略別TTL取得
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

  @override
  String toString() => "CacheConfig(strategy: $strategy, ttl: $ttl)";
}