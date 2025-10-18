import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/enums.dart";
import "../../../../core/utils/error_handler.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../../menu/models/menu_model.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "../../services/order/order_management_service.dart";
import "../../shared/order_status_mapper.dart";
import "../../../shared/utils/payment_method_label.dart";
import "../view_data/order_history_view_data.dart";

/// 注文履歴画面の状態。
@immutable
class OrderHistoryState {
  /// [OrderHistoryState]を生成する。
  OrderHistoryState({
    required List<OrderHistoryViewData> orders,
    this.selectedStatusFilter = 0,
    this.searchQuery = "",
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.isLoading = false,
    this.selectedDateRange,
    this.selectedOrder,
    this.errorMessage,
  }) : orders = List<OrderHistoryViewData>.unmodifiable(orders);

  /// デフォルトの初期状態を取得する。
  factory OrderHistoryState.initial() =>
      OrderHistoryState(orders: const <OrderHistoryViewData>[], isLoading: true);

  /// 注文履歴一覧。
  final List<OrderHistoryViewData> orders;

  /// 選択中のステータスフィルター（0=全て、1=準備中、2=完了、3=キャンセル）。
  final int selectedStatusFilter;

  /// 検索クエリ。
  final String searchQuery;

  /// 現在のページ番号。
  final int currentPage;

  /// 総ページ数。
  final int totalPages;

  /// 総注文数。
  final int totalCount;

  /// ローディング状態。
  final bool isLoading;

  /// 選択中の日付範囲。
  final DateTimeRange? selectedDateRange;

  /// 選択中の注文（詳細表示用）。
  final OrderHistoryViewData? selectedOrder;

  /// エラーメッセージ。
  final String? errorMessage;

