import "dart:math" as math;

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/base/base_error_msg.dart";
import "../../../core/constants/constants.dart";
import "../../../core/contracts/realtime/realtime_manager.dart" as r_contract;
import "../../../core/contracts/repositories/inventory/material_repository_contract.dart";
import "../../../core/contracts/repositories/inventory/recipe_repository_contract.dart";
import "../../../core/contracts/repositories/menu/menu_repository_contracts.dart";
// Removed LoggerComponent mixin; use local tag
import "../../../core/logging/compat.dart" as log;
import "../../../core/realtime/realtime_service_mixin.dart";
import "../../../core/validation/input_validator.dart";
import "../../auth/presentation/providers/auth_providers.dart";
import "../../inventory/dto/inventory_dto.dart";
import "../../inventory/models/inventory_model.dart";
import "../dto/menu_dto.dart";
import "../models/menu_model.dart";

/// メニュー機能のリアルタイムイベントをUI層へ伝搬するためのカウンタープロバイダー。
final StateProvider<int> menuRealtimeEventCounterProvider = StateProvider<int>((Ref ref) => 0);

typedef _AvailabilityContext = ({
  Map<String, List<Recipe>> recipesByMenuItemId,
  Map<String, Material> materialIndex,
});

class MenuService with RealtimeServiceContractMixin implements RealtimeServiceControl {
  MenuService({
    required Ref ref,
    required r_contract.RealtimeManagerContract realtimeManager,
    required MenuItemRepositoryContract<MenuItem> menuItemRepository,
    required MenuCategoryRepositoryContract<MenuCategory> menuCategoryRepository,
    required MaterialRepositoryContract<Material> materialRepository,
    required RecipeRepositoryContract<Recipe> recipeRepository,
  }) : _ref = ref,
       _realtimeManager = realtimeManager,
       _menuItemRepository = menuItemRepository,
       _menuCategoryRepository = menuCategoryRepository,
       _materialRepository = materialRepository,
       _recipeRepository = recipeRepository;

  final Ref _ref;
  final MenuItemRepositoryContract<MenuItem> _menuItemRepository;
  final MenuCategoryRepositoryContract<MenuCategory> _menuCategoryRepository;
  final MaterialRepositoryContract<Material> _materialRepository;
  final RecipeRepositoryContract<Recipe> _recipeRepository;
  final r_contract.RealtimeManagerContract _realtimeManager;

  String get loggerComponent => "MenuService";

  // 契約Mixin用の依存提供
  @override
  r_contract.RealtimeManagerContract get realtimeManager => _realtimeManager;

  @override
  String? get currentUserId => _ref.read(currentUserIdProvider);

  // ===== Realtime: メニュー・カテゴリの監視 =====
  @override
  Future<void> enableRealtimeFeatures() async => startRealtimeMonitoring();

  @override
  Future<void> disableRealtimeFeatures() async => stopRealtimeMonitoring();

  @override
  bool isFeatureRealtimeEnabled(String featureName) => isMonitoringFeature(featureName);

  @override
  bool isRealtimeConnected() => isRealtimeHealthy();

  @override
  Map<String, dynamic> getRealtimeInfo() => getRealtimeStats();

  Future<void> startRealtimeMonitoring() async {
    try {
      log.i("Starting menu realtime monitoring", tag: loggerComponent);
      await startFeatureMonitoring(
        "menu",
        "menu_items",
        _handleMenuItemUpdate,
        eventTypes: const <String>["INSERT", "UPDATE", "DELETE"],
      );
      await startFeatureMonitoring(
        "menu",
        "menu_categories",
        _handleMenuCategoryUpdate,
        eventTypes: const <String>["INSERT", "UPDATE", "DELETE"],
      );
      log.i("Menu realtime monitoring started", tag: loggerComponent);
    } catch (e) {
      log.e("Failed to start menu realtime monitoring", tag: loggerComponent, error: e);
      rethrow;
    }
  }

