import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/utils/error_handler.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../dto/inventory_dto.dart";
import "../../dto/transaction_dto.dart";
import "../../models/inventory_model.dart";
import "../../services/inventory_service_contract.dart";

/// 在庫ステータス。
enum StockStatus { sufficient, low, critical }

/// 在庫アイテムの表示用データ。
class InventoryItemViewData {
  const InventoryItemViewData({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.category,
    required this.current,
    required this.unitType,
    required this.unit,
    required this.alertThreshold,
    required this.criticalThreshold,
    required this.updatedAt,
    required this.updatedBy,
    this.notes,
  });

  final String id;
  final String name;
  final String categoryId;
  final String category;
  final double current;
  final UnitType unitType;
  final String unit;
  final double alertThreshold;
  final double criticalThreshold;
  final DateTime updatedAt;
  final String updatedBy;
  final String? notes;

  StockStatus get status {
    if (current <= criticalThreshold) {
      return StockStatus.critical;
    }
    if (current <= alertThreshold) {
      return StockStatus.low;
    }
    return StockStatus.sufficient;
  }

  InventoryItemViewData copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? category,
    double? current,
    UnitType? unitType,
    String? unit,
    double? alertThreshold,
    double? criticalThreshold,
    DateTime? updatedAt,
    String? updatedBy,
    String? notes,
  }) => InventoryItemViewData(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    category: category ?? this.category,
    current: current ?? this.current,
    unitType: unitType ?? this.unitType,
    unit: unit ?? this.unit,
    alertThreshold: alertThreshold ?? this.alertThreshold,
    criticalThreshold: criticalThreshold ?? this.criticalThreshold,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    notes: notes ?? this.notes,
  );
}

/// 画面状態。
class InventoryManagementState {
  const InventoryManagementState({
    required this.items,
    required this.categories,
    required this.categoryEntities,
    required this.materialById,
    required this.selectedCategoryIndex,
    required this.selectedStatusFilter, // null=全て、sufficient/low/critical
    required this.searchText,
    required this.pendingAdjustments,
    required this.sortBy,
    required this.sortAsc,
    required this.selectedIds,
    this.isLoading = false,
    this.errorMessage,
  });

  // コンストラクタは他メンバより前に配置（lint: sort_constructors_first対応）
  factory InventoryManagementState.initial() => InventoryManagementState(
    items: const <InventoryItemViewData>[],
    categories: const <String>["すべて"],
    categoryEntities: const <MaterialCategory>[],
    materialById: const <String, Material>{},
    selectedCategoryIndex: 0,
    selectedStatusFilter: null,
    searchText: "",
    pendingAdjustments: const <String, int>{},
    sortBy: InventorySortBy.none,
    sortAsc: true,
    selectedIds: const <String>{},
    isLoading: true,
  );

  final List<InventoryItemViewData> items;
  final List<String> categories; // 先頭は "すべて"
  final List<MaterialCategory> categoryEntities;
  final Map<String, Material> materialById;
  final int selectedCategoryIndex;
  final StockStatus? selectedStatusFilter;
  final String searchText;
  final Map<String, int> pendingAdjustments; // itemId -> delta
  final InventorySortBy sortBy;
  final bool sortAsc;
  final Set<String> selectedIds;
  final bool isLoading;
  final String? errorMessage;

  List<InventoryItemViewData> get filteredItems {
    final String query = searchText.trim().toLowerCase();
    final String? category = selectedCategoryIndex == 0 ? null : categories[selectedCategoryIndex];

    List<InventoryItemViewData> list = items
        .where((InventoryItemViewData i) {
          final bool q = query.isEmpty || i.name.toLowerCase().contains(query);
          final bool c = category == null || i.category == category;
          final bool s = selectedStatusFilter == null || i.status == selectedStatusFilter;
          return q && c && s;
        })
        .toList(growable: false);

    int cmpNum(num a, num b) => a.compareTo(b);
    int cmpDate(DateTime a, DateTime b) => a.compareTo(b);
    switch (sortBy) {
      case InventorySortBy.category:
        list.sort(
          (InventoryItemViewData a, InventoryItemViewData b) =>
              _compareCategoryName(a.category, b.category),
        );
        break;
      case InventorySortBy.state:
        list.sort(
          (InventoryItemViewData a, InventoryItemViewData b) =>
              a.status.index.compareTo(b.status.index),
        );
        break;
      case InventorySortBy.quantity:
        list.sort(
          (InventoryItemViewData a, InventoryItemViewData b) => cmpNum(a.current, b.current),
        );
        break;
      case InventorySortBy.delta:
        list.sort((InventoryItemViewData a, InventoryItemViewData b) {
          final int da = pendingAdjustments[a.id] ?? 0;
          final int db = pendingAdjustments[b.id] ?? 0;
          return da.compareTo(db);
        });
        break;
      case InventorySortBy.updatedAt:
        list.sort(
          (InventoryItemViewData a, InventoryItemViewData b) => cmpDate(a.updatedAt, b.updatedAt),
        );
        break;
      case InventorySortBy.none:
        break;
    }
    if (!sortAsc) {
      list = list.reversed.toList(growable: false);
    }
    return list;
  }

