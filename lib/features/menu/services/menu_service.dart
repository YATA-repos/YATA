import "dart:math" as math;

import "../../../core/constants/exceptions.dart";
import "../../../core/constants/log_enums/menu.dart";
import "../../../core/utils/logger_mixin.dart";
import "../../../core/validation/input_validator.dart";
import "../../inventory/dto/inventory_dto.dart";
import "../../inventory/models/inventory_model.dart";
import "../../inventory/repositories/material_repository.dart";
import "../../inventory/repositories/recipe_repository.dart";
import "../dto/menu_dto.dart";
import "../models/menu_model.dart";
import "../repositories/menu_category_repository.dart";
import "../repositories/menu_item_repository.dart";

class MenuService with LoggerMixin {
  MenuService({
    MenuItemRepository? menuItemRepository,
    MenuCategoryRepository? menuCategoryRepository,
    MaterialRepository? materialRepository,
    RecipeRepository? recipeRepository,
  }) : _menuItemRepository = menuItemRepository ?? MenuItemRepository(),
       _menuCategoryRepository = menuCategoryRepository ?? MenuCategoryRepository(),
       _materialRepository = materialRepository ?? MaterialRepository(),
       _recipeRepository = recipeRepository ?? RecipeRepository();

  final MenuItemRepository _menuItemRepository;
  final MenuCategoryRepository _menuCategoryRepository;
  final MaterialRepository _materialRepository;
  final RecipeRepository _recipeRepository;

  @override
  String get loggerComponent => "MenuService";

  /// メニューカテゴリ一覧を取得
  Future<List<MenuCategory>> getMenuCategories(String userId) async =>
      _menuCategoryRepository.findActiveOrdered(userId);

  /// カテゴリ別メニューアイテム一覧を取得
  Future<List<MenuItem>> getMenuItemsByCategory(String? categoryId, String userId) async =>
      _menuItemRepository.findByCategoryId(categoryId, userId);

  /// メニューアイテムを検索
  Future<List<MenuItem>> searchMenuItems(String keyword, String userId) async {
    // 入力検証
    final List<ValidationResult> validationResults = <ValidationResult>[
      InputValidator.validateString(keyword, required: true, maxLength: 100, fieldName: "検索キーワード"),
      InputValidator.validateString(userId, required: true, fieldName: "ユーザーID"),
    ];

    // 検証エラーがある場合は例外を投げる
    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      throw ValidationException(InputValidator.getErrorMessages(errors));
    }

    logDebug("Started menu item search: keyword=\"$keyword\"");

    try {
      // まずユーザーのメニューアイテムを取得してから手動検索
      final List<MenuItem> userItems = await _menuItemRepository.findByCategoryId(null, userId);

      logDebug("Retrieved ${userItems.length} menu items for search");

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

      logDebug("Menu search completed: ${matchingItems.length} items found");
      return matchingItems;
    } catch (e, stackTrace) {
      logErrorMessage(MenuError.searchFailed, null, e, stackTrace);
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
      InputValidator.validateNumber(quantity, required: true, min: 1, max: 1000, fieldName: "数量"),
      InputValidator.validateString(userId, required: true, fieldName: "ユーザーID"),
    ];

