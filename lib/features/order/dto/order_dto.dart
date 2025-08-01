import "../../../core/constants/enums.dart";

/// カートアイテム追加/更新リクエスト
class CartItemRequest {
  CartItemRequest({
    required this.menuItemId,
    required this.quantity,
    this.selectedOptions,
    this.specialRequest,
  });

  /// JSONからオブジェクトを生成
  factory CartItemRequest.fromJson(Map<String, dynamic> json) => CartItemRequest(
    menuItemId: json["menu_item_id"] as String,
    quantity: (json["quantity"] as num?)?.toInt() ?? 1,
    selectedOptions: json["selected_options"] as Map<String, String>?,
    specialRequest: json["special_request"] as String?,
  );

  /// メニューアイテムID
  String menuItemId;

  /// 数量
  int quantity;

  /// 選択されたオプション
  Map<String, String>? selectedOptions;

  /// 特別リクエスト
  String? specialRequest;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "menu_item_id": menuItemId,
    "quantity": quantity,
    "selected_options": selectedOptions,
    "special_request": specialRequest,
  };
}

/// 注文確定リクエスト
class OrderCheckoutRequest {
  OrderCheckoutRequest({
    required this.paymentMethod,
    required this.discountAmount,
    this.customerName,
    this.notes,
  });

  /// JSONからオブジェクトを生成
  factory OrderCheckoutRequest.fromJson(Map<String, dynamic> json) => OrderCheckoutRequest(
    paymentMethod: PaymentMethod.values.firstWhere(
      (PaymentMethod method) => method.value == json["payment_method"] as String,
    ),
    customerName: json["customer_name"] as String?,
    discountAmount: (json["discount_amount"] as num?)?.toInt() ?? 0,
    notes: json["notes"] as String?,
  );

  /// 支払い方法
  PaymentMethod paymentMethod;

  /// 顧客名
  String? customerName;

  /// 割引額
  int discountAmount;

  /// 備考
  String? notes;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "payment_method": paymentMethod.value,
    "customer_name": customerName,
    "discount_amount": discountAmount,
    "notes": notes,
  };
}

/// 注文検索リクエスト
class OrderSearchRequest {
  OrderSearchRequest({
    required this.page,
    required this.limit,
    this.dateFrom,
    this.dateTo,
    this.statusFilter,
    this.customerName,
    this.menuItemName,
    this.searchQuery,
  });

  /// JSONからオブジェクトを生成
  factory OrderSearchRequest.fromJson(Map<String, dynamic> json) => OrderSearchRequest(
    dateFrom: json["date_from"] == null ? null : DateTime.parse(json["date_from"] as String),
    dateTo: json["date_to"] == null ? null : DateTime.parse(json["date_to"] as String),
    statusFilter: json["status_filter"] == null
        ? null
        : (json["status_filter"] as List<dynamic>)
              .map(
                (dynamic status) =>
                    OrderStatus.values.firstWhere((OrderStatus s) => s.value == status as String),
              )
              .toList(),
    customerName: json["customer_name"] as String?,
    menuItemName: json["menu_item_name"] as String?,
    searchQuery: json["search_query"] as String?,
    page: (json["page"] as num?)?.toInt() ?? 1,
    limit: (json["limit"] as num?)?.toInt() ?? 20,
  );

  /// 開始日
  DateTime? dateFrom;

  /// 終了日
  DateTime? dateTo;

  /// ステータスフィルター
  List<OrderStatus>? statusFilter;

  /// 顧客名
  String? customerName;

  /// メニューアイテム名
  String? menuItemName;

  /// 検索クエリ（顧客名や注文番号など）
  String? searchQuery;

  /// ページ番号
  int page;

  /// 1ページあたりの件数
  int limit;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "date_from": dateFrom?.toIso8601String(),
    "date_to": dateTo?.toIso8601String(),
    "status_filter": statusFilter?.map((OrderStatus status) => status.value).toList(),
    "customer_name": customerName,
    "menu_item_name": menuItemName,
    "search_query": searchQuery,
    "page": page,
    "limit": limit,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! OrderSearchRequest) {
      return false;
    }

    return dateFrom == other.dateFrom &&
        dateTo == other.dateTo &&
        _listEquals(statusFilter, other.statusFilter) &&
        customerName == other.customerName &&
        menuItemName == other.menuItemName &&
        searchQuery == other.searchQuery &&
        page == other.page &&
        limit == other.limit;
  }

  @override
  int get hashCode => Object.hash(
    dateFrom,
    dateTo,
    statusFilter,
    customerName,
    menuItemName,
    searchQuery,
    page,
    limit,
  );

  /// List equality check
  bool _listEquals(List<OrderStatus>? a, List<OrderStatus>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null) {
      return false;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// 注文金額計算結果
class OrderCalculationResult {
  OrderCalculationResult({
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
  });

  /// JSONからオブジェクトを生成
  factory OrderCalculationResult.fromJson(Map<String, dynamic> json) => OrderCalculationResult(
    subtotal: (json["subtotal"] as num?)?.toInt() ?? 0,
    taxAmount: (json["tax_amount"] as num?)?.toInt() ?? 0,
    discountAmount: (json["discount_amount"] as num?)?.toInt() ?? 0,
    totalAmount: (json["total_amount"] as num?)?.toInt() ?? 0,
  );

  /// 小計
  int subtotal;

  /// 税額
  int taxAmount;

  /// 割引額
  int discountAmount;

  /// 合計金額
  int totalAmount;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "subtotal": subtotal,
    "tax_amount": taxAmount,
    "discount_amount": discountAmount,
    "total_amount": totalAmount,
  };
}
