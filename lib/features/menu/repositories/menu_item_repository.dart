import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/menu_model.dart";

/// メニューアイテムリポジトリ
class MenuItemRepository extends BaseRepository<MenuItem, String> {
  /// コンストラクタ
  MenuItemRepository() : super(tableName: "menu_items");

  @override
  MenuItem Function(Map<String, dynamic> json) get fromJson =>
      MenuItem.fromJson;

  /// カテゴリIDでメニューアイテムを取得（None時は全件）
  Future<List<MenuItem>> findByCategoryId(
    String? categoryId,
    String userId,
  ) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
    ];

    if (categoryId != null) {
      filters.add(QueryConditionBuilder.eq("category_id", categoryId));
    }

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 販売可能なメニューアイテムのみ取得
  Future<List<MenuItem>> findAvailableOnly(String userId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.eq("is_available", true),
    ];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }

  /// 名前でメニューアイテムを検索
  Future<List<MenuItem>> searchByName(dynamic keyword, String userId) async {
    // キーワードの正規化
    List<String> keywords;
    if (keyword is String) {
      keywords = keyword.trim().isNotEmpty
          ? <String>[keyword.trim()]
          : <String>[];
    } else if (keyword is List<String>) {
      keywords = keyword
          .map((String k) => k.trim())
          .where((String k) => k.isNotEmpty)
          .toList();
    } else {
      keywords = <String>[];
    }

    if (keywords.isEmpty) {
      return <MenuItem>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
    ];

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
  Future<List<MenuItem>> findByIds(
    List<String> menuItemIds,
    String userId,
  ) async {
    if (menuItemIds.isEmpty) {
      return <MenuItem>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("user_id", userId),
      QueryConditionBuilder.inList("id", menuItemIds),
    ];

    return find(filters: filters);
  }
}
