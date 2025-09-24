import "../../../base/base_model.dart";
import "../../repositories/crud_repository.dart";

abstract interface class MaterialCategoryRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findActiveOrdered();
}
