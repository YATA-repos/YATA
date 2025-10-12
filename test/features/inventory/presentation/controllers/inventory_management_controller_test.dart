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
      current: 12,
      unitType: UnitType.piece,
      unit: "個",
      alertThreshold: 5,
      criticalThreshold: 2,
      updatedAt: updatedAt,
      updatedBy: "user-1",
      notes: "冷蔵庫2段目",
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
    expect(row.thresholdsLabel, "警告 5 / 危険 2 個");
    expect(row.deltaLabel, "+3");
    expect(row.afterChangeLabel, "→ 15 個");
    expect(row.updatedAtLabel, "10/12 08:30");
    expect(row.updatedTooltip, "最終更新: 2025/10/12 08:30 / by user-1");
    expect(row.memo, "冷蔵庫2段目");
    expect(row.hasMemo, isTrue);
    expect(row.hasPendingDelta, isTrue);
    expect(row.canApplyByRule, isTrue);
    expect(row.isBusy, isFalse);
    expect(row.errorMessage, isNull);
    expect(row.badges, hasLength(2));
    expect(row.badges.first.label, "在庫良好");
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
      current: 1,
      unitType: UnitType.piece,
      unit: "個",
      alertThreshold: 5,
      criticalThreshold: 3,
      updatedAt: updatedAt,
      updatedBy: "user-2",
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
    expect(row.badges.first.label, "緊急補充");
    expect(row.badges.first.type, InventoryRowBadgeType.danger);
  });
}
