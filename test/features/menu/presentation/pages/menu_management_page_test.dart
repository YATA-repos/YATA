import "package:flutter/material.dart";
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
import "package:yata/features/menu/presentation/pages/menu_management_page.dart";
import "package:yata/features/menu/services/menu_service.dart";

class _MockMenuService extends Mock implements MenuService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String userId = "user-1";
  const String menuId = "menu-1";

  late ProviderContainer container;
  late _MockMenuService menuService;
  late MenuAvailabilityInfo availabilityInfo;

  setUp(() {
    menuService = _MockMenuService();
    availabilityInfo = MenuAvailabilityInfo(
      menuItemId: menuId,
      isAvailable: true,
      missingMaterials: const <String>[],
      estimatedServings: 8,
    );

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
    when(
      () => menuService.bulkCheckMenuAvailability(any()),
    ).thenAnswer((_) async => <String, MenuAvailabilityInfo>{menuId: availabilityInfo});
    when(() => menuService.getMenuRecipes(any())).thenAnswer((_) async => <MenuRecipeDetail>[]);
    when(
      () => menuService.refreshMenuAvailabilityForMenu(any()),
    ).thenAnswer((_) async => availabilityInfo);
    when(
      () => menuService.calculateMaxServings(any(), any()),
    ).thenAnswer((_) async => availabilityInfo.estimatedServings ?? 0);

    container = ProviderContainer(
      overrides: <Override>[
        currentUserIdProvider.overrideWith((Ref _) => userId),
        menuServiceProvider.overrideWithValue(menuService),
      ],
    );
  });

  tearDown(() => container.dispose());

  testWidgets("行タップで詳細モーダルを表示し、閉じる操作で状態をリセットする", (WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MenuManagementPage()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text("焼きそば"), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await tester.ensureVisible(find.text("焼きそば"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("焼きそば"));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text("メニュー詳細"), findsOneWidget);

    await tester.tap(find.byTooltip("閉じる"));
    await tester.pump();
    await tester.pumpAndSettle();

    final MenuManagementState state = container.read(menuManagementControllerProvider);
    expect(state.detail, isNull);
    expect(state.selectedMenuId, isNull);
  });

  testWidgets("販売状態スイッチを操作すると可否が更新される", (WidgetTester tester) async {
    when(() => menuService.toggleMenuItemAvailability(any(), any(), any())).thenAnswer(
      (Invocation invocation) async {
        final bool next = invocation.positionalArguments[1] as bool;
        return MenuItem(
          id: menuId,
          name: "焼きそば",
          categoryId: "cat-1",
          price: 800,
          isAvailable: next,
          displayOrder: 1,
        );
      },
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MenuManagementPage()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final Finder switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();

    await tester.tap(switchFinder, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    verify(() => menuService.toggleMenuItemAvailability(menuId, false, userId)).called(1);
  });
}