  /// コピーを生成する。
  OrderHistoryState copyWith({
    List<OrderHistoryViewData>? orders,
    int? selectedStatusFilter,
    String? searchQuery,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool? isLoading,
    DateTimeRange? selectedDateRange,
    OrderHistoryViewData? selectedOrder,
    bool clearSelectedOrder = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => OrderHistoryState(
    orders: orders ?? this.orders,
    selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
    searchQuery: searchQuery ?? this.searchQuery,
    currentPage: currentPage ?? this.currentPage,
    totalPages: totalPages ?? this.totalPages,
    totalCount: totalCount ?? this.totalCount,
    isLoading: isLoading ?? this.isLoading,
    selectedDateRange: selectedDateRange ?? this.selectedDateRange,
    selectedOrder: clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
  );

  /// フィルターされた注文一覧を取得する。
  List<OrderHistoryViewData> get filteredOrders {
    List<OrderHistoryViewData> filtered = orders;

    // ステータスフィルター
    if (selectedStatusFilter > 0) {
      final OrderStatus targetStatus = switch (selectedStatusFilter) {
        1 => OrderStatus.inProgress,
        2 => OrderStatus.completed,
        3 => OrderStatus.cancelled,
        _ => OrderStatus.inProgress,
      };
      filtered = orders
          .where(
            (OrderHistoryViewData order) =>
                OrderStatusMapper.normalize(order.status) == targetStatus,
          )
          .toList();
    }

    // 検索クエリフィルター
    if (searchQuery.isNotEmpty) {
      final String query = searchQuery.toLowerCase();
      filtered = filtered.where((OrderHistoryViewData order) {
        final bool matchesOrderNumber = order.orderNumber?.toLowerCase().contains(query) ?? false;
        final bool matchesCustomerName = order.customerName?.toLowerCase().contains(query) ?? false;
        final bool matchesItemName = order.items.any(
          (OrderItemViewData item) => item.menuItemName.toLowerCase().contains(query),
        );
        final bool matchesPaymentMethod =
            paymentMethodLabel(order.paymentMethod).toLowerCase().contains(query);

        return matchesOrderNumber ||
            matchesCustomerName ||
            matchesItemName ||
            matchesPaymentMethod;
      }).toList();
    }

    // 日付範囲フィルター
    if (selectedDateRange != null) {
      filtered = filtered
          .where(
            (OrderHistoryViewData order) =>
                order.orderedAt.isAfter(selectedDateRange!.start) &&
                order.orderedAt.isBefore(selectedDateRange!.end.add(const Duration(days: 1))),
          )
          .toList();
    }

    return filtered;
  }
}

/// 注文履歴画面のコントローラー。
class OrderHistoryController extends StateNotifier<OrderHistoryState> {
  /// [OrderHistoryController]を生成する。
  OrderHistoryController({required Ref ref, required OrderManagementService orderManagementService})
    : _ref = ref,
      _orderManagementService = orderManagementService,
      super(OrderHistoryState.initial()) {
    unawaited(loadHistory());
  }

  static const int _pageLimit = 20;

  final Ref _ref;
  final OrderManagementService _orderManagementService;

  /// ステータスフィルターを変更する。
  void setStatusFilter(int filterIndex) {
    if (filterIndex == state.selectedStatusFilter) {
      return;
    }
    state = state.copyWith(selectedStatusFilter: filterIndex, currentPage: 1);
    unawaited(loadHistory());
  }

  /// 検索クエリを変更する。
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 日付範囲フィルターを変更する。
  void setDateRange(DateTimeRange? dateRange) {
    state = state.copyWith(selectedDateRange: dateRange, currentPage: 1);
  }

  /// ページを変更する。
  void setPage(int page) {
    if (page == state.currentPage) {
      return;
    }
    state = state.copyWith(currentPage: page);
    unawaited(loadHistory());
  }

  /// 注文詳細を選択する。
  void selectOrder(OrderHistoryViewData order) {
    state = state.copyWith(selectedOrder: order);
  }

  /// 注文詳細選択を解除する。
  void clearSelectedOrder() {
    state = state.copyWith(clearSelectedOrder: true);
  }

  /// 注文履歴を再読み込みする。
  void refreshHistory() => unawaited(loadHistory());

  /// 注文履歴を取得する。
  Future<void> loadHistory() async {
    final String? userId = _ensureUserId();
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final OrderSearchRequest request = _buildRequest();
    final Map<String, dynamic> result =
      await _orderManagementService.getOrderHistory(request, userId);
      final List<Order> rawOrders = (result["orders"] as List<dynamic>).cast<Order>();

      final List<OrderHistoryViewData> viewOrders = <OrderHistoryViewData>[];
      for (final Order order in rawOrders) {
        if (order.id == null) {
          continue;
        }
        if (order.isCart) {
          continue;
        }
  final List<OrderItemViewData> items = await _loadOrderItems(order.id!, userId);
        viewOrders.add(
          OrderHistoryViewData(
            id: order.id!,
            orderNumber: order.orderNumber,
            status: OrderStatusMapper.normalize(order.status),
            customerName: order.customerName,
            totalAmount: order.totalAmount,
            discountAmount: order.discountAmount,
            paymentMethod: order.paymentMethod,
            orderedAt: order.orderedAt,
            items: items,
            notes: order.notes,
            completedAt: order.completedAt,
          ),
        );
      }

      final int totalCount = result["total_count"] as int? ?? viewOrders.length;
      final int totalPages =
          result["total_pages"] as int? ?? ((totalCount + _pageLimit - 1) ~/ _pageLimit);
      final int page = result["page"] as int? ?? request.page;

      state = state.copyWith(
        orders: viewOrders,
        totalCount: totalCount,
        totalPages: math.max(1, totalPages),
        currentPage: math.max(1, page),
        isLoading: false,
        clearErrorMessage: true,
        clearSelectedOrder: true,
      );
    } catch (error) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  Future<List<OrderItemViewData>> _loadOrderItems(String orderId, String userId) async {
  final Map<String, dynamic>? data =
    await _orderManagementService.getOrderWithItems(orderId, userId);
    if (data == null) {
      return const <OrderItemViewData>[];
    }

    final List<Map<String, dynamic>> rawItems = (data["items"] as List<dynamic>)
        .cast<Map<String, dynamic>>();
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

  OrderSearchRequest _buildRequest() {
    final List<OrderStatus>? statusFilter = _statusFilterFromSelection();
    return OrderSearchRequest(
      page: state.currentPage,
      limit: _pageLimit,
      dateFrom: state.selectedDateRange?.start,
      dateTo: state.selectedDateRange?.end,
      searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
      statusFilter: statusFilter,
    );
  }

  List<OrderStatus>? _statusFilterFromSelection() {
    switch (state.selectedStatusFilter) {
      case 1:
        return <OrderStatus>[OrderStatus.inProgress];
      case 2:
        return <OrderStatus>[OrderStatus.completed];
      case 3:
        return <OrderStatus>[OrderStatus.cancelled];
      default:
        return null;
    }
  }

  String? _ensureUserId() {
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = state.copyWith(errorMessage: "ユーザー情報を取得できませんでした。再度ログインしてください。");
    }
    return userId;
  }
}

/// 注文履歴コントローラーのプロバイダー。
final StateNotifierProvider<OrderHistoryController, OrderHistoryState>
orderHistoryControllerProvider = StateNotifierProvider<OrderHistoryController, OrderHistoryState>(
  (Ref ref) => OrderHistoryController(
    ref: ref,
    orderManagementService: ref.read(orderManagementServiceProvider),
  ),
);
