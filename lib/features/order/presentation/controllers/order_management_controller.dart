import "dart:async";
import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../../core/utils/error_handler.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../../menu/models/menu_model.dart";
import "../../../menu/services/menu_service.dart";
import "../../../shared/logging/ui_action_logger.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "../../services/cart_service.dart";
import "../../services/models/cart_snapshot.dart";
import "../../services/order_service.dart";
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

/// 注文管理画面の振る舞いを担うコントローラ。
class OrderManagementController extends StateNotifier<OrderManagementState> {
  /// [OrderManagementController]を生成する。
  OrderManagementController({
    required Ref ref,
    required MenuService menuService,
    required CartService cartService,
    required OrderService orderService,
    required log_contract.LoggerContract logger,
  }) : _ref = ref,
       _menuService = menuService,
       _cartService = cartService,
       _orderService = orderService,
       _logger = logger,
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
  final log_contract.LoggerContract _logger;
  late final ProviderSubscription<String?> _authSubscription;

  final Map<String, MenuItemViewData> _menuItemCache = <String, MenuItemViewData>{};
  int _highlightSeq = 0;

  Future<T> _traceAsyncSection<T>(
    String name,
    Future<T> Function() action, {
    TraceArgumentsBuilder? startArguments,
    TraceArgumentsBuilder? finishArguments,
    Duration? logThreshold,
  }) => OrderManagementTracer.traceAsync<T>(
    "controller.$name",
    action,
    startArguments: startArguments,
    finishArguments: finishArguments,
    logThreshold: logThreshold,
  );

  T _traceSyncSection<T>(
    String name,
    T Function() action, {
    TraceArgumentsBuilder? startArguments,
    TraceArgumentsBuilder? finishArguments,
    Duration? logThreshold,
  }) => OrderManagementTracer.traceSync<T>(
    "controller.$name",
    action,
    startArguments: startArguments,
    finishArguments: finishArguments,
    logThreshold: logThreshold,
  );

  void _logPerf(String message) {
    OrderManagementTracer.logMessage("controller.$message");
  }

