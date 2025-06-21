/// 在庫更新リクエスト
class StockUpdateRequest {
  /// コンストラクタ
  StockUpdateRequest({
    required this.materialId,
    required this.newQuantity,
    required this.reason,
    this.notes,
  });

  /// JSONからオブジェクトを生成
  factory StockUpdateRequest.fromJson(Map<String, dynamic> json) =>
      StockUpdateRequest(
        materialId: json["material_id"] as String,
        newQuantity: json["new_quantity"] as double,
        reason: json["reason"] as String,
        notes: json["notes"] as String?,
      );

  /// 材料ID
  String materialId;

  /// 新しい数量
  double newQuantity;

  /// 理由
  String reason;

  /// 備考
  String? notes;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "material_id": materialId,
    "new_quantity": newQuantity,
    "reason": reason,
    "notes": notes,
  };
}

/// 仕入れリクエスト
class PurchaseRequest {
  /// コンストラクタ
  PurchaseRequest({
    required this.items,
    required this.purchaseDate,
    this.notes,
  });

  /// JSONからオブジェクトを生成
  factory PurchaseRequest.fromJson(Map<String, dynamic> json) =>
      PurchaseRequest(
        items: (json["items"] as List<dynamic>)
            .map(
              (dynamic item) =>
                  PurchaseItemDto.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        purchaseDate: DateTime.parse(json["purchase_date"] as String),
        notes: json["notes"] as String?,
      );

  /// 仕入れアイテムリスト
  List<PurchaseItemDto> items;

  /// 仕入れ日
  DateTime purchaseDate;

  /// 備考
  String? notes;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "items": items.map((PurchaseItemDto item) => item.toJson()).toList(),
    "purchase_date": purchaseDate.toIso8601String(),
    "notes": notes,
  };
}

/// 仕入れアイテムDTO
class PurchaseItemDto {
  /// コンストラクタ
  PurchaseItemDto({required this.materialId, required this.quantity});

  /// JSONからオブジェクトを生成
  factory PurchaseItemDto.fromJson(Map<String, dynamic> json) =>
      PurchaseItemDto(
        materialId: json["material_id"] as String,
        quantity: json["quantity"] as double,
      );

  /// 材料ID
  String materialId;

  /// 数量
  double quantity;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "material_id": materialId,
    "quantity": quantity,
  };
}
