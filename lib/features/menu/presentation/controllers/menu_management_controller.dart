import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/logging/compat.dart" as log;
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../dto/menu_dto.dart";
import "../../models/menu_model.dart";
import "../../services/menu_service.dart";

const String _logTag = "MenuManagementController";

/// 在庫可用性の状態を表す列挙体。
enum MenuAvailabilityStatus { idle, loading, available, unavailable, error }

/// メニューアイテムの在庫可用性をUI向けに保持するViewModel。
class MenuAvailabilityViewData {
  /// [MenuAvailabilityViewData]を生成する。
  const MenuAvailabilityViewData({
    required this.status,
    this.info,
    this.errorMessage,
    this.updatedAt,
  });

  /// 未取得状態を示すインスタンスを生成する。
  const MenuAvailabilityViewData.idle() : this(status: MenuAvailabilityStatus.idle);

  /// ローディング状態を示すインスタンスを生成する。
  const MenuAvailabilityViewData.loading()
    : this(status: MenuAvailabilityStatus.loading, updatedAt: null);

  /// 在庫可用性情報からViewDataを生成する。
  factory MenuAvailabilityViewData.fromInfo(MenuAvailabilityInfo info) => MenuAvailabilityViewData(
    status: info.isAvailable
        ? MenuAvailabilityStatus.available
        : MenuAvailabilityStatus.unavailable,
    info: info,
    updatedAt: DateTime.now(),
  );

  /// 取得失敗状態を生成する。
  factory MenuAvailabilityViewData.failure(String message) => MenuAvailabilityViewData(
    status: MenuAvailabilityStatus.error,
    errorMessage: message,
    updatedAt: DateTime.now(),
  );

  /// 表示用ステータス。
  final MenuAvailabilityStatus status;

  /// 取得した在庫情報。
  final MenuAvailabilityInfo? info;

  /// エラーメッセージ。
  final String? errorMessage;

  /// 最終更新日時。
  final DateTime? updatedAt;

  /// 在庫が利用可能かどうかを返す。
  bool get isAvailable =>
      status == MenuAvailabilityStatus.available && (info?.isAvailable ?? false);

  /// 情報を更新したコピーを返す。
  MenuAvailabilityViewData copyWith({
    MenuAvailabilityStatus? status,
    MenuAvailabilityInfo? info,
    bool clearInfo = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    DateTime? updatedAt,
  }) => MenuAvailabilityViewData(
    status: status ?? this.status,
    info: clearInfo ? null : (info ?? this.info),
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// メニューカテゴリの表示用データ。
class MenuCategoryViewData {
  /// [MenuCategoryViewData]を生成する。
  const MenuCategoryViewData({
    required this.id,
    required this.name,
    required this.displayOrder,
    this.itemCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// カテゴリID。
  final String id;

  /// カテゴリ名。
  final String name;

  /// 表示順。
  final int displayOrder;

  /// カテゴリに紐づくアイテム数。
  final int itemCount;

  /// 作成日時。
  final DateTime? createdAt;

  /// 更新日時。
  final DateTime? updatedAt;

  /// モデルへ変換する。
  MenuCategory toModel() => MenuCategory(
    id: id,
    name: name,
    displayOrder: displayOrder,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  /// 値を更新したコピーを返す。
  MenuCategoryViewData copyWith({
    String? name,
    int? displayOrder,
    int? itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MenuCategoryViewData(
    id: id,
    name: name ?? this.name,
    displayOrder: displayOrder ?? this.displayOrder,
    itemCount: itemCount ?? this.itemCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// メニューアイテムの表示用データ。
class MenuItemViewData {
  /// [MenuItemViewData]を生成する。
  const MenuItemViewData({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.isAvailable,
    required this.displayOrder,
    required this.estimatedPrepTimeMinutes,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// モデルから生成する。
  factory MenuItemViewData.fromModel(MenuItem model, {required String categoryName}) =>
      MenuItemViewData(
        id: model.id ?? "",
        name: model.name,
        categoryId: model.categoryId,
        categoryName: categoryName,
        price: model.price,
        isAvailable: model.isAvailable,
        displayOrder: model.displayOrder,
        estimatedPrepTimeMinutes: model.estimatedPrepTimeMinutes,
        description: model.description,
        imageUrl: model.imageUrl,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
      );

  /// メニューアイテムID。
  final String id;

  /// 表示名。
  final String name;

  /// 紐づくカテゴリID。
  final String categoryId;

  /// 紐づくカテゴリ名。
  final String categoryName;

  /// 価格（円）。
  final int price;

  /// 販売可能フラグ。
  final bool isAvailable;

  /// 表示順。
  final int displayOrder;

  /// 推定調理時間（分）。
  final int estimatedPrepTimeMinutes;

  /// 詳細説明。
  final String? description;

  /// 画像URL。
  final String? imageUrl;

  /// 作成日時。
  final DateTime? createdAt;

  /// 更新日時。
  final DateTime? updatedAt;

  /// モデルへ変換する。
  MenuItem toModel() => MenuItem(
    id: id.isEmpty ? null : id,
    name: name,
    categoryId: categoryId,
    price: price,
    description: description,
    isAvailable: isAvailable,
    estimatedPrepTimeMinutes: estimatedPrepTimeMinutes,
    displayOrder: displayOrder,
    imageUrl: imageUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  /// 値を更新したコピーを返す。
  MenuItemViewData copyWith({
    String? name,
    String? categoryId,
    String? categoryName,
    int? price,
    bool? isAvailable,
    int? displayOrder,
    int? estimatedPrepTimeMinutes,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MenuItemViewData(
    id: id,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    price: price ?? this.price,
    isAvailable: isAvailable ?? this.isAvailable,
    displayOrder: displayOrder ?? this.displayOrder,
    estimatedPrepTimeMinutes: estimatedPrepTimeMinutes ?? this.estimatedPrepTimeMinutes,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// メニュー管理画面全体の状態。
class MenuManagementState {
  MenuManagementState({
    required this.isInitializing,
    required this.isRealtimeEnabled,
    required List<MenuCategoryViewData> categories,
    required List<MenuItemViewData> items,
    required this.categoryQuery,
    required this.itemQuery,
    required this.selectedCategoryId,
    required this.selectedItemId,
    required Map<String, MenuAvailabilityViewData> availabilityMap,
    required this.lastSyncedAt,
    required Set<String> savingCategoryIds,
    required Set<String> deletingCategoryIds,
    required Set<String> savingItemIds,
    required Set<String> deletingItemIds,
    required this.errorMessage,
  }) : _categories = List<MenuCategoryViewData>.unmodifiable(categories),
       _items = List<MenuItemViewData>.unmodifiable(items),
       _availabilityMap = Map<String, MenuAvailabilityViewData>.unmodifiable(availabilityMap),
       _savingCategoryIds = Set<String>.unmodifiable(savingCategoryIds),
       _deletingCategoryIds = Set<String>.unmodifiable(deletingCategoryIds),
       _savingItemIds = Set<String>.unmodifiable(savingItemIds),
       _deletingItemIds = Set<String>.unmodifiable(deletingItemIds);

  /// 初期状態を生成する。
  factory MenuManagementState.initial() => MenuManagementState(
    isInitializing: true,
    isRealtimeEnabled: false,
    categories: const <MenuCategoryViewData>[],
    items: const <MenuItemViewData>[],
    categoryQuery: "",
    itemQuery: "",
    selectedCategoryId: null,
    selectedItemId: null,
    availabilityMap: const <String, MenuAvailabilityViewData>{},
    lastSyncedAt: null,
    savingCategoryIds: const <String>{},
    deletingCategoryIds: const <String>{},
    savingItemIds: const <String>{},
    deletingItemIds: const <String>{},
    errorMessage: null,
  );

  static const Object _sentinel = Object();

  /// 読み込み中かどうか。
  final bool isInitializing;

  /// リアルタイム監視が有効かどうか。
  final bool isRealtimeEnabled;

  final List<MenuCategoryViewData> _categories;
  final List<MenuItemViewData> _items;
  final Map<String, MenuAvailabilityViewData> _availabilityMap;
  final Set<String> _savingCategoryIds;
  final Set<String> _deletingCategoryIds;
  final Set<String> _savingItemIds;
  final Set<String> _deletingItemIds;

  /// カテゴリ検索クエリ。
  final String categoryQuery;

  /// アイテム検索クエリ。
  final String itemQuery;

  /// 選択中のカテゴリID。nullの場合は全カテゴリ。
  final String? selectedCategoryId;

  /// 選択中のメニューアイテムID。
  final String? selectedItemId;

  /// 最終同期日時。
  final DateTime? lastSyncedAt;

  /// 表示中のエラー。
  final String? errorMessage;

  /// カテゴリ一覧。
  List<MenuCategoryViewData> get categories => _categories;

  /// メニューアイテム一覧。
  List<MenuItemViewData> get items => _items;

  /// 在庫可用性マップ。
  Map<String, MenuAvailabilityViewData> get availabilityMap => _availabilityMap;

  /// 保存処理中のカテゴリID集合。
  Set<String> get savingCategoryIds => _savingCategoryIds;

  /// 削除処理中のカテゴリID集合。
  Set<String> get deletingCategoryIds => _deletingCategoryIds;

  /// 保存処理中のメニューアイテムID集合。
  Set<String> get savingItemIds => _savingItemIds;

  /// 削除処理中のメニューアイテムID集合。
  Set<String> get deletingItemIds => _deletingItemIds;

  /// エラーを保持しているかどうか。
  bool get hasError => errorMessage != null;

  /// 検索クエリが適用されたカテゴリ一覧。
  List<MenuCategoryViewData> get visibleCategories {
    final String query = categoryQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _categories;
    }
    return _categories
        .where((MenuCategoryViewData category) => category.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  /// 検索・カテゴリ選択が適用されたメニューアイテム一覧。
  List<MenuItemViewData> get visibleItems {
    final String query = itemQuery.trim().toLowerCase();
    return _items
        .where((MenuItemViewData item) {
          final bool categoryMatches =
              selectedCategoryId == null || item.categoryId == selectedCategoryId;
          if (!categoryMatches) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          final String nameLower = item.name.toLowerCase();
          final String? descriptionLower = item.description?.toLowerCase();
          return nameLower.contains(query) || (descriptionLower?.contains(query) ?? false);
        })
        .toList(growable: false);
  }

  /// 選択中のメニューアイテムを返す。
  MenuItemViewData? get selectedItem {
    if (selectedItemId == null) {
      return null;
    }
    for (final MenuItemViewData item in _items) {
      if (item.id == selectedItemId) {
        return item;
      }
    }
    return null;
  }

  /// 指定IDの在庫可用性を取得する。
  MenuAvailabilityViewData availabilityFor(String menuItemId) =>
      _availabilityMap[menuItemId] ?? const MenuAvailabilityViewData.idle();

  /// 状態を更新する。
  MenuManagementState copyWith({
    bool? isInitializing,
    bool? isRealtimeEnabled,
    List<MenuCategoryViewData>? categories,
    List<MenuItemViewData>? items,
    String? categoryQuery,
    String? itemQuery,
    Object? selectedCategoryId = _sentinel,
    Object? selectedItemId = _sentinel,
    Map<String, MenuAvailabilityViewData>? availabilityMap,
    Object? lastSyncedAt = _sentinel,
    Set<String>? savingCategoryIds,
    Set<String>? deletingCategoryIds,
    Set<String>? savingItemIds,
    Set<String>? deletingItemIds,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => MenuManagementState(
    isInitializing: isInitializing ?? this.isInitializing,
    isRealtimeEnabled: isRealtimeEnabled ?? this.isRealtimeEnabled,
    categories: categories ?? _categories,
    items: items ?? _items,
    categoryQuery: categoryQuery ?? this.categoryQuery,
    itemQuery: itemQuery ?? this.itemQuery,
    selectedCategoryId: selectedCategoryId == _sentinel
        ? this.selectedCategoryId
        : selectedCategoryId as String?,
    selectedItemId: selectedItemId == _sentinel ? this.selectedItemId : selectedItemId as String?,
    availabilityMap: availabilityMap ?? _availabilityMap,
    lastSyncedAt: lastSyncedAt == _sentinel ? this.lastSyncedAt : lastSyncedAt as DateTime?,
    savingCategoryIds: savingCategoryIds ?? _savingCategoryIds,
    deletingCategoryIds: deletingCategoryIds ?? _deletingCategoryIds,
    savingItemIds: savingItemIds ?? _savingItemIds,
    deletingItemIds: deletingItemIds ?? _deletingItemIds,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
  );
}

/// メニュー管理画面の状態管理を担当するStateNotifier。
class MenuManagementController extends StateNotifier<MenuManagementState> {
  /// [MenuManagementController]を生成する。
  MenuManagementController({required Ref ref, required MenuService menuService})
    : _ref = ref,
      _menuService = menuService,
      super(MenuManagementState.initial()) {
    _ref.onDispose(_dispose);
    _initialize();
    _registerRealtimeListener();
  }

  /// Riverpodの参照。
  final Ref _ref;

  /// メニュー関連サービス。
  final MenuService _menuService;

  /// 初期化処理を行う。
  void _initialize() {
    // * 初期表示データを非同期で取得
    unawaited(
      _loadInitialData(
        showLoadingIndicator: true,
        fallbackCategoryId: state.selectedCategoryId,
        fallbackItemId: state.selectedItemId,
      ).then((_) => _startRealtimeMonitoring()),
    );
  }

  /// 初期データおよび再取得処理を行う。
  Future<void> _loadInitialData({
    required bool showLoadingIndicator,
    String? fallbackCategoryId,
    String? fallbackItemId,
  }) async {
    if (showLoadingIndicator) {
      state = state.copyWith(isInitializing: true, clearErrorMessage: true);
    }

    try {
      final List<MenuCategory> categories = await _menuService.getMenuCategories();
      final List<MenuItem> items = await _menuService.getMenuItemsByCategory(null);

      final List<MenuCategoryViewData> categoryViewData = _buildCategoryViewData(categories, items);
      final Map<String, MenuCategoryViewData> categoryIndex = <String, MenuCategoryViewData>{
        for (final MenuCategoryViewData category in categoryViewData) category.id: category,
      };
      final List<MenuItemViewData> itemViewData = _buildItemViewData(items, categoryIndex);

      final Map<String, MenuAvailabilityViewData> availability = await _buildAvailabilityMap(
        itemViewData.map((MenuItemViewData item) => item.id),
      );

      final String? resolvedCategoryId = _resolveSelectedCategoryId(
        fallbackCategoryId ?? state.selectedCategoryId,
        categoryViewData,
      );
      final String? resolvedItemId = _resolveSelectedItemId(
        fallbackItemId ?? state.selectedItemId,
        itemViewData,
      );

      state = state.copyWith(
        isInitializing: false,
        categories: categoryViewData,
        items: itemViewData,
        selectedCategoryId: resolvedCategoryId,
        selectedItemId: resolvedItemId,
        availabilityMap: availability,
        lastSyncedAt: DateTime.now(),
        clearErrorMessage: true,
      );
    } catch (error, stackTrace) {
      log.e("メニュー情報の取得に失敗しました", error: error, st: stackTrace, tag: _logTag);
      state = state.copyWith(isInitializing: false, errorMessage: "メニュー情報の取得に失敗しました");
    }
  }

  /// カテゴリ検索クエリを更新する。
  void updateCategorySearch(String query) {
    if (query == state.categoryQuery) {
      return;
    }
    state = state.copyWith(categoryQuery: query);
  }

  /// アイテム検索クエリを更新する。
  void updateItemSearch(String query) {
    if (query == state.itemQuery) {
      return;
    }
    state = state.copyWith(itemQuery: query);
  }

  /// カテゴリを選択する。
  void selectCategory(String? categoryId) {
    if (categoryId != null &&
        !state.categories.any((MenuCategoryViewData category) => category.id == categoryId)) {
      log.w("存在しないカテゴリが選択されました: $categoryId", tag: _logTag);
      return;
    }
    if (state.selectedCategoryId == categoryId) {
      return;
    }
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  /// カテゴリを追加する。
  Future<MenuCategoryViewData> createCategory({
    required String name,
    required int displayOrder,
  }) async {
    try {
      final MenuCategory created = await _menuService.createCategory(
        name: name,
        displayOrder: displayOrder,
      );
      final Map<String, int> counts = _itemCountsByCategory(state.items);
      final MenuCategoryViewData view = _mapCategory(created, counts);
      final List<MenuCategoryViewData> categories =
          List<MenuCategoryViewData>.from(state.categories)
            ..add(view)
            ..sort((MenuCategoryViewData a, MenuCategoryViewData b) {
              final int order = a.displayOrder.compareTo(b.displayOrder);
              if (order != 0) {
                return order;
              }
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
      state = state.copyWith(categories: categories);
      return view;
    } catch (error) {
      log.e("カテゴリの作成に失敗しました", tag: _logTag, error: error);
      rethrow;
    }
  }

  /// カテゴリを更新する。
  Future<MenuCategoryViewData?> updateCategory(String id, {String? name, int? displayOrder}) async {
    final Set<String> saving = Set<String>.from(state.savingCategoryIds)..add(id);
    state = state.copyWith(savingCategoryIds: saving);
    final List<MenuCategoryViewData> previous = state.categories;
    try {
      final MenuCategory? updated = await _menuService.updateCategory(
        id,
        name: name,
        displayOrder: displayOrder,
      );
      if (updated == null) {
        return null;
      }
      final Map<String, int> counts = _itemCountsByCategory(state.items);
      final MenuCategoryViewData view = _mapCategory(updated, counts);
      final List<MenuCategoryViewData> categories = <MenuCategoryViewData>[];
      for (final MenuCategoryViewData category in previous) {
        if (category.id == id) {
          categories.add(view);
        } else {
          categories.add(category);
        }
      }
      categories.sort((MenuCategoryViewData a, MenuCategoryViewData b) {
        final int order = a.displayOrder.compareTo(b.displayOrder);
        if (order != 0) {
          return order;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      state = state.copyWith(categories: categories);
      return view;
    } catch (error) {
      log.e("カテゴリの更新に失敗しました", tag: _logTag, error: error);
      rethrow;
    } finally {
      final Set<String> updatedSaving = Set<String>.from(state.savingCategoryIds)..remove(id);
      state = state.copyWith(savingCategoryIds: updatedSaving);
    }
  }

  /// カテゴリを削除する。
  Future<void> deleteCategory(String id) async {
    final List<MenuCategoryViewData> previousCategories = state.categories;
    final List<MenuItemViewData> previousItems = state.items;
    final Set<String> deleting = Set<String>.from(state.deletingCategoryIds)..add(id);
    final List<MenuCategoryViewData> categories = previousCategories
        .where((MenuCategoryViewData category) => category.id != id)
        .toList();
    final List<MenuItemViewData> items = previousItems
        .where((MenuItemViewData item) => item.categoryId != id)
        .toList();
    state = state.copyWith(
      categories: categories,
      items: items,
      deletingCategoryIds: deleting,
      selectedCategoryId: state.selectedCategoryId == id ? null : state.selectedCategoryId,
      selectedItemId: state.selectedItem?.categoryId == id ? null : state.selectedItemId,
    );

    try {
      await _menuService.deleteCategory(id);
    } catch (error) {
      log.e("カテゴリの削除に失敗しました", tag: _logTag, error: error);
      state = state.copyWith(categories: previousCategories, items: previousItems);
      rethrow;
    } finally {
      final Set<String> updatedDeleting = Set<String>.from(state.deletingCategoryIds)..remove(id);
      state = state.copyWith(deletingCategoryIds: updatedDeleting);
    }
  }

  /// カテゴリの表示順を変更する。
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final List<MenuCategoryViewData> original = state.categories;
    final List<MenuCategoryViewData> reordered = List<MenuCategoryViewData>.from(original);
    if (oldIndex < 0 || oldIndex >= reordered.length) {
      return;
    }
    if (newIndex >= reordered.length) {
      newIndex = reordered.length - 1;
    }
    if (newIndex < 0) {
      newIndex = 0;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final MenuCategoryViewData moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final List<MenuCategoryViewData> adjusted = <MenuCategoryViewData>[];
    for (int index = 0; index < reordered.length; index++) {
      adjusted.add(reordered[index].copyWith(displayOrder: index + 1));
    }
    state = state.copyWith(categories: adjusted);

    final List<MenuCategory> payload = <MenuCategory>[];
    for (final MenuCategoryViewData category in adjusted) {
      payload.add(
        MenuCategory(
          id: category.id,
          name: category.name,
          displayOrder: category.displayOrder,
          createdAt: category.createdAt,
          updatedAt: category.updatedAt,
        ),
      );
    }

    try {
      await _menuService.updateCategoryOrder(payload);
    } catch (error) {
      log.e("カテゴリの並び替えに失敗しました", tag: _logTag, error: error);
      state = state.copyWith(categories: original);
    }
  }

  /// メニューアイテムを選択する。
  void selectItem(String? menuItemId) {
    if (menuItemId != null && !state.items.any((MenuItemViewData item) => item.id == menuItemId)) {
      log.w("存在しないメニューアイテムが指定されました: $menuItemId", tag: _logTag);
      return;
    }
    if (state.selectedItemId == menuItemId) {
      return;
    }
    state = state.copyWith(selectedItemId: menuItemId);
  }

  /// 販売可否を切り替える。
  Future<void> toggleItemAvailability(MenuItemViewData item, bool isAvailable) async {
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception("ユーザーIDが取得できません");
    }
    final Set<String> saving = Set<String>.from(state.savingItemIds)..add(item.id);
    state = state.copyWith(savingItemIds: saving);

    final List<MenuItemViewData> previousItems = state.items;
    final List<MenuItemViewData> updatedItems = List<MenuItemViewData>.from(previousItems);
    final int index = updatedItems.indexWhere((MenuItemViewData element) => element.id == item.id);
    if (index == -1) {
      final Set<String> cleanup = Set<String>.from(state.savingItemIds)..remove(item.id);
      state = state.copyWith(savingItemIds: cleanup);
      return;
    }

    final Map<String, MenuCategoryViewData> categoryIndex = <String, MenuCategoryViewData>{
      for (final MenuCategoryViewData category in state.categories) category.id: category,
    };
    updatedItems[index] = updatedItems[index].copyWith(isAvailable: isAvailable);
    state = state.copyWith(items: updatedItems);

    try {
      final MenuItem? updated = await _menuService.toggleMenuItemAvailability(
        item.id,
        isAvailable,
        userId,
      );
      if (updated != null) {
        final MenuItemViewData view = _mapMenuItem(updated, categoryIndex);
        updatedItems[index] = view;
        state = state.copyWith(items: updatedItems);
      }
      await refreshAvailability(<String>[item.id]);
    } catch (error) {
      log.e("メニューの販売可否切り替えに失敗しました", tag: _logTag, error: error);
      state = state.copyWith(items: previousItems);
      rethrow;
    } finally {
      final Set<String> cleanup = Set<String>.from(state.savingItemIds)..remove(item.id);
      state = state.copyWith(savingItemIds: cleanup);
    }
  }

  /// メニューアイテムを作成する。
  Future<MenuItemViewData> createMenuItem({
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required int estimatedPrepTimeMinutes,
    required int displayOrder,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final MenuItem created = await _menuService.createMenuItem(
        name: name,
        categoryId: categoryId,
        price: price,
        isAvailable: isAvailable,
        estimatedPrepTimeMinutes: estimatedPrepTimeMinutes,
        displayOrder: displayOrder,
        description: description,
        imageUrl: imageUrl,
      );
      if (created.id == null) {
        throw Exception("作成したメニューにIDが割り当てられていません");
      }
      final Map<String, MenuCategoryViewData> categoryIndex = <String, MenuCategoryViewData>{
        for (final MenuCategoryViewData category in state.categories) category.id: category,
      };
      final MenuItemViewData view = _mapMenuItem(created, categoryIndex);
      final List<MenuItemViewData> items = List<MenuItemViewData>.from(state.items)
        ..add(view)
        ..sort((MenuItemViewData a, MenuItemViewData b) {
          final int order = a.displayOrder.compareTo(b.displayOrder);
          if (order != 0) {
            return order;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      final Map<String, int> counts = _itemCountsByCategory(items);
      final List<MenuCategoryViewData> categories = _updateCategoryItemCounts(
        state.categories,
        counts,
      );
      state = state.copyWith(items: items, categories: categories, selectedItemId: view.id);
      await refreshAvailability(<String>[view.id]);
      return view;
    } catch (error) {
      log.e("メニューの作成に失敗しました", tag: _logTag, error: error);
      rethrow;
    }
  }

  /// メニューアイテムを更新する。
  Future<MenuItemViewData?> updateMenuItem(
    String id, {
    String? name,
    String? categoryId,
    int? price,
    bool? isAvailable,
    int? estimatedPrepTimeMinutes,
    int? displayOrder,
    String? description,
    String? imageUrl,
  }) async {
    final Set<String> saving = Set<String>.from(state.savingItemIds)..add(id);
    final List<MenuItemViewData> previousItems = state.items;
    state = state.copyWith(savingItemIds: saving);
    try {
      final MenuItem? updated = await _menuService.updateMenuItem(
        id,
        name: name,
        categoryId: categoryId,
        price: price,
        isAvailable: isAvailable,
        estimatedPrepTimeMinutes: estimatedPrepTimeMinutes,
        displayOrder: displayOrder,
        description: description,
        imageUrl: imageUrl,
      );
      if (updated == null) {
        return null;
      }
      final Map<String, MenuCategoryViewData> categoryIndex = <String, MenuCategoryViewData>{
        for (final MenuCategoryViewData category in state.categories) category.id: category,
      };
      final MenuItemViewData view = _mapMenuItem(updated, categoryIndex);
      final List<MenuItemViewData> items = <MenuItemViewData>[];
      for (final MenuItemViewData current in previousItems) {
        if (current.id == id) {
          items.add(view);
        } else {
          items.add(current);
        }
      }
      items.sort((MenuItemViewData a, MenuItemViewData b) {
        final int order = a.displayOrder.compareTo(b.displayOrder);
        if (order != 0) {
          return order;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      final Map<String, int> counts = _itemCountsByCategory(items);
      final List<MenuCategoryViewData> categories = _updateCategoryItemCounts(
        state.categories,
        counts,
      );
      state = state.copyWith(items: items, categories: categories, selectedItemId: view.id);
      await refreshAvailability(<String>[view.id]);
      return view;
    } catch (error) {
      log.e("メニューの更新に失敗しました", tag: _logTag, error: error);
      rethrow;
    } finally {
      final Set<String> cleanup = Set<String>.from(state.savingItemIds)..remove(id);
      state = state.copyWith(savingItemIds: cleanup);
    }
  }

  /// メニューアイテムを削除する。
  Future<void> deleteMenuItem(String id) async {
    final List<MenuItemViewData> previousItems = state.items;
    final List<MenuCategoryViewData> previousCategories = state.categories;
    final Set<String> deleting = Set<String>.from(state.deletingItemIds)..add(id);
    final List<MenuItemViewData> items = previousItems
        .where((MenuItemViewData item) => item.id != id)
        .toList();
    final Map<String, int> counts = _itemCountsByCategory(items);
    final List<MenuCategoryViewData> categories = _updateCategoryItemCounts(
      state.categories,
      counts,
    );
    state = state.copyWith(
      items: items,
      categories: categories,
      deletingItemIds: deleting,
      selectedItemId: state.selectedItemId == id ? null : state.selectedItemId,
    );
    try {
      await _menuService.deleteMenuItem(id);
    } catch (error) {
      log.e("メニューの削除に失敗しました", tag: _logTag, error: error);
      state = state.copyWith(items: previousItems, categories: previousCategories);
      rethrow;
    } finally {
      final Set<String> cleanup = Set<String>.from(state.deletingItemIds)..remove(id);
      state = state.copyWith(deletingItemIds: cleanup);
    }
  }

  /// 在庫可用性を最新化する。
  Future<void> refreshAvailability([Iterable<String>? menuItemIds]) async {
    final Set<String> targetIds = <String>{
      if (menuItemIds == null || menuItemIds.isEmpty)
        ...state.items.map((MenuItemViewData item) => item.id)
      else
        ...menuItemIds,
    };

    if (targetIds.isEmpty) {
      return;
    }

    final Map<String, MenuAvailabilityViewData> loadingMap =
        Map<String, MenuAvailabilityViewData>.from(state.availabilityMap);
    for (final String id in targetIds) {
      loadingMap[id] = const MenuAvailabilityViewData.loading();
    }
    state = state.copyWith(availabilityMap: loadingMap);

    final Map<String, MenuAvailabilityViewData> refreshed = await _buildAvailabilityMap(targetIds);
    final Map<String, MenuAvailabilityViewData> merged = Map<String, MenuAvailabilityViewData>.from(
      state.availabilityMap,
    )..addAll(refreshed);

    state = state.copyWith(availabilityMap: merged, lastSyncedAt: DateTime.now());
  }

  /// 全データを再取得する。
  Future<void> refreshAll({bool keepSelection = true}) async {
    final String? fallbackCategoryId = keepSelection ? state.selectedCategoryId : null;
    final String? fallbackItemId = keepSelection ? state.selectedItemId : null;
    await _loadInitialData(
      showLoadingIndicator: false,
      fallbackCategoryId: fallbackCategoryId,
      fallbackItemId: fallbackItemId,
    );
  }

  /// リアルタイムイベントの購読を開始する。
  void _registerRealtimeListener() {
    _ref.listen<int>(menuRealtimeEventCounterProvider, (int? previous, int next) {
      if (previous == null) {
        return;
      }
      unawaited(_handleRealtimeEvent());
    }, fireImmediately: false);
  }

  /// リアルタイムイベント受信時の処理。
  Future<void> _handleRealtimeEvent() async {
    log.d("リアルタイムイベントを検知したため再フェッチを実行", tag: _logTag);
    await refreshAll();
  }

  /// リアルタイム監視を開始する。
  Future<void> _startRealtimeMonitoring() async {
    if (state.isRealtimeEnabled) {
      return;
    }
    try {
      await _menuService.startRealtimeMonitoring();
      state = state.copyWith(isRealtimeEnabled: true);
    } catch (error, stackTrace) {
      log.e("リアルタイム監視の開始に失敗しました", error: error, st: stackTrace, tag: _logTag);
    }
  }

  /// 可用性マップを構築する。
  Future<Map<String, MenuAvailabilityViewData>> _buildAvailabilityMap(
    Iterable<String> menuItemIds,
  ) async {
    final List<String> ids = menuItemIds
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) {
      return <String, MenuAvailabilityViewData>{};
    }

    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      log.w("ユーザーIDが取得できないため在庫可用性チェックをスキップ", tag: _logTag);
      return <String, MenuAvailabilityViewData>{
        for (final String id in ids) id: const MenuAvailabilityViewData.idle(),
      };
    }

    try {
      final Map<String, MenuAvailabilityInfo> availability = await _menuService
          .bulkCheckMenuAvailability(userId, menuItemIds: ids);
      return <String, MenuAvailabilityViewData>{
        for (final String id in ids)
          id: availability.containsKey(id)
              ? MenuAvailabilityViewData.fromInfo(availability[id]!)
              : const MenuAvailabilityViewData.idle(),
      };
    } catch (error, stackTrace) {
      log.e("在庫可用性の取得に失敗しました", error: error, st: stackTrace, tag: _logTag);
      return <String, MenuAvailabilityViewData>{
        for (final String id in ids) id: MenuAvailabilityViewData.failure("在庫可用性の取得に失敗しました"),
      };
    }
  }

  /// カテゴリ一覧をViewDataへ変換する。
  List<MenuCategoryViewData> _buildCategoryViewData(
    List<MenuCategory> categories,
    List<MenuItem> items,
  ) {
    final Map<String, int> counts = <String, int>{};
    for (final MenuItem item in items) {
      final String categoryId = item.categoryId;
      counts[categoryId] = (counts[categoryId] ?? 0) + 1;
    }

    final List<MenuCategoryViewData> result = <MenuCategoryViewData>[];
    for (final MenuCategory category in categories) {
      final String? id = category.id;
      if (id == null) {
        log.w("IDが設定されていないカテゴリをスキップしました", tag: _logTag);
        continue;
      }
      result.add(
        MenuCategoryViewData(
          id: id,
          name: category.name,
          displayOrder: category.displayOrder,
          itemCount: counts[id] ?? 0,
          createdAt: category.createdAt,
          updatedAt: category.updatedAt,
        ),
      );
    }
    result.sort((MenuCategoryViewData a, MenuCategoryViewData b) {
      final int order = a.displayOrder.compareTo(b.displayOrder);
      if (order != 0) {
        return order;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  /// メニューアイテム一覧をViewDataへ変換する。
  List<MenuItemViewData> _buildItemViewData(
    List<MenuItem> items,
    Map<String, MenuCategoryViewData> categoryIndex,
  ) {
    final List<MenuItemViewData> result = <MenuItemViewData>[];
    for (final MenuItem item in items) {
      final String? id = item.id;
      if (id == null) {
        log.w("IDが設定されていないメニューアイテムをスキップしました", tag: _logTag);
        continue;
      }
      final MenuCategoryViewData? category = categoryIndex[item.categoryId];
      final String categoryName = category?.name ?? "未分類";
      result.add(MenuItemViewData.fromModel(item, categoryName: categoryName));
    }
    result.sort((MenuItemViewData a, MenuItemViewData b) {
      final int order = a.displayOrder.compareTo(b.displayOrder);
      if (order != 0) {
        return order;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  MenuCategoryViewData _mapCategory(MenuCategory category, Map<String, int> counts) =>
      MenuCategoryViewData(
        id: category.id ?? "",
        name: category.name,
        displayOrder: category.displayOrder,
        itemCount: counts[category.id] ?? 0,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
      );

  MenuItemViewData _mapMenuItem(MenuItem item, Map<String, MenuCategoryViewData> categoryIndex) {
    final MenuCategoryViewData? category = categoryIndex[item.categoryId];
    final String categoryName = category?.name ?? "未分類";
    return MenuItemViewData.fromModel(item, categoryName: categoryName);
  }

  Map<String, int> _itemCountsByCategory(List<MenuItemViewData> items) {
    final Map<String, int> counts = <String, int>{};
    for (final MenuItemViewData item in items) {
      counts[item.categoryId] = (counts[item.categoryId] ?? 0) + 1;
    }
    return counts;
  }

  List<MenuCategoryViewData> _updateCategoryItemCounts(
    List<MenuCategoryViewData> categories,
    Map<String, int> counts,
  ) => categories
      .map(
        (MenuCategoryViewData category) =>
            category.copyWith(itemCount: counts[category.id] ?? category.itemCount),
      )
      .toList();

  /// 選択中のカテゴリIDを再評価する。
  String? _resolveSelectedCategoryId(String? candidate, List<MenuCategoryViewData> categories) {
    if (candidate == null) {
      return null;
    }
    final bool exists = categories.any((MenuCategoryViewData category) => category.id == candidate);
    return exists ? candidate : null;
  }

  /// 選択中のメニューアイテムIDを再評価する。
  String? _resolveSelectedItemId(String? candidate, List<MenuItemViewData> items) {
    if (candidate == null) {
      return null;
    }
    final bool exists = items.any((MenuItemViewData item) => item.id == candidate);
    return exists ? candidate : null;
  }

  /// 廃棄時の後処理。
  void _dispose() {
    unawaited(_menuService.stopRealtimeMonitoring());
  }
}

/// メニュー管理画面向けのStateNotifierProvider。
final StateNotifierProvider<MenuManagementController, MenuManagementState>
menuManagementControllerProvider =
    StateNotifierProvider<MenuManagementController, MenuManagementState>(
      (Ref ref) => MenuManagementController(ref: ref, menuService: ref.read(menuServiceProvider)),
    );
