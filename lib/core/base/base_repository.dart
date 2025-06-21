import "package:supabase_flutter/supabase_flutter.dart";

import "../auth/auth_service.dart";
import "../constants/query_types.dart";
import "../error/repository.dart";
import "../utils/log_service.dart";
import "../utils/query_utils.dart";
import "base_model.dart";

/// 主キーマップ型定義
typedef PrimaryKeyMap = Map<String, dynamic>;

/// ベースCRUDリポジトリ抽象クラス
///
/// [T] モデル型（BaseModelを継承し、toJsonメソッドを持つ）
/// [ID] 単一主キーの型（String, int など）
abstract class BaseRepository<T extends BaseModel, ID> {
  /// コンストラクタ
  BaseRepository({
    required this.tableName,
    this.primaryKeyColumns = const <String>["id"],
  });

  /// テーブル名
  final String tableName;

  /// 主キーカラム名のリスト（複合主キー対応）
  final List<String> primaryKeyColumns;

  /// Supabaseクライアントを取得
  SupabaseClient get _client => SupabaseClientService.client;

  /// テーブルクエリビルダーを取得
  SupabaseQueryBuilder get _table => _client.from(tableName);

  /// JSONからモデルインスタンスを作成するファクトリ関数
  ///
  /// 各サブクラスで実装する必要があります
  T Function(Map<String, dynamic> json) get fromJson;

  /// 内部用JSONデシリアライゼーションヘルパー
  T _fromJson(Map<String, dynamic> json) => fromJson(json);

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  /// 単一キーを主キーマップに正規化
  PrimaryKeyMap _normalizeKey(dynamic key) {
    if (key is Map<String, dynamic>) {
      return key;
    }

    // 単一値の場合、主キーカラムが1つであることを確認
    if (primaryKeyColumns.length != 1) {
      throw ArgumentError("複合主キーにはMap<String, dynamic>形式でキーを指定してください");
    }

    return <String, dynamic>{primaryKeyColumns[0]: key};
  }

