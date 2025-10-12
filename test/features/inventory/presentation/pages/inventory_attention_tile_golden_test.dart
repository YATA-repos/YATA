import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/features/inventory/presentation/controllers/inventory_management_controller.dart";
import "package:yata/features/inventory/presentation/pages/inventory_management_page.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("AttentionInventoryTile golden", () {
    Future<void> pumpTile(
      WidgetTester tester,
      InventoryItemViewData item,
      String goldenName,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 160));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: buildAttentionInventoryTileForTest(item: item, onEditItem: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(find.byType(Scaffold), matchesGoldenFile("goldens/$goldenName.png"));
    }

    testWidgets("renders critical status", (WidgetTester tester) async {
      final InventoryItemViewData item = InventoryItemViewData(
        id: "critical-1",
        name: "生鮮トマトパック",
        categoryId: "vegetable",
        category: "野菜",
        current: 1.5,
        unitType: UnitType.kilogram,
        unit: "kg",
        alertThreshold: 3,
        criticalThreshold: 2,
        updatedAt: DateTime(2025, 10, 13, 9, 0),
        updatedBy: "tester",
        notes: "冷蔵庫上段",
      );

      await pumpTile(tester, item, "inventory_attention_tile_critical");
    }, tags: <String>["golden"]);

    testWidgets("renders low status", (WidgetTester tester) async {
      final InventoryItemViewData item = InventoryItemViewData(
        id: "low-1",
        name: "自家製トマトソース",
        categoryId: "sauce",
        category: "ソース",
        current: 4,
        unitType: UnitType.liter,
        unit: "L",
        alertThreshold: 5,
        criticalThreshold: 2,
        updatedAt: DateTime(2025, 10, 13, 9, 0),
        updatedBy: "tester",
        notes: null,
      );

      await pumpTile(tester, item, "inventory_attention_tile_low");
    }, tags: <String>["golden"]);
  });
}
