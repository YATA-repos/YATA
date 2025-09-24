import "../../base/base_model.dart";
import "../../constants/query_types.dart";

/// プライマリキー
typedef PrimaryKeyMap = Map<String, dynamic>;

/// DB非依存の汎用CRUD契約
///
/// - 実装は `infra/` 側で具体データソース（Supabase等）に接続する
/// - フィルタ/並び替えは暫定的に `core/constants/query_types.dart` を使用
/// - マルチテナントや認証は実装側で扱い、契約には含めない
abstract class CrudRepository<T extends BaseModel, ID> {
  /// エンティティ作成
  Future<T?> create(T entity);

  /// 複数エンティティ一括作成
  Future<List<T>> bulkCreate(List<T> entities);

  /// IDによる取得
  Future<T?> getById(ID id);

  /// 主キーマップによる取得（複合主キー対応）
  Future<T?> getByPrimaryKey(PrimaryKeyMap keyMap);

  /// IDによる更新
  Future<T?> updateById(ID id, Map<String, dynamic> updates);

  /// 主キーマップによる更新
  Future<T?> updateByPrimaryKey(PrimaryKeyMap keyMap, Map<String, dynamic> updates);

  /// IDによる削除
  Future<void> deleteById(ID id);

  /// 主キーマップによる削除
  Future<void> deleteByPrimaryKey(PrimaryKeyMap keyMap);

  /// 複数削除
  Future<void> bulkDelete(List<ID> keys);

  /// 検索
  Future<List<T>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  });

  /// 件数取得
  Future<int> count({List<QueryFilter>? filters});
}
