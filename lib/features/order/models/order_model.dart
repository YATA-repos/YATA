import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base.dart";
import "../../../core/constants/enums.dart";
import "../shared/order_status_mapper.dart";

part "order_model.g.dart";

/// 注文
@JsonSerializable(fieldRename: FieldRename.snake)
class Order extends BaseModel {
  Order({
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.discountAmount,
    required this.orderedAt,
    this.isCart = false,
    this.orderNumber,
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

  /// JSONからインスタンスを作成
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// 合計金額
  int totalAmount;

  /// 注文番号
  String? orderNumber;

  /// カート注文フラグ
  @JsonKey(defaultValue: false)
  bool isCart;

  /// 注文ステータス
  @JsonKey(fromJson: OrderStatusMapper.fromJson, toJson: OrderStatusMapper.toJson)
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

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

/// 注文明細
@JsonSerializable(fieldRename: FieldRename.snake)
class OrderItem extends BaseModel {
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

  /// JSONからインスタンスを作成
  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

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

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}
