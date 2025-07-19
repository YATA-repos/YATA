import "package:flutter/material.dart";
import "app_colors.dart";

class AppTextStyles {
  AppTextStyles._();

  static const String fontGeistSans = "Geist";
  static const String fontGeistMono = "GeistMono";
  static const String fontSystemSans = "system-ui, -apple-system, sans-serif";
  static const String fontSystemMono = "Courier New, monospace";

  static const TextStyle text2Xs = TextStyle(fontSize: 10, fontWeight: FontWeight.w400);
  static const TextStyle textXs = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const TextStyle textSm = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);
  static const TextStyle text = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const TextStyle textMd = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
  static const TextStyle textLg = TextStyle(fontSize: 20, fontWeight: FontWeight.w500);
  static const TextStyle textXl = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const TextStyle text2Xl = TextStyle(fontSize: 30, fontWeight: FontWeight.w700);

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
  static const TextStyle textCaption = textXs;
  static const TextStyle textTitle = text2Xl;
  static const TextStyle textSubtitle = textLg;



  static TextStyle withColor(TextStyle baseStyle, Color color) => baseStyle.copyWith(color: color);
  static TextStyle withWeight(TextStyle baseStyle, FontWeight weight) =>
      baseStyle.copyWith(fontWeight: weight);
  static TextStyle withSize(TextStyle baseStyle, double size) => baseStyle.copyWith(fontSize: size);
  static TextStyle withUnderline(TextStyle baseStyle) =>
      baseStyle.copyWith(decoration: TextDecoration.underline);
  static TextStyle withStrikethrough(TextStyle baseStyle) =>
      baseStyle.copyWith(decoration: TextDecoration.lineThrough);
}
