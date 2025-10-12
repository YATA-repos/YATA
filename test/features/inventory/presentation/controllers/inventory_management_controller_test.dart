import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:yata/app/wiring/provider.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/inventory/dto/inventory_dto.dart";
import "package:yata/features/inventory/models/inventory_model.dart";
import "package:yata/features/inventory/presentation/controllers/inventory_management_controller.dart";
import "package:yata/features/inventory/services/inventory_service.dart";

class _MockInventoryService extends Mock implements InventoryService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late InventoryManagementController controller;
  late _MockInventoryService inventoryService;

  setUp(() {
    inventoryService = _MockInventoryService();
    when(
      () => inventoryService.getMaterialCategories(),
    ).thenAnswer((_) async => <MaterialCategory>[]);
    when(
      () => inventoryService.getMaterialsWithStockInfo(any<String?>(), any<String>()),
    ).thenAnswer((_) async => <MaterialStockInfo>[]);

    container = ProviderContainer(
      overrides: <Override>[
        currentUserIdProvider.overrideWith((Ref _) => "user-1"),
        inventoryServiceProvider.overrideWithValue(inventoryService),
      ],
    );
    controller = container.read(inventoryManagementControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test("buildRowViewData formats inventory row fields", () {
    final DateTime updatedAt = DateTime(2025, 10, 12, 8, 30);
    final InventoryItemViewData item = InventoryItemViewData(
      id: "item-1",
      name: "鶏肉",
      categoryId: "cat-1",
      category: "肉類",
      categoryCode: "MEAT",
      current: 12,
      unitType: UnitType.piece,
      unit: "個",
      alertThreshold: 5,
      criticalThreshold: 2,
      updatedAt: updatedAt,
      updatedBy: "user-1",
      notes: "冷蔵庫2段目",
      searchIndex: InventoryItemViewData.composeSearchIndex(
        name: "鶏肉",
        categoryName: "肉類",
        categoryCode: "MEAT",
      ),
    );

    controller.state = controller.state.copyWith(
      items: <InventoryItemViewData>[item],
      pendingAdjustments: <String, int>{"item-1": 3},
      busyItemIds: const <String>{},
      rowErrors: const <String, String>{},
      isLoading: false,
    );

    final List<InventoryRowViewData> rows = controller.buildRowViewData();

    expect(rows, hasLength(1));
    final InventoryRowViewData row = rows.first;

    expect(row.name, "鶏肉");
    expect(row.categoryName, "肉類");
    expect(row.quantityLabel, "12 個");
    expect(row.quantityValueLabel, "12");
    expect(row.unitLabel, "個");
    expect(row.thresholdsLabel, "警告 5 / 危険 2 個");
    expect(row.deltaLabel, "+3");
    expect(row.afterChangeLabel, "→ 15 個");
    expect(row.updatedAtLabel, "10/12 08:30");
    expect(row.updatedTooltip, "最終更新: 2025/10/12 08:30 / by user-1");
    expect(row.memo, "冷蔵庫2段目");
    expect(row.memoTooltip, "冷蔵庫2段目");
    expect(row.hasMemo, isTrue);
    expect(row.hasPendingDelta, isTrue);
    expect(row.canApplyByRule, isTrue);
    expect(row.isBusy, isFalse);
    expect(row.status, StockStatus.sufficient);
    expect(row.errorMessage, isNull);
    expect(row.badges, hasLength(2));
    expect(row.badges.first.label, "適切");
    expect(row.badges.first.type, InventoryRowBadgeType.success);
    expect(row.badges.last.label, "未適用 +3");
    expect(row.badges.last.type, InventoryRowBadgeType.info);
  });

  test("buildRowViewData marks busy rows and surfacing errors", () {
    final DateTime updatedAt = DateTime(2025, 10, 12, 9);
    final InventoryItemViewData item = InventoryItemViewData(
      id: "item-2",
      name: "レタス",
      categoryId: "cat-2",
      category: "野菜",
      categoryCode: "VEG",
      current: 1,
      unitType: UnitType.piece,
      unit: "個",
      alertThreshold: 5,
      criticalThreshold: 3,
      updatedAt: updatedAt,
      updatedBy: "user-2",
      searchIndex: InventoryItemViewData.composeSearchIndex(
        name: "レタス",
        categoryName: "野菜",
        categoryCode: "VEG",
      ),
    );

    controller.state = controller.state.copyWith(
      items: <InventoryItemViewData>[item],
      pendingAdjustments: <String, int>{"item-2": -5},
      busyItemIds: const <String>{"item-2"},
      rowErrors: const <String, String>{"item-2": "更新に失敗しました"},
      isLoading: false,
    );

    final InventoryRowViewData row = controller.buildRowViewData().first;

    expect(row.deltaLabel, "-5");
    expect(row.deltaTrend, InventoryDeltaTrend.decrease);
    expect(row.afterChangeLabel, "→ 0 個");
    expect(row.canApplyByRule, isFalse);
    expect(row.hasPendingDelta, isTrue);
    expect(row.isBusy, isTrue);
    expect(row.errorMessage, "更新に失敗しました");
    expect(row.memo, "メモ未登録");
    expect(row.hasMemo, isFalse);
    expect(row.memoTooltip, isNull);
    expect(row.status, StockStatus.critical);
    expect(row.badges.first.label, "危険");
    expect(row.badges.first.type, InventoryRowBadgeType.danger);
  });

  test("cycleSummarySort toggles category and clears when descending", () {
    controller.state = controller.state.copyWith(
      sortBy: InventorySortBy.none,
      sortAsc: true,
      isLoading: false,
    );

    controller.cycleSummarySort();
    expect(controller.state.sortBy, InventorySortBy.category);
    expect(controller.state.sortAsc, isTrue);

    controller.cycleSummarySort();
    expect(controller.state.sortBy, InventorySortBy.category);
    expect(controller.state.sortAsc, isFalse);

    controller.cycleSummarySort();
    expect(controller.state.sortBy, InventorySortBy.none);
  });

  test("cycleSummarySort restores category sort from other keys", () {
    controller.state = controller.state.copyWith(
      sortBy: InventorySortBy.delta,
      sortAsc: false,
      isLoading: false,
    );

    controller.cycleSummarySort();
    expect(controller.state.sortBy, InventorySortBy.category);
    expect(controller.state.sortAsc, isTrue);
  });

  test("cycleMetricsSort cycles state and quantity", () {
    controller.state = controller.state.copyWith(
      sortBy: InventorySortBy.none,
      sortAsc: true,
      isLoading: false,
    );

    controller.cycleMetricsSort();
    expect(controller.state.sortBy, InventorySortBy.state);
    expect(controller.state.sortAsc, isTrue);

    controller.cycleMetricsSort();
    expect(controller.state.sortBy, InventorySortBy.state);
    expect(controller.state.sortAsc, isFalse);

    controller.cycleMetricsSort();
    expect(controller.state.sortBy, InventorySortBy.quantity);
    expect(controller.state.sortAsc, isTrue);

    controller.cycleMetricsSort();
    expect(controller.state.sortBy, InventorySortBy.quantity);
    expect(controller.state.sortAsc, isFalse);

    controller.cycleMetricsSort();
    expect(controller.state.sortBy, InventorySortBy.none);
  });

  test("cycleMetricsSort restores from other keys", () {
    controller.state = controller.state.copyWith(
      sortBy: InventorySortBy.delta,
      sortAsc: false,
      isLoading: false,
    );

    controller.cycleMetricsSort();
    expect(controller.state.sortBy, InventorySortBy.state);
    expect(controller.state.sortAsc, isTrue);
  });

  test("filteredItems hits when category name matches search", () {
    final InventoryItemViewData meat = InventoryItemViewData(
      id: "meat",
      name: "鶏肉",
      categoryId: "cat-meat",
      category: "肉類",
      categoryCode: "MEAT",
      current: 5,
      unitType: UnitType.piece,
      unit: "個",
      alertThreshold: 2,
      criticalThreshold: 1,
      updatedAt: DateTime(2025, 10, 1),
      updatedBy: "user-1",
      searchIndex: InventoryItemViewData.composeSearchIndex(
        name: "鶏肉",
        categoryName: "肉類",
        categoryCode: "MEAT",
      ),
    );
    final InventoryItemViewData vegetable = InventoryItemViewData(
      id: "veg",
      name: "レタス",
      categoryId: "cat-veg",
      category: "野菜",
      categoryCode: "VEG",
      current: 12,
      unitType: UnitType.piece,
      unit: "個",
      alertThreshold: 4,
      criticalThreshold: 2,
      updatedAt: DateTime(2025, 10, 2),
      updatedBy: "user-1",
      searchIndex: InventoryItemViewData.composeSearchIndex(
        name: "レタス",
        categoryName: "野菜",
        categoryCode: "VEG",
      ),
    );

    controller.state = controller.state.copyWith(
      items: <InventoryItemViewData>[meat, vegetable],
      categories: const <String>["すべて", "肉類", "野菜"],
      selectedCategoryIndex: 0,
      searchText: "野菜",
      isLoading: false,
    );

  expect(controller.state.filteredItems, <InventoryItemViewData>[vegetable]);
  });

  test("filteredItems hits when category code matches search", () {
    final InventoryItemViewData drink = InventoryItemViewData(
      id: "drink",
      name: "炭酸水",
      categoryId: "cat-drk",
      category: "ドリンク",
      categoryCode: "BEV",
      current: 20,
      unitType: UnitType.piece,
      unit: "本",
      alertThreshold: 6,
      criticalThreshold: 3,
      updatedAt: DateTime(2025, 10, 3),
      updatedBy: "user-2",
      searchIndex: InventoryItemViewData.composeSearchIndex(
        name: "炭酸水",
        categoryName: "ドリンク",
        categoryCode: "BEV",
      ),
    );
    final InventoryItemViewData dessert = InventoryItemViewData(
      id: "dessert",
      name: "プリン",
      categoryId: "cat-des",
      category: "デザート",
      categoryCode: "DST",
      current: 8,
      unitType: UnitType.piece,
      unit: "個",
      alertThreshold: 3,
      criticalThreshold: 1,
      updatedAt: DateTime(2025, 10, 4),
      updatedBy: "user-2",
      searchIndex: InventoryItemViewData.composeSearchIndex(
        name: "プリン",
        categoryName: "デザート",
        categoryCode: "DST",
      ),
    );

    controller.state = controller.state.copyWith(
      items: <InventoryItemViewData>[drink, dessert],
      categories: const <String>["すべて", "ドリンク", "デザート"],
      selectedCategoryIndex: 0,
      searchText: "bev",
      isLoading: false,
    );

  expect(controller.state.filteredItems, <InventoryItemViewData>[drink]);
  });
}
