import "../../../base/base_model.dart";
import "../../../constants/enums.dart";
import "../../repositories/crud_repository.dart";

abstract interface class StockTransactionRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> createBatch(List<T> transactions);
  Future<List<T>> findByReference(ReferenceType referenceType, String referenceId);
  Future<List<T>> findByMaterialAndDateRange(String materialId, DateTime dateFrom, DateTime dateTo);
  Future<List<T>> findConsumptionTransactions(DateTime dateFrom, DateTime dateTo);
}
