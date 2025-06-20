import "../../../core/base/base.dart";

/// 日別集計
class DailySummary extends BaseModel {
  /// コンストラクタ
  DailySummary({
    required this.summaryDate,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.totalRevenue,
    required this.mostPopularItemCount,
    this.averagePrepTimeMinutes,
    this.mostPopularItemId,
    this.createdAt,
    this.updatedAt,
    super.id,
    super.userId,
  });

  /// 集計日
  DateTime summaryDate;

  /// 総注文数
  int totalOrders;

  /// 完了注文数
  int completedOrders;

  /// 進行中注文数
  int pendingOrders;

  /// 総売上
  int totalRevenue;

  /// 平均調理時間（分）
  int? averagePrepTimeMinutes;

  /// 最も人気のある商品のID
  String? mostPopularItemId;

  /// 最も人気のある商品の注文数
  int mostPopularItemCount;

  /// 作成日時
  DateTime? createdAt;

  /// 更新日時
  DateTime? updatedAt;

  @override
  String get tableName => "daily_summaries";
}
