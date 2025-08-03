import "../../../core/base/base_model.dart";
import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "cache_manager.dart";
import "cache_strategy.dart";

/// BaseRepositoryにキャッシュ機能を追加するMixin
/// 既存の継承関係を破壊しない設計
/// 
/// **使用方法**:
/// ```dart
/// class InventoryRepository extends BaseRepository<Material, String> 
///     with RepositoryCacheMixin<Material> {
///   
///   @override
///   CacheConfig get cacheConfig => const CacheConfig(
///     strategy: CacheStrategy.longTerm,
///     maxItems: 100,
///   );
/// }
/// ```
mixin RepositoryCacheMixin<T extends BaseModel, ID> on BaseRepository<T, ID> {
  
  /// キャッシュマネージャーインスタンス
  CacheManager get _cacheManager => CacheManager();

  /// キャッシュ設定（サブクラスでオーバーライド可能）
  /// デフォルトはメモリオンリー戦略
  CacheConfig get cacheConfig => CacheConfig.defaultConfig;

  /// ユーザーIDの取得（サブクラスで実装必要）
  /// マルチテナント対応のため
  String? get currentUserId;

  /// キャッシュキー生成（サブクラスでカスタマイズ可能）
  /// 
  /// **格式**: `table:operation:user:params_hash`
  /// 例: `materials:findAll:user123:category_food`
  String generateCacheKey(String operation, [Map<String, dynamic>? params]) {
    final StringBuffer keyBuffer = StringBuffer()
      ..write(tableName)
      ..write(":")
      ..write(operation);
    
    // ユーザーID（マルチテナント対応）
    if (currentUserId != null) {
      keyBuffer
        ..write(":user:")
        ..write(currentUserId);
    }
    
    // パラメータ（フィルター条件等）
    if (params != null && params.isNotEmpty) {
      keyBuffer.write(":");
      // パラメータをソートして一意性確保
      final List<String> sortedKeys = params.keys.toList()..sort();
      for (final String key in sortedKeys) {
        keyBuffer.write("${key}_${params[key]}");
        if (key != sortedKeys.last) {
          keyBuffer.write("-");
        }
      }
    }
    
    return keyBuffer.toString();
  }

  /// キャッシュ付きfind
  /// 既存のfindメソッドをキャッシュでラップ
  Future<List<T>> findCached({List<QueryFilter>? filters}) async {
    final String cacheKey = generateCacheKey("find", <String, dynamic>{
      "filters": _serializeFilters(filters),
    });
    
    // キャッシュから取得試行
    final List<T>? cached = await _cacheManager.get<List<T>>(cacheKey, cacheConfig);
    if (cached != null) {
      logDebug("Cache hit for $cacheKey");
      return cached;
    }
    
    // キャッシュミス時は通常のfindを実行
    logDebug("Cache miss for $cacheKey - fetching from database");
    final List<T> result = await find(filters: filters);
    
    // 結果をキャッシュに保存
    await _cacheManager.set(cacheKey, result, cacheConfig);
    logDebug("Cached result for $cacheKey (${result.length} items)");
    
    return result;
  }

  /// キャッシュ付きgetById  
  /// 既存のgetByIdメソッドをキャッシュでラップ
  Future<T?> getByIdCached(ID id) async {
    final String cacheKey = generateCacheKey("getById", <String, dynamic>{"id": id.toString()});
    
    // キャッシュから取得試行
    final T? cached = await _cacheManager.get<T>(cacheKey, cacheConfig);
    if (cached != null) {
      logDebug("Cache hit for $cacheKey");
      return cached;
    }
    
    // キャッシュミス時は通常のgetByIdを実行
    logDebug("Cache miss for $cacheKey - fetching from database");
    final T? result = await getById(id);
    
    // 結果をキャッシュに保存（nullでなければ）
    if (result != null) {
      await _cacheManager.set(cacheKey, result, cacheConfig);
      logDebug("Cached result for $cacheKey");
    }
    
    return result;
  }

  /// キャッシュ付きcount
  /// 集計系クエリのキャッシュ
  Future<int> countCached({List<QueryFilter>? filters}) async {
    final String cacheKey = generateCacheKey("count", <String, dynamic>{
      "filters": _serializeFilters(filters),
    });
    
    // キャッシュから取得試行
    final int? cached = await _cacheManager.get<int>(cacheKey, cacheConfig);
    if (cached != null) {
      logDebug("Cache hit for count $cacheKey");
      return cached;
    }
    
    // キャッシュミス時はcountを実行
    logDebug("Cache miss for count $cacheKey - fetching from database");
    final int result = await count(filters: filters);
    
    // 結果をキャッシュに保存
    await _cacheManager.set(cacheKey, result, cacheConfig);
    logDebug("Cached count result for $cacheKey: $result");
    
    return result;
  }

  /// エンティティ作成時のキャッシュ無効化
  /// createメソッド後にキャッシュを無効化
  Future<T?> createWithCacheInvalidation(T entity) async {
    final T? result = await create(entity);
    
    if (result != null) {
      // 関連キャッシュの無効化
      await _invalidateRelatedCache("create");
      logDebug("Invalidated cache after create operation");
    }
    
    return result;
  }

  /// エンティティ更新時のキャッシュ無効化
  /// updateByIdメソッド後にキャッシュを無効化
  Future<T?> updateWithCacheInvalidation(ID id, Map<String, dynamic> updates) async {
    final T? result = await updateById(id, updates);
    
    if (result != null) {
      // 関連キャッシュの無効化
      await _invalidateRelatedCache("update", id);
      logDebug("Invalidated cache after update operation");
    }
    
    return result;
  }

  /// エンティティ削除時のキャッシュ無効化
  /// deleteByIdメソッド後にキャッシュを無効化
  Future<void> deleteWithCacheInvalidation(ID id) async {
    await deleteById(id);
    
    // 関連キャッシュの無効化
    await _invalidateRelatedCache("delete", id);
    logDebug("Invalidated cache after delete operation");
  }

  /// 手動キャッシュ無効化
  /// 外部からの明示的なキャッシュクリア
  Future<void> invalidateCache([String? specificKey]) async {
    if (specificKey != null) {
      await _cacheManager.invalidate(specificKey);
      logDebug("Invalidated specific cache: $specificKey");
    } else {
      await _invalidateRelatedCache("manual");
      logDebug("Invalidated all related cache for $tableName");
    }
  }

  /// QueryFilterのシリアライズ
  /// キャッシュキー生成用
  String _serializeFilters(List<QueryFilter>? filters) {
    if (filters == null || filters.isEmpty) {
      return "none";
    }
    
    final List<String> serialized = <String>[];
    for (final QueryFilter filter in filters) {
      if (filter is FilterCondition) {
        serialized.add("${filter.column}_${filter.operator.name}_${filter.value}");
      } else if (filter is AndCondition) {
        serialized.add("AND(${_serializeFilters(filter.conditions)})");
      } else if (filter is OrCondition) {
        serialized.add("OR(${_serializeFilters(filter.conditions)})");
      } else {
        serialized.add(filter.runtimeType.toString());
      }
    }
    return serialized.join("|");
  }

  /// 関連キャッシュの無効化
  /// CUD操作時に呼び出される内部メソッド
  Future<void> _invalidateRelatedCache(String operation, [ID? id]) async {
    // テーブル全体のキャッシュを無効化
    String pattern = "$tableName:*";
    
    // ユーザー固有データの場合は範囲を限定
    if (currentUserId != null) {
      pattern = "$tableName:*:user:$currentUserId:*";
    }
    
    await _cacheManager.invalidatePattern(pattern);
    
    // 特定IDのキャッシュも無効化
    if (id != null) {
      final String specificKey = generateCacheKey("getById", <String, dynamic>{"id": id.toString()});
      await _cacheManager.invalidate(specificKey);
    }
  }
}