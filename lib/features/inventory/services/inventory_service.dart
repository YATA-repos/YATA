import "dart:math" as math;

import "../../../core/constants/enums.dart";

import "../../order/repositories/order_item_repository.dart";
import "../../stock/dto/stock_dto.dart";
import "../../stock/models/stock_model.dart";
import "../../stock/repositories/purchase_item_repository.dart";
import "../../stock/repositories/purchase_repository.dart";
import "../../stock/repositories/stock_adjustment_repository.dart";
import "../../stock/repositories/stock_transaction_repository.dart";
import "../dto/inventory_dto.dart";
import "../models/inventory_model.dart";
import "../repositories/material_category_repository.dart";
import "../repositories/material_repository.dart";
import "../repositories/recipe_repository.dart";

/// 在庫管理サービス
class InventoryService {
  /// コンストラクタ
  InventoryService({
    MaterialRepository? materialRepository,
    MaterialCategoryRepository? materialCategoryRepository,
    RecipeRepository? recipeRepository,
    PurchaseRepository? purchaseRepository,
    PurchaseItemRepository? purchaseItemRepository,
    StockAdjustmentRepository? stockAdjustmentRepository,
    StockTransactionRepository? stockTransactionRepository,
    OrderItemRepository? orderItemRepository,
  }) : _materialRepository = materialRepository ?? MaterialRepository(),
       _materialCategoryRepository =
           materialCategoryRepository ?? MaterialCategoryRepository(),
       _recipeRepository = recipeRepository ?? RecipeRepository(),
       _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
       _purchaseItemRepository =
           purchaseItemRepository ?? PurchaseItemRepository(),
       _stockAdjustmentRepository =
           stockAdjustmentRepository ?? StockAdjustmentRepository(),
       _stockTransactionRepository =
           stockTransactionRepository ?? StockTransactionRepository(),
       _orderItemRepository = orderItemRepository ?? OrderItemRepository();

  final MaterialRepository _materialRepository;
  final MaterialCategoryRepository _materialCategoryRepository;
  final RecipeRepository _recipeRepository;
  final PurchaseRepository _purchaseRepository;
  final PurchaseItemRepository _purchaseItemRepository;
  final StockAdjustmentRepository _stockAdjustmentRepository;
  final StockTransactionRepository _stockTransactionRepository;
  final OrderItemRepository _orderItemRepository;

  /// 材料を作成
  Future<Material?> createMaterial(Material material, String userId) async {
    // ユーザーIDを設定
    material.userId = userId;
    return _materialRepository.create(material);
  }

  /// 材料カテゴリ一覧を取得
  Future<List<MaterialCategory>> getMaterialCategories(String userId) async =>
      _materialCategoryRepository.findActiveOrdered(userId);

  /// カテゴリ別材料一覧を取得
  Future<List<Material>> getMaterialsByCategory(
    String? categoryId,
    String userId,
  ) async => _materialRepository.findByCategoryId(categoryId, userId);

  /// 在庫レベル別アラート材料を取得
  Future<Map<StockLevel, List<Material>>> getStockAlertsByLevel(
    String userId,
  ) async {
    final List<Material> criticalMaterials = await _materialRepository
        .findBelowCriticalThreshold(userId);
    final List<Material> alertMaterials = await _materialRepository
        .findBelowAlertThreshold(userId);

    // アラートレベルからクリティカルを除外
    final List<Material> alertOnly = alertMaterials
        .where((Material m) => !criticalMaterials.contains(m))
        .toList();

    return <StockLevel, List<Material>>{
      StockLevel.critical: criticalMaterials,
      StockLevel.low: alertOnly,
      StockLevel.sufficient: <Material>[],
    };
  }

  /// 緊急レベルの材料一覧を取得
  Future<List<Material>> getCriticalStockMaterials(String userId) async =>
      _materialRepository.findBelowCriticalThreshold(userId);

