import "package:flutter/widgets.dart";

/// 角丸表現の統一トークン。
class YataRadiusTokens {
  const YataRadiusTokens._();

  /// 角丸なし。
  static const double none = 0.0;

  /// 小型バッジやタグで使用。
  static const double small = 8.0;

  /// カードや入力フィールドの標準角丸。
  static const double medium = 12.0;

  /// 主要カードやモーダルの角丸。
  static const double large = 16.0;

  /// ヒーローカードやハイライトの角丸。
  static const double xLarge = 20.0;

  /// カードに共通するBorderRadius。
  static const BorderRadius borderRadiusCard = BorderRadius.all(Radius.circular(medium));

  /// バッジなどに使用するピル型BorderRadius。
  static const BorderRadius borderRadiusPill = BorderRadius.all(Radius.circular(999));
}
