import "../../logging/levels.dart";

/// 分析サービス関連の情報メッセージ定義 (logger パッケージ準拠)
enum AnalyticsInfo {
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

/// AnalyticsInfo enum extension for EnhancedLogMessage features
extension AnalyticsInfoExtension on AnalyticsInfo {
  Level get recommendedLevel => Level.info;

  Level get yataLevel => Level.info;
}

/// 分析サービス関連のデバッグメッセージ定義 (logger パッケージ準拠)
enum AnalyticsDebug {
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

/// AnalyticsDebug enum extension for EnhancedLogMessage features
extension AnalyticsDebugExtension on AnalyticsDebug {
  Level get recommendedLevel => Level.debug;

  Level get yataLevel => Level.debug;
}

/// 分析サービス関連の警告メッセージ定義 (logger パッケージ準拠)
enum AnalyticsWarning {
  /// データ不整合検出
  dataInconsistencyDetected,

  /// パフォーマンス劣化検出
  performanceDegradationDetected,

  /// キャッシュミス多発
  frequentCacheMisses;

  String get message {
    switch (this) {
      case AnalyticsWarning.dataInconsistencyDetected:
        return "Data inconsistency detected in analytics calculation: {details}";
      case AnalyticsWarning.performanceDegradationDetected:
        return "Performance degradation detected: {metric} is {value}";
      case AnalyticsWarning.frequentCacheMisses:
        return "Frequent cache misses detected: {missRate}% miss rate";
    }
  }
}

/// AnalyticsWarning enum extension for EnhancedLogMessage features
extension AnalyticsWarningExtension on AnalyticsWarning {
  Level get recommendedLevel => Level.warn;

  Level get yataLevel => Level.warn;
}

/// 分析サービス関連のエラーメッセージ定義 (logger パッケージ準拠)
enum AnalyticsError {
  /// 日次統計取得失敗
  dailyStatsRetrievalFailed,

  /// 人気商品ランキング取得失敗
  popularItemsRetrievalFailed,

  /// 売上計算失敗
  revenueCalculationFailed,

  /// メニュー可否自動更新失敗
  autoUpdateFailed,

  /// データベース接続失敗
  databaseConnectionFailed,

  /// 不正なデータ検出
  invalidDataDetected;

  String get message {
    switch (this) {
      case AnalyticsError.dailyStatsRetrievalFailed:
        return "Failed to retrieve real-time daily stats: {error}";
      case AnalyticsError.popularItemsRetrievalFailed:
        return "Failed to retrieve popular items ranking: {error}";
      case AnalyticsError.revenueCalculationFailed:
        return "Failed to calculate revenue by date range: {error}";
      case AnalyticsError.autoUpdateFailed:
        return "Failed to auto-update menu availability by stock: {error}";
      case AnalyticsError.databaseConnectionFailed:
        return "Failed to connect to analytics database: {error}";
      case AnalyticsError.invalidDataDetected:
        return "Invalid data detected in analytics: {dataType} = {value}";
    }
  }
}

/// AnalyticsError enum extension for EnhancedLogMessage features
extension AnalyticsErrorExtension on AnalyticsError {
  Level get recommendedLevel => Level.error;

  Level get yataLevel => Level.error;
}

/// 分析サービス関連のファタルメッセージ定義 (logger パッケージ準拠)
enum AnalyticsFatal {
  /// システム全体の分析機能停止
  analyticsSystemFailure,

  /// 重要データ損失
  criticalDataLoss;

  String get message {
    switch (this) {
      case AnalyticsFatal.analyticsSystemFailure:
        return "Critical failure in analytics system: {reason}";
      case AnalyticsFatal.criticalDataLoss:
        return "Critical data loss detected in analytics: {affectedData}";
    }
  }
}

/// AnalyticsFatal enum extension for EnhancedLogMessage features
extension AnalyticsFatalExtension on AnalyticsFatal {
  Level get recommendedLevel => Level.fatal;

  Level get yataLevel => Level.fatal; // 統合enumでfatalを直接サポート
}

/// 分析サービス関連のトレースメッセージ定義 (logger パッケージ準拠)
enum AnalyticsTrace {
  /// 詳細実行トレース
  executionTrace,

  /// SQL クエリトレース
  sqlQueryTrace,

  /// キャッシュアクセストレース
  cacheAccessTrace;

  String get message {
    switch (this) {
      case AnalyticsTrace.executionTrace:
        return "Execution trace: {method} at {timestamp} took {duration}ms";
      case AnalyticsTrace.sqlQueryTrace:
        return "SQL query trace: {query} returned {rowCount} rows in {duration}ms";
      case AnalyticsTrace.cacheAccessTrace:
        return "Cache access trace: {key} {hitOrMiss} in {duration}ms";
    }
  }
}

/// AnalyticsTrace enum extension for EnhancedLogMessage features
extension AnalyticsTraceExtension on AnalyticsTrace {
  Level get recommendedLevel => Level.trace;

  Level get yataLevel => Level.trace; // 統合enumでtraceを直接サポート
}
