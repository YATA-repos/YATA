import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../core/base/base_model.dart";
import "../../core/constants/exceptions/exceptions.dart";
import "../../core/constants/query_types.dart";
// import "../../core/logging/logger_mixin.dart";
import "../../utils/query_utils.dart";
import "../../core/validation/type_validator.dart";
import "../../features/auth/presentation/providers/auth_providers.dart";
import "../../infrastructure/supabase/supabase_client.dart";

/// プライマリキー
typedef PrimaryKeyMap = Map<String, dynamic>;

/// ベースCRUDリポジトリ抽象クラス（マルチテナント対応）
/// 
/// デフォルトで全ての操作に自動的にuser_idフィルタリングを適用します。
/// 認証されたユーザーのデータのみにアクセスを制限し、データの分離を実現します。
abstract class BaseRepository<T extends BaseModel, ID>{
  BaseRepository({
    required this.tableName,
    required Ref ref,
    this.primaryKeyColumns = const <String>["id"],
    this.enableMultiTenant = true,
    String userIdColumn = "user_id",
  }) : _ref = ref,
       _userIdColumn = userIdColumn;

  final String tableName;

  /// 主キーカラム名のリスト（複合主キー対応）
  final List<String> primaryKeyColumns;

  /// Riverpod Ref（認証状態にアクセスするため）
  final Ref _ref;

  /// マルチテナント機能の有効/無効（デフォルト: true）
  final bool enableMultiTenant;

  /// user_idカラム名（デフォルト: "user_id"）
  final String _userIdColumn;

  /// JSONからモデルインスタンスを作成するファクトリ関数
  ///
  /// サブクラスで実装し、対応するモデルのfromJsonメソッドを呼び出します。
  /// これにより、シリアライゼーション処理をモデル側に完全に集約できます。
  T fromJson(Map<String, dynamic> json);

  /// Supabaseクライアント取得
  SupabaseClient get _client => SupabaseClientService.client;

  /// クエリビルダー取得
  SupabaseQueryBuilder get _table => _client.from(tableName);

  /// 現在認証されているユーザーIDを取得
  String? get _currentUserId {
    if (!enableMultiTenant) {
      return null;
    }
    try {
      return _ref.read(currentUserIdProvider);
    } catch (e) {
      return null;
    }
  }

  /// パブリックな現在ユーザーID取得（RepositoryCacheMixin用）
  String? get currentUserId => _currentUserId;

  /// 認証チェック付きユーザーID取得
  String _requireAuthenticatedUserId() {
    if (!enableMultiTenant) {
      throw ArgumentError("マルチテナント機能が無効のため、ユーザーIDを取得できません。");
    }
    final String? userId = _currentUserId;
    if (userId == null) {
      // ! AuthException.invalidSession()を投げる
      throw Exception("無効なセッション");
    }
    return userId;
  }

  /// user_idフィルタを自動追加
  List<QueryFilter> _addUserIdFilter(List<QueryFilter>? filters) {
    if (!enableMultiTenant) {
      return filters?.toList() ?? <QueryFilter>[];
    }
    
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
    if (!enableMultiTenant) {
      return entity;
    }
    final String userId = _requireAuthenticatedUserId();
    entity.userId = userId;
    return entity;
  }

  /// 複数エンティティのuser_idを自動設定
  List<T> _setUserIdForEntities(List<T> entities) {
    if (!enableMultiTenant) {
      return entities;
    }
    return entities.map(_setUserIdForEntity).toList();
  }

  /// 内部用JSONデシリアライゼーションヘルパー
  ///
  /// モデル側のfromJsonメソッドを呼び出します。
  T _fromJson(Map<String, dynamic> json) => fromJson(json);

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  /// 単一キーを主キーマップに正規化（型安全）
  PrimaryKeyMap _normalizeKey(ID key) {
    // 型検証を最初に実行
    if (!TypeValidator.isValidIdType(key)) {
      throw InvalidIdTypeException(key.runtimeType, <Type>[String, int, Map]);
    }

    if (key is Map<String, dynamic>) {
      return key;
    }

    // 単一値の場合、主キーカラムが1つであることを確認
    if (primaryKeyColumns.length != 1) {
      throw ArgumentError("複合主キーにはMap<String, dynamic>形式でキーを指定してください");
    }

    return <String, dynamic>{primaryKeyColumns[0]: key};
  }

