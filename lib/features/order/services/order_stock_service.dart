import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/logging/logger_mixin.dart";
import "../../inventory/models/inventory_model.dart";
import "../../inventory/repositories/material_repository.dart";
import "../../inventory/repositories/recipe_repository.dart";
import "../models/order_model.dart";

/// 注文関連在庫操作サービス（在庫確認・材料消費・復元）
class OrderStockService with LoggerMixin {
  OrderStockService({
    required Ref ref,
    MaterialRepository? materialRepository,
    RecipeRepository? recipeRepository,
  }) : _materialRepository = materialRepository ?? MaterialRepository(ref: ref),
       _recipeRepository = recipeRepository ?? RecipeRepository(ref: ref);

  final MaterialRepository _materialRepository;
  final RecipeRepository _recipeRepository;

  @override
  String get loggerComponent => "OrderStockService";

  /// メニューアイテムの在庫充足を確認
  Future<bool> checkMenuItemStock(String menuItemId, int quantity) async {
    logDebug("Checking stock for menu item: $menuItemId, quantity: $quantity");

    try {
      // レシピを取得
      final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId);

      for (final Recipe recipe in recipes) {
        if (recipe.isOptional) {
          continue; // オプション材料は在庫確認不要
        }

        // 必要な材料量を計算
        final double requiredAmount = recipe.requiredAmount * quantity;

        // 材料の在庫を確認
        final Material? material = await _materialRepository.getById(recipe.materialId);
        if (material == null || material.currentStock < requiredAmount) {
          logWarning(
            "Insufficient stock for material: ${recipe.materialId}, required: $requiredAmount, available: ${material?.currentStock ?? 0}",
          );
          return false;
        }
      }

      logDebug("Stock check passed for menu item: $menuItemId");
      return true;
    } catch (e, stackTrace) {
      logError("Failed to check menu item stock", e, stackTrace);
      rethrow;
    }
  }

  /// カート内全商品の在庫を検証（戻り値: {order_item_id: 在庫充足フラグ}）
  Future<Map<String, bool>> validateCartStock(List<OrderItem> cartItems, ) async {
    logInfo("Started validating cart stock for ${cartItems.length} items");

    try {
      final Map<String, bool> stockValidation = <String, bool>{};
      int insufficientItems = 0;

      for (final OrderItem item in cartItems) {
        final bool isSufficient = await checkMenuItemStock(item.menuItemId, item.quantity);
        stockValidation[item.id!] = isSufficient;
        if (!isSufficient) {
          insufficientItems++;
        }
      }

      if (insufficientItems > 0) {
        logWarning("Stock validation found $insufficientItems items with insufficient stock");
      } else {
        logInfo("Cart stock validation completed: all items have sufficient stock");
      }

      return stockValidation;
    } catch (e, stackTrace) {
      logError("Failed to validate cart stock", e, stackTrace);
      rethrow;
    }
  }

  /// 注文に対する材料消費を実行
  Future<void> consumeMaterialsForOrder(List<OrderItem> orderItems, ) async {
    logInfo("Started consuming materials for order");

    try {
      final Map<String, double> materialConsumption = <String, double>{};

      // 必要な材料量を集計
      for (final OrderItem item in orderItems) {
        final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(
          item.menuItemId,
        );
        for (final Recipe recipe in recipes) {
          if (!recipe.isOptional) {
            final double requiredAmount = recipe.requiredAmount * item.quantity;
            materialConsumption[recipe.materialId] =
                (materialConsumption[recipe.materialId] ?? 0.0) + requiredAmount;
          }
        }
      }

      logDebug(
        "Material consumption calculated: ${materialConsumption.length} materials to consume",
      );

      // 材料在庫を消費
      for (final MapEntry<String, double> entry in materialConsumption.entries) {
        final String materialId = entry.key;
        final double consumedAmount = entry.value;

        final Material? material = await _materialRepository.getById(materialId);
        if (material != null) {
          final double newStock = material.currentStock - consumedAmount;
          await _materialRepository.updateStockAmount(materialId, newStock);
          logDebug("Material consumed: $materialId, amount: $consumedAmount, newStock: $newStock");
        }
      }

      logInfo("Materials consumed successfully for order");
    } catch (e, stackTrace) {
      logError("Failed to consume materials for order", e, stackTrace);
      rethrow;
    }
  }

  /// 注文キャンセル時の材料在庫復元
  Future<void> restoreMaterialsFromOrder(List<OrderItem> orderItems, ) async {
    logInfo("Started restoring materials from canceled order");

    try {
      final Map<String, double> materialRestoration = <String, double>{};

      // 復元する材料量を集計
      for (final OrderItem item in orderItems) {
        final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(
          item.menuItemId,
        );
        for (final Recipe recipe in recipes) {
          if (!recipe.isOptional) {
            final double restoredAmount = recipe.requiredAmount * item.quantity;
            materialRestoration[recipe.materialId] =
                (materialRestoration[recipe.materialId] ?? 0.0) + restoredAmount;
          }
        }
      }

      logDebug(
        "Material restoration calculated: ${materialRestoration.length} materials to restore",
      );

      // 材料在庫を復元
      for (final MapEntry<String, double> entry in materialRestoration.entries) {
        final String materialId = entry.key;
        final double restoredAmount = entry.value;

        final Material? material = await _materialRepository.getById(materialId);
        if (material != null) {
          final double newStock = material.currentStock + restoredAmount;
          await _materialRepository.updateStockAmount(materialId, newStock);
          logDebug("Material restored: $materialId, amount: $restoredAmount, newStock: $newStock");
        }
      }

      logInfo("Materials restored successfully from canceled order");
    } catch (e, stackTrace) {
      logError("Failed to restore materials from order", e, stackTrace);
      rethrow;
    }
  }
}
