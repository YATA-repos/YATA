import "package:flutter/foundation.dart";

import "../../core/constants/enums.dart";
import "../enums/sort_enums.dart";

/// 検索・フィルター用の軽量状態モデル
/// 各画面での検索・絞り込み機能に特化

/// メニュー検索フィルター状態
@immutable
class MenuFilterState {
  const MenuFilterState({
    this.searchQuery = "",
    this.selectedCategoryId,
    this.minPrice,
    this.maxPrice,
    this.isAvailableOnly = false,
    this.maxPrepTime,
    this.sortBy = MenuSortType.name,
    this.sortOrder = SortOrder.ascending,
  });

  final String searchQuery;
  final String? selectedCategoryId;
  final int? minPrice;
  final int? maxPrice;
  final bool isAvailableOnly;
  final int? maxPrepTime;
  final MenuSortType sortBy;
  final SortOrder sortOrder;

  /// フィルターが適用されているかどうか
  bool get hasActiveFilters => searchQuery.isNotEmpty ||
        selectedCategoryId != null ||
        minPrice != null ||
        maxPrice != null ||
        isAvailableOnly ||
        maxPrepTime != null;

  /// アクティブフィルター数
  int get activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) {
      count++;
    }
    if (selectedCategoryId != null) {
      count++;
    }
    if (minPrice != null) {
      count++;
    }
    if (maxPrice != null) {
      count++;
    }
    if (isAvailableOnly) {
      count++;
    }
    if (maxPrepTime != null) {
      count++;
    }
    return count;
  }

  /// 価格範囲の表示文字列
  String? get priceRangeDisplay {
    if (minPrice != null && maxPrice != null) {
      return "¥$minPrice - ¥$maxPrice";
    } else if (minPrice != null) {
      return "¥$minPrice以上";
    } else if (maxPrice != null) {
      return "¥$maxPrice以下";
    }
    return null;
  }

  /// フィルター説明文の生成
  String get filterDescription {
    final List<String> descriptions = <String>[];

    if (searchQuery.isNotEmpty) {
      descriptions.add("「$searchQuery」で検索");
    }
    if (isAvailableOnly) {
      descriptions.add("販売中のみ");
    }
    if (priceRangeDisplay != null) {
      descriptions.add("価格: $priceRangeDisplay");
    }
    if (maxPrepTime != null) {
      descriptions.add("調理時間: $maxPrepTime分以内");
    }

    return descriptions.isEmpty ? "フィルターなし" : descriptions.join(", ");
  }

  /// コピー作成
  MenuFilterState copyWith({
    String? searchQuery,
    String? selectedCategoryId,
    int? minPrice,
    int? maxPrice,
    bool? isAvailableOnly,
    int? maxPrepTime,
    MenuSortType? sortBy,
    SortOrder? sortOrder,
  }) => MenuFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      isAvailableOnly: isAvailableOnly ?? this.isAvailableOnly,
      maxPrepTime: maxPrepTime ?? this.maxPrepTime,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );

  /// フィルターリセット
  MenuFilterState reset() => const MenuFilterState();

  /// 検索クエリのみ更新
  MenuFilterState updateQuery(String query) => copyWith(searchQuery: query);

  /// カテゴリフィルター更新
  MenuFilterState updateCategory(String? categoryId) => copyWith(selectedCategoryId: categoryId);

  /// 価格範囲フィルター更新
  MenuFilterState updatePriceRange(int? min, int? max) => copyWith(minPrice: min, maxPrice: max);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MenuFilterState &&
        other.searchQuery == searchQuery &&
        other.selectedCategoryId == selectedCategoryId &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.isAvailableOnly == isAvailableOnly &&
        other.maxPrepTime == maxPrepTime &&
        other.sortBy == sortBy &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(
      searchQuery,
      selectedCategoryId,
      minPrice,
      maxPrice,
      isAvailableOnly,
      maxPrepTime,
      sortBy,
      sortOrder,
    );
}

/// 注文検索フィルター状態
@immutable
class OrderFilterState {
  const OrderFilterState({
    this.searchQuery = "",
    this.selectedStatus,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.customerName,
    this.sortBy = OrderSortType.orderedAt,
    this.sortOrder = SortOrder.descending,
  });

  final String searchQuery;
  final OrderStatus? selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minAmount;
  final int? maxAmount;
  final String? customerName;
  final OrderSortType sortBy;
  final SortOrder sortOrder;

  /// フィルターが適用されているかどうか
  bool get hasActiveFilters => searchQuery.isNotEmpty ||
        selectedStatus != null ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null ||
        (customerName != null && customerName!.isNotEmpty);

