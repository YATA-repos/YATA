import "../../log_enums/log_enums.dart";
import "../base/base_context_exception.dart";
import "../base/exception_types.dart";

/// 分析関連の例外クラス
///
/// 分析サービス中に発生するエラーを管理します。
/// AnalyticsErrorと連携して、型安全なエラーハンドリングを提供します。
class AnalyticsException extends BaseContextException<AnalyticsError> {
  /// AnalyticsErrorを使用したコンストラクタ
  AnalyticsException(super.error, {super.params, super.code});

  /// メニュー可否自動更新失敗例外の作成
  factory AnalyticsException.autoUpdateFailed(String error, {int? itemCount}) => AnalyticsException(
    AnalyticsError.autoUpdateFailed,
    params: <String, String>{
      "error": error,
      if (itemCount != null) "itemCount": itemCount.toString(),
    },
  );

  /// 日次統計取得失敗例外の作成
  factory AnalyticsException.dailyStatsRetrievalFailed(String error) => AnalyticsException(
    AnalyticsError.dailyStatsRetrievalFailed,
    params: <String, String>{"error": error},
  );

  /// 人気商品ランキング取得失敗例外の作成
  factory AnalyticsException.popularItemsRetrievalFailed(int days, int limit, String error) =>
      AnalyticsException(
        AnalyticsError.popularItemsRetrievalFailed,
        params: <String, String>{
          "days": days.toString(),
          "limit": limit.toString(),
          "error": error,
        },
      );

  /// 売上計算失敗例外の作成
  factory AnalyticsException.revenueCalculationFailed(
    String startDate,
    String endDate,
    String error,
  ) => AnalyticsException(
    AnalyticsError.revenueCalculationFailed,
    params: <String, String>{"startDate": startDate, "endDate": endDate, "error": error},
  );

  /// 日次統計取得失敗（日付指定）例外の作成
  factory AnalyticsException.dailyStatsRetrievalFailedWithDate(String date, String error) =>
      AnalyticsException(
        AnalyticsError.dailyStatsRetrievalFailed,
        params: <String, String>{"date": date, "error": error},
      );

  /// 人気商品ランキング取得失敗（期間なし）例外の作成
  factory AnalyticsException.popularItemsRetrievalFailedSimple(String error) => AnalyticsException(
    AnalyticsError.popularItemsRetrievalFailed,
    params: <String, String>{"error": error},
  );

  /// 売上計算失敗（期間なし）例外の作成
  factory AnalyticsException.revenueCalculationFailedSimple(String error) => AnalyticsException(
    AnalyticsError.revenueCalculationFailed,
    params: <String, String>{"error": error},
  );

  /// 自動更新失敗（メニューアイテム指定）例外の作成
  factory AnalyticsException.autoUpdateFailedForMenuItem(
    String menuId,
    String itemName,
    String error,
  ) => AnalyticsException(
    AnalyticsError.autoUpdateFailed,
    params: <String, String>{"menuId": menuId, "itemName": itemName, "error": error},
  );

  /// 例外タイプ
  ExceptionType get type => ExceptionType.analytics;

  /// エラーの重要度を取得
  ExceptionSeverity get severity {
    switch (error) {
      case AnalyticsError.dailyStatsRetrievalFailed:
      case AnalyticsError.revenueCalculationFailed:
        return ExceptionSeverity.high;
      case AnalyticsError.popularItemsRetrievalFailed:
      case AnalyticsError.autoUpdateFailed:
        return ExceptionSeverity.medium;
    }
  }
}