  int get totalItems => items.length;
  int get lowCount => items.where((InventoryItemViewData i) => i.status == StockStatus.low).length;
  int get criticalCount =>
      items.where((InventoryItemViewData i) => i.status == StockStatus.critical).length;

  /// 未適用件数。
  int get pendingCount => pendingAdjustments.length;

  /// 合計差分。
  int get pendingDeltaTotal => pendingAdjustments.values.fold<int>(0, (int acc, int v) => acc + v);

  InventoryManagementState copyWith({
    List<InventoryItemViewData>? items,
    List<String>? categories,
    List<MaterialCategory>? categoryEntities,
    Map<String, Material>? materialById,
    int? selectedCategoryIndex,
    StockStatus? selectedStatusFilter,
    bool selectedStatusFilterSet = false,
    String? searchText,
    Map<String, int>? pendingAdjustments,
    InventorySortBy? sortBy,
    bool? sortAsc,
    Set<String>? selectedIds,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => InventoryManagementState(
    items: items ?? this.items,
    categories: categories ?? this.categories,
    categoryEntities: categoryEntities ?? this.categoryEntities,
    materialById: materialById ?? this.materialById,
    selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
    selectedStatusFilter: selectedStatusFilterSet
        ? selectedStatusFilter
        : this.selectedStatusFilter,
    searchText: searchText ?? this.searchText,
    pendingAdjustments: pendingAdjustments ?? this.pendingAdjustments,
    sortBy: sortBy ?? this.sortBy,
    sortAsc: sortAsc ?? this.sortAsc,
    selectedIds: selectedIds ?? this.selectedIds,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
  );
}

/// 在庫管理画面のコントローラ。
class InventoryManagementController extends StateNotifier<InventoryManagementState> {
  InventoryManagementController({
    required Ref ref,
    required InventoryServiceContract inventoryService,
  }) : _ref = ref,
       _inventoryService = inventoryService,
       super(InventoryManagementState.initial()) {
    unawaited(loadInventory());
  }

  final Ref _ref;
  final InventoryServiceContract _inventoryService;

  /// 初期データおよび最新データを取得する。
  Future<void> loadInventory() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = state.copyWith(isLoading: false, errorMessage: "ユーザー情報を取得できませんでした。再度ログインしてください。");
      return;
    }

    try {
      final List<MaterialCategory> categoryModels = await _inventoryService.getMaterialCategories();
      final List<MaterialStockInfo> stockInfos = await _inventoryService.getMaterialsWithStockInfo(
        null,
        userId,
      );

    final String? previousCategorySelectionRaw =
          state.selectedCategoryIndex <= 0 || state.selectedCategoryIndex >= state.categories.length
              ? null
              : state.categories[state.selectedCategoryIndex];
    final String? previousCategorySelection = previousCategorySelectionRaw == null
      ? null
      : (previousCategorySelectionRaw.trim().isEmpty
        ? null
        : previousCategorySelectionRaw.trim());

    String? previousCategoryId;
    if (previousCategorySelection != null) {
      for (final MaterialCategory category in state.categoryEntities) {
        final String trimmed = category.name.trim();
        if (trimmed.isEmpty) {
          continue;
        }
        if (trimmed == previousCategorySelection) {
          previousCategoryId = category.id;
          break;
        }
      }
    }

      final Map<String, String> categoryNameById = <String, String>{
        for (final MaterialCategory category in categoryModels)
          if (category.id != null) category.id!: category.name.trim(),
      };

      final Set<String> validIds = <String>{};
      final Map<String, Material> materialMap = <String, Material>{};

      final List<InventoryItemViewData> items = stockInfos
          .where((MaterialStockInfo info) => info.material.id != null)
          .map((MaterialStockInfo info) {
            final Material material = info.material;
            final String id = material.id!;
            validIds.add(id);
            materialMap[id] = material;
      final String rawCategoryName = categoryNameById[material.categoryId] ?? "未分類";
      final String categoryName = rawCategoryName.trim().isEmpty
        ? "未分類"
        : rawCategoryName.trim();

            final DateTime updatedAt = material.updatedAt ?? material.createdAt ?? DateTime.now();

            return InventoryItemViewData(
              id: id,
              name: material.name,
              categoryId: material.categoryId,
              category: categoryName,
              current: material.currentStock,
              unitType: material.unitType,
              unit: material.unitType.symbol,
              alertThreshold: material.alertThreshold,
              criticalThreshold: material.criticalThreshold,
              updatedAt: updatedAt,
              updatedBy: material.userId ?? "system",
              notes: material.notes,
            );
          })
          .toList(growable: false);

        final Set<String> categoryNames = <String>{};
        for (final MaterialCategory category in categoryModels) {
          final String name = category.name.trim();
          if (name.isNotEmpty) {
            categoryNames.add(name);
          }
        }
        for (final InventoryItemViewData item in items) {
          final String name = item.category.trim();
          if (name.isNotEmpty) {
            categoryNames.add(name);
          }
        }

        final List<String> sortedCategoryNames = categoryNames.toList(growable: false)
          ..sort(_compareCategoryName);
        final List<String> categories = <String>["すべて", ...sortedCategoryNames];

        int resolvedCategoryIndex = 0;

        if (previousCategoryId != null) {
          String? resolvedName;
          for (final MaterialCategory category in categoryModels) {
            if (category.id == previousCategoryId) {
              final String trimmedName = category.name.trim();
              if (trimmedName.isNotEmpty) {
                resolvedName = trimmedName;
              }
              break;
            }
          }

          if (resolvedName != null) {
            for (int i = 0; i < categories.length; i++) {
              if (categories[i].trim() == resolvedName) {
                resolvedCategoryIndex = i;
                break;
              }
            }
          }
        }

        if (resolvedCategoryIndex == 0 && previousCategorySelection != null) {
          final int index = categories.indexOf(previousCategorySelection);
          if (index >= 0) {
            resolvedCategoryIndex = index;
          }
        }

      final Map<String, int> pending = Map<String, int>.from(state.pendingAdjustments)
        ..removeWhere((String key, _) => !validIds.contains(key));

      final Set<String> selectedIds = state.selectedIds.where(validIds.contains).toSet();

      state = state.copyWith(
        items: items,
        categories: categories,
        categoryEntities: List<MaterialCategory>.unmodifiable(categoryModels),
        materialById: Map<String, Material>.unmodifiable(materialMap),
          selectedCategoryIndex: resolvedCategoryIndex,
        pendingAdjustments: pending,
        selectedIds: selectedIds,
        isLoading: false,
        clearErrorMessage: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  /// データを再読み込みする。
  void refresh() => unawaited(loadInventory());

  /// 材料カテゴリを新規作成する。
  Future<String?> createCategory(String name) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      const String message = "カテゴリ名を入力してください。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    if (_ref.read(currentUserIdProvider) == null) {
      const String message = "ユーザー情報を取得できませんでした。再度ログインしてください。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    int nextDisplayOrder = 0;
    for (final MaterialCategory category in state.categoryEntities) {
      if (category.displayOrder >= nextDisplayOrder) {
        nextDisplayOrder = category.displayOrder + 1;
      }
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      await _inventoryService.createMaterialCategory(
        MaterialCategory(
          name: trimmedName,
          displayOrder: nextDisplayOrder,
        ),
      );
      await loadInventory();
      return null;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return message;
    }
  }

  /// 材料カテゴリの名称を変更する。
  Future<String?> renameCategory(String categoryId, String newName) async {
    final String trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      const String message = "カテゴリ名を入力してください。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    MaterialCategory? targetCategory;
    for (final MaterialCategory category in state.categoryEntities) {
      if (category.id == categoryId) {
        targetCategory = category;
        break;
      }
    }

    if (targetCategory == null || targetCategory.id == null) {
      const String message = "対象のカテゴリが見つかりませんでした。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    final String currentName = targetCategory.name.trim();
    if (currentName == trimmedName) {
      return "カテゴリ名は変更されていません。";
    }

    final String normalizedName = trimmedName.toLowerCase();
    final bool duplicateExists = state.categoryEntities.any(
      (MaterialCategory category) =>
          category.id != categoryId && category.name.trim().toLowerCase() == normalizedName,
    );

    if (duplicateExists) {
      const String message = "同じ名前のカテゴリが既に存在します。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      await _inventoryService.updateMaterialCategory(
        MaterialCategory(
          id: targetCategory.id,
          name: trimmedName,
          displayOrder: targetCategory.displayOrder,
          createdAt: targetCategory.createdAt,
          updatedAt: DateTime.now(),
          userId: targetCategory.userId,
        ),
      );

      await loadInventory();
      return null;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return message;
    }
  }

  /// 材料カテゴリを削除する。
  Future<String?> deleteCategory(String categoryId) async {
    MaterialCategory? targetCategory;
    for (final MaterialCategory category in state.categoryEntities) {
      if (category.id == categoryId) {
        targetCategory = category;
        break;
      }
    }

    if (targetCategory == null || targetCategory.id == null) {
      const String message = "削除対象のカテゴリが見つかりませんでした。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    final bool hasLinkedItems = state.items.any(
      (InventoryItemViewData item) => item.categoryId == categoryId,
    );

    if (hasLinkedItems) {
      const String message = "このカテゴリに紐づく在庫アイテムが存在するため削除できません。";
      return message;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      await _inventoryService.deleteMaterialCategory(categoryId);
      await loadInventory();
      return null;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return message;
    }
  }

  /// 材料を新規作成する。
  Future<String?> createInventoryItem({
    required String name,
    required String categoryId,
    required UnitType unitType,
    required double currentStock,
    required double alertThreshold,
    required double criticalThreshold,
    String? notes,
  }) async {
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      const String message = "ユーザー情報を取得できませんでした。再度ログインしてください。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      await _inventoryService.createMaterial(
        Material(
          name: name,
          categoryId: categoryId,
          unitType: unitType,
          currentStock: currentStock,
          alertThreshold: alertThreshold,
          criticalThreshold: criticalThreshold,
          notes: notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: userId,
        ),
      );
      await loadInventory();
      return null;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return message;
    }
  }

