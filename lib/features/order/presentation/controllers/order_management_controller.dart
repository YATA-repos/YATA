import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// 注文管理画面で扱うメニューカテゴリの表示用データ。
@immutable
class MenuCategoryViewData {
  /// [MenuCategoryViewData]を生成する。
  const MenuCategoryViewData({required this.id, required this.label});

  /// カテゴリ識別子。
  final String id;

  /// 表示ラベル。
  final String label;
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
  });

  /// 商品ID。
  final String id;

  /// 表示名。
  final String name;

  /// 所属カテゴリID。
  final String categoryId;

  /// 価格（税抜き）。
  final int price;
}

/// 注文カートに表示するアイテム情報。
@immutable
class CartItemViewData {
  /// [CartItemViewData]を生成する。
  const CartItemViewData({required this.menuItem, required this.quantity});

  /// メニューアイテム。
  final MenuItemViewData menuItem;

  /// 数量。
  final int quantity;

  /// 小計金額。
  int get subtotal => menuItem.price * quantity;

  /// コピーを生成する。
  CartItemViewData copyWith({MenuItemViewData? menuItem, int? quantity}) =>
      CartItemViewData(menuItem: menuItem ?? this.menuItem, quantity: quantity ?? this.quantity);
}

/// 注文管理画面の状態。
@immutable
class OrderManagementState {
  /// [OrderManagementState]を生成する。
  OrderManagementState({
    required List<MenuCategoryViewData> categories,
    required List<MenuItemViewData> menuItems,
    required List<CartItemViewData> cartItems,
    this.selectedCategoryIndex = 0,
    this.searchQuery = "",
    this.orderNumber = "#1046",
    this.taxRate = 0.1,
    this.highlightedItemId,
  }) : categories = List<MenuCategoryViewData>.unmodifiable(categories),
       menuItems = List<MenuItemViewData>.unmodifiable(menuItems),
       cartItems = List<CartItemViewData>.unmodifiable(cartItems);

  /// デフォルトの初期状態を取得する。
  factory OrderManagementState.initial() {
    final List<MenuCategoryViewData> categories = <MenuCategoryViewData>[
      const MenuCategoryViewData(id: "all", label: "すべて"),
      const MenuCategoryViewData(id: "main", label: "メイン料理"),
      const MenuCategoryViewData(id: "side", label: "サイドメニュー"),
      const MenuCategoryViewData(id: "drink", label: "ドリンク"),
      const MenuCategoryViewData(id: "dessert", label: "デザート"),
    ];

    final List<MenuItemViewData> menuItems = <MenuItemViewData>[
      const MenuItemViewData(id: "item-1", name: "チキンラップ", categoryId: "main", price: 850),
      const MenuItemViewData(id: "item-2", name: "ファラフェルボウル", categoryId: "main", price: 975),
      const MenuItemViewData(id: "item-3", name: "アイスコーヒー", categoryId: "drink", price: 425),
      const MenuItemViewData(id: "item-4", name: "ベジバーガー", categoryId: "main", price: 1050),
      const MenuItemViewData(id: "item-5", name: "フレッシュレモネード", categoryId: "drink", price: 375),
      const MenuItemViewData(id: "item-6", name: "さつまいもフライ", categoryId: "side", price: 450),
      // * 以下ダミー商品: 長いリストの体感用
      const MenuItemViewData(id: "item-7", name: "グリルチキンプレート", categoryId: "main", price: 980),
      const MenuItemViewData(id: "item-8", name: "ガーリックシュリンプ", categoryId: "main", price: 1150),
      const MenuItemViewData(id: "item-9", name: "スパイシータコス", categoryId: "main", price: 900),
      const MenuItemViewData(id: "item-10", name: "日替わりスープ", categoryId: "side", price: 320),
      const MenuItemViewData(id: "item-11", name: "コールスロー", categoryId: "side", price: 280),
      const MenuItemViewData(id: "item-12", name: "オニオンリング", categoryId: "side", price: 390),
      const MenuItemViewData(id: "item-13", name: "ホットコーヒー", categoryId: "drink", price: 350),
      const MenuItemViewData(id: "item-14", name: "カフェラテ", categoryId: "drink", price: 480),
      const MenuItemViewData(id: "item-15", name: "緑茶（アイス）", categoryId: "drink", price: 300),
      const MenuItemViewData(id: "item-16", name: "クラフトコーラ", categoryId: "drink", price: 520),
      const MenuItemViewData(id: "item-17", name: "チョコブラウニー", categoryId: "dessert", price: 420),
      const MenuItemViewData(id: "item-18", name: "バスクチーズケーキ", categoryId: "dessert", price: 560),
      const MenuItemViewData(id: "item-19", name: "ソフトクリーム", categoryId: "dessert", price: 350),
      const MenuItemViewData(id: "item-20", name: "フルーツサンデー", categoryId: "dessert", price: 600),
      const MenuItemViewData(id: "item-21", name: "ベジタコス（2個）", categoryId: "main", price: 980),
      const MenuItemViewData(id: "item-22", name: "チキンケバブ", categoryId: "main", price: 1020),
      const MenuItemViewData(id: "item-23", name: "フムス＆ピタ", categoryId: "side", price: 500),
      const MenuItemViewData(id: "item-24", name: "スパークリングウォーター", categoryId: "drink", price: 260),
    ];

    final List<CartItemViewData> initialCart = <CartItemViewData>[
      CartItemViewData(menuItem: menuItems[0], quantity: 1), // チキンラップ
      CartItemViewData(menuItem: menuItems[2], quantity: 2), // アイスコーヒー
      CartItemViewData(menuItem: menuItems[5], quantity: 1), // さつまいもフライ
      CartItemViewData(menuItem: menuItems[3], quantity: 1), // ベジバーガー
      CartItemViewData(menuItem: menuItems[6], quantity: 1), // グリルチキンプレート
      CartItemViewData(menuItem: menuItems[7], quantity: 1), // ガーリックシュリンプ
      CartItemViewData(menuItem: menuItems[8], quantity: 2), // スパイシータコス
      CartItemViewData(menuItem: menuItems[9], quantity: 1), // 日替わりスープ
      CartItemViewData(menuItem: menuItems[10], quantity: 1), // コールスロー
      CartItemViewData(menuItem: menuItems[11], quantity: 1), // オニオンリング
      CartItemViewData(menuItem: menuItems[14], quantity: 1), // 緑茶（アイス）
      CartItemViewData(menuItem: menuItems[18], quantity: 1), // ソフトクリーム
    ];

    return OrderManagementState(
      categories: categories,
      menuItems: menuItems,
      cartItems: initialCart,
    );
  }

  /// 表示するカテゴリ一覧。
  final List<MenuCategoryViewData> categories;

  /// 全メニューアイテム。
  final List<MenuItemViewData> menuItems;

  /// カート内アイテム。
  final List<CartItemViewData> cartItems;

  /// 選択中のカテゴリインデックス。
  final int selectedCategoryIndex;

  /// 検索キーワード。
  final String searchQuery;

  /// 注文番号。
  final String orderNumber;

  /// 税率（例: 0.1 = 10%）。
  final double taxRate;

  /// 直近にハイライト表示する対象のメニューID（UI用・一時的）。
  final String? highlightedItemId;

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
    final String query = searchQuery.trim().toLowerCase();

    return menuItems
        .where((MenuItemViewData item) {
          final bool matchesCategory =
              category == null || category.id == "all" || item.categoryId == category.id;
          final bool matchesQuery = query.isEmpty || item.name.toLowerCase().contains(query);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
  }

  /// カート内に指定IDのアイテムが存在するか。
  bool isInCart(String menuItemId) =>
      cartItems.any((CartItemViewData item) => item.menuItem.id == menuItemId);

  /// 小計金額。
  int get subtotal =>
      cartItems.fold<int>(0, (int total, CartItemViewData item) => total + item.subtotal);

  /// 消費税。
  int get tax => (subtotal * taxRate).round();

  /// 合計金額。
  int get total => subtotal + tax;

  /// 金額を円表記で整形する。
  String formatPrice(int amount) => _formatCurrency(amount);

  /// 状態のコピーを生成する。
  OrderManagementState copyWith({
    List<CartItemViewData>? cartItems,
    int? selectedCategoryIndex,
    String? searchQuery,
    String? orderNumber,
    double? taxRate,
    String? highlightedItemId,
    bool clearHighlightedItemId = false,
  }) => OrderManagementState(
    categories: categories,
    menuItems: menuItems,
    cartItems: cartItems ?? this.cartItems,
    selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
    searchQuery: searchQuery ?? this.searchQuery,
    orderNumber: orderNumber ?? this.orderNumber,
    taxRate: taxRate ?? this.taxRate,
    highlightedItemId: clearHighlightedItemId
        ? null
        : (highlightedItemId ?? this.highlightedItemId),
  );
}

/// 注文管理画面の振る舞いを担うコントローラ。
class OrderManagementController extends StateNotifier<OrderManagementState> {
  /// [OrderManagementController]を生成する。
  OrderManagementController() : super(OrderManagementState.initial());

