import "../../../base/base_model.dart";
import "../../repositories/crud_repository.dart";

abstract interface class PurchaseRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findRecent(int days);
  Future<List<T>> findByDateRange(DateTime dateFrom, DateTime dateTo);
}

abstract interface class PurchaseItemRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findByPurchaseId(String purchaseId);
  Future<List<T>> createBatch(List<T> items);
}
