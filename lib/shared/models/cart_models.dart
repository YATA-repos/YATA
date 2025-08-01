import "package:flutter/foundation.dart";

import "../../features/menu/models/menu_model.dart";
import "../../features/order/models/order_model.dart";

/// カート専用軽量モデル
/// UI専用の状態管理に特化、既存OrderItemとの相互変換が可能

/// カート内アイテム
/// MenuItemから作成され、OrderItemに変換可能
@immutable
class CartItem {
  const CartItem({
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.selectedOptions,
    this.specialRequest,
  });

  /// 既存OrderItemからの作成
  factory CartItem.fromOrderItem(OrderItem orderItem) => CartItem(
    menuItemId: orderItem.menuItemId,
    name: "商品名", // 実際にはMenuItemから取得が必要
    unitPrice: orderItem.unitPrice,
    quantity: orderItem.quantity,
    selectedOptions: orderItem.selectedOptions,
    specialRequest: orderItem.specialRequest,
  );

  /// 既存MenuItemからの作成
  factory CartItem.fromMenuItem(MenuItem menuItem, {int quantity = 1}) => CartItem(
    menuItemId: menuItem.id!,
    name: menuItem.name,
    unitPrice: menuItem.price,
    quantity: quantity,
  );

  final String menuItemId;
  final String name;
  final int unitPrice;
  final int quantity;
  final Map<String, String>? selectedOptions;
  final String? specialRequest;

  /// 小計計算
  int get totalPrice => unitPrice * quantity;

  /// UI表示用の価格フォーマット
  String get formattedUnitPrice {
    final String formattedNumber = unitPrice.toString().replaceAllMapped(
      RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
      (Match match) => "${match[1]},",
    );
    return "¥$formattedNumber";
  }

  /// UI表示用の小計フォーマット
  String get formattedTotalPrice {
    final String formattedNumber = totalPrice.toString().replaceAllMapped(
      RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
      (Match match) => "${match[1]},",
    );
    return "¥$formattedNumber";
  }

  /// OrderItemへの変換
  OrderItem toOrderItem(String orderId, String userId) => OrderItem(
    orderId: orderId,
    menuItemId: menuItemId,
    quantity: quantity,
    unitPrice: unitPrice,
    subtotal: totalPrice,
    selectedOptions: selectedOptions,
    specialRequest: specialRequest,
    userId: userId,
  );

  /// コピー作成（immutable対応）
  CartItem copyWith({
    String? menuItemId,
    String? name,
    int? unitPrice,
    int? quantity,
    Map<String, String>? selectedOptions,
    String? specialRequest,
  }) => CartItem(
    menuItemId: menuItemId ?? this.menuItemId,
    name: name ?? this.name,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    selectedOptions: selectedOptions ?? this.selectedOptions,
    specialRequest: specialRequest ?? this.specialRequest,
  );

  /// 数量変更用のヘルパー
  CartItem withQuantity(int newQuantity) => copyWith(quantity: newQuantity);

  /// オプション追加用のヘルパー
  CartItem withOptions(Map<String, String> options) => copyWith(selectedOptions: options);

  /// 特別リクエスト追加用のヘルパー
  CartItem withSpecialRequest(String request) => copyWith(specialRequest: request);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CartItem &&
        other.menuItemId == menuItemId &&
        other.name == name &&
        other.unitPrice == unitPrice &&
        other.quantity == quantity &&
        mapEquals(other.selectedOptions, selectedOptions) &&
        other.specialRequest == specialRequest;
  }

  @override
  int get hashCode =>
      Object.hash(menuItemId, name, unitPrice, quantity, selectedOptions, specialRequest);

  @override
  String toString() =>
      "CartItem(menuItemId: $menuItemId, name: $name, "
      "unitPrice: $unitPrice, quantity: $quantity, "
      "totalPrice: $totalPrice)";
}

/// カート状態管理
/// アプリケーション全体のカート状態を管理
@immutable
class CartState {
  const CartState({
    this.items = const <CartItem>[],
    this.totalAmount = 0,
    this.itemCount = 0,
    this.discountAmount = 0,
    this.notes,
  });

  /// 既存OrderItemリストからの作成
  factory CartState.fromOrderItems(List<OrderItem> orderItems) {
    final List<CartItem> cartItems = orderItems.map(CartItem.fromOrderItem).toList();
    final int total = cartItems.fold(0, (int sum, CartItem item) => sum + item.totalPrice);
    final int count = cartItems.fold(0, (int sum, CartItem item) => sum + item.quantity);

    return CartState(items: cartItems, totalAmount: total, itemCount: count);
  }

