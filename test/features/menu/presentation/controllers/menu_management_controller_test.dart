import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/app/wiring/provider.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/inventory/models/inventory_model.dart" as inventory;
import "package:yata/features/menu/dto/menu_dto.dart";
import "package:yata/features/menu/dto/menu_recipe_detail.dart";
import "package:yata/features/menu/models/menu_model.dart";
import "package:yata/features/menu/presentation/controllers/menu_management_controller.dart";
import "package:yata/features/menu/presentation/controllers/menu_management_state.dart";
import "package:yata/features/menu/services/menu_service.dart";

class _MockMenuService extends Mock implements MenuService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String userId = "user-1";
  const String menuId = "menu-1";
  final MenuAvailabilityInfo initialAvailability = MenuAvailabilityInfo(
    menuItemId: menuId,
    isAvailable: true,
    missingMaterials: <String>[],
    estimatedServings: 5,
  );
  final MenuAvailabilityInfo toggledAvailability = MenuAvailabilityInfo(
    menuItemId: menuId,
    isAvailable: false,
    missingMaterials: <String>[],
    estimatedServings: 5,
  );

  late ProviderContainer container;
  late _MockMenuService menuService;
  late int availabilityCallCount;

  setUp(() {
    menuService = _MockMenuService();
    availabilityCallCount = 0;

    when(() => menuService.enableRealtimeFeatures()).thenAnswer((_) async {});
    when(() => menuService.disableRealtimeFeatures()).thenAnswer((_) async {});
    when(() => menuService.isRealtimeConnected()).thenReturn(false);
    when(() => menuService.getMenuCategories()).thenAnswer(
      (_) async => <MenuCategory>[MenuCategory(id: "cat-1", name: "メイン", displayOrder: 1)],
    );
    when(() => menuService.getMenuItemsByCategory(any<String?>())).thenAnswer(
      (_) async => <MenuItem>[
        MenuItem(
          id: menuId,
          name: "焼きそば",
          categoryId: "cat-1",
          price: 800,
          isAvailable: true,
          displayOrder: 1,
        ),
      ],
    );
    when(() => menuService.getMenuRecipes(any())).thenAnswer((_) async => <MenuRecipeDetail>[]);
    when(() => menuService.getMaterialCandidates()).thenAnswer((_) async => <inventory.Material>[]);
    when(() => menuService.bulkCheckMenuAvailability(any())).thenAnswer((_) async {
      availabilityCallCount += 1;
      return <String, MenuAvailabilityInfo>{
        menuId: availabilityCallCount == 1 ? initialAvailability : toggledAvailability,
      };
    });

    container = ProviderContainer(
      overrides: <Override>[
        currentUserIdProvider.overrideWith((Ref _) => userId),
        menuServiceProvider.overrideWithValue(menuService),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<MenuManagementController> initializeController() async {
    final MenuManagementController controller = container.read(
      menuManagementControllerProvider.notifier,
    );
    await controller.loadInitialData();
    return controller;
  }

  test("toggleMenuAvailability updates state on success", () async {
    when(() => menuService.toggleMenuItemAvailability(any(), any(), any())).thenAnswer(
      (_) async => MenuItem(
        id: menuId,
        name: "焼きそば",
        categoryId: "cat-1",
        price: 800,
        isAvailable: false,
        displayOrder: 1,
      ),
    );

    final MenuManagementController controller = await initializeController();
    availabilityCallCount = 1; // next availability check should reflect toggled state

    await controller.toggleMenuAvailability(menuId, false);

    final MenuManagementState state = container.read(menuManagementControllerProvider);

    expect(state.pendingAvailabilityMenuIds, isEmpty);
    expect(state.availabilityErrorMessages, isEmpty);
    expect(
      state.menuItems.firstWhere((MenuItemViewData item) => item.id == menuId).isAvailable,
      isFalse,
    );
    verify(() => menuService.toggleMenuItemAvailability(menuId, false, userId)).called(1);
  });

  test("toggleMenuAvailability reverts state on failure", () async {
    when(
      () => menuService.toggleMenuItemAvailability(any(), any(), any()),
    ).thenThrow(Exception("network"));

    final MenuManagementController controller = await initializeController();

    await controller.toggleMenuAvailability(menuId, false);

    final MenuManagementState state = container.read(menuManagementControllerProvider);

    expect(state.pendingAvailabilityMenuIds, isEmpty);
    expect(
      state.menuItems.firstWhere((MenuItemViewData item) => item.id == menuId).isAvailable,
      isTrue,
    );
    expect(state.availabilityErrorMessages[menuId], "予期しないエラーが発生しました。もう一度お試しください。");
  });

  test("openDetail sets detail and closeDetail clears it", () async {
    when(
      () => menuService.refreshMenuAvailabilityForMenu(menuId),
    ).thenAnswer((_) async => initialAvailability);
    when(() => menuService.calculateMaxServings(menuId, userId)).thenAnswer((_) async => 6);

    final MenuManagementController controller = await initializeController();

    await controller.openDetail(menuId);

    MenuManagementState state = container.read(menuManagementControllerProvider);
    expect(state.detail, isNotNull);
    expect(state.detail!.menu.id, menuId);
    expect(state.selectedMenuId, menuId);

    controller.closeDetail();

    state = container.read(menuManagementControllerProvider);
    expect(state.detail, isNull);
    expect(state.selectedMenuId, isNull);
  });

  test("createMenu registers draft recipes and preserves cache", () async {
    final MenuManagementController controller = await initializeController();

    final inventory.Material pork = inventory.Material(
      id: "mat-1",
      userId: userId,
      name: "豚肉",
      categoryId: "meat",
      unitType: UnitType.gram,
      currentStock: 3200,
      alertThreshold: 800,
      criticalThreshold: 400,
    );

    when(
      () => menuService.createMenuItem(
        name: any(named: "name"),
        categoryId: any(named: "categoryId"),
        price: any(named: "price"),
        isAvailable: any(named: "isAvailable"),
        displayOrder: any(named: "displayOrder"),
        description: any(named: "description"),
      ),
    ).thenAnswer(
      (_) async => MenuItem(
        id: "menu-2",
        name: "唐揚げ",
        categoryId: "cat-1",
        price: 680,
        isAvailable: true,
        displayOrder: 2,
      ),
    );
    when(
      () => menuService.upsertMenuRecipe(
        menuItemId: any(named: "menuItemId"),
        materialId: any(named: "materialId"),
        requiredAmount: any(named: "requiredAmount"),
        isOptional: any(named: "isOptional"),
        notes: any(named: "notes"),
      ),
    ).thenAnswer(
      (_) async => MenuRecipeDetail(
        recipeId: "recipe-1",
        menuItemId: "menu-2",
        materialId: pork.id!,
        requiredAmount: 120,
        isOptional: false,
        material: pork,
        notes: "下味済み",
      ),
    );

    final MenuFormData formData = MenuFormData(
      name: "唐揚げ",
      categoryId: "cat-1",
      price: 680,
      isAvailable: true,
      description: "ジューシー",
      recipes: <MenuRecipeDraft>[
        MenuRecipeDraft(
          materialId: pork.id!,
          materialName: pork.name,
          unitType: pork.unitType,
          requiredAmount: 120,
          notes: "下味済み",
        ),
      ],
    );

    await controller.createMenu(formData);

    verify(
      () => menuService.createMenuItem(
        name: "唐揚げ",
        categoryId: "cat-1",
        price: 680,
        isAvailable: true,
        displayOrder: 2,
        description: "ジューシー",
      ),
    ).called(1);
    verify(
      () => menuService.upsertMenuRecipe(
        menuItemId: "menu-2",
        materialId: pork.id!,
        requiredAmount: 120,
        notes: "下味済み",
      ),
    ).called(1);
  });

  test("updateMenu syncs recipe changes including deletions", () async {
    final inventory.Material cabbage = inventory.Material(
      id: "mat-1",
      userId: userId,
      name: "キャベツ",
      categoryId: "vegetable",
      unitType: UnitType.gram,
      currentStock: 1200,
      alertThreshold: 400,
      criticalThreshold: 200,
    );
    final MenuRecipeDetail existingRecipe = MenuRecipeDetail(
      recipeId: "recipe-1",
      menuItemId: menuId,
      materialId: cabbage.id!,
      requiredAmount: 80,
      isOptional: false,
      material: cabbage,
    );

    when(
      () => menuService.getMenuRecipes(menuId),
    ).thenAnswer((_) async => <MenuRecipeDetail>[existingRecipe]);

    final MenuManagementController controller = await initializeController();

    final inventory.Material flour = inventory.Material(
      id: "mat-2",
      userId: userId,
      name: "小麦粉",
      categoryId: "dry",
      unitType: UnitType.gram,
      currentStock: 2000,
      alertThreshold: 600,
      criticalThreshold: 300,
    );

    when(
      () => menuService.updateMenuItem(
        menuId,
        name: any(named: "name"),
        categoryId: any(named: "categoryId"),
        price: any(named: "price"),
        description: any(named: "description"),
        isAvailable: any(named: "isAvailable"),
        displayOrder: any(named: "displayOrder"),
      ),
    ).thenAnswer(
      (_) async => MenuItem(
        id: menuId,
        name: "焼きそば",
        categoryId: "cat-1",
        price: 820,
        isAvailable: true,
        displayOrder: 1,
      ),
    );
    when(() => menuService.deleteMenuRecipe("recipe-1")).thenAnswer((_) async {});
    when(
      () => menuService.upsertMenuRecipe(
        menuItemId: menuId,
        materialId: flour.id!,
        requiredAmount: 30,
        isOptional: true,
        notes: any(named: "notes"),
      ),
    ).thenAnswer(
      (_) async => MenuRecipeDetail(
        recipeId: "recipe-2",
        menuItemId: menuId,
        materialId: flour.id!,
        requiredAmount: 30,
        isOptional: true,
        material: flour,
        notes: "仕上げ用",
      ),
    );

    final MenuFormData formData = MenuFormData(
      name: "焼きそば",
      categoryId: "cat-1",
      price: 820,
      isAvailable: true,
      description: "ソース増量",
      recipes: <MenuRecipeDraft>[
        MenuRecipeDraft(
          recipeId: existingRecipe.recipeId,
          materialId: flour.id!,
          materialName: flour.name,
          unitType: flour.unitType,
          requiredAmount: 30,
          isOptional: true,
          notes: "仕上げ用",
        ),
      ],
      removedRecipeIds: <String>["recipe-1"],
    );

    await controller.updateMenu(menuId, formData);

    verify(
      () => menuService.updateMenuItem(
        menuId,
        name: "焼きそば",
        categoryId: "cat-1",
        price: 820,
        description: "ソース増量",
        isAvailable: true,
      ),
    ).called(1);
    verify(() => menuService.deleteMenuRecipe("recipe-1")).called(1);
    verify(
      () => menuService.upsertMenuRecipe(
        menuItemId: menuId,
        materialId: flour.id!,
        requiredAmount: 30,
        isOptional: true,
        notes: "仕上げ用",
      ),
    ).called(1);
  });
}
