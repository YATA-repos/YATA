import "../../../core/base/base_multitenant_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/menu_model.dart";

class MenuCategoryRepository extends BaseMultiTenantRepository<MenuCategory, String> {
  MenuCategoryRepository({required super.ref}) : super(tableName: "menu_categories");

  @override
  MenuCategory fromJson(Map<String, dynamic> json) => MenuCategory.fromJson(json);

  /// アクティブなカテゴリ一覧を表示順で取得
  Future<List<MenuCategory>> findActiveOrdered() async {
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return find(orderBy: orderBy);
  }
}