    // 検証エラーがある場合は例外を投げる
    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      throw ValidationException(InputValidator.getErrorMessages(errors));
    }

    logDebug("Checking menu availability: quantity=$quantity");

    try {
      // メニューアイテムを取得
      final MenuItem? menuItem = await _menuItemRepository.getById(menuItemId);

      if (menuItem == null || menuItem.userId != userId) {
        logWarningMessage(MenuWarning.menuItemNotFound);
        return MenuAvailabilityInfo(
          menuItemId: menuItemId,
          isAvailable: false,
          missingMaterials: <String>["Menu item not found"],
          estimatedServings: 0,
        );
      }

      // メニューアイテムが無効になっている場合
      if (!menuItem.isAvailable) {
        logInfoMessage(MenuInfo.menuItemDisabled, <String, String>{"itemName": menuItem.name});
        return MenuAvailabilityInfo(
          menuItemId: menuItemId,
          isAvailable: false,
          missingMaterials: <String>["Menu item disabled"],
          estimatedServings: 0,
        );
      }

      // レシピを取得
      final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId, userId);

      if (recipes.isEmpty) {
        // レシピがない場合は作成可能とみなす
        logDebug(MenuDebug.noRecipesFound.message);
        return MenuAvailabilityInfo(
          menuItemId: menuItemId,
          isAvailable: true,
          missingMaterials: <String>[],
          estimatedServings: quantity,
        );
      }

      logDebug("Checking ${recipes.length} recipes for availability");

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
        logDebug(
          "Menu item not available: ${menuItem.name}, missing materials: ${missingMaterials.join(", ")}",
        );
      } else {
        logInfoMessage(MenuInfo.menuItemEnabled, <String, String>{
          "itemName": menuItem.name,
          "maxServings": maxServings.round().toString(),
        });
      }

      return MenuAvailabilityInfo(
        menuItemId: menuItemId,
        isAvailable: isAvailable,
        missingMaterials: missingMaterials,
        estimatedServings: maxServings.round(),
      );
    } catch (e, stackTrace) {
      logErrorMessage(MenuError.availabilityCheckFailed, null, e, stackTrace);
      rethrow;
    }
  }

  /// 在庫不足で販売不可なメニューアイテムIDを取得
  Future<List<String>> getUnavailableMenuItems(String userId) async {
    // 全メニューアイテムを取得
    final List<MenuItem> menuItems = await _menuItemRepository.findByCategoryId(null, userId);

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
    final List<MenuItem> menuItems = await _menuItemRepository.findByCategoryId(null, userId);

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

  /// 現在の在庫で作れる最大数を計算
  Future<int> calculateMaxServings(String menuItemId, String userId) async {
    // レシピを取得
    final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId, userId);

    if (recipes.isEmpty) {
      // レシピがない場合は無制限とみなす（実際には業務ルールに依存）
      // ! ここは要件に応じて調整が必要
      return 999999;
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
    final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId, userId);

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

    logInfoMessage(MenuInfo.toggleAvailabilityStarted, <String, String>{
      "isAvailable": isAvailable.toString(),
    });

    try {
      // メニューアイテムを取得
      final MenuItem? menuItem = await _menuItemRepository.getById(menuItemId);

      if (menuItem == null || menuItem.userId != userId) {
        logWarningMessage(MenuWarning.accessDenied);
        throw Exception("Menu item not found or access denied: $menuItemId");
      }

      // 可否状態を更新
      final Map<String, dynamic> updateData = <String, dynamic>{"is_available": isAvailable};

      // 更新
      final MenuItem? updatedItem = await _menuItemRepository.updateById(menuItemId, updateData);

      if (updatedItem != null) {
        logInfoMessage(MenuInfo.toggleAvailabilityCompleted, <String, String>{
          "itemName": menuItem.name,
          "status": isAvailable ? "available" : "unavailable",
        });
      } else {
        logDebug("Failed to update menu item availability: ${menuItem.name}");
      }

      return updatedItem;
    } catch (e, stackTrace) {
      logErrorMessage(MenuError.toggleAvailabilityFailed, null, e, stackTrace);
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
    logInfo("Started auto-updating menu availability by stock");

    try {
      // 全メニューアイテムの在庫状況をチェック
      final Map<String, MenuAvailabilityInfo> availabilityInfo = await bulkCheckMenuAvailability(
        userId,
      );

      logDebug("Checked availability for ${availabilityInfo.length} menu items");

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

      logDebug("Found ${updates.length} menu items requiring availability updates");

      // 一括更新
      if (updates.isNotEmpty) {
        results.addAll(await bulkUpdateMenuAvailability(updates, userId));
        logInfo("Auto-updated menu availability: ${results.length} items updated");
      } else {
        logInfo("No menu availability updates required");
      }

      return results;
    } catch (e, stackTrace) {
      logError("Failed to auto-update menu availability by stock", e, stackTrace);
      rethrow;
    }
  }
}
