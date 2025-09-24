import "../../../base/base_model.dart";
import "../../repositories/crud_repository.dart";

abstract interface class SupplierRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findActive();
  Future<List<T>> findByName(String name);
  Future<T?> deactivate(String supplierId);
  Future<T?> reactivate(String supplierId);
}

abstract interface class MaterialSupplierRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findByMaterialId(String materialId);
  Future<List<T>> findBySupplierId(String supplierId);
  Future<T?> findPreferredSupplier(String materialId);
  Future<void> setPreferredSupplier(String materialId, String supplierId);
}
