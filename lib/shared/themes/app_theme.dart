import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../foundations/tokens/color_tokens.dart";
import "../foundations/tokens/elevetion_token.dart";
import "../foundations/tokens/radius_tokens.dart";
import "../foundations/tokens/spacing_tokens.dart";
import "../foundations/tokens/typography_tokens.dart";

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final ColorScheme colorScheme = brightness == Brightness.light
        ? _lightColorScheme
        : _darkColorScheme;
    final TextTheme baseTextTheme = _buildTextTheme(brightness);
    final TextTheme textTheme = GoogleFonts.notoSansJpTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.notoSansJp().fontFamily,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      shadowColor: colorScheme.shadow,
      dividerColor: colorScheme.outlineVariant,
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      hoverColor: colorScheme.primary.withOpacity(0.08),
      highlightColor: colorScheme.primary.withOpacity(0.12),
      splashColor: colorScheme.primary.withOpacity(0.14),
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme, textTheme),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, space: 1, thickness: 1),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      radioTheme: _buildRadioTheme(colorScheme),
      switchTheme: _buildSwitchTheme(colorScheme),
      floatingActionButtonTheme: _buildFabTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme, textTheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      listTileTheme: _buildListTileTheme(colorScheme),
      visualDensity: VisualDensity.standard,
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color primaryTextColor = brightness == Brightness.light
        ? YataColorTokens.textPrimary
        : YataColorTokens.neutral0;
    final Color secondaryTextColor = brightness == Brightness.light
        ? YataColorTokens.textSecondary
        : YataColorTokens.neutral200;

    const TextTheme base = TextTheme(
      displayLarge: YataTypographyTokens.displayLarge,
      headlineLarge: YataTypographyTokens.headlineLarge,
      headlineMedium: YataTypographyTokens.headlineMedium,
      headlineSmall: YataTypographyTokens.headlineSmall,
      titleLarge: YataTypographyTokens.titleLarge,
      titleMedium: YataTypographyTokens.titleMedium,
      titleSmall: YataTypographyTokens.titleSmall,
      bodyLarge: YataTypographyTokens.bodyLarge,
      bodyMedium: YataTypographyTokens.bodyMedium,
      bodySmall: YataTypographyTokens.bodySmall,
      labelLarge: YataTypographyTokens.labelLarge,
      labelMedium: YataTypographyTokens.labelMedium,
      labelSmall: YataTypographyTokens.labelSmall,
    );

    return base
        .apply(
          bodyColor: primaryTextColor,
          displayColor: primaryTextColor,
          decorationColor: primaryTextColor,
        )
        .copyWith(
          bodyMedium: base.bodyMedium?.copyWith(color: secondaryTextColor),
          bodySmall: base.bodySmall?.copyWith(color: secondaryTextColor),
          titleSmall: base.titleSmall?.copyWith(color: secondaryTextColor),
          labelMedium: base.labelMedium?.copyWith(color: secondaryTextColor),
          labelSmall: base.labelSmall?.copyWith(color: secondaryTextColor),
        );
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) => AppBarTheme(
    backgroundColor: colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    foregroundColor: colorScheme.onSurface,
    titleTextStyle: GoogleFonts.notoSansJp(
      textStyle: YataTypographyTokens.titleLarge.copyWith(color: colorScheme.onSurface),
    ),
    iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
  );

  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    final BoxShadow cardShadow = YataElevationTokens.level1.first;

    return CardThemeData(
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      margin: EdgeInsets.zero,
      shadowColor: cardShadow.color,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.large)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(ColorScheme colorScheme) =>
      FilledButtonThemeData(style: _buildPrimaryFilledButtonStyle(colorScheme));

  static ButtonStyle _buildPrimaryFilledButtonStyle(ColorScheme colorScheme) {
    final BoxShadow buttonShadow = YataElevationTokens.level2.first;

    return ButtonStyle(
      textStyle: WidgetStateProperty.all(YataTypographyTokens.labelLarge),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: YataSpacingTokens.lg,
          vertical: YataSpacingTokens.sm,
        ),
      ),
      shape: WidgetStateProperty.all(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        ),
      ),
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(buttonShadow.color),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) =>
      ElevatedButtonThemeData(
        style: _buildPrimaryFilledButtonStyle(colorScheme).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => states.contains(WidgetState.disabled)
                ? colorScheme.primary.withOpacity(0.45)
                : colorScheme.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => states.contains(WidgetState.disabled)
                ? colorScheme.onSurface.withOpacity(0.4)
                : colorScheme.onPrimary,
          ),
          overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.transparent;
            }
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withOpacity(0.18);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withOpacity(0.1);
            }
            return null;
          }),
        ),
      );

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme colorScheme) =>
      OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => states.contains(WidgetState.disabled)
                ? colorScheme.onSurface.withOpacity(0.4)
                : colorScheme.primary,
          ),
          textStyle: WidgetStateProperty.all(
            YataTypographyTokens.labelLarge.copyWith(color: colorScheme.primary),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: YataSpacingTokens.lg,
              vertical: YataSpacingTokens.sm,
            ),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
            ),
          ),
          side: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? colorScheme.outlineVariant
                  : colorScheme.primary,
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.transparent;
            }
            final double opacity = states.contains(WidgetState.pressed) ? 0.1 : 0.05;
            return colorScheme.primary.withOpacity(opacity);
          }),
        ),
      );

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) => TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? colorScheme.onSurface.withOpacity(0.4)
            : colorScheme.primary,
      ),
      textStyle: WidgetStateProperty.all(
        YataTypographyTokens.labelLarge.copyWith(color: colorScheme.primary),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: YataSpacingTokens.md,
          vertical: YataSpacingTokens.xs,
        ),
      ),
      overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        final double opacity = states.contains(WidgetState.pressed) ? 0.1 : 0.05;
        return colorScheme.primary.withOpacity(opacity);
      }),
    ),
  );

  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme colorScheme) {
    const BorderRadius inputRadius = BorderRadius.all(Radius.circular(YataRadiusTokens.medium));
    final OutlineInputBorder baseBorder = OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1.2),
    );
    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
    );
    final OutlineInputBorder errorBorder = OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: BorderSide(color: colorScheme.error, width: 1.4),
    );
    final OutlineInputBorder focusedErrorBorder = OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: BorderSide(color: colorScheme.error, width: 1.6),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: YataSpacingTokens.inputPadding,
      hintStyle: YataTypographyTokens.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      labelStyle: YataTypographyTokens.titleSmall.copyWith(color: colorScheme.onSurfaceVariant),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: focusedErrorBorder,
      errorStyle: YataTypographyTokens.bodySmall.copyWith(color: colorScheme.error),
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme, TextTheme textTheme) =>
      ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        disabledColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        selectedColor: colorScheme.primary.withOpacity(0.12),
        secondarySelectedColor: colorScheme.primary.withOpacity(0.18),
        padding: const EdgeInsets.symmetric(
          horizontal: YataSpacingTokens.sm,
          vertical: YataSpacingTokens.xs,
        ),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
        brightness: colorScheme.brightness,
        side: BorderSide(color: colorScheme.outlineVariant),
      );

  static CheckboxThemeData _buildCheckboxTheme(ColorScheme colorScheme) => CheckboxThemeData(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(YataRadiusTokens.small)),
    ),
    side: BorderSide(color: colorScheme.outlineVariant),
    fillColor: WidgetStateProperty.resolveWith(
      (Set<WidgetState> states) =>
          states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.surface,
    ),
    checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
  );

  static RadioThemeData _buildRadioTheme(ColorScheme colorScheme) => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (Set<WidgetState> states) =>
          states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.outlineVariant,
    ),
  );

  static SwitchThemeData _buildSwitchTheme(ColorScheme colorScheme) => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (Set<WidgetState> states) =>
          states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.outlineVariant,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (Set<WidgetState> states) => states.contains(WidgetState.selected)
          ? colorScheme.primary.withOpacity(0.35)
          : colorScheme.outlineVariant.withOpacity(0.5),
    ),
  );

  static FloatingActionButtonThemeData _buildFabTheme(ColorScheme colorScheme) =>
      FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YataRadiusTokens.large)),
        ),
        focusColor: colorScheme.primary.withOpacity(0.18),
        splashColor: colorScheme.primary.withOpacity(0.2),
        hoverColor: colorScheme.primary.withOpacity(0.12),
        iconSize: 24,
      );

  static DialogThemeData _buildDialogTheme(ColorScheme colorScheme, TextTheme textTheme) =>
      DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: YataElevationTokens.level4.first.color,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YataRadiusTokens.large)),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      );

  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) =>
      BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(YataRadiusTokens.large)),
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
      );

  static ListTileThemeData _buildListTileTheme(ColorScheme colorScheme) => ListTileThemeData(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
    ),
    tileColor: colorScheme.surface,
    iconColor: colorScheme.onSurfaceVariant,
    textColor: colorScheme.onSurface,
    dense: false,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: YataSpacingTokens.md,
      vertical: YataSpacingTokens.xs,
    ),
  );

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: YataColorTokens.primary,
    onPrimary: YataColorTokens.neutral0,
    primaryContainer: YataColorTokens.primarySoft,
    onPrimaryContainer: YataColorTokens.primary,
    secondary: YataColorTokens.info,
    onSecondary: YataColorTokens.neutral0,
    secondaryContainer: YataColorTokens.infoSoft,
    onSecondaryContainer: YataColorTokens.info,
    tertiary: YataColorTokens.success,
    onTertiary: YataColorTokens.neutral0,
    tertiaryContainer: YataColorTokens.successSoft,
    onTertiaryContainer: YataColorTokens.success,
    error: YataColorTokens.danger,
    onError: YataColorTokens.neutral0,
    errorContainer: YataColorTokens.dangerSoft,
    onErrorContainer: YataColorTokens.danger,
    surface: YataColorTokens.surface,
    onSurface: YataColorTokens.textPrimary,
    surfaceContainerHighest: YataColorTokens.surfaceAlt,
    onSurfaceVariant: YataColorTokens.textSecondary,
    outline: YataColorTokens.border,
    outlineVariant: YataColorTokens.neutral300,
    shadow: Color(0x1411182A),
    scrim: Color(0x6611182A),
    inverseSurface: YataColorTokens.neutral900,
    onInverseSurface: YataColorTokens.neutral0,
    inversePrimary: Color(0xFFBFD6FF),
    surfaceTint: YataColorTokens.primary,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: YataColorTokens.primary,
    onPrimary: YataColorTokens.neutral0,
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: YataColorTokens.primarySoft,
    secondary: YataColorTokens.info,
    onSecondary: YataColorTokens.neutral0,
    secondaryContainer: Color(0xFF0C4A6E),
    onSecondaryContainer: Color(0xFFBAE6FD),
    tertiary: YataColorTokens.success,
    onTertiary: YataColorTokens.neutral0,
    tertiaryContainer: Color(0xFF14532D),
    onTertiaryContainer: YataColorTokens.successSoft,
    error: YataColorTokens.danger,
    onError: YataColorTokens.neutral0,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: YataColorTokens.dangerSoft,
    surface: YataColorTokens.neutral800,
    onSurface: YataColorTokens.neutral0,
    surfaceContainerHighest: YataColorTokens.neutral700,
    onSurfaceVariant: YataColorTokens.neutral200,
    outline: YataColorTokens.neutral600,
    outlineVariant: YataColorTokens.neutral700,
    shadow: Color(0xFF000000),
    scrim: Color(0xB3000000),
    inverseSurface: YataColorTokens.neutral100,
    onInverseSurface: YataColorTokens.neutral900,
    inversePrimary: Color(0xFFE0E9FF),
    surfaceTint: YataColorTokens.primary,
  );
}
