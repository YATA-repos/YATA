import "../../../core/base/base_repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/inventory_model.dart";

/// 材料カテゴリリポジトリ
class MaterialCategoryRepository extends BaseRepository<MaterialCategory, String> {
  /// コンストラクタ
  MaterialCategoryRepository() : super(tableName: "material_categories");

  @override
  MaterialCategory fromJson(Map<String, dynamic> json) => MaterialCategory.fromJson(json);

  /// アクティブなカテゴリ一覧を表示順で取得
  Future<List<MaterialCategory>> findActiveOrdered(String userId) async {
    final List<QueryFilter> filters = <QueryFilter>[QueryConditionBuilder.eq("user_id", userId)];

    final List<OrderByCondition> orderBy = <OrderByCondition>[
      const OrderByCondition(column: "display_order"),
    ];

    return find(filters: filters, orderBy: orderBy);
  }
}
