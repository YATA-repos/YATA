import "package:supabase_flutter/supabase_flutter.dart";

import "../constants/exceptions/exceptions.dart";
import "../constants/query_types.dart";
import "../../data/remote/supabase_client.dart";
import "../logging/logger_mixin.dart";
import "../utils/query_utils.dart";
import "../validation/type_validator.dart";
import "base_model.dart";

/// プライマリキー
typedef PrimaryKeyMap = Map<String, dynamic>;

/// ベースCRUDリポジトリ抽象クラス
abstract class BaseRepository<T extends BaseModel, ID> with LoggerMixin {
  BaseRepository({required this.tableName, this.primaryKeyColumns = const <String>["id"]});

  final String tableName;

  /// 主キーカラム名のリスト（複合主キー対応）
  final List<String> primaryKeyColumns;

  /// JSONからモデルインスタンスを作成するファクトリ関数
  ///
  /// サブクラスで実装し、対応するモデルのfromJsonメソッドを呼び出します。
  /// これにより、シリアライゼーション処理をモデル側に完全に集約できます。
  T fromJson(Map<String, dynamic> json);

  /// Supabaseクライアント取得
  SupabaseClient get _client => SupabaseClientService.client;

  /// クエリビルダー取得
  SupabaseQueryBuilder get _table => _client.from(tableName);

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
      logError("Invalid ID type provided: ${key.runtimeType}");
      throw InvalidIdTypeException(key.runtimeType, <Type>[String, int, Map]);
    }

    if (key is Map<String, dynamic>) {
      return key;
    }

    // 単一値の場合、主キーカラムが1つであることを確認
    if (primaryKeyColumns.length != 1) {
      logError("複合主キーを使用する場合は、Map<String, dynamic>形式でキーを指定してください");
      throw ArgumentError("複合主キーにはMap<String, dynamic>形式でキーを指定してください");
    }

    return <String, dynamic>{primaryKeyColumns[0]: key};
  }

  /// フィルタ条件を使用したエンティティの単一取得
  Future<T?> findOne({List<QueryFilter>? filters}) async {
    try {
      logDebug("Finding single entity in table: $tableName");

      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _table.select();

      if (filters != null && filters.isNotEmpty) {
        query = QueryUtils.applyFilters(query, filters);
      }

      final Map<String, dynamic>? response = await query.maybeSingle();

      if (response != null) {
        logDebug("Entity found in table: $tableName");
        return _fromJson(response);
      }

      logDebug("Entity not found in table: $tableName");
      return null;
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to find single entity in table: $tableName", e);
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

  /// エンティティを作成
  Future<T?> create(T entity) async {
    try {
      logDebug("Creating entity in table: $tableName");
      final Map<String, dynamic> data = entity.toJson();
      final List<Map<String, dynamic>> response = await _table.insert(data).select();

      if (response.isNotEmpty) {
        // * 事前定義するべきか検討
        logInfo("Entity created successfully in table: $tableName");
        return _fromJson(response[0]);
      }
      // * 事前定義するべきか検討
      logWarning("No response returned from entity creation in table: $tableName");
      return null;
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to create entity in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.insertFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 複数エンティティを一括作成
  Future<List<T>> bulkCreate(List<T> entities) async {
    if (entities.isEmpty) {
      return <T>[];
    }

    try {
      logDebug("Bulk creating ${entities.length} entities in table: $tableName");
      final List<Map<String, dynamic>> dataList = entities.map((T e) => e.toJson()).toList();
      final List<Map<String, dynamic>> response = await _table.insert(dataList).select();

      // * 事前定義するべきか検討
      logInfo("Bulk created ${response.length} entities in table: $tableName");
      return response.map(_fromJson).toList();
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to bulk create entities in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.insertFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// IDによってエンティティを取得
  Future<T?> getById(ID id) async {
    try {
      logDebug("Getting entity by ID from table: $tableName");
      final PrimaryKeyMap keyMap = _normalizeKey(id);
      final Map<String, dynamic>? response = await _applyPrimaryKey(
        _table.select(),
        keyMap,
      ).maybeSingle();

      if (response != null) {
        logDebug("Entity found in table: $tableName");
        return _fromJson(response);
      }
      logDebug("Entity not found in table: $tableName");
      return null;
    } catch (e) {
      if (e is InvalidIdTypeException) {
        logError("Type error in getById: invalid id type", e);
        throw RepositoryException(
          RepositoryError.invalidQueryParameters,
          params: <String, String>{"error": "Invalid ID type: ${id.runtimeType}"},
        );
      }
      logError("Failed to get entity by ID in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 主キーマップによってエンティティを取得
  Future<T?> getByPrimaryKey(PrimaryKeyMap keyMap) async {
    try {
      logDebug("Getting entity by primary key from table: $tableName");
      final Map<String, dynamic>? response = await _applyPrimaryKey(
        _table.select(),
        keyMap,
      ).maybeSingle();

      if (response != null) {
        logDebug("Entity found in table: $tableName");
        return _fromJson(response);
      }
      logDebug("Entity not found in table: $tableName");
      return null;
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to get entity by primary key in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// IDによってエンティティを更新
  Future<T?> updateById(ID id, Map<String, dynamic> updates) async {
    try {
      logDebug("Updating entity by ID in table: $tableName");
      final PrimaryKeyMap keyMap = _normalizeKey(id);
      final List<Map<String, dynamic>> response = await _applyPrimaryKey(
        _table.update(updates),
        keyMap,
      ).select();

      if (response.isNotEmpty) {
        logInfo("Entity updated successfully in table: $tableName");
        return _fromJson(response[0]);
      }
      logWarning("No entity updated in table: $tableName");
      return null;
    } catch (e) {
      if (e is InvalidIdTypeException) {
        logError("Type error in updateById: invalid id type", e);
        throw RepositoryException(
          RepositoryError.invalidQueryParameters,
          params: <String, String>{"error": "Invalid ID type: ${id.runtimeType}"},
        );
      }
      logError("Failed to update entity by ID in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.updateFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 主キーマップによってエンティティを更新
  Future<T?> updateByPrimaryKey(PrimaryKeyMap keyMap, Map<String, dynamic> updates) async {
    try {
      logDebug("Updating entity by primary key in table: $tableName");
      final List<Map<String, dynamic>> response = await _applyPrimaryKey(
        _table.update(updates),
        keyMap,
      ).select();

      if (response.isNotEmpty) {
        // * 事前定義するべきか検討
        logInfo("Entity updated successfully by primary key in table: $tableName");
        return _fromJson(response[0]);
      }
      // * 事前定義するべきか検討
      logWarning("No entity updated by primary key in table: $tableName");
      return null;
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to update entity by primary key in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.updateFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// IDによってエンティティを削除
  Future<void> deleteById(ID id) async {
    try {
      logDebug("Deleting entity by ID from table: $tableName");
      final PrimaryKeyMap keyMap = _normalizeKey(id);
      await _applyPrimaryKey(_table.delete(), keyMap);
      logInfo("Entity deleted successfully from table: $tableName");
    } catch (e) {
      if (e is InvalidIdTypeException) {
        logError("Type error in deleteById: invalid id type", e);
        throw RepositoryException(
          RepositoryError.invalidQueryParameters,
          params: <String, String>{"error": "Invalid ID type: ${id.runtimeType}"},
        );
      }
      logError("Failed to delete entity by ID from table: $tableName", e);
      throw RepositoryException(
        RepositoryError.deleteFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 主キーマップによってエンティティを削除
  Future<void> deleteByPrimaryKey(PrimaryKeyMap keyMap) async {
    try {
      logDebug("Deleting entity by primary key from table: $tableName");
      await _applyPrimaryKey(_table.delete(), keyMap);
      // * 事前定義するべきか検討
      logInfo("Entity deleted successfully by primary key from table: $tableName");
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to delete entity by primary key from table: $tableName", e);
      throw RepositoryException(
        RepositoryError.deleteFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 複数エンティティを一括削除
  Future<void> bulkDelete(List<ID> keys) async {
    if (keys.isEmpty) {
      return;
    }

    try {
      logDebug("Bulk deleting ${keys.length} entities from table: $tableName");
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
        // * 事前定義するべきか検討
        logInfo("Bulk deleted ${keys.length} entities from table: $tableName");
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
        // * 事前定義するべきか検討
        logInfo("Bulk deleted ${keys.length} entities with composite keys from table: $tableName");
      }
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to bulk delete entities from table: $tableName", e);
      throw RepositoryException(
        RepositoryError.deleteFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// IDによってエンティティの存在を確認
  Future<bool> existsById(ID id) async {
    try {
      final PrimaryKeyMap keyMap = _normalizeKey(id);
      final PostgrestResponse<List<Map<String, dynamic>>> response = await _applyPrimaryKey(
        _table.select(primaryKeyColumns.join(", ")),
        keyMap,
      ).limit(1).count(); // ? `limit(1)`のカウントでいいんだっけ?existsみたいなの無かった？

      return response.count > 0;
      // ? エラーハンドリング詳細化？
    } catch (e) {
      logError("Failed to check entity existence by ID in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 主キーマップによってエンティティの存在を確認
  Future<bool> existsByPrimaryKey(PrimaryKeyMap keyMap) async {
    try {
      final PostgrestResponse<List<Map<String, dynamic>>> response = await _applyPrimaryKey(
        _table.select(primaryKeyColumns.join(", ")),
        keyMap,
      ).limit(1).count(); // ? existsByIdと同様の疑問

      return response.count > 0;
      // ? エラーハンドリング詳細化？
    } catch (e) {
      logError("Failed to check entity existence by primary key in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  // =================================================================
  // リスト・検索機能
  // =================================================================

  /// エンティティのリストを取得
  Future<List<T>> list({int limit = 100, int offset = 0}) async {
    if (limit <= 0) {
      throw ArgumentError("limitは正の数である必要があります");
    }

    try {
      logDebug("Listing entities from table: $tableName (limit: $limit, offset: $offset)");
      // クエリビルダーを使用してデータを取得
      final List<Map<String, dynamic>> response = await _table.select().range(
        offset,
        offset + limit - 1,
      );

      logDebug("Retrieved ${response.length} entities from table: $tableName");
      return response.map(_fromJson).toList();
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to list entities from table: $tableName", e);
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 条件によってエンティティを検索する
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
      logDebug("Finding entities in table: $tableName (limit: $limit, offset: $offset)");

      // ベースクエリを構築
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _table.select();

      // フィルタ条件を適用
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

      logDebug("Found ${response.length} entities in table: $tableName");
      return response.map(_fromJson).toList();
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to find entities in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 条件に一致するエンティティの数を取得する
  Future<int> count({List<QueryFilter>? filters}) async {
    try {
      if (filters != null && filters.isNotEmpty) {
        // 条件付きカウントの場合
        logDebug("Counting entities with condition in table: $tableName");
        final PostgrestFilterBuilder<List<Map<String, dynamic>>> baseQuery = _table.select();
        final PostgrestFilterBuilder<List<Map<String, dynamic>>> query = QueryUtils.applyFilters(baseQuery, filters);
        final PostgrestResponse<List<Map<String, dynamic>>> response = await query.count();
        logDebug("Counted ${response.count} entities in table: $tableName");
        return response.count;
      } else {
        // 全件カウントの場合
        logDebug("Counting all entities in table: $tableName");
        final int response = await _table.count();
        logDebug("Counted $response entities in table: $tableName");
        return response;
      }
      // ? エラーハンドリング詳細化？
    } catch (e) {
      // * 事前定義するべきか検討
      logError("Failed to count entities in table: $tableName", e);
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }
}
