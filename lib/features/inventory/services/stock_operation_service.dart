import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/constants/enums.dart";
import "../../../core/constants/log_enums/service.dart";
import "../../../core/logging/logger_mixin.dart";
import "../dto/transaction_dto.dart";
import "../models/inventory_model.dart";
import "../models/transaction_model.dart";
import "../repositories/material_repository.dart";
import "../repositories/purchase_item_repository.dart";
import "../repositories/purchase_repository.dart";
import "../repositories/stock_adjustment_repository.dart";
import "../repositories/stock_transaction_repository.dart";

/// 在庫操作サービス（手動更新・仕入れ記録）
class StockOperationService with LoggerMixin {
  StockOperationService({
    required Ref ref,
    MaterialRepository? materialRepository,
    PurchaseRepository? purchaseRepository,
    PurchaseItemRepository? purchaseItemRepository,
    StockAdjustmentRepository? stockAdjustmentRepository,
    StockTransactionRepository? stockTransactionRepository,
  }) : _materialRepository = materialRepository ?? MaterialRepository(ref: ref),
       _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
       _purchaseItemRepository = purchaseItemRepository ?? PurchaseItemRepository(),
       _stockAdjustmentRepository = stockAdjustmentRepository ?? StockAdjustmentRepository(),
       _stockTransactionRepository = stockTransactionRepository ?? StockTransactionRepository();

  final MaterialRepository _materialRepository;
  final PurchaseRepository _purchaseRepository;
  final PurchaseItemRepository _purchaseItemRepository;
  final StockAdjustmentRepository _stockAdjustmentRepository;
  final StockTransactionRepository _stockTransactionRepository;

  @override
  String get loggerComponent => "StockOperationService";

  /// 材料在庫を手動更新
  Future<Material?> updateMaterialStock(StockUpdateRequest request, String userId) async {
    logInfoMessage(ServiceInfo.stockUpdateStarted, <String, String>{
      "newQuantity": request.newQuantity.toString(),
    });

    try {
      // 材料を取得
      final Material? material = await _materialRepository.getById(request.materialId);
      if (material == null) {
        logWarningMessage(ServiceWarning.accessDenied);
        throw Exception("Material not found");
      }

      final double oldStock = material.currentStock;
      final double adjustmentAmount = request.newQuantity - oldStock;

      logDebug(
        "Stock adjustment: oldStock=$oldStock, newStock=${request.newQuantity}, adjustment=$adjustmentAmount",
      );

      // 在庫調整を記録
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
      final Material? updatedMaterial = await _materialRepository.updateById(
        material.id!,
        <String, dynamic>{"current_stock": request.newQuantity},
      );

      logInfoMessage(ServiceInfo.stockUpdateSuccessful, <String, String>{
        "materialName": material.name,
      });
      return updatedMaterial;
    } catch (e, stackTrace) {
      logErrorMessage(ServiceError.stockUpdateFailed, null, e, stackTrace);
      rethrow;
    }
  }

  /// 仕入れを記録し、在庫を増加
  Future<String?> recordPurchase(PurchaseRequest request, String userId) async {
    logInfoMessage(ServiceInfo.purchaseRecordingStarted, <String, String>{
      "itemCount": request.items.length.toString(),
    });

    try {
      // 仕入れを作成
      final Purchase purchase = Purchase(
        purchaseDate: request.purchaseDate,
        notes: request.notes,
        userId: userId,
      );
      final Purchase? createdPurchase = await _purchaseRepository.create(purchase);

      if (createdPurchase?.id == null) {
        logWarningMessage(ServiceWarning.purchaseCreationFailed);
        throw Exception("Failed to create purchase");
      }

      logDebug("Purchase record created: ${createdPurchase!.id}");

      // 仕入れ明細を作成
      final List<PurchaseItem> purchaseItems = <PurchaseItem>[];
      for (final PurchaseItemDto itemData in request.items) {
        final PurchaseItem item = PurchaseItem(
          purchaseId: createdPurchase.id!,
          materialId: itemData.materialId,
          quantity: itemData.quantity,
          userId: userId,
        );
        purchaseItems.add(item);
      }

      await _purchaseItemRepository.createBatch(purchaseItems);
      logDebug("Purchase items created: ${purchaseItems.length} items");

      // 各材料の在庫を増加し、取引を記録
      final List<StockTransaction> transactions = <StockTransaction>[];
      int updatedMaterials = 0;

      for (final PurchaseItemDto itemData in request.items) {
        // 材料を取得して在庫更新
        final Material? material = await _materialRepository.getById(itemData.materialId);
        if (material != null) {
          final double oldStock = material.currentStock;
          material.currentStock += itemData.quantity;
          await _materialRepository.updateById(material.id!, <String, dynamic>{
            "current_stock": material.currentStock,
          });

          updatedMaterials++;
          logDebug(
            "Material stock increased: ${material.name} from $oldStock to ${material.currentStock}",
          );

          // 取引記録を作成
          final StockTransaction transaction = StockTransaction(
            materialId: itemData.materialId,
            transactionType: TransactionType.purchase,
            changeAmount: itemData.quantity,
            referenceType: ReferenceType.purchase,
            referenceId: createdPurchase.id!,
            userId: userId,
          );
          transactions.add(transaction);
        }
      }

      await _stockTransactionRepository.createBatch(transactions);

      logInfoMessage(ServiceInfo.purchaseRecordingSuccessful, <String, String>{
        "materialCount": updatedMaterials.toString(),
      });
      return createdPurchase.id!;
    } catch (e, stackTrace) {
      logErrorMessage(ServiceError.purchaseRecordingFailed, null, e, stackTrace);
      rethrow;
    }
  }
}
