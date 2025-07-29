import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "./app_colors.dart";
import "./app_text_theme.dart";

class AppTheme {
  AppTheme._();

  /// ライトテーマ
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = _buildLightColorScheme();
    final TextTheme textTheme = _buildTextTheme(false);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,

      // AppBar テーマ
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.foreground,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextTheme.navigationText.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card テーマ
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
        ),
      ),

      // ElevatedButton テーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          textStyle: AppTextTheme.buttonText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // OutlinedButton テーマ
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextTheme.buttonTextSecondary,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // TextButton テーマ
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextTheme.buttonTextSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // InputDecoration テーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        labelStyle: AppTextTheme.inputLabel,
        hintStyle: AppTextTheme.inputHint,
        helperStyle: AppTextTheme.cardDescription,
        errorStyle: AppTextTheme.dangerText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),

      // BottomNavigationBar テーマ
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        selectedLabelStyle: AppTextTheme.mobileNavTextActive,
        unselectedLabelStyle: AppTextTheme.mobileNavText,
        type: BottomNavigationBarType.fixed,
      ),

      // Divider テーマ
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),

      // IconButton テーマ
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.foreground),
      ),
    );
  }

  /// ダークテーマ
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = _buildDarkColorScheme();
    final TextTheme textTheme = _buildTextTheme(true);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // AppBar テーマ
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.darkForeground,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextTheme.navigationText.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkForeground,
        ),
      ),

      // Card テーマ
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.darkBorder),
        ),
      ),

      // その他のテーマはライトテーマと同様の構造でダーク色を適用
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          textStyle: AppTextTheme.buttonText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppTextTheme.inputLabel.copyWith(color: AppColors.darkForeground),
        hintStyle: AppTextTheme.inputHint.copyWith(color: AppColors.darkMutedForeground),
      ),
    );
  }

  /// ライトモード用ColorScheme構築
  static ColorScheme _buildLightColorScheme() => ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.secondaryForeground,
    onSurface: AppColors.cardForeground,
    error: AppColors.danger,
    onError: AppColors.dangerForeground,
    outline: AppColors.border,
  );

  /// ダークモード用ColorScheme構築
  static ColorScheme _buildDarkColorScheme() => ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.primaryForeground,
    secondary: AppColors.secondary,
    onSecondary: AppColors.secondaryForeground,
    surface: AppColors.darkCard,
    onSurface: AppColors.darkCardForeground,
    error: AppColors.danger,
    onError: AppColors.dangerForeground,
    outline: AppColors.darkBorder,
  );

  /// TextTheme構築
  static TextTheme _buildTextTheme(bool isDark) {
    final TextTheme baseTheme = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    // 既存のAppTextThemeを統合
    return baseTheme
        .copyWith(
          displayLarge: AppTextTheme.textTheme.displayLarge,
          displayMedium: AppTextTheme.textTheme.displayMedium,
          displaySmall: AppTextTheme.textTheme.displaySmall,
          headlineLarge: AppTextTheme.textTheme.headlineLarge,
          headlineMedium: AppTextTheme.textTheme.headlineMedium,
          headlineSmall: AppTextTheme.textTheme.headlineSmall,
          titleLarge: AppTextTheme.textTheme.titleLarge,
          titleMedium: AppTextTheme.textTheme.titleMedium,
          titleSmall: AppTextTheme.textTheme.titleSmall,
          bodyLarge: AppTextTheme.textTheme.bodyLarge,
          bodyMedium: AppTextTheme.textTheme.bodyMedium,
          bodySmall: AppTextTheme.textTheme.bodySmall,
          labelLarge: AppTextTheme.textTheme.labelLarge,
          labelMedium: AppTextTheme.textTheme.labelMedium,
          labelSmall: AppTextTheme.textTheme.labelSmall,
        )
        .apply(
          bodyColor: isDark ? AppColors.darkForeground : AppColors.foreground,
          displayColor: isDark ? AppColors.darkForeground : AppColors.foreground,
        );
  }
}
