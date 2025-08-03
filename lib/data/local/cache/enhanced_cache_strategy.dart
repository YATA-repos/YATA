
import "cache_strategy.dart";

/// 拡張キャッシュ戦略
/// データタイプ別の最適なキャッシュ戦略を定義
enum DataType {
  /// ユーザー固有の動的データ（在庫数、注文状況）
  userDynamicData,
  
  /// ユーザー固有の準静的データ（材料マスタ、メニュー）
  userSemiStaticData,
  
  /// グローバル設定データ（システム設定、マスタデータ）
  globalStaticData,
  
  /// リアルタイムデータ（現在進行中の注文）
  realtimeData,
  
  /// 分析データ（統計、レポート）
  analyticsData,
  
  /// UI状態データ（フィルター設定、画面状態）
  uiStateData,
}

/// キャッシュ優先度
enum CachePriority {
  /// 低優先度（メモリ不足時に最初に削除）
  low,
  
  /// 通常優先度
  normal,
  
  /// 高優先度（重要なデータ、削除されにくい）
  high,
  
  /// 最高優先度（システム動作に必須）
  critical,
}

/// 拡張キャッシュ設定
class EnhancedCacheConfig extends CacheConfig {
  const EnhancedCacheConfig({
    required super.strategy,
    required this.dataType,
    this.priority = CachePriority.normal,
    this.autoRefresh = false,
    this.refreshInterval,
    this.dependsOn = const <String>[],
    super.customTtl,
    super.maxItems,
    super.invalidateOnNetworkChange,
    super.invalidateOnUserChange,
  });

  /// データタイプ
  final DataType dataType;
  
  /// キャッシュ優先度
  final CachePriority priority;
  
  /// 自動リフレッシュ有効フラグ
  final bool autoRefresh;
  
  /// 自動リフレッシュ間隔
  final Duration? refreshInterval;
  
  /// 依存関係（これらのキーが無効化されたときに連動して無効化）
  final List<String> dependsOn;

  /// データタイプ別デフォルト設定取得
  static EnhancedCacheConfig forDataType(DataType dataType) {
    switch (dataType) {
      case DataType.userDynamicData:
        return EnhancedCacheConfig(
          strategy: CacheStrategy.shortTerm,
          dataType: dataType,
          autoRefresh: true,
          refreshInterval: const Duration(seconds: 30),
          maxItems: 20,
        );
        
      case DataType.userSemiStaticData:
        return EnhancedCacheConfig(
          strategy: CacheStrategy.longTerm,
          dataType: dataType,
          priority: CachePriority.high,
          maxItems: 100,
        );
        
      case DataType.globalStaticData:
        return EnhancedCacheConfig(
          strategy: CacheStrategy.persistent,
          dataType: dataType,
          priority: CachePriority.critical,
          customTtl: const Duration(hours: 24),
          maxItems: 50,
        );
        
      case DataType.realtimeData:
        return const EnhancedCacheConfig(
          strategy: CacheStrategy.noCache,
          dataType: DataType.realtimeData,
          priority: CachePriority.low,
        );
        
      case DataType.analyticsData:
        return EnhancedCacheConfig(
          strategy: CacheStrategy.longTerm,
          dataType: dataType,
          customTtl: const Duration(minutes: 15),
          maxItems: 30,
        );
        
      case DataType.uiStateData:
        return EnhancedCacheConfig(
          strategy: CacheStrategy.memoryOnly,
          dataType: dataType,
          priority: CachePriority.low,
          customTtl: const Duration(minutes: 5),
          maxItems: 10,
        );
    }
  }

  @override
  String toString() => "EnhancedCacheConfig("
      "dataType: $dataType, "
      "strategy: $strategy, "
      "priority: $priority, "
      "ttl: $ttl"
      ")";
}

/// キャッシュライフサイクル管理
class CacheLifecycleManager {
  static const Map<DataType, Duration> _dataTypeLifecycles = <DataType, Duration>{
    DataType.userDynamicData: Duration(minutes: 2),
    DataType.userSemiStaticData: Duration(minutes: 30),
    DataType.globalStaticData: Duration(hours: 24),
    DataType.realtimeData: Duration.zero,
    DataType.analyticsData: Duration(minutes: 15),
    DataType.uiStateData: Duration(minutes: 5),
  };

  /// データタイプの推奨ライフサイクル取得
  static Duration getRecommendedLifecycle(DataType dataType) => _dataTypeLifecycles[dataType] ?? const Duration(minutes: 10);

