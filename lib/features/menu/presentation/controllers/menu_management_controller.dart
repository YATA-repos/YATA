import "dart:async";
import "dart:math" as math;

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/utils/error_handler.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../../inventory/models/inventory_model.dart";
import "../../dto/menu_dto.dart";
import "../../dto/menu_recipe_detail.dart";
import "../../models/menu_model.dart";
import "../../services/menu_service.dart";
import "menu_management_state.dart";

/// メニュー作成・編集フォームの入力値。
class MenuFormData {
  /// [MenuFormData]を生成する。
  const MenuFormData({
    required this.name,
    required this.categoryId,
    required this.price,
    required this.isAvailable,
    this.description,
    this.imageUrl,
  });

  /// メニュー名。
  final String name;

  /// 紐づけるカテゴリID。
  final String categoryId;

  /// 価格（税抜）。
  final int price;

  /// 販売可否。
  final bool isAvailable;

  /// 説明文。
  final String? description;

  /// 画像URL。
  final String? imageUrl;
}

/// レシピ編集フォームの入力値。
class MenuRecipeFormData {
  /// [MenuRecipeFormData]を生成する。
  const MenuRecipeFormData({
    required this.menuItemId,
    required this.materialId,
    required this.requiredAmount,
    this.isOptional = false,
    this.notes,
  });

  /// 対象メニューID。
  final String menuItemId;

  /// 使用する材料ID。
  final String materialId;

  /// 必要量。
  final double requiredAmount;

  /// 任意材料かどうか。
  final bool isOptional;

  /// 備考。
  final String? notes;
}

/// レシピ編集用に表示する材料選択肢。
class MaterialOption {
  /// [MaterialOption]を生成する。
  const MaterialOption({
    required this.id,
    required this.name,
    required this.unitType,
    this.currentStock,
  });

  /// 材料ID。
  final String id;

  /// 材料名。
  final String name;

  /// 単位種別。
  final UnitType unitType;

  /// 現在庫量。
  final double? currentStock;
}

/// メニュー管理画面用のコントローラープロバイダー。
final StateNotifierProvider<MenuManagementController, MenuManagementState>
menuManagementControllerProvider =
    StateNotifierProvider<MenuManagementController, MenuManagementState>(
      (Ref ref) => MenuManagementController(ref: ref, menuService: ref.read(menuServiceProvider)),
    );

/// メニュー管理画面の状態と操作を担うStateNotifier。
class MenuManagementController extends StateNotifier<MenuManagementState> {
  /// コントローラーを生成する。
  MenuManagementController({required Ref ref, required MenuService menuService})
    : _ref = ref,
      _menuService = menuService,
      super(MenuManagementState.initial()) {
    _authSubscription = _ref.listen<String?>(
      currentUserIdProvider,
      _handleUserChange,
      fireImmediately: false,
    );
    _setupRealtimeListener();
    unawaited(loadInitialData());
  }

  static const int _recipeBatchSize = 6;

  final Ref _ref;
  final MenuService _menuService;
  final Map<String, MenuCategory> _categoryIndex = <String, MenuCategory>{};
  final Map<String, MenuItem> _menuItemIndex = <String, MenuItem>{};
  final Map<String, bool> _recipePresence = <String, bool>{};
  final Map<String, List<MenuRecipeDetail>> _recipeCache = <String, List<MenuRecipeDetail>>{};
  Map<String, MenuAvailabilityInfo> _availabilityIndex = <String, MenuAvailabilityInfo>{};
  List<MaterialOption>? _materialOptionsCache;

  ProviderSubscription<int>? _realtimeSubscription;
  ProviderSubscription<String?>? _authSubscription;
  Timer? _realtimeDebounce;
  Future<void>? _loadingFuture;

  @override
  void dispose() {
    _realtimeSubscription?.close();
    _authSubscription?.close();
    _realtimeDebounce?.cancel();
    unawaited(_menuService.disableRealtimeFeatures());
    super.dispose();
  }

