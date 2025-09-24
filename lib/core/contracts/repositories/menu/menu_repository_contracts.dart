import "../../../base/base_model.dart";
import "../../repositories/crud_repository.dart";

abstract interface class MenuItemRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findByCategoryId(String? categoryId);
  Future<List<T>> findAvailableOnly();
  Future<List<T>> searchByName(dynamic keyword);
  Future<List<T>> findByIds(List<String> menuItemIds);
}

abstract interface class MenuCategoryRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findActiveOrdered();
}