  /// アクティブフィルター数
  int get activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) {
      count++;
    }
    if (selectedStatus != null) {
      count++;
    }
    if (startDate != null || endDate != null) {
      count++;
    }
    if (minAmount != null || maxAmount != null) {
      count++;
    }
    if (customerName != null && customerName!.isNotEmpty) {
      count++;
    }
    return count;
  }

  /// 日付範囲の表示文字列
  String? get dateRangeDisplay {
    if (startDate != null && endDate != null) {
      return "${_formatDate(startDate!)} - ${_formatDate(endDate!)}";
    } else if (startDate != null) {
      return "${_formatDate(startDate!)}以降";
    } else if (endDate != null) {
      return "${_formatDate(endDate!)}以前";
    }
    return null;
  }

  /// 金額範囲の表示文字列
  String? get amountRangeDisplay {
    if (minAmount != null && maxAmount != null) {
      return "¥$minAmount - ¥$maxAmount";
    } else if (minAmount != null) {
      return "¥$minAmount以上";
    } else if (maxAmount != null) {
      return "¥$maxAmount以下";
    }
    return null;
  }

  String _formatDate(DateTime date) => "${date.month}/${date.day}";

  /// フィルター説明文の生成
  String get filterDescription {
    final List<String> descriptions = <String>[];

    if (searchQuery.isNotEmpty) {
      descriptions.add("「$searchQuery」で検索");
    }
    if (selectedStatus != null) {
      descriptions.add("ステータス: ${_getStatusDisplayName(selectedStatus!)}");
    }
    if (dateRangeDisplay != null) {
      descriptions.add("期間: $dateRangeDisplay");
    }
    if (amountRangeDisplay != null) {
      descriptions.add("金額: $amountRangeDisplay");
    }
    if (customerName != null && customerName!.isNotEmpty) {
      descriptions.add("顧客: $customerName");
    }

    return descriptions.isEmpty ? "フィルターなし" : descriptions.join(", ");
  }

  String _getStatusDisplayName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return "受付中";
      case OrderStatus.confirmed:
        return "確認済み";
      case OrderStatus.preparing:
        return "調理中";
      case OrderStatus.ready:
        return "提供準備完了";
      case OrderStatus.delivered:
        return "提供済み";
      case OrderStatus.completed:
        return "完了";
      case OrderStatus.cancelled:
        return "キャンセル";
      case OrderStatus.refunded:
        return "返金済み";
    }
  }

  /// コピー作成
  OrderFilterState copyWith({
    String? searchQuery,
    OrderStatus? selectedStatus,
    DateTime? startDate,
    DateTime? endDate,
    int? minAmount,
    int? maxAmount,
    String? customerName,
    OrderSortType? sortBy,
    SortOrder? sortOrder,
  }) => OrderFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      customerName: customerName ?? this.customerName,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );

  /// フィルターリセット
  OrderFilterState reset() => const OrderFilterState();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrderFilterState &&
        other.searchQuery == searchQuery &&
        other.selectedStatus == selectedStatus &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.customerName == customerName &&
        other.sortBy == sortBy &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(
      searchQuery,
      selectedStatus,
      startDate,
      endDate,
      minAmount,
      maxAmount,
      customerName,
      sortBy,
      sortOrder,
    );
}

/// 在庫検索フィルター状態
@immutable
class InventoryFilterState {
  const InventoryFilterState({
    this.searchQuery = "",
    this.selectedCategoryId,
    this.stockLevel,
    this.sortBy = InventorySortType.name,
    this.sortOrder = SortOrder.ascending,
  });

  final String searchQuery;
  final String? selectedCategoryId;
  final StockLevel? stockLevel;
  final InventorySortType sortBy;
  final SortOrder sortOrder;

  /// フィルターが適用されているかどうか
  bool get hasActiveFilters => searchQuery.isNotEmpty || selectedCategoryId != null || stockLevel != null;

  /// アクティブフィルター数
  int get activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) {
      count++;
    }
    if (selectedCategoryId != null) {
      count++;
    }
    if (stockLevel != null) {
      count++;
    }
    return count;
  }

  /// フィルター説明文の生成
  String get filterDescription {
    final List<String> descriptions = <String>[];

    if (searchQuery.isNotEmpty) {
      descriptions.add("「$searchQuery」で検索");
    }
    if (stockLevel != null) {
      descriptions.add("在庫レベル: ${_getStockLevelDisplayName(stockLevel!)}");
    }

    return descriptions.isEmpty ? "フィルターなし" : descriptions.join(", ");
  }

  String _getStockLevelDisplayName(StockLevel level) {
    switch (level) {
      case StockLevel.sufficient:
        return "在庫あり";
      case StockLevel.low:
        return "在庫少";
      case StockLevel.critical:
        return "緊急";
    }
  }

  /// コピー作成
  InventoryFilterState copyWith({
    String? searchQuery,
    String? selectedCategoryId,
    StockLevel? stockLevel,
    InventorySortType? sortBy,
    SortOrder? sortOrder,
  }) => InventoryFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      stockLevel: stockLevel ?? this.stockLevel,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );

  /// フィルターリセット
  InventoryFilterState reset() => const InventoryFilterState();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is InventoryFilterState &&
        other.searchQuery == searchQuery &&
        other.selectedCategoryId == selectedCategoryId &&
        other.stockLevel == stockLevel &&
        other.sortBy == sortBy &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(searchQuery, selectedCategoryId, stockLevel, sortBy, sortOrder);
}
