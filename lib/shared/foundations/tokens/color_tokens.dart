import 'package:flutter/material.dart';

/// YATAアプリ全体のカラーパレット定義。
class YataColorTokens {
  const YataColorTokens._();

  /// ブランドのプライマリカラー。
  static const Color primary = Color(0xFF2563EB);

  /// プライマリカラーのホバー/フォーカス用トーン。
  static const Color primaryHover = Color(0xFF1D4ED8);

  /// プライマリカラーの淡い背景用トーン。
  static const Color primarySoft = Color(0xFFE8EDFF);

  /// 行選択/一時ハイライト等に使う淡い背景色。
  /// 現状はブランドの `primarySoft` を採用（用途が広がれば独立調整可）。
  static const Color selectionSoft = primarySoft;

  /// 行選択/一時ハイライト等に使う透明感のあるティント。
  /// primaryに約10%のアルファを適用（ARGB）。
  static const Color selectionTint = Color(0x1A2563EB);

  /// 成功状態で使用するアクセントカラー。
  static const Color success = Color(0xFF16A34A);

  /// 成功状態の淡い背景色。
  static const Color successSoft = Color(0xFFDCFCE7);

  /// 警告状態で使用するアクセントカラー。
  static const Color warning = Color(0xFFF59E0B);

  /// 警告状態の淡い背景色。
  static const Color warningSoft = Color(0xFFFEF3C7);

  /// エラー状態で使用するアクセントカラー。
  static const Color danger = Color(0xFFDC2626);

  /// エラー状態の淡い背景色。
  static const Color dangerSoft = Color(0xFFFEE2E2);

  /// 情報強調で使用するアクセントカラー。
  static const Color info = Color(0xFF0284C7);

  /// 情報強調の淡い背景色。
  static const Color infoSoft = Color(0xFFE0F2FE);

  /// ニュートラルカラースケール (ライト → ダーク)。
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  /// アプリ全体の背景色。
  static const Color background = neutral50;

  /// 一般的なカード/シートの表面色。
  static const Color surface = neutral0;

  /// 強調カードなどで使用するセカンダリ表面色。
  static const Color surfaceAlt = neutral100;

  /// 標準的なボーダー色。
  static const Color border = neutral200;

  /// 区切り線・分割線カラー。
  static const Color divider = neutral200;

  /// プライマリテキストのカラー。
  static const Color textPrimary = neutral900;

  /// セカンダリテキストのカラー。
  static const Color textSecondary = neutral600;

  /// 弱いテキストのカラー。
  static const Color textTertiary = neutral500;
}
