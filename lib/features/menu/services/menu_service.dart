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
    } catch (e) {
      log.e("Failed to stop menu realtime monitoring", tag: loggerComponent, error: e);
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

    log.d("Started menu item search: keyword=\"$keyword\"", tag: loggerComponent);

    try {
      // まずユーザーのメニューアイテムを取得してから手動検索
      final List<MenuItem> userItems = await _menuItemRepository.findByCategoryId(null);

      log.d("Retrieved ${userItems.length} menu items for search", tag: loggerComponent);

      // 手動でキーワード検索（Supabaseの制限回避）
      final List<MenuItem> matchingItems = <MenuItem>[];
      for (final MenuItem item in userItems) {
        if (keyword.toLowerCase().isNotEmpty &&
            (item.name.toLowerCase().contains(keyword.toLowerCase()) ||
                (item.description != null &&
                    item.description!.toLowerCase().contains(keyword.toLowerCase())))) {
          matchingItems.add(item);
        }
      }

      log.d("Menu search completed: ${matchingItems.length} items found", tag: loggerComponent);
      return matchingItems;
    } catch (e, stackTrace) {
      log.e(MenuError.searchFailed.message, tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
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

    log.d("Checking menu availability: quantity=$quantity", tag: loggerComponent);

    try {
      // メニューアイテムを取得
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

      // メニューアイテムが無効になっている場合
      if (!menuItem.isAvailable) {
        log.i(
          MenuInfo.menuItemDisabled.withParams(<String, String>{"itemName": menuItem.name}),
          tag: loggerComponent,
        );
        return MenuAvailabilityInfo(
          menuItemId: menuItemId,
          isAvailable: false,
          missingMaterials: <String>["Menu item disabled"],
          estimatedServings: 0,
        );
      }

      // レシピを取得
      final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId);

      if (recipes.isEmpty) {
        // レシピがない場合は作成可能とみなす
        log.d(MenuDebug.noRecipesFound.message, tag: loggerComponent);
        return MenuAvailabilityInfo(
          menuItemId: menuItemId,
          isAvailable: true,
          missingMaterials: <String>[],
          estimatedServings: quantity,
        );
      }

      log.d("Checking ${recipes.length} recipes for availability", tag: loggerComponent);

      final List<String> missingMaterials = <String>[];
      double maxServings = double.infinity;

      for (final Recipe recipe in recipes) {
        // 材料を取得
        final Material? material = await _materialRepository.getById(recipe.materialId);

        if (material == null || material.userId != userId) {
          continue;
        }

        final double requiredAmount = recipe.requiredAmount * quantity;
        final double availableAmount = material.currentStock;

        if (!recipe.isOptional && availableAmount < requiredAmount) {
          missingMaterials.add(material.name);
        }

        // 最大作成可能数を計算
        if (!recipe.isOptional && recipe.requiredAmount > 0) {
          final int possibleServings = (availableAmount / recipe.requiredAmount).floor();
          maxServings = maxServings == double.infinity
              ? possibleServings.toDouble()
              : math.min(maxServings, possibleServings.toDouble());
        }
      }

      if (maxServings == double.infinity) {
        maxServings = quantity.toDouble();
      }

      final bool isAvailable = missingMaterials.isEmpty && maxServings >= quantity;

      if (!isAvailable) {
        log.d(
          "Menu item not available: ${menuItem.name}, missing materials: ${missingMaterials.join(", ")}",
          tag: loggerComponent,
        );
      } else {
        log.i(
          MenuInfo.menuItemEnabled.withParams(<String, String>{
            "itemName": menuItem.name,
            "maxServings": maxServings.round().toString(),
          }),
          tag: loggerComponent,
        );
      }

      return MenuAvailabilityInfo(
        menuItemId: menuItemId,
        isAvailable: isAvailable,
        missingMaterials: missingMaterials,
        estimatedServings: maxServings.round(),
      );
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
    // 全メニューアイテムを取得
    final List<MenuItem> menuItems = await _menuItemRepository.findByCategoryId(null);

    final List<String> unavailableItems = <String>[];

    for (final MenuItem menuItem in menuItems) {
      if (!menuItem.isAvailable) {
        unavailableItems.add(menuItem.id!);
        continue;
      }

      // 在庫チェック
      final MenuAvailabilityInfo availability = await checkMenuAvailability(
        menuItem.id!,
        1,
        userId,
      );
      if (!availability.isAvailable) {
        unavailableItems.add(menuItem.id!);
      }
    }

    return unavailableItems;
  }

  /// 全メニューアイテムの在庫可否を一括チェック
  Future<Map<String, MenuAvailabilityInfo>> bulkCheckMenuAvailability(String userId) async {
    // 全メニューアイテムを取得
    final List<MenuItem> menuItems = await _menuItemRepository.findByCategoryId(null);

    final Map<String, MenuAvailabilityInfo> availabilityInfo = <String, MenuAvailabilityInfo>{};

    for (final MenuItem menuItem in menuItems) {
      final MenuAvailabilityInfo availability = await checkMenuAvailability(
        menuItem.id!,
        1,
        userId,
      );
      availabilityInfo[menuItem.id!] = availability;
    }

    return availabilityInfo;
  }

  /// レシピがないメニューアイテムの最大提供可能数（業務ルールによる制限）
  static const int _maxServingsWithoutRecipe = 1000;

  /// 現在の在庫で作れる最大数を計算
  Future<int> calculateMaxServings(String menuItemId, String userId) async {
    // レシピを取得
    final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId);

    if (recipes.isEmpty) {
      // レシピがない場合は業務ルールに基づく上限値を返す
      // 小規模店舗向けの合理的な上限として1000個を設定
      return _maxServingsWithoutRecipe;
    }

    double maxServings = double.infinity;

    for (final Recipe recipe in recipes) {
      if (recipe.isOptional) {
        continue;
      }

      // 材料を取得
      final Material? material = await _materialRepository.getById(recipe.materialId);

      if (material == null || material.userId != userId) {
        continue;
      }

      if (recipe.requiredAmount > 0) {
        final int possibleServings = (material.currentStock / recipe.requiredAmount).floor();
        maxServings = maxServings == double.infinity
            ? possibleServings.toDouble()
            : math.min(maxServings, possibleServings.toDouble());
      }
    }

    return maxServings == double.infinity ? 0 : maxServings.round();
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
      // 全メニューアイテムの在庫状況をチェック
      final Map<String, MenuAvailabilityInfo> availabilityInfo = await bulkCheckMenuAvailability(
        userId,
      );

      log.d("Checked availability for ${availabilityInfo.length} menu items", tag: loggerComponent);

      final Map<String, bool> updates = <String, bool>{};
      final Map<String, bool> results = <String, bool>{};

      for (final MapEntry<String, MenuAvailabilityInfo> entry in availabilityInfo.entries) {
        final String menuItemId = entry.key;
        final MenuAvailabilityInfo info = entry.value;

        // 在庫に基づく可否状態を決定
        final bool shouldBeAvailable = info.isAvailable && (info.estimatedServings ?? 0) > 0;

        // 現在のメニューアイテムを取得して状態比較
        final MenuItem? menuItem = await _menuItemRepository.getById(menuItemId);

        if (menuItem != null && menuItem.isAvailable != shouldBeAvailable) {
          updates[menuItemId] = shouldBeAvailable;
        }
      }

      log.d(
        "Found ${updates.length} menu items requiring availability updates",
        tag: loggerComponent,
      );

      // 一括更新
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
}

// Providerは app/wiring/provider.dart 側で合成し公開する
