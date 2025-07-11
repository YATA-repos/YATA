import "package:flutter/material.dart";
import "app_colors.dart";

class AppTextStyles {
  AppTextStyles._();

  static const String fontGeistSans = "Geist";
  static const String fontGeistMono = "GeistMono";
  static const String fontSystemSans = "system-ui, -apple-system, sans-serif";
  static const String fontSystemMono = "Courier New, monospace";

  static const TextStyle textXs = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const TextStyle textSm = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const TextStyle textBase = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const TextStyle textLg = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
  static const TextStyle textXl = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const TextStyle text2xl = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const TextStyle text3xl = TextStyle(fontSize: 30, fontWeight: FontWeight.w700);

  static const TextStyle textSuccess = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
  );
  static const TextStyle textWarning = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
  );
  static const TextStyle textError = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.danger,
  );
  static const TextStyle textMuted = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);

  static const TextStyle monoXs = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontGeistMono,
  );
  static const TextStyle monoSm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: fontGeistMono,
  );
  static const TextStyle monoBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: fontGeistMono,
  );
  static const TextStyle monoLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: fontGeistMono,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryForeground,
  );
  static const TextStyle buttonDefault = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryForeground,
  );
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryForeground,
  );
  static const TextStyle buttonOutline = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );
  static const TextStyle buttonGhost = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );

  static const TextStyle darkTextBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.darkForeground,
  );
  static const TextStyle darkTextXl = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkForeground,
  );
  static const TextStyle darkText3xl = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.darkForeground,
  );
  static const TextStyle darkTextMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkMutedForeground,
  );

  static const TextStyle textPrice = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: fontGeistMono,
    color: AppColors.foreground,
  );
  static const TextStyle textPriceLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: fontGeistMono,
    color: AppColors.foreground,
  );
  static const TextStyle textQuantity = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: fontGeistMono,
    color: AppColors.foreground,
  );
  static const TextStyle textStatistic = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: fontGeistMono,
    color: AppColors.foreground,
  );
  static const TextStyle textBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryForeground,
  );
  static const TextStyle textCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  );

  static TextStyle withColor(TextStyle baseStyle, Color color) => baseStyle.copyWith(color: color);
  static TextStyle withWeight(TextStyle baseStyle, FontWeight weight) =>
      baseStyle.copyWith(fontWeight: weight);
  static TextStyle withSize(TextStyle baseStyle, double size) => baseStyle.copyWith(fontSize: size);
  static TextStyle withUnderline(TextStyle baseStyle) =>
      baseStyle.copyWith(decoration: TextDecoration.underline);
  static TextStyle withStrikethrough(TextStyle baseStyle) =>
      baseStyle.copyWith(decoration: TextDecoration.lineThrough);

  static Color getThemeAwareForegroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkForeground
      : AppColors.foreground;
  static Color getThemeAwareMutedColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkMutedForeground
      : AppColors.mutedForeground;
  static TextStyle getThemeAwareTextBase(BuildContext context) =>
      textBase.copyWith(color: getThemeAwareForegroundColor(context));
  static TextStyle getThemeAwareTextLg(BuildContext context) =>
      textLg.copyWith(color: getThemeAwareForegroundColor(context));
  static TextStyle getThemeAwareTextCaption(BuildContext context) =>
      textCaption.copyWith(color: getThemeAwareMutedColor(context));
  static TextStyle getThemeAwareTextPrice(BuildContext context) =>
      textPrice.copyWith(color: getThemeAwareForegroundColor(context));
}