  int _highlightSeq = 0;

  void _triggerHighlight(String menuItemId) {
    final int token = ++_highlightSeq;
    state = state.copyWith(highlightedItemId: menuItemId);
    Future<void>.delayed(const Duration(milliseconds: 1200)).then((_) {
      if (_highlightSeq == token && state.highlightedItemId == menuItemId) {
        state = state.copyWith(clearHighlightedItemId: true);
      }
    });
  }

  /// カテゴリを選択する。
  void selectCategory(int index) {
    if (index == state.selectedCategoryIndex) {
      return;
    }
    state = state.copyWith(selectedCategoryIndex: index);
  }

  /// 検索キーワードを更新する。
  void updateSearchQuery(String query) {
    if (query == state.searchQuery) {
      return;
    }
    state = state.copyWith(searchQuery: query);
  }

  /// メニューをカートへ追加する。
  void addMenuItem(String menuItemId) {
    final MenuItemViewData? menuItem = _findMenuItem(menuItemId);
    if (menuItem == null) {
      return;
    }

    final List<CartItemViewData> updatedCart = List<CartItemViewData>.from(state.cartItems);
    final int existingIndex = updatedCart.indexWhere(
      (CartItemViewData item) => item.menuItem.id == menuItemId,
    );

    if (existingIndex >= 0) {
      final CartItemViewData current = updatedCart[existingIndex];
      updatedCart[existingIndex] = current.copyWith(quantity: current.quantity + 1);
    } else {
      updatedCart.add(CartItemViewData(menuItem: menuItem, quantity: 1));
    }

    state = state.copyWith(cartItems: updatedCart);
    _triggerHighlight(menuItemId);
  }

  /// カート内アイテムの数量を更新する。
  void updateItemQuantity(String menuItemId, int quantity) {
    final List<CartItemViewData> updatedCart = List<CartItemViewData>.from(state.cartItems);
    final int index = updatedCart.indexWhere(
      (CartItemViewData item) => item.menuItem.id == menuItemId,
    );

    if (index == -1) {
      return;
    }

    if (quantity <= 0) {
      updatedCart.removeAt(index);
    } else {
      updatedCart[index] = updatedCart[index].copyWith(quantity: quantity);
    }

    state = state.copyWith(cartItems: updatedCart);
    if (quantity > 0) {
      _triggerHighlight(menuItemId);
    } else if (state.highlightedItemId == menuItemId) {
      state = state.copyWith(clearHighlightedItemId: true);
    }
  }

  /// アイテムをカートから削除する。
  void removeItem(String menuItemId) {
    final List<CartItemViewData> updatedCart = state.cartItems
        .where((CartItemViewData item) => item.menuItem.id != menuItemId)
        .toList(growable: false);
    state = state.copyWith(cartItems: updatedCart);
    if (state.highlightedItemId == menuItemId) {
      state = state.copyWith(clearHighlightedItemId: true);
    }
  }

  /// カートをクリアする。
  void clearCart() {
    if (state.cartItems.isEmpty) {
      return;
    }
    state = state.copyWith(cartItems: <CartItemViewData>[], clearHighlightedItemId: true);
  }

  MenuItemViewData? _findMenuItem(String menuItemId) {
    for (final MenuItemViewData item in state.menuItems) {
      if (item.id == menuItemId) {
        return item;
      }
    }
    return null;
  }
}

/// 注文管理画面のStateNotifierプロバイダー。
final StateNotifierProvider<OrderManagementController, OrderManagementState>
orderManagementControllerProvider =
    StateNotifierProvider<OrderManagementController, OrderManagementState>(
      (Ref ref) => OrderManagementController(),
    );

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
