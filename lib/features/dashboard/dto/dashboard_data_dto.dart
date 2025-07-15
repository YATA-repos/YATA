import "package:json_annotation/json_annotation.dart";

import "../../order/models/order_model.dart";
import "../models/alert_model.dart";
import "../models/dashboard_stats_model.dart";
import "../models/quick_stat_model.dart";

part "dashboard_data_dto.g.dart";

/// ダッシュボードデータDTO
///
/// ダッシュボード画面に表示する全体的なデータを転送するためのオブジェクト。
@JsonSerializable()
class DashboardDataDto {
  const DashboardDataDto({
    required this.stats,
    required this.recentOrders,
    this.alerts,
    this.quickStats,
  });

  /// JSONからDashboardDataDtoを作成
  factory DashboardDataDto.fromJson(Map<String, dynamic> json) => _$DashboardDataDtoFromJson(json);

  /// 統計情報
  final DashboardStatsModel stats;

  /// 最近の注文
  final List<Order> recentOrders;

  /// アラート情報
  final List<AlertModel>? alerts;

  /// クイック統計
  final List<QuickStatModel>? quickStats;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$DashboardDataDtoToJson(this);

  /// アクティブなアラートのみを取得
  List<AlertModel> get activeAlerts =>
      alerts?.where((AlertModel alert) => alert.isActive).toList() ?? <AlertModel>[];

  /// 未読アラートのみを取得
  List<AlertModel> get unreadAlerts =>
      alerts?.where((AlertModel alert) => !alert.isRead && alert.isActive).toList() ??
      <AlertModel>[];

  /// 重要度別のアラート数を取得
  Map<AlertSeverity, int> get alertCountBySeverity {
    final Map<AlertSeverity, int> counts = <AlertSeverity, int>{
      AlertSeverity.info: 0,
      AlertSeverity.warning: 0,
      AlertSeverity.error: 0,
      AlertSeverity.critical: 0,
    };

    for (final AlertModel alert in activeAlerts) {
      counts[alert.severity] = (counts[alert.severity] ?? 0) + 1;
    }

    return counts;
  }

  /// 表示順でソートされたクイック統計を取得
  List<QuickStatModel> get sortedQuickStats {
    if (quickStats == null) {
      return <QuickStatModel>[];
    }
    final List<QuickStatModel> sorted = quickStats!.toList()
      ..sort((QuickStatModel a, QuickStatModel b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  }

  @override
  String toString() =>
      "DashboardDataDto(stats: $stats, recentOrders: ${recentOrders.length} orders, alerts: ${alerts?.length ?? 0})";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardDataDto &&
          runtimeType == other.runtimeType &&
          stats == other.stats &&
          recentOrders == other.recentOrders;

  @override
  int get hashCode => Object.hash(stats, recentOrders);
}