  /// 初期データを読み込み、画面を構築する。
  Future<void> loadInitialData({bool resetSelection = false}) =>
      _loadData(showLoading: true, resetCategorySelection: resetSelection);

  /// 最新データを再取得する。
  Future<void> refreshAll() => _loadData(showLoading: false);

  /// 在庫可用性を再計算する。
  Future<void> refreshAvailability() async {
    if (state.isRefreshingAvailability) {
      return;
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    state = state.copyWith(isRefreshingAvailability: true, clearError: true);

    try {
      await _menuService.autoUpdateMenuAvailabilityByStock(userId);
      await _reloadAvailability(userId);
      state = state.copyWith(
        isRefreshingAvailability: false,
        isRealtimeConnected: _menuService.isRealtimeConnected(),
        realtimeEventCount: _ref.read(menuRealtimeEventCounterProvider),
        clearError: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isRefreshingAvailability: false, errorMessage: message);
    }
  }

  /// カテゴリ選択を更新する。
  void selectCategory(String? categoryId) {
    final String? resolvedId =
        categoryId != null &&
            state.categories.any((MenuCategoryViewData category) => category.id == categoryId)
        ? categoryId
        : null;
    if (resolvedId == state.selectedCategoryId) {
      return;
    }
    state = state.copyWith(
      setSelectedCategory: true,
      selectedCategoryId: resolvedId,
      clearError: true,
    );
  }

  /// テキスト検索を更新する。
  void updateSearchQuery(String query) {
    if (query == state.searchQuery) {
      return;
    }
    state = state.copyWith(searchQuery: query, clearError: true);
  }

  /// 在庫フィルターを変更する。
  void updateAvailabilityFilter(MenuAvailabilityFilter filter) {
    if (filter == state.availabilityFilter) {
      return;
    }
    state = state.copyWith(availabilityFilter: filter, clearError: true);
  }

  /// メニュー詳細を開く。
  Future<void> openDetail(String menuItemId) async {
    final MenuItemViewData? base = _findMenuInState(menuItemId);
    if (base == null) {
      state = state.copyWith(errorMessage: "選択したメニューが見つかりませんでした。");
      return;
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      List<MenuRecipeDetail> recipes = _recipeCache[menuItemId] ?? <MenuRecipeDetail>[];
      if (recipes.isEmpty) {
        recipes = await _menuService.getMenuRecipes(menuItemId);
        _recipeCache[menuItemId] = recipes;
        _recipePresence[menuItemId] = recipes.isNotEmpty;
      }

      final MenuAvailabilityInfo? availability =
          _availabilityIndex[menuItemId] ??
          await _menuService.refreshMenuAvailabilityForMenu(menuItemId);
      if (availability != null) {
        _availabilityIndex[menuItemId] = availability;
      }

      final int maxServings = await _menuService.calculateMaxServings(menuItemId, userId);

      final MenuItemViewData? latest = _findMenuInState(menuItemId);
      final MenuItemViewData merged = (latest ?? base).copyWith(
        isStockAvailable: availability?.isAvailable ?? base.isStockAvailable,
        missingMaterials: availability == null
            ? base.missingMaterials
            : _normalizeMissingMaterials(availability.missingMaterials),
        estimatedServings: availability?.estimatedServings ?? base.estimatedServings,
      );

      final MenuDetailViewData detail = MenuDetailViewData(
        menu: merged,
        recipes: recipes,
        availabilityLabel: _buildAvailabilityLabel(merged, availability, maxServings),
        maxServings: maxServings,
      );

      state = state.copyWith(
        isSubmitting: false,
        setSelectedMenu: true,
        selectedMenuId: menuItemId,
        setDetail: true,
        detail: detail,
        clearError: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
    }
  }

  /// 詳細パネルを閉じる。
  void closeDetail() {
    if (state.selectedMenuId == null && state.detail == null) {
      return;
    }
    state = state.copyWith(
      setSelectedMenu: true,
      clearDetail: true,
      clearError: true,
    );
  }

  /// カテゴリを新規作成する。
  Future<void> createCategory(String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: "カテゴリ名を入力してください。");
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final int nextOrder = _categoryIndex.values.isEmpty
          ? 1
          : _categoryIndex.values.map((MenuCategory c) => c.displayOrder).reduce(math.max) + 1;
      final MenuCategory created = await _menuService.createCategory(
        name: trimmed,
        displayOrder: nextOrder,
      );
      await _loadData(showLoading: false);
      state = state.copyWith(
        isSubmitting: false,
        setSelectedCategory: true,
        selectedCategoryId: created.id,
        clearError: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
    }
  }

  /// カテゴリ名を更新する。
  Future<void> renameCategory(String categoryId, String newName) async {
    final String trimmed = newName.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: "カテゴリ名を入力してください。");
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _menuService.updateCategory(categoryId, name: trimmed);
      await _loadData(showLoading: false);
      state = state.copyWith(
        isSubmitting: false,
        setSelectedCategory: true,
        selectedCategoryId: categoryId,
        clearError: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
    }
  }

