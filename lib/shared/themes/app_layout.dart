import "package:flutter/material.dart";

/// YATAアプリケーションのレイアウト定数
///
/// UIシステムデータガイドに基づいて定義されたレイアウトシステム
class AppLayout {
  AppLayout._();

  // ==========================================================================
  // Spacing (スペーシング) - 4px基準
  // ==========================================================================

  /// 4px
  static const double spacing1 = 4.0;

  /// 8px
  static const double spacing2 = 8.0;

  /// 12px
  static const double spacing3 = 12.0;

  /// 16px
  static const double spacing4 = 16.0;

  /// 20px
  static const double spacing5 = 20.0;

  /// 24px
  static const double spacing6 = 24.0;

  /// 32px
  static const double spacing8 = 32.0;

  /// 40px
  static const double spacing10 = 40.0;

  /// 48px
  static const double spacing12 = 48.0;

  /// 64px
  static const double spacing16 = 64.0;

  // ==========================================================================
  // Padding (パディング)
  // ==========================================================================

  /// 4px パディング
  static const EdgeInsets padding1 = EdgeInsets.all(spacing1);

  /// 8px パディング
  static const EdgeInsets padding2 = EdgeInsets.all(spacing2);

  /// 12px パディング
  static const EdgeInsets padding3 = EdgeInsets.all(spacing3);

  /// 16px パディング
  static const EdgeInsets padding4 = EdgeInsets.all(spacing4);

  /// 20px パディング
  static const EdgeInsets padding5 = EdgeInsets.all(spacing5);

  /// 24px パディング
  static const EdgeInsets padding6 = EdgeInsets.all(spacing6);

  /// 32px パディング
  static const EdgeInsets padding8 = EdgeInsets.all(spacing8);

  /// 水平方向 8px パディング
  static const EdgeInsets paddingHorizontal2 = EdgeInsets.symmetric(horizontal: spacing2);

  /// 水平方向 16px パディング
  static const EdgeInsets paddingHorizontal4 = EdgeInsets.symmetric(horizontal: spacing4);

  /// 水平方向 24px パディング
  static const EdgeInsets paddingHorizontal6 = EdgeInsets.symmetric(horizontal: spacing6);

  /// 垂直方向 8px パディング
  static const EdgeInsets paddingVertical2 = EdgeInsets.symmetric(vertical: spacing2);

  /// 垂直方向 16px パディング
  static const EdgeInsets paddingVertical4 = EdgeInsets.symmetric(vertical: spacing4);

  /// 垂直方向 24px パディング
  static const EdgeInsets paddingVertical6 = EdgeInsets.symmetric(vertical: spacing6);

  // ==========================================================================
  // Border Radius (境界線の丸み)
  // ==========================================================================

