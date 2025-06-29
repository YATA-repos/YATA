import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/menu_model.dart";

/// メニューカテゴリリポジトリ
class MenuCategoryRepository extends BaseRepository<MenuCategory, String> {
  /// コンストラクタ
  MenuCategoryRepository() : super(tableName: "menu_categories");

  @override
  MenuCategory Function(Map<String, dynamic> json) get fromJson => MenuCategory.fromJson;

  /// アクティブなカテゴリ一覧を表示順で取得
  Future<List<MenuCategory>> findActiveOrdered(String userId) async {
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.eq("user_id", userId)];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }
}
