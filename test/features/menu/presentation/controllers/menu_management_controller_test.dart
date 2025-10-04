import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "package:yata/app/wiring/provider.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
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
}
