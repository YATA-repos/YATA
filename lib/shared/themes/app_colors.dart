import "package:flutter/material.dart";

class AppColors {
  AppColors._();

  // ==========================================================================
  // Primary Colors (青系)
  // ==========================================================================

  /// メインアクション用プライマリカラー (blue-600)
  static const Color primary = Color(0xFF2563EB);

  /// プライマリカラー用の前景色
  static const Color primaryForeground = Color(0xFFFFFFFF);

  /// セカンダリアクション用カラー (blue-700)
  static const Color secondary = Color(0xFF1D4ED8);

  /// セカンダリカラー用の前景色
  static const Color secondaryForeground = Color(0xFFFFFFFF);

  /// アクセントカラー (blue-500)
  static const Color accent = Color(0xFF3B82F6);

  /// アクセントカラー用の前景色
  static const Color accentForeground = Color(0xFFFFFFFF);

  // ==========================================================================
  // Semantic Colors (ステータスカラー)
  // ==========================================================================

  /// 成功・在庫あり (green-600)
  static const Color success = Color(0xFF16A34A);

  /// 成功カラー用の前景色
  static const Color successForeground = Color(0xFFF0FDF4);

  /// 警告・在庫少 (yellow-600)
  static const Color warning = Color(0xFFCA8A04);

  /// 警告カラー用の前景色
  static const Color warningForeground = Color(0xFFFEFCE8);

  /// 危険・緊急 (red-600)
  static const Color danger = Color(0xFFDC2626);

  /// 危険カラー用の前景色
  static const Color dangerForeground = Color(0xFFFEF2F2);

  // ==========================================================================
  // Base Colors (基本カラー)
  // ==========================================================================

  /// 背景色
  static const Color background = Color(0xFFFFFFFF);

  /// 前景色
  static const Color foreground = Color(0xFF0F172A);

  /// カード背景色
  static const Color card = Color(0xFFFFFFFF);

  /// カード前景色
  static const Color cardForeground = Color(0xFF0F172A);

  /// ポップオーバー背景色
  static const Color popover = Color(0xFFFFFFFF);

  /// ポップオーバー前景色
  static const Color popoverForeground = Color(0xFF0F172A);

  /// ミュートされた背景色
  static const Color muted = Color(0xFFF1F5F9);

  /// ミュートされた前景色
  static const Color mutedForeground = Color(0xFF64748B);

  /// 境界線色
  static const Color border = Color(0xFFE2E8F0);

  /// 入力フィールド境界線色
  static const Color input = Color(0xFFE2E8F0);

  /// フォーカスリング色
  static const Color ring = Color(0xFF2563EB);

  // ==========================================================================
  // Utility Colors (ユーティリティカラー)
  // ==========================================================================

  /// 半透明の成功カラー (10% opacity)
  static const Color successMuted = Color(0x1A16A34A);

  /// 半透明の警告カラー (10% opacity)
  static const Color warningMuted = Color(0x1ACA8A04);

  /// 半透明の危険カラー (10% opacity)
  static const Color dangerMuted = Color(0x1ADC2626);

  /// 半透明の成功カラー (20% opacity) - ホバー用
  static const Color successMutedHover = Color(0x3316A34A);

  /// 半透明の警告カラー (20% opacity) - ホバー用
  static const Color warningMutedHover = Color(0x33CA8A04);

  /// 半透明の危険カラー (20% opacity) - ホバー用
  static const Color dangerMutedHover = Color(0x33DC2626);

  /// 半透明のミュートカラー (50% opacity) - ホバー用
  static const Color mutedHover = Color(0x80F1F5F9);

  /// 半透明のプライマリカラー (90% opacity) - ホバー用
  static const Color primaryHover = Color(0xE62563EB);

  // ==========================================================================
  // Dark Mode Colors (ダークモード用カラー)
  // ==========================================================================

  /// ダークモード用背景色
  static const Color darkBackground = Color(0xFF0F172A);

  /// ダークモード用前景色
  static const Color darkForeground = Color(0xFFF8FAFC);

  /// ダークモード用カード背景色
  static const Color darkCard = Color(0xFF1E293B);

  /// ダークモード用カード前景色
  static const Color darkCardForeground = Color(0xFFF8FAFC);

  /// ダークモード用ミュート背景色
  static const Color darkMuted = Color(0xFF1E293B);

  /// ダークモード用ミュート前景色
  static const Color darkMutedForeground = Color(0xFF94A3B8);

  /// ダークモード用境界線色
  static const Color darkBorder = Color(0xFF334155);

  /// ダークモード用入力フィールド境界線色
  static const Color darkInput = Color(0xFF334155);
}
