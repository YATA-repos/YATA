import "package:flutter/material.dart" as flutter;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/features/inventory/dto/inventory_dto.dart";
import "package:yata/features/inventory/dto/transaction_dto.dart";
import "package:yata/features/inventory/models/inventory_model.dart";
import "package:yata/features/inventory/presentation/controllers/inventory_management_controller.dart";
import "package:yata/features/inventory/presentation/pages/inventory_management_page.dart";
import "package:yata/features/inventory/services/inventory_service_contract.dart";

class _StubInventoryService implements InventoryServiceContract {
  @override
  Future<Material?> createMaterial(Material material) async => null;

  @override
  Future<MaterialCategory?> createMaterialCategory(MaterialCategory category) async => null;

  @override
  Future<void> deleteMaterialCategory(String categoryId) async {}

  @override
  Future<List<MaterialCategory>> getMaterialCategories() async => const <MaterialCategory>[];

  @override
  Future<List<MaterialStockInfo>> getMaterialsWithStockInfo(
    String? categoryId,
    String userId,
  ) async => const <MaterialStockInfo>[];

  @override
  Future<Material?> updateMaterial(Material material) async => null;

  @override
  Future<MaterialCategory?> updateMaterialCategory(MaterialCategory category) async => null;

  @override
  Future<Material?> updateMaterialStock(StockUpdateRequest request, String userId) async => null;
}

class _StubInventoryManagementController extends InventoryManagementController {
  _StubInventoryManagementController(Ref ref)
    : super(ref: ref, inventoryService: _StubInventoryService());

  @override
  Future<void> loadInventory() async {
    final DateTime now = DateTime(2025, 10, 12, 10, 0);
    final InventoryItemViewData item = InventoryItemViewData(
      id: "item-1",
      name: "枝豆",
      categoryId: "cat-1",
      category: "野菜",
      current: 12,
      unitType: UnitType.piece,
      unit: "個",
      alertThreshold: 5,
      criticalThreshold: 2,
      updatedAt: now,
      updatedBy: "tester",
      notes: "冷蔵庫下段",
    );

    state = state.copyWith(
      items: <InventoryItemViewData>[item],
      categories: const <String>["すべて", "野菜"],
      categoryEntities: <MaterialCategory>[
        MaterialCategory(id: "cat-1", name: "野菜", displayOrder: 0),
      ],
      materialById: <String, Material>{
        "item-1": Material(
          id: "item-1",
          name: "枝豆",
          categoryId: "cat-1",
          unitType: UnitType.piece,
          currentStock: 12,
          alertThreshold: 5,
          criticalThreshold: 2,
          updatedAt: now,
        ),
      },
      pendingAdjustments: const <String, int>{"item-1": 2},
      busyItemIds: const <String>{},
      rowErrors: const <String, String>{},
      isLoading: false,
      clearErrorMessage: true,
    );
  }
}

void main() {
  testWidgets("inventory table shows compact summary/action columns", (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          inventoryManagementControllerProvider.overrideWith(
            (Ref ref) => _StubInventoryManagementController(ref),
          ),
        ],
        child: const flutter.MaterialApp(home: flutter.Scaffold(body: InventoryManagementPage())),
      ),
    );

    await tester.pumpAndSettle();

    final flutter.DataTable dataTable = tester.widget<flutter.DataTable>(find.byType(flutter.DataTable));
    expect(dataTable.columns, hasLength(2));
    expect(find.text("在庫情報"), findsOneWidget);
    expect(find.text("調整操作"), findsOneWidget);
    expect(find.byIcon(flutter.Icons.save_outlined), findsWidgets);
  });
}
