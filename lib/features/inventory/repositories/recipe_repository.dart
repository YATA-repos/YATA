import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/inventory/recipe_repository_contract.dart";
import "../models/inventory_model.dart";

/// レシピリポジトリ
class RecipeRepository implements RecipeRepositoryContract<Recipe> {
  RecipeRepository({required repo_contract.CrudRepository<Recipe, String> delegate})
    : _delegate = delegate;

  final repo_contract.CrudRepository<Recipe, String> _delegate;

  /// メニューアイテムIDでレシピ一覧を取得
  @override
  Future<List<Recipe>> findByMenuItemId(String menuItemId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("menu_item_id", menuItemId),
    ];

    return _delegate.find(filters: filters);
  }

  /// 材料IDを使用するレシピ一覧を取得
  @override
  Future<List<Recipe>> findByMaterialId(String materialId) async {
    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("material_id", materialId),
    ];

    return _delegate.find(filters: filters);
  }

  /// 複数メニューアイテムのレシピを一括取得
  @override
  Future<List<Recipe>> findByMenuItemIds(List<String> menuItemIds) async {
    if (menuItemIds.isEmpty) {
      return <Recipe>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.inList("menu_item_id", menuItemIds),
    ];

    return _delegate.find(filters: filters);
  }

  /// メニューIDと材料IDで単一レシピを取得
  @override
  Future<Recipe?> findByMenuItemAndMaterial(String menuItemId, String materialId) => _delegate
      .getByPrimaryKey(<String, dynamic>{"menu_item_id": menuItemId, "material_id": materialId});

  /// メニューIDと材料IDをキーにレシピを作成または更新
  @override
  Future<Recipe?> upsertByMenuItemAndMaterial(Recipe entity) async {
    final Recipe? existing = await findByMenuItemAndMaterial(entity.menuItemId, entity.materialId);

    final Map<String, dynamic> updates = <String, dynamic>{
      "required_amount": entity.requiredAmount,
      "is_optional": entity.isOptional,
      "notes": entity.notes,
      "user_id": entity.userId,
      if (entity.updatedAt != null) "updated_at": entity.updatedAt!.toIso8601String(),
    };

    if (existing == null) {
      return _delegate.create(entity);
    }

    if (existing.id != null) {
      return _delegate.updateById(existing.id!, updates);
    }

    return _delegate.updateByPrimaryKey(<String, dynamic>{
      "menu_item_id": entity.menuItemId,
      "material_id": entity.materialId,
    }, updates);
  }

  /// メニューIDに紐づくレシピを一括削除
  @override
  Future<void> deleteByMenuItemId(String menuItemId) async {
    final List<Recipe> recipes = await findByMenuItemId(menuItemId);
    if (recipes.isEmpty) {
      return;
    }

    final List<String> ids = <String>[];
    final List<Future<void>> pending = <Future<void>>[];

    for (final Recipe recipe in recipes) {
      if (recipe.id != null) {
        ids.add(recipe.id!);
      } else {
        pending.add(
          _delegate.deleteByPrimaryKey(<String, dynamic>{
            "menu_item_id": recipe.menuItemId,
            "material_id": recipe.materialId,
          }),
        );
      }
    }

    if (ids.isNotEmpty) {
      await _delegate.bulkDelete(ids);
    }

    if (pending.isNotEmpty) {
      await Future.wait(pending);
    }
  }

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<Recipe?> create(Recipe entity) => _delegate.create(entity);

  @override
  Future<List<Recipe>> bulkCreate(List<Recipe> entities) => _delegate.bulkCreate(entities);

  @override
  Future<Recipe?> getById(String id) => _delegate.getById(id);

  @override
  Future<Recipe?> getByPrimaryKey(Map<String, dynamic> keyMap) => _delegate.getByPrimaryKey(keyMap);

  @override
  Future<Recipe?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<Recipe?> updateByPrimaryKey(Map<String, dynamic> keyMap, Map<String, dynamic> updates) =>
      _delegate.updateByPrimaryKey(keyMap, updates);

  @override
  Future<void> deleteById(String id) => _delegate.deleteById(id);

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.deleteByPrimaryKey(keyMap);

  @override
  Future<void> bulkDelete(List<String> keys) => _delegate.bulkDelete(keys);

  @override
  Future<List<Recipe>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