  Future<void> stopRealtimeMonitoring() async {
    try {
      log.i("Stopping menu realtime monitoring", tag: loggerComponent);
      await stopFeatureMonitoring("menu");
      log.i("Menu realtime monitoring stopped", tag: loggerComponent);
    } catch (e, stackTrace) {
      final String errorText = e.toString();
      if (e is StateError &&
          errorText.contains("ProviderContainer") &&
          errorText.contains("already disposed")) {
        log.w(
          "Provider container disposed before realtime monitoring teardown completed: $errorText",
          tag: loggerComponent,
        );
        return;
      }
      log.e(
        "Failed to stop menu realtime monitoring",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  void _handleMenuItemUpdate(Map<String, dynamic> data) {
    final String eventType = data["event_type"] as String? ?? "unknown";
    final Map<String, dynamic>? newRecord = data["new_record"] as Map<String, dynamic>?;
    final Map<String, dynamic>? oldRecord = data["old_record"] as Map<String, dynamic>?;
    log.d(
      "MenuItem event: $eventType",
      tag: loggerComponent,
      fields: <String, dynamic>{"item": newRecord ?? oldRecord},
    );
    _notifyRealtimeUpdate("menu_items");
  }

  void _handleMenuCategoryUpdate(Map<String, dynamic> data) {
    final String eventType = data["event_type"] as String? ?? "unknown";
    final Map<String, dynamic>? newRecord = data["new_record"] as Map<String, dynamic>?;
    final Map<String, dynamic>? oldRecord = data["old_record"] as Map<String, dynamic>?;
    log.d(
      "MenuCategory event: $eventType",
      tag: loggerComponent,
      fields: <String, dynamic>{"category": newRecord ?? oldRecord},
    );
    _notifyRealtimeUpdate("menu_categories");
  }

  /// メニューカテゴリを作成する。
  Future<MenuCategory> createCategory({required String name, required int displayOrder}) async {
    final MenuCategory category = MenuCategory(name: name, displayOrder: displayOrder);
    try {
      final MenuCategory? created = await _menuCategoryRepository.create(category);
      if (created == null) {
        throw Exception("Failed to create menu category");
      }
      log.i("Created menu category: ${created.name}", tag: loggerComponent);
      return created;
    } catch (error, stackTrace) {
      log.e("Failed to create menu category", tag: loggerComponent, error: error, st: stackTrace);
      rethrow;
    }
  }

  /// メニューカテゴリを更新する。
  Future<MenuCategory?> updateCategory(String id, {String? name, int? displayOrder}) async {
    final Map<String, dynamic> updates = <String, dynamic>{};
    if (name != null) {
      updates["name"] = name;
    }
    if (displayOrder != null) {
      updates["display_order"] = displayOrder;
    }

    if (updates.isEmpty) {
      return _menuCategoryRepository.getById(id);
    }

    try {
      final MenuCategory? updated = await _menuCategoryRepository.updateById(id, updates);
      if (updated != null) {
        log.i("Updated menu category: ${updated.name}", tag: loggerComponent);
      }
      return updated;
    } catch (error, stackTrace) {
      log.e("Failed to update menu category", tag: loggerComponent, error: error, st: stackTrace);
      rethrow;
    }
  }

  /// メニューカテゴリを削除する。
  Future<void> deleteCategory(String id) async {
    try {
      await _menuCategoryRepository.deleteById(id);
      log.i("Deleted menu category: $id", tag: loggerComponent);
    } catch (error, stackTrace) {
      log.e("Failed to delete menu category", tag: loggerComponent, error: error, st: stackTrace);
      rethrow;
    }
  }

  /// 表示順を更新する。
  Future<void> updateCategoryOrder(List<MenuCategory> categories) async {
    try {
      for (final MenuCategory category in categories) {
        if (category.id == null) {
          continue;
        }
        await _menuCategoryRepository.updateById(category.id!, <String, dynamic>{
          "display_order": category.displayOrder,
        });
      }
      log.i("Updated category ordering (${categories.length} entries)", tag: loggerComponent);
    } catch (error, stackTrace) {
      log.e(
        "Failed to update category ordering",
        tag: loggerComponent,
        error: error,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// メニューアイテムを作成する。
  Future<MenuItem> createMenuItem({
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required int estimatedPrepTimeMinutes,
    required int displayOrder,
    String? description,
    String? imageUrl,
  }) async {
    final MenuItem item = MenuItem(
      name: name,
      categoryId: categoryId,
      price: price,
      isAvailable: isAvailable,
      estimatedPrepTimeMinutes: estimatedPrepTimeMinutes,
      displayOrder: displayOrder,
      description: description,
      imageUrl: imageUrl,
    );
    try {
      final MenuItem? created = await _menuItemRepository.create(item);
      if (created == null) {
        throw Exception("Failed to create menu item");
      }
      log.i("Created menu item: ${created.name}", tag: loggerComponent);
      return created;
    } catch (error, stackTrace) {
      log.e("Failed to create menu item", tag: loggerComponent, error: error, st: stackTrace);
      rethrow;
    }
  }

  /// メニューアイテムを更新する。
  Future<MenuItem?> updateMenuItem(
    String id, {
    String? name,
    String? categoryId,
    int? price,
    String? description,
    bool? isAvailable,
    int? estimatedPrepTimeMinutes,
    int? displayOrder,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> updates = <String, dynamic>{};
    if (name != null) {
      updates["name"] = name;
    }
    if (categoryId != null) {
      updates["category_id"] = categoryId;
    }
    if (price != null) {
      updates["price"] = price;
    }
    if (description != null) {
      updates["description"] = description;
    }
    if (isAvailable != null) {
      updates["is_available"] = isAvailable;
    }
    if (estimatedPrepTimeMinutes != null) {
      updates["estimated_prep_time_minutes"] = estimatedPrepTimeMinutes;
    }
    if (displayOrder != null) {
      updates["display_order"] = displayOrder;
    }
    if (imageUrl != null) {
      updates["image_url"] = imageUrl;
    }

    if (updates.isEmpty) {
      return _menuItemRepository.getById(id);
    }

    try {
      final MenuItem? updated = await _menuItemRepository.updateById(id, updates);
      if (updated != null) {
        log.i("Updated menu item: ${updated.name}", tag: loggerComponent);
      }
      return updated;
    } catch (error, stackTrace) {
      log.e("Failed to update menu item", tag: loggerComponent, error: error, st: stackTrace);
      rethrow;
    }
  }

  /// メニューアイテムを削除する。
  Future<void> deleteMenuItem(String id) async {
    try {
      await _menuItemRepository.deleteById(id);
      log.i("Deleted menu item: $id", tag: loggerComponent);
    } catch (error, stackTrace) {
      log.e("Failed to delete menu item", tag: loggerComponent, error: error, st: stackTrace);
      rethrow;
    }
  }

  /// リアルタイム更新をUI層へ通知する。
  void _notifyRealtimeUpdate(String featureName) {
    final StateController<int> controller = _ref.read(menuRealtimeEventCounterProvider.notifier);
    controller.state = controller.state + 1;
    log.t("Menu realtime event propagated: $featureName", tag: loggerComponent);
  }

  /// メニューカテゴリ一覧を取得
  Future<List<MenuCategory>> getMenuCategories() async =>
      _menuCategoryRepository.findActiveOrdered();

  /// カテゴリ別メニューアイテム一覧を取得
  Future<List<MenuItem>> getMenuItemsByCategory(String? categoryId) async =>
      _menuItemRepository.findByCategoryId(categoryId);

  /// メニューアイテムを検索
  Future<List<MenuItem>> searchMenuItems(String keyword, String userId) async {
    // 入力検証
    final List<ValidationResult> validationResults = <ValidationResult>[
      InputValidator.validateString(
        keyword,
        required: true,
        maxLength: AppConfig.maxItemNameLength,
        fieldName: "検索キーワード",
      ),
      InputValidator.validateString(userId, required: true, fieldName: "ユーザーID"),
    ];

    // 検証エラーがある場合は例外を投げる
    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      throw ValidationException(InputValidator.getErrorMessages(errors));
    }

    log.d(
      MenuDebug.menuSearchStarted.withParams(<String, String>{"keyword": keyword}),
      tag: loggerComponent,
    );

    try {
      final List<MenuItem> results = await _menuItemRepository.searchByName(keyword);

      log.d(
        MenuDebug.menuSearchCompleted.withParams(<String, String>{
          "itemCount": results.length.toString(),
        }),
        tag: loggerComponent,
      );

      return results;
    } catch (e, stackTrace) {
      log.w(
        "Falling back to manual search due to repository failure: $e",
        tag: loggerComponent,
      );
      log.t(stackTrace.toString(), tag: loggerComponent);

      final List<MenuItem> fallbackResults = await _searchMenuItemsFallback(keyword);

      log.d(
        MenuDebug.menuSearchCompleted.withParams(<String, String>{
          "itemCount": fallbackResults.length.toString(),
        }),
        tag: loggerComponent,
      );

      return fallbackResults;
    }
  }

  /// メニューアイテムの在庫可否を詳細チェック
  Future<MenuAvailabilityInfo> checkMenuAvailability(
    String menuItemId,
    int quantity,
    String userId,
  ) async {
    // 入力検証
    final List<ValidationResult> validationResults = <ValidationResult>[
      InputValidator.validateString(menuItemId, required: true, fieldName: "メニューアイテムID"),
      InputValidator.validateNumber(
        quantity,
        required: true,
        min: AppConfig.minQuantity,
        max: AppConfig.maxQuantity,
        fieldName: "数量",
      ),
      InputValidator.validateString(userId, required: true, fieldName: "ユーザーID"),
    ];

    // 検証エラーがある場合は例外を投げる
    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      throw ValidationException(InputValidator.getErrorMessages(errors));
    }

    log.d(
      MenuDebug.availabilityCheckStarted.withParams(<String, String>{
        "quantity": quantity.toString(),
      }),
      tag: loggerComponent,
    );

    try {
      final MenuItem? menuItem = await _menuItemRepository.getById(menuItemId);

      if (menuItem == null || menuItem.userId != userId) {
        log.w(MenuWarning.menuItemNotFound.message, tag: loggerComponent);
        return MenuAvailabilityInfo(
          menuItemId: menuItemId,
          isAvailable: false,
          missingMaterials: <String>["Menu item not found"],
          estimatedServings: 0,
        );
      }

      if (!menuItem.isAvailable) {
        log.i(
          MenuInfo.menuItemDisabled.withParams(<String, String>{"itemName": menuItem.name}),
          tag: loggerComponent,
        );
        return _buildDisabledAvailability(menuItemId);
      }

      final _AvailabilityContext context =
          await _buildAvailabilityContext(<String>[menuItemId]);
      final List<Recipe> recipes = context.recipesByMenuItemId[menuItemId] ?? <Recipe>[];

      if (recipes.isEmpty) {
        log.d(MenuDebug.noRecipesFound.message, tag: loggerComponent);
      } else {
        log.d(
          MenuDebug.recipesChecking.withParams(<String, String>{
            "recipeCount": recipes.length.toString(),
          }),
          tag: loggerComponent,
        );
      }

      final MenuAvailabilityInfo info = _buildAvailabilityForEnabledItem(
        menuItem: menuItem,
        recipes: recipes,
        materialIndex: context.materialIndex,
        quantity: quantity,
        userId: userId,
      );

      if (!info.isAvailable) {
        log.d(
          MenuDebug.insufficientStock.withParams(<String, String>{
            "itemName": menuItem.name,
            "missingMaterials": info.missingMaterials.join(", "),
          }),
          tag: loggerComponent,
        );
      } else {
        log.i(
          MenuInfo.menuItemEnabled.withParams(<String, String>{
            "itemName": menuItem.name,
            "maxServings": (info.estimatedServings ?? quantity).toString(),
          }),
          tag: loggerComponent,
        );
      }

      return info;
    } catch (e, stackTrace) {
      log.e(
        MenuError.availabilityCheckFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 在庫不足で販売不可なメニューアイテムIDを取得
  Future<List<String>> getUnavailableMenuItems(String userId) async {
    final List<MenuItem> menuItems = await _menuItemRepository.findByCategoryId(null);
    final List<MenuItem> itemsWithId =
        menuItems.where((MenuItem item) => item.id != null).toList(growable: false);

    if (itemsWithId.isEmpty) {
      return <String>[];
    }

    final Map<String, MenuAvailabilityInfo> availabilityMap =
        await _evaluateAvailabilityForMenuItems(itemsWithId, userId);

    final List<String> unavailableItems = <String>[];

    for (final MenuItem menuItem in itemsWithId) {
      final String id = menuItem.id!;
      final MenuAvailabilityInfo? availability = availabilityMap[id];
      if (!menuItem.isAvailable || availability == null || !availability.isAvailable) {
        unavailableItems.add(id);
      }
    }

    return unavailableItems;
  }

  /// 全メニューアイテムの在庫可否を一括チェック
  Future<Map<String, MenuAvailabilityInfo>> bulkCheckMenuAvailability(
    String userId, {
    Iterable<String>? menuItemIds,
  }) async {
    List<MenuItem> menuItems;
    Set<String>? filterIds;

    if (menuItemIds == null) {
      menuItems = await _menuItemRepository.findByCategoryId(null);
    } else {
      filterIds = <String>{
        for (final String id in menuItemIds)
          if (id.isNotEmpty) id,
      };

      if (filterIds.isEmpty) {
        return <String, MenuAvailabilityInfo>{};
      }

      menuItems = await _menuItemRepository.findByIds(filterIds.toList(growable: false));
    }

    if (filterIds != null) {
      menuItems = menuItems
          .where((MenuItem item) => item.id != null && filterIds!.contains(item.id))
          .toList(growable: false);
    }

    if (menuItems.isEmpty) {
      return <String, MenuAvailabilityInfo>{};
    }

    return _evaluateAvailabilityForMenuItems(menuItems, userId);
  }

  /// レシピがないメニューアイテムの最大提供可能数（業務ルールによる制限）
  static const int _maxServingsWithoutRecipe = 1000;

  /// 現在の在庫で作れる最大数を計算
  Future<int> calculateMaxServings(String menuItemId, String userId) async {
    final _AvailabilityContext context =
        await _buildAvailabilityContext(<String>[menuItemId]);
    final List<Recipe> recipes = context.recipesByMenuItemId[menuItemId] ?? <Recipe>[];

    if (recipes.isEmpty) {
      return _maxServingsWithoutRecipe;
    }

    double maxServings = double.infinity;

    for (final Recipe recipe in recipes) {
      if (recipe.isOptional) {
        continue;
      }

      final Material? material = context.materialIndex[recipe.materialId];
      if (material == null || material.userId != userId) {
        return 0;
      }

      if (recipe.requiredAmount > 0) {
        final double possibleServings = material.currentStock / recipe.requiredAmount;
        maxServings = maxServings.isFinite ? math.min(maxServings, possibleServings) : possibleServings;
      }
    }

    if (!maxServings.isFinite || maxServings <= 0) {
      return 0;
    }

    return maxServings.floor();
  }

  /// メニュー作成に必要な材料と使用量を計算
  Future<List<MaterialUsageCalculation>> getRequiredMaterialsForMenu(
    String menuItemId,
    int quantity,
    String userId,
  ) async {
    // レシピを取得
    final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId);

    final List<MaterialUsageCalculation> calculations = <MaterialUsageCalculation>[];

    for (final Recipe recipe in recipes) {
      // 材料を取得
      final Material? material = await _materialRepository.getById(recipe.materialId);

      if (material == null || material.userId != userId) {
        continue;
      }

      final double requiredAmount = recipe.requiredAmount * quantity;
      final double availableAmount = material.currentStock;
      final bool isSufficient = availableAmount >= requiredAmount;

      final MaterialUsageCalculation calculation = MaterialUsageCalculation(
        materialId: recipe.materialId,
        requiredAmount: requiredAmount,
        availableAmount: availableAmount,
        isSufficient: isSufficient,
      );
      calculations.add(calculation);
    }

    return calculations;
  }

  /// メニューアイテムの販売可否を切り替え
  Future<MenuItem?> toggleMenuItemAvailability(
    String menuItemId,
    bool isAvailable,
    String userId,
  ) async {
    // 入力検証
    final List<ValidationResult> validationResults = <ValidationResult>[
      InputValidator.validateString(menuItemId, required: true, fieldName: "メニューアイテムID"),
      InputValidator.validateString(userId, required: true, fieldName: "ユーザーID"),
    ];

    // 検証エラーがある場合は例外を投げる
    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      throw ValidationException(InputValidator.getErrorMessages(errors));
    }

    log.i(
      MenuInfo.toggleAvailabilityStarted.withParams(<String, String>{
        "isAvailable": isAvailable.toString(),
      }),
      tag: loggerComponent,
    );

    try {
      // メニューアイテムを取得
      final MenuItem? menuItem = await _menuItemRepository.getById(menuItemId);

      if (menuItem == null || menuItem.userId != userId) {
        log.w(MenuWarning.accessDenied.message, tag: loggerComponent);
        throw Exception("Menu item not found or access denied: $menuItemId");
      }

      // 可否状態を更新
      final Map<String, dynamic> updateData = <String, dynamic>{"is_available": isAvailable};

      // 更新
      final MenuItem? updatedItem = await _menuItemRepository.updateById(menuItemId, updateData);

      if (updatedItem != null) {
        log.i(
          MenuInfo.toggleAvailabilityCompleted.withParams(<String, String>{
            "itemName": menuItem.name,
            "status": isAvailable ? "available" : "unavailable",
          }),
          tag: loggerComponent,
        );
      } else {
        log.d("Failed to update menu item availability: ${menuItem.name}", tag: loggerComponent);
      }

      return updatedItem;
    } catch (e, stackTrace) {
      log.e(
        MenuError.toggleAvailabilityFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// メニューアイテムの販売可否を一括更新
  Future<Map<String, bool>> bulkUpdateMenuAvailability(
    Map<String, bool> availabilityUpdates,
    String userId,
  ) async {
    final Map<String, bool> results = <String, bool>{};

    for (final MapEntry<String, bool> entry in availabilityUpdates.entries) {
      try {
        await toggleMenuItemAvailability(entry.key, entry.value, userId);
        results[entry.key] = entry.value;
      } catch (e) {
        // アクセス権限がない場合はスキップ
        results[entry.key] = false;
      }
    }

    return results;
  }

  /// 在庫状況に基づいてメニューの販売可否を自動更新
  Future<Map<String, bool>> autoUpdateMenuAvailabilityByStock(String userId) async {
    log.i("Started auto-updating menu availability by stock", tag: loggerComponent);

    try {
      final List<MenuItem> menuItems = await _menuItemRepository.findByCategoryId(null);
      if (menuItems.isEmpty) {
        log.i("No menu items found for auto-update", tag: loggerComponent);
        return <String, bool>{};
      }

      final Map<String, MenuItem> menuItemIndex = <String, MenuItem>{
        for (final MenuItem item in menuItems)
          if (item.id != null) item.id!: item,
      };

      final Map<String, MenuAvailabilityInfo> availabilityInfo =
          await _evaluateAvailabilityForMenuItems(menuItems, userId);

      log.d("Checked availability for ${availabilityInfo.length} menu items", tag: loggerComponent);

      final Map<String, bool> updates = <String, bool>{};
      final Map<String, bool> results = <String, bool>{};

      for (final MapEntry<String, MenuAvailabilityInfo> entry in availabilityInfo.entries) {
        final MenuItem? menuItem = menuItemIndex[entry.key];
        if (menuItem == null) {
          continue;
        }

        final bool shouldBeAvailable =
            entry.value.isAvailable && (entry.value.estimatedServings ?? 0) > 0;

        if (menuItem.isAvailable != shouldBeAvailable) {
          updates[entry.key] = shouldBeAvailable;
        }
      }

      log.d(
        "Found ${updates.length} menu items requiring availability updates",
        tag: loggerComponent,
      );

      if (updates.isNotEmpty) {
        results.addAll(await bulkUpdateMenuAvailability(updates, userId));
        log.i(
          "Auto-updated menu availability: ${results.length} items updated",
          tag: loggerComponent,
        );
      } else {
        log.i("No menu availability updates required", tag: loggerComponent);
      }

      return results;
    } catch (e, stackTrace) {
      log.e(
        "Failed to auto-update menu availability by stock",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<MenuItem>> _searchMenuItemsFallback(String keyword) async {
    final String normalizedKeyword = keyword.toLowerCase();
    final List<MenuItem> userItems = await _menuItemRepository.findByCategoryId(null);

    log.d(
      MenuDebug.menuItemsRetrieved.withParams(<String, String>{
        "itemCount": userItems.length.toString(),
      }),
      tag: loggerComponent,
    );

    if (normalizedKeyword.isEmpty) {
      return userItems;
    }

    final List<MenuItem> matchingItems = <MenuItem>[];
    for (final MenuItem item in userItems) {
      final String name = item.name.toLowerCase();
      final String? description = item.description?.toLowerCase();
      if (name.contains(normalizedKeyword) || (description?.contains(normalizedKeyword) ?? false)) {
        matchingItems.add(item);
      }
    }

    return matchingItems;
  }

  MenuAvailabilityInfo _buildDisabledAvailability(String menuItemId) => MenuAvailabilityInfo(
    menuItemId: menuItemId,
    isAvailable: false,
    missingMaterials: const <String>["Menu item disabled"],
    estimatedServings: 0,
  );

  Future<Map<String, MenuAvailabilityInfo>> _evaluateAvailabilityForMenuItems(
    List<MenuItem> menuItems,
    String userId, {
    int quantity = 1,
  }) async {
    final List<MenuItem> itemsWithId =
        menuItems.where((MenuItem item) => item.id != null).toList(growable: false);

    if (itemsWithId.isEmpty) {
      return <String, MenuAvailabilityInfo>{};
    }

    final List<MenuItem> enabledItems =
        itemsWithId.where((MenuItem item) => item.isAvailable).toList(growable: false);

    final _AvailabilityContext context = await _buildAvailabilityContext(
      enabledItems.map((MenuItem item) => item.id!),
    );

    final Map<String, MenuAvailabilityInfo> availability = <String, MenuAvailabilityInfo>{};

    for (final MenuItem item in itemsWithId) {
      final String id = item.id!;
      if (!item.isAvailable) {
        availability[id] = _buildDisabledAvailability(id);
        continue;
      }

      final List<Recipe> recipes = context.recipesByMenuItemId[id] ?? <Recipe>[];
      availability[id] = _buildAvailabilityForEnabledItem(
        menuItem: item,
        recipes: recipes,
        materialIndex: context.materialIndex,
        quantity: quantity,
        userId: userId,
      );
    }

    return availability;
  }

  MenuAvailabilityInfo _buildAvailabilityForEnabledItem({
    required MenuItem menuItem,
    required List<Recipe> recipes,
    required Map<String, Material> materialIndex,
    required int quantity,
    required String userId,
  }) {
    final String? menuItemId = menuItem.id;
    if (menuItemId == null) {
      return MenuAvailabilityInfo(
        menuItemId: "",
        isAvailable: false,
        missingMaterials: const <String>["Menu item not found"],
        estimatedServings: 0,
      );
    }

    if (recipes.isEmpty) {
      return MenuAvailabilityInfo(
        menuItemId: menuItemId,
        isAvailable: true,
        missingMaterials: const <String>[],
        estimatedServings: quantity,
      );
    }

    final Set<String> missingMaterials = <String>{};
    double maxServings = double.infinity;

    for (final Recipe recipe in recipes) {
      final Material? material = materialIndex[recipe.materialId];

      if (material == null || material.userId != userId) {
        if (!recipe.isOptional) {
          missingMaterials.add(_describeMissingMaterial(material, recipe));
          maxServings = 0;
        }
        continue;
      }

      final double requiredAmount = recipe.requiredAmount * quantity;
      final double availableAmount = material.currentStock;

      if (!recipe.isOptional && availableAmount < requiredAmount) {
        missingMaterials.add(material.name);
      }

      if (!recipe.isOptional && recipe.requiredAmount > 0) {
        final double possibleServings = availableAmount / recipe.requiredAmount;
        maxServings = maxServings.isFinite ? math.min(maxServings, possibleServings) : possibleServings;
      }
    }

    if (!maxServings.isFinite) {
      maxServings = quantity.toDouble();
    }

    final bool isAvailable = missingMaterials.isEmpty && maxServings >= quantity;
    final int estimatedServings = math.max(0, maxServings.floor());

    return MenuAvailabilityInfo(
      menuItemId: menuItemId,
      isAvailable: isAvailable,
      missingMaterials: missingMaterials.toList(growable: false),
      estimatedServings: estimatedServings,
    );
  }

  Future<_AvailabilityContext> _buildAvailabilityContext(Iterable<String> menuItemIds) async {
    final Set<String> ids = <String>{
      for (final String id in menuItemIds)
        if (id.isNotEmpty) id,
    };

    if (ids.isEmpty) {
      return (
        recipesByMenuItemId: <String, List<Recipe>>{},
        materialIndex: <String, Material>{},
      );
    }

    final List<Recipe> recipes = await _recipeRepository.findByMenuItemIds(ids.toList());
    final Map<String, List<Recipe>> recipesByMenuItemId = <String, List<Recipe>>{};
    final Set<String> materialIds = <String>{};

    for (final Recipe recipe in recipes) {
      recipesByMenuItemId.putIfAbsent(recipe.menuItemId, () => <Recipe>[]).add(recipe);
      materialIds.add(recipe.materialId);
    }

    if (materialIds.isEmpty) {
      return (
        recipesByMenuItemId: recipesByMenuItemId,
        materialIndex: <String, Material>{},
      );
    }

    final List<Material> materials = await _materialRepository.findByIds(
      materialIds.toList(growable: false),
    );

    final Map<String, Material> materialIndex = <String, Material>{
      for (final Material material in materials)
        if (material.id != null) material.id!: material,
    };

    return (
      recipesByMenuItemId: recipesByMenuItemId,
      materialIndex: materialIndex,
    );
  }

  String _describeMissingMaterial(Material? material, Recipe recipe) {
    if (material == null) {
      return "Material not found (ID: ${recipe.materialId})";
    }
    return material.name;
  }
}

// Providerは app/wiring/provider.dart 側で合成し公開する
