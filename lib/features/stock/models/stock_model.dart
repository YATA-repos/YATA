import "../../../core/base/base.dart";
import "../../../core/constants/enums.dart";

/// 在庫取引記録
class StockTransaction extends BaseModel {
  /// コンストラクタ
  StockTransaction({
    required this.materialId,
    required this.transactionType,
    required this.changeAmount,
    this.referenceType,
    this.referenceId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// 材料ID
  String materialId;

  /// 取引タイプ
  TransactionType transactionType;

  /// 変動量（正=入庫、負=出庫）
  double changeAmount;

  /// 参照タイプ
  ReferenceType? referenceType;

  /// 参照ID
  String? referenceId;

  /// 備考
  String? notes;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "stock_transactions";
}

/// 仕入れ記録
class Purchase extends BaseModel {
  /// コンストラクタ
  Purchase({
    required this.purchaseDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// 仕入れ日
  DateTime purchaseDate;

  /// 備考
  String? notes;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "purchases";
}

/// 仕入れ明細
class PurchaseItem extends BaseModel {
  /// コンストラクタ
  PurchaseItem({
    required this.purchaseId,
    required this.materialId,
    required this.quantity,
    this.createdAt,
    super.id,
    super.userId,
  });

  /// 仕入れID
  String purchaseId;

  /// 材料ID
  String materialId;

  /// 仕入れ量（パッケージ単位）
  double quantity;

  /// 作成日時
  DateTime? createdAt;

  @override
  String get tableName => "purchase_items";
}

/// 在庫調整
class StockAdjustment extends BaseModel {
  /// コンストラクタ
  StockAdjustment({
    required this.materialId,
    required this.adjustmentAmount,
    required this.adjustedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// 材料ID
  String materialId;

  /// 調整量（正負両方）
  double adjustmentAmount;

  /// メモ
  String? notes;

  /// 調整日時
  DateTime adjustedAt;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "stock_adjustments";
}