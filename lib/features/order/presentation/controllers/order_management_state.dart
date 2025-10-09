import "dart:math" as math;

import "package:flutter/foundation.dart";

import "../../../../core/constants/enums.dart";
import "../performance/order_management_tracing.dart";

/// 注文管理画面で扱うメニューカテゴリの表示用データ。
@immutable
class MenuCategoryViewData {
  /// [MenuCategoryViewData]を生成する。
  const MenuCategoryViewData({required this.id, required this.label, this.displayOrder = 0});

  /// カテゴリ識別子。
  final String id;

  /// 表示ラベル。
  final String label;

  /// 表示順序。
  final int displayOrder;

  /// コピーを生成する。
  MenuCategoryViewData copyWith({String? id, String? label, int? displayOrder}) =>
      MenuCategoryViewData(
        id: id ?? this.id,
        label: label ?? this.label,
        displayOrder: displayOrder ?? this.displayOrder,
      );
}

/// 注文管理画面で扱うメニューアイテムの表示用データ。
@immutable
class MenuItemViewData {
  /// [MenuItemViewData]を生成する。
  const MenuItemViewData({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.description,
    this.isAvailable = true,
    this.displayOrder = 0,
  });

  /// 商品ID。
  final String id;

  /// 表示名。
  final String name;

  /// 所属カテゴリID。
  final String categoryId;

  /// 価格（税抜き）。
  final int price;

  /// 説明。
  final String? description;

  /// 販売可能かどうか。
  final bool isAvailable;

  /// 表示順序。
  final int displayOrder;

  /// コピーを生成する。
  MenuItemViewData copyWith({
    String? id,
    String? name,
    String? categoryId,
    int? price,
    String? description,
    bool? isAvailable,
    int? displayOrder,
  }) => MenuItemViewData(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    price: price ?? this.price,
    description: description ?? this.description,
    isAvailable: isAvailable ?? this.isAvailable,
    displayOrder: displayOrder ?? this.displayOrder,
  );
}

/// 注文カートに表示するアイテム情報。
@immutable
class CartItemViewData {
  /// [CartItemViewData]を生成する。
  const CartItemViewData({
    required this.menuItem,
    required this.quantity,
    this.orderItemId,
    this.selectedOptions,
    this.notes,
    this.hasSufficientStock,
  });

  /// メニューアイテム。
  final MenuItemViewData menuItem;

  /// 数量。
  final int quantity;

  /// 注文明細ID。
  final String? orderItemId;

  /// 選択オプション。
  final Map<String, String>? selectedOptions;

  /// 特記事項。
  final String? notes;

  /// 在庫が十分かどうか。
  final bool? hasSufficientStock;

  /// 小計金額。
  int get subtotal => menuItem.price * quantity;

  /// コピーを生成する。
  CartItemViewData copyWith({
    MenuItemViewData? menuItem,
    int? quantity,
    String? orderItemId,
    Map<String, String>? selectedOptions,
    String? notes,
    bool? hasSufficientStock,
  }) => CartItemViewData(
    menuItem: menuItem ?? this.menuItem,
    quantity: quantity ?? this.quantity,
    orderItemId: orderItemId ?? this.orderItemId,
    selectedOptions: selectedOptions ?? this.selectedOptions,
    notes: notes ?? this.notes,
    hasSufficientStock: hasSufficientStock ?? this.hasSufficientStock,
  );
}

/// 注文管理画面の状態。
@immutable
class OrderManagementState {
  /// [OrderManagementState]を生成する。
  OrderManagementState({
    required List<MenuCategoryViewData> categories,
    required List<MenuItemViewData> menuItems,
    required List<CartItemViewData> cartItems,
    this.currentPaymentMethod = PaymentMethod.cash,
    this.selectedCategoryIndex = 0,
    this.searchQuery = "",
    this.orderNumber,
    this.taxRate = 0.1,
    this.highlightedItemId,
    this.cartId,
    this.discountAmount = 0,
    this.isCheckoutInProgress = false,
    this.isLoading = false,
    this.errorMessage,
    this.orderNotes = "",
  }) : categories = List<MenuCategoryViewData>.unmodifiable(categories),
       menuItems = List<MenuItemViewData>.unmodifiable(menuItems),
       cartItems = List<CartItemViewData>.unmodifiable(cartItems),
       cartItemByMenuId = Map<String, CartItemViewData>.unmodifiable(<String, CartItemViewData>{
         for (final CartItemViewData item in cartItems) item.menuItem.id: item,
       });

  /// デフォルトの初期状態を取得する。
  factory OrderManagementState.initial() => OrderManagementState(
    categories: const <MenuCategoryViewData>[MenuCategoryViewData(id: "all", label: "すべて")],
    menuItems: const <MenuItemViewData>[],
    cartItems: const <CartItemViewData>[],
    isLoading: true,
  );

  /// 表示するカテゴリ一覧。
  final List<MenuCategoryViewData> categories;

  /// 全メニューアイテム。
  final List<MenuItemViewData> menuItems;

  /// カート内アイテム。
  final List<CartItemViewData> cartItems;

  /// メニューIDをキーとしたカートアイテムの参照キャッシュ。
  final Map<String, CartItemViewData> cartItemByMenuId;

