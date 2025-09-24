import "dart:math" as math;

import "../../../core/base/base_error_msg.dart";
import "../../../core/constants/enums.dart";
import "../../../core/constants/log_enums/service.dart";
import "../../../core/contracts/repositories/inventory/material_repository_contract.dart";
import "../../../core/contracts/repositories/inventory/recipe_repository_contract.dart";
import "../../../core/contracts/repositories/inventory/stock_transaction_repository_contract.dart";
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
// Removed LoggerComponent mixin; use local tag
import "../../../core/logging/compat.dart" as log;
import "../../order/models/order_model.dart";
import "../models/inventory_model.dart";
import "../models/transaction_model.dart";

/// 注文関連在庫操作サービス
class OrderStockService {
  OrderStockService({
    required MaterialRepositoryContract<Material> materialRepository,
    required RecipeRepositoryContract<Recipe> recipeRepository,
    required StockTransactionRepositoryContract<StockTransaction> stockTransactionRepository,
    required OrderItemRepositoryContract<OrderItem> orderItemRepository,
  }) : _materialRepository = materialRepository,
       _recipeRepository = recipeRepository,
       _stockTransactionRepository = stockTransactionRepository,
       _orderItemRepository = orderItemRepository;

  final MaterialRepositoryContract<Material> _materialRepository;
  final RecipeRepositoryContract<Recipe> _recipeRepository;
  final StockTransactionRepositoryContract<StockTransaction> _stockTransactionRepository;
  final OrderItemRepositoryContract<OrderItem> _orderItemRepository;

  String get loggerComponent => "OrderStockService";

  /// 注文に対する材料を消費（在庫減算）
  Future<bool> consumeMaterialsForOrder(String orderId, String userId) async {
    log.i(ServiceInfo.materialConsumptionStarted.message, tag: loggerComponent);

    try {
      // 注文明細を取得
      final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);

      if (orderItems.isEmpty) {
        log.d(ServiceDebug.consumptionCompletedSuccessfully.message, tag: loggerComponent);
        return true; // 注文明細がない場合は成功とみなす
      }

      log.d(
        "Processing material consumption for ${orderItems.length} order items",
        tag: loggerComponent,
      );

      // 注文明細から必要な材料を計算
      final Map<String, double> materialRequirements = <String, double>{};

      for (final OrderItem orderItem in orderItems) {
        // メニューアイテムのレシピを取得
        final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(orderItem.menuItemId);

        for (final Recipe recipe in recipes) {
          // 必要量 = レシピの必要量 × 注文数量
          final double requiredAmount = recipe.requiredAmount * orderItem.quantity;
          materialRequirements[recipe.materialId] =
              (materialRequirements[recipe.materialId] ?? 0.0) + requiredAmount;
        }
      }

      log.d(
        "Material requirements calculated: ${materialRequirements.length} materials needed",
        tag: loggerComponent,
      );

      // 各材料の在庫を減算し、取引を記録
      final List<StockTransaction> transactions = <StockTransaction>[];
      int processedMaterials = 0;

      for (final MapEntry<String, double> entry in materialRequirements.entries) {
        final String materialId = entry.key;
        final double requiredAmount = entry.value;

        // 材料を取得
        final Material? material = await _materialRepository.getById(materialId);
        if (material == null) {
          continue;
        }

        final double oldStock = material.currentStock;
        // 在庫を減算
        final double newStock = material.currentStock - requiredAmount;
        material.currentStock = math.max(newStock, 0.0); // 負の在庫は0にする

        log.d(
          "Material consumed: ${material.name} from $oldStock to ${material.currentStock}",
          tag: loggerComponent,
        );

        // 材料を更新
        await _materialRepository.updateById(material.id!, <String, dynamic>{
          "current_stock": material.currentStock,
        });

        // 取引記録を作成（負の値で記録）
        final StockTransaction transaction = StockTransaction(
          materialId: materialId,
          transactionType: TransactionType.sale,
          changeAmount: -requiredAmount,
          referenceType: ReferenceType.order,
          referenceId: orderId,
          notes: "Order $orderId consumption",
          userId: userId,
        );
        transactions.add(transaction);
        processedMaterials++;
      }

      // 取引を一括作成
      if (transactions.isNotEmpty) {
        await _stockTransactionRepository.createBatch(transactions);
      }

      log.i(
        ServiceInfo.materialConsumptionSuccessful.withParams(<String, String>{
          "materialCount": processedMaterials.toString(),
        }),
        tag: loggerComponent,
      );
      return true;
    } catch (e, stackTrace) {
      log.e(
        ServiceError.materialConsumptionFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      return false;
    }
  }

  /// 注文キャンセル時の材料を復元（在庫復旧）
  Future<bool> restoreMaterialsForOrder(String orderId, String userId) async {
    log.i(ServiceInfo.materialRestorationStarted.message, tag: loggerComponent);

    try {
      // 該当注文の消費取引を取得
      final List<StockTransaction> consumptionTransactions = await _stockTransactionRepository
          .findByReference(ReferenceType.order, orderId);

      // 消費取引（負の値）のみを対象
      final List<StockTransaction> consumptionOnly = consumptionTransactions
          .where(
            (StockTransaction t) => t.changeAmount < 0 && t.transactionType == TransactionType.sale,
          )
          .toList();

      if (consumptionOnly.isEmpty) {
        log.d(ServiceDebug.restorationCompletedSuccessfully.message, tag: loggerComponent);
        return true; // 消費取引がない場合は成功とみなす
      }

      log.d(
        "Found ${consumptionOnly.length} consumption transactions to restore",
        tag: loggerComponent,
      );

      // 復元取引を作成
      final List<StockTransaction> restoreTransactions = <StockTransaction>[];
      int restoredMaterials = 0;

      for (final StockTransaction transaction in consumptionOnly) {
        // 材料を取得
        final Material? material = await _materialRepository.getById(transaction.materialId);
        if (material == null) {
          continue;
        }

        final double oldStock = material.currentStock;
        // 在庫を復元（消費量の絶対値を加算）
        final double restoreAmount = transaction.changeAmount.abs();
        material.currentStock += restoreAmount;

        log.d(
          "Material restored: ${material.name} from $oldStock to ${material.currentStock}",
          tag: loggerComponent,
        );

        // 材料を更新
        await _materialRepository.updateById(material.id!, <String, dynamic>{
          "current_stock": material.currentStock,
        });

        // 復元取引記録を作成（正の値で記録）
        final StockTransaction restoreTransaction = StockTransaction(
          materialId: transaction.materialId,
          transactionType: TransactionType.adjustment,
          changeAmount: restoreAmount,
          referenceType: ReferenceType.order,
          referenceId: orderId,
          notes: "Order $orderId cancellation restore",
          userId: userId,
        );
        restoreTransactions.add(restoreTransaction);
        restoredMaterials++;
      }

      // 復元取引を一括作成
      if (restoreTransactions.isNotEmpty) {
        await _stockTransactionRepository.createBatch(restoreTransactions);
      }

      log.i(
        ServiceInfo.materialRestorationSuccessful.withParams(<String, String>{
          "materialCount": restoredMaterials.toString(),
        }),
        tag: loggerComponent,
      );
      return true;
    } catch (e, stackTrace) {
      log.e(
        ServiceError.materialRestorationFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      return false;
    }
  }
}
