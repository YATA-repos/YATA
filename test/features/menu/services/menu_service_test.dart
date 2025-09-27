import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:yata/app/wiring/provider.dart"
  show
    menuCategoryRepositoryProvider,
    menuItemRepositoryProvider,
    menuServiceProvider,
    materialRepositoryProvider,
    realtimeManagerProvider,
    recipeRepositoryProvider;
import "package:yata/core/constants/enums.dart";
import "package:yata/core/contracts/realtime/realtime_manager.dart";
import "package:yata/core/contracts/repositories/inventory/material_repository_contract.dart";
import "package:yata/core/contracts/repositories/inventory/recipe_repository_contract.dart";
import "package:yata/core/contracts/repositories/menu/menu_repository_contracts.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/inventory/models/inventory_model.dart";
import "package:yata/features/menu/dto/menu_dto.dart";
import "package:yata/features/menu/models/menu_model.dart";
import "package:yata/features/menu/services/menu_service.dart";

class MockMenuItemRepository extends Mock
    implements MenuItemRepositoryContract<MenuItem> {}

class MockMenuCategoryRepository extends Mock
    implements MenuCategoryRepositoryContract<MenuCategory> {}

class MockMaterialRepository extends Mock
    implements MaterialRepositoryContract<Material> {}

class MockRecipeRepository extends Mock
    implements RecipeRepositoryContract<Recipe> {}

class MockRealtimeManager extends Mock implements RealtimeManagerContract {}

class _FakeStringList extends Fake implements List<String> {}

class _FakeStringIterable extends Fake implements Iterable<String> {}

void main() {
  late ProviderContainer container;
  late MenuService service;
  late MockMenuItemRepository menuItemRepository;
  late MockMenuCategoryRepository menuCategoryRepository;
  late MockMaterialRepository materialRepository;
  late MockRecipeRepository recipeRepository;
  late MockRealtimeManager realtimeManager;

  setUpAll(() {
    registerFallbackValue(_FakeStringList());
    registerFallbackValue(_FakeStringIterable());
  });

  setUp(() {
    menuItemRepository = MockMenuItemRepository();
    menuCategoryRepository = MockMenuCategoryRepository();
    materialRepository = MockMaterialRepository();
    recipeRepository = MockRecipeRepository();
    realtimeManager = MockRealtimeManager();

    container = ProviderContainer(overrides: <Override>[
      currentUserIdProvider.overrideWith((Ref ref) => "user-1"),
      realtimeManagerProvider.overrideWithValue(realtimeManager),
      menuItemRepositoryProvider.overrideWithValue(menuItemRepository),
      menuCategoryRepositoryProvider.overrideWithValue(menuCategoryRepository),
      materialRepositoryProvider.overrideWithValue(materialRepository),
      recipeRepositoryProvider.overrideWithValue(recipeRepository),
    ]);

    service = container.read(menuServiceProvider);
  });

  tearDown(() {
    container.dispose();
  });

  group("checkMenuAvailability", () {
    test("returns unavailable when required material is missing", () async {
      final MenuItem menuItem = MenuItem(
        id: "item-1",
        name: "焼きそば",
        categoryId: "cat-1",
        price: 900,
        isAvailable: true,
        estimatedPrepTimeMinutes: 5,
        displayOrder: 1,
        userId: "user-1",
      );

      when(() => menuItemRepository.getById("item-1")).thenAnswer((_) async => menuItem);

      final Recipe recipe = Recipe(
        id: "recipe-1",
        menuItemId: "item-1",
        materialId: "mat-1",
        requiredAmount: 2,
        isOptional: false,
        userId: "user-1",
      );

      when(() => recipeRepository.findByMenuItemIds(any<List<String>>())).thenAnswer(
        (_) async => <Recipe>[recipe],
      );

      when(() => materialRepository.findByIds(any<List<String>>()))
          .thenAnswer((_) async => <Material>[]);

      final MenuAvailabilityInfo result =
          await service.checkMenuAvailability("item-1", 1, "user-1");

      expect(result.isAvailable, isFalse);
      expect(result.estimatedServings, 0);
      expect(result.missingMaterials, contains(allOf(contains("mat-1"), contains("not"))));
    });
  });

  group("bulkCheckMenuAvailability", () {
    test("filters by provided menu item ids", () async {
      final MenuItem availableItem = MenuItem(
        id: "item-1",
        name: "お好み焼き",
        categoryId: "cat-1",
        price: 800,
        isAvailable: true,
        estimatedPrepTimeMinutes: 7,
        displayOrder: 1,
        userId: "user-1",
      );

      final MenuItem disabledItem = MenuItem(
        id: "item-2",
        name: "たこ焼き",
        categoryId: "cat-1",
        price: 600,
        isAvailable: false,
        estimatedPrepTimeMinutes: 6,
        displayOrder: 2,
        userId: "user-1",
      );

      when(() => menuItemRepository.findByIds(any<List<String>>())).thenAnswer(
        (_) async => <MenuItem>[availableItem, disabledItem],
      );

      final Recipe recipe = Recipe(
        id: "recipe-1",
        menuItemId: "item-1",
        materialId: "mat-1",
        requiredAmount: 1,
        isOptional: false,
        userId: "user-1",
      );

      when(() => recipeRepository.findByMenuItemIds(any<List<String>>())).thenAnswer(
        (_) async => <Recipe>[recipe],
      );

      final Material material = Material(
        id: "mat-1",
        name: "ソース",
        categoryId: "mat-cat",
        unitType: UnitType.piece,
        currentStock: 10,
        alertThreshold: 1,
        criticalThreshold: 0,
        userId: "user-1",
      );

      when(() => materialRepository.findByIds(any<List<String>>())).thenAnswer(
        (_) async => <Material>[material],
      );

      final Map<String, MenuAvailabilityInfo> result =
          await service.bulkCheckMenuAvailability("user-1", menuItemIds: <String>["item-1"]);

      expect(result.keys, contains("item-1"));
      expect(result.keys, isNot(contains("item-2")));
      expect(result["item-1"]!.isAvailable, isTrue);
    });
  });

  group("searchMenuItems", () {
    test("falls back to manual search when repository call fails", () async {
  when(() => menuItemRepository.searchByName(any<dynamic>())).thenThrow(Exception("network"));

      final MenuItem match = MenuItem(
        id: "item-1",
        name: "餃子セット",
        categoryId: "cat-1",
        price: 700,
        isAvailable: true,
        estimatedPrepTimeMinutes: 6,
        displayOrder: 1,
        userId: "user-1",
        description: "焼き餃子",
      );

      final MenuItem other = MenuItem(
        id: "item-2",
        name: "味噌汁",
        categoryId: "cat-1",
        price: 450,
        isAvailable: true,
        estimatedPrepTimeMinutes: 3,
        displayOrder: 2,
        userId: "user-1",
        description: "具たっぷり",
      );

      when(() => menuItemRepository.findByCategoryId(null)).thenAnswer(
        (_) async => <MenuItem>[match, other],
      );

      final List<MenuItem> results = await service.searchMenuItems("餃子", "user-1");

      expect(results, hasLength(1));
      expect(results.first.id, "item-1");
    });
  });
}
