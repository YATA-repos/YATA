import "package:flutter_test/flutter_test.dart";

import "package:yata/features/inventory/presentation/controllers/inventory_management_controller.dart";

void main() {
  group("InventoryManagementController bulk actions", () {
    late InventoryManagementController controller;

    setUp(() {
      controller = InventoryManagementController();
    });

    test("applySelected applies only valid adjustments and clears selection", () {
      final InventoryItemViewData first = controller.state.items[0];
      final InventoryItemViewData second = controller.state.items[1];

      controller
        ..setPendingAdjustment(first.id, -5)
        ..setPendingAdjustment(second.id, -20)
        ..toggleSelect(first.id)
        ..toggleSelect(second.id);

      final double firstBefore = first.current;
      final DateTime firstUpdatedAtBefore = first.updatedAt;
      final double secondBefore = second.current;

      controller.applySelected();

      final InventoryItemViewData updatedFirst = controller.state.items.firstWhere((InventoryItemViewData i) => i.id == first.id);
      final InventoryItemViewData updatedSecond = controller.state.items.firstWhere((InventoryItemViewData i) => i.id == second.id);

      expect(updatedFirst.current, firstBefore - 5);
      expect(updatedFirst.updatedAt.isAfter(firstUpdatedAtBefore), isTrue);
      expect(updatedFirst.updatedBy, "current_user");

      expect(updatedSecond.current, secondBefore);

      expect(controller.state.pendingAdjustments.containsKey(first.id), isFalse);
      expect(controller.state.pendingAdjustments[second.id], -20);
      expect(controller.state.selectedIds, isEmpty);
    });

    test("applyAllVisible applies adjustments for visible items and clears selection", () {
      final InventoryItemViewData first = controller.state.items[0];
      final InventoryItemViewData second = controller.state.items[1];

      controller
        ..setPendingAdjustment(first.id, 3)
        ..setPendingAdjustment(second.id, -100)
        ..toggleSelect(first.id)
        ..toggleSelect(second.id);

      final double firstBefore = first.current;
      final double secondBefore = second.current;

      controller.applyAllVisible();

      final InventoryItemViewData updatedFirst = controller.state.items.firstWhere((InventoryItemViewData i) => i.id == first.id);
      final InventoryItemViewData updatedSecond = controller.state.items.firstWhere((InventoryItemViewData i) => i.id == second.id);

      expect(updatedFirst.current, firstBefore + 3);
      expect(updatedSecond.current, secondBefore);

      expect(controller.state.pendingAdjustments.containsKey(first.id), isFalse);
      expect(controller.state.pendingAdjustments[second.id], -100);
      expect(controller.state.selectedIds, isEmpty);
    });

    test("clearAdjustmentsForSelected removes pending deltas for selected items", () {
      final InventoryItemViewData first = controller.state.items[0];
      final InventoryItemViewData second = controller.state.items[1];

      controller
        ..setPendingAdjustment(first.id, 4)
        ..setPendingAdjustment(second.id, -2)
        ..toggleSelect(first.id)
        ..clearAdjustmentsForSelected();

      expect(controller.state.pendingAdjustments.containsKey(first.id), isFalse);
      expect(controller.state.pendingAdjustments[second.id], -2);
      expect(controller.state.selectedIds.contains(first.id), isTrue);
    });
  });
}
