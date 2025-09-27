import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/inventory/dto/inventory_dto.dart";
import "package:yata/features/inventory/dto/transaction_dto.dart";
import "package:yata/features/inventory/models/inventory_model.dart";
import "package:yata/features/inventory/presentation/controllers/inventory_management_controller.dart";
import "package:yata/features/inventory/services/inventory_service_contract.dart";

void main() {
  group("InventoryManagementController bulk actions", () {
    late InventoryManagementController controller;

    setUp(() async {
      controller = InventoryManagementController(
        ref: _FakeRef(
          values: <ProviderListenable<dynamic>, dynamic>{currentUserIdProvider: "current_user"},
        ),
        inventoryService: _FakeInventoryService(),
      );

      await controller.loadInventory();
    });

    tearDown(() => controller.dispose());

    test("applySelected applies only valid adjustments and clears selection", () async {
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
      await pumpEventQueue();

      final InventoryItemViewData updatedFirst = controller.state.items.firstWhere(
        (InventoryItemViewData i) => i.id == first.id,
      );
      final InventoryItemViewData updatedSecond = controller.state.items.firstWhere(
        (InventoryItemViewData i) => i.id == second.id,
      );

      expect(updatedFirst.current, firstBefore - 5);
      expect(updatedFirst.updatedAt.isAfter(firstUpdatedAtBefore), isTrue);
      expect(updatedFirst.updatedBy, "current_user");

      expect(updatedSecond.current, secondBefore);

      expect(controller.state.pendingAdjustments.containsKey(first.id), isFalse);
      expect(controller.state.pendingAdjustments[second.id], -20);
      expect(controller.state.selectedIds, isEmpty);
    });

    test("applyAllVisible applies adjustments for visible items and clears selection", () async {
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
      await pumpEventQueue();

      final InventoryItemViewData updatedFirst = controller.state.items.firstWhere(
        (InventoryItemViewData i) => i.id == first.id,
      );
      final InventoryItemViewData updatedSecond = controller.state.items.firstWhere(
        (InventoryItemViewData i) => i.id == second.id,
      );

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

    test("createInventoryItem adds new entry and refreshes state", () async {
      final String? result = await controller.createInventoryItem(
        name: "ネギ",
        categoryId: "cat_ingredients",
        unitType: UnitType.piece,
        currentStock: 12,
        alertThreshold: 4,
        criticalThreshold: 2,
        notes: "仕入れ先A",
      );

      expect(result, isNull);
      await pumpEventQueue();

      expect(controller.state.items.length, 3);
      final InventoryItemViewData created = controller.state.items.firstWhere(
        (InventoryItemViewData item) => item.name == "ネギ",
      );
      expect(created.categoryId, "cat_ingredients");
      expect(created.unitType, UnitType.piece);
      expect(created.current, 12);
      expect(created.alertThreshold, 4);
      expect(created.criticalThreshold, 2);
      expect(created.notes, "仕入れ先A");
    });

    test("updateInventoryItem updates existing entry", () async {
      final InventoryItemViewData target = controller.state.items.first;

      final String? result = await controller.updateInventoryItem(
        target.id,
        name: "キャベツ（特大）",
        categoryId: "cat_ingredients",
        unitType: UnitType.kilogram,
        currentStock: target.current + 5,
        alertThreshold: target.alertThreshold + 1,
        criticalThreshold: target.criticalThreshold,
        notes: "サイズ変更",
      );

      expect(result, isNull);
      await pumpEventQueue();

      final InventoryItemViewData updated = controller.state.items.firstWhere(
        (InventoryItemViewData item) => item.id == target.id,
      );
      expect(updated.name, "キャベツ（特大）");
      expect(updated.unitType, UnitType.kilogram);
      expect(updated.current, target.current + 5);
      expect(updated.alertThreshold, target.alertThreshold + 1);
      expect(updated.notes, "サイズ変更");

      final Material? material = controller.state.materialById[target.id];
      expect(material, isNotNull);
      expect(material!.unitType, UnitType.kilogram);
      expect(material.notes, "サイズ変更");
    });
  });
}

class _FakeInventoryService implements InventoryServiceContract {
  _FakeInventoryService() {
    final DateTime now = DateTime(2024);

    _categories = <MaterialCategory>[
      MaterialCategory(
        id: "cat_ingredients",
        name: "食材",
        displayOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      MaterialCategory(
        id: "cat_condiments",
        name: "調味料",
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    _stockInfos = <MaterialStockInfo>[
      MaterialStockInfo(
        material: Material(
          id: "mat_1",
          name: "キャベツ",
          categoryId: "cat_ingredients",
          unitType: UnitType.piece,
          currentStock: 20,
          alertThreshold: 5,
          criticalThreshold: 2,
          createdAt: now,
          updatedAt: now,
          userId: "current_user",
        ),
        stockLevel: StockLevel.sufficient,
      ),
      MaterialStockInfo(
        material: Material(
          id: "mat_2",
          name: "ソース",
          categoryId: "cat_condiments",
          unitType: UnitType.liter,
          currentStock: 8,
          alertThreshold: 3,
          criticalThreshold: 1,
          createdAt: now,
          updatedAt: now,
          userId: "current_user",
        ),
        stockLevel: StockLevel.sufficient,
      ),
    ];
  }

  late final List<MaterialCategory> _categories;
  late final List<MaterialStockInfo> _stockInfos;

  @override
  Future<List<MaterialCategory>> getMaterialCategories() async =>
      _categories.toList(growable: false);

  @override
  Future<List<MaterialStockInfo>> getMaterialsWithStockInfo(
    String? categoryId,
    String userId,
  ) async => _stockInfos
      .where(
        (MaterialStockInfo info) => categoryId == null || info.material.categoryId == categoryId,
      )
      .map(
        (MaterialStockInfo info) => MaterialStockInfo(
          material: info.material,
          stockLevel: info.stockLevel,
          estimatedUsageDays: info.estimatedUsageDays,
          dailyUsageRate: info.dailyUsageRate,
        ),
      )
      .toList(growable: false);

  @override
  Future<Material?> createMaterial(Material material) async {
    final String newId = material.id ?? "mat_${_stockInfos.length + 1}";
    final DateTime now = material.createdAt ?? DateTime.now();
    final Material created = Material(
      id: newId,
      name: material.name,
      categoryId: material.categoryId,
      unitType: material.unitType,
      currentStock: material.currentStock,
      alertThreshold: material.alertThreshold,
      criticalThreshold: material.criticalThreshold,
      notes: material.notes,
      createdAt: now,
      updatedAt: material.updatedAt ?? now,
      userId: material.userId,
    );

    _stockInfos.add(MaterialStockInfo(material: created, stockLevel: created.getStockLevel()));

    return created;
  }

  @override
  Future<Material?> updateMaterial(Material material) async {
    for (final MaterialStockInfo info in _stockInfos) {
      if (info.material.id == material.id) {
        info.material
          ..name = material.name
          ..categoryId = material.categoryId
          ..unitType = material.unitType
          ..currentStock = material.currentStock
          ..alertThreshold = material.alertThreshold
          ..criticalThreshold = material.criticalThreshold
          ..notes = material.notes
          ..updatedAt = material.updatedAt ?? DateTime.now()
          ..userId = material.userId;
        info.stockLevel = info.material.getStockLevel();
        return info.material;
      }
    }
    return null;
  }

  @override
  Future<Material?> updateMaterialStock(StockUpdateRequest request, String userId) async {
    for (final MaterialStockInfo info in _stockInfos) {
      if (info.material.id == request.materialId) {
        info.material
          ..currentStock = request.newQuantity
          ..updatedAt = DateTime.now()
          ..userId = userId;
        return info.material;
      }
    }
    return null;
  }
}

class _FakeRef implements Ref<Object?> {
  _FakeRef({required Map<ProviderListenable<dynamic>, dynamic> values}) : _values = values;

  final Map<ProviderListenable<dynamic>, dynamic> _values;

  @override
  ProviderContainer get container => throw UnsupportedError("container is not available in tests");

  @override
  bool exists(ProviderBase<Object?> provider) =>
      throw UnsupportedError("exists is not supported in tests");

  @override
  void invalidate(ProviderOrFamily provider) =>
      throw UnsupportedError("invalidate is not supported in tests");

  @override
  void invalidateSelf() => throw UnsupportedError("invalidateSelf is not supported");

  @override
  KeepAliveLink keepAlive() => throw UnsupportedError("keepAlive is not supported");

  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) => throw UnsupportedError("listen is not supported in tests");

  @override
  void listenSelf(
    void Function(Object? previous, Object? next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) => throw UnsupportedError("listenSelf is not supported");

  @override
  void notifyListeners() => throw UnsupportedError("notifyListeners is not supported in tests");

  @override
  void onAddListener(void Function() cb) =>
      throw UnsupportedError("onAddListener is not supported in tests");

  @override
  void onCancel(void Function() cb) => throw UnsupportedError("onCancel is not supported in tests");

  @override
  void onDispose(void Function() cb) =>
      throw UnsupportedError("onDispose is not supported in tests");

  @override
  void onRemoveListener(void Function() cb) =>
      throw UnsupportedError("onRemoveListener is not supported");

  @override
  void onResume(void Function() cb) => throw UnsupportedError("onResume is not supported in tests");

  @override
  T read<T>(ProviderListenable<T> provider) {
    if (_values.containsKey(provider)) {
      return _values[provider] as T;
    }
    throw UnsupportedError("Unhandled provider: $provider");
  }

  @override
  T refresh<T>(Refreshable<T> provider) =>
      throw UnsupportedError("refresh is not supported in tests");

  @override
  T watch<T>(ProviderListenable<T> provider) =>
      throw UnsupportedError("watch is not supported in tests");
}
