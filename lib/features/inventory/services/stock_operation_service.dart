import "../../../core/base/base_error_msg.dart";
import "../../../core/constants/enums.dart";
import "../../../core/constants/log_enums/service.dart";
import "../../../core/contracts/repositories/inventory/material_repository_contract.dart";
import "../../../core/contracts/repositories/inventory/purchase_repository_contract.dart";
import "../../../core/contracts/repositories/inventory/stock_adjustment_repository_contract.dart";
import "../../../core/contracts/repositories/inventory/stock_transaction_repository_contract.dart";
// Removed LoggerComponent mixin; use local tag
import "../../../core/logging/compat.dart" as log;
import "../dto/transaction_dto.dart";
import "../models/inventory_model.dart";
import "../models/transaction_model.dart";

/// 在庫操作サービス（手動更新・仕入れ記録）
class StockOperationService {
  StockOperationService({
    required MaterialRepositoryContract<Material> materialRepository,
    required PurchaseRepositoryContract<Purchase> purchaseRepository,
    required PurchaseItemRepositoryContract<PurchaseItem> purchaseItemRepository,
    required StockAdjustmentRepositoryContract<StockAdjustment> stockAdjustmentRepository,
    required StockTransactionRepositoryContract<StockTransaction> stockTransactionRepository,
  }) : _materialRepository = materialRepository,
       _purchaseRepository = purchaseRepository,
       _purchaseItemRepository = purchaseItemRepository,
       _stockAdjustmentRepository = stockAdjustmentRepository,
       _stockTransactionRepository = stockTransactionRepository;

  final MaterialRepositoryContract<Material> _materialRepository;
  final PurchaseRepositoryContract<Purchase> _purchaseRepository;
  final PurchaseItemRepositoryContract<PurchaseItem> _purchaseItemRepository;
  final StockAdjustmentRepositoryContract<StockAdjustment> _stockAdjustmentRepository;
  final StockTransactionRepositoryContract<StockTransaction> _stockTransactionRepository;

  String get loggerComponent => "StockOperationService";

  /// 材料在庫を手動更新
  Future<Material?> updateMaterialStock(StockUpdateRequest request, String userId) async {
    log.i(
      ServiceInfo.stockUpdateStarted.withParams(<String, String>{
        "newQuantity": request.newQuantity.toString(),
      }),
      tag: loggerComponent,
    );

    try {
      // 材料を取得
      final Material? material = await _materialRepository.getById(request.materialId);
      if (material == null) {
        log.w(ServiceWarning.accessDenied.message, tag: loggerComponent);
        throw Exception("Material not found");
      }

      final double oldStock = material.currentStock;
      final double adjustmentAmount = request.newQuantity - oldStock;

      log.d(
        "Stock adjustment: oldStock=$oldStock, newStock=${request.newQuantity}, adjustment=$adjustmentAmount",
        tag: loggerComponent,
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

      log.i(
        ServiceInfo.stockUpdateSuccessful.withParams(<String, String>{
          "materialName": material.name,
        }),
        tag: loggerComponent,
      );
      return updatedMaterial;
    } catch (e, stackTrace) {
      log.e(ServiceError.stockUpdateFailed.message, tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 仕入れを記録し、在庫を増加
  Future<String?> recordPurchase(PurchaseRequest request, String userId) async {
    log.i(
      ServiceInfo.purchaseRecordingStarted.withParams(<String, String>{
        "itemCount": request.items.length.toString(),
      }),
      tag: loggerComponent,
    );

    try {
      // 仕入れを作成
      final Purchase purchase = Purchase(
        purchaseDate: request.purchaseDate,
        notes: request.notes,
        userId: userId,
      );
      final Purchase? createdPurchase = await _purchaseRepository.create(purchase);

      if (createdPurchase?.id == null) {
        log.w(ServiceWarning.purchaseCreationFailed.message, tag: loggerComponent);
        throw Exception("Failed to create purchase");
      }

      log.d("Purchase record created: ${createdPurchase!.id}", tag: loggerComponent);

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
      log.d("Purchase items created: ${purchaseItems.length} items", tag: loggerComponent);

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
          log.d(
            "Material stock increased: ${material.name} from $oldStock to ${material.currentStock}",
            tag: loggerComponent,
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

      log.i(
        ServiceInfo.purchaseRecordingSuccessful.withParams(<String, String>{
          "materialCount": updatedMaterials.toString(),
        }),
        tag: loggerComponent,
      );
      return createdPurchase.id!;
    } catch (e, stackTrace) {
      log.e(
        ServiceError.purchaseRecordingFailed.message,
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }
}
