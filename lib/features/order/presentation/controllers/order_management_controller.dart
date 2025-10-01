import "dart:async";
import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/utils/error_handler.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../../menu/models/menu_model.dart";
import "../../../menu/services/menu_service.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "../../services/cart_service.dart";
import "../../services/order_service.dart";

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
       cartItems = List<CartItemViewData>.unmodifiable(cartItems);

  /// デフォルトの初期状態を取得する。
  factory OrderManagementState.initial() => OrderManagementState(
    categories: const <MenuCategoryViewData>[MenuCategoryViewData(id: "all", label: "すべて")],
    menuItems: const <MenuItemViewData>[],
    cartItems: const <CartItemViewData>[],
    isLoading: true,
    orderNotes: "",
  );

  /// 表示するカテゴリ一覧。
  final List<MenuCategoryViewData> categories;

  /// 全メニューアイテム。
  final List<MenuItemViewData> menuItems;

  /// カート内アイテム。
  final List<CartItemViewData> cartItems;

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
    final String query = searchQuery.trim().toLowerCase();

    return menuItems
        .where((MenuItemViewData item) {
          final bool matchesCategory =
              category == null || category.id == "all" || item.categoryId == category.id;
          final bool matchesQuery = query.isEmpty || item.name.toLowerCase().contains(query);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false)
      ..sort((MenuItemViewData a, MenuItemViewData b) => a.displayOrder.compareTo(b.displayOrder));
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

/// 注文管理画面の振る舞いを担うコントローラ。
class OrderManagementController extends StateNotifier<OrderManagementState> {
  /// [OrderManagementController]を生成する。
  OrderManagementController({
    required Ref ref,
    required MenuService menuService,
    required CartService cartService,
    required OrderService orderService,
  }) : _ref = ref,
       _menuService = menuService,
       _cartService = cartService,
       _orderService = orderService,
       super(OrderManagementState.initial()) {
    _authSubscription = _ref.listen<String?>(
      currentUserIdProvider,
      _handleUserChange,
      fireImmediately: false,
    );
    unawaited(loadInitialData());
  }

  final Ref _ref;
  final MenuService _menuService;
  final CartService _cartService;
  final OrderService _orderService;
  late final ProviderSubscription<String?> _authSubscription;

  final Map<String, MenuItemViewData> _menuItemCache = <String, MenuItemViewData>{};
  int _highlightSeq = 0;

  void _handleUserChange(String? previousUserId, String? nextUserId) {
    if (previousUserId == nextUserId) {
      return;
    }
    _menuItemCache.clear();
    _highlightSeq = 0;

    if (nextUserId == null) {
      state = OrderManagementState.initial();
      return;
    }

    unawaited(loadInitialData(reset: true));
  }

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }

  /// 初期データを読み込む。
  Future<void> loadInitialData({bool reset = false}) async {
    if (reset) {
      state = OrderManagementState.initial();
    } else {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
    }
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = state.copyWith(isLoading: false, errorMessage: "ユーザー情報を取得できませんでした。再度ログインしてください。");
      return;
    }

    try {
      final List<MenuCategory> categoryModels = await _menuService.getMenuCategories();
      final List<MenuItem> menuItemModels = await _menuService.getMenuItemsByCategory(null);
      _updateMenuCache(menuItemModels);

      final List<MenuCategoryViewData> categoryView = _buildCategoryView(categoryModels);
      final Order? cart = await _cartService.getActiveCart(userId);
      String? cartId = cart?.id;
      _CartSnapshot snapshot = const _CartSnapshot(items: <CartItemViewData>[]);
      if (cartId != null) {
        snapshot = await _loadCartSnapshot(cartId, userId);
        cartId = snapshot.cartId ?? cartId;
      }

      final List<MenuItemViewData> synchronisedMenu = _menuItemCache.values.toList()
        ..sort(
          (MenuItemViewData a, MenuItemViewData b) => a.displayOrder.compareTo(b.displayOrder),
        );

      final int safeIndex = categoryView.isEmpty
          ? 0
          : state.selectedCategoryIndex.clamp(0, categoryView.length - 1);

      state = state.copyWith(
        categories: categoryView,
        menuItems: synchronisedMenu,
        cartItems: snapshot.items,
        currentPaymentMethod:
            snapshot.paymentMethod ?? cart?.paymentMethod ?? state.currentPaymentMethod,
        cartId: cartId,
        orderNumber: snapshot.orderNumber ?? cart?.orderNumber,
        discountAmount: snapshot.discountAmount ?? cart?.discountAmount ?? 0,
        orderNotes: snapshot.orderNotes ?? cart?.notes ?? state.orderNotes,
        selectedCategoryIndex: safeIndex,
        isLoading: false,
        clearErrorMessage: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  /// データを再読み込みする。
  void refresh() {
    if (state.isCheckoutInProgress) {
      return;
    }
    unawaited(loadInitialData());
  }

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
    state = state.copyWith(selectedCategoryIndex: index, clearErrorMessage: true);
  }

  /// 検索キーワードを更新する。
  void updateSearchQuery(String query) {
    if (query == state.searchQuery) {
      return;
    }
    state = state.copyWith(searchQuery: query, clearErrorMessage: true);
  }

  /// メニューをカートへ追加する。
  void addMenuItem(String menuItemId) => unawaited(_addMenuItem(menuItemId));

  Future<void> _addMenuItem(String menuItemId) async {
    if (state.isCheckoutInProgress) {
      return;
    }
    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    final MenuItemViewData? menuItem = _menuItemCache[menuItemId] ?? _findMenuItem(menuItemId);
    if (menuItem == null) {
      state = state.copyWith(errorMessage: "選択したメニューが見つかりませんでした。");
      return;
    }

    final String? cartId = await _ensureCart(userId);
    if (cartId == null) {
      return;
    }

    try {
      state = state.copyWith(clearErrorMessage: true);
      await _cartService.addItemToCart(
        cartId,
        CartItemRequest(menuItemId: menuItemId, quantity: 1),
        userId,
      );
      await _refreshCart(cartId, userId);
      _triggerHighlight(menuItemId);
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
    }
  }

  /// カート内アイテムの数量を更新する。
  void updateItemQuantity(String menuItemId, int quantity) =>
      unawaited(_updateItemQuantity(menuItemId, quantity));

  Future<void> _updateItemQuantity(String menuItemId, int quantity) async {
    if (state.isCheckoutInProgress) {
      return;
    }
    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    final String? cartId = state.cartId ?? await _ensureCart(userId);
    if (cartId == null) {
      return;
    }

    CartItemViewData? target;
    String? orderItemId;
    for (final CartItemViewData item in state.cartItems) {
      if (item.menuItem.id == menuItemId) {
        target = item;
        orderItemId = item.orderItemId;
        break;
      }
    }

    if (target == null || orderItemId == null) {
      if (quantity > 0) {
        await _addMenuItem(menuItemId);
      }
      return;
    }

    try {
      state = state.copyWith(clearErrorMessage: true);
      if (quantity <= 0) {
        await _cartService.removeItemFromCart(cartId, orderItemId, userId);
      } else {
        await _cartService.updateCartItemQuantity(cartId, orderItemId, quantity, userId);
      }
      await _refreshCart(cartId, userId);
      if (quantity > 0) {
        _triggerHighlight(menuItemId);
      }
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
    }
  }

  /// アイテムをカートから削除する。
  void removeItem(String menuItemId) => unawaited(_removeItem(menuItemId));

  Future<void> _removeItem(String menuItemId) async {
    if (state.isCheckoutInProgress) {
      return;
    }
    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    final String? cartId = state.cartId;
    if (cartId == null) {
      return;
    }

    CartItemViewData? target;
    String? orderItemId;
    for (final CartItemViewData item in state.cartItems) {
      if (item.menuItem.id == menuItemId) {
        target = item;
        orderItemId = item.orderItemId;
        break;
      }
    }

    if (target == null || orderItemId == null) {
      state = state.copyWith(
        cartItems: state.cartItems
            .where((CartItemViewData item) => item.menuItem.id != menuItemId)
            .toList(growable: false),
        clearHighlightedItemId: state.highlightedItemId == menuItemId,
      );
      return;
    }

    try {
      state = state.copyWith(clearErrorMessage: true);
      await _cartService.removeItemFromCart(cartId, orderItemId, userId);
      await _refreshCart(cartId, userId);
      if (state.highlightedItemId == menuItemId) {
        state = state.copyWith(clearHighlightedItemId: true);
      }
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
    }
  }

  /// 支払い方法を更新する。
  Future<void> updatePaymentMethod(PaymentMethod method) async {
    if (state.isCheckoutInProgress || state.isLoading || method == state.currentPaymentMethod) {
      return;
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    final PaymentMethod previous = state.currentPaymentMethod;

    String? cartId = state.cartId;
    cartId ??= await _ensureCart(userId);
    if (cartId == null) {
      state = state.copyWith(
        currentPaymentMethod: previous,
        errorMessage: "カート情報を取得できませんでした。再度お試しください。",
      );
      return;
    }

    state = state.copyWith(currentPaymentMethod: method, clearErrorMessage: true);

    try {
      await _cartService.updateCartPaymentMethod(cartId, method, userId);
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(
        currentPaymentMethod: previous,
        errorMessage: message,
      );
    }
  }

  /// カートを会計処理する。
  Future<CheckoutActionResult> checkout() async {
    if (state.isCheckoutInProgress) {
      return CheckoutActionResult.failure(message: "会計処理中です。");
    }

    if (state.cartItems.isEmpty) {
      return CheckoutActionResult.emptyCart(message: "カートに商品がありません。");
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      return CheckoutActionResult.authenticationFailed(
        message: "ユーザー情報を取得できませんでした。再度ログインしてください。",
      );
    }

    state = state.copyWith(isCheckoutInProgress: true, clearErrorMessage: true);

    try {
      String? cartId = state.cartId;
      cartId ??= await _ensureCart(userId);
      if (cartId == null) {
        state = state.copyWith(isCheckoutInProgress: false);
        return CheckoutActionResult.missingCart(message: "カート情報の取得に失敗しました。");
      }

      final OrderCheckoutRequest request = OrderCheckoutRequest(
        paymentMethod: state.currentPaymentMethod,
        discountAmount: state.discountAmount,
        notes: state.orderNotes.isEmpty ? null : state.orderNotes,
      );

      final OrderCheckoutResult result =
          await _orderService.checkoutCart(cartId, request, userId);

      if (!result.isSuccess || result.isStockInsufficient) {
        const String message = "在庫が不足している商品があります。数量を調整して再度お試しください。";
        state = state.copyWith(
          isCheckoutInProgress: false,
          errorMessage: message,
        );
        return CheckoutActionResult.stockInsufficient(result.order, message: message);
      }

      final Order? newCart = result.newCart;
      if (newCart == null) {
        const String message = "新しいカートの初期化に失敗しました。";
        state = state.copyWith(
          isCheckoutInProgress: false,
          errorMessage: message,
        );
        return CheckoutActionResult.failure(order: result.order, message: message);
      }

      state = state.copyWith(
        isCheckoutInProgress: false,
        cartItems: const <CartItemViewData>[],
        cartId: newCart.id,
        orderNumber: newCart.orderNumber,
        discountAmount: newCart.discountAmount,
        currentPaymentMethod: newCart.paymentMethod,
        clearHighlightedItemId: true,
        clearErrorMessage: true,
        orderNotes: "",
      );

  await loadInitialData(reset: true);

      return CheckoutActionResult.success(result.order);
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(
        isCheckoutInProgress: false,
        errorMessage: message,
      );
      return CheckoutActionResult.failure(message: message);
    }
  }

  /// カートをクリアする。
  void clearCart() => unawaited(_clearCart());

  Future<void> _clearCart() async {
    if (state.isCheckoutInProgress) {
      return;
    }
    if (state.cartItems.isEmpty) {
      return;
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    final String? cartId = state.cartId;
    if (cartId == null) {
      state = state.copyWith(
        cartItems: <CartItemViewData>[],
        clearHighlightedItemId: true,
        orderNotes: "",
      );
      return;
    }

    try {
      state = state.copyWith(clearErrorMessage: true, orderNotes: "");
      await _cartService.clearCart(cartId, userId);
      await _refreshCart(cartId, userId);
      state = state.copyWith(clearHighlightedItemId: true);
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
    }
  }

  /// 注文メモを更新する。
  void updateOrderNotes(String notes) {
    if (notes == state.orderNotes) {
      return;
    }
    state = state.copyWith(orderNotes: notes, clearErrorMessage: true);
  }

  MenuItemViewData? _findMenuItem(String menuItemId) {
    for (final MenuItemViewData item in state.menuItems) {
      if (item.id == menuItemId) {
        return item;
      }
    }
    return null;
  }

  String? _ensureUserId() {
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = state.copyWith(errorMessage: "ユーザー情報を取得できませんでした。再度ログインしてください。");
    }
    return userId;
  }

  Future<String?> _ensureCart(String userId) async {
    if (state.cartId != null) {
      return state.cartId;
    }
    try {
      final Order? cart = await _cartService.getOrCreateActiveCart(userId);
      if (cart == null || cart.id == null) {
        state = state.copyWith(errorMessage: "カートの初期化に失敗しました。");
        return null;
      }
      state = state.copyWith(
        cartId: cart.id,
        orderNumber: cart.orderNumber,
        discountAmount: cart.discountAmount,
        currentPaymentMethod: cart.paymentMethod,
        orderNotes: cart.notes ?? "",
        clearErrorMessage: true,
      );
      return cart.id;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
      return null;
    }
  }

  void _updateMenuCache(List<MenuItem> items) {
    for (final MenuItem item in items) {
      final MenuItemViewData? view = _mapMenuItem(item);
      if (view != null) {
        _menuItemCache[view.id] = view;
      }
    }
  }

  List<MenuCategoryViewData> _buildCategoryView(List<MenuCategory> categories) {
    final List<MenuCategoryViewData> list = <MenuCategoryViewData>[
      const MenuCategoryViewData(id: "all", label: "すべて"),
    ];
    final Set<String> seenIds = <String>{"all"};
    for (final MenuCategory category in categories) {
      final String? id = category.id;
      if (id == null || seenIds.contains(id)) {
        continue;
      }
      seenIds.add(id);
      list.add(
        MenuCategoryViewData(id: id, label: category.name, displayOrder: category.displayOrder),
      );
    }
    list.sort(
      (MenuCategoryViewData a, MenuCategoryViewData b) => a.displayOrder.compareTo(b.displayOrder),
    );
    return list;
  }

  MenuItemViewData? _mapMenuItem(MenuItem item) {
    final String? id = item.id;
    if (id == null) {
      return null;
    }
    return MenuItemViewData(
      id: id,
      name: item.name,
      categoryId: item.categoryId,
      price: item.price,
      description: item.description,
      isAvailable: item.isAvailable,
      displayOrder: item.displayOrder,
    );
  }

  Future<_CartSnapshot> _loadCartSnapshot(String cartId, String userId) async {
    try {
      final Map<String, dynamic>? data = await _orderService.getOrderWithItems(cartId, userId);
      if (data == null) {
        return _CartSnapshot(items: const <CartItemViewData>[], cartId: cartId);
      }

      final Order order = data["order"] as Order;
      final List<Map<String, dynamic>> rawItems = (data["items"] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final List<CartItemViewData> items = <CartItemViewData>[];
      for (final Map<String, dynamic> entry in rawItems) {
        final OrderItem orderItem = entry["order_item"] as OrderItem;
        MenuItemViewData? menuView = _menuItemCache[orderItem.menuItemId];
        final MenuItem? menuItemModel = entry["menu_item"] as MenuItem?;
        if (menuView == null && menuItemModel != null) {
          final MenuItemViewData? mapped = _mapMenuItem(menuItemModel);
          if (mapped != null) {
            _menuItemCache[mapped.id] = mapped;
            menuView = mapped;
          }
        }
        if (menuView == null) {
          continue;
        }
        items.add(
          CartItemViewData(
            menuItem: menuView,
            quantity: orderItem.quantity,
            orderItemId: orderItem.id,
            selectedOptions: orderItem.selectedOptions,
            notes: orderItem.specialRequest,
          ),
        );
      }

      return _CartSnapshot(
        items: items,
        orderNumber: order.orderNumber,
        discountAmount: order.discountAmount,
        paymentMethod: order.paymentMethod,
        cartId: order.id ?? cartId,
        orderNotes: order.notes,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
      return _CartSnapshot(items: const <CartItemViewData>[], cartId: cartId);
    }
  }

  Future<void> _refreshCart(String cartId, String userId) async {
    final _CartSnapshot snapshot = await _loadCartSnapshot(cartId, userId);
    final List<MenuItemViewData> menuView = _menuItemCache.values.toList()
      ..sort((MenuItemViewData a, MenuItemViewData b) => a.displayOrder.compareTo(b.displayOrder));

    state = state.copyWith(
      cartItems: snapshot.items,
      menuItems: menuView,
      currentPaymentMethod: snapshot.paymentMethod ?? state.currentPaymentMethod,
      orderNumber: snapshot.orderNumber ?? state.orderNumber,
      discountAmount: snapshot.discountAmount ?? state.discountAmount,
      cartId: snapshot.cartId ?? state.cartId,
      orderNotes: snapshot.orderNotes ?? state.orderNotes,
      clearErrorMessage: true,
    );
  }
}

/// 注文管理画面のStateNotifierプロバイダー。
final StateNotifierProvider<OrderManagementController, OrderManagementState>
    orderManagementControllerProvider =
    StateNotifierProvider<OrderManagementController, OrderManagementState>(
      (Ref ref) => OrderManagementController(
        ref: ref,
        menuService: ref.read(menuServiceProvider),
        cartService: ref.read(cartServiceProvider),
        orderService: ref.read(orderServiceProvider),
      ),
    );

class _CartSnapshot {
  const _CartSnapshot({
    required this.items,
    this.orderNumber,
    this.discountAmount,
    this.paymentMethod,
    this.cartId,
    this.orderNotes,
  });

  final List<CartItemViewData> items;
  final String? orderNumber;
  final int? discountAmount;
  final PaymentMethod? paymentMethod;
  final String? cartId;
  final String? orderNotes;
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

/// 会計アクションの状態フラグ。
enum CheckoutActionStatus {
  /// 会計が成功した。
  success,

  /// 在庫不足などで会計に失敗した。
  stockInsufficient,

  /// カートが空だった。
  emptyCart,

  /// ユーザー情報が取得できなかった。
  authenticationFailed,

  /// カートが取得できなかった。
  missingCart,

  /// その他のエラーが発生した。
  failure,
}

/// 会計アクションの結果情報。
class CheckoutActionResult {
  const CheckoutActionResult._({
    required this.status,
    this.order,
    this.message,
  });

  /// 成功結果を生成する。
  factory CheckoutActionResult.success(Order order) => CheckoutActionResult._(
        status: CheckoutActionStatus.success,
        order: order,
      );

  /// 在庫不足による失敗結果を生成する。
  factory CheckoutActionResult.stockInsufficient(Order order, {String? message}) =>
      CheckoutActionResult._(
        status: CheckoutActionStatus.stockInsufficient,
        order: order,
        message: message,
      );

  /// カートが空の場合の結果を生成する。
  factory CheckoutActionResult.emptyCart({String? message}) => CheckoutActionResult._(
        status: CheckoutActionStatus.emptyCart,
        message: message,
      );

  /// 認証失敗時の結果を生成する。
  factory CheckoutActionResult.authenticationFailed({String? message}) =>
      CheckoutActionResult._(
        status: CheckoutActionStatus.authenticationFailed,
        message: message,
      );

  /// カート取得失敗時の結果を生成する。
  factory CheckoutActionResult.missingCart({String? message}) => CheckoutActionResult._(
        status: CheckoutActionStatus.missingCart,
        message: message,
      );

  /// その他のエラーの場合の結果を生成する。
  factory CheckoutActionResult.failure({String? message, Order? order}) =>
      CheckoutActionResult._(
        status: CheckoutActionStatus.failure,
        order: order,
        message: message,
      );

  /// 結果状態。
  final CheckoutActionStatus status;

  /// 処理対象となった注文。
  final Order? order;

  /// 結果に付随するメッセージ。
  final String? message;

  /// 成功したかどうか。
  bool get isSuccess => status == CheckoutActionStatus.success;
}
