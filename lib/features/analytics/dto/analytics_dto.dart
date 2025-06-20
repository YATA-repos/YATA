/// 日次統計結果
class DailyStatsResult {
  /// コンストラクタ
  DailyStatsResult({
    required this.completedOrders,
    required this.pendingOrders,
    required this.totalRevenue,
    this.averagePrepTimeMinutes,
    this.mostPopularItem,
  });

  /// JSONからオブジェクトを生成
  factory DailyStatsResult.fromJson(Map<String, dynamic> json) =>
      DailyStatsResult(
        completedOrders: json["completed_orders"] as int,
        pendingOrders: json["pending_orders"] as int,
        totalRevenue: json["total_revenue"] as int,
        averagePrepTimeMinutes: json["average_prep_time_minutes"] as int?,
        mostPopularItem: json["most_popular_item"] as Map<String, dynamic>?,
      );

  /// 完了注文数
  int completedOrders;

  /// 進行中注文数
  int pendingOrders;

  /// 総売上
  int totalRevenue;

  /// 平均調理時間（分）
  int? averagePrepTimeMinutes;

  /// 最も人気のある商品情報
  Map<String, dynamic>? mostPopularItem;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
        "completed_orders": completedOrders,
        "pending_orders": pendingOrders,
        "total_revenue": totalRevenue,
        "average_prep_time_minutes": averagePrepTimeMinutes,
        "most_popular_item": mostPopularItem,
      };
}