import "../../core/constants/enums.dart";

/// 丸めルール
enum RoundingRule { round, ceil, floor }

/// 単位設定
class UnitSettings {
  const UnitSettings({
    required this.step,
    required this.decimals,
    this.min = 0.0,
    this.max,
    this.rounding = RoundingRule.round,
  });

  final double step; // 入力ステップ
  final int decimals; // 表示・丸め小数桁
  final double min; // 最小値
  final double? max; // 最大値
  final RoundingRule rounding; // 丸めルール
}

/// 既定の単位設定テーブル
class UnitConfig {
  static const Map<UnitType, UnitSettings> defaults = <UnitType, UnitSettings>{
    UnitType.piece: UnitSettings(step: 1, decimals: 0),
    UnitType.gram: UnitSettings(step: 10, decimals: 0),
    UnitType.kilogram: UnitSettings(step: 0.1, decimals: 1),
    UnitType.liter: UnitSettings(step: 0.1, decimals: 1),
  };

  static UnitSettings get(UnitType unit) => defaults[unit] ?? defaults[UnitType.piece]!;
}

/// 数値の丸め・クランプ・フォーマット
class UnitFormatter {
  static double clamp(double value, UnitType unit) {
    final UnitSettings s = UnitConfig.get(unit);
    final double min = s.min;
    final double max = s.max ?? double.infinity;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static double roundValue(double value, UnitType unit) {
    final UnitSettings s = UnitConfig.get(unit);
    final num pow10 = _pow10(s.decimals);
    double v = value * pow10;
    switch (s.rounding) {
      case RoundingRule.round:
        v = v.roundToDouble();
        break;
      case RoundingRule.ceil:
        v = v.ceilToDouble();
        break;
      case RoundingRule.floor:
        v = v.floorToDouble();
        break;
    }
    return v / pow10;
  }

  static String format(double value, UnitType unit) {
    final UnitSettings s = UnitConfig.get(unit);
    return value.toStringAsFixed(s.decimals);
  }

  static num _pow10(int n) {
    num r = 1;
    for (int i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
