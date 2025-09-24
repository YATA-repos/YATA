import "../../../base/base_model.dart";
import "../../repositories/crud_repository.dart";

abstract interface class StockAdjustmentRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findByMaterialId(String materialId);
  Future<List<T>> findRecent(int days);
}
