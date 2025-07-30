import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../features/auth/presentation/providers/auth_providers.dart";
import "../constants/exceptions/exceptions.dart";
import "../constants/query_types.dart";
import "base_model.dart";
import "base_repository.dart";

/// マルチテナント対応ベースリポジトリ
/// 
/// BaseRepositoryを拡張し、全ての操作に自動的にuser_idフィルタリングを適用します。
/// 認証されたユーザーのデータのみにアクセスを制限し、データの分離を実現します。
abstract class BaseMultiTenantRepository<T extends BaseModel, ID> extends BaseRepository<T, ID> {
  BaseMultiTenantRepository({
    required super.tableName,
    required Ref ref, super.primaryKeyColumns,
    String userIdColumn = "user_id",
  }) : _ref = ref,
       _userIdColumn = userIdColumn;

  /// Riverpod Ref（認証状態にアクセスするため）
  final Ref _ref;

  /// user_idカラム名（デフォルト: "user_id"）
  final String _userIdColumn;

  /// 現在認証されているユーザーIDを取得
  String? get _currentUserId {
    try {
      return _ref.read(currentUserIdProvider);
    } catch (e) {
      logError("Failed to get current user ID: $e", e);
      return null;
    }
  }

  /// 認証チェック付きユーザーID取得
  String _requireAuthenticatedUserId() {
    final String? userId = _currentUserId;
    if (userId == null) {
      throw AuthException.invalidSession();
    }
    return userId;
  }

  /// user_idフィルタを自動追加
  List<QueryFilter> _addUserIdFilter(List<QueryFilter>? filters) {
    final String userId = _requireAuthenticatedUserId();
    final List<QueryFilter> result = filters?.toList() ?? <QueryFilter>[];
    
    // 既にuser_idフィルタが含まれているかチェック
    // QueryFilterの実装に依存するが、一般的なパターンで判定
    final bool hasUserIdFilter = result.any((QueryFilter filter) => filter.toString().contains(_userIdColumn));

    if (!hasUserIdFilter) {
      result.add(QueryConditionBuilder.eq(_userIdColumn, userId));
    }

    return result;
  }

  /// エンティティのuser_idを自動設定
  T _setUserIdForEntity(T entity) {
    final String userId = _requireAuthenticatedUserId();
    entity.userId = userId;
    return entity;
  }

  /// 複数エンティティのuser_idを自動設定
  List<T> _setUserIdForEntities(List<T> entities) => entities.map(_setUserIdForEntity).toList();

  // =================================================================
  // オーバーライドされたCRUD操作（マルチテナント対応）
  // =================================================================

  /// エンティティを作成（user_id自動設定）
  @override
  Future<T?> create(T entity) async {
    final T entityWithUserId = _setUserIdForEntity(entity);
    return super.create(entityWithUserId);
  }

  /// 複数エンティティを一括作成（user_id自動設定）
  @override
  Future<List<T>> bulkCreate(List<T> entities) async {
    final List<T> entitiesWithUserId = _setUserIdForEntities(entities);
    return super.bulkCreate(entitiesWithUserId);
  }

