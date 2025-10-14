import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/utils/error_handler.dart";
import "../../../../shared/search/search_utils.dart";
import "../../../../shared/utils/unit_config.dart";
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
    required this.current, required this.unitType, required this.unit, required this.alertThreshold, required this.criticalThreshold, required this.updatedAt, required this.updatedBy, required this.searchIndex, this.categoryCode,
    this.notes,
  });

  final String id;
  final String name;
  final String categoryId;
  final String category;
  final String? categoryCode;
  final double current;
  final UnitType unitType;
  final String unit;
  final double alertThreshold;
  final double criticalThreshold;
  final DateTime updatedAt;
  final String updatedBy;
  final String? notes;
  final String searchIndex;

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
    String? categoryCode,
    double? current,
    UnitType? unitType,
    String? unit,
    double? alertThreshold,
    double? criticalThreshold,
    DateTime? updatedAt,
    String? updatedBy,
    String? notes,
    String? searchIndex,
  }) {
    final String resolvedName = name ?? this.name;
    final String resolvedCategory = category ?? this.category;
    final String? resolvedCategoryCode = categoryCode ?? this.categoryCode;
    return InventoryItemViewData(
      id: id ?? this.id,
      name: resolvedName,
      categoryId: categoryId ?? this.categoryId,
      category: resolvedCategory,
      categoryCode: resolvedCategoryCode,
      current: current ?? this.current,
      unitType: unitType ?? this.unitType,
      unit: unit ?? this.unit,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      notes: notes ?? this.notes,
      searchIndex: searchIndex ??
          InventoryItemViewData.composeSearchIndex(
            name: resolvedName,
            categoryName: resolvedCategory,
            categoryCode: resolvedCategoryCode,
          ),
    );
  }

  static String composeSearchIndex({
    required String name,
    required String categoryName,
    String? categoryCode,
  }) {
    final SearchIndexBuilder builder = SearchIndexBuilder()
      ..add(name)
      ..add(categoryName)
      ..add(categoryCode);
    return builder.build();
  }
}

/// テーブル表示用のステータスバッジ種別。
enum InventoryRowBadgeType { success, warning, danger, info, neutral }

/// テーブル表示用のステータスバッジ情報。
class InventoryRowBadgeViewData {
  const InventoryRowBadgeViewData({required this.label, required this.type});

  final String label;
  final InventoryRowBadgeType type;
}

/// 行ごとに必要なフォーマット済みデータ。
class InventoryRowViewData {
  const InventoryRowViewData({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.quantityLabel,
    required this.quantityValueLabel,
    required this.unitLabel,
    required this.thresholdsLabel,
    required this.badges,
    required this.memo,
    required this.memoTooltip,
    required this.hasMemo,
    required this.deltaLabel,
    required this.afterChangeLabel,
    required this.deltaTrend,
    required this.pendingDelta,
    required this.updatedAtLabel,
    required this.updatedTooltip,
    required this.hasPendingDelta,
    required this.canApplyByRule,
    required this.isBusy,
    required this.status,
    this.errorMessage,
  });

  final String id;
  final String name;
  final String categoryName;
  final String quantityLabel;
  final String quantityValueLabel;
  final String unitLabel;
  final String thresholdsLabel;
  final List<InventoryRowBadgeViewData> badges;
  final String memo;
  final String? memoTooltip;
  final bool hasMemo;
  final String deltaLabel;
  final String afterChangeLabel;
  final InventoryDeltaTrend deltaTrend;
  final int pendingDelta;
  final String updatedAtLabel;
  final String updatedTooltip;
  final bool hasPendingDelta;
  final bool canApplyByRule;
  final bool isBusy;
  final StockStatus status;
  final String? errorMessage;
}