  /// 2px 丸み
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(2));

  /// 4px 丸み
  static const BorderRadius radius = BorderRadius.all(Radius.circular(4));

  /// 6px 丸み
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(6));

  /// 8px 丸み
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(8));

  /// 12px 丸み
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(12));

  /// 16px 丸み
  static const BorderRadius radius2xl = BorderRadius.all(Radius.circular(16));

  /// 完全な円形
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(9999));

  // ==========================================================================
  // Elevation (影の高さ)
  // ==========================================================================

  /// 軽い影
  static const double elevationSm = 1.0;

  /// 標準の影
  static const double elevation = 2.0;

  /// 中程度の影
  static const double elevationMd = 4.0;

  /// 強い影
  static const double elevationLg = 8.0;

  /// 非常に強い影
  static const double elevationXl = 12.0;

  // ==========================================================================
  // Component Sizes (コンポーネントサイズ)
  // ==========================================================================

  /// 小ボタンの高さ
  static const double buttonHeightSm = 36.0;

  /// 標準ボタンの高さ
  static const double buttonHeight = 40.0;

  /// 大ボタンの高さ
  static const double buttonHeightLg = 44.0;

  /// アイコンボタンのサイズ
  static const double iconButtonSize = 40.0;

  /// 小アイコンボタンのサイズ
  static const double iconButtonSizeSm = 32.0;

  /// 大アイコンボタンのサイズ
  static const double iconButtonSizeLg = 48.0;

  /// 入力フィールドの高さ
  static const double inputHeight = 48.0;

  /// 小入力フィールドの高さ
  static const double inputHeightSm = 40.0;

  /// 大入力フィールドの高さ
  static const double inputHeightLg = 56.0;

  // ==========================================================================
  // Icon Sizes (アイコンサイズ)
  // ==========================================================================

  /// 小アイコン
  static const double iconSizeSm = 16.0;

  /// 標準アイコン
  static const double iconSize = 20.0;

  /// 中アイコン
  static const double iconSizeMd = 24.0;

  /// 大アイコン
  static const double iconSizeLg = 32.0;

  /// 特大アイコン
  static const double iconSizeXl = 40.0;

  // ==========================================================================
  // Grid System (グリッドシステム)
  // ==========================================================================

  /// モバイル用グリッド（1カラム）
  static const int gridMobile = 1;

  /// タブレット用グリッド（2カラム）
  static const int gridTablet = 2;

  /// デスクトップ用グリッド（3カラム）
  static const int gridDesktop = 3;

  /// ワイド用グリッド（4カラム）
  static const int gridWide = 4;

  /// 統計カード用グリッド（4カラム）
  static const int gridStats = 4;

  // ==========================================================================
  // Breakpoints (ブレークポイント)
  // ==========================================================================

  /// モバイル端末の最大幅
  static const double breakpointMobile = 640.0;

  /// タブレット端末の最大幅
  static const double breakpointTablet = 768.0;

  /// デスクトップ端末の最大幅
  static const double breakpointDesktop = 1024.0;

  /// ワイド端末の最大幅
  static const double breakpointWide = 1280.0;

  // ==========================================================================
  // Container Sizes (コンテナサイズ)
  // ==========================================================================

  /// 小コンテナ幅
  static const double containerSm = 640.0;

  /// 中コンテナ幅
  static const double containerMd = 768.0;

  /// 大コンテナ幅
  static const double containerLg = 1024.0;

  /// 特大コンテナ幅
  static const double containerXl = 1280.0;

  /// 最大コンテナ幅
  static const double containerMax = 1536.0;

  // ==========================================================================
  // App Bar & Navigation (アプリバーとナビゲーション)
  // ==========================================================================

  /// アプリバーの高さ
  static const double appBarHeight = 56.0;

  /// ボトムナビゲーションの高さ
  static const double bottomNavigationHeight = 60.0;

  /// タブバーの高さ
  static const double tabBarHeight = 48.0;

  /// フローティングアクションボタンのサイズ
  static const double fabSize = 56.0;

  /// 小フローティングアクションボタンのサイズ
  static const double fabSizeSm = 40.0;

  // ==========================================================================
  // List & Card (リストとカード)
  // ==========================================================================

  /// リストタイルの最小高さ
  static const double listTileMinHeight = 56.0;

  /// カードの最小高さ
  static const double cardMinHeight = 80.0;

  /// 統計カードの高さ
  static const double statsCardHeight = 120.0;

  /// メニューカードの高さ
  static const double menuCardHeight = 160.0;

  // ==========================================================================
  // Utility Methods (ユーティリティメソッド)
  // ==========================================================================

  /// 現在の画面サイズに基づいてグリッドカラム数を取得
  static int getGridColumns(double screenWidth) {
    if (screenWidth < breakpointMobile) {
      return gridMobile;
    } else if (screenWidth < breakpointTablet) {
      return gridTablet;
    } else if (screenWidth < breakpointDesktop) {
      return gridDesktop;
    } else {
      return gridWide;
    }
  }

  /// 現在の画面サイズに基づいてコンテナ幅を取得
  static double getContainerWidth(double screenWidth) {
    if (screenWidth < breakpointMobile) {
      return screenWidth;
    } else if (screenWidth < breakpointTablet) {
      return containerSm;
    } else if (screenWidth < breakpointDesktop) {
      return containerMd;
    } else if (screenWidth < breakpointWide) {
      return containerLg;
    } else {
      return containerXl;
    }
  }

  /// レスポンシブパディングを取得
  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (screenWidth < breakpointMobile) {
      return padding4;
    } else if (screenWidth < breakpointTablet) {
      return padding6;
    } else {
      return padding8;
    }
  }

  /// デバイスタイプを判定
  static bool isMobile(double screenWidth) => screenWidth < breakpointMobile;
  static bool isTablet(double screenWidth) =>
      screenWidth >= breakpointMobile && screenWidth < breakpointDesktop;
  static bool isDesktop(double screenWidth) => screenWidth >= breakpointDesktop;
}
