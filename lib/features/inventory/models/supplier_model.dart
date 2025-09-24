import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base.dart";

part "supplier_model.g.dart";

/// 供給業者（サプライヤー）
@JsonSerializable()
class Supplier extends BaseModel {
  Supplier({
    required this.name,
    required this.contactInfo,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// JSONからインスタンスを作成
  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);

  /// 供給業者名
  String name;

  /// 連絡先情報（電話番号、メール、住所など）
  String contactInfo;

  /// 備考
  String? notes;

  /// アクティブ状態
  bool isActive;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "suppliers";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$SupplierToJson(this);
}

/// 材料と供給業者の関連
@JsonSerializable()
class MaterialSupplier extends BaseModel {
  MaterialSupplier({
    required this.materialId,
    required this.supplierId,
    this.isPreferred = false,
    this.notes,
    this.createdAt,
    super.id,
    super.userId,
  });

  /// JSONからインスタンスを作成
  factory MaterialSupplier.fromJson(Map<String, dynamic> json) => _$MaterialSupplierFromJson(json);

  /// 材料ID
  String materialId;

  /// 供給業者ID
  String supplierId;

  /// 優先供給業者かどうか
  bool isPreferred;

  /// 備考
  String? notes;

  /// 作成日時
  DateTime? createdAt;

  @override
  String get tableName => "material_suppliers";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$MaterialSupplierToJson(this);
}
