import "package:flutter/material.dart";

class AppLayout {
  AppLayout._();

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  static const EdgeInsets padding4 = EdgeInsets.all(spacing4);
  static const EdgeInsets padding8 = EdgeInsets.all(spacing8);
  static const EdgeInsets padding12 = EdgeInsets.all(spacing12);
  static const EdgeInsets padding16 = EdgeInsets.all(spacing16);
  static const EdgeInsets padding20 = EdgeInsets.all(spacing20);
  static const EdgeInsets padding24 = EdgeInsets.all(spacing24);
  static const EdgeInsets padding32 = EdgeInsets.all(spacing32);
  static const EdgeInsets paddingHorizontal8 = EdgeInsets.symmetric(horizontal: spacing8);
  static const EdgeInsets paddingHorizontal16 = EdgeInsets.symmetric(horizontal: spacing16);
  static const EdgeInsets paddingHorizontal24 = EdgeInsets.symmetric(horizontal: spacing24);
  static const EdgeInsets paddingVertical8 = EdgeInsets.symmetric(vertical: spacing8);
  static const EdgeInsets paddingVertical16 = EdgeInsets.symmetric(vertical: spacing16);
  static const EdgeInsets paddingVertical24 = EdgeInsets.symmetric(vertical: spacing24);

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(2));
  static const BorderRadius radius = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(6));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radius2xl = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(9999));

  static const double elevationSm = 1.0;
  static const double elevation = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;

  static const double buttonHeightSm = 36.0;
  static const double buttonHeight = 40.0;
  static const double buttonHeightLg = 44.0;
  static const double iconButtonSize = 40.0;
  static const double iconButtonSizeSm = 32.0;
  static const double iconButtonSizeLg = 48.0;
  static const double inputHeight = 48.0;
  static const double inputHeightSm = 40.0;
  static const double inputHeightLg = 56.0;

  static const double iconSizeSm = 16.0;
  static const double iconSize = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 40.0;

  static const int gridMobile = 1;
  static const int gridTablet = 2;
  static const int gridDesktop = 3;
  static const int gridWide = 4;
  static const int gridStats = 4;

  static const double breakpointMobile = 640.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;
  static const double breakpointWide = 1280.0;

  static const double containerSm = 640.0;
  static const double containerMd = 768.0;
  static const double containerLg = 1024.0;
  static const double containerXl = 1280.0;
  static const double containerMax = 1536.0;

  static const double appBarHeight = 56.0;
  static const double bottomNavigationHeight = 60.0;
  static const double tabBarHeight = 48.0;
  static const double fabSize = 56.0;
  static const double fabSizeSm = 40.0;

  static const double listTileMinHeight = 56.0;
  static const double cardMinHeight = 80.0;
  static const double statsCardHeight = 120.0;
  static const double menuCardHeight = 160.0;

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

  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (screenWidth < breakpointMobile) {
      return padding16;
    } else if (screenWidth < breakpointTablet) {
      return padding24;
    } else {
      return padding32;
    }
  }

  static bool isMobile(double screenWidth) => screenWidth < breakpointMobile;
  static bool isTablet(double screenWidth) =>
      screenWidth >= breakpointMobile && screenWidth < breakpointDesktop;
  static bool isDesktop(double screenWidth) => screenWidth >= breakpointDesktop;
}
