import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base_model.dart";
import "alert_model.dart";

part "quick_stat_model.g.dart";

/// クイック統計モデル
///
/// ダッシュボードのクイック統計情報を管理します。
@JsonSerializable()
class QuickStatModel extends BaseModel {
  QuickStatModel({
    required this.label,
    required this.value,
    required this.trend,
    this.unit,
    this.trendPercentage,
    this.displayOrder = 0,
    super.id,
    super.userId,
    this.createdAt,
    this.updatedAt,
  });

  /// JSONからQuickStatModelを作成
  factory QuickStatModel.fromJson(Map<String, dynamic> json) => _$QuickStatModelFromJson(json);

  @override
  String get tableName => "quick_stats";

  /// ラベル
  final String label;

  /// 値
  final String value;

  /// トレンド方向
  final TrendDirection trend;

  /// 単位
  final String? unit;

  /// トレンド比率
  final double? trendPercentage;

  /// 表示順序
  final int displayOrder;

  /// 作成日時
  final DateTime? createdAt;

  /// 更新日時
  final DateTime? updatedAt;

  @override
  Map<String, dynamic> toJson() => _$QuickStatModelToJson(this);

  /// トレンドテキストを取得
  String get trendText {
    switch (trend) {
      case TrendDirection.up:
        return "上昇";
      case TrendDirection.down:
        return "下降";
      case TrendDirection.stable:
        return "横ばい";
    }
  }

  /// トレンド表示用の値を取得
  String get displayValue {
    if (unit != null) {
      return "$value$unit";
    }
    return value;
  }

  /// コピーメソッド
  QuickStatModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? value,
    TrendDirection? trend,
    String? unit,
    double? trendPercentage,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuickStatModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    label: label ?? this.label,
    value: value ?? this.value,
    trend: trend ?? this.trend,
    unit: unit ?? this.unit,
    trendPercentage: trendPercentage ?? this.trendPercentage,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() => "QuickStatModel(id: $id, label: $label, value: $value, trend: $trend)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickStatModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          value == other.value &&
          trend == other.trend;

  @override
  int get hashCode => Object.hash(id, label, value, trend);
}
