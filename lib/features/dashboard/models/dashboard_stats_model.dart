import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base_model.dart";

part "dashboard_stats_model.g.dart";

/// ダッシュボード統計モデル
///
/// ダッシュボード画面に表示される統計情報を管理します。
@JsonSerializable()
class DashboardStatsModel extends BaseModel {
  DashboardStatsModel({
    required this.todayOrders,
    required this.todayRevenue,
    required this.activeOrders,
    required this.lowStockItems,
    super.id,
    super.userId,
    this.date,
    this.previousDayOrders,
    this.previousDayRevenue,
    this.averageOrderValue,
    this.createdAt,
    this.updatedAt,
  });

  /// JSONからDashboardStatsModelを作成
  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsModelFromJson(json);

  @override
  String get tableName => "dashboard_stats";

  /// 本日の注文数
  final int todayOrders;

  /// 本日の売上
  final double todayRevenue;

  /// アクティブな注文数
  final int activeOrders;

  /// 在庫不足アイテム数
  final int lowStockItems;

  /// 統計日付
  final DateTime? date;

  /// 前日の注文数（比較用）
  final int? previousDayOrders;

  /// 前日の売上（比較用）
  final double? previousDayRevenue;

  /// 平均注文金額
  final double? averageOrderValue;

  /// 作成日時
  final DateTime? createdAt;

  /// 更新日時
  final DateTime? updatedAt;

  @override
  Map<String, dynamic> toJson() => _$DashboardStatsModelToJson(this);

  /// 注文数の変化率（前日比）
  double? get ordersChangeRate {
    if (previousDayOrders == null || previousDayOrders == 0) {
      return null;
    }
    return ((todayOrders - previousDayOrders!) / previousDayOrders!) * 100;
  }

  /// 売上の変化率（前日比）
  double? get revenueChangeRate {
    if (previousDayRevenue == null || previousDayRevenue == 0) {
      return null;
    }
    return ((todayRevenue - previousDayRevenue!) / previousDayRevenue!) * 100;
  }

  /// 現在の平均注文金額
  double get currentAverageOrderValue {
    if (todayOrders == 0) {
      return 0.0;
    }
    return todayRevenue / todayOrders;
  }

  /// コピーメソッド
  DashboardStatsModel copyWith({
    String? id,
    String? userId,
    int? todayOrders,
    double? todayRevenue,
    int? activeOrders,
    int? lowStockItems,
    DateTime? date,
    int? previousDayOrders,
    double? previousDayRevenue,
    double? averageOrderValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DashboardStatsModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    todayOrders: todayOrders ?? this.todayOrders,
    todayRevenue: todayRevenue ?? this.todayRevenue,
    activeOrders: activeOrders ?? this.activeOrders,
    lowStockItems: lowStockItems ?? this.lowStockItems,
    date: date ?? this.date,
    previousDayOrders: previousDayOrders ?? this.previousDayOrders,
    previousDayRevenue: previousDayRevenue ?? this.previousDayRevenue,
    averageOrderValue: averageOrderValue ?? this.averageOrderValue,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() =>
      "DashboardStatsModel(id: $id, todayOrders: $todayOrders, todayRevenue: $todayRevenue, activeOrders: $activeOrders)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStatsModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          todayOrders == other.todayOrders &&
          todayRevenue == other.todayRevenue &&
          activeOrders == other.activeOrders &&
          lowStockItems == other.lowStockItems;

  @override
  int get hashCode => Object.hash(id, todayOrders, todayRevenue, activeOrders, lowStockItems);
}
