import "../../../core/base/base.dart";
import "../../../core/constants/enums.dart";

/// 注文
class Order extends BaseModel {
  /// コンストラクタ
  Order({
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.discountAmount,
    required this.orderedAt,
    this.customerName,
    this.notes,
    this.startedPreparingAt,
    this.readyAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// 合計金額
  int totalAmount;

  /// 注文ステータス
  OrderStatus status;

  /// 支払い方法
  PaymentMethod paymentMethod;

  /// 割引額
  int discountAmount;

  /// 顧客名（呼び出し用）
  String? customerName;

  /// 備考
  String? notes;

  /// 注文日時
  DateTime orderedAt;

  /// 調理開始日時
  DateTime? startedPreparingAt;

  /// 完成日時
  DateTime? readyAt;

  /// 提供完了日時
  DateTime? completedAt;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "orders";
}

/// 注文明細
class OrderItem extends BaseModel {
  /// コンストラクタ
  OrderItem({
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.selectedOptions,
    this.specialRequest,
    this.createdAt,
    super.id,
    super.userId,
  });

  /// 注文ID
  String orderId;

  /// メニューID
  String menuItemId;

  /// 数量
  int quantity;

  /// 単価（注文時点の価格）
  int unitPrice;

  /// 小計
  int subtotal;

  /// 選択されたオプション
  Map<String, String>? selectedOptions;

  /// 特別リクエスト（例: アレルギー対応）
  String? specialRequest;

  /// 作成日時
  DateTime? createdAt;

  @override
  String get tableName => "order_items";
}