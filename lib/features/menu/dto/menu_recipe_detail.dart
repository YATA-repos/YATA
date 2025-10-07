import "../../../core/constants/enums.dart";
import "../../inventory/models/inventory_model.dart";

/// メニューに紐づくレシピと材料の表示用DTO。
class MenuRecipeDetail {
  const MenuRecipeDetail({
    required this.recipeId,
    required this.menuItemId,
    required this.materialId,
    required this.requiredAmount,
    required this.isOptional,
    this.notes,
    this.material,
  });

  /// レシピ情報からDTOを生成する。
  factory MenuRecipeDetail.fromRecipe({required Recipe recipe, Material? material}) =>
      MenuRecipeDetail(
        recipeId: recipe.id,
        menuItemId: recipe.menuItemId,
        materialId: recipe.materialId,
        requiredAmount: recipe.requiredAmount,
        isOptional: recipe.isOptional,
        notes: recipe.notes,
        material: material,
      );

  /// レシピID。
  final String? recipeId;

  /// メニューアイテムID。
  final String menuItemId;

  /// 材料ID。
  final String materialId;

  /// 必要量。
  final double requiredAmount;

  /// 任意材料かどうか。
  final bool isOptional;

  /// 備考。
  final String? notes;

  /// 関連する材料詳細。
  final Material? material;

  /// 材料名を取得する（未存在時はハイフン）。
  String get materialName => material?.name ?? "-";

  /// 材料単位を取得する。
  UnitType? get materialUnitType => material?.unitType;

  /// 現在庫量を取得する。
  double? get materialCurrentStock => material?.currentStock;
}
