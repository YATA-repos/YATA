import "../../../core/base/base.dart";

/// 日別集計
class DailySummary extends BaseModel {
  /// コンストラクタ
  DailySummary({
    required this.summaryDate,
    required this.completedOrders,
    required this.totalRevenue,
    required this.mostPopularItemCount,
    this.averagePrepTimeMinutes,
    this.mostPopularItemId,
  });

  /// 集計日
  DateTime summaryDate;

  /// 総注文数
  int completedOrders;

  /// 総売上
  int totalRevenue;

  /// 最も人気のある商品の注文数
  int mostPopularItemCount;

  /// 平均調理時間（分）
  int? averagePrepTimeMinutes;

  /// 最も人気のある商品のID
  String? mostPopularItemId;

  @override
  String get tableName => "daily_summary";
}
