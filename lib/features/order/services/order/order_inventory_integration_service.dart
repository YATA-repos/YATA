import "../../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../../core/contracts/repositories/inventory/material_repository_contract.dart";
import "../../../../core/contracts/repositories/inventory/recipe_repository_contract.dart";
import "../../../inventory/models/inventory_model.dart";
import "../../models/order_model.dart";

/// 注文と在庫ドメインの連携を担うサービス（在庫確認・材料消費・復元）
class OrderInventoryIntegrationService {
  OrderInventoryIntegrationService({
    required log_contract.LoggerContract logger,
    required MaterialRepositoryContract<Material> materialRepository,
    required RecipeRepositoryContract<Recipe> recipeRepository,
  }) : _logger = logger,
       _materialRepository = materialRepository,
       _recipeRepository = recipeRepository;

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final MaterialRepositoryContract<Material> _materialRepository;
  final RecipeRepositoryContract<Recipe> _recipeRepository;

  String get loggerComponent => "OrderInventoryIntegrationService";

  /// メニューアイテムの在庫充足を確認
  Future<bool> checkMenuItemStock(String menuItemId, int quantity) async {
    log.d(
      "Checking stock for menu item: $menuItemId, quantity: $quantity",
      tag: loggerComponent,
    );

    try {
      final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId);

      for (final Recipe recipe in recipes) {
        if (recipe.isOptional) {
          continue;
        }

        final double requiredAmount = recipe.requiredAmount * quantity;
        final Material? material = await _materialRepository.getById(recipe.materialId);
        if (material == null || material.currentStock < requiredAmount) {
          log.w(
            "Insufficient stock for material: ${recipe.materialId}, required: $requiredAmount, available: ${material?.currentStock ?? 0}",
            tag: loggerComponent,
          );
          return false;
        }
      }

      log.d("Stock check passed for menu item: $menuItemId", tag: loggerComponent);
      return true;
    } catch (e, stackTrace) {
      log.e(
        "Failed to check menu item stock",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// カート内全商品の在庫を検証（戻り値: {order_item_id: 在庫充足フラグ}）
  Future<Map<String, bool>> validateCartStock(List<OrderItem> cartItems) async {
    log.i(
      "Started validating cart stock for ${cartItems.length} items",
      tag: loggerComponent,
    );

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
        log.w(
          "Stock validation found $insufficientItems items with insufficient stock",
          tag: loggerComponent,
        );
      } else {
        log.i(
          "Cart stock validation completed: all items have sufficient stock",
          tag: loggerComponent,
        );
      }

      return stockValidation;
    } catch (e, stackTrace) {
      log.e(
        "Failed to validate cart stock",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 注文に対する材料消費を実行
  Future<void> consumeMaterialsForOrder(List<OrderItem> orderItems) async {
    log.i("Started consuming materials for order", tag: loggerComponent);

    try {
      final Map<String, double> materialConsumption = <String, double>{};

      for (final OrderItem item in orderItems) {
        final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(item.menuItemId);
        for (final Recipe recipe in recipes) {
          if (!recipe.isOptional) {
            final double requiredAmount = recipe.requiredAmount * item.quantity;
            materialConsumption[recipe.materialId] =
                (materialConsumption[recipe.materialId] ?? 0.0) + requiredAmount;
          }
        }
      }

      log.d(
        "Material consumption calculated: ${materialConsumption.length} materials to consume",
        tag: loggerComponent,
      );

      for (final MapEntry<String, double> entry in materialConsumption.entries) {
        final String materialId = entry.key;
        final double consumedAmount = entry.value;

        final Material? material = await _materialRepository.getById(materialId);
        if (material != null) {
          final double newStock = material.currentStock - consumedAmount;
          await _materialRepository.updateStockAmount(materialId, newStock);
          log.d(
            "Material consumed: $materialId, amount: $consumedAmount, newStock: $newStock",
            tag: loggerComponent,
          );
        }
      }

      log.i("Materials consumed successfully for order", tag: loggerComponent);
    } catch (e, stackTrace) {
      log.e(
        "Failed to consume materials for order",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 注文キャンセル時の材料在庫復元
  Future<void> restoreMaterialsFromOrder(List<OrderItem> orderItems) async {
    log.i("Started restoring materials from canceled order", tag: loggerComponent);

    try {
      final Map<String, double> materialRestoration = <String, double>{};

      for (final OrderItem item in orderItems) {
        final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(item.menuItemId);
        for (final Recipe recipe in recipes) {
          if (!recipe.isOptional) {
            final double restoredAmount = recipe.requiredAmount * item.quantity;
            materialRestoration[recipe.materialId] =
                (materialRestoration[recipe.materialId] ?? 0.0) + restoredAmount;
          }
        }
      }

      log.d(
        "Material restoration calculated: ${materialRestoration.length} materials to restore",
        tag: loggerComponent,
      );

      for (final MapEntry<String, double> entry in materialRestoration.entries) {
        final String materialId = entry.key;
        final double restoredAmount = entry.value;

        final Material? material = await _materialRepository.getById(materialId);
        if (material != null) {
          final double newStock = material.currentStock + restoredAmount;
          await _materialRepository.updateStockAmount(materialId, newStock);
          log.d(
            "Material restored: $materialId, amount: $restoredAmount, newStock: $newStock",
            tag: loggerComponent,
          );
        }
      }

      log.i("Materials restored successfully from canceled order", tag: loggerComponent);
    } catch (e, stackTrace) {
      log.e(
        "Failed to restore materials from order",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }
}