  /// カテゴリを削除する。
  Future<void> deleteCategory(String categoryId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _menuService.deleteCategory(categoryId);
      await _loadData(showLoading: false, resetCategorySelection: true);
      state = state.copyWith(
        isSubmitting: false,
        setSelectedCategory: true,
        clearError: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
    }
  }

  /// メニューを新規追加する。
  Future<void> createMenu(MenuFormData data) async {
    final String trimmedName = data.name.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(errorMessage: "メニュー名を入力してください。");
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _menuService.createMenuItem(
        name: trimmedName,
        categoryId: data.categoryId,
        price: data.price,
        isAvailable: data.isAvailable,
        displayOrder: _nextMenuDisplayOrder(data.categoryId),
        description: _normalizeNullableText(data.description),
        imageUrl: _normalizeNullableText(data.imageUrl),
      );
      await _loadData(showLoading: false);
      state = state.copyWith(
        isSubmitting: false,
        setSelectedCategory: true,
        selectedCategoryId: data.categoryId,
        clearError: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
    }
  }

  /// 既存メニューを更新する。
  Future<void> updateMenu(String menuItemId, MenuFormData data) async {
    final String trimmedName = data.name.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(errorMessage: "メニュー名を入力してください。");
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _menuService.updateMenuItem(
        menuItemId,
        name: trimmedName,
        categoryId: data.categoryId,
        price: data.price,
        description: _normalizeNullableText(data.description),
        isAvailable: data.isAvailable,
        imageUrl: _normalizeNullableText(data.imageUrl),
      );
      await _loadData(showLoading: false);
      state = state.copyWith(
        isSubmitting: false,
        setSelectedCategory: true,
        selectedCategoryId: data.categoryId,
        clearError: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
    }
  }

