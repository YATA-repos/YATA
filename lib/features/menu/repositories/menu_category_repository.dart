import "../../../core/constants/query_types.dart";
import "../../../data/repositories/base_repository.dart";
import "../models/menu_model.dart";

class MenuCategoryRepository extends BaseRepository<MenuCategory, String> {
  MenuCategoryRepository({required super.ref}) : super(tableName: "menu_categories", enableMultiTenant: true);

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
