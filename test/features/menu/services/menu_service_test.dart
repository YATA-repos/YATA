import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/core/contracts/realtime/realtime_manager.dart" as realtime_contract;
import "package:yata/core/contracts/repositories/inventory/material_repository_contract.dart";
import "package:yata/core/contracts/repositories/inventory/recipe_repository_contract.dart";
import "package:yata/core/contracts/repositories/menu/menu_repository_contracts.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/core/constants/exceptions/base/validation_exception.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/inventory/models/inventory_model.dart";
import "package:yata/features/menu/dto/menu_recipe_detail.dart";
import "package:yata/features/menu/models/menu_model.dart";
import "package:yata/features/menu/services/menu_service.dart";

class _MockRef extends Mock implements Ref {}

class _MockRealtimeManager extends Mock implements realtime_contract.RealtimeManagerContract {}

class _MockMenuItemRepository extends Mock
		implements MenuItemRepositoryContract<MenuItem> {}

class _MockMenuCategoryRepository extends Mock
		implements MenuCategoryRepositoryContract<MenuCategory> {}

class _MockMaterialRepository extends Mock
		implements MaterialRepositoryContract<Material> {}

class _MockRecipeRepository extends Mock implements RecipeRepositoryContract<Recipe> {}

void main() {
	setUpAll(() {
		registerFallbackValue(() {});
	});

	late _MockRef ref;
	late _MockRealtimeManager realtimeManager;
	late _MockMenuItemRepository menuItemRepository;
	late _MockMenuCategoryRepository menuCategoryRepository;
	late _MockMaterialRepository materialRepository;
	late _MockRecipeRepository recipeRepository;
	late MenuService service;
	late Material cabbage;
	late MenuItem yakisoba;

	setUp(() {
		ref = _MockRef();
		realtimeManager = _MockRealtimeManager();
		menuItemRepository = _MockMenuItemRepository();
		menuCategoryRepository = _MockMenuCategoryRepository();
		materialRepository = _MockMaterialRepository();
		recipeRepository = _MockRecipeRepository();

		when(() => ref.onDispose(any())).thenAnswer((_) {});
		when(() => ref.read<String?>(currentUserIdProvider)).thenReturn("user-1");

		service = MenuService(
			ref: ref,
			realtimeManager: realtimeManager,
			menuItemRepository: menuItemRepository,
			menuCategoryRepository: menuCategoryRepository,
			materialRepository: materialRepository,
			recipeRepository: recipeRepository,
		);

		cabbage = Material(
			id: "material-1",
			name: "キャベツ",
			categoryId: "cat-1",
			unitType: UnitType.gram,
			currentStock: 1000,
			alertThreshold: 200,
			criticalThreshold: 100,
			userId: "user-1",
		);

		yakisoba = MenuItem(
			id: "menu-1",
			name: "焼きそば",
			categoryId: "cat-menu",
			price: 800,
			isAvailable: true,
			displayOrder: 1,
			userId: "user-1",
		);

		when(() => menuItemRepository.findByIds(any())).thenAnswer((_) async => <MenuItem>[yakisoba]);
		when(() => recipeRepository.findByMenuItemIds(any())).thenAnswer((_) async => <Recipe>[]);
		when(() => materialRepository.findByIds(any())).thenAnswer((_) async => <Material>[cabbage]);
	});

	group("getMenuRecipes", () {
		test("returns recipe details with material info", () async {
			final Recipe recipe = Recipe(
				id: "recipe-1",
				menuItemId: "menu-1",
				materialId: "material-1",
				requiredAmount: 120,
				isOptional: false,
				notes: "メイン具材",
				userId: "user-1",
			);

			when(() => recipeRepository.findByMenuItemId("menu-1"))
					.thenAnswer((_) async => <Recipe>[recipe]);

			final List<MenuRecipeDetail> details = await service.getMenuRecipes("menu-1");

			expect(details, hasLength(1));
			expect(details.first.materialName, "キャベツ");
			expect(details.first.requiredAmount, 120);
		});
	});

	group("upsertMenuRecipe", () {
		test("throws ValidationException when amount is negative", () async {
			expect(
				() => service.upsertMenuRecipe(
					menuItemId: "menu-1",
					materialId: "material-1",
					requiredAmount: -1,
				),
				throwsA(isA<ValidationException>()),
			);
		});

		test("creates recipe when none exists", () async {
			when(() => recipeRepository.findByMenuItemAndMaterial("menu-1", "material-1"))
					.thenAnswer((_) async => null);
			when(() => materialRepository.getById("material-1"))
					.thenAnswer((_) async => cabbage);

			final Recipe created = Recipe(
				id: "recipe-1",
				menuItemId: "menu-1",
				materialId: "material-1",
				requiredAmount: 120,
				isOptional: false,
				userId: "user-1",
			);

			when(() => recipeRepository.upsertByMenuItemAndMaterial(any())).thenAnswer(
				(Invocation invocation) async => created,
			);

			when(() => recipeRepository.findByMenuItemIds(any()))
					.thenAnswer((_) async => <Recipe>[created]);

			final result = await service.upsertMenuRecipe(
				menuItemId: "menu-1",
				materialId: "material-1",
				requiredAmount: 120,
			);

			expect(result.recipeId, "recipe-1");
			expect(result.materialName, "キャベツ");
			verify(() => recipeRepository.upsertByMenuItemAndMaterial(any())).called(1);
		});

		test("updates recipe when existing entry found", () async {
			final Recipe existing = Recipe(
				id: "recipe-1",
				menuItemId: "menu-1",
				materialId: "material-1",
				requiredAmount: 100,
				isOptional: true,
				userId: "user-1",
			);

			when(() => recipeRepository.findByMenuItemAndMaterial("menu-1", "material-1"))
					.thenAnswer((_) async => existing);
			when(() => materialRepository.getById("material-1"))
					.thenAnswer((_) async => cabbage);

			final Recipe updated = Recipe(
				id: "recipe-1",
				menuItemId: "menu-1",
				materialId: "material-1",
				requiredAmount: 80,
				isOptional: false,
				userId: "user-1",
			);

			when(() => recipeRepository.upsertByMenuItemAndMaterial(any())).thenAnswer(
				(_) async => updated,
			);
			when(() => recipeRepository.findByMenuItemIds(any()))
					.thenAnswer((_) async => <Recipe>[updated]);

			final result = await service.upsertMenuRecipe(
				menuItemId: "menu-1",
				materialId: "material-1",
				requiredAmount: 80,
				isOptional: false,
			);

			expect(result.requiredAmount, 80);
			expect(result.isOptional, false);
		});
	});

	group("deleteMenuRecipe", () {
		test("deletes recipe and refreshes availability", () async {
			final Recipe recipe = Recipe(
				id: "recipe-1",
				menuItemId: "menu-1",
				materialId: "material-1",
				requiredAmount: 100,
				isOptional: false,
				userId: "user-1",
			);

			when(() => recipeRepository.getById("recipe-1"))
					.thenAnswer((_) async => recipe);
			when(() => recipeRepository.deleteById("recipe-1")).thenAnswer((_) async {});
			when(() => recipeRepository.findByMenuItemIds(any()))
					.thenAnswer((_) async => <Recipe>[]);

			await service.deleteMenuRecipe("recipe-1");

			verify(() => recipeRepository.deleteById("recipe-1")).called(1);
		});
	});
}