  /// メニューを削除する。
  Future<void> deleteMenu(String menuItemId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _menuService.deleteMenuItem(menuItemId);
      if (state.selectedMenuId == menuItemId) {
        state = state.copyWith(clearDetail: true, setSelectedMenu: true);
      }
      await _loadData(showLoading: false);
      state = state.copyWith(isSubmitting: false, clearError: true);
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
    }
  }

  /// メニューの販売可否を切り替える。
  Future<void> toggleMenuAvailability(String menuItemId, bool nextAvailability) async {
    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    if (state.pendingAvailabilityMenuIds.contains(menuItemId)) {
      return;
    }

    final MenuItemViewData? previous = _findMenuInState(menuItemId);
    if (previous == null) {
      final Map<String, String> errors =
          Map<String, String>.from(state.availabilityErrorMessages)
            ..[menuItemId] = "選択したメニューが見つかりませんでした。";
      state = state.copyWith(availabilityErrorMessages: errors, errorMessage: errors[menuItemId]);
      return;
    }

    final List<MenuItemViewData> updatedMenuItems = state.menuItems
        .map(
          (MenuItemViewData item) =>
              item.id == menuItemId ? item.copyWith(isAvailable: nextAvailability) : item,
        )
        .toList(growable: false);

    final Set<String> pending = Set<String>.from(state.pendingAvailabilityMenuIds)..add(menuItemId);
    final Map<String, String> errors = Map<String, String>.from(state.availabilityErrorMessages)
      ..remove(menuItemId);

    final MenuDetailViewData? currentDetail = state.detail;
    MenuDetailViewData? nextDetail = currentDetail;
    if (currentDetail != null && currentDetail.menu.id == menuItemId) {
      final MenuItemViewData nextMenu = currentDetail.menu.copyWith(isAvailable: nextAvailability);
      final MenuAvailabilityInfo? info = _availabilityIndex[menuItemId];
      final int maxServings = currentDetail.maxServings ?? 0;
      nextDetail = currentDetail.copyWith(
        menu: nextMenu,
        availabilityLabel: _buildAvailabilityLabel(nextMenu, info, maxServings),
      );
    }

    state = state.copyWith(
      menuItems: updatedMenuItems,
      pendingAvailabilityMenuIds: pending,
      availabilityErrorMessages: errors,
      setDetail: nextDetail != null,
      detail: nextDetail,
      clearDetail: nextDetail == null && currentDetail != null,
      clearError: true,
    );

    try {
      final MenuItem? updated = await _menuService.toggleMenuItemAvailability(
        menuItemId,
        nextAvailability,
        userId,
      );
      if (updated != null && updated.id != null) {
        _menuItemIndex[updated.id!] = updated;
      }
      await _reloadAvailability(userId);
      final Set<String> clearedPending =
          Set<String>.from(state.pendingAvailabilityMenuIds)..remove(menuItemId);
      state = state.copyWith(pendingAvailabilityMenuIds: clearedPending, clearError: true);
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      final Set<String> clearedPending =
          Set<String>.from(state.pendingAvailabilityMenuIds)..remove(menuItemId);
      final Map<String, String> nextErrors =
          Map<String, String>.from(state.availabilityErrorMessages)
            ..[menuItemId] = message;
      final List<MenuItemViewData> revertedMenuItems = state.menuItems
          .map(
            (MenuItemViewData item) => item.id == menuItemId
                ? item.copyWith(isAvailable: previous.isAvailable)
                : item,
          )
          .toList(growable: false);

      MenuDetailViewData? detail = state.detail;
      if (detail != null && detail.menu.id == menuItemId) {
        final MenuItemViewData revertedMenu = detail.menu.copyWith(
          isAvailable: previous.isAvailable,
        );
        detail = detail.copyWith(
          menu: revertedMenu,
          availabilityLabel: _buildAvailabilityLabel(
            revertedMenu,
            _availabilityIndex[menuItemId],
            detail.maxServings ?? 0,
          ),
        );
      }

      state = state.copyWith(
        menuItems: revertedMenuItems,
        pendingAvailabilityMenuIds: clearedPending,
        availabilityErrorMessages: nextErrors,
        errorMessage: message,
        setDetail: detail != null,
        detail: detail,
        clearDetail: detail == null && state.detail != null,
      );
    }
  }

  /// レシピ編集用の材料候補を取得する。
  Future<List<MaterialOption>> loadMaterialOptions() async {
    if (_materialOptionsCache != null) {
      return _materialOptionsCache!;
    }

    try {
      final List<Material> materials = await _menuService.getMaterialCandidates();
      final List<MaterialOption> options =
          materials
              .where((Material material) => material.id != null)
              .map(
                (Material material) => MaterialOption(
                  id: material.id!,
                  name: material.name,
                  unitType: material.unitType,
                  currentStock: material.currentStock,
                ),
              )
              .toList(growable: false)
            ..sort((MaterialOption a, MaterialOption b) => a.name.compareTo(b.name));
      _materialOptionsCache = options;
      return options;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
      return const <MaterialOption>[];
    }
  }

  /// レシピを追加または更新する。
  Future<void> upsertMenuRecipe(MenuRecipeFormData data) async {
    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final MenuRecipeDetail saved = await _menuService.upsertMenuRecipe(
        menuItemId: data.menuItemId,
        materialId: data.materialId,
        requiredAmount: data.requiredAmount,
        isOptional: data.isOptional,
        notes: _normalizeNullableText(data.notes),
      );

      final List<MenuRecipeDetail> updatedRecipes = List<MenuRecipeDetail>.from(
        _recipeCache[data.menuItemId] ?? state.detail?.recipes ?? <MenuRecipeDetail>[],
      );
      final int index = updatedRecipes.indexWhere(
        (MenuRecipeDetail e) => e.materialId == saved.materialId,
      );
      if (index >= 0) {
        updatedRecipes[index] = saved;
      } else {
        updatedRecipes.add(saved);
      }
      updatedRecipes.sort(
        (MenuRecipeDetail a, MenuRecipeDetail b) => a.materialName.compareTo(b.materialName),
      );
      _recipeCache[data.menuItemId] = updatedRecipes;
      _recipePresence[data.menuItemId] = updatedRecipes.isNotEmpty;

      await _menuService.refreshMenuAvailabilityForMenu(data.menuItemId);
      await _reloadAvailability(userId);

      if (state.selectedMenuId == data.menuItemId && state.detail != null) {
        state = state.copyWith(
          isSubmitting: false,
          setDetail: true,
          detail: state.detail!.copyWith(recipes: updatedRecipes),
          clearError: true,
        );
      } else {
        state = state.copyWith(isSubmitting: false, clearError: true);
      }
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
    }
  }

  /// レシピを削除する。
  Future<void> deleteMenuRecipe(String recipeId, String menuItemId) async {
    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _menuService.deleteMenuRecipe(recipeId);
      await _menuService.refreshMenuAvailabilityForMenu(menuItemId);

      final List<MenuRecipeDetail> updatedRecipes = List<MenuRecipeDetail>.from(
        _recipeCache[menuItemId] ?? state.detail?.recipes ?? <MenuRecipeDetail>[],
      )..removeWhere((MenuRecipeDetail e) => e.recipeId == recipeId);

      _recipeCache[menuItemId] = updatedRecipes;
      _recipePresence[menuItemId] = updatedRecipes.isNotEmpty;

      await _reloadAvailability(userId);

      if (state.selectedMenuId == menuItemId && state.detail != null) {
        state = state.copyWith(
          isSubmitting: false,
          setDetail: true,
          detail: state.detail!.copyWith(recipes: updatedRecipes),
          clearError: true,
        );
      } else {
        state = state.copyWith(isSubmitting: false, clearError: true);
      }
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
    }
  }

  MenuItemViewData? _findMenuInState(String menuItemId) =>
      _findMenuItemView(state.menuItems, menuItemId);

  MenuItemViewData? _findMenuItemView(Iterable<MenuItemViewData> items, String menuItemId) {
    for (final MenuItemViewData item in items) {
      if (item.id == menuItemId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _loadData({required bool showLoading, bool resetCategorySelection = false}) {
    if (_loadingFuture != null) {
      return _loadingFuture!;
    }

    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    final Future<void> future = _performLoad(
      resetCategorySelection: resetCategorySelection,
    ).whenComplete(() => _loadingFuture = null);
    _loadingFuture = future;
    return future;
  }

  Future<void> _performLoad({bool resetCategorySelection = false}) async {
    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    try {
      await _menuService.enableRealtimeFeatures();

      final Future<List<MenuCategory>> categoriesFuture = _menuService.getMenuCategories();
      final Future<List<MenuItem>> menuFuture = _menuService.getMenuItemsByCategory(null);

      final List<MenuCategory> categoryModels = await categoriesFuture;
      final List<MenuItem> menuItemModels = await menuFuture;

      final Map<String, MenuAvailabilityInfo> availability = menuItemModels.isEmpty
          ? <String, MenuAvailabilityInfo>{}
          : await _menuService.bulkCheckMenuAvailability(userId);

      final Map<String, bool> recipePresence = await _resolveRecipePresence(menuItemModels);

      _replaceIndexes(
        categories: categoryModels,
        menuItems: menuItemModels,
        availability: availability,
        recipePresence: recipePresence,
      );

      final List<MenuItemViewData> items = _composeMenuItemViewData(
        menuItemModels,
        availability,
        recipePresence,
      );
      final List<MenuCategoryViewData> categories = _composeCategoryViewData(categoryModels, items);

      final String? resolvedCategoryId = _resolveCategorySelection(
        categories,
        resetCategorySelection,
      );

      MenuDetailViewData? detail = state.detail;
      String? detailId = state.selectedMenuId;
      if (detailId != null) {
        final MenuItemViewData? updated = _findMenuItemView(items, detailId);
        if (updated == null) {
          detailId = null;
          detail = null;
        } else {
          detail = detail?.copyWith(menu: updated);
        }
      }

      state = state.copyWith(
        categories: categories,
        menuItems: items,
        setSelectedCategory: true,
        selectedCategoryId: resolvedCategoryId,
        isLoading: false,
        isSubmitting: false,
        isRealtimeConnected: _menuService.isRealtimeConnected(),
        realtimeEventCount: _ref.read(menuRealtimeEventCounterProvider),
        setDetail: detail != null,
        detail: detail,
        clearDetail: detail == null,
        setSelectedMenu: true,
        selectedMenuId: detailId,
        clearError: true,
        pendingAvailabilityMenuIds: const <String>{},
        availabilityErrorMessages: const <String, String>{},
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, isSubmitting: false, errorMessage: message);
    }
  }

  String? _normalizeNullableText(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int _nextMenuDisplayOrder(String categoryId) {
    int maxOrder = 0;
    for (final MenuItem item in _menuItemIndex.values) {
      if (item.categoryId == categoryId) {
        maxOrder = math.max(maxOrder, item.displayOrder);
      }
    }
    return maxOrder + 1;
  }

  void _replaceIndexes({
    required List<MenuCategory> categories,
    required List<MenuItem> menuItems,
    required Map<String, MenuAvailabilityInfo> availability,
    required Map<String, bool> recipePresence,
  }) {
    _categoryIndex
      ..clear()
      ..addEntries(
        categories
            .where((MenuCategory category) => category.id != null)
            .map(
              (MenuCategory category) =>
                  MapEntry<String, MenuCategory>(category.id!, category),
            ),
      );
    _menuItemIndex
      ..clear()
      ..addEntries(
        menuItems
            .where((MenuItem item) => item.id != null)
            .map(
              (MenuItem item) => MapEntry<String, MenuItem>(item.id!, item),
            ),
      );
    _availabilityIndex = Map<String, MenuAvailabilityInfo>.from(availability);

    final Set<String> presentIds = _menuItemIndex.keys.toSet();
    _recipePresence.removeWhere((String key, _) => !presentIds.contains(key));
    _recipeCache.removeWhere((String key, _) => !presentIds.contains(key));

    for (final MapEntry<String, bool> entry in recipePresence.entries) {
      _recipePresence[entry.key] = entry.value;
    }
  }

  void _setupRealtimeListener() {
    _realtimeSubscription ??= _ref.listen<int>(menuRealtimeEventCounterProvider, (
      int? previous,
      int next,
    ) {
      if (!mounted || previous == next) {
        return;
      }
      _handleRealtimeEvent(next);
    }, fireImmediately: false);
  }

  void _handleRealtimeEvent(int nextCounter) {
    state = state.copyWith(realtimeEventCount: nextCounter);
    _scheduleRealtimeRefresh();
  }

  void _handleUserChange(String? previousUserId, String? nextUserId) {
    if (previousUserId == nextUserId) {
      return;
    }

    _clearCaches();

    if (nextUserId == null) {
      state = MenuManagementState.initial();
      unawaited(_menuService.disableRealtimeFeatures());
      return;
    }

    unawaited(loadInitialData(resetSelection: true));
  }

  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) {
        return;
      }
      unawaited(refreshAll());
    });
  }

  void _clearCaches() {
    _categoryIndex.clear();
    _menuItemIndex.clear();
    _recipePresence.clear();
    _recipeCache.clear();
    _availabilityIndex = <String, MenuAvailabilityInfo>{};
  }

  String? _ensureUserId({bool notifyError = true}) {
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null && notifyError) {
      state = state.copyWith(
        isLoading: false,
        isSubmitting: false,
        isRefreshingAvailability: false,
        errorMessage: "ユーザー情報を取得できませんでした。再度ログインしてください。",
      );
    }
    return userId;
  }

  Future<Map<String, bool>> _resolveRecipePresence(List<MenuItem> menuItems) async {
    final Map<String, bool> presence = <String, bool>{};
    final List<String> pending = <String>[];

    for (final MenuItem item in menuItems) {
      final String? id = item.id;
      if (id == null) {
        continue;
      }
      final bool? cached = _recipePresence[id];
      if (cached != null) {
        presence[id] = cached;
      } else {
        pending.add(id);
      }
    }

    for (int index = 0; index < pending.length; index += _recipeBatchSize) {
      final List<String> batch = pending.sublist(
        index,
        index + _recipeBatchSize > pending.length ? pending.length : index + _recipeBatchSize,
      );
      await _loadRecipeBatch(batch, presence);
    }

    return presence;
  }

  Future<void> _loadRecipeBatch(List<String> batch, Map<String, bool> presence) async {
    await Future.wait(
      batch.map((String id) async {
        final List<MenuRecipeDetail> recipes = await _menuService.getMenuRecipes(id);
        final bool hasRecipe = recipes.isNotEmpty;
        presence[id] = hasRecipe;
        _recipePresence[id] = hasRecipe;
        if (hasRecipe) {
          _recipeCache[id] = recipes;
        } else {
          _recipeCache.remove(id);
        }
      }),
    );
  }

  List<MenuItemViewData> _composeMenuItemViewData(
    List<MenuItem> menuItems,
    Map<String, MenuAvailabilityInfo> availability,
    Map<String, bool> recipePresence,
  ) {
    final List<MenuItemViewData> result = <MenuItemViewData>[];

    for (final MenuItem item in menuItems) {
      final String? id = item.id;
      if (id == null) {
        continue;
      }
      final MenuAvailabilityInfo? info = availability[id];
      final String categoryName = _categoryIndex[item.categoryId]?.name ?? "未分類";
      result.add(
        MenuItemViewData(
          id: id,
          name: item.name,
          price: item.price,
          isAvailable: item.isAvailable,
          isStockAvailable: info?.isAvailable ?? item.isAvailable,
          categoryId: item.categoryId,
          categoryName: categoryName,
          displayOrder: item.displayOrder,
          hasRecipe: recipePresence[id] ?? false,
          missingMaterials: info == null
              ? const <String>[]
              : _normalizeMissingMaterials(info.missingMaterials),
          description: item.description,
          imageUrl: item.imageUrl,
          updatedAt: item.updatedAt ?? item.createdAt,
          estimatedServings: info?.estimatedServings,
        ),
      );
    }

    result.sort((MenuItemViewData a, MenuItemViewData b) {
      final int order = a.displayOrder.compareTo(b.displayOrder);
      if (order != 0) {
        return order;
      }
      return a.name.compareTo(b.name);
    });

    return result;
  }

  List<MenuCategoryViewData> _composeCategoryViewData(
    List<MenuCategory> categories,
    List<MenuItemViewData> menuItems,
  ) {
    final List<MenuCategoryViewData> view = <MenuCategoryViewData>[
      MenuCategoryViewData(
        id: null,
        name: "すべて",
        displayOrder: 0,
        totalItems: menuItems.length,
        availableItems: menuItems
            .where((MenuItemViewData item) => item.isAvailable && item.isStockAvailable)
            .length,
        attentionItems: menuItems.where((MenuItemViewData item) => item.needsAttention).length,
      ),
    ];

    final Map<String, List<MenuItemViewData>> grouped = <String, List<MenuItemViewData>>{};
    for (final MenuItemViewData item in menuItems) {
      grouped.putIfAbsent(item.categoryId, () => <MenuItemViewData>[]).add(item);
    }

    final List<MenuCategory> sortedCategories = categories.toList()
      ..sort((MenuCategory a, MenuCategory b) {
        final int order = a.displayOrder.compareTo(b.displayOrder);
        if (order != 0) {
          return order;
        }
        return a.name.compareTo(b.name);
      });

    for (final MenuCategory category in sortedCategories) {
      final String? id = category.id;
      if (id == null) {
        continue;
      }
      final List<MenuItemViewData> items = grouped[id] ?? const <MenuItemViewData>[];
      view.add(
        MenuCategoryViewData(
          id: id,
          name: category.name,
          displayOrder: category.displayOrder,
          totalItems: items.length,
          availableItems: items
              .where((MenuItemViewData item) => item.isAvailable && item.isStockAvailable)
              .length,
          attentionItems: items.where((MenuItemViewData item) => item.needsAttention).length,
        ),
      );
    }

    return view;
  }

  String? _resolveCategorySelection(List<MenuCategoryViewData> categories, bool reset) {
    if (reset) {
      return null;
    }
    final String? current = state.selectedCategoryId;
    if (current == null) {
      return null;
    }
    final bool exists = categories.any((MenuCategoryViewData category) => category.id == current);
    return exists ? current : null;
  }

  List<String> _normalizeMissingMaterials(List<String> materials) {
    if (materials.isEmpty) {
      return materials;
    }
    final List<String> normalized = <String>[];
    for (final String material in materials) {
      switch (material) {
        case "Menu item disabled":
          normalized.add("販売停止中");
          break;
        case "Menu item not found":
          normalized.add("メニューが見つかりません");
          break;
        default:
          normalized.add(material);
      }
    }
    return normalized;
  }

  Future<void> _reloadAvailability(String userId) async {
    try {
      final Map<String, MenuAvailabilityInfo> availability = await _menuService
          .bulkCheckMenuAvailability(userId);
      _availabilityIndex = Map<String, MenuAvailabilityInfo>.from(availability);

      final List<MenuItem> menuModels = _menuItemIndex.values.toList(growable: false);
      final List<MenuItemViewData> items = _composeMenuItemViewData(
        menuModels,
        availability,
        _recipePresence,
      );
      final List<MenuCategoryViewData> categories = _composeCategoryViewData(
        _categoryIndex.values.toList(),
        items,
      );
      final String? resolvedCategoryId = _resolveCategorySelection(categories, false);

      MenuDetailViewData? detail = state.detail;
      String? detailId = state.selectedMenuId;
      if (detailId != null) {
        final MenuItemViewData? updated = _findMenuItemView(items, detailId);
        if (updated == null) {
          detail = null;
          detailId = null;
        } else {
          detail = detail?.copyWith(menu: updated);
        }
      }

      state = state.copyWith(
        categories: categories,
        menuItems: items,
        setSelectedCategory: true,
        selectedCategoryId: resolvedCategoryId,
        setDetail: detail != null,
        detail: detail,
        clearDetail: detail == null,
        setSelectedMenu: true,
        selectedMenuId: detailId,
        clearError: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
    }
  }

  String _buildAvailabilityLabel(
    MenuItemViewData menu,
    MenuAvailabilityInfo? info,
    int maxServings,
  ) {
    if (!menu.isAvailable) {
      return "販売停止中";
    }
    if (info == null) {
      return menu.isStockAvailable ? "在庫情報未取得" : "提供不可";
    }
    if (!info.isAvailable) {
      return info.missingMaterials.isEmpty ? "提供不可" : "在庫不足";
    }
    if (maxServings > 0) {
      return "最大提供可能数: $maxServings";
    }
    if (info.estimatedServings != null) {
      return "提供可能 (推定${info.estimatedServings}食)";
    }
    return "提供可能";
  }
}
