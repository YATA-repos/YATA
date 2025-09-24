import "../../core/base/base_model.dart";
import "../../core/contracts/repositories/crud_repository.dart";
import "base_repository.dart";

/// ジェネリックCRUD実装
///
/// モデルの `fromJson` を外部から受け取り、`BaseRepository` の抽象を満たす
/// シンプルな具象実装を提供する。これにより features 側は infra を参照せず、
/// app 層の合成で両者を橋渡しできる。
class GenericCrudRepository<T extends BaseModel> extends BaseRepository<T, String>
    implements CrudRepository<T, String> {
  GenericCrudRepository({
    required super.ref,
    required super.tableName,
    required T Function(Map<String, dynamic>) fromJson,
    super.enableMultiTenant,
    super.primaryKeyColumns,
    super.userIdColumn,
  }) : _fromJson = fromJson;

  final T Function(Map<String, dynamic>) _fromJson;

  @override
  T fromJson(Map<String, dynamic> json) => _fromJson(json);
}
