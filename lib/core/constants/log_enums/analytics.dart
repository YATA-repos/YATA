import "../../base/base_error_msg.dart";

/// 分析サービス関連の情報メッセージ定義
enum AnalyticsInfo implements LogMessage {
  /// 日次統計取得開始
  dailyStatsStarted,

  /// 日次統計計算完了
  dailyStatsCompleted,

  /// 人気商品ランキング取得開始
  popularItemsStarted,

  /// 人気商品ランキング完了
  popularItemsCompleted,

  /// 売上計算開始
  revenueCalculationStarted,

  /// 売上計算完了
  revenueCalculationCompleted,

  /// メニュー可否自動更新開始
  autoUpdateStarted,

  /// メニュー可否自動更新完了
  autoUpdateCompleted;

  /// 情報メッセージを取得
  @override
  String get message {
    switch (this) {
      case AnalyticsInfo.dailyStatsStarted:
        return "Started retrieving real-time daily stats";
      case AnalyticsInfo.dailyStatsCompleted:
        return "Daily stats calculation completed: revenue={totalRevenue}, orders={totalOrders}";
      case AnalyticsInfo.popularItemsStarted:
        return "Started retrieving popular items ranking: days={days}, limit={limit}";
      case AnalyticsInfo.popularItemsCompleted:
        return "Popular items ranking completed: {itemCount} items in ranking";
      case AnalyticsInfo.revenueCalculationStarted:
        return "Started calculating revenue by date range";
      case AnalyticsInfo.revenueCalculationCompleted:
        return "Revenue calculation completed: totalRevenue={totalRevenue}, totalOrders={totalOrders}";
      case AnalyticsInfo.autoUpdateStarted:
        return "Started auto-updating menu availability by stock";
      case AnalyticsInfo.autoUpdateCompleted:
        return "Auto-updated menu availability: {updatedCount} items updated";
    }
  }
}

/// 分析サービス関連のデバッグメッセージ定義
enum AnalyticsDebug implements LogMessage {
  /// 完了注文数取得
  completedOrdersRetrieved,

  /// 売上集計取得
  salesSummaryRetrieved,

  /// 日付範囲内の注文発見
  ordersFoundInRange,

  /// 可否チェック実行
  availabilityChecked,

  /// 更新が必要なメニュー項目発見
  menuItemsRequireUpdate,

  /// 更新不要
  noUpdatesRequired;

  /// デバッグメッセージを取得
  @override
  String get message {
    switch (this) {
      case AnalyticsDebug.completedOrdersRetrieved:
        return "Retrieved {orderCount} completed orders for stats calculation";
      case AnalyticsDebug.salesSummaryRetrieved:
        return "Retrieved sales summary for {itemCount} menu items";
      case AnalyticsDebug.ordersFoundInRange:
        return "Found {orderCount} completed orders in date range";
      case AnalyticsDebug.availabilityChecked:
        return "Checked availability for {itemCount} menu items";
      case AnalyticsDebug.menuItemsRequireUpdate:
        return "Found {updateCount} menu items requiring availability updates";
      case AnalyticsDebug.noUpdatesRequired:
        return "No menu availability updates required";
    }
  }
}

/// 分析サービス関連のエラーメッセージ定義
enum AnalyticsError implements LogMessage {
  /// 日次統計取得失敗
  dailyStatsRetrievalFailed,

  /// 人気商品ランキング取得失敗
  popularItemsRetrievalFailed,

  /// 売上計算失敗
  revenueCalculationFailed,

  /// メニュー可否自動更新失敗
  autoUpdateFailed;

  /// エラーメッセージを取得
  @override
  String get message {
    switch (this) {
      case AnalyticsError.dailyStatsRetrievalFailed:
        return "Failed to retrieve real-time daily stats";
      case AnalyticsError.popularItemsRetrievalFailed:
        return "Failed to retrieve popular items ranking";
      case AnalyticsError.revenueCalculationFailed:
        return "Failed to calculate revenue by date range";
      case AnalyticsError.autoUpdateFailed:
        return "Failed to auto-update menu availability by stock";
    }
  }
}
