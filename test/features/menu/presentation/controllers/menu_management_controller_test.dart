import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/app/wiring/provider.dart" as wiring;
import "package:yata/core/constants/enums.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/inventory/models/inventory_model.dart";
import "package:yata/features/menu/dto/menu_dto.dart";
import "package:yata/features/menu/dto/menu_recipe_detail.dart";
import "package:yata/features/menu/models/menu_model.dart";
import "package:yata/features/menu/presentation/controllers/menu_management_controller.dart";
import "package:yata/features/menu/services/menu_service.dart";

class _MockMenuService extends Mock implements MenuService {}

Future<void> _waitForInitialization(MenuManagementController controller) async {
	for (int i = 0; i < 10 && controller.state.isInitializing; i++) {
		await Future<void>.delayed(const Duration(milliseconds: 10));
	}
}

void main() {
	setUpAll(() {
		registerFallbackValue(<String>[]);
	});

	late _MockMenuService menuService;
	late ProviderContainer container;
	late MenuManagementController controller;

	final MenuCategory category = MenuCategory(
		id: "cat-1",
		name: "主菜",
		displayOrder: 1,
	);

	final MenuItem menuItem = MenuItem(
		id: "menu-1",
		name: "焼きそば",
		categoryId: "cat-1",
		price: 800,
		isAvailable: true,
		displayOrder: 1,
	);

	setUp(() async {
		menuService = _MockMenuService();

		when(() => menuService.getMenuCategories()).thenAnswer((_) async => <MenuCategory>[category]);
		when(() => menuService.getMenuItemsByCategory(null)).thenAnswer((_) async => <MenuItem>[menuItem]);
		when(() => menuService.getMaterialCandidates(categoryId: any(named: "categoryId")))
				.thenAnswer((_) async => <Material>[]);
		when(() => menuService.getMenuRecipes(any())).thenAnswer((_) async => <MenuRecipeDetail>[]);
		when(() => menuService.bulkCheckMenuAvailability(any(), menuItemIds: any(named: "menuItemIds")))
				.thenAnswer((_) async => <String, MenuAvailabilityInfo>{});
		when(() => menuService.startRealtimeMonitoring()).thenAnswer((_) async {});
		when(() => menuService.stopRealtimeMonitoring()).thenAnswer((_) async {});
		when(() => menuService.refreshMenuAvailabilityForMenu(any())).thenAnswer((_) async => null);

		container = ProviderContainer(
			overrides: <Override>[
				wiring.menuServiceProvider.overrideWith((Ref _) => menuService),
				currentUserIdProvider.overrideWithValue("user-1"),
			],
		);
		addTearDown(container.dispose);

		controller = container.read(menuManagementControllerProvider.notifier);
		await _waitForInitialization(controller);
	});

	group("loadRecipesForItem", () {
		test("populates recipes map and clears loading flag", () async {
			final Material cabbage = Material(
				id: "material-1",
				name: "キャベツ",
				categoryId: "veg",
				unitType: UnitType.gram,
				currentStock: 500,
				alertThreshold: 100,
				criticalThreshold: 50,
			);
			final MenuRecipeDetail detail = MenuRecipeDetail(
				recipeId: "recipe-1",
				menuItemId: "menu-1",
				materialId: "material-1",
				requiredAmount: 120,
				isOptional: false,
				material: cabbage,
			);

			when(() => menuService.getMenuRecipes("menu-1"))
					.thenAnswer((_) async => <MenuRecipeDetail>[detail]);

			await controller.loadRecipesForItem("menu-1", force: true);

			expect(controller.state.recipesFor("menu-1"), contains(detail));
			expect(controller.state.isRecipeLoading, isFalse);
			expect(controller.state.hasRecipeError, isFalse);
		});
	});

	group("saveRecipe", () {
		test("stores recipe and updates availability", () async {
			final Material pork = Material(
				id: "material-2",
				name: "豚肉",
				categoryId: "meat",
				unitType: UnitType.gram,
				currentStock: 800,
				alertThreshold: 200,
				criticalThreshold: 80,
			);
			final MenuRecipeDetail savedDetail = MenuRecipeDetail(
				recipeId: "recipe-2",
				menuItemId: "menu-1",
				materialId: "material-2",
				requiredAmount: 150,
				isOptional: false,
				material: pork,
			);

			when(
				() => menuService.upsertMenuRecipe(
					menuItemId: any(named: "menuItemId"),
					materialId: any(named: "materialId"),
					requiredAmount: any(named: "requiredAmount"),
					isOptional: any(named: "isOptional"),
					notes: any(named: "notes"),
				),
			).thenAnswer((_) async => savedDetail);

			when(() => menuService.refreshMenuAvailabilityForMenu("menu-1")).thenAnswer(
				(_) async => MenuAvailabilityInfo(
					menuItemId: "menu-1",
					isAvailable: true,
					missingMaterials: const <String>[],
					estimatedServings: 5,
				),
			);

			await controller.saveRecipe(
				menuItemId: "menu-1",
				materialId: "material-2",
				requiredAmount: 150,
			);

			final List<MenuRecipeDetail> recipes = controller.state.recipesFor("menu-1");
			expect(recipes, hasLength(1));
			expect(recipes.first.recipeId, "recipe-2");
			expect(controller.state.materialCandidates.any((Material m) => m.id == "material-2"), isTrue);
			expect(controller.state.availabilityFor("menu-1").isAvailable, isTrue);
		});
	});

	group("deleteRecipe", () {
		test("removes recipe entry and refreshes availability", () async {
			final Material sauce = Material(
				id: "material-3",
				name: "ソース",
				categoryId: "seasoning",
				unitType: UnitType.liter,
				currentStock: 10,
				alertThreshold: 2,
				criticalThreshold: 1,
			);
			final MenuRecipeDetail savedDetail = MenuRecipeDetail(
				recipeId: "recipe-3",
				menuItemId: "menu-1",
				materialId: "material-3",
				requiredAmount: 0.1,
				isOptional: false,
				material: sauce,
			);

			when(
				() => menuService.upsertMenuRecipe(
					menuItemId: any(named: "menuItemId"),
					materialId: any(named: "materialId"),
					requiredAmount: any(named: "requiredAmount"),
					isOptional: any(named: "isOptional"),
					notes: any(named: "notes"),
				),
			).thenAnswer((_) async => savedDetail);
			when(() => menuService.refreshMenuAvailabilityForMenu("menu-1")).thenAnswer(
				(_) async => MenuAvailabilityInfo(
					menuItemId: "menu-1",
					isAvailable: true,
					missingMaterials: const <String>[],
					estimatedServings: 8,
				),
			);

			await controller.saveRecipe(
				menuItemId: "menu-1",
				materialId: "material-3",
				requiredAmount: 0.1,
			);

			when(() => menuService.deleteMenuRecipe("recipe-3")).thenAnswer((_) async {});
			when(() => menuService.refreshMenuAvailabilityForMenu("menu-1")).thenAnswer(
				(_) async => MenuAvailabilityInfo(
					menuItemId: "menu-1",
					isAvailable: true,
					missingMaterials: const <String>[],
					estimatedServings: 9,
				),
			);

			await controller.deleteRecipe(menuItemId: "menu-1", recipeId: "recipe-3");

			expect(controller.state.recipesFor("menu-1"), isEmpty);
			expect(controller.state.hasRecipeError, isFalse);
		});
	});
}
