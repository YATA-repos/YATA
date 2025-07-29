import "package:flutter/material.dart";
import "./app_colors.dart";

class AppTextTheme {
  AppTextTheme._();

  // TextTheme定義
  static TextTheme get textTheme => const TextTheme(
    // ヘッダー・タイトル系
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.foreground,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.foreground,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.foreground),

    // 見出し系
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.foreground,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.foreground,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.foreground,
    ),

    // タイトル系
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground),
    titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.foreground),

    // ボディテキスト系
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.foreground,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.foreground,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.mutedForeground,
      height: 1.3,
    ),

    // ラベル系
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.foreground),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.mutedForeground,
    ),
  );

  // カスタムテキストスタイル（アプリ固有）
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );

  static const TextStyle cardDescription = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.mutedForeground,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.trueWhite,
  );

  static const TextStyle buttonTextSecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );

  static const TextStyle priceText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.foreground,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.trueWhite,
  );

  static const TextStyle tableHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );

  static const TextStyle tableCell = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.foreground,
  );

  static const TextStyle navigationText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );

  static const TextStyle navigationTextActive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle mobileNavText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.mutedForeground,
  );

  static const TextStyle mobileNavTextActive = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.primary,
  );

  // ステータス別テキストスタイル
  static const TextStyle successText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
  );

  static const TextStyle warningText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
  );

  static const TextStyle dangerText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.danger,
  );

  // 入力フィールド用
  static const TextStyle inputText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.foreground,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.mutedForeground,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );
}
