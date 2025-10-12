import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/utils/error_handler.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../../menu/models/menu_model.dart";
import "../../models/order_model.dart";
import "../../services/order/order_management_service.dart";
import "../../shared/order_status_presentation.dart";
import "../view_data/order_history_view_data.dart";

/// 注文状況ページで表示する注文のビューモデル。
class OrderStatusOrderViewData {
  /// [OrderStatusOrderViewData]を生成する。
  const OrderStatusOrderViewData({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.orderedAt,
    this.orderNumber,
    this.customerName,
    this.completedAt,
    this.notes,
  });

  /// 注文ID。
  final String id;

  /// 注文番号。
  final String? orderNumber;

  /// 現在の注文ステータス。
  final OrderStatus status;

  /// 顧客名。
  final String? customerName;

  /// 合計金額。
  final int totalAmount;

  /// 注文日時。
  final DateTime orderedAt;

  /// 完了日時。
  final DateTime? completedAt;

  /// 備考。
  final String? notes;
}

/// 注文状況ページの状態。
class OrderStatusState {
  /// [OrderStatusState]を生成する。
  OrderStatusState({
    required List<OrderStatusOrderViewData> inProgressOrders,
    required List<OrderStatusOrderViewData> completedOrders,
    required List<OrderStatusOrderViewData> cancelledOrders,
    this.isLoading = false,
    this.errorMessage,
    this.selectedOrder,
    this.isDetailLoading = false,
    Set<String>? updatingOrderIds,
  }) : inProgressOrders = List<OrderStatusOrderViewData>.unmodifiable(inProgressOrders),
       completedOrders = List<OrderStatusOrderViewData>.unmodifiable(completedOrders),
       cancelledOrders = List<OrderStatusOrderViewData>.unmodifiable(cancelledOrders),
       updatingOrderIds = Set<String>.unmodifiable(updatingOrderIds ?? <String>{});

  /// 初期状態を生成する。
  factory OrderStatusState.initial() => OrderStatusState(
    inProgressOrders: const <OrderStatusOrderViewData>[],
    completedOrders: const <OrderStatusOrderViewData>[],
    cancelledOrders: const <OrderStatusOrderViewData>[],
    isLoading: true,
  );

  /// 準備中の注文一覧。
  final List<OrderStatusOrderViewData> inProgressOrders;

  /// 提供済みの注文一覧。
  final List<OrderStatusOrderViewData> completedOrders;

  /// キャンセル済みの注文一覧。
  final List<OrderStatusOrderViewData> cancelledOrders;

  /// 読み込み中かどうか。
  final bool isLoading;

  /// エラーメッセージ。
  final String? errorMessage;

  /// モーダル表示中の注文詳細。
  final OrderHistoryViewData? selectedOrder;

  /// 詳細取得のローディング状態。
  final bool isDetailLoading;

  /// 更新中の注文ID集合。
  final Set<String> updatingOrderIds;

  /// 状態を複製する。
  OrderStatusState copyWith({
    List<OrderStatusOrderViewData>? inProgressOrders,
    List<OrderStatusOrderViewData>? completedOrders,
    List<OrderStatusOrderViewData>? cancelledOrders,
    bool? isLoading,
    String? errorMessage,
    Set<String>? updatingOrderIds,
    bool clearErrorMessage = false,
    OrderHistoryViewData? selectedOrder,
    bool clearSelectedOrder = false,
    bool? isDetailLoading,
  }) => OrderStatusState(
    inProgressOrders: inProgressOrders ?? this.inProgressOrders,
    completedOrders: completedOrders ?? this.completedOrders,
    cancelledOrders: cancelledOrders ?? this.cancelledOrders,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    selectedOrder: clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
    isDetailLoading: isDetailLoading ?? this.isDetailLoading,
    updatingOrderIds: updatingOrderIds ?? this.updatingOrderIds,
  );
}

/// 注文状況ページのロジックを担うコントローラ。
class OrderStatusController extends StateNotifier<OrderStatusState> {
  /// [OrderStatusController]を生成する。
  OrderStatusController({required Ref ref, required OrderManagementService orderManagementService})
    : _ref = ref,
      _orderManagementService = orderManagementService,
      super(OrderStatusState.initial()) {
    unawaited(loadOrders());
  }

  final Ref _ref;
  final OrderManagementService _orderManagementService;

  /// 注文一覧を読み込む。
  Future<void> loadOrders({bool showLoadingIndicator = true}) async {
    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    if (showLoadingIndicator) {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
    }

    try {
      final Map<OrderStatus, List<Order>> grouped = await _orderManagementService
          .getOrdersByStatuses(OrderStatusPresentation.displayOrder, userId);

      state = state.copyWith(
        inProgressOrders: _mapOrders(grouped[OrderStatus.inProgress] ?? const <Order>[]),
        completedOrders: _mapOrders(grouped[OrderStatus.completed] ?? const <Order>[]),
        cancelledOrders: _mapOrders(grouped[OrderStatus.cancelled] ?? const <Order>[]),
        isLoading: showLoadingIndicator ? false : state.isLoading,
        clearErrorMessage: true,
        clearSelectedOrder: true,
        isDetailLoading: false,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message, isDetailLoading: false);
    }
  }