  /// 材料在庫を手動更新
  Future<Material?> updateMaterialStock(
    StockUpdateRequest request,
    String userId,
  ) async {
    // 材料を取得
    final Material? material = await _materialRepository.getById(
      request.materialId,
    );
    if (material == null || material.userId != userId) {
      throw Exception("Material not found or access denied");
    }

    // 在庫調整を記録
    final double adjustmentAmount = request.newQuantity - material.currentStock;
    final StockAdjustment adjustment = StockAdjustment(
      materialId: request.materialId,
      adjustmentAmount: adjustmentAmount,
      notes: request.notes,
      adjustedAt: DateTime.now(),
      userId: userId,
    );
    await _stockAdjustmentRepository.create(adjustment);

    // 在庫取引を記録
    final StockTransaction transaction = StockTransaction(
      materialId: request.materialId,
      transactionType: TransactionType.adjustment,
      changeAmount: adjustmentAmount,
      referenceType: ReferenceType.adjustment,
      referenceId: adjustment.id,
      notes: request.reason,
      userId: userId,
    );
    await _stockTransactionRepository.create(transaction);

    // 材料の在庫を更新
    material.currentStock = request.newQuantity;
    return _materialRepository.updateById(material.id!, <String, dynamic>{
      "current_stock": request.newQuantity,
    });
  }

  /// 仕入れを記録し、在庫を増加
  Future<String?> recordPurchase(PurchaseRequest request, String userId) async {
    // 仕入れを作成
    final Purchase purchase = Purchase(
      purchaseDate: request.purchaseDate,
      notes: request.notes,
      userId: userId,
    );
    final Purchase? createdPurchase = await _purchaseRepository.create(
      purchase,
    );

    if (createdPurchase?.id == null) {
      throw Exception("Failed to create purchase");
    }

    // 仕入れ明細を作成
    final List<PurchaseItem> purchaseItems = <PurchaseItem>[];
    for (final PurchaseItemDto itemData in request.items) {
      final PurchaseItem item = PurchaseItem(
        purchaseId: createdPurchase!.id!,
        materialId: itemData.materialId,
        quantity: itemData.quantity,
        userId: userId,
      );
      purchaseItems.add(item);
    }

    await _purchaseItemRepository.createBatch(purchaseItems);

    // 各材料の在庫を増加し、取引を記録
    final List<StockTransaction> transactions = <StockTransaction>[];
    for (final PurchaseItemDto itemData in request.items) {
      // 材料を取得して在庫更新
      final Material? material = await _materialRepository.getById(
        itemData.materialId,
      );
      if (material != null && material.userId == userId) {
        material.currentStock += itemData.quantity;
        await _materialRepository.updateById(material.id!, <String, dynamic>{
          "current_stock": material.currentStock,
        });

        // 取引記録を作成
        final StockTransaction transaction = StockTransaction(
          materialId: itemData.materialId,
          transactionType: TransactionType.purchase,
          changeAmount: itemData.quantity,
          referenceType: ReferenceType.purchase,
          referenceId: createdPurchase!.id!,
          userId: userId,
        );
        transactions.add(transaction);
      }
    }

    await _stockTransactionRepository.createBatch(transactions);

    return createdPurchase!.id!;
  }

  /// 材料一覧を在庫レベル・使用可能日数付きで取得
  Future<List<MaterialStockInfo>> getMaterialsWithStockInfo(
    String? categoryId,
    String userId,
  ) async {
    // 材料一覧を取得
    final List<Material> materials = await _materialRepository.findByCategoryId(
      categoryId,
      userId,
    );

    // 各材料の使用可能日数を計算
    final Map<String, int?> usageDays = await bulkCalculateUsageDays(userId);

    // MaterialStockInfoに変換
    final List<MaterialStockInfo> stockInfos = <MaterialStockInfo>[];
    for (final Material material in materials) {
      final double? dailyUsageRate = await calculateMaterialUsageRate(
        material.id!,
        30,
        userId,
      );

      final MaterialStockInfo stockInfo = MaterialStockInfo(
        material: material,
        stockLevel: material.getStockLevel(),
        estimatedUsageDays: usageDays[material.id!],
        dailyUsageRate: dailyUsageRate,
      );
      stockInfos.add(stockInfo);
    }

    return stockInfos;
  }

