import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/enums.dart";

/// 注文履歴画面で表示する注文の表示用データ。
@immutable
class OrderHistoryViewData {
  /// [OrderHistoryViewData]を生成する。
  const OrderHistoryViewData({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.totalAmount,
    required this.discountAmount,
    required this.paymentMethod,
    required this.orderedAt,
    required this.items,
    this.notes,
    this.completedAt,
  });

  /// 注文ID。
  final String id;

  /// 注文番号。
  final String? orderNumber;

  /// 注文ステータス。
  final OrderStatus status;

  /// 顧客名。
  final String? customerName;

  /// 合計金額。
  final int totalAmount;

  /// 割引額。
  final int discountAmount;

  /// 支払い方法。
  final PaymentMethod paymentMethod;

  /// 注文日時。
  final DateTime orderedAt;

  /// 注文明細。
  final List<OrderItemViewData> items;

  /// 備考。
  final String? notes;

  /// 完了日時。
  final DateTime? completedAt;

  /// 小計金額（税抜き）。
  int get subtotal => totalAmount - discountAmount;
  
  /// 実際の支払い金額。
  int get actualAmount => totalAmount - discountAmount;
}

/// 注文明細の表示用データ。
@immutable
class OrderItemViewData {
  /// [OrderItemViewData]を生成する。
  const OrderItemViewData({
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.selectedOptions,
    this.specialRequest,
  });

  /// メニューアイテムID。
  final String menuItemId;

  /// メニューアイテム名。
  final String menuItemName;

  /// 数量。
  final int quantity;

  /// 単価。
  final int unitPrice;

  /// 小計。
  final int subtotal;

  /// 選択されたオプション。
  final Map<String, String>? selectedOptions;

  /// 特別リクエスト。
  final String? specialRequest;
}

/// 注文履歴画面の状態。
@immutable
class OrderHistoryState {
  /// [OrderHistoryState]を生成する。
  OrderHistoryState({
    required List<OrderHistoryViewData> orders,
    this.selectedStatusFilter = 0,  // 0 = 全て
    this.searchQuery = "",
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.isLoading = false,
    this.selectedDateRange,
    this.selectedOrder,
  }) : orders = List<OrderHistoryViewData>.unmodifiable(orders);

  /// デフォルトの初期状態を取得する。
  factory OrderHistoryState.initial() => OrderHistoryState(
      orders: _mockOrderHistory(),
      totalCount: _mockOrderHistory().length,
    );

  /// 注文履歴一覧。
  final List<OrderHistoryViewData> orders;

  /// 選択中のステータスフィルター（0=全て、1=完了、2=キャンセル等）。
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
  }) => OrderHistoryState(
      orders: orders ?? this.orders,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      selectedOrder: selectedOrder ?? this.selectedOrder,
    );

  /// フィルターされた注文一覧を取得する。
  List<OrderHistoryViewData> get filteredOrders {
    List<OrderHistoryViewData> filtered = orders;

    // ステータスフィルター
    if (selectedStatusFilter > 0) {
      final OrderStatus targetStatus = switch (selectedStatusFilter) {
        1 => OrderStatus.completed,
        2 => OrderStatus.cancelled,
        3 => OrderStatus.refunded,
        _ => OrderStatus.completed,
      };
      filtered = orders.where((OrderHistoryViewData order) => order.status == targetStatus).toList();
    }

    // 検索クエリフィルター
    if (searchQuery.isNotEmpty) {
      final String query = searchQuery.toLowerCase();
      filtered = filtered.where((OrderHistoryViewData order) {
        final bool matchesOrderNumber = order.orderNumber?.toLowerCase().contains(query) ?? false;
        final bool matchesCustomerName = order.customerName?.toLowerCase().contains(query) ?? false;
        final bool matchesItemName = order.items.any((OrderItemViewData item) =>
            item.menuItemName.toLowerCase().contains(query));
        return matchesOrderNumber || matchesCustomerName || matchesItemName;
      }).toList();
    }

    // 日付範囲フィルター
    if (selectedDateRange != null) {
      filtered = filtered.where((OrderHistoryViewData order) => order.orderedAt.isAfter(selectedDateRange!.start) &&
               order.orderedAt.isBefore(selectedDateRange!.end.add(const Duration(days: 1)))).toList();
    }

    return filtered;
  }
}

/// 注文履歴画面のコントローラー。
class OrderHistoryController extends StateNotifier<OrderHistoryState> {
  /// [OrderHistoryController]を生成する。
  OrderHistoryController() : super(OrderHistoryState.initial());

  /// ステータスフィルターを変更する。
  void setStatusFilter(int filterIndex) {
    state = state.copyWith(selectedStatusFilter: filterIndex);
  }

