import "../../../base/base_model.dart";
import "../../repositories/crud_repository.dart";

abstract interface class RecipeRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findByMenuItemId(String menuItemId);
  Future<List<T>> findByMaterialId(String materialId);
  Future<List<T>> findByMenuItemIds(List<String> menuItemIds);
  Future<T?> findByMenuItemAndMaterial(String menuItemId, String materialId);
  Future<T?> upsertByMenuItemAndMaterial(T entity);
  Future<void> deleteByMenuItemId(String menuItemId);
}
