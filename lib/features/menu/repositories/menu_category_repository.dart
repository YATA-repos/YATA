import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/menu/menu_repository_contracts.dart";
import "../models/menu_model.dart";

class MenuCategoryRepository implements MenuCategoryRepositoryContract<MenuCategory> {
  MenuCategoryRepository({required repo_contract.CrudRepository<MenuCategory, String> delegate})
    : _delegate = delegate;

  final repo_contract.CrudRepository<MenuCategory, String> _delegate;

  /// アクティブなカテゴリ一覧を表示順で取得
  @override
  Future<List<MenuCategory>> findActiveOrdered() async {
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return _delegate.find(orderBy: orderBy);
  }

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<MenuCategory?> create(MenuCategory entity) => _delegate.create(entity);

  @override
  Future<List<MenuCategory>> bulkCreate(List<MenuCategory> entities) =>
      _delegate.bulkCreate(entities);

  @override
  Future<MenuCategory?> getById(String id) => _delegate.getById(id);

  @override
  Future<MenuCategory?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<MenuCategory?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<MenuCategory?> updateByPrimaryKey(
    Map<String, dynamic> keyMap,
    Map<String, dynamic> updates,
  ) => _delegate.updateByPrimaryKey(keyMap, updates);

  @override
  Future<void> deleteById(String id) => _delegate.deleteById(id);

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.deleteByPrimaryKey(keyMap);

  @override
  Future<void> bulkDelete(List<String> keys) => _delegate.bulkDelete(keys);

  @override
  Future<List<MenuCategory>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