  /// カート状態の再計算
  /// アイテムリストから合計金額と個数を再計算
  factory CartState.recalculate(List<CartItem> items, {int discountAmount = 0, String? notes}) {
    final int total = items.fold(0, (int sum, CartItem item) => sum + item.totalPrice);
    final int count = items.fold(0, (int sum, CartItem item) => sum + item.quantity);

    return CartState(
      items: items,
      totalAmount: total,
      itemCount: count,
      discountAmount: discountAmount,
      notes: notes,
    );
  }

  final List<CartItem> items;
  final int totalAmount;
  final int itemCount;
  final int discountAmount;
  final String? notes;

  /// 最終的な支払い金額
  int get finalAmount => totalAmount - discountAmount;

  /// カートが空かどうか
  bool get isEmpty => items.isEmpty;

  /// カートにアイテムがあるかどうか
  bool get isNotEmpty => items.isNotEmpty;

  /// UI表示用の合計金額フォーマット
  String get formattedTotalAmount {
    final String formattedNumber = totalAmount.toString().replaceAllMapped(
      RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
      (Match match) => "${match[1]},",
    );
    return "¥$formattedNumber";
  }

  /// UI表示用の最終金額フォーマット
  String get formattedFinalAmount {
    final String formattedNumber = finalAmount.toString().replaceAllMapped(
      RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
      (Match match) => "${match[1]},",
    );
    return "¥$formattedNumber";
  }

  /// UI表示用の割引額フォーマット
  String? get formattedDiscountAmount {
    if (discountAmount > 0) {
      final String formattedNumber = discountAmount.toString().replaceAllMapped(
        RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
        (Match match) => "${match[1]},",
      );
      return "-¥$formattedNumber";
    }
    return null;
  }

  /// OrderItemリストへの変換
  List<OrderItem> toOrderItems(String orderId, String userId) =>
      items.map((CartItem item) => item.toOrderItem(orderId, userId)).toList();

  /// コピー作成（immutable対応）
  CartState copyWith({
    List<CartItem>? items,
    int? totalAmount,
    int? itemCount,
    int? discountAmount,
    String? notes,
  }) => CartState(
    items: items ?? this.items,
    totalAmount: totalAmount ?? this.totalAmount,
    itemCount: itemCount ?? this.itemCount,
    discountAmount: discountAmount ?? this.discountAmount,
    notes: notes ?? this.notes,
  );

  /// アイテム追加
  CartState addItem(CartItem newItem) {
    final int existingIndex = items.indexWhere(
      (CartItem item) =>
          item.menuItemId == newItem.menuItemId &&
          mapEquals(item.selectedOptions, newItem.selectedOptions),
    );

    List<CartItem> updatedItems;
    if (existingIndex != -1) {
      // 既存アイテムの数量を増加
      updatedItems = List<CartItem>.from(items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + newItem.quantity,
      );
    } else {
      // 新規アイテムを追加
      updatedItems = <CartItem>[...items, newItem];
    }

    return CartState.recalculate(updatedItems, discountAmount: discountAmount, notes: notes);
  }

  /// アイテム削除
  CartState removeItem(String menuItemId, {Map<String, String>? options}) {
    final List<CartItem> updatedItems = items
        .where(
          (CartItem item) =>
              !(item.menuItemId == menuItemId && mapEquals(item.selectedOptions, options)),
        )
        .toList();

    return CartState.recalculate(updatedItems, discountAmount: discountAmount, notes: notes);
  }

  /// アイテム数量更新
  CartState updateItemQuantity(String menuItemId, int quantity, {Map<String, String>? options}) {
    if (quantity <= 0) {
      return removeItem(menuItemId, options: options);
    }

    final List<CartItem> updatedItems = items.map((CartItem item) {
      if (item.menuItemId == menuItemId && mapEquals(item.selectedOptions, options)) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    return CartState.recalculate(updatedItems, discountAmount: discountAmount, notes: notes);
  }

  /// カートクリア
  CartState clear() => const CartState();

  /// 割引適用
  CartState applyDiscount(int discount) => copyWith(discountAmount: discount);

  /// 備考追加
  CartState addNotes(String newNotes) => copyWith(notes: newNotes);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CartState &&
        listEquals(other.items, items) &&
        other.totalAmount == totalAmount &&
        other.itemCount == itemCount &&
        other.discountAmount == discountAmount &&
        other.notes == notes;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(items), totalAmount, itemCount, discountAmount, notes);

  @override
  String toString() =>
      "CartState(items: ${items.length}, totalAmount: $totalAmount, "
      "itemCount: $itemCount, finalAmount: $finalAmount)";
}