  /// 注文を完了状態に更新する。
  Future<String?> markOrderCompleted(String orderId) async {
    final String? userId = _ensureUserId();
    if (userId == null) {
      const String message = "ユーザー情報を取得できませんでした。再度ログインしてください。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    final Set<String> nextUpdating = <String>{...state.updatingOrderIds, orderId};
    state = state.copyWith(updatingOrderIds: nextUpdating, clearErrorMessage: true);

    try {
      await _orderManagementService.updateOrderStatus(orderId, OrderStatus.completed, userId);
      final Set<String> updatedSet = <String>{...state.updatingOrderIds}..remove(orderId);
      await loadOrders(showLoadingIndicator: false);
      state = state.copyWith(updatingOrderIds: updatedSet);
      return null;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      final Set<String> updatedSet = <String>{...state.updatingOrderIds}..remove(orderId);
      state = state.copyWith(errorMessage: message, updatingOrderIds: updatedSet);
      return message;
    }
  }

  /// 注文をキャンセルする。
  Future<String?> cancelOrder(String orderId, {String reason = "店舗側キャンセル"}) async {
    final String? userId = _ensureUserId();
    if (userId == null) {
      const String message = "ユーザー情報を取得できませんでした。再度ログインしてください。";
      state = state.copyWith(errorMessage: message);
      return message;
    }

    final Set<String> nextUpdating = <String>{...state.updatingOrderIds, orderId};
    state = state.copyWith(updatingOrderIds: nextUpdating, clearErrorMessage: true);

    try {
      final (_, bool didUpdate) = await _orderManagementService.cancelOrder(
        orderId,
        reason,
        userId,
      );
      final Set<String> updatedSet = <String>{...state.updatingOrderIds}..remove(orderId);
      await loadOrders(showLoadingIndicator: false);
      state = state.copyWith(updatingOrderIds: updatedSet);

      if (!didUpdate) {
        return "すでにキャンセル済みの注文です";
      }

      return null;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      final Set<String> updatedSet = <String>{...state.updatingOrderIds}..remove(orderId);
      state = state.copyWith(errorMessage: message, updatingOrderIds: updatedSet);
      return message;
    }
  }

  /// 注文詳細を読み込んでモーダル表示用に保持する。
  Future<String?> loadOrderDetail(String orderId) async {
    final String? userId = _ensureUserId();
    if (userId == null) {
      return "ユーザー情報を取得できませんでした。再度ログインしてください。";
    }

    if (state.isDetailLoading && state.selectedOrder?.id == orderId) {
      return null;
    }

    state = state.copyWith(isDetailLoading: true, clearErrorMessage: true);

    try {
      final OrderHistoryViewData? detail = await _fetchOrderDetail(orderId, userId);
      if (detail == null) {
        state = state.copyWith(isDetailLoading: false);
        return "注文詳細を取得できませんでした";
      }

      state = state.copyWith(
        selectedOrder: detail,
        isDetailLoading: false,
        clearErrorMessage: true,
      );
      return null;
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isDetailLoading: false);
      return message;
    }
  }

  /// 注文詳細モーダルを閉じる。
  void clearSelectedOrder() {
    state = state.copyWith(clearSelectedOrder: true, isDetailLoading: false);
  }

  Future<OrderHistoryViewData?> _fetchOrderDetail(String orderId, String userId) async {
    final Map<String, dynamic>? data = await _orderManagementService.getOrderWithItems(
      orderId,
      userId,
    );
    if (data == null) {
      return null;
    }

    final Order? order = data["order"] as Order?;
    if (order == null || order.id == null) {
      return null;
    }

    final List<Map<String, dynamic>> rawItems = (data["items"] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final List<OrderItemViewData> items = _mapOrderItems(rawItems);

    return OrderHistoryViewData(
      id: order.id!,
      orderNumber: order.orderNumber,
      status: order.status,
      customerName: order.customerName,
      totalAmount: order.totalAmount,
      discountAmount: order.discountAmount,
      paymentMethod: order.paymentMethod,
      orderedAt: order.orderedAt,
      items: items,
      notes: order.notes,
      completedAt: order.completedAt,
    );
  }

  List<OrderItemViewData> _mapOrderItems(List<Map<String, dynamic>> rawItems) {
    final List<OrderItemViewData> items = <OrderItemViewData>[];
    for (final Map<String, dynamic> entry in rawItems) {
      final OrderItem orderItem = entry["order_item"] as OrderItem;
      final MenuItem? menuItem = entry["menu_item"] as MenuItem?;
      final String menuName = menuItem?.name ?? orderItem.menuItemId;
      items.add(
        OrderItemViewData(
          menuItemId: orderItem.menuItemId,
          menuItemName: menuName,
          quantity: orderItem.quantity,
          unitPrice: orderItem.unitPrice,
          subtotal: orderItem.subtotal,
          selectedOptions: orderItem.selectedOptions,
          specialRequest: orderItem.specialRequest,
        ),
      );
    }

    return items;
  }

  /// ユーザーIDを取得する。
  String? _ensureUserId() {
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = state.copyWith(errorMessage: "ユーザー情報を取得できませんでした。再度ログインしてください。");
    }
    return userId;
  }

  List<OrderStatusOrderViewData> _mapOrders(List<Order> orders) => orders
      .map(
        (Order order) => OrderStatusOrderViewData(
          id: order.id!,
          status: order.status,
          totalAmount: order.totalAmount,
          orderedAt: order.orderedAt,
          orderNumber: order.orderNumber,
          customerName: order.customerName,
          completedAt: order.completedAt,
          notes: order.notes,
        ),
      )
      .toList(growable: false);
}

/// 注文状況ページ用のStateNotifierプロバイダー。
final StateNotifierProvider<OrderStatusController, OrderStatusState> orderStatusControllerProvider =
    StateNotifierProvider<OrderStatusController, OrderStatusState>(
      (Ref ref) => OrderStatusController(
        ref: ref,
        orderManagementService: ref.read(orderManagementServiceProvider),
      ),
    );