  /// フィルタ条件を使用したエンティティの単一取得
  Future<T?> findOne({List<QueryFilter>? filters}) async {
    try {
      LogService.debug(
        "BaseRepository",
        "Finding single entity in table: $tableName",
      );

      PostgrestFilterBuilder<dynamic> query =
          _table.select() as PostgrestFilterBuilder<dynamic>;

      if (filters != null && filters.isNotEmpty) {
        query = QueryUtils.applyFilters(query, filters);
      }

      final Map<String, dynamic>? response = await query.maybeSingle();

      if (response != null) {
        LogService.debug("BaseRepository", "Entity found in table: $tableName");
        return _fromJson(response);
      }

      LogService.debug(
        "BaseRepository",
        "Entity not found in table: $tableName",
      );
      return null;
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to find single entity in table: $tableName",
        null,
        e,
      );
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// クエリに主キー条件を適用
  PostgrestFilterBuilder<dynamic> _applyPrimaryKey(
    PostgrestFilterBuilder<dynamic> query,
    PrimaryKeyMap keyMap,
  ) {
    PostgrestFilterBuilder<dynamic> result = query;

    for (final String column in primaryKeyColumns) {
      if (!keyMap.containsKey(column)) {
        throw ArgumentError("主キーカラム '$column' がキーマップに見つかりません");
      }
      result = result.eq(column, keyMap[column] as Object);
    }

    return result;
  }

  // =================================================================
  // CRUD操作
  // =================================================================

  /// エンティティを作成
  Future<T?> create(T entity) async {
    try {
      LogService.debug(
        "BaseRepository",
        "Creating entity in table: $tableName",
      );
      final Map<String, dynamic> data = entity.toJson();
      final List<Map<String, dynamic>> response = await _table
          .insert(data)
          .select();

      if (response.isNotEmpty) {
        LogService.info(
          "BaseRepository",
          "Entity created successfully in table: $tableName",
        );
        return _fromJson(response[0]);
      }
      LogService.warning(
        "BaseRepository",
        "No response returned from entity creation in table: $tableName",
      );
      return null;
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to create entity in table: $tableName",
        null,
        e,
      );
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
      LogService.debug(
        "BaseRepository",
        "Bulk creating ${entities.length} entities in table: $tableName",
      );
      final List<Map<String, dynamic>> dataList = entities
          .map((T e) => e.toJson())
          .toList();
      final List<Map<String, dynamic>> response = await _table
          .insert(dataList)
          .select();

      LogService.info(
        "BaseRepository",
        "Bulk created ${response.length} entities in table: $tableName",
      );
      return response.map(_fromJson).toList();
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to bulk create entities in table: $tableName",
        null,
        e,
      );
      throw RepositoryException(
        RepositoryError.insertFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// IDによってエンティティを取得
  Future<T?> getById(ID id) async {
    try {
      LogService.debug(
        "BaseRepository",
        "Getting entity by ID from table: $tableName",
      );
      final PrimaryKeyMap keyMap = _normalizeKey(id);
      final Map<String, dynamic>? response = await _applyPrimaryKey(
        _table.select(),
        keyMap,
      ).maybeSingle();

      if (response != null) {
        LogService.debug("BaseRepository", "Entity found in table: $tableName");
        return _fromJson(response);
      }
      LogService.debug(
        "BaseRepository",
        "Entity not found in table: $tableName",
      );
      return null;
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to get entity by ID in table: $tableName",
        null,
        e,
      );
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 主キーマップによってエンティティを取得
  Future<T?> getByPrimaryKey(PrimaryKeyMap keyMap) async {
    try {
      final Map<String, dynamic>? response = await _applyPrimaryKey(
        _table.select(),
        keyMap,
      ).maybeSingle();

      if (response != null) {
        return _fromJson(response);
      }
      return null;
    } catch (e) {
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// IDによってエンティティを更新
  Future<T?> updateById(ID id, Map<String, dynamic> updates) async {
    try {
      LogService.debug(
        "BaseRepository",
        "Updating entity by ID in table: $tableName",
      );
      final PrimaryKeyMap keyMap = _normalizeKey(id);
      final List<Map<String, dynamic>> response = await _applyPrimaryKey(
        _table.update(updates),
        keyMap,
      ).select();

      if (response.isNotEmpty) {
        LogService.info(
          "BaseRepository",
          "Entity updated successfully in table: $tableName",
        );
        return _fromJson(response[0]);
      }
      LogService.warning(
        "BaseRepository",
        "No entity updated in table: $tableName",
      );
      return null;
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to update entity by ID in table: $tableName",
        null,
        e,
      );
      throw RepositoryException(
        RepositoryError.updateFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 主キーマップによってエンティティを更新
  Future<T?> updateByPrimaryKey(
    PrimaryKeyMap keyMap,
    Map<String, dynamic> updates,
  ) async {
    try {
      final List<Map<String, dynamic>> response = await _applyPrimaryKey(
        _table.update(updates),
        keyMap,
      ).select();

      if (response.isNotEmpty) {
        return _fromJson(response[0]);
      }
      return null;
    } catch (e) {
      throw RepositoryException(
        RepositoryError.updateFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// IDによってエンティティを削除
  Future<void> deleteById(ID id) async {
    try {
      LogService.debug(
        "BaseRepository",
        "Deleting entity by ID from table: $tableName",
      );
      final PrimaryKeyMap keyMap = _normalizeKey(id);
      await _applyPrimaryKey(_table.delete(), keyMap);
      LogService.info(
        "BaseRepository",
        "Entity deleted successfully from table: $tableName",
      );
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to delete entity by ID from table: $tableName",
        null,
        e,
      );
      throw RepositoryException(
        RepositoryError.deleteFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 主キーマップによってエンティティを削除
  Future<void> deleteByPrimaryKey(PrimaryKeyMap keyMap) async {
    try {
      await _applyPrimaryKey(_table.delete(), keyMap);
    } catch (e) {
      throw RepositoryException(
        RepositoryError.deleteFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 複数エンティティを一括削除
  Future<void> bulkDelete(List<dynamic> keys) async {
    if (keys.isEmpty) {
      return;
    }

    try {
      LogService.debug(
        "BaseRepository",
        "Bulk deleting ${keys.length} entities from table: $tableName",
      );
      // 単一カラム主キーの場合はin演算子を使用
      if (primaryKeyColumns.length == 1) {
        final String pkColumn = primaryKeyColumns[0];
        final List<dynamic> values = keys.map((dynamic key) {
          final PrimaryKeyMap normalized = _normalizeKey(key);
          return normalized[pkColumn];
        }).toList();

        await _table.delete().inFilter(pkColumn, values);
        LogService.info(
          "BaseRepository",
          "Bulk deleted ${keys.length} entities from table: $tableName",
        );
      } else {
        // 複合主キーの場合は効率的な削除のためチャンク処理
        const int chunkSize = 100;
        for (int i = 0; i < keys.length; i += chunkSize) {
          final int end = (i + chunkSize < keys.length)
              ? i + chunkSize
              : keys.length;
          final List<dynamic> chunk = keys.sublist(i, end);

          // 各チャンクを並列削除
          await Future.wait(
            chunk.map((dynamic key) async {
              if (key is Map<String, dynamic>) {
                return deleteByPrimaryKey(key);
              } else {
                return deleteById(key as ID);
              }
            }),
          );
        }
        LogService.info(
          "BaseRepository",
          "Bulk deleted ${keys.length} entities with composite keys from table: $tableName",
        );
      }
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to bulk delete entities from table: $tableName",
        null,
        e,
      );
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
      final PostgrestResponse<dynamic> response = await _applyPrimaryKey(
        _table.select(primaryKeyColumns.join(", ")),
        keyMap,
      ).limit(1).count();

      return response.count > 0;
    } catch (e) {
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 主キーマップによってエンティティの存在を確認
  Future<bool> existsByPrimaryKey(PrimaryKeyMap keyMap) async {
    try {
      final PostgrestResponse<dynamic> response = await _applyPrimaryKey(
        _table.select(primaryKeyColumns.join(", ")),
        keyMap,
      ).limit(1).count();

      return response.count > 0;
    } catch (e) {
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
      LogService.debug(
        "BaseRepository",
        "Listing entities from table: $tableName (limit: $limit, offset: $offset)",
      );
      final List<Map<String, dynamic>> response = await _table.select().range(
        offset,
        offset + limit - 1,
      );

      LogService.debug(
        "BaseRepository",
        "Retrieved ${response.length} entities from table: $tableName",
      );
      return response.map(_fromJson).toList();
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to list entities from table: $tableName",
        null,
        e,
      );
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 条件によってエンティティを検索
  ///
  /// [filters] フィルタ条件のリスト
  /// [orderBy] ソート条件のリスト
  /// [limit] 取得する件数の上限
  /// [offset] 取得開始位置
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
      LogService.debug(
        "BaseRepository",
        "Finding entities in table: $tableName (limit: $limit, offset: $offset)",
      );

      // ベースクエリを構築
      PostgrestTransformBuilder<List<Map<String, dynamic>>> query = _table
          .select()
          .range(offset, offset + limit - 1);

      // フィルタ条件を適用
      if (filters != null && filters.isNotEmpty) {
        query =
            QueryUtils.applyFilters(
                  query as PostgrestFilterBuilder<dynamic>,
                  filters,
                )
                as PostgrestTransformBuilder<List<Map<String, dynamic>>>;
      }

      // ソート条件を適用
      if (orderBy != null && orderBy.isNotEmpty) {
        query = QueryUtils.applyOrderBys(query, orderBy);
      }

      final List<Map<String, dynamic>> response = await query;

      LogService.debug(
        "BaseRepository",
        "Found ${response.length} entities in table: $tableName",
      );
      return response.map(_fromJson).toList();
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to find entities in table: $tableName",
        null,
        e,
      );
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }

  /// 条件に一致するエンティティの数を取得
  ///
  /// [filters] フィルタ条件のリスト
  Future<int> count({List<QueryFilter>? filters}) async {
    try {
      if (filters != null && filters.isNotEmpty) {
        // 条件付きカウントの場合
        LogService.debug(
          "BaseRepository",
          "Counting entities with condition in table: $tableName",
        );
        final PostgrestFilterBuilder<dynamic> baseQuery =
            _table.select() as PostgrestFilterBuilder<dynamic>;
        final PostgrestFilterBuilder<dynamic> query = QueryUtils.applyFilters(
          baseQuery,
          filters,
        );
        final PostgrestResponse<dynamic> response = await query.count();
        LogService.debug(
          "BaseRepository",
          "Counted ${response.count} entities in table: $tableName",
        );
        return response.count;
      } else {
        // 全件カウントの場合
        LogService.debug(
          "BaseRepository",
          "Counting all entities in table: $tableName",
        );
        final int response = await _table.count();
        LogService.debug(
          "BaseRepository",
          "Counted $response entities in table: $tableName",
        );
        return response;
      }
    } catch (e) {
      LogService.error(
        "BaseRepository",
        "Failed to count entities in table: $tableName",
        null,
        e,
      );
      throw RepositoryException(
        RepositoryError.databaseConnectionFailed,
        params: <String, String>{"error": e.toString()},
      );
    }
  }
}
