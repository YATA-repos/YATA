// ignore_for_file: directives_ordering

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yata/app/wiring/provider.dart";
import "package:yata/core/contracts/realtime/realtime_manager.dart";
import "package:yata/core/contracts/repositories/inventory/material_repository_contract.dart";
import "package:yata/core/contracts/repositories/inventory/recipe_repository_contract.dart";
import "package:yata/core/contracts/repositories/menu/menu_repository_contracts.dart";
import "package:yata/core/constants/query_types.dart";
import "package:yata/features/auth/models/auth_state.dart";
import "package:yata/features/auth/models/user_profile.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/inventory/models/inventory_model.dart";
import "package:yata/features/menu/dto/menu_dto.dart";
import "package:yata/features/menu/models/menu_model.dart";
import "package:yata/features/menu/presentation/controllers/menu_management_controller.dart";
import "package:yata/features/menu/services/menu_service.dart";

class _FakeRealtimeManager implements RealtimeManagerContract {
  @override
  Future<void> startMonitoring(
    RealtimeSubscriptionConfig config,
    String subscriptionId,
    RealtimeDataCallback onData,
  ) async {}

  @override
  Future<void> stopMonitoring(String subscriptionId) async {}

  @override
  Future<void> stopAllMonitoring() async {}

  @override
  bool isMonitoring(String subscriptionId) => false;

  @override
  List<String> getActiveSubscriptions() => <String>[];

  @override
  Map<String, dynamic> getStats() => <String, dynamic>{"status": "connected"};
}

class _MemoryMenuCategoryRepository implements MenuCategoryRepositoryContract<MenuCategory> {
  _MemoryMenuCategoryRepository();

  final List<MenuCategory> _categories = <MenuCategory>[];
  int _counter = 0;