  /// ライフサイクルに基づくキャッシュ戦略決定
  static CacheStrategy getRecommendedStrategy(DataType dataType) {
    final Duration lifecycle = getRecommendedLifecycle(dataType);
    
    if (lifecycle == Duration.zero) {
      return CacheStrategy.noCache;
    } else if (lifecycle.inMinutes <= 5) {
      return CacheStrategy.shortTerm;
    } else if (lifecycle.inMinutes <= 30) {
      return CacheStrategy.longTerm;
    } else {
      return CacheStrategy.persistent;
    }
  }
}

/// スマートキャッシュ無効化ルール
class CacheInvalidationRules {
  /// データタイプ別無効化ルール
  static const Map<DataType, List<String>> _invalidationPatterns = <DataType, List<String>>{
    DataType.userDynamicData: <String>[
      "inventory:*",
      "orders:active:*",
      "stock:levels:*",
    ],
    DataType.userSemiStaticData: <String>[
      "materials:*",
      "menu:items:*",
      "suppliers:*",
    ],
    DataType.analyticsData: <String>[
      "analytics:*",
      "stats:*",
      "reports:*",
    ],
  };

  /// データタイプの無効化パターン取得
  static List<String> getInvalidationPatterns(DataType dataType) => _invalidationPatterns[dataType] ?? <String>[];

  /// 関連データの連動無効化判定
  static bool shouldInvalidateTogether(DataType source, DataType target) {
    // 在庫データが変更されたら分析データも無効化
    if (source == DataType.userDynamicData && target == DataType.analyticsData) {
      return true;
    }
    
    // 材料マスタが変更されたら在庫データも無効化
    if (source == DataType.userSemiStaticData && target == DataType.userDynamicData) {
      return true;
    }
    
    return false;
  }
}

/// キャッシュウォーミング戦略
class CacheWarmingStrategy {
  /// データタイプ別ウォーミング優先度
  static const Map<DataType, int> _warmingPriority = <DataType, int>{
    DataType.globalStaticData: 1,    // 最優先
    DataType.userSemiStaticData: 2,  // 高優先
    DataType.uiStateData: 3,         // 中優先
    DataType.analyticsData: 4,       // 低優先
    DataType.userDynamicData: 5,     // 最低優先（動的なため）
  };

  /// ウォーミング優先度取得
  static int getWarmingPriority(DataType dataType) => _warmingPriority[dataType] ?? 999;

  /// ウォーミングが推奨されるか
  static bool shouldWarmCache(DataType dataType) => getWarmingPriority(dataType) <= 3;

  /// ウォーミング戦略取得
  static List<String> getWarmingKeys(DataType dataType, String userId) {
    switch (dataType) {
      case DataType.globalStaticData:
        return <String>[
          "system:config",
          "app:settings",
        ];
        
      case DataType.userSemiStaticData:
        return <String>[
          "user:$userId:materials",
          "user:$userId:menu",
          "user:$userId:suppliers",
        ];
        
      case DataType.uiStateData:
        return <String>[
          "user:$userId:ui:filters",
          "user:$userId:ui:preferences",
        ];
        
      case DataType.userDynamicData:
      case DataType.realtimeData:
      case DataType.analyticsData:
        // これらのデータタイプはウォーミングに適さない
        return <String>[];
    }
  }
}

/// メモリ効率的なキャッシュ戦略
class MemoryEfficientCacheStrategy {
  /// データタイプ別メモリ使用量見積もり（KB）
  static const Map<DataType, double> _estimatedMemoryUsage = <DataType, double>{
    DataType.userDynamicData: 50.0,     // 在庫データ等
    DataType.userSemiStaticData: 200.0, // 材料マスタ等
    DataType.globalStaticData: 100.0,   // システム設定等
    DataType.analyticsData: 300.0,      // 分析結果等
    DataType.uiStateData: 10.0,         // UI状態
    DataType.realtimeData: 0.0,         // キャッシュしない
  };

  /// データタイプのメモリ使用量見積もり取得
  static double getEstimatedMemoryUsage(DataType dataType) => _estimatedMemoryUsage[dataType] ?? 50.0;

  /// メモリ制限に基づくキャッシュ戦略調整
  static EnhancedCacheConfig adjustForMemoryLimit(
    EnhancedCacheConfig original,
    double availableMemoryMB,
  ) {
    // メモリ不足の場合は戦略を調整
    if (availableMemoryMB < 10.0) { // 10MB未満の場合
      return EnhancedCacheConfig(
        strategy: CacheStrategy.noCache,
        dataType: original.dataType,
        priority: CachePriority.low,
      );
    } else if (availableMemoryMB < 50.0) { // 50MB未満の場合
      return EnhancedCacheConfig(
        strategy: CacheStrategy.shortTerm,
        dataType: original.dataType,
        priority: original.priority,
        maxItems: (original.maxItems ?? 50) ~/ 2, // 半分に制限
      );
    }
    
    return original; // メモリに余裕がある場合はそのまま
  }
}