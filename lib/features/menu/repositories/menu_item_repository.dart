import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/menu/menu_repository_contracts.dart";
import "../models/menu_model.dart";

class MenuItemRepository implements MenuItemRepositoryContract<MenuItem> {
  MenuItemRepository({required repo_contract.CrudRepository<MenuItem, String> delegate})
    : _delegate = delegate;

  final repo_contract.CrudRepository<MenuItem, String> _delegate;

  /// カテゴリIDでメニューアイテムを取得（None時は全件）
  @override
  Future<List<MenuItem>> findByCategoryId(String? categoryId) async {
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    if (categoryId == null) {
      return _delegate.find();
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("category_id", categoryId),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 販売可能なメニューアイテムのみ取得
  @override
  Future<List<MenuItem>> findAvailableOnly() async {
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.eq("is_available", true)];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return _delegate.find(filters: filters, orderBy: orderBy);
  }

  /// 名前でメニューアイテムを検索
  @override
  Future<List<MenuItem>> searchByName(dynamic keyword) async {
    // キーワードの正規化
    List<String> keywords;
    if (keyword is String) {
      keywords = keyword.trim().isNotEmpty ? <String>[keyword.trim()] : <String>[];
    } else if (keyword is List<String>) {
      keywords = keyword.map((String k) => k.trim()).where((String k) => k.isNotEmpty).toList();
    } else {
      keywords = <String>[];
    }

    if (keywords.isEmpty) {
      return <MenuItem>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[];

    // 複数キーワードの場合はAND条件で検索
    // Supabaseでは複数のilike条件は自動的にANDになる
    for (final String kw in keywords) {
      filters.add(QueryConditionBuilder.ilike("name", "%$kw%"));
    }

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// IDリストでメニューアイテムを取得
  @override
  Future<List<MenuItem>> findByIds(List<String> menuItemIds) async {
    if (menuItemIds.isEmpty) {
      return <MenuItem>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.inList("id", menuItemIds),
    ];

    return _delegate.find(filters: filters);
  }

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<MenuItem?> create(MenuItem entity) => _delegate.create(entity);

  @override
  Future<List<MenuItem>> bulkCreate(List<MenuItem> entities) => _delegate.bulkCreate(entities);

  @override
  Future<MenuItem?> getById(String id) => _delegate.getById(id);

  @override
  Future<MenuItem?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<MenuItem?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<MenuItem?> updateByPrimaryKey(Map<String, dynamic> keyMap, Map<String, dynamic> updates) =>
      _delegate.updateByPrimaryKey(keyMap, updates);

  @override
  Future<void> deleteById(String id) => _delegate.deleteById(id);

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.deleteByPrimaryKey(keyMap);

  @override
  Future<void> bulkDelete(List<String> keys) => _delegate.bulkDelete(keys);

  @override
  Future<List<MenuItem>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