  @override
  Future<MenuCategory?> create(MenuCategory entity) async {
    final MenuCategory created = MenuCategory(
      id: entity.id ?? "cat-${_counter++}",
      name: entity.name,
      displayOrder: entity.displayOrder,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _categories.add(created);
    return created;
  }

  @override
  Future<List<MenuCategory>> findActiveOrdered() async {
    final List<MenuCategory> clone = List<MenuCategory>.from(_categories)
      ..sort((MenuCategory a, MenuCategory b) => a.displayOrder.compareTo(b.displayOrder));
    return clone;
  }

  @override
  Future<MenuCategory?> getById(String id) async {
    final int index = _categories.indexWhere((MenuCategory category) => category.id == id);
    if (index == -1) {
      return null;
    }
    return _categories[index];
  }

  @override
  Future<MenuCategory?> updateById(String id, Map<String, dynamic> updates) async {
    final int index = _categories.indexWhere((MenuCategory category) => category.id == id);
    if (index == -1) {
      return null;
    }
    final MenuCategory current = _categories[index];
    final MenuCategory updated = MenuCategory(
      id: current.id,
      name: (updates["name"] as String?) ?? current.name,
      displayOrder: (updates["display_order"] as int?) ?? current.displayOrder,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    _categories[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteById(String id) async {
    _categories.removeWhere((MenuCategory category) => category.id == id);
  }

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) async {
    final String? id = keyMap["id"] as String?;
    if (id != null) {
      await deleteById(id);
    }
  }

  // Unused methods throw UnimplementedError to catch unexpected calls.
  @override
  Future<List<MenuCategory>> bulkCreate(List<MenuCategory> entities) => throw UnimplementedError();

  @override
  Future<void> bulkDelete(List<String> keys) => throw UnimplementedError();

  @override
  Future<int> count({List<QueryFilter>? filters}) => throw UnimplementedError();

  @override
  Future<List<MenuCategory>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<MenuCategory?> getByPrimaryKey(Map<String, dynamic> keyMap) => throw UnimplementedError();

  @override
  Future<MenuCategory?> updateByPrimaryKey(
    Map<String, dynamic> keyMap,
    Map<String, dynamic> updates,
  ) => throw UnimplementedError();
}

class _MemoryMenuItemRepository implements MenuItemRepositoryContract<MenuItem> {
  _MemoryMenuItemRepository();

  final List<MenuItem> _items = <MenuItem>[];
  int _counter = 0;

  @override
  Future<MenuItem?> create(MenuItem entity) async {
    final MenuItem created = MenuItem(
      id: entity.id ?? "item-${_counter++}",
      name: entity.name,
      categoryId: entity.categoryId,
      price: entity.price,
      isAvailable: entity.isAvailable,
      estimatedPrepTimeMinutes: entity.estimatedPrepTimeMinutes,
      displayOrder: entity.displayOrder,
      description: entity.description,
      imageUrl: entity.imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _items.add(created);
    return created;
  }

  @override
  Future<MenuItem?> updateById(String id, Map<String, dynamic> updates) async {
    final int index = _items.indexWhere((MenuItem item) => item.id == id);
    if (index == -1) {
      return null;
    }
    final MenuItem current = _items[index];
    final MenuItem updated = MenuItem(
      id: current.id,
      name: (updates["name"] as String?) ?? current.name,
      categoryId: (updates["category_id"] as String?) ?? current.categoryId,
      price: (updates["price"] as int?) ?? current.price,
      isAvailable: (updates["is_available"] as bool?) ?? current.isAvailable,
      estimatedPrepTimeMinutes:
          (updates["estimated_prep_time_minutes"] as int?) ?? current.estimatedPrepTimeMinutes,
      displayOrder: (updates["display_order"] as int?) ?? current.displayOrder,
      description: (updates["description"] as String?) ?? current.description,
      imageUrl: (updates["image_url"] as String?) ?? current.imageUrl,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteById(String id) async {
    _items.removeWhere((MenuItem item) => item.id == id);
  }

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) async {
    final String? id = keyMap["id"] as String?;
    if (id != null) {
      await deleteById(id);
    }
  }

  @override
  Future<List<MenuItem>> findByCategoryId(String? categoryId) async {
    if (categoryId == null) {
      return List<MenuItem>.from(_items)
        ..sort((MenuItem a, MenuItem b) => a.displayOrder.compareTo(b.displayOrder));
    }
    return _items
        .where((MenuItem item) => item.categoryId == categoryId)
        .toList(growable: false);
  }

  @override
  Future<MenuItem?> getById(String id) async {
    final int index = _items.indexWhere((MenuItem item) => item.id == id);
    if (index == -1) {
      return null;
    }
    return _items[index];
  }

  // Remaining methods are unimplemented for brevity.
  @override
  Future<List<MenuItem>> findAvailableOnly() => throw UnimplementedError();

  @override
  Future<List<MenuItem>> searchByName(dynamic keyword) => throw UnimplementedError();

  @override
  Future<List<MenuItem>> findByIds(List<String> menuItemIds) => throw UnimplementedError();

  @override
  Future<List<MenuItem>> bulkCreate(List<MenuItem> entities) => throw UnimplementedError();

  @override
  Future<void> bulkDelete(List<String> keys) => throw UnimplementedError();

  @override
  Future<int> count({List<QueryFilter>? filters}) => throw UnimplementedError();

  @override
  Future<List<MenuItem>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<MenuItem?> getByPrimaryKey(Map<String, dynamic> keyMap) => throw UnimplementedError();

  @override
  Future<MenuItem?> updateByPrimaryKey(
    Map<String, dynamic> keyMap,
    Map<String, dynamic> updates,
  ) => throw UnimplementedError();
}

class _NullMaterialRepository implements MaterialRepositoryContract<Material> {
  @override
  Future<Material?> create(Material entity) => throw UnimplementedError();

  @override
  Future<List<Material>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<Material?> getById(String id) async => null;

  @override
  Future<List<Material>> findByCategoryId(String? categoryId) async => <Material>[];

  @override
  Future<List<Material>> findByIds(List<String> materialIds) async => <Material>[];

  @override
  Future<Material?> updateStockAmount(String materialId, double newAmount) async => null;

  // Remaining methods unused in tests.
  @override
  Future<void> bulkDelete(List<String> keys) => throw UnimplementedError();

  @override
  Future<List<Material>> bulkCreate(List<Material> entities) => throw UnimplementedError();

  @override
  Future<int> count({List<QueryFilter>? filters}) => throw UnimplementedError();

  @override
  Future<void> deleteById(String id) => throw UnimplementedError();

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) async {}

  @override
  Future<Material?> getByPrimaryKey(Map<String, dynamic> keyMap) => throw UnimplementedError();

  @override
  Future<Material?> updateById(String id, Map<String, dynamic> updates) => throw UnimplementedError();

  @override
  Future<Material?> updateByPrimaryKey(
    Map<String, dynamic> keyMap,
    Map<String, dynamic> updates,
  ) => throw UnimplementedError();
}

class _NullRecipeRepository implements RecipeRepositoryContract<Recipe> {
  @override
  Future<List<Recipe>> findByMenuItemId(String menuItemId) async => <Recipe>[];

  @override
  Future<List<Recipe>> findByMaterialId(String materialId) async => <Recipe>[];

  @override
  Future<List<Recipe>> findByMenuItemIds(List<String> menuItemIds) async => <Recipe>[];

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) async {}

  // Remaining methods unused.
  @override
  Future<Recipe?> create(Recipe entity) => throw UnimplementedError();

  @override
  Future<List<Recipe>> bulkCreate(List<Recipe> entities) => throw UnimplementedError();

  @override
  Future<void> bulkDelete(List<String> keys) => throw UnimplementedError();

  @override
  Future<int> count({List<QueryFilter>? filters}) => throw UnimplementedError();

  @override
  Future<void> deleteById(String id) => throw UnimplementedError();

  @override
  Future<List<Recipe>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<Recipe?> getById(String id) => throw UnimplementedError();

  @override
  Future<Recipe?> getByPrimaryKey(Map<String, dynamic> keyMap) => throw UnimplementedError();

  @override
  Future<Recipe?> updateById(String id, Map<String, dynamic> updates) => throw UnimplementedError();

  @override
  Future<Recipe?> updateByPrimaryKey(
    Map<String, dynamic> keyMap,
    Map<String, dynamic> updates,
  ) => throw UnimplementedError();
}

class _TestMenuService extends MenuService {
  _TestMenuService({
    required super.ref,
    required MenuItemRepositoryContract<MenuItem> itemRepository,
    required MenuCategoryRepositoryContract<MenuCategory> categoryRepository,
  })  : _itemRepository = itemRepository,
        _categoryRepository = categoryRepository,
        super(
          realtimeManager: _FakeRealtimeManager(),
          menuItemRepository: itemRepository,
          menuCategoryRepository: categoryRepository,
          materialRepository: _NullMaterialRepository(),
          recipeRepository: _NullRecipeRepository(),
        );

  final MenuItemRepositoryContract<MenuItem> _itemRepository;
  final MenuCategoryRepositoryContract<MenuCategory> _categoryRepository;

  @override
  Future<Map<String, MenuAvailabilityInfo>> bulkCheckMenuAvailability(String userId) async {
    final List<MenuItem> items = await _itemRepository.findByCategoryId(null);
    return <String, MenuAvailabilityInfo>{
      for (final MenuItem item in items)
        if (item.id != null)
          item.id!: MenuAvailabilityInfo(
            menuItemId: item.id!,
            isAvailable: item.isAvailable,
            missingMaterials: const <String>[],
            estimatedServings: 10,
          ),
    };
  }

  @override
  Future<MenuAvailabilityInfo> checkMenuAvailability(
    String menuItemId,
    int quantity,
    String userId,
  ) async => MenuAvailabilityInfo(
        menuItemId: menuItemId,
        isAvailable: true,
        missingMaterials: const <String>[],
        estimatedServings: 10,
      );

  @override
  Future<void> updateCategoryOrder(List<MenuCategory> categories) async {
    for (final MenuCategory category in categories) {
      if (category.id != null) {
        await _categoryRepository.updateById(
          category.id!,
          <String, dynamic>{"display_order": category.displayOrder},
        );
      }
    }
  }
}

void main() {
  late ProviderContainer container;
  late MenuManagementController controller;

  setUp(() {
    final _MemoryMenuCategoryRepository categoryRepository = _MemoryMenuCategoryRepository();
    final _MemoryMenuItemRepository itemRepository = _MemoryMenuItemRepository();

    container = ProviderContainer(overrides: <Override>[
      menuServiceProvider.overrideWith(
        (Ref ref) => _TestMenuService(
          ref: ref,
          itemRepository: itemRepository,
          categoryRepository: categoryRepository,
        ),
      ),
    ]);

    final UserProfile userProfile = UserProfile(email: "owner@example.com", id: "user-1", userId: "user-1");
    container.read(authStateNotifierProvider.notifier).state = AuthState.authenticated(userProfile);

    controller = container.read(menuManagementControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test("createCategory adds category and updates state", () async {
    await controller.createCategory(name: "主菜", displayOrder: 1);

    expect(controller.state.categories, hasLength(1));
    expect(controller.state.categories.first.name, "主菜");
    expect(controller.state.categories.first.displayOrder, 1);
  });

  test("createMenuItem increases item count for category", () async {
    final MenuCategoryViewData category =
        await controller.createCategory(name: "主菜", displayOrder: 1);

    await controller.createMenuItem(
      name: "餃子",
      categoryId: category.id,
      price: 680,
      isAvailable: true,
      estimatedPrepTimeMinutes: 10,
      displayOrder: 1,
      description: "焼き餃子6個",
    );

    expect(controller.state.items, hasLength(1));
    expect(controller.state.items.first.name, "餃子");
    expect(controller.state.categories.first.itemCount, 1);
  });
}