  /// 検索クエリを変更する。
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 日付範囲フィルターを変更する。
  void setDateRange(DateTimeRange? dateRange) {
    state = state.copyWith(selectedDateRange: dateRange);
  }

  /// ページを変更する。
  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  /// 注文詳細を選択する。
  void selectOrder(OrderHistoryViewData order) {
    state = state.copyWith(selectedOrder: order);
  }

  /// 注文詳細選択を解除する。
  void clearSelectedOrder() {
    state = state.copyWith();
  }

  /// 注文履歴を再読み込みする。
  void refreshHistory() {
    state = state.copyWith(isLoading: true);
    // TODO: 実際のサービスと連携して注文履歴を取得
    // 現在はモックデータで対応
    state = state.copyWith(
      orders: _mockOrderHistory(),
      isLoading: false,
    );
  }
}

/// 注文履歴コントローラーのプロバイダー。
final StateNotifierProvider<OrderHistoryController, OrderHistoryState> orderHistoryControllerProvider =
    StateNotifierProvider<OrderHistoryController, OrderHistoryState>(
  (Ref ref) => OrderHistoryController(),
);

/// モック用の注文履歴データを生成する。
List<OrderHistoryViewData> _mockOrderHistory() {
  final DateTime now = DateTime.now();
  
  return <OrderHistoryViewData>[
    OrderHistoryViewData(
      id: "order-001",
      orderNumber: "#1046",
      status: OrderStatus.completed,
      customerName: "田中 太郎",
      totalAmount: 1280,
      discountAmount: 80,
      paymentMethod: PaymentMethod.cash,
      orderedAt: now.subtract(const Duration(hours: 2)),
      completedAt: now.subtract(const Duration(hours: 1, minutes: 45)),
      items: <OrderItemViewData>[
        const OrderItemViewData(
          menuItemId: "menu-001",
          menuItemName: "唐揚げ定食",
          quantity: 1,
          unitPrice: 880,
          subtotal: 880,
        ),
        const OrderItemViewData(
          menuItemId: "menu-002",
          menuItemName: "生ビール",
          quantity: 2,
          unitPrice: 200,
          subtotal: 400,
        ),
      ],
      notes: "大盛りでお願いします",
    ),
    OrderHistoryViewData(
      id: "order-002",
      orderNumber: "#1045",
      status: OrderStatus.completed,
      customerName: "佐藤 花子",
      totalAmount: 650,
      discountAmount: 0,
      paymentMethod: PaymentMethod.card,
      orderedAt: now.subtract(const Duration(hours: 4)),
      completedAt: now.subtract(const Duration(hours: 3, minutes: 30)),
      items: <OrderItemViewData>[
        const OrderItemViewData(
          menuItemId: "menu-003",
          menuItemName: "カレーライス",
          quantity: 1,
          unitPrice: 650,
          subtotal: 650,
        ),
      ],
    ),
    OrderHistoryViewData(
      id: "order-003",
      orderNumber: "#1044",
      status: OrderStatus.cancelled,
      customerName: "鈴木 一文",
      totalAmount: 1500,
      discountAmount: 0,
      paymentMethod: PaymentMethod.cash,
      orderedAt: now.subtract(const Duration(hours: 6)),
      items: <OrderItemViewData>[
        const OrderItemViewData(
          menuItemId: "menu-004",
          menuItemName: "刺身盛り合わせ",
          quantity: 1,
          unitPrice: 1500,
          subtotal: 1500,
        ),
      ],
      notes: "キャンセル理由: 時間がかかりすぎるため",
    ),
    OrderHistoryViewData(
      id: "order-004",
      orderNumber: "#1043",
      status: OrderStatus.completed,
      customerName: null, // 顧客名なし
      totalAmount: 380,
      discountAmount: 20,
      paymentMethod: PaymentMethod.other,
      orderedAt: now.subtract(const Duration(days: 1, hours: 2)),
      completedAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 30)),
      items: <OrderItemViewData>[
        const OrderItemViewData(
          menuItemId: "menu-005",
          menuItemName: "焼きそば",
          quantity: 1,
          unitPrice: 400,
          subtotal: 400,
        ),
      ],
    ),
    OrderHistoryViewData(
      id: "order-005",
      orderNumber: "#1042",
      status: OrderStatus.refunded,
      customerName: "山田 次郎",
      totalAmount: 2800,
      discountAmount: 300,
      paymentMethod: PaymentMethod.card,
      orderedAt: now.subtract(const Duration(days: 2)),
      items: <OrderItemViewData>[
        const OrderItemViewData(
          menuItemId: "menu-006",
          menuItemName: "特上寿司",
          quantity: 2,
          unitPrice: 1400,
          subtotal: 2800,
        ),
      ],
      notes: "返金理由: 食材に問題があったため",
    ),
  ];
}