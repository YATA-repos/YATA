import "../../base/base_error_msg.dart";

/// 在庫管理関連のエラーメッセージ定義
enum InventoryError implements LogMessage {
  /// 在庫アイテムが見つからない
  itemNotFound,

  /// 在庫が不足している
  insufficientStock,

  /// 期限切れのアイテム
  expiredItem,

  /// 無効な数量が指定された
  invalidQuantity,

  /// 在庫レベルの更新に失敗
  stockUpdateFailed,

  /// 在庫カテゴリが見つからない
  categoryNotFound,

  /// 重複する在庫アイテム
  duplicateItem,

  /// 在庫レベルが危険域に達している
  stockLevelCritical;

  @override
  String get message {
    switch (this) {
      case InventoryError.itemNotFound:
        return "Inventory item not found";
      case InventoryError.insufficientStock:
        return "Insufficient stock available";
      case InventoryError.expiredItem:
        return "Item has expired";
      case InventoryError.invalidQuantity:
        return "Invalid quantity specified";
      case InventoryError.stockUpdateFailed:
        return "Failed to update stock level";
      case InventoryError.categoryNotFound:
        return "Inventory category not found";
      case InventoryError.duplicateItem:
        return "Duplicate inventory item";
      case InventoryError.stockLevelCritical:
        return "Stock level is critically low";
    }
  }
}

/// 在庫管理関連の警告メッセージ定義
enum InventoryWarning implements LogMessage {
  /// 在庫レベルが低下している
  stockLevelLow,

  /// アイテムの期限が近づいている
  expirationSoon,

  /// 異常な消費パターンを検出
  unusualConsumption,

  /// アイテムの再注文が必要
  reorderRequired;

  @override
  String get message {
    switch (this) {
      case InventoryWarning.stockLevelLow:
        return "Stock level is low";
      case InventoryWarning.expirationSoon:
        return "Item will expire soon";
      case InventoryWarning.unusualConsumption:
        return "Unusual consumption pattern detected";
      case InventoryWarning.reorderRequired:
        return "Reorder required for item";
    }
  }
}