  void _logPerfLazy(LazyLogMessageBuilder builder) {
    OrderManagementTracer.logLazy(() => "controller.${builder()}");
  }

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
  Future<void> loadInitialData({
    bool reset = false,
  }) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "load_initial_data",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{"reset": reset},
      message: "注文管理 初期データ読み込みを開始",
    );

    await _traceAsyncSection<void>("loadInitialData", () async {
      if (reset) {
        state = OrderManagementState.initial();
      } else {
        state = state.copyWith(isLoading: true, clearErrorMessage: true);
      }

      final String? userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "ユーザー情報を取得できませんでした。再度ログインしてください。",
        );
        _logPerf("loadInitialData.userMissing");
        logSession.failed(
          reason: "missing_user",
          message: "注文管理 初期データ読み込みに失敗（ユーザー情報なし）",
          metadata: <String, dynamic>{"reset": reset},
        );
        return;
      }

      try {
        final List<MenuCategory> categoryModels = await _traceAsyncSection<List<MenuCategory>>(
          "loadInitialData.getMenuCategories",
          _menuService.getMenuCategories,
          startArguments: () => <String, dynamic>{"userId": userId},
        );
        final List<MenuItem> menuItemModels = await _traceAsyncSection<List<MenuItem>>(
          "loadInitialData.getMenuItemsByCategory",
          () => _menuService.getMenuItemsByCategory(null),
          startArguments: () => <String, dynamic>{"userId": userId},
        );

        _traceSyncSection<void>(
          "loadInitialData.updateMenuCache",
          () => _updateMenuCache(menuItemModels),
          startArguments: () => <String, dynamic>{"items": menuItemModels.length},
          logThreshold: const Duration(milliseconds: 2),
        );

        final List<MenuCategoryViewData> categoryView = _traceSyncSection<List<MenuCategoryViewData>>(
          "loadInitialData.buildCategoryView",
          () => _buildCategoryView(categoryModels),
          startArguments: () => <String, dynamic>{"categories": categoryModels.length},
          logThreshold: const Duration(milliseconds: 2),
        );

        final Order? cart = await _traceAsyncSection<Order?>(
          "loadInitialData.getActiveCart",
          () => _cartService.getActiveCart(userId),
          startArguments: () => <String, dynamic>{"userId": userId},
        );

        String? cartId = cart?.id;
        _CartSnapshot snapshot = const _CartSnapshot(items: <CartItemViewData>[]);
        if (cartId != null) {
          snapshot = await _traceAsyncSection<_CartSnapshot>(
            "loadInitialData.loadCartSnapshot",
            () => _loadCartSnapshot(cartId!, userId),
            startArguments: () => <String, dynamic>{"cartId": cartId},
          );
          cartId = snapshot.cartId ?? cartId;
        }
        logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

        int menuCount = 0;
        final List<MenuItemViewData> synchronisedMenu = _traceSyncSection<List<MenuItemViewData>>(
          "loadInitialData.synchroniseMenu",
          () {
            final List<MenuItemViewData> list = _menuItemCache.values.toList()
              ..sort(
                (MenuItemViewData a, MenuItemViewData b) => a.displayOrder.compareTo(b.displayOrder),
              );
            menuCount = list.length;
            return list;
          },
          startArguments: () => <String, dynamic>{"cacheSize": _menuItemCache.length},
          finishArguments: () => <String, dynamic>{"menuCount": menuCount},
          logThreshold: const Duration(milliseconds: 2),
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

        logSession.succeeded(
          message: "注文管理 初期データ読み込みが完了",
          metadata: <String, dynamic>{
            "category_count": categoryView.length,
            "menu_item_count": synchronisedMenu.length,
            "cart_item_count": snapshot.items.length,
            "has_active_cart": cartId != null,
          },
        );

        _logPerfLazy(
          () =>
              "loadInitialData.completed categories=${categoryView.length} menu=${synchronisedMenu.length} cartItems=${snapshot.items.length}",
        );
      } catch (error, stackTrace) {
        final String message = ErrorHandler.instance.handleError(error);
        state = state.copyWith(isLoading: false, errorMessage: message);
        logSession.failed(
          message: "注文管理 初期データ読み込みでエラー発生",
          reason: "load_initial_data_failed",
          metadata: <String, dynamic>{"reset": reset},
          error: error,
          stackTrace: stackTrace,
        );
        _logPerfLazy(() => "loadInitialData.error message=$message");
      }
    }, startArguments: () => <String, dynamic>{"reset": reset});
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
    final int previousIndex = state.selectedCategoryIndex;
    _traceSyncSection<void>(
      "selectCategory",
      () {
        if (index == previousIndex) {
          _logPerfLazy(() => "selectCategory.skip index=$index");
          return;
        }
        state = state.copyWith(selectedCategoryIndex: index, clearErrorMessage: true);
      },
      startArguments: () => <String, dynamic>{"from": previousIndex, "to": index},
      finishArguments: () => <String, dynamic>{
        "changed": previousIndex != state.selectedCategoryIndex,
      },
      logThreshold: const Duration(milliseconds: 1),
    );
  }

  /// 検索キーワードを更新する。
  void updateSearchQuery(String query) {
    final String previous = state.searchQuery;
    _traceSyncSection<void>(
      "updateSearchQuery",
      () {
        if (query == previous) {
          _logPerfLazy(() => "updateSearchQuery.skip length=${query.length}");
          return;
        }
        state = state.copyWith(searchQuery: query, clearErrorMessage: true);
      },
      startArguments: () => <String, dynamic>{
        "previousLength": previous.length,
        "nextLength": query.length,
      },
      finishArguments: () => <String, dynamic>{"changed": previous != state.searchQuery},
      logThreshold: const Duration(milliseconds: 1),
    );
  }

  /// メニューをカートへ追加する。
  void addMenuItem(String menuItemId) => unawaited(_addMenuItem(menuItemId));

  Future<void> _addMenuItem(String menuItemId) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "add_menu_item",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{"menu_item_id": menuItemId},
      message: "注文管理 カート追加を開始",
    );

    await _traceAsyncSection<void>("addMenuItem", () async {
      if (state.isCheckoutInProgress) {
        _logPerfLazy(() => "addMenuItem.skip checkoutInProgress item=$menuItemId");
        logSession.cancelled(
          message: "会計処理中のためカート追加を中断",
          reason: "checkout_in_progress",
        );
        return;
      }
      final String? userId = _ensureUserId();
      if (userId == null) {
        logSession.failed(
          message: "カート追加に失敗（ユーザー未認証）",
          reason: "missing_user",
        );
        return;
      }

      final MenuItemViewData? menuItem = _menuItemCache[menuItemId] ?? _findMenuItem(menuItemId);
      if (menuItem == null) {
        state = state.copyWith(errorMessage: "選択したメニューが見つかりませんでした。");
        logSession.failed(
          message: "カート追加に失敗（メニュー未検出）",
          reason: "menu_item_not_found",
        );
        return;
      }

      final String? cartId = await _ensureCart(userId);
      if (cartId == null) {
        logSession.failed(
          message: "カート追加に失敗（カート未取得）",
          reason: "cart_unavailable",
        );
        return;
      }
      logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

      try {
        state = state.copyWith(clearErrorMessage: true);
        final CartMutationResult result = await _traceAsyncSection<CartMutationResult>(
          "addMenuItem.addItemToCart",
          () => _cartService.addItemToCart(
            cartId,
            CartItemRequest(menuItemId: menuItemId, quantity: 1),
            userId,
          ),
          startArguments: () => <String, dynamic>{"cartId": cartId, "menuItemId": menuItemId},
          logThreshold: const Duration(milliseconds: 4),
        );
        _applyCartMutationResult(result);
        final String highlightTarget = result.highlightMenuItemId ?? menuItemId;
        _triggerHighlight(highlightTarget);

        logSession.succeeded(
          message: "カートにメニューを追加しました",
          metadata: <String, dynamic>{
            "cart_item_count": state.cartItems.length,
            "mutation_kind": result.kind.name,
            "stock_warning": result.hasStockIssue,
          },
        );
      } catch (error, stackTrace) {
        final String message = ErrorHandler.instance.handleError(error);
        state = state.copyWith(errorMessage: message);
        logSession.failed(
          message: "カート追加でエラーが発生",
          reason: "add_item_failed",
          metadata: <String, dynamic>{"error_message": message},
          error: error,
          stackTrace: stackTrace,
        );
        _logPerfLazy(() => "addMenuItem.error item=$menuItemId message=$message");
      }
    }, startArguments: () => <String, dynamic>{"menuItemId": menuItemId});
  }

  /// カート内アイテムの数量を更新する。
  void updateItemQuantity(String menuItemId, int quantity) =>
      unawaited(_updateItemQuantity(menuItemId, quantity));

  Future<void> _updateItemQuantity(String menuItemId, int quantity) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "update_item_quantity",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{
        "menu_item_id": menuItemId,
        "requested_quantity": quantity,
      },
      message: "注文管理 カート数量更新を開始",
    );

    await _traceAsyncSection<void>(
      "updateItemQuantity",
      () async {
        if (state.isCheckoutInProgress) {
          _logPerfLazy(
            () => "updateItemQuantity.skip checkoutInProgress item=$menuItemId quantity=$quantity",
          );
          logSession.cancelled(
            message: "会計処理中のため数量更新を中断",
            reason: "checkout_in_progress",
          );
          return;
        }
        final String? userId = _ensureUserId();
        if (userId == null) {
          logSession.failed(
            message: "数量更新に失敗（ユーザー未認証）",
            reason: "missing_user",
          );
          return;
        }

        final String? cartId = state.cartId ?? await _ensureCart(userId);
        if (cartId == null) {
          logSession.failed(
            message: "数量更新に失敗（カート未取得）",
            reason: "cart_unavailable",
          );
          return;
        }
        logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

        final CartItemViewData? target = state.cartItemByMenuId[menuItemId];
        final String? orderItemId = target?.orderItemId;

        if (target == null || orderItemId == null) {
          if (quantity > 0) {
            logSession.cancelled(
              message: "数量更新対象が見つからないため追加処理へフォールバック",
              reason: "fallback_to_add",
            );
            await _addMenuItem(menuItemId);
          } else {
            logSession.cancelled(
              message: "削除対象が見つからないためスキップ",
              reason: "missing_target",
            );
          }
          return;
        }

        try {
          state = state.copyWith(clearErrorMessage: true);
          late final CartMutationResult result;
          if (quantity <= 0) {
            result = await _traceAsyncSection<CartMutationResult>(
              "updateItemQuantity.removeItemFromCart",
              () => _cartService.removeItemFromCart(cartId, orderItemId, userId),
              startArguments: () => <String, dynamic>{"cartId": cartId, "orderItemId": orderItemId},
              logThreshold: const Duration(milliseconds: 4),
            );
          } else {
            result = await _traceAsyncSection<CartMutationResult>(
              "updateItemQuantity.updateCartItemQuantity",
              () => _cartService.updateCartItemQuantity(cartId, orderItemId, quantity, userId),
              startArguments: () => <String, dynamic>{
                "cartId": cartId,
                "orderItemId": orderItemId,
                "quantity": quantity,
              },
              logThreshold: const Duration(milliseconds: 4),
            );
          }
          _applyCartMutationResult(result);

          if (quantity > 0) {
            final String highlightTarget = result.highlightMenuItemId ?? menuItemId;
            _triggerHighlight(highlightTarget);
          } else if (state.highlightedItemId == menuItemId) {
            state = state.copyWith(clearHighlightedItemId: true);
          }

          logSession.succeeded(
            message: quantity > 0 ? "カート数量を更新しました" : "カートからアイテムを削除しました",
            metadata: <String, dynamic>{
              "cart_item_count": state.cartItems.length,
              "mutation_kind": result.kind.name,
              "stock_warning": result.hasStockIssue,
              "requested_quantity": quantity,
            },
          );
        } catch (error, stackTrace) {
          final String message = ErrorHandler.instance.handleError(error);
          state = state.copyWith(errorMessage: message);
          logSession.failed(
            message: "数量更新でエラーが発生",
            reason: "update_quantity_failed",
            metadata: <String, dynamic>{"error_message": message},
            error: error,
            stackTrace: stackTrace,
          );
          _logPerfLazy(
            () => "updateItemQuantity.error item=$menuItemId quantity=$quantity message=$message",
          );
        }
      },
      startArguments: () => <String, dynamic>{"menuItemId": menuItemId, "quantity": quantity},
    );
  }

  /// アイテムをカートから削除する。
  void removeItem(String menuItemId) => unawaited(_removeItem(menuItemId));

  Future<void> _removeItem(String menuItemId) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "remove_item",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{"menu_item_id": menuItemId},
      message: "注文管理 カート削除を開始",
    );

    await _traceAsyncSection<void>("removeItem", () async {
      if (state.isCheckoutInProgress) {
        _logPerfLazy(() => "removeItem.skip checkoutInProgress item=$menuItemId");
        logSession.cancelled(
          message: "会計処理中のため削除を中断",
          reason: "checkout_in_progress",
        );
        return;
      }
      final String? userId = _ensureUserId();
      if (userId == null) {
        logSession.failed(
          message: "カート削除に失敗（ユーザー未認証）",
          reason: "missing_user",
        );
        return;
      }

      final String? cartId = state.cartId;
      if (cartId == null) {
        logSession.failed(
          message: "カート削除に失敗（カート未取得）",
          reason: "cart_unavailable",
        );
        return;
      }
      logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

      final CartItemViewData? target = state.cartItemByMenuId[menuItemId];
      final String? orderItemId = target?.orderItemId;

      if (target == null || orderItemId == null) {
        state = state.copyWith(
          cartItems: state.cartItems
              .where((CartItemViewData item) => item.menuItem.id != menuItemId)
              .toList(growable: false),
          clearHighlightedItemId: state.highlightedItemId == menuItemId,
        );
        logSession.succeeded(
          message: "UI 上のカートからアイテムを除外しました",
          metadata: <String, dynamic>{
            "cart_item_count": state.cartItems.length,
            "mutation_kind": "local_prune",
          },
        );
        return;
      }

      try {
        state = state.copyWith(clearErrorMessage: true);
        final CartMutationResult result = await _traceAsyncSection<CartMutationResult>(
          "removeItem.cartService",
          () => _cartService.removeItemFromCart(cartId, orderItemId, userId),
          startArguments: () => <String, dynamic>{"cartId": cartId, "orderItemId": orderItemId},
          logThreshold: const Duration(milliseconds: 4),
        );
        _applyCartMutationResult(result);
        if (state.highlightedItemId == menuItemId) {
          state = state.copyWith(clearHighlightedItemId: true);
        }

        logSession.succeeded(
          message: "カートからアイテムを削除しました",
          metadata: <String, dynamic>{
            "cart_item_count": state.cartItems.length,
            "mutation_kind": result.kind.name,
          },
        );
      } catch (error, stackTrace) {
        final String message = ErrorHandler.instance.handleError(error);
        state = state.copyWith(errorMessage: message);
        logSession.failed(
          message: "カート削除でエラーが発生",
          reason: "remove_item_failed",
          metadata: <String, dynamic>{"error_message": message},
          error: error,
          stackTrace: stackTrace,
        );
        _logPerfLazy(() => "removeItem.error item=$menuItemId message=$message");
      }
    }, startArguments: () => <String, dynamic>{"menuItemId": menuItemId});
  }

  /// 支払い方法を更新する。
  Future<void> updatePaymentMethod(PaymentMethod method) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "update_payment_method",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{
        "requested_method": method.name,
        "current_method": state.currentPaymentMethod.name,
      },
      message: "注文管理 支払い方法更新を開始",
    );

    if (state.isCheckoutInProgress || state.isLoading) {
      logSession.cancelled(
        message: "処理実行中のため支払い方法を更新できません",
        reason: "busy_state",
      );
      return;
    }
    if (method == state.currentPaymentMethod) {
      logSession.cancelled(
        message: "支払い方法が既に選択済みのため変更なし",
        reason: "no_change",
      );
      return;
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      logSession.failed(
        message: "支払い方法の更新に失敗（ユーザー未認証）",
        reason: "missing_user",
      );
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
      logSession.failed(
        message: "支払い方法の更新に失敗（カート未取得）",
        reason: "cart_unavailable",
      );
      return;
    }
    logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

    state = state.copyWith(currentPaymentMethod: method, clearErrorMessage: true);

    try {
      await _cartService.updateCartPaymentMethod(cartId, method, userId);
      logSession.succeeded(
        message: "支払い方法を更新しました",
        metadata: <String, dynamic>{"applied_method": method.name},
      );
    } catch (error, stackTrace) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(currentPaymentMethod: previous, errorMessage: message);
      logSession.failed(
        message: "支払い方法の更新でエラーが発生",
        reason: "update_payment_failed",
        metadata: <String, dynamic>{"error_message": message},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// カートを会計処理する。
  Future<CheckoutActionResult> checkout() async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "checkout",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{
        "cart_item_count": state.cartItems.length,
        "discount_amount": state.discountAmount,
        "payment_method": state.currentPaymentMethod.name,
      },
      message: "注文管理 会計処理を開始",
    );

    if (state.isCheckoutInProgress) {
      logSession.cancelled(
        message: "会計処理がすでに進行中のため新たな処理を開始しません",
        reason: "checkout_in_progress",
      );
      return CheckoutActionResult.failure(message: "会計処理中です。");
    }

    if (state.cartItems.isEmpty) {
      logSession.cancelled(
        message: "カートが空のため会計処理を実行しません",
        reason: "empty_cart",
      );
      return CheckoutActionResult.emptyCart(message: "カートに商品がありません。");
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      logSession.failed(
        message: "会計処理に失敗（ユーザー未認証）",
        reason: "missing_user",
      );
      return CheckoutActionResult.authenticationFailed(message: "ユーザー情報を取得できませんでした。再度ログインしてください。");
    }

    state = state.copyWith(isCheckoutInProgress: true, clearErrorMessage: true);

    try {
      String? cartId = state.cartId;
      cartId ??= await _ensureCart(userId);
      if (cartId == null) {
        state = state.copyWith(isCheckoutInProgress: false);
        logSession.failed(
          message: "会計処理に失敗（カート未取得）",
          reason: "cart_unavailable",
        );
        return CheckoutActionResult.missingCart(message: "カート情報の取得に失敗しました。");
      }
      logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

      final OrderCheckoutRequest request = OrderCheckoutRequest(
        paymentMethod: state.currentPaymentMethod,
        discountAmount: state.discountAmount,
        notes: state.orderNotes.isEmpty ? null : state.orderNotes,
      );

      final OrderCheckoutResult result = await _orderService.checkoutCart(cartId, request, userId);

      if (!result.isSuccess || result.isStockInsufficient) {
        const String message = "在庫が不足している商品があります。数量を調整して再度お試しください。";
        state = state.copyWith(isCheckoutInProgress: false, errorMessage: message);
        logSession.failed(
          message: "会計処理に失敗（在庫不足）",
          reason: "stock_insufficient",
          metadata: <String, dynamic>{
            "order_id": result.order.id,
            "insufficient": true,
          },
        );
        return CheckoutActionResult.stockInsufficient(result.order, message: message);
      }

      final Order? newCart = result.newCart;
      if (newCart == null) {
        const String message = "新しいカートの初期化に失敗しました。";
        state = state.copyWith(isCheckoutInProgress: false, errorMessage: message);
        logSession.failed(
          message: "会計処理に失敗（カート初期化）",
          reason: "new_cart_init_failed",
          metadata: <String, dynamic>{"order_id": result.order.id},
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

      logSession.succeeded(
        message: "会計処理が完了しました",
        metadata: <String, dynamic>{
          "order_id": result.order.id,
          "order_number": result.order.orderNumber,
          "next_cart_id": newCart.id,
        },
      );

      return CheckoutActionResult.success(result.order);
    } catch (error, stackTrace) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isCheckoutInProgress: false, errorMessage: message);
      logSession.failed(
        message: "会計処理で例外が発生",
        reason: "checkout_exception",
        metadata: <String, dynamic>{"error_message": message},
        error: error,
        stackTrace: stackTrace,
      );
      return CheckoutActionResult.failure(message: message);
    }
  }

  /// カートをクリアする。
  void clearCart() => unawaited(_clearCart());

  Future<void> _clearCart() async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "clear_cart",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{"cart_item_count": state.cartItems.length},
      message: "注文管理 カートクリアを開始",
    );

    if (state.isCheckoutInProgress) {
      logSession.cancelled(
        message: "会計処理中のためカートをクリアできません",
        reason: "checkout_in_progress",
      );
      return;
    }
    if (state.cartItems.isEmpty) {
      logSession.cancelled(
        message: "カートが空のためクリア処理を実行しません",
        reason: "empty_cart",
      );
      return;
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      logSession.failed(
        message: "カートクリアに失敗（ユーザー未認証）",
        reason: "missing_user",
      );
      return;
    }

    final String? cartId = state.cartId;
    if (cartId == null) {
      state = state.copyWith(
        cartItems: <CartItemViewData>[],
        clearHighlightedItemId: true,
        orderNotes: "",
      );
      logSession.succeeded(
        message: "カートID不明のためローカル状態のみリセットしました",
        metadata: <String, dynamic>{"cart_item_count": 0, "mutation_kind": "local_prune"},
      );
      return;
    }
    logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

    try {
      state = state.copyWith(clearErrorMessage: true, orderNotes: "");
      final CartMutationResult result = await _cartService.clearCart(cartId, userId);
      _applyCartMutationResult(result);
      state = state.copyWith(clearHighlightedItemId: true);
      logSession.succeeded(
        message: "カートをクリアしました",
        metadata: <String, dynamic>{
          "cart_item_count": state.cartItems.length,
          "mutation_kind": result.kind.name,
        },
      );
    } catch (error, stackTrace) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
      logSession.failed(
        message: "カートクリアでエラーが発生",
        reason: "clear_cart_failed",
        metadata: <String, dynamic>{"error_message": message},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// 注文メモを更新する。
  void updateOrderNotes(String notes) {
    final String previous = state.orderNotes;
    _traceSyncSection<void>(
      "updateOrderNotes",
      () {
        if (notes == previous) {
          _logPerfLazy(() => "updateOrderNotes.skip length=${notes.length}");
          return;
        }
        state = state.copyWith(orderNotes: notes, clearErrorMessage: true);
      },
      startArguments: () => <String, dynamic>{
        "previousLength": previous.length,
        "nextLength": notes.length,
      },
      finishArguments: () => <String, dynamic>{"changed": previous != state.orderNotes},
      logThreshold: const Duration(milliseconds: 1),
    );
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

  _CartSnapshot _buildCartSnapshotFromData(CartSnapshotData data) {
    int missingMenuCount = 0;

    return _traceSyncSection<_CartSnapshot>(
      "cartMutation.buildSnapshot",
      () {
        for (final MenuItem menuItem in data.menuItems) {
          final MenuItemViewData? mapped = _mapMenuItem(menuItem);
          if (mapped != null) {
            _menuItemCache[mapped.id] = mapped;
          }
        }

        final List<CartItemViewData> items = <CartItemViewData>[];
        for (final OrderItem orderItem in data.orderItems) {
          final MenuItemViewData? menuView = _menuItemCache[orderItem.menuItemId];
          if (menuView == null) {
            missingMenuCount++;
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
          orderNumber: data.order.orderNumber,
          discountAmount: data.order.discountAmount,
          paymentMethod: data.order.paymentMethod,
          cartId: data.order.id,
          orderNotes: data.order.notes,
        );
      },
      startArguments: () => <String, dynamic>{
        "orderId": data.order.id,
        "items": data.orderItems.length,
      },
      finishArguments: () => <String, dynamic>{
        "mapped": data.orderItems.length - missingMenuCount,
        "missing": missingMenuCount,
      },
      logThreshold: const Duration(milliseconds: 2),
    );
  }

  void _applyCartSnapshot(_CartSnapshot snapshot) {
    int menuCount = 0;
    final List<MenuItemViewData> menuView = _traceSyncSection<List<MenuItemViewData>>(
      "refreshCart.sortMenu",
      () {
        final List<MenuItemViewData> list = _menuItemCache.values.toList()
          ..sort(
            (MenuItemViewData a, MenuItemViewData b) => a.displayOrder.compareTo(b.displayOrder),
          );
        menuCount = list.length;
        return list;
      },
      startArguments: () => <String, dynamic>{"cacheSize": _menuItemCache.length},
      finishArguments: () => <String, dynamic>{"menuCount": menuCount},
      logThreshold: const Duration(milliseconds: 2),
    );

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

    _logPerfLazy(
      () =>
          "cartSnapshot.applied cartId=${snapshot.cartId ?? state.cartId} items=${snapshot.items.length} menu=$menuCount",
    );
  }

  void _applyCartMutationResult(CartMutationResult result) {
    final _CartSnapshot snapshot = _buildCartSnapshotFromData(result.snapshot);
    _applyCartSnapshot(snapshot);

    if (result.hasStockIssue) {
      state = state.copyWith(
        errorMessage: state.errorMessage ?? "在庫が不足している商品があります。数量を調整して再度お試しください。",
      );
    }
  }

  Future<_CartSnapshot> _loadCartSnapshot(String cartId, String userId) async =>
      _traceAsyncSection<_CartSnapshot>("loadCartSnapshot", () async {
        try {
          final Map<String, dynamic>? data = await _traceAsyncSection<Map<String, dynamic>?>(
            "loadCartSnapshot.getOrderWithItems",
            () => _orderService.getOrderWithItems(cartId, userId),
            startArguments: () => <String, dynamic>{"cartId": cartId},
          );
          if (data == null) {
            return _CartSnapshot(items: const <CartItemViewData>[], cartId: cartId);
          }

          final Order order = data["order"] as Order;
          final List<Map<String, dynamic>> rawItems = (data["items"] as List<dynamic>)
              .cast<Map<String, dynamic>>();

          int mappedCount = 0;
          final List<CartItemViewData> items = _traceSyncSection<List<CartItemViewData>>(
            "loadCartSnapshot.mapItems",
            () {
              final List<CartItemViewData> list = <CartItemViewData>[];
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
                mappedCount++;
                list.add(
                  CartItemViewData(
                    menuItem: menuView,
                    quantity: orderItem.quantity,
                    orderItemId: orderItem.id,
                    selectedOptions: orderItem.selectedOptions,
                    notes: orderItem.specialRequest,
                  ),
                );
              }
              return list;
            },
            startArguments: () => <String, dynamic>{"rawItems": rawItems.length},
            finishArguments: () => <String, dynamic>{"mapped": mappedCount},
            logThreshold: const Duration(milliseconds: 2),
          );

          _logPerfLazy(
            () => "loadCartSnapshot.completed cartId=${order.id ?? cartId} items=${items.length}",
          );

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
          _logPerfLazy(() => "loadCartSnapshot.error cartId=$cartId message=$message");
          return _CartSnapshot(items: const <CartItemViewData>[], cartId: cartId);
        }
  }, startArguments: () => <String, dynamic>{"cartId": cartId, "userId": userId});
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
        logger: ref.read(loggerProvider),
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
  const CheckoutActionResult._({required this.status, this.order, this.message});

  /// 成功結果を生成する。
  factory CheckoutActionResult.success(Order order) =>
      CheckoutActionResult._(status: CheckoutActionStatus.success, order: order);

  /// 在庫不足による失敗結果を生成する。
  factory CheckoutActionResult.stockInsufficient(Order order, {String? message}) =>
      CheckoutActionResult._(
        status: CheckoutActionStatus.stockInsufficient,
        order: order,
        message: message,
      );

  /// カートが空の場合の結果を生成する。
  factory CheckoutActionResult.emptyCart({String? message}) =>
      CheckoutActionResult._(status: CheckoutActionStatus.emptyCart, message: message);

  /// 認証失敗時の結果を生成する。
  factory CheckoutActionResult.authenticationFailed({String? message}) =>
      CheckoutActionResult._(status: CheckoutActionStatus.authenticationFailed, message: message);

  /// カート取得失敗時の結果を生成する。
  factory CheckoutActionResult.missingCart({String? message}) =>
      CheckoutActionResult._(status: CheckoutActionStatus.missingCart, message: message);

  /// その他のエラーの場合の結果を生成する。
  factory CheckoutActionResult.failure({String? message, Order? order}) =>
      CheckoutActionResult._(status: CheckoutActionStatus.failure, order: order, message: message);

  /// 結果状態。
  final CheckoutActionStatus status;

  /// 処理対象となった注文。
  final Order? order;

  /// 結果に付随するメッセージ。
  final String? message;

  /// 成功したかどうか。
  bool get isSuccess => status == CheckoutActionStatus.success;
}
