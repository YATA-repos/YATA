/// 在庫管理関連のエラーメッセージ定義
enum InventoryError {
  itemNotFound,
  insufficientStock,
  expiredItem,
  invalidQuantity,
  stockUpdateFailed,
  categoryNotFound,
  duplicateItem,
  stockLevelCritical;

  /// 英語エラーメッセージを取得
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

  /// 日本語エラーメッセージを取得
  String get messageJa {
    switch (this) {
      case InventoryError.itemNotFound:
        return "在庫アイテムが見つかりません";
      case InventoryError.insufficientStock:
        return "在庫不足です";
      case InventoryError.expiredItem:
        return "期限切れアイテムです";
      case InventoryError.invalidQuantity:
        return "無効な数量が指定されました";
      case InventoryError.stockUpdateFailed:
        return "在庫レベル更新に失敗しました";
      case InventoryError.categoryNotFound:
        return "在庫カテゴリが見つかりません";
      case InventoryError.duplicateItem:
        return "重複する在庫アイテムです";
      case InventoryError.stockLevelCritical:
        return "在庫レベルが危険域です";
    }
  }

  /// 組み合わせメッセージ（英語 + 日本語）を取得
  String get combinedMessage => "$message ($messageJa)";
}

/// 在庫管理関連の警告メッセージ定義
enum InventoryWarning {
  stockLevelLow,
  expirationSoon,
  unusualConsumption,
  reorderRequired;

  /// 英語警告メッセージを取得
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

  /// 日本語警告メッセージを取得
  String get messageJa {
    switch (this) {
      case InventoryWarning.stockLevelLow:
        return "在庫レベルが低下しています";
      case InventoryWarning.expirationSoon:
        return "アイテムの期限が近づいています";
      case InventoryWarning.unusualConsumption:
        return "異常な消費パターンを検出しました";
      case InventoryWarning.reorderRequired:
        return "アイテムの再注文が必要です";
    }
  }

  /// 組み合わせメッセージ（英語 + 日本語）を取得
  String get combinedMessage => "$message ($messageJa)";
}
