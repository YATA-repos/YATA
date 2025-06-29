import "../../base/base_error_msg.dart";

/// メニューサービス関連の情報メッセージ定義
enum MenuInfo implements LogMessage {
  /// メニュー可否切り替え開始
  toggleAvailabilityStarted,

  /// メニュー可否切り替え完了
  toggleAvailabilityCompleted,

  /// メニュー無効化
  menuItemDisabled,

  /// メニュー有効化
  menuItemEnabled;

  /// 情報メッセージを取得
  @override
  String get message {
    switch (this) {
      case MenuInfo.toggleAvailabilityStarted:
        return "Started toggling menu item availability: isAvailable={isAvailable}";
      case MenuInfo.toggleAvailabilityCompleted:
        return "Menu item availability updated: {itemName} set to {status}";
      case MenuInfo.menuItemDisabled:
        return "Menu item disabled: {itemName}";
      case MenuInfo.menuItemEnabled:
        return "Menu item available: {itemName}, max servings: {maxServings}";
    }
  }
}

/// メニューサービス関連のデバッグメッセージ定義
enum MenuDebug implements LogMessage {
  /// メニュー検索開始
  menuSearchStarted,

  /// メニュー検索完了
  menuSearchCompleted,

  /// メニュー項目取得
  menuItemsRetrieved,

  /// 在庫チェック開始
  availabilityCheckStarted,

  /// レシピなし
  noRecipesFound,

  /// レシピチェック
  recipesChecking,

  /// 在庫不足警告
  insufficientStock,

  /// 更新失敗警告
  updateFailed;

  /// デバッグメッセージを取得
  @override
  String get message {
    switch (this) {
      case MenuDebug.menuSearchStarted:
        return "Started menu item search: keyword=\"{keyword}\"";
      case MenuDebug.menuSearchCompleted:
        return "Menu search completed: {itemCount} items found";
      case MenuDebug.menuItemsRetrieved:
        return "Retrieved {itemCount} menu items for search";
      case MenuDebug.availabilityCheckStarted:
        return "Checking menu availability: quantity={quantity}";
      case MenuDebug.noRecipesFound:
        return "No recipes found: menu item available without material constraints";
      case MenuDebug.recipesChecking:
        return "Checking {recipeCount} recipes for availability";
      case MenuDebug.insufficientStock:
        return "Menu item not available: {itemName}, missing materials: {missingMaterials}";
      case MenuDebug.updateFailed:
        return "Failed to update menu item availability: {itemName}";
    }
  }
}

/// メニューサービス関連の警告メッセージ定義
enum MenuWarning implements LogMessage {
  /// メニューアイテム見つからない
  menuItemNotFound,

  /// アクセス権限なし
  accessDenied,

  /// 更新失敗
  updateFailed;

  /// 警告メッセージを取得
  @override
  String get message {
    switch (this) {
      case MenuWarning.menuItemNotFound:
        return "Menu item access denied or menu item not found";
      case MenuWarning.accessDenied:
        return "Menu item access denied or menu item not found";
      case MenuWarning.updateFailed:
        return "Failed to update menu item availability: {itemName}";
    }
  }
}

/// メニューサービス関連のエラーメッセージ定義
enum MenuError implements LogMessage {
  /// メニュー検索失敗
  searchFailed,

  /// 在庫チェック失敗
  availabilityCheckFailed,

  /// 可否切り替え失敗
  toggleAvailabilityFailed;

  /// エラーメッセージを取得
  @override
  String get message {
    switch (this) {
      case MenuError.searchFailed:
        return "Failed to search menu items";
      case MenuError.availabilityCheckFailed:
        return "Failed to check menu availability";
      case MenuError.toggleAvailabilityFailed:
        return "Failed to toggle menu item availability";
    }
  }
}
