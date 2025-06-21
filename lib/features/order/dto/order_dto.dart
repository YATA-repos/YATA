import "../../../core/constants/enums.dart";

/// カートアイテム追加/更新リクエスト
class CartItemRequest {
  /// コンストラクタ
  CartItemRequest({
    required this.menuItemId,
    required this.quantity,
    this.selectedOptions,
    this.specialRequest,
  });

  /// JSONからオブジェクトを生成
  factory CartItemRequest.fromJson(Map<String, dynamic> json) =>
      CartItemRequest(
        menuItemId: json["menu_item_id"] as String,
        quantity: json["quantity"] as int,
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
  /// コンストラクタ
  OrderCheckoutRequest({
    required this.paymentMethod,
    required this.discountAmount,
    this.customerName,
    this.notes,
  });

  /// JSONからオブジェクトを生成
  factory OrderCheckoutRequest.fromJson(Map<String, dynamic> json) =>
      OrderCheckoutRequest(
        paymentMethod: PaymentMethod.values.firstWhere(
          (PaymentMethod method) =>
              method.value == json["payment_method"] as String,
        ),
        customerName: json["customer_name"] as String?,
        discountAmount: json["discount_amount"] as int,
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
  /// コンストラクタ
  OrderSearchRequest({
    required this.page,
    required this.limit,
    this.dateFrom,
    this.dateTo,
    this.statusFilter,
    this.customerName,
    this.menuItemName,
  });

  /// JSONからオブジェクトを生成
  factory OrderSearchRequest.fromJson(Map<String, dynamic> json) =>
      OrderSearchRequest(
        dateFrom: json["date_from"] == null
            ? null
            : DateTime.parse(json["date_from"] as String),
        dateTo: json["date_to"] == null
            ? null
            : DateTime.parse(json["date_to"] as String),
        statusFilter: json["status_filter"] == null
            ? null
            : (json["status_filter"] as List<dynamic>)
                  .map(
                    (dynamic status) => OrderStatus.values.firstWhere(
                      (OrderStatus s) => s.value == status as String,
                    ),
                  )
                  .toList(),
        customerName: json["customer_name"] as String?,
        menuItemName: json["menu_item_name"] as String?,
        page: json["page"] as int,
        limit: json["limit"] as int,
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

  /// ページ番号
  int page;

  /// 1ページあたりの件数
  int limit;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "date_from": dateFrom?.toIso8601String(),
    "date_to": dateTo?.toIso8601String(),
    "status_filter": statusFilter
        ?.map((OrderStatus status) => status.value)
        .toList(),
    "customer_name": customerName,
    "menu_item_name": menuItemName,
    "page": page,
    "limit": limit,
  };
}

/// 注文金額計算結果
class OrderCalculationResult {
  /// コンストラクタ
  OrderCalculationResult({
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
  });

  /// JSONからオブジェクトを生成
  factory OrderCalculationResult.fromJson(Map<String, dynamic> json) =>
      OrderCalculationResult(
        subtotal: json["subtotal"] as int,
        taxAmount: json["tax_amount"] as int,
        discountAmount: json["discount_amount"] as int,
        totalAmount: json["total_amount"] as int,
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
