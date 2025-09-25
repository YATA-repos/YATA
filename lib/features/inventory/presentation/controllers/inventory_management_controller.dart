import "package:flutter_riverpod/flutter_riverpod.dart";

/// 在庫ステータス。
enum StockStatus { sufficient, low, critical }

/// 在庫アイテムの表示用データ。
class InventoryItemViewData {
  const InventoryItemViewData({
    required this.id,
    required this.name,
    required this.category,
    required this.current,
    required this.unit,
    required this.alertThreshold,
    required this.criticalThreshold,
    required this.updatedAt,
    required this.updatedBy,
  });

  final String id;
  final String name;
  final String category;
  final double current;
  final String unit;
  final double alertThreshold;
  final double criticalThreshold;
  final DateTime updatedAt;
  final String updatedBy;

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
    String? category,
    double? current,
    String? unit,
    double? alertThreshold,
    double? criticalThreshold,
    DateTime? updatedAt,
    String? updatedBy,
  }) => InventoryItemViewData(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    current: current ?? this.current,
    unit: unit ?? this.unit,
    alertThreshold: alertThreshold ?? this.alertThreshold,
    criticalThreshold: criticalThreshold ?? this.criticalThreshold,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
  );
}

/// 画面状態。
class InventoryManagementState {
  const InventoryManagementState({
    required this.items,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.selectedStatusFilter, // null=全て、sufficient/low/critical
    required this.searchText,
    required this.pendingAdjustments,
    required this.sortBy,
    required this.sortAsc,
    required this.selectedIds,
  });

  // コンストラクタは他メンバより前に配置（lint: sort_constructors_first対応）
  factory InventoryManagementState.initial() {
    final DateTime now = DateTime.now();
    final List<InventoryItemViewData> seed = <InventoryItemViewData>[
      InventoryItemViewData(
        id: "m-001",
        name: "玉ねぎ",
        category: "野菜",
        current: 42,
        unit: "個",
        alertThreshold: 30,
        criticalThreshold: 10,
        updatedAt: now.subtract(const Duration(hours: 2)),
        updatedBy: "system",
      ),
      InventoryItemViewData(
        id: "m-002",
        name: "牛肩ロース",
        category: "肉",
        current: 8,
        unit: "kg",
        alertThreshold: 10,
        criticalThreshold: 5,
        updatedAt: now.subtract(const Duration(days: 1, hours: 3)),
        updatedBy: "tanaka",
      ),
      InventoryItemViewData(
        id: "m-003",
        name: "醤油",
        category: "調味料",
        current: 2,
        unit: "L",
        alertThreshold: 3,
        criticalThreshold: 1,
        updatedAt: now.subtract(const Duration(minutes: 30)),
        updatedBy: "suzuki",
      ),
      InventoryItemViewData(
        id: "m-004",
        name: "キャベツ",
        category: "野菜",
        current: 16,
        unit: "玉",
        alertThreshold: 12,
        criticalThreshold: 6,
        updatedAt: now.subtract(const Duration(days: 2)),
        updatedBy: "system",
      ),
      InventoryItemViewData(
        id: "m-005",
        name: "中華麺",
        category: "主食",
        current: 110,
        unit: "玉",
        alertThreshold: 80,
        criticalThreshold: 40,
        updatedAt: now.subtract(const Duration(hours: 12)),
        updatedBy: "yamada",
      ),
    ];

    final Set<String> cats = <String>{for (final InventoryItemViewData i in seed) i.category};
    final List<String> categoryList = <String>["すべて", ...cats];
    return InventoryManagementState(
      items: seed,
      categories: categoryList,
      selectedCategoryIndex: 0,
      selectedStatusFilter: null,
      searchText: "",
      pendingAdjustments: <String, int>{},
      sortBy: InventorySortBy.none,
      sortAsc: true,
      selectedIds: <String>{},
    );
  }