  /// 材料情報を更新する。
  Future<String?> updateInventoryItem(
    String itemId, {
    required String name,
    required String categoryId,
    required UnitType unitType,
    required double currentStock,
    required double alertThreshold,
    required double criticalThreshold,
    String? notes,
  }) async {
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      const String message = "ユーザー情報を取得できませんでした。再度ログインしてください。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    final Material? baseMaterial = state.materialById[itemId];
    if (baseMaterial == null) {
      const String message = "対象の在庫情報が見つかりませんでした。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      await _inventoryService.updateMaterial(
        Material(
          id: itemId,
          name: name,
          categoryId: categoryId,
          unitType: unitType,
          currentStock: currentStock,
          alertThreshold: alertThreshold,
          criticalThreshold: criticalThreshold,
          notes: notes,
          createdAt: baseMaterial.createdAt,
          updatedAt: DateTime.now(),
          userId: baseMaterial.userId ?? userId,
        ),
      );
      await loadInventory();
      return null;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return message;
    }
  }

  void setSearchText(String value) =>
      state = state.copyWith(searchText: value, clearErrorMessage: true);

  void selectCategory(int index) => state = state.copyWith(selectedCategoryIndex: index);

  /// ステータスカードでのフィルタ選択/解除。
  void toggleStatusFilter(StockStatus s) {
    final StockStatus? current = state.selectedStatusFilter;
    state = state.copyWith(
      selectedStatusFilter: current == s ? null : s,
      selectedStatusFilterSet: true,
    );
  }

  /// ソートキーの変更。既に同じキーなら昇順/降順をトグル、違うキーなら昇順に設定。
  void sortBy(InventorySortBy key) {
    if (state.sortBy == key) {
      state = state.copyWith(sortAsc: !state.sortAsc);
    } else {
      state = state.copyWith(sortBy: key, sortAsc: true);
    }
  }

  /// ソートのサイクル: none -> asc -> desc -> none ...
  void cycleSort(InventorySortBy key) {
    if (state.sortBy != key) {
      state = state.copyWith(sortBy: key, sortAsc: true);
      return;
    }
    if (state.sortAsc) {
      state = state.copyWith(sortAsc: false);
    } else {
      state = state.copyWith(sortBy: InventorySortBy.none);
    }
  }

  /// 行の調整量(差分)を設定。負数で出庫、正数で入庫。
  void setPendingAdjustment(String itemId, int delta) {
    final Map<String, int> map = Map<String, int>.from(state.pendingAdjustments);
    if (delta == 0) {
      map.remove(itemId);
    } else {
      map[itemId] = delta;
    }
    state = state.copyWith(pendingAdjustments: map);
  }

  /// 調整を適用してサービスに反映する。
  void applyAdjustment(String itemId) => unawaited(_applyAdjustment(itemId));

  Future<void> _applyAdjustment(String itemId) async {
    final int? delta = state.pendingAdjustments[itemId];
    if (delta == null || delta == 0) {
      return;
    }

    if (!canApply(itemId)) {
      state = state.copyWith(errorMessage: "適用できない調整があります。数量を確認してください。");
      return;
    }

    InventoryItemViewData? target;
    for (final InventoryItemViewData item in state.items) {
      if (item.id == itemId) {
        target = item;
        break;
      }
    }

    if (target == null) {
      return;
    }

    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = state.copyWith(errorMessage: "ユーザー情報を取得できませんでした。再度ログインしてください。");
      return;
    }

    final InventoryItemViewData currentItem = target;
    final double newQuantity = (currentItem.current + delta).clamp(0, double.infinity);

    try {
      state = state.copyWith(clearErrorMessage: true);
      await _inventoryService.updateMaterialStock(
        StockUpdateRequest(
          materialId: itemId,
          newQuantity: newQuantity,
          reason: "UI adjustment",
          notes: delta > 0 ? "+$delta" : delta.toString(),
        ),
        userId,
      );

      final List<InventoryItemViewData> updatedItems = state.items
          .map(
            (InventoryItemViewData item) => item.id == itemId
                ? item.copyWith(current: newQuantity, updatedAt: DateTime.now(), updatedBy: userId)
                : item,
          )
          .toList(growable: false);

      final Map<String, int> pending = Map<String, int>.from(state.pendingAdjustments)
        ..remove(itemId);
      final Set<String> selectedIds = Set<String>.from(state.selectedIds)..remove(itemId);
      final Map<String, Material> materials = Map<String, Material>.from(state.materialById);
      final Material? existingMaterial = materials[itemId];
      if (existingMaterial != null) {
        materials[itemId] = Material(
          id: existingMaterial.id,
          name: existingMaterial.name,
          categoryId: existingMaterial.categoryId,
          unitType: existingMaterial.unitType,
          currentStock: newQuantity,
          alertThreshold: existingMaterial.alertThreshold,
          criticalThreshold: existingMaterial.criticalThreshold,
          notes: existingMaterial.notes,
          createdAt: existingMaterial.createdAt,
          updatedAt: DateTime.now(),
          userId: userId,
        );
      }

      state = state.copyWith(
        items: updatedItems,
        pendingAdjustments: pending,
        selectedIds: selectedIds,
        materialById: Map<String, Material>.unmodifiable(materials),
        clearErrorMessage: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
    }
  }

  void toggleSelect(String itemId) {
    final Set<String> s = Set<String>.from(state.selectedIds);
    if (s.contains(itemId)) {
      s.remove(itemId);
    } else {
      s.add(itemId);
    }
    state = state.copyWith(selectedIds: s);
  }

  /// 全選択/解除。
  void selectAll(bool selected) {
    if (selected) {
      state = state.copyWith(
        selectedIds: state.filteredItems.map((InventoryItemViewData e) => e.id).toSet(),
      );
    } else {
      state = state.copyWith(selectedIds: <String>{});
    }
  }

  /// 簡易バリデーション: 新在庫が0未満になる行は適用不可（戻り値: 適用できるか）。
  bool canApply(String itemId) {
    final int delta = state.pendingAdjustments[itemId] ?? 0;
    final InventoryItemViewData item = state.items.firstWhere(
      (InventoryItemViewData x) => x.id == itemId,
      orElse: () => InventoryItemViewData(
        id: "__invalid__",
        name: "",
        categoryId: "",
        category: "",
        current: 0,
        unitType: UnitType.piece,
        unit: "",
        alertThreshold: 0,
        criticalThreshold: 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedBy: "",
      ),
    );
    if (item.id == "__invalid__") {
      return false;
    }
    final double after = item.current + delta;
    return after >= 0;
  }

  /// 選択行に対して一括適用（負在庫になる行はスキップ）。
  void applySelected() => unawaited(_applySelected());

  Future<void> _applySelected() async {
    final List<String> ids = state.selectedIds.toList(growable: false);
    for (final String id in ids) {
      if (!canApply(id)) {
        continue;
      }
      await _applyAdjustment(id);
    }
    state = state.copyWith(selectedIds: <String>{});
  }

  /// フィルタ後の全件に対して一括適用（負在庫になる行はスキップ）。
  void applyAllVisible() => unawaited(_applyAllVisible());

  Future<void> _applyAllVisible() async {
    final List<InventoryItemViewData> visibleItems = state.filteredItems;
    for (final InventoryItemViewData item in visibleItems) {
      if (!canApply(item.id)) {
        continue;
      }
      await _applyAdjustment(item.id);
    }
    state = state.copyWith(selectedIds: <String>{});
  }

  /// 選択解除。
  void clearSelection() => state = state.copyWith(selectedIds: <String>{});

  /// 全件に対する未適用の調整をクリア。
  void clearAllAdjustments() => state = state.copyWith(pendingAdjustments: <String, int>{});

  // * 以下は選択行向けの一括操作API（UIの選択ツールバーから利用）

  /// 選択されている行すべての未適用差分に対して、[amount] を加算する。
  /// 例: +5 なら各行の差分に +5、-3 なら -3 を加算。
  void incrementSelectedBy(int amount) {
    if (amount == 0 || state.selectedIds.isEmpty) {
      return;
    }
    final Map<String, int> map = Map<String, int>.from(state.pendingAdjustments);
    for (final String id in state.selectedIds) {
      final int current = map[id] ?? 0;
      map[id] = current + amount;
    }
    state = state.copyWith(pendingAdjustments: map);
  }

  /// 選択行の未適用差分をクリア（0に）する。
  void clearAdjustmentsForSelected() {
    if (state.selectedIds.isEmpty) {
      return;
    }
    final Map<String, int> map = Map<String, int>.from(state.pendingAdjustments);
    for (final String id in state.selectedIds) {
      map.remove(id);
    }
    state = state.copyWith(pendingAdjustments: map);
  }

  /// 選択されている行を削除（モック実装）。
  /// 実サービス接続後は Service -> Repository 経由に置換する。
  void deleteSelected() {
    if (state.selectedIds.isEmpty) {
      return;
    }
    final Set<String> toDelete = state.selectedIds;
    final List<InventoryItemViewData> remaining = state.items
        .where((InventoryItemViewData i) => !toDelete.contains(i.id))
        .toList(growable: false);
    final Map<String, int> pending = Map<String, int>.from(state.pendingAdjustments)
      ..removeWhere((String key, _) => toDelete.contains(key));
    final Map<String, Material> materials = Map<String, Material>.from(state.materialById)
      ..removeWhere((String key, _) => toDelete.contains(key));
    state = state.copyWith(
      items: remaining,
      pendingAdjustments: pending,
      selectedIds: <String>{},
      materialById: Map<String, Material>.unmodifiable(materials),
    );
    // TODO サービスレイヤー統合: まとめて削除APIに接続する
  }
}