  /// 材料の平均使用量を計算（日次）
  Future<double?> calculateMaterialUsageRate(
    String materialId,
    int days,
    String userId,
  ) async {
    // 過去N日間の期間を設定
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(Duration(days: days));

    // 期間内の消費取引を取得（負の値のみ）
    final List<StockTransaction> transactions =
        await _stockTransactionRepository.findByMaterialAndDateRange(
          materialId,
          startDate,
          endDate,
          userId,
        );

    // 消費取引のみをフィルタ（負の値）
    final List<StockTransaction> consumptionTransactions = transactions
        .where((StockTransaction t) => t.changeAmount < 0)
        .toList();

    if (consumptionTransactions.isEmpty) {
      return null;
    }

    // 総消費量を計算（絶対値）
    final double totalConsumption = consumptionTransactions.fold(
      0.0,
      (double sum, StockTransaction t) => sum + t.changeAmount.abs(),
    );

    // 日次平均を計算
    return days > 0 ? totalConsumption / days : null;
  }

  /// 推定使用可能日数を計算
  Future<int?> calculateEstimatedUsageDays(
    String materialId,
    String userId,
  ) async {
    // 材料を取得
    final Material? material = await _materialRepository.getById(materialId);
    if (material == null || material.userId != userId) {
      return null;
    }

    // 平均使用量を計算（過去30日間）
    final double? dailyUsage = await calculateMaterialUsageRate(
      materialId,
      30,
      userId,
    );

    if (dailyUsage == null || dailyUsage <= 0) {
      return null;
    }

    // 現在在庫量 ÷ 日次使用量 = 使用可能日数
    final double estimatedDays = material.currentStock / dailyUsage;

    return estimatedDays >= 0 ? estimatedDays.floor() : 0;
  }

  /// 全材料の使用可能日数を一括計算
  Future<Map<String, int?>> bulkCalculateUsageDays(String userId) async {
    // 全材料を取得
    final List<Material> materials = await _materialRepository.findByCategoryId(
      null,
      userId,
    );

    // 各材料の使用可能日数を計算
    final Map<String, int?> usageDays = <String, int?>{};
    for (final Material material in materials) {
      if (material.id != null) {
        final int? days = await calculateEstimatedUsageDays(
          material.id!,
          userId,
        );
        usageDays[material.id!] = days;
      }
    }

    return usageDays;
  }

  /// 詳細な在庫アラート情報を取得（レベル別 + 詳細情報付き）
  Future<Map<String, List<MaterialStockInfo>>> getDetailedStockAlerts(
    String userId,
  ) async {
    // 全材料の在庫情報を取得
    final List<MaterialStockInfo> allMaterialsInfo =
        await getMaterialsWithStockInfo(null, userId);

    // レベル別に分類
    final Map<String, List<MaterialStockInfo>> alerts =
        <String, List<MaterialStockInfo>>{
          "critical": <MaterialStockInfo>[],
          "low": <MaterialStockInfo>[],
          "sufficient": <MaterialStockInfo>[],
        };

    for (final MaterialStockInfo materialInfo in allMaterialsInfo) {
      if (materialInfo.stockLevel == StockLevel.critical) {
        alerts["critical"]!.add(materialInfo);
      } else if (materialInfo.stockLevel == StockLevel.low) {
        alerts["low"]!.add(materialInfo);
      } else {
        alerts["sufficient"]!.add(materialInfo);
      }
    }

    // 各レベル内で材料名でソート
    for (final String level in alerts.keys) {
      alerts[level]!.sort(
        (MaterialStockInfo a, MaterialStockInfo b) =>
            a.material.name.compareTo(b.material.name),
      );
    }

    return alerts;
  }

