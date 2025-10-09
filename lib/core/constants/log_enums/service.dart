import "../../base/base_error_msg.dart";

/// サービス共通の情報メッセージ定義
enum ServiceInfo implements LogMessage {
  /// 操作開始
  operationStarted,

  /// 操作完了
  operationCompleted,

  /// 作成成功
  creationSuccessful,

  /// 更新成功
  updateSuccessful,

  /// 削除成功
  deletionSuccessful,

  /// 材料作成開始
  materialCreationStarted,

  /// 材料作成成功
  materialCreationSuccessful,

  /// 在庫更新開始
  stockUpdateStarted,

  /// 在庫更新成功
  stockUpdateSuccessful,

  /// 仕入記録開始
  purchaseRecordingStarted,

  /// 仕入記録成功
  purchaseRecordingSuccessful,

  /// 材料消費開始
  materialConsumptionStarted,

  /// 材料消費成功
  materialConsumptionSuccessful,

  /// 材料復元開始
  materialRestorationStarted,

  /// 材料復元成功
  materialRestorationSuccessful;

  @override
  String get message {
    switch (this) {
      case ServiceInfo.operationStarted:
        return "Started {operationType} operation";
      case ServiceInfo.operationCompleted:
        return "Operation completed successfully";
      case ServiceInfo.creationSuccessful:
        return "Entity created successfully";
      case ServiceInfo.updateSuccessful:
        return "Entity updated successfully";
      case ServiceInfo.deletionSuccessful:
        return "Entity deleted successfully";
      case ServiceInfo.materialCreationStarted:
        return "Started creating material: {materialName}";
      case ServiceInfo.materialCreationSuccessful:
        return "Material created successfully: {materialName}";
      case ServiceInfo.stockUpdateStarted:
        return "Started updating material stock: newQuantity={newQuantity}";
      case ServiceInfo.stockUpdateSuccessful:
        return "Material stock updated successfully: {materialName}";
      case ServiceInfo.purchaseRecordingStarted:
        return "Started recording purchase: {itemCount} items";
      case ServiceInfo.purchaseRecordingSuccessful:
        return "Purchase recorded successfully: {materialCount} materials updated";
      case ServiceInfo.materialConsumptionStarted:
        return "Started consuming materials for order";
      case ServiceInfo.materialConsumptionSuccessful:
        return "Materials consumed successfully: {materialCount} materials processed";
      case ServiceInfo.materialRestorationStarted:
        return "Started restoring materials for canceled order";
      case ServiceInfo.materialRestorationSuccessful:
        return "Materials restored successfully: {materialCount} materials restored";
    }
  }
}

/// サービス共通のデバッグメッセージ定義
enum ServiceDebug implements LogMessage {
  /// データ取得
  dataRetrieved,

  /// アイテム処理
  itemsProcessed,

  /// 在庫調整
  stockAdjustment,

  /// 購入記録作成
  purchaseRecordCreated,

  /// 購入明細作成
  purchaseItemsCreated,

  /// 在庫増加
  stockIncreased,

  /// 材料要件計算
  materialRequirementsCalculated,

  /// 材料消費
  materialConsumed,

  /// 消費取引発見
  consumptionTransactionsFound,

  /// 材料復元
  materialRestored,

  /// 復元完了確認
  restorationCompletedSuccessfully,

  /// 消費完了確認
  consumptionCompletedSuccessfully;

  @override
  String get message {
    switch (this) {
      case ServiceDebug.dataRetrieved:
        return "Retrieved {count} {entityType} for processing";
      case ServiceDebug.itemsProcessed:
        return "Processing {itemType} for {count} items";
      case ServiceDebug.stockAdjustment:
        return "Stock adjustment: oldStock={oldStock}, newStock={newStock}, adjustment={adjustment}";
      case ServiceDebug.purchaseRecordCreated:
        return "Purchase record created: {purchaseId}";
      case ServiceDebug.purchaseItemsCreated:
        return "Purchase items created: {itemCount} items";
      case ServiceDebug.stockIncreased:
        return "Material stock increased: {materialName} from {oldStock} to {newStock}";
      case ServiceDebug.materialRequirementsCalculated:
        return "Material requirements calculated: {materialCount} materials needed";
      case ServiceDebug.materialConsumed:
        return "Material consumed: {materialName} from {oldStock} to {newStock}";
      case ServiceDebug.consumptionTransactionsFound:
        return "Found {transactionCount} consumption transactions to restore";
      case ServiceDebug.materialRestored:
        return "Material restored: {materialName} from {oldStock} to {newStock}";
      case ServiceDebug.restorationCompletedSuccessfully:
        return "No consumption transactions found: restoration completed successfully";
      case ServiceDebug.consumptionCompletedSuccessfully:
        return "No order items found: consumption completed successfully";
    }
  }
}

/// サービス共通の警告メッセージ定義
enum ServiceWarning implements LogMessage {
  /// 操作失敗
  operationFailed,

  /// アクセス拒否
  accessDenied,

  /// エンティティ見つからない
  entityNotFound,

  /// 作成失敗
  creationFailed,

  /// 更新失敗
  updateFailed,

  /// 購入作成失敗
  purchaseCreationFailed;

  @override
  String get message {
    switch (this) {
      case ServiceWarning.operationFailed:
        return "Failed to complete {operationType} operation";
      case ServiceWarning.accessDenied:
        return "Access denied or entity not found";
      case ServiceWarning.entityNotFound:
        return "Entity not found: {entityType}";
      case ServiceWarning.creationFailed:
        return "Failed to create {entityType}";
      case ServiceWarning.updateFailed:
        return "Failed to update {entityType}";
      case ServiceWarning.purchaseCreationFailed:
        return "Failed to create purchase record";
    }
  }
}

/// サービス共通のエラーメッセージ定義
enum ServiceError implements LogMessage {
  /// 操作失敗
  operationFailed,

  /// 材料作成失敗
  materialCreationFailed,

  /// 在庫更新失敗
  stockUpdateFailed,

  /// 仕入記録失敗
  purchaseRecordingFailed,

  /// 材料消費失敗
  materialConsumptionFailed,

  /// 材料復元失敗
  materialRestorationFailed,

  /// CSVエクスポートのレートリミット超過
  exportRateLimitExceeded,

  /// CSVエクスポートの同時実行制限違反
  concurrentExportInProgress,

  /// エクスポートジョブが見つからない
  exportJobNotFound,

  /// 再ダウンロード期限切れ
  exportRedownloadExpired;

  @override
  String get message {
    switch (this) {
      case ServiceError.operationFailed:
        return "Failed to execute {operationType} operation";
      case ServiceError.materialCreationFailed:
        return "Failed to create material: {materialName}";
      case ServiceError.stockUpdateFailed:
        return "Failed to update material stock";
      case ServiceError.purchaseRecordingFailed:
        return "Failed to record purchase";
      case ServiceError.materialConsumptionFailed:
        return "Failed to consume materials for order";
      case ServiceError.materialRestorationFailed:
        return "Failed to restore materials for order";
      case ServiceError.exportRateLimitExceeded:
        return "CSV export rate limit exceeded for {organizationId}";
      case ServiceError.concurrentExportInProgress:
        return "Another CSV export is already running for {organizationId}";
      case ServiceError.exportJobNotFound:
        return "Export job not found: {exportJobId}";
      case ServiceError.exportRedownloadExpired:
        return "Export job expired and cannot be redownloaded: {exportJobId}";
    }
  }
}
