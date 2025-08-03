import "../../../core/constants/query_types.dart";
import "../../../data/repositories/base_multitenant_repository.dart";
import "../models/menu_model.dart";

class MenuItemRepository extends BaseMultiTenantRepository<MenuItem, String> {
  MenuItemRepository({required super.ref}) : super(tableName: "menu_items");

  @override
  MenuItem fromJson(Map<String, dynamic> json) => MenuItem.fromJson(json);

  /// カテゴリIDでメニューアイテムを取得（None時は全件）
  Future<List<MenuItem>> findByCategoryId(String? categoryId) async {
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    if (categoryId == null) {
      return list();
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("category_id", categoryId),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 販売可能なメニューアイテムのみ取得
  Future<List<MenuItem>> findAvailableOnly() async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("is_available", true),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 名前でメニューアイテムを検索
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
  Future<List<MenuItem>> findByIds(List<String> menuItemIds) async {
    if (menuItemIds.isEmpty) {
      return <MenuItem>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.inList("id", menuItemIds),
    ];

    return find(filters: filters);
  }
}