  /// 注文に対する材料を消費（在庫減算）
  Future<bool> consumeMaterialsForOrder(String orderId, String userId) async {
    try {
      // 注文明細を取得
      final List<dynamic> orderItems = await _orderItemRepository.findByOrderId(
        orderId,
      );

      if (orderItems.isEmpty) {
        return true; // 注文明細がない場合は成功とみなす
      }

      // 注文明細から必要な材料を計算
      final Map<String, double> materialRequirements = <String, double>{};

      for (final dynamic orderItem in orderItems) {
        // メニューアイテムのレシピを取得
        final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(
          orderItem.menuItemId as String,
          userId,
        );

        for (final Recipe recipe in recipes) {
          // 必要量 = レシピの必要量 × 注文数量
          final double requiredAmount =
              recipe.requiredAmount * (orderItem.quantity as int);
          materialRequirements[recipe.materialId] =
              (materialRequirements[recipe.materialId] ?? 0.0) + requiredAmount;
        }
      }

      // 各材料の在庫を減算し、取引を記録
      final List<StockTransaction> transactions = <StockTransaction>[];

      for (final MapEntry<String, double> entry
          in materialRequirements.entries) {
        final String materialId = entry.key;
        final double requiredAmount = entry.value;

        // 材料を取得
        final Material? material = await _materialRepository.getById(
          materialId,
        );
        if (material == null || material.userId != userId) {
          continue;
        }

        // 在庫を減算
        final double newStock = material.currentStock - requiredAmount;
        material.currentStock = math.max(newStock, 0.0); // 負の在庫は0にする

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
      }

      // 取引を一括作成
      if (transactions.isNotEmpty) {
        await _stockTransactionRepository.createBatch(transactions);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 注文キャンセル時の材料を復元（在庫復旧）
  Future<bool> restoreMaterialsForOrder(String orderId, String userId) async {
    try {
      // 該当注文の消費取引を取得
      final List<StockTransaction> consumptionTransactions =
          await _stockTransactionRepository.findByReference(
            ReferenceType.order,
            orderId,
            userId,
          );

      // 消費取引（負の値）のみを対象
      final List<StockTransaction> consumptionOnly = consumptionTransactions
          .where(
            (StockTransaction t) =>
                t.changeAmount < 0 && t.transactionType == TransactionType.sale,
          )
          .toList();

      if (consumptionOnly.isEmpty) {
        return true; // 消費取引がない場合は成功とみなす
      }

      // 復元取引を作成
      final List<StockTransaction> restoreTransactions = <StockTransaction>[];

      for (final StockTransaction transaction in consumptionOnly) {
        // 材料を取得
        final Material? material = await _materialRepository.getById(
          transaction.materialId,
        );
        if (material == null || material.userId != userId) {
          continue;
        }

        // 在庫を復元（消費量の絶対値を加算）
        final double restoreAmount = transaction.changeAmount.abs();
        material.currentStock += restoreAmount;

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
      }

      // 復元取引を一括作成
      if (restoreTransactions.isNotEmpty) {
        await _stockTransactionRepository.createBatch(restoreTransactions);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 材料のアラート閾値を更新
  Future<Material?> updateMaterialThresholds(
    String materialId,
    double alertThreshold,
    double criticalThreshold,
    String userId,
  ) async {
    // 材料を取得
    final Material? material = await _materialRepository.getById(materialId);
    if (material == null || material.userId != userId) {
      throw Exception("Material not found or access denied");
    }

    // 閾値の妥当性チェック
    if (criticalThreshold > alertThreshold) {
      throw Exception(
        "Critical threshold must be less than or equal to alert threshold",
      );
    }

    if (criticalThreshold < 0 || alertThreshold < 0) {
      throw Exception("Thresholds must be non-negative");
    }

    // 閾値を更新
    material
      ..alertThreshold = alertThreshold
      ..criticalThreshold = criticalThreshold;

    // 材料を更新して返す
    return _materialRepository.updateById(materialId, <String, dynamic>{
      "alert_threshold": alertThreshold,
      "critical_threshold": criticalThreshold,
    });
  }
}
