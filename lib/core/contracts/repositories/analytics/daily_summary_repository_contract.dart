import "../../../base/base_model.dart";
import "../../repositories/crud_repository.dart";

abstract interface class DailySummaryRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<T?> findByDate(DateTime targetDate);
  Future<List<T>> findByDateRange(DateTime dateFrom, DateTime dateTo);
}
