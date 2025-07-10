import "package:flutter/material.dart";
import "app_colors.dart";

/// YATAアプリケーションのテーマ設定
///
/// UIシステムデータガイドに基づいて定義されたテーマシステム
class AppTheme {
  AppTheme._();

  // ==========================================================================
  // Light Theme (ライトテーマ)
  // ==========================================================================

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // カラースキーム
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      tertiary: AppColors.accent,
      onTertiary: AppColors.accentForeground,
      error: AppColors.danger,
      onError: AppColors.dangerForeground,
      onSurface: AppColors.foreground,
      surfaceContainerHighest: AppColors.card,
      onSurfaceVariant: AppColors.mutedForeground,
      outline: AppColors.border,
      shadow: Colors.black26,
    ),

    // スカッフォールド
    scaffoldBackgroundColor: AppColors.background,

    // アプリバー
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.foreground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    // カード
    cardTheme: const CardThemeData(
      color: AppColors.card,
      shadowColor: Colors.black12,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    ),

    // ボタン
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.foreground,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
    ),

    // 入力フィールド
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.input),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.input),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.ring, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      hintStyle: TextStyle(color: AppColors.mutedForeground),
    ),

    // 分割線
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),

    // タブバー
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.foreground,
      unselectedLabelColor: AppColors.mutedForeground,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
    ),

    // ボトムナビゲーション
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.mutedForeground,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // ダイアログ
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.background,
      titleTextStyle: TextStyle(
        color: AppColors.foreground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: AppColors.foreground, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    ),

    // スナックバー
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.foreground,
      contentTextStyle: TextStyle(color: AppColors.background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(
        color: AppColors.foreground,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      subtitleTextStyle: TextStyle(
        color: AppColors.mutedForeground,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Chip
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.muted,
      labelStyle: TextStyle(color: AppColors.foreground),
      side: BorderSide(color: AppColors.border),
    ),

    // Icon
    iconTheme: const IconThemeData(color: AppColors.foreground, size: 24),

    // Badge
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.danger,
      textColor: AppColors.dangerForeground,
    ),

    // テキストテーマ
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.foreground),
      displayMedium: TextStyle(color: AppColors.foreground),
      displaySmall: TextStyle(color: AppColors.foreground),
      headlineLarge: TextStyle(color: AppColors.foreground),
      headlineMedium: TextStyle(color: AppColors.foreground),
      headlineSmall: TextStyle(color: AppColors.foreground),
      titleLarge: TextStyle(color: AppColors.foreground),
      titleMedium: TextStyle(color: AppColors.foreground),
      titleSmall: TextStyle(color: AppColors.foreground),
      bodyLarge: TextStyle(color: AppColors.foreground),
      bodyMedium: TextStyle(color: AppColors.foreground),
      bodySmall: TextStyle(color: AppColors.mutedForeground),
      labelLarge: TextStyle(color: AppColors.foreground),
      labelMedium: TextStyle(color: AppColors.foreground),
      labelSmall: TextStyle(color: AppColors.mutedForeground),
    ),
  );

  // ==========================================================================
  // Dark Theme (ダークテーマ)
  // ==========================================================================

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // カラースキーム
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      tertiary: AppColors.accent,
      onTertiary: AppColors.accentForeground,
      error: AppColors.danger,
      onError: AppColors.dangerForeground,
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkForeground,
      surfaceContainerHighest: AppColors.darkCard,
      onSurfaceVariant: AppColors.darkMutedForeground,
      outline: AppColors.darkBorder,
      shadow: Colors.black54,
    ),

    // スカッフォールド
    scaffoldBackgroundColor: AppColors.darkBackground,

    // アプリバー
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkForeground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.darkForeground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    // カード
    cardTheme: const CardThemeData(
      color: AppColors.darkCard,
      shadowColor: Colors.black54,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    ),

    // ボタン
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkForeground,
        side: const BorderSide(color: AppColors.darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkForeground,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
    ),

    // 入力フィールド
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkBackground,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.darkInput),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.darkInput),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.ring, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      hintStyle: TextStyle(color: AppColors.darkMutedForeground),
    ),

    // 分割線
    dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1),

    // タブバー
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.darkForeground,
      unselectedLabelColor: AppColors.darkMutedForeground,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
    ),

    // ボトムナビゲーション
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBackground,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkMutedForeground,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // ダイアログ
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.darkCard,
      titleTextStyle: TextStyle(
        color: AppColors.darkForeground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: AppColors.darkForeground, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    ),

    // スナックバー
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.darkForeground,
      contentTextStyle: TextStyle(color: AppColors.darkBackground),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(
        color: AppColors.darkForeground,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      subtitleTextStyle: TextStyle(
        color: AppColors.darkMutedForeground,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Chip
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.darkMuted,
      labelStyle: TextStyle(color: AppColors.darkForeground),
      side: BorderSide(color: AppColors.darkBorder),
    ),

    // Icon
    iconTheme: const IconThemeData(color: AppColors.darkForeground, size: 24),

    // Badge
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.danger,
      textColor: AppColors.dangerForeground,
    ),

    // テキストテーマ
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.darkForeground),
      displayMedium: TextStyle(color: AppColors.darkForeground),
      displaySmall: TextStyle(color: AppColors.darkForeground),
      headlineLarge: TextStyle(color: AppColors.darkForeground),
      headlineMedium: TextStyle(color: AppColors.darkForeground),
      headlineSmall: TextStyle(color: AppColors.darkForeground),
      titleLarge: TextStyle(color: AppColors.darkForeground),
      titleMedium: TextStyle(color: AppColors.darkForeground),
      titleSmall: TextStyle(color: AppColors.darkForeground),
      bodyLarge: TextStyle(color: AppColors.darkForeground),
      bodyMedium: TextStyle(color: AppColors.darkForeground),
      bodySmall: TextStyle(color: AppColors.darkMutedForeground),
      labelLarge: TextStyle(color: AppColors.darkForeground),
      labelMedium: TextStyle(color: AppColors.darkForeground),
      labelSmall: TextStyle(color: AppColors.darkMutedForeground),
    ),
  );
}
