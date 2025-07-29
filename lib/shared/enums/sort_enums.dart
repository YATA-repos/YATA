/// メニューソート種別
enum MenuSortType {
  name, // 名前順
  price, // 価格順
  prepTime, // 調理時間順
  category, // カテゴリー順
  availability, // 販売可否順
}

/// 注文ソート種別
enum OrderSortType {
  orderedAt, // 注文日時順
  totalAmount, // 合計金額順
  status, // ステータス順
  customerName, // 顧客名順
  orderNumber, // 注文番号順
}

/// 在庫ソート種別
enum InventorySortType {
  name, // 材料名順
  stockLevel, // 在庫レベル順
  category, // カテゴリー順
  lastUpdated, // 最終更新日順
}

/// ソート順序
enum SortOrder {
  ascending, // 昇順
  descending, // 降順
}

/// ソート拡張メソッド
extension MenuSortTypeExtension on MenuSortType {
  String get displayName {
    switch (this) {
      case MenuSortType.name:
        return "名前順";
      case MenuSortType.price:
        return "価格順";
      case MenuSortType.prepTime:
        return "調理時間順";
      case MenuSortType.category:
        return "カテゴリー順";
      case MenuSortType.availability:
        return "販売可否順";
    }
  }
}

extension OrderSortTypeExtension on OrderSortType {
  String get displayName {
    switch (this) {
      case OrderSortType.orderedAt:
        return "注文日時順";
      case OrderSortType.totalAmount:
        return "合計金額順";
      case OrderSortType.status:
        return "ステータス順";
      case OrderSortType.customerName:
        return "顧客名順";
      case OrderSortType.orderNumber:
        return "注文番号順";
    }
  }
}

extension InventorySortTypeExtension on InventorySortType {
  String get displayName {
    switch (this) {
      case InventorySortType.name:
        return "材料名順";
      case InventorySortType.stockLevel:
        return "在庫レベル順";
      case InventorySortType.category:
        return "カテゴリー順";
      case InventorySortType.lastUpdated:
        return "最終更新日順";
    }
  }
}

extension SortOrderExtension on SortOrder {
  String get displayName {
    switch (this) {
      case SortOrder.ascending:
        return "昇順";
      case SortOrder.descending:
        return "降順";
    }
  }
}