  /// 選択中の支払い方法。
  final PaymentMethod currentPaymentMethod;

  /// 選択中のカテゴリインデックス。
  final int selectedCategoryIndex;

  /// 検索キーワード。
  final String searchQuery;

  /// 注文番号。
  final String? orderNumber;

  /// 税率（例: 0.1 = 10%）。
  final double taxRate;

  /// 直近にハイライト表示する対象のメニューID（UI用・一時的）。
  final String? highlightedItemId;

  /// カートID（注文ID）。
  final String? cartId;

  /// 割引額。
  final int discountAmount;

  /// 会計処理中かどうか。
  final bool isCheckoutInProgress;

  /// ローディング中かどうか。
  final bool isLoading;

  /// エラーメッセージ。
  final String? errorMessage;

  /// 注文メモ。
  final String orderNotes;

  /// 選択中のカテゴリ。
  MenuCategoryViewData? get selectedCategory {
    if (categories.isEmpty ||
        selectedCategoryIndex < 0 ||
        selectedCategoryIndex >= categories.length) {
      return null;
    }
    return categories[selectedCategoryIndex];
  }

  /// カテゴリ・検索条件で絞り込んだメニュー一覧。
  List<MenuItemViewData> get filteredMenuItems {
    final MenuCategoryViewData? category = selectedCategory;
    final String rawQuery = searchQuery.trim();
    final String normalizedQuery = rawQuery.toLowerCase();
    int resultCount = 0;

    final List<MenuItemViewData> result = OrderManagementTracer.traceSync<List<MenuItemViewData>>(
      "state.filteredMenuItems",
      () {
        final Iterable<MenuItemViewData> filtered = menuItems.where((MenuItemViewData item) {
          final bool matchesCategory =
              category == null || category.id == "all" || item.categoryId == category.id;
          final bool matchesQuery =
              normalizedQuery.isEmpty || item.name.toLowerCase().contains(normalizedQuery);
          return matchesCategory && matchesQuery;
        });
        final List<MenuItemViewData> list = List<MenuItemViewData>.unmodifiable(filtered);
        resultCount = list.length;
        return list;
      },
      startArguments: () => <String, dynamic>{
        "category": category?.id ?? "all",
        "queryLength": normalizedQuery.length,
        "sourceCount": menuItems.length,
      },
      finishArguments: () => <String, dynamic>{"resultCount": resultCount},
      logThreshold: const Duration(milliseconds: 4),
    );

    OrderManagementTracer.logLazy(
      () =>
          "state.filteredMenuItems category=${category?.id ?? "all"} query=\"${rawQuery.replaceAll("\n", " ")}\" result=$resultCount/${menuItems.length}",
    );

    return result;
  }

  /// カート内に指定IDのアイテムが存在するか。
  bool isInCart(String menuItemId) => cartItemByMenuId.containsKey(menuItemId);

  /// 指定IDのアイテム数量を取得する。
  int? quantityFor(String menuItemId) => cartItemByMenuId[menuItemId]?.quantity;

  /// 小計金額。
  int get subtotal =>
      cartItems.fold<int>(0, (int total, CartItemViewData item) => total + item.subtotal);

  /// 消費税。
  int get tax => (subtotal * taxRate).round();

  /// 合計金額。
  int get total {
    final int value = subtotal + tax - discountAmount;
    return math.max(0, value);
  }

  /// 金額を円表記で整形する。
  String formatPrice(int amount) => _formatCurrency(amount);

  /// 状態のコピーを生成する。
  OrderManagementState copyWith({
    List<MenuCategoryViewData>? categories,
    List<MenuItemViewData>? menuItems,
    List<CartItemViewData>? cartItems,
    PaymentMethod? currentPaymentMethod,
    int? selectedCategoryIndex,
    String? searchQuery,
    String? orderNumber,
    double? taxRate,
    String? highlightedItemId,
    bool clearHighlightedItemId = false,
    String? cartId,
    int? discountAmount,
    bool? isCheckoutInProgress,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? orderNotes,
  }) => OrderManagementState(
    categories: categories ?? this.categories,
    menuItems: menuItems ?? this.menuItems,
    cartItems: cartItems ?? this.cartItems,
    currentPaymentMethod: currentPaymentMethod ?? this.currentPaymentMethod,
    selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
    searchQuery: searchQuery ?? this.searchQuery,
    orderNumber: orderNumber ?? this.orderNumber,
    taxRate: taxRate ?? this.taxRate,
    highlightedItemId: clearHighlightedItemId
        ? null
        : (highlightedItemId ?? this.highlightedItemId),
    cartId: cartId ?? this.cartId,
    discountAmount: discountAmount ?? this.discountAmount,
    isCheckoutInProgress: isCheckoutInProgress ?? this.isCheckoutInProgress,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    orderNotes: orderNotes ?? this.orderNotes,
  );
}

String _formatCurrency(int amount) {
  final String sign = amount < 0 ? "-" : "";
  final String digits = amount.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int index = 0; index < digits.length; index++) {
    if (index != 0 && index % 3 == 0) {
      buffer.write(",");
    }
    buffer.write(digits[digits.length - index - 1]);
  }

  final String formatted = buffer.toString().split("").reversed.join();
  return "¥$sign$formatted";
}