final StateNotifierProvider<InventoryManagementController, InventoryManagementState>
inventoryManagementControllerProvider =
    StateNotifierProvider<InventoryManagementController, InventoryManagementState>(
      (Ref ref) => InventoryManagementController(
        ref: ref,
        inventoryService: ref.read(inventoryServiceProvider),
      ),
    );

/// ソートキー。
enum InventorySortBy { none, category, state, quantity, delta, updatedAt }

/// カテゴリ名を比較して50音順・アルファベット順での昇順/降順ソートを実現する。
int _compareCategoryName(String a, String b) {
  final String left = _normalizeForSort(a);
  final String right = _normalizeForSort(b);
  final int primary = left.compareTo(right);
  if (primary != 0) {
    return primary;
  }
  return a.compareTo(b);
}

/// 50音・アルファベットの比較を行いやすいように文字列を正規化する。
String _normalizeForSort(String input) {
  final String trimmed = input.trim();
  if (trimmed.isEmpty) {
    return "";
  }

  final StringBuffer buffer = StringBuffer();
  for (final int rune in trimmed.runes) {
    // カタカナ -> ひらがな
    if (rune >= 0x30A1 && rune <= 0x30F3) {
      buffer.writeCharCode(rune - 0x60);
      continue;
    }

    // 半角カタカナをひらがなに寄せる
    final int? halfWidth = _halfWidthKatakanaToHiragana[rune];
    if (halfWidth != null) {
      buffer.writeCharCode(halfWidth);
      continue;
    }

    // 全角英数字 -> 半角英数字
    if ((rune >= 0xFF10 && rune <= 0xFF19) ||
        (rune >= 0xFF21 && rune <= 0xFF3A) ||
        (rune >= 0xFF41 && rune <= 0xFF5A)) {
      buffer.writeCharCode(rune - 0xFEE0);
      continue;
    }

    buffer.writeCharCode(rune);
  }

  return buffer.toString().toLowerCase();
}