/// 差分トレンド。
enum InventoryDeltaTrend { increase, decrease, none }

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
    this.busyItemIds = const <String>{},
    this.rowErrors = const <String, String>{},
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
  final Set<String> busyItemIds;
  final Map<String, String> rowErrors;
  final bool isLoading;
  final String? errorMessage;

  List<InventoryItemViewData> get filteredItems {
    final List<String> searchTokens = tokenizeSearchQuery(searchText);
    final String? category = selectedCategoryIndex == 0 ? null : categories[selectedCategoryIndex];

    bool hasMemo(InventoryItemViewData data) {
      final String? notes = data.notes;
      if (notes == null) {
        return false;
      }
      return notes.trim().isNotEmpty;
    }

    List<InventoryItemViewData> list = items
        .where((InventoryItemViewData i) {
          final bool q = searchTokens.isEmpty || matchesSearchTokens(i.searchIndex, searchTokens);
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
      case InventorySortBy.name:
        list.sort(
          (InventoryItemViewData a, InventoryItemViewData b) =>
              _compareItemName(a.name, b.name),
        );
        break;
      case InventorySortBy.memo:
        list.sort((InventoryItemViewData a, InventoryItemViewData b) {
          final bool aHasMemo = hasMemo(a);
          final bool bHasMemo = hasMemo(b);
          if (aHasMemo == bHasMemo) {
            return _compareItemName(a.name, b.name);
          }
          return aHasMemo ? 1 : -1;
        });
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
    Set<String>? busyItemIds,
    Map<String, String>? rowErrors,
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
    busyItemIds: busyItemIds ?? this.busyItemIds,
    rowErrors: rowErrors ?? this.rowErrors,
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
  static final DateFormat _rowDateFormat = DateFormat("MM/dd HH:mm");
  static final DateFormat _rowTooltipFormat = DateFormat("yyyy/MM/dd HH:mm");

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
      String? normalizeCategoryCode(String? value) {
        if (value == null) {
          return null;
        }
        final String trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
      final Map<String, String?> categoryCodeById = <String, String?>{
        for (final MaterialCategory category in categoryModels)
          if (category.id != null) category.id!: normalizeCategoryCode(category.code),
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
            final String? categoryCode = categoryCodeById[material.categoryId];

            final DateTime updatedAt = material.updatedAt ?? material.createdAt ?? DateTime.now();

            return InventoryItemViewData(
              id: id,
              name: material.name,
              categoryId: material.categoryId,
              category: categoryName,
              categoryCode: categoryCode,
              current: material.currentStock,
              unitType: material.unitType,
              unit: material.unitType.symbol,
              alertThreshold: material.alertThreshold,
              criticalThreshold: material.criticalThreshold,
              updatedAt: updatedAt,
              updatedBy: material.userId ?? "system",
              notes: material.notes,
              searchIndex: InventoryItemViewData.composeSearchIndex(
                name: material.name,
                categoryName: categoryName,
                categoryCode: categoryCode,
              ),
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

      state = state.copyWith(
        items: items,
        categories: categories,
        categoryEntities: List<MaterialCategory>.unmodifiable(categoryModels),
        materialById: Map<String, Material>.unmodifiable(materialMap),
        selectedCategoryIndex: resolvedCategoryIndex,
        pendingAdjustments: pending,
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
        MaterialCategory(name: trimmedName, displayOrder: nextDisplayOrder),
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

  /// ステータスフィルターを直接設定。
  void setStatusFilter(StockStatus? status) {
    state = state.copyWith(selectedStatusFilter: status, selectedStatusFilterSet: true);
  }

  /// ソートキーの変更。既に同じキーなら昇順/降順をトグル、違うキーなら昇順に設定。
  void sortBy(InventorySortBy key) {
    if (state.sortBy == key) {
      state = state.copyWith(sortAsc: !state.sortAsc);
    } else {
      state = state.copyWith(sortBy: key, sortAsc: true);
    }
  }

  /// サマリー列のソートサイクル (カテゴリのみ)。
  void cycleSummarySort() {
    if (state.sortBy != InventorySortBy.category) {
      state = state.copyWith(sortBy: InventorySortBy.category, sortAsc: true);
      return;
    }
    if (state.sortAsc) {
      state = state.copyWith(sortAsc: false);
      return;
    }
    state = state.copyWith(sortBy: InventorySortBy.none);
  }

  /// 在庫名列のソートサイクル。
  void cycleNameSort() {
    if (state.sortBy != InventorySortBy.name) {
      state = state.copyWith(sortBy: InventorySortBy.name, sortAsc: true);
      return;
    }
    if (state.sortAsc) {
      state = state.copyWith(sortAsc: false);
      return;
    }
    state = state.copyWith(sortBy: InventorySortBy.none);
  }

  /// メモ列のソートサイクル (メモ有無)。
  void cycleMemoSort() {
    if (state.sortBy != InventorySortBy.memo) {
      state = state.copyWith(sortBy: InventorySortBy.memo, sortAsc: true);
      return;
    }
    if (state.sortAsc) {
      state = state.copyWith(sortAsc: false);
      return;
    }
    state = state.copyWith(sortBy: InventorySortBy.none);
  }

  /// ステータス/数量列のソートサイクル。
  void cycleMetricsSort() {
    const List<InventorySortBy> order = <InventorySortBy>[
      InventorySortBy.state,
      InventorySortBy.quantity,
    ];
    final int currentIndex = order.indexOf(state.sortBy);
    if (currentIndex == -1) {
      state = state.copyWith(sortBy: order.first, sortAsc: true);
      return;
    }
    if (state.sortAsc) {
      state = state.copyWith(sortAsc: false);
      return;
    }
    if (currentIndex == order.length - 1) {
      state = state.copyWith(sortBy: InventorySortBy.none);
      return;
    }
    state = state.copyWith(sortBy: order[currentIndex + 1], sortAsc: true);
  }

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

  /// テーブル表示用の行データを生成する。
  List<InventoryRowViewData> buildRowViewData() =>
      state.filteredItems.map(_composeRowViewData).toList(growable: false);

  InventoryRowViewData _composeRowViewData(InventoryItemViewData item) {
    final int pendingDelta = state.pendingAdjustments[item.id] ?? 0;
    final double adjustedQuantity = (item.current + pendingDelta).clamp(0, double.infinity);
    final UnitType unitType = item.unitType;
    final String unitLabel = item.unit;
    final String quantityValueLabel = UnitFormatter.format(item.current, unitType);
    final String quantityLabel = "$quantityValueLabel $unitLabel";
    final String thresholdsLabel =
        "警告 ${UnitFormatter.format(item.alertThreshold, unitType)} / 危険 ${UnitFormatter.format(item.criticalThreshold, unitType)} $unitLabel";

    final List<InventoryRowBadgeViewData> badges = _resolveBadges(item.status, pendingDelta);
    final String? memo = _resolveMemo(item.notes);
    final bool hasMemo = memo != null;
    final String memoLabel = memo ?? "メモ未登録";

    final InventoryDeltaTrend deltaTrend;
    final String deltaLabel;
    if (pendingDelta > 0) {
      deltaTrend = InventoryDeltaTrend.increase;
      deltaLabel = "+$pendingDelta";
    } else if (pendingDelta < 0) {
      deltaTrend = InventoryDeltaTrend.decrease;
      deltaLabel = pendingDelta.toString();
    } else {
      deltaTrend = InventoryDeltaTrend.none;
      deltaLabel = "±0";
    }

    final String afterChangeLabel =
        "→ ${UnitFormatter.format(adjustedQuantity, unitType)} $unitLabel";
    final DateTime localUpdatedAt = item.updatedAt.toLocal();
    final String updatedAtLabel = _rowDateFormat.format(localUpdatedAt);
    final String updatedTooltip =
        "最終更新: ${_rowTooltipFormat.format(localUpdatedAt)}";

    final bool hasPendingDelta = pendingDelta != 0;
    final bool canApplyByRule = hasPendingDelta && canApply(item.id);
    final bool isBusy = state.busyItemIds.contains(item.id);
    final String? errorMessage = state.rowErrors[item.id];

    return InventoryRowViewData(
      id: item.id,
      name: item.name,
      categoryName: item.category,
      quantityLabel: quantityLabel,
      quantityValueLabel: quantityValueLabel,
      unitLabel: unitLabel,
      thresholdsLabel: thresholdsLabel,
      badges: badges,
      memo: memoLabel,
      memoTooltip: memo,
      hasMemo: hasMemo,
      deltaLabel: deltaLabel,
      afterChangeLabel: afterChangeLabel,
      deltaTrend: deltaTrend,
      pendingDelta: pendingDelta,
      updatedAtLabel: updatedAtLabel,
      updatedTooltip: updatedTooltip,
      hasPendingDelta: hasPendingDelta,
      canApplyByRule: canApplyByRule,
      isBusy: isBusy,
      status: item.status,
      errorMessage: errorMessage,
    );
  }

  List<InventoryRowBadgeViewData> _resolveBadges(StockStatus status, int pendingDelta) {
    final List<InventoryRowBadgeViewData> badges = <InventoryRowBadgeViewData>[
      _statusToBadge(status),
    ];
    if (pendingDelta != 0) {
      final String deltaLabel = pendingDelta > 0 ? "+$pendingDelta" : pendingDelta.toString();
      badges.add(
        InventoryRowBadgeViewData(label: "未適用 $deltaLabel", type: InventoryRowBadgeType.info),
      );
    }
    return badges;
  }

  InventoryRowBadgeViewData _statusToBadge(StockStatus status) {
    switch (status) {
      case StockStatus.sufficient:
        return const InventoryRowBadgeViewData(label: "適切", type: InventoryRowBadgeType.success);
      case StockStatus.low:
        return const InventoryRowBadgeViewData(label: "注意", type: InventoryRowBadgeType.warning);
      case StockStatus.critical:
        return const InventoryRowBadgeViewData(label: "危険", type: InventoryRowBadgeType.danger);
    }
  }

  String? _resolveMemo(String? notes) {
    if (notes == null) {
      return null;
    }
    final String trimmed = notes.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
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

    final Set<String> busyItems = Set<String>.from(state.busyItemIds)..add(itemId);
    final Map<String, String> rowErrors = Map<String, String>.from(state.rowErrors)..remove(itemId);
    state = state.copyWith(
      busyItemIds: Set<String>.unmodifiable(busyItems),
      rowErrors: Map<String, String>.unmodifiable(rowErrors),
      clearErrorMessage: true,
    );

    try {
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

      final Set<String> busyAfter = Set<String>.from(state.busyItemIds)..remove(itemId);
      final Map<String, String> rowErrorsAfter = Map<String, String>.from(state.rowErrors)
        ..remove(itemId);

      state = state.copyWith(
        items: updatedItems,
        pendingAdjustments: pending,
        materialById: Map<String, Material>.unmodifiable(materials),
        busyItemIds: Set<String>.unmodifiable(busyAfter),
        rowErrors: Map<String, String>.unmodifiable(rowErrorsAfter),
        clearErrorMessage: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      final Set<String> busyAfter = Set<String>.from(state.busyItemIds)..remove(itemId);
      final Map<String, String> rowErrorsAfter = Map<String, String>.from(state.rowErrors)
        ..[itemId] = message;
      state = state.copyWith(
        errorMessage: message,
        busyItemIds: Set<String>.unmodifiable(busyAfter),
        rowErrors: Map<String, String>.unmodifiable(rowErrorsAfter),
      );
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
        searchIndex: "",
      ),
    );
    if (item.id == "__invalid__") {
      return false;
    }
    final double after = item.current + delta;
    return after >= 0;
  }

  /// 全件に対する未適用の調整をクリア。
  void clearAllAdjustments() => state = state.copyWith(pendingAdjustments: <String, int>{});
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
enum InventorySortBy { none, category, name, memo, state, quantity, delta, updatedAt }

/// カテゴリ名を比較して50音順・アルファベット順での昇順/降順ソートを実現する。
int _compareCategoryName(String a, String b) {
  final String left = SearchNormalizer.normalizeForSort(a);
  final String right = SearchNormalizer.normalizeForSort(b);
  final int primary = left.compareTo(right);
  if (primary != 0) {
    return primary;
  }
  return a.compareTo(b);
}

int _compareItemName(String a, String b) {
  final String left = SearchNormalizer.normalizeForSort(a);
  final String right = SearchNormalizer.normalizeForSort(b);
  final int primary = left.compareTo(right);
  if (primary != 0) {
    return primary;
  }
  return a.compareTo(b);
}
