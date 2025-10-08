import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/utils/error_handler.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../models/order_model.dart";
import "../../services/order/order_management_service.dart";
import "../../shared/order_status_presentation.dart";

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
  }) => OrderStatusState(
    inProgressOrders: inProgressOrders ?? this.inProgressOrders,
    completedOrders: completedOrders ?? this.completedOrders,
    cancelledOrders: cancelledOrders ?? this.cancelledOrders,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
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
    final Map<OrderStatus, List<Order>> grouped =
      await _orderManagementService.getOrdersByStatuses(
        OrderStatusPresentation.displayOrder,
        userId,
      );

      state = state.copyWith(
        inProgressOrders: _mapOrders(grouped[OrderStatus.inProgress] ?? const <Order>[]),
        completedOrders: _mapOrders(grouped[OrderStatus.completed] ?? const <Order>[]),
        cancelledOrders: _mapOrders(grouped[OrderStatus.cancelled] ?? const <Order>[]),
        isLoading: showLoadingIndicator ? false : state.isLoading,
        clearErrorMessage: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message);
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
    final (_, bool didUpdate) =
      await _orderManagementService.cancelOrder(orderId, reason, userId);
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
