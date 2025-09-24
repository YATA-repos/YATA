import 'package:flutter/widgets.dart';

/// コンポーネント間の余白スケールを提供するトークン。
class YataSpacingTokens {
  const YataSpacingTokens._();

  /// 最小マージン (アイコン同士など)。
  static const double xxs = 4.0;

  /// コンパクトなUI要素で使用。
  static const double xs = 8.0;

  /// テキストとアイコンの標準余白。
  static const double sm = 12.0;

  /// コンポーネント間の基本余白。
  static const double md = 16.0;

  /// カード間やセクション間の余白。
  static const double lg = 24.0;

  /// ページ内の大型セクション余白。
  static const double xl = 32.0;

  /// 画面全幅の余白やヒーローブロック用。
  static const double xxl = 48.0;

  /// 共通の画面パディング。
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0);

  /// カードコンポーネントの標準パディング。
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);

  /// 入力フォームの内容パディング。
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
}
