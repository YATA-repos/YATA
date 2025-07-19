import "package:flutter/material.dart";

class AppLayout {
  AppLayout._();

  static const double spacing2Xs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 20.0;
  static const double spacing = 32.0;
  static const double spacingMd = 40.0;
  static const double spacingLg = 48.0;
  static const double spacingXl = 56.0;
  static const double spacing2Xl = 64.0;

  static const EdgeInsets padding2Xs = EdgeInsets.all(spacing2Xs);
  static const EdgeInsets paddingXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets paddingSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets padding = EdgeInsets.all(spacing);
  static const EdgeInsets paddingMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets paddingLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets paddingXl = EdgeInsets.all(spacingXl);
  static const EdgeInsets padding2Xl = EdgeInsets.all(spacing2Xl);
  static const EdgeInsets paddingHorizontalXs = EdgeInsets.symmetric(horizontal: spacingXs);
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: spacingSm);
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: spacing);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: spacingMd);
  static const EdgeInsets paddingVerticalXs = EdgeInsets.symmetric(vertical: spacingXs);
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: spacingSm);
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: spacing);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: spacingMd);

  static const BorderRadius radius2Xs = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radius = BorderRadius.all(Radius.circular(32));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(40));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(48));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(56));
  static const BorderRadius radius2Xl = BorderRadius.all(Radius.circular(64));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(9999));

  static const double elevation2Xs = 1.0;
  static const double elevationXs = 2.0;
  static const double elevationSm = 4.0;
  static const double elevation = 8.0;
  static const double elevationMd = 10.0;
  static const double elevationLg = 12.0;
  static const double elevationXl = 14.0;
  static const double elevation2Xl = 16.0;

  static const double buttonHeight2Xs = 24.0;
  static const double buttonHeightXs = 28.0;
  static const double buttonHeightSm = 32.0;
  static const double buttonHeight = 40.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 52.0;
  static const double buttonHeight2Xl = 56.0;
  
  static const double appBarHeightSm = 48.0;
  static const double appBarHeight = 56.0;
  static const double appBarHeightLg = 64.0;

  static const double iconButtonSizeSm = 32.0;
  static const double iconButtonSize = 40.0;
  static const double iconButtonSizeMd = 44.0;
  static const double iconButtonSizeLg = 48.0;
  
  static const double inputHeightSm = 40.0;
  static const double inputHeight = 48.0;
  static const double inputHeightLg = 56.0;

  static const double iconSize2Xs = 4.0;
  static const double iconSizeXs = 8.0;
  static const double iconSizeSm = 20.0;
  static const double iconSize = 32.0;
  static const double iconSizeMd = 40.0;
  static const double iconSizeLg = 48.0;
  static const double iconSizeXl = 56.0;
  static const double iconSize2Xl = 64.0;

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
      return paddingSm;
    } else if (screenWidth < breakpointTablet) {
      return paddingMd;
    } else {
      return padding;
    }
  }

  static bool isMobile(double screenWidth) => screenWidth < breakpointMobile;
  static bool isTablet(double screenWidth) =>
      screenWidth >= breakpointMobile && screenWidth < breakpointDesktop;
  static bool isDesktop(double screenWidth) => screenWidth >= breakpointDesktop;
}