  /// IDによってエンティティを取得（user_idフィルタ自動適用）
  @override
  Future<T?> getById(ID id) async {
    final List<QueryFilter> filters = _addUserIdFilter(<QueryFilter>[
      QueryConditionBuilder.eq(primaryKeyColumns.first, id),
    ]);
    
    final List<T> results = await find(filters: filters, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// 主キーマップによってエンティティを取得（user_idフィルタ自動適用）
  @override
  Future<T?> getByPrimaryKey(PrimaryKeyMap keyMap) async {
    final List<QueryFilter> filters = _addUserIdFilter(null);
    
    // 主キーフィルタを追加
    for (final MapEntry<String, dynamic> entry in keyMap.entries) {
      filters.add(QueryConditionBuilder.eq(entry.key, entry.value));
    }

    final List<T> results = await find(filters: filters, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// IDによってエンティティを更新（user_idフィルタ自動適用）
  @override
  Future<T?> updateById(ID id, Map<String, dynamic> updates) async {
    // user_idの更新を防ぐ
    final Map<String, dynamic> safeUpdates = Map<String, dynamic>.from(updates)
    ..remove(_userIdColumn)
    ..remove("user_id");

    // 現在のユーザーのエンティティのみ更新対象とする
    final T? existing = await getById(id);
    if (existing == null) {
      return null;
    }

    // BaseRepositoryのupdateByIdを使用（user_idは既にチェック済み）
    return super.updateById(id, safeUpdates);
  }

  /// 主キーマップによってエンティティを更新（user_idフィルタ自動適用）
  @override
  Future<T?> updateByPrimaryKey(PrimaryKeyMap keyMap, Map<String, dynamic> updates) async {
    // user_idの更新を防ぐ
    final Map<String, dynamic> safeUpdates = Map<String, dynamic>.from(updates)
    ..remove(_userIdColumn)
    ..remove("user_id");

    // 現在のユーザーのエンティティのみ更新対象とする
    final T? existing = await getByPrimaryKey(keyMap);
    if (existing == null) {
      return null;
    }

    // BaseRepositoryのupdateByPrimaryKeyを使用（user_idは既にチェック済み）
    return super.updateByPrimaryKey(keyMap, safeUpdates);
  }

  /// IDによってエンティティを削除（user_idフィルタ自動適用）
  @override
  Future<void> deleteById(ID id) async {
    // 現在のユーザーのエンティティのみ削除対象とする
    final T? existing = await getById(id);
    if (existing == null) {
      return; // 存在しないか、他のユーザーのデータ
    }

    // BaseRepositoryのdeleteByIdを使用（user_idは既にチェック済み）
    return super.deleteById(id);
  }

  /// 主キーマップによってエンティティを削除（user_idフィルタ自動適用）
  @override
  Future<void> deleteByPrimaryKey(PrimaryKeyMap keyMap) async {
    // 現在のユーザーのエンティティのみ削除対象とする
    final T? existing = await getByPrimaryKey(keyMap);
    if (existing == null) {
      return; // 存在しないか、他のユーザーのデータ
    }

    // BaseRepositoryのdeleteByPrimaryKeyを使用（user_idは既にチェック済み）
    return super.deleteByPrimaryKey(keyMap);
  }

  /// 複数エンティティを一括削除（user_idフィルタ自動適用）
  @override
  Future<void> bulkDelete(List<ID> keys) async {
    // 各IDについて現在のユーザーのデータのみ削除
    final List<ID> userOwnedKeys = <ID>[];
    
    for (final ID key in keys) {
      final T? entity = await getById(key);
      if (entity != null && belongsToCurrentUser(entity)) {
        userOwnedKeys.add(key);
      }
    }

    if (userOwnedKeys.isNotEmpty) {
      return super.bulkDelete(userOwnedKeys);
    }
  }

  /// IDによってエンティティの存在を確認（user_idフィルタ自動適用）
  @override
  Future<bool> existsById(ID id) async {
    final T? entity = await getById(id);
    return entity != null;
  }

  /// 主キーマップによってエンティティの存在を確認（user_idフィルタ自動適用）
  @override
  Future<bool> existsByPrimaryKey(PrimaryKeyMap keyMap) async {
    final T? entity = await getByPrimaryKey(keyMap);
    return entity != null;
  }

  /// エンティティのリストを取得（user_idフィルタ自動適用）
  @override
  Future<List<T>> list({int limit = 100, int offset = 0}) async {
    final List<QueryFilter> filters = _addUserIdFilter(null);
    return find(filters: filters, limit: limit, offset: offset);
  }

  /// フィルタ条件を使用したエンティティの単一取得（user_idフィルタ自動適用）
  @override
  Future<T?> findOne({List<QueryFilter>? filters}) async {
    final List<QueryFilter> filtersWithUserId = _addUserIdFilter(filters);
    return super.findOne(filters: filtersWithUserId);
  }

  /// 条件によってエンティティを検索する（user_idフィルタ自動適用）
  @override
  Future<List<T>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) async {
    final List<QueryFilter> filtersWithUserId = _addUserIdFilter(filters);
    return super.find(
      filters: filtersWithUserId,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// 条件に一致するエンティティの数を取得する（user_idフィルタ自動適用）
  @override
  Future<int> count({List<QueryFilter>? filters}) async {
    final List<QueryFilter> filtersWithUserId = _addUserIdFilter(filters);
    return super.count(filters: filtersWithUserId);
  }

  // =================================================================
  // マルチテナント用新しいメソッド  
  // =================================================================

  /// 現在のユーザーIDを取得（認証確認付き）
  String getCurrentUserId() => _requireAuthenticatedUserId();

  /// 指定したエンティティが現在のユーザーに属するかチェック
  bool belongsToCurrentUser(T entity) {
    final String? currentUserId = _currentUserId;
    return currentUserId != null && entity.userId == currentUserId;
  }

  /// 複数エンティティが現在のユーザーに属するかチェック
  bool allBelongToCurrentUser(List<T> entities) => entities.every(belongsToCurrentUser);

  /// マルチテナント非対応のfindメソッド（管理者用）
  /// 
  /// 注意：このメソッドはuser_idフィルタを適用しません。
  /// 管理者機能や特別な用途でのみ使用してください。
  Future<List<T>> findWithoutUserFilter({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) async => super.find(
      filters: filters,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

  /// マルチテナント非対応のcountメソッド（管理者用）
  /// 
  /// 注意：このメソッドはuser_idフィルタを適用しません。
  /// 管理者機能や特別な用途でのみ使用してください。
  Future<int> countWithoutUserFilter({List<QueryFilter>? filters}) async => super.count(filters: filters);
}