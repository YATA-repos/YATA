import "../../../core/base/base_multitenant_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/inventory_model.dart";

/// 材料カテゴリリポジトリ
class MaterialCategoryRepository extends BaseMultiTenantRepository<MaterialCategory, String> {
  MaterialCategoryRepository({required super.ref}) : super(tableName: "material_categories");

  @override
  MaterialCategory fromJson(Map<String, dynamic> json) => MaterialCategory.fromJson(json);

  /// アクティブなカテゴリ一覧を表示順で取得
  Future<List<MaterialCategory>> findActiveOrdered() async {
    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return find(orderBy: orderBy);
  }
}