/// 半角カタカナ -> ひらがな変換マップ。
const Map<int, int> _halfWidthKatakanaToHiragana = <int, int>{
  0xFF66: 0x3092, // ｦ -> を
  0xFF67: 0x3041, // ｧ -> ぁ
  0xFF68: 0x3043, // ｨ -> ぃ
  0xFF69: 0x3045, // ｩ -> ぅ
  0xFF6A: 0x3047, // ｪ -> ぇ
  0xFF6B: 0x3049, // ｫ -> ぉ
  0xFF6C: 0x3083, // ｬ -> ゃ
  0xFF6D: 0x3085, // ｭ -> ゅ
  0xFF6E: 0x3087, // ｮ -> ょ
  0xFF6F: 0x3063, // ｯ -> っ
  0xFF70: 0x30FC, // ｰ -> ー
  0xFF71: 0x3042, // ｱ -> あ
  0xFF72: 0x3044, // ｲ -> い
  0xFF73: 0x3046, // ｳ -> う
  0xFF74: 0x3048, // ｴ -> え
  0xFF75: 0x304A, // ｵ -> お
  0xFF76: 0x304B, // ｶ -> か
  0xFF77: 0x304D, // ｷ -> き
  0xFF78: 0x304F, // ｸ -> く
  0xFF79: 0x3051, // ｹ -> け
  0xFF7A: 0x3053, // ｺ -> こ
  0xFF7B: 0x3055, // ｻ -> さ
  0xFF7C: 0x3057, // ｼ -> し
  0xFF7D: 0x3059, // ｽ -> す
  0xFF7E: 0x305B, // ｾ -> せ
  0xFF7F: 0x305D, // ｿ -> そ
  0xFF80: 0x305F, // ﾀ -> た
  0xFF81: 0x3061, // ﾁ -> ち
  0xFF82: 0x3064, // ﾂ -> つ
  0xFF83: 0x3066, // ﾃ -> て
  0xFF84: 0x3068, // ﾄ -> と
  0xFF85: 0x306A, // ﾅ -> な
  0xFF86: 0x306B, // ﾆ -> に
  0xFF87: 0x306C, // ﾇ -> ぬ
  0xFF88: 0x306D, // ﾈ -> ね
  0xFF89: 0x306E, // ﾉ -> の
  0xFF8A: 0x306F, // ﾊ -> は
  0xFF8B: 0x3072, // ﾋ -> ひ
  0xFF8C: 0x3075, // ﾌ -> ふ
  0xFF8D: 0x3078, // ﾍ -> へ
  0xFF8E: 0x307B, // ﾎ -> ほ
  0xFF8F: 0x307E, // ﾏ -> ま
  0xFF90: 0x307F, // ﾐ -> み
  0xFF91: 0x3080, // ﾑ -> む
  0xFF92: 0x3081, // ﾒ -> め
  0xFF93: 0x3082, // ﾓ -> も
  0xFF94: 0x3084, // ﾔ -> や
  0xFF95: 0x3086, // ﾕ -> ゆ
  0xFF96: 0x3088, // ﾖ -> よ
  0xFF97: 0x3089, // ﾗ -> ら
  0xFF98: 0x308A, // ﾘ -> り
  0xFF99: 0x308B, // ﾙ -> る
  0xFF9A: 0x308C, // ﾚ -> れ
  0xFF9B: 0x308D, // ﾛ -> ろ
  0xFF9C: 0x308F, // ﾜ -> わ
  0xFF9D: 0x3093, // ﾝ -> ん
  0xFF9E: 0x309B, // ﾞ -> ゛
  0xFF9F: 0x309C, // ﾟ -> ゜
};
