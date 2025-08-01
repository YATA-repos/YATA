import "../../../core/constants/enums.dart";
import "../models/inventory_model.dart";

/// 材料在庫情報（在庫レベル付き）
class MaterialStockInfo {
  MaterialStockInfo({
    required this.material,
    required this.stockLevel,
    this.estimatedUsageDays,
    this.dailyUsageRate,
  });

  /// JSONからオブジェクトを生成
  factory MaterialStockInfo.fromJson(Map<String, dynamic> json) => MaterialStockInfo(
    material: json["material"] as Material,
    stockLevel: StockLevel.values.firstWhere(
      (StockLevel level) => level.value == json["stock_level"] as String,
    ),
    estimatedUsageDays: (json["estimated_usage_days"] as num?)?.toInt(),
    dailyUsageRate: (json["daily_usage_rate"] as num?)?.toDouble(),
  );

  /// 材料情報
  Material material;

  /// 在庫レベル
  StockLevel stockLevel;

  /// 推定使用日数
  int? estimatedUsageDays;

  /// 日間使用率
  double? dailyUsageRate;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "material": material,
    "stock_level": stockLevel.value,
    "estimated_usage_days": estimatedUsageDays,
    "daily_usage_rate": dailyUsageRate,
  };
}

/// 材料使用量計算結果
class MaterialUsageCalculation {
  MaterialUsageCalculation({
    required this.materialId,
    required this.requiredAmount,
    required this.availableAmount,
    required this.isSufficient,
  });

  /// JSONからオブジェクトを生成
  factory MaterialUsageCalculation.fromJson(Map<String, dynamic> json) => MaterialUsageCalculation(
    materialId: json["material_id"] as String,
    requiredAmount: (json["required_amount"] as num?)?.toDouble() ?? 0.0,
    availableAmount: (json["available_amount"] as num?)?.toDouble() ?? 0.0,
    isSufficient: json["is_sufficient"] as bool,
  );

  /// 材料ID
  String materialId;

  /// 必要量
  double requiredAmount;

  /// 利用可能量
  double availableAmount;

  /// 十分かどうか
  bool isSufficient;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "material_id": materialId,
    "required_amount": requiredAmount,
    "available_amount": availableAmount,
    "is_sufficient": isSufficient,
  };
}