  /// フィルタ条件を使用したエンティティの単一取得（user_idフィルタ自動適用）
  Future<T?> findOne({List<QueryFilter>? filters}) async {
    try {
      final List<QueryFilter> filtersWithUserId = _addUserIdFilter(filters);
      
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _table.select();

      if (filtersWithUserId.isNotEmpty) {
        query = QueryUtils.applyFilters(query, filtersWithUserId);
      }

      final Map<String, dynamic>? response = await query.maybeSingle();

      if (response != null) {
        return _fromJson(response);
      }

      return null;
      // TODO: エラーハンドリングの詳細化が必要
    } catch (e) {
      // エラー分類とログレベルの標準化が必要
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// クエリに主キー条件を適用
  PostgrestFilterBuilder<TQuery> _applyPrimaryKey<TQuery>(
    PostgrestFilterBuilder<TQuery> query,
    PrimaryKeyMap keyMap,
  ) {
    PostgrestFilterBuilder<TQuery> result = query;

    for (final String column in primaryKeyColumns) {
      if (!keyMap.containsKey(column)) {
        throw ArgumentError("主キーカラム '$column' がキーマップに見つかりません");
      }

      final Object? value = keyMap[column];
      if (value is String || value is int || value is double || value is bool) {
        result = result.eq(column, value as Object);
      } else {
        throw ArgumentError("主キーカラム '$column' の値が無効な型です: ${value.runtimeType}");
      }
    }

    return result;
  }

  // =================================================================
  // CRUD操作
  // =================================================================

  /// エンティティを作成（user_id自動設定）
  Future<T?> create(T entity) async {
    try {
      final T entityWithUserId = _setUserIdForEntity(entity);
      final Map<String, dynamic> data = entityWithUserId.toJson();
      final List<Map<String, dynamic>> response = await _table.insert(data).select();

      if (response.isNotEmpty) {
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        return _fromJson(response[0]);
      }
      // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
      return null;
      // TODO: エラーハンドリングの詳細化が必要
    } catch (e) {
      // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
      throw RepositoryException(
        RepositoryError.insertFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 複数エンティティを一括作成（user_id自動設定）
  Future<List<T>> bulkCreate(List<T> entities) async {
    if (entities.isEmpty) {
      return <T>[];
    }

    try {
      final List<T> entitiesWithUserId = _setUserIdForEntities(entities);
      final List<Map<String, dynamic>> dataList = entitiesWithUserId.map((T e) => e.toJson()).toList();
      final List<Map<String, dynamic>> response = await _table.insert(dataList).select();

      // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
      return response.map(_fromJson).toList();
      // TODO: エラーハンドリングの詳細化が必要
    } catch (e) {
      // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
      throw RepositoryException(
        RepositoryError.insertFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// IDによってエンティティを取得（user_idフィルタ自動適用）
  Future<T?> getById(ID id) async {
    if (!enableMultiTenant) {
      try {
        final PrimaryKeyMap keyMap = _normalizeKey(id);
        final Map<String, dynamic>? response = await _applyPrimaryKey(
          _table.select(),
          keyMap,
        ).maybeSingle();

        if (response != null) {
          return _fromJson(response);
        }
        return null;
      } catch (e) {
        if (e is InvalidIdTypeException) {
          throw RepositoryException(
            RepositoryError.invalidQueryParameters,
            params: <String, String>{"error": "Invalid ID type: ${id.runtimeType}"},
          );
        }
        throw RepositoryException(
          RepositoryError.databaseConnectionFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    }

    // マルチテナント機能有効の場合
    final List<QueryFilter> filters = _addUserIdFilter(<QueryFilter>[
      QueryConditionBuilder.eq(primaryKeyColumns.first, id),
    ]);
    
    final List<T> results = await find(filters: filters, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// 主キーマップによってエンティティを取得（user_idフィルタ自動適用）
  Future<T?> getByPrimaryKey(PrimaryKeyMap keyMap) async {
    if (!enableMultiTenant) {
      try {
        final Map<String, dynamic>? response = await _applyPrimaryKey(
          _table.select(),
          keyMap,
        ).maybeSingle();

        if (response != null) {
          return _fromJson(response);
        }
        return null;
        // TODO: エラーハンドリングの詳細化が必要
      } catch (e) {
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        throw RepositoryException(
          RepositoryError.databaseConnectionFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    }

    // マルチテナント機能有効の場合
    final List<QueryFilter> filters = _addUserIdFilter(null);
    
    // 主キーフィルタを追加
    for (final MapEntry<String, dynamic> entry in keyMap.entries) {
      filters.add(QueryConditionBuilder.eq(entry.key, entry.value));
    }

    final List<T> results = await find(filters: filters, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// IDによってエンティティを更新（user_idフィルタ自動適用）
  Future<T?> updateById(ID id, Map<String, dynamic> updates) async {
    if (!enableMultiTenant) {
      try {
        final PrimaryKeyMap keyMap = _normalizeKey(id);
        final List<Map<String, dynamic>> response = await _applyPrimaryKey(
          _table.update(updates),
          keyMap,
        ).select();

        if (response.isNotEmpty) {
          return _fromJson(response[0]);
        }
        return null;
      } catch (e) {
        if (e is InvalidIdTypeException) {
          throw RepositoryException(
            RepositoryError.invalidQueryParameters,
            params: <String, String>{"error": "Invalid ID type: ${id.runtimeType}"},
          );
        }
        throw RepositoryException(
          RepositoryError.updateFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    }

    // マルチテナント機能有効の場合
    // user_idの更新を防ぐ
    final Map<String, dynamic> safeUpdates = Map<String, dynamic>.from(updates)
    ..remove(_userIdColumn)
    ..remove("user_id");

    // 現在のユーザーのエンティティのみ更新対象とする
    final T? existing = await getById(id);
    if (existing == null) {
      return null;
    }

    // 結果として更新を実行（user_idは既にチェック済み）
    try {
      final PrimaryKeyMap keyMap = _normalizeKey(id);
      final List<Map<String, dynamic>> response = await _applyPrimaryKey(
        _table.update(safeUpdates),
        keyMap,
      ).select();

      if (response.isNotEmpty) {
        return _fromJson(response[0]);
      }
      return null;
    } catch (e) {
      if (e is InvalidIdTypeException) {
        throw RepositoryException(
          RepositoryError.invalidQueryParameters,
          params: <String, String>{"error": "Invalid ID type: ${id.runtimeType}"},
        );
      }
      throw RepositoryException(
        RepositoryError.updateFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 主キーマップによってエンティティを更新（user_idフィルタ自動適用）
  Future<T?> updateByPrimaryKey(PrimaryKeyMap keyMap, Map<String, dynamic> updates) async {
    if (!enableMultiTenant) {
      try {
        final List<Map<String, dynamic>> response = await _applyPrimaryKey(
          _table.update(updates),
          keyMap,
        ).select();

        if (response.isNotEmpty) {
          // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
          return _fromJson(response[0]);
        }
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        return null;
        // TODO: エラーハンドリングの詳細化が必要
      } catch (e) {
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        throw RepositoryException(
          RepositoryError.updateFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    }

    // マルチテナント機能有効の場合
    // user_idの更新を防ぐ
    final Map<String, dynamic> safeUpdates = Map<String, dynamic>.from(updates)
    ..remove(_userIdColumn)
    ..remove("user_id");

    // 現在のユーザーのエンティティのみ更新対象とする
    final T? existing = await getByPrimaryKey(keyMap);
    if (existing == null) {
      return null;
    }

    // 結果として更新を実行（user_idは既にチェック済み）
    try {
      final List<Map<String, dynamic>> response = await _applyPrimaryKey(
        _table.update(safeUpdates),
        keyMap,
      ).select();

      if (response.isNotEmpty) {
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        return _fromJson(response[0]);
      }
      // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
      return null;
      // TODO: エラーハンドリングの詳細化が必要
    } catch (e) {
      // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
      throw RepositoryException(
        RepositoryError.updateFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// IDによってエンティティを削除（user_idフィルタ自動適用）
  Future<void> deleteById(ID id) async {
    if (!enableMultiTenant) {
      try {
        final PrimaryKeyMap keyMap = _normalizeKey(id);
        await _applyPrimaryKey(_table.delete(), keyMap);
      } catch (e) {
        if (e is InvalidIdTypeException) {
          throw RepositoryException(
            RepositoryError.invalidQueryParameters,
            params: <String, String>{"error": "Invalid ID type: ${id.runtimeType}"},
          );
        }
        throw RepositoryException(
          RepositoryError.deleteFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    } else {
      // マルチテナント機能有効の場合
      // 現在のユーザーのエンティティのみ削除対象とする
      final T? existing = await getById(id);
      if (existing == null) {
        return; // 存在しないか、他のユーザーのデータ
      }

      // 実際の削除を実行（user_idは既にチェック済み）
      try {
        final PrimaryKeyMap keyMap = _normalizeKey(id);
        await _applyPrimaryKey(_table.delete(), keyMap);
      } catch (e) {
        if (e is InvalidIdTypeException) {
          throw RepositoryException(
            RepositoryError.invalidQueryParameters,
            params: <String, String>{"error": "Invalid ID type: ${id.runtimeType}"},
          );
        }
        throw RepositoryException(
          RepositoryError.deleteFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    }
  }

  /// 主キーマップによってエンティティを削除（user_idフィルタ自動適用）
  Future<void> deleteByPrimaryKey(PrimaryKeyMap keyMap) async {
    if (!enableMultiTenant) {
      try {
        await _applyPrimaryKey(_table.delete(), keyMap);
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        // TODO: エラーハンドリングの詳細化が必要
      } catch (e) {
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        throw RepositoryException(
          RepositoryError.deleteFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    } else {
      // マルチテナント機能有効の場合
      // 現在のユーザーのエンティティのみ削除対象とする
      final T? existing = await getByPrimaryKey(keyMap);
      if (existing == null) {
        return; // 存在しないか、他のユーザーのデータ
      }

      // 実際の削除を実行（user_idは既にチェック済み）
      try {
        await _applyPrimaryKey(_table.delete(), keyMap);
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        // TODO: エラーハンドリングの詳細化が必要
      } catch (e) {
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        throw RepositoryException(
          RepositoryError.deleteFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    }
  }

  /// 複数エンティティを一括削除（user_idフィルタ自動適用）
  Future<void> bulkDelete(List<ID> keys) async {
    if (keys.isEmpty) {
      return;
    }

    if (!enableMultiTenant) {
      try {
        // 単一カラム主キーの場合はin演算子を使用
        if (primaryKeyColumns.length == 1) {
          final String pkColumn = primaryKeyColumns[0];
          // 主キーカラムを正規化して値のリストを作成
          final List<Object> values = keys.map((ID key) {
            final PrimaryKeyMap normalized = _normalizeKey(key);
            final dynamic value = normalized[pkColumn];
            if (value is String || value is int || value is double || value is bool) {
              return value as Object;
            } else {
              throw ArgumentError("主キーカラム '$pkColumn' の値が無効な型です: ${value.runtimeType}");
            }
          }).toList();

          await _table.delete().inFilter(pkColumn, values);
          // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        } else {
          // 複合主キーの場合は効率的な削除のためチャンク処理
          const int chunkSize = 100;
          for (int i = 0; i < keys.length; i += chunkSize) {
            final int end = (i + chunkSize < keys.length) ? i + chunkSize : keys.length;
            final List<ID> chunk = keys.sublist(i, end);

            // 各チャンクを並列削除
            await Future.wait(
              chunk.map((ID key) async {
                if (key is Map<String, dynamic>) {
                  return deleteByPrimaryKey(key);
                } else {
                  return deleteById(key);
                }
              }),
            );
          }
          // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        }
        // TODO: エラーハンドリングの詳細化が必要
      } catch (e) {
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        throw RepositoryException(
          RepositoryError.deleteFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    } else {
      // マルチテナント機能有効の場合
      // 各IDについて現在のユーザーのデータのみ削除
      final List<ID> userOwnedKeys = <ID>[];
      
      for (final ID key in keys) {
        final T? entity = await getById(key);
        if (entity != null && belongsToCurrentUser(entity)) {
          userOwnedKeys.add(key);
        }
      }

      if (userOwnedKeys.isNotEmpty) {
        // 各キーを個別に削除（既にuser_idチェック済み）
        try {
          // 単一カラム主キーの場合はin演算子を使用
          if (primaryKeyColumns.length == 1) {
            final String pkColumn = primaryKeyColumns[0];
            final List<Object> values = userOwnedKeys.map((ID key) {
              final PrimaryKeyMap normalized = _normalizeKey(key);
              final dynamic value = normalized[pkColumn];
              if (value is String || value is int || value is double || value is bool) {
                return value as Object;
              } else {
                throw ArgumentError("主キーカラム '$pkColumn' の値が無効な型です: ${value.runtimeType}");
              }
            }).toList();

            await _table.delete().inFilter(pkColumn, values);
          } else {
            // 複合主キーの場合はチャンク処理
            const int chunkSize = 100;
            for (int i = 0; i < userOwnedKeys.length; i += chunkSize) {
              final int end = (i + chunkSize < userOwnedKeys.length) ? i + chunkSize : userOwnedKeys.length;
              final List<ID> chunk = userOwnedKeys.sublist(i, end);

              await Future.wait(
                chunk.map((ID key) async {
                  final PrimaryKeyMap keyMap = _normalizeKey(key);
                  await _applyPrimaryKey(_table.delete(), keyMap);
                }),
              );
            }
          }
        } catch (e) {
          throw RepositoryException(
            RepositoryError.deleteFailed,
            params: <String, String>{"error": e.toString()},
          );
        }
      }
    }
  }

  /// IDによってエンティティの存在を確認（user_idフィルタ自動適用）
  Future<bool> existsById(ID id) async {
    if (!enableMultiTenant) {
      try {
        final PrimaryKeyMap keyMap = _normalizeKey(id);
        final PostgrestResponse<List<Map<String, dynamic>>> response = await _applyPrimaryKey(
          _table.select(primaryKeyColumns.join(", ")),
          keyMap,
        ).limit(1).count(); // TODO: 存在チェック用のより効率的なメソッドがあるか調査

        return response.count > 0;
        // TODO: エラーハンドリングの詳細化が必要
      } catch (e) {
        throw RepositoryException(
          RepositoryError.databaseConnectionFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    }

    // マルチテナント機能有効の場合
    final T? entity = await getById(id);
    return entity != null;
  }

  /// 主キーマップによってエンティティの存在を確認（user_idフィルタ自動適用）
  Future<bool> existsByPrimaryKey(PrimaryKeyMap keyMap) async {
    if (!enableMultiTenant) {
      try {
        final PostgrestResponse<List<Map<String, dynamic>>> response = await _applyPrimaryKey(
          _table.select(primaryKeyColumns.join(", ")),
          keyMap,
        ).limit(1).count(); // TODO: 存在チェック用のより効率的なメソッドがあるか調査

        return response.count > 0;
        // TODO: エラーハンドリングの詳細化が必要
      } catch (e) {
        throw RepositoryException(
          RepositoryError.databaseConnectionFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    }

    // マルチテナント機能有効の場合
    final T? entity = await getByPrimaryKey(keyMap);
    return entity != null;
  }

  // =================================================================
  // リスト・検索機能
  // =================================================================

  /// エンティティのリストを取得（user_idフィルタ自動適用）
  Future<List<T>> list({int limit = 100, int offset = 0}) async {
    if (limit <= 0) {
      throw ArgumentError("limitは正の数である必要があります");
    }

    if (!enableMultiTenant) {
      try {
        // クエリビルダーを使用してデータを取得
        final List<Map<String, dynamic>> response = await _table.select().range(
          offset,
          offset + limit - 1,
        );

        return response.map(_fromJson).toList();
        // TODO: エラーハンドリングの詳細化が必要
      } catch (e) {
        // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
        throw RepositoryException(
          RepositoryError.databaseConnectionFailed,
          params: <String, String>{"error": e.toString()},
        );
      }
    }

    // マルチテナント機能有効の場合
    final List<QueryFilter> filters = _addUserIdFilter(null);
    return find(filters: filters, limit: limit, offset: offset);
  }

  /// 条件によってエンティティを検索する（user_idフィルタ自動適用）
  Future<List<T>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) async {
    if (limit <= 0) {
      throw ArgumentError("limitは正の数である必要があります");
    }

    try {
      final List<QueryFilter> filtersWithUserId = _addUserIdFilter(filters);

      // ベースクエリを構築
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _table.select();

      // フィルタ条件を適用
      if (filtersWithUserId.isNotEmpty) {
        query = QueryUtils.applyFilters(query, filtersWithUserId);
      }

      // rangeを適用してTransformBuilderに変換
      PostgrestTransformBuilder<List<Map<String, dynamic>>> transformQuery = query.range(
        offset,
        offset + limit - 1,
      );

      // ソート条件を適用
      if (orderBy != null && orderBy.isNotEmpty) {
        transformQuery = QueryUtils.applyOrderBys(transformQuery, orderBy);
      }

      final List<Map<String, dynamic>> response = await transformQuery;

      return response.map(_fromJson).toList();
      // TODO: エラーハンドリングの詳細化が必要
    } catch (e) {
      // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 条件に一致するエンティティの数を取得する（user_idフィルタ自動適用）
  Future<int> count({List<QueryFilter>? filters}) async {
    try {
      final List<QueryFilter> filtersWithUserId = _addUserIdFilter(filters);
      
      if (filtersWithUserId.isNotEmpty) {
        // 条件付きカウントの場合
        final PostgrestFilterBuilder<List<Map<String, dynamic>>> baseQuery = _table.select();
        final PostgrestFilterBuilder<List<Map<String, dynamic>>> query = QueryUtils.applyFilters(baseQuery, filtersWithUserId);
        final PostgrestResponse<List<Map<String, dynamic>>> response = await query.count();
        return response.count;
      } else {
        // 全件カウントの場合（マルチテナント機能無効のみ）
        final int response = await _table.count();
        return response;
      }
      // TODO: エラーハンドリングの詳細化が必要
    } catch (e) {
      // NOTE: エラー分類・ログレベル・戻り値の標準化が必要
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  // =================================================================
  // マルチテナント用新しいメソッド  
  // =================================================================

  /// 現在のユーザーIDを取得（認証確認付き）
  String getCurrentUserId() {
    if (!enableMultiTenant) {
      throw ArgumentError("マルチテナント機能が無効のため、ユーザーIDを取得できません。");
    }
    return _requireAuthenticatedUserId();
  }

  /// 指定したエンティティが現在のユーザーに属するかチェック
  bool belongsToCurrentUser(T entity) {
    if (!enableMultiTenant) {
      return true; // マルチテナント機能が無効の場合は常にtrue
    }
    final String? currentUserId = _currentUserId;
    return currentUserId != null && entity.userId == currentUserId;
  }

  /// 複数エンティティが現在のユーザーに属するかチェック
  bool allBelongToCurrentUser(List<T> entities) {
    if (!enableMultiTenant) {
      return true; // マルチテナント機能が無効の場合は常にtrue
    }
    return entities.every(belongsToCurrentUser);
  }

  /// マルチテナント非対応のfindメソッド（管理者用）
  /// 
  /// 注意：このメソッドはuser_idフィルタを適用しません。
  /// 管理者機能や特別な用途でのみ使用してください。
  Future<List<T>> findWithoutUserFilter({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) async {
    if (limit <= 0) {
      throw ArgumentError("limitは正の数である必要があります");
    }

    try {
      // ベースクエリを構築
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _table.select();

      // フィルタ条件を適用（user_idフィルタなし）
      if (filters != null && filters.isNotEmpty) {
        query = QueryUtils.applyFilters(query, filters);
      }

      // rangeを適用してTransformBuilderに変換
      PostgrestTransformBuilder<List<Map<String, dynamic>>> transformQuery = query.range(
        offset,
        offset + limit - 1,
      );

      // ソート条件を適用
      if (orderBy != null && orderBy.isNotEmpty) {
        transformQuery = QueryUtils.applyOrderBys(transformQuery, orderBy);
      }

      final List<Map<String, dynamic>> response = await transformQuery;
      return response.map(_fromJson).toList();
    } catch (e) {
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// マルチテナント非対応のcountメソッド（管理者用）
  /// 
  /// 注意：このメソッドはuser_idフィルタを適用しません。
  /// 管理者機能や特別な用途でのみ使用してください。
  Future<int> countWithoutUserFilter({List<QueryFilter>? filters}) async {
    try {
      if (filters != null && filters.isNotEmpty) {
        // 条件付きカウントの場合（user_idフィルタなし）
        final PostgrestFilterBuilder<List<Map<String, dynamic>>> baseQuery = _table.select();
        final PostgrestFilterBuilder<List<Map<String, dynamic>>> query = QueryUtils.applyFilters(baseQuery, filters);
        final PostgrestResponse<List<Map<String, dynamic>>> response = await query.count();
        return response.count;
      } else {
        // 全件カウントの場合
        final int response = await _table.count();
        return response;
      }
    } catch (e) {
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }
}
