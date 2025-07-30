import "../../../core/base/base_multitenant_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/inventory_model.dart";

/// レシピリポジトリ
class RecipeRepository extends BaseMultiTenantRepository<Recipe, String> {
  RecipeRepository({required super.ref}) : super(tableName: "recipes");

  @override
  Recipe fromJson(Map<String, dynamic> json) => Recipe.fromJson(json);

  /// メニューアイテムIDでレシピ一覧を取得
  Future<List<Recipe>> findByMenuItemId(String menuItemId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("menu_item_id", menuItemId),
    ];

    return find(filters: filters);
  }

  /// 材料IDを使用するレシピ一覧を取得
  Future<List<Recipe>> findByMaterialId(String materialId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
    ];

    return find(filters: filters);
  }

  /// 複数メニューアイテムのレシピを一括取得
  Future<List<Recipe>> findByMenuItemIds(List<String> menuItemIds) async {
    if (menuItemIds.isEmpty) {
      return <Recipe>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.inList("menu_item_id", menuItemIds),
    ];

    return find(filters: filters);
  }
}
