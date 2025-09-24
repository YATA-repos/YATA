import "../../../base/base_model.dart";
import "../../../constants/enums.dart";
import "../../../constants/query_types.dart";
import "../../repositories/crud_repository.dart";

abstract interface class OrderRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<T?> findActiveDraftByUser();
  Future<List<T>> findByStatusList(List<OrderStatus> statusList);
  Future<(List<T>, int)> searchWithPagination(List<QueryFilter> filters, int page, int limit);
  Future<List<T>> findByDateRange(DateTime dateFrom, DateTime dateTo);
  Future<List<T>> findCompletedByDate(DateTime targetDate);
  Future<String> generateNextOrderNumber();
  Future<List<T>> findOrdersByCompletionTimeRange(DateTime startTime, DateTime endTime);
  Future<List<T>> findActiveOrders();
  Future<List<T>> findRecentOrders({int limit = 10});
  Future<List<T>> findCompletedByDateRange(DateTime start, DateTime end);
  Future<Map<OrderStatus, Map<DateTime, int>>> countByStatusAndDateRange(
    DateTime start,
    DateTime end,
  );
  Future<Map<OrderStatus, List<T>>> getActiveOrdersByStatus();
}

abstract interface class OrderItemRepositoryContract<T extends BaseModel>
    implements CrudRepository<T, String> {
  Future<List<T>> findByOrderId(String orderId);
  Future<T?> findExistingItem(String orderId, String menuItemId);
  Future<bool> deleteByOrderId(String orderId);
  Future<List<T>> findByMenuItemAndDateRange(String menuItemId, DateTime dateFrom, DateTime dateTo);
  Future<List<Map<String, dynamic>>> getMenuItemSalesSummary(int days);
}