  final List<InventoryItemViewData> items;
  final List<String> categories; // 先頭は "すべて"
  final int selectedCategoryIndex;
  final StockStatus? selectedStatusFilter;
  final String searchText;
  final Map<String, int> pendingAdjustments; // itemId -> delta
  final InventorySortBy sortBy;
  final bool sortAsc;
  final Set<String> selectedIds;

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
    int? selectedCategoryIndex,
    StockStatus? selectedStatusFilter,
    bool selectedStatusFilterSet = false,
    String? searchText,
    Map<String, int>? pendingAdjustments,
    InventorySortBy? sortBy,
    bool? sortAsc,
    Set<String>? selectedIds,
  }) => InventoryManagementState(
    items: items ?? this.items,
    categories: categories ?? this.categories,
    selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
    selectedStatusFilter: selectedStatusFilterSet
        ? selectedStatusFilter
        : this.selectedStatusFilter,
    searchText: searchText ?? this.searchText,
    pendingAdjustments: pendingAdjustments ?? this.pendingAdjustments,
    sortBy: sortBy ?? this.sortBy,
    sortAsc: sortAsc ?? this.sortAsc,
    selectedIds: selectedIds ?? this.selectedIds,
  );
}

/// 在庫管理画面のコントローラ。
class InventoryManagementController extends StateNotifier<InventoryManagementState> {
  InventoryManagementController() : super(InventoryManagementState.initial());

  void setSearchText(String value) => state = state.copyWith(searchText: value);

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

  /// 調整を適用（モック）。実際はサービスに委譲予定。
  void applyAdjustment(String itemId) {
    final int? delta = state.pendingAdjustments[itemId];
    if (delta == null || delta == 0) {
      return;
    }

    final DateTime now = DateTime.now();
    final List<InventoryItemViewData> updated = state.items
        .map((InventoryItemViewData i) {
          if (i.id != itemId) return i;
          final double next = (i.current + delta).clamp(0, double.infinity);
          return i.copyWith(current: next, updatedAt: now, updatedBy: "current_user");
        })
        .toList(growable: false);

    final Map<String, int> map = Map<String, int>.from(state.pendingAdjustments)..remove(itemId);
    state = state.copyWith(items: updated, pendingAdjustments: map);
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
      state = state.copyWith(selectedIds: state.filteredItems.map((InventoryItemViewData e) => e.id).toSet());
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
        category: "",
        current: 0,
        unit: "",
        alertThreshold: 0,
        criticalThreshold: 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedBy: "",
      ),
    );
    if (item.id == "__invalid__") return false;
    final double after = item.current + delta;
    return after >= 0;
  }

  /// 選択行に対して一括適用（負在庫になる行はスキップ）。
  void applySelected() {
    final Set<String> ids = state.selectedIds;
    for (final String id in ids) {
      if (!canApply(id)) continue;
      applyAdjustment(id);
    }
    state = state.copyWith(selectedIds: <String>{});
  }

  /// フィルタ後の全件に対して一括適用（負在庫になる行はスキップ）。
  void applyAllVisible() {
    for (final InventoryItemViewData i in state.filteredItems) {
      if (!canApply(i.id)) continue;
      applyAdjustment(i.id);
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
    if (amount == 0 || state.selectedIds.isEmpty) return;
    final Map<String, int> map = Map<String, int>.from(state.pendingAdjustments);
    for (final String id in state.selectedIds) {
      final int current = map[id] ?? 0;
      map[id] = current + amount;
    }
    state = state.copyWith(pendingAdjustments: map);
  }

  /// 選択行の未適用差分をクリア（0に）する。
  void clearAdjustmentsForSelected() {
    if (state.selectedIds.isEmpty) return;
    final Map<String, int> map = Map<String, int>.from(state.pendingAdjustments);
    for (final String id in state.selectedIds) {
      map.remove(id);
    }
    state = state.copyWith(pendingAdjustments: map);
  }

  /// 選択されている行を削除（モック実装）。
  /// 実サービス接続後は Service -> Repository 経由に置換する。
  void deleteSelected() {
    if (state.selectedIds.isEmpty) return;
    final Set<String> toDelete = state.selectedIds;
    final List<InventoryItemViewData> remaining = state.items
        .where((InventoryItemViewData i) => !toDelete.contains(i.id))
        .toList(growable: false);
    final Map<String, int> pending = Map<String, int>.from(state.pendingAdjustments)
      ..removeWhere((String key, _) => toDelete.contains(key));
    state = state.copyWith(
      items: remaining,
      pendingAdjustments: pending,
      selectedIds: <String>{},
    );
    // TODO サービスレイヤー統合: まとめて削除APIに接続する
  }
}

final StateNotifierProvider<InventoryManagementController, InventoryManagementState>
inventoryManagementControllerProvider =
    StateNotifierProvider<InventoryManagementController, InventoryManagementState>(
      (Ref ref) => InventoryManagementController(),
    );

/// ソートキー。
enum InventorySortBy { none, state, quantity, delta, updatedAt }
