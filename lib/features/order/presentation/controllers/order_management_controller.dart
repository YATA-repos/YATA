import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../../core/utils/error_handler.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../../auth/services/auth_service.dart";
import "../../../menu/models/menu_model.dart";
import "../../../menu/services/menu_service.dart";
import "../../../shared/logging/ui_action_logger.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "../../services/cart_management_service.dart";
import "../../services/models/cart_snapshot.dart";
import "../../services/order_service.dart";
import "../performance/order_management_tracing.dart";
import "order_management_state.dart";

part "order_management_menu_filter_controller.dart";
part "order_management_cart_operation_controller.dart";
part "order_management_checkout_controller.dart";

/// 注文管理画面の振る舞いを担うコントローラの共通基盤。
abstract class _OrderManagementControllerBase extends StateNotifier<OrderManagementState> {
  _OrderManagementControllerBase({
    required Ref ref,
    required MenuService menuService,
    required CartManagementService cartManagementService,
    required OrderService orderService,
    required log_contract.LoggerContract logger,
  }) : _ref = ref,
       _menuService = menuService,
       _cartManagementService = cartManagementService,
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
  static const String _loggerTag = "OrderManagementController";

  String get loggerTag => _loggerTag;

  final Ref _ref;
  final MenuService _menuService;
  final CartManagementService _cartManagementService;
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

  Future<void> loadInitialData({bool reset = false});

  void refresh();

  void selectCategory(int index);

  void updateSearchQuery(String query);

  void addMenuItem(String menuItemId);

  void updateItemQuantity(String menuItemId, int quantity);

  void removeItem(String menuItemId);

  Future<void> updatePaymentMethod(PaymentMethod method);

  Future<CheckoutActionResult> checkout();

  void clearCart();

  void updateOrderNotes(String notes);

  void _triggerHighlight(String menuItemId) {
    final int token = ++_highlightSeq;
    state = state.copyWith(highlightedItemId: menuItemId);
    Future<void>.delayed(const Duration(milliseconds: 1200)).then((_) {
      if (_highlightSeq == token && state.highlightedItemId == menuItemId) {
        state = state.copyWith(clearHighlightedItemId: true);
      }
    });
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
      final Order? cart = await _cartManagementService.getOrCreateActiveCart(userId);
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

class OrderManagementController extends _OrderManagementControllerBase
    with MenuFilterController, CartOperationController, CheckoutController {
  OrderManagementController({
    required Ref ref,
    required MenuService menuService,
    required CartManagementService cartManagementService,
    required OrderService orderService,
    required log_contract.LoggerContract logger,
  }) : super(
          ref: ref,
          menuService: menuService,
          cartManagementService: cartManagementService,
          orderService: orderService,
          logger: logger,
        );
}

/// 注文管理画面のStateNotifierプロバイダー。
final StateNotifierProvider<OrderManagementController, OrderManagementState>
orderManagementControllerProvider =
    StateNotifierProvider<OrderManagementController, OrderManagementState>(
      (Ref ref) => OrderManagementController(
        ref: ref,
        menuService: ref.read(menuServiceProvider),
        cartManagementService: ref.read(cartManagementServiceProvider),
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
