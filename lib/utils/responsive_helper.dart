import "package:flutter/material.dart";

import "../core/constants/enums.dart";

/// レスポンシブデザイン支援ユーティリティクラス
///
/// デバイスサイズに基づいてレイアウトを調整するためのヘルパーメソッドを提供します。
/// YATAアプリの主要ターゲット（Android, Windows）に最適化されています。
class ResponsiveHelper {
  ResponsiveHelper._();

  // ブレークポイント定義
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  /// モバイルデバイスかどうかを判定
  ///
  /// width < 768px の場合にtrueを返します
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// タブレットデバイスかどうかを判定
  ///
  /// 768px <= width < 1024px の場合にtrueを返します
  static bool isTablet(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// デスクトップデバイスかどうかを判定
  ///
  /// width >= 1024px の場合にtrueを返します
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// 大画面デスクトップかどうかを判定
  ///
  /// width >= 1440px の場合にtrueを返します
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// デバイスタイプを取得
  static DeviceType getDeviceType(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < desktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  /// 現在の画面幅を取得
  static double getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;

  /// 現在の画面高さを取得
  static double getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  /// レスポンシブ値を取得
  ///
  /// デバイスタイプに応じて異なる値を返します
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final DeviceType deviceType = getDeviceType(context);

    return switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile,
      DeviceType.desktop => desktop ?? tablet ?? mobile,
      DeviceType.largeDesktop => largeDesktop ?? desktop ?? tablet ?? mobile,
    };
  }

  /// グリッドのカラム数を取得
  ///
  /// デバイスサイズに応じて適切なカラム数を返します
  static int getGridColumns(BuildContext context) => getResponsiveValue(context, mobile: 1, tablet: 2, desktop: 3, largeDesktop: 4);

  /// メニューアイテムグリッドのカラム数を取得
  ///
  /// メニュー表示に最適化されたカラム数を返します
  static int getMenuGridColumns(BuildContext context) => getResponsiveValue(context, mobile: 2, tablet: 3, desktop: 4, largeDesktop: 5);

  /// サイドナビゲーションを表示するかどうか
  ///
  /// タブレット以上でtrueを返します
  static bool shouldShowSideNavigation(BuildContext context) => !isMobile(context);

  /// ボトムナビゲーションを表示するかどうか
  ///
  /// モバイルでtrueを返します
  static bool shouldShowBottomNavigation(BuildContext context) => isMobile(context);

  /// パディング値を取得
  ///
  /// デバイスサイズに応じて適切なパディングを返します
  static EdgeInsets getResponsivePadding(BuildContext context) => EdgeInsets.all(
      getResponsiveValue(context, mobile: 16.0, tablet: 24.0, desktop: 32.0, largeDesktop: 40.0),
    );

  /// マージン値を取得
  ///
  /// デバイスサイズに応じて適切なマージンを返します
  static EdgeInsets getResponsiveMargin(BuildContext context) => EdgeInsets.all(
      getResponsiveValue(context, mobile: 8.0, tablet: 12.0, desktop: 16.0, largeDesktop: 20.0),
    );
}
