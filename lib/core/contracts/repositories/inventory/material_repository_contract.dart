import "../../../base/base_model.dart";
import "../../repositories/crud_repository.dart";

/// 材料リポジトリ契約（ドメイン拡張）
abstract interface class MaterialRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findByCategoryId(String? categoryId);
  Future<List<T>> findByIds(List<String> materialIds);
  Future<T?> updateStockAmount(String materialId, double newAmount);
}
