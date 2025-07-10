import "package:flutter/material.dart";
import "app_colors.dart";

/// YATAアプリケーションのテキストスタイル
///
/// UIシステムデータガイドに基づいて定義されたタイポグラフィシステム
class AppTextStyles {
  AppTextStyles._();

  // ==========================================================================
  // Font Family (フォントファミリー)
  // ==========================================================================

  /// Geist Sans - UI テキスト用
  static const String fontGeistSans = "Geist";

  /// Geist Mono - コード・数値用
  static const String fontGeistMono = "GeistMono";

  /// システムフォントファミリー（フォールバック）
  static const String fontSystemSans = "system-ui, -apple-system, sans-serif";

  /// システムモノスペースフォントファミリー（フォールバック）
  static const String fontSystemMono = "Courier New, monospace";

  // ==========================================================================
  // Base Text Styles (基本テキストスタイル)
  // ==========================================================================

  /// 補助情報用（12px）
  static const TextStyle textXs = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);

  /// 説明文用（14px）
  static const TextStyle textSm = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);

  /// 本文用（16px）
  static const TextStyle textBase = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  /// 小見出し用（18px）
  static const TextStyle textLg = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);

  /// 見出し用（20px）
  static const TextStyle textXl = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);

  /// 大見出し用（24px）
  static const TextStyle text2xl = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);

  /// タイトル用（30px）
  static const TextStyle text3xl = TextStyle(fontSize: 30, fontWeight: FontWeight.w700);

  // ==========================================================================
  // Semantic Text Styles (セマンティックテキストスタイル)
  // ==========================================================================

  /// 成功メッセージ用
  static const TextStyle textSuccess = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
  );

  /// 警告メッセージ用
  static const TextStyle textWarning = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
  );

  /// エラーメッセージ用
  static const TextStyle textError = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.danger,
  );

  /// ミュートされたテキスト用
  static const TextStyle textMuted = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);

  // ==========================================================================
  // Monospace Text Styles (モノスペーステキストスタイル)
  // ==========================================================================

  /// コード・数値用（12px）
  static const TextStyle monoXs = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontGeistMono,
  );

  /// コード・数値用（14px）
  static const TextStyle monoSm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: fontGeistMono,
  );

  /// コード・数値用（16px）
  static const TextStyle monoBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: fontGeistMono,
  );

  /// 大きなコード・数値用（18px）
  static const TextStyle monoLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: fontGeistMono,
  );

  // ==========================================================================
  // Button Text Styles (ボタンテキストスタイル)
  // ==========================================================================

  /// 小ボタン用テキスト
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryForeground,
  );

  /// 標準ボタン用テキスト
  static const TextStyle buttonDefault = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryForeground,
  );

  /// 大ボタン用テキスト
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryForeground,
  );

  /// アウトラインボタン用テキスト
  static const TextStyle buttonOutline = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );

  /// ゴーストボタン用テキスト
  static const TextStyle buttonGhost = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );

  // ==========================================================================
  // Dark Mode Text Styles (ダークモードテキストスタイル)
  // ==========================================================================

  /// ダークモード用本文
  static const TextStyle darkTextBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.darkForeground,
  );

  /// ダークモード用見出し
  static const TextStyle darkTextXl = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkForeground,
  );

  /// ダークモード用タイトル
  static const TextStyle darkText3xl = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.darkForeground,
  );

  /// ダークモード用ミュートテキスト
  static const TextStyle darkTextMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkMutedForeground,
  );

  // ==========================================================================
  // Special Text Styles (特別なテキストスタイル)
  // ==========================================================================

  /// 価格表示用
  static const TextStyle textPrice = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: fontGeistMono,
    color: AppColors.foreground,
  );

  /// 大きな価格表示用
  static const TextStyle textPriceLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: fontGeistMono,
    color: AppColors.foreground,
  );

  /// 数量表示用
  static const TextStyle textQuantity = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: fontGeistMono,
    color: AppColors.foreground,
  );

  /// 統計数値用
  static const TextStyle textStatistic = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: fontGeistMono,
    color: AppColors.foreground,
  );

  /// バッジ用テキスト
  static const TextStyle textBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryForeground,
  );

  /// キャプション用テキスト
  static const TextStyle textCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  );

  // ==========================================================================
  // Utility Methods (ユーティリティメソッド)
  // ==========================================================================

  /// テキストスタイルの色を変更
  static TextStyle withColor(TextStyle baseStyle, Color color) => baseStyle.copyWith(color: color);

  /// テキストスタイルの太さを変更
  static TextStyle withWeight(TextStyle baseStyle, FontWeight weight) =>
      baseStyle.copyWith(fontWeight: weight);

  /// テキストスタイルのサイズを変更
  static TextStyle withSize(TextStyle baseStyle, double size) => baseStyle.copyWith(fontSize: size);

  /// テキストスタイルにアンダーラインを追加
  static TextStyle withUnderline(TextStyle baseStyle) =>
      baseStyle.copyWith(decoration: TextDecoration.underline);

  /// テキストスタイルに取り消し線を追加
  static TextStyle withStrikethrough(TextStyle baseStyle) =>
      baseStyle.copyWith(decoration: TextDecoration.lineThrough);

  // ==========================================================================
  // Theme-Aware Methods (テーマ対応メソッド)
  // ==========================================================================

  /// テーマに応じて適切な前景色を取得
  static Color getThemeAwareForegroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkForeground
      : AppColors.foreground;

  /// テーマに応じて適切なミュート前景色を取得
  static Color getThemeAwareMutedColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkMutedForeground
      : AppColors.mutedForeground;

  /// テーマに応じたテキストスタイルを取得（本文用）
  static TextStyle getThemeAwareTextBase(BuildContext context) =>
      textBase.copyWith(color: getThemeAwareForegroundColor(context));

  /// テーマに応じたテキストスタイルを取得（見出し用）
  static TextStyle getThemeAwareTextLg(BuildContext context) =>
      textLg.copyWith(color: getThemeAwareForegroundColor(context));

  /// テーマに応じたテキストスタイルを取得（キャプション用）
  static TextStyle getThemeAwareTextCaption(BuildContext context) =>
      textCaption.copyWith(color: getThemeAwareMutedColor(context));

  /// テーマに応じたテキストスタイルを取得（価格用）
  static TextStyle getThemeAwareTextPrice(BuildContext context) =>
      textPrice.copyWith(color: getThemeAwareForegroundColor(context));
}
