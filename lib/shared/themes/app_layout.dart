import "package:flutter/material.dart";

class AppLayout {
  AppLayout._();
  // `v`=vertical, `h`=horizontal

  static const SizedBox vSpacerTiny = SizedBox(height: 4.0);
  static const SizedBox vSpacerSmall = SizedBox(height: 8.0);
  static const SizedBox vSpacerDefault = SizedBox(height: 16.0);
  static const SizedBox vSpacerMedium = SizedBox(height: 24.0);
  static const SizedBox vSpacerLarge = SizedBox(height: 32.0);
  static const SizedBox vSpacerHuge = SizedBox(height: 64.0);

  static const SizedBox hSpacerTiny = SizedBox(width: 4.0);
  static const SizedBox hSpacerSmall = SizedBox(width: 8.0);
  static const SizedBox hSpacerDefault = SizedBox(width: 16.0);
  static const SizedBox hSpacerMedium = SizedBox(width: 24.0);
  static const SizedBox hSpacerLarge = SizedBox(width: 32.0);
  static const SizedBox hSpacerHuge = SizedBox(width: 64.0);

  static const EdgeInsets paddingTiny = EdgeInsets.all(4.0);
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);
  static const EdgeInsets paddingDefault = EdgeInsets.all(16.0);
  static const EdgeInsets paddingMedium = EdgeInsets.all(24.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(32.0);
  static const EdgeInsets paddingHuge = EdgeInsets.all(64.0);

  static const EdgeInsets marginTiny = paddingTiny;
  static const EdgeInsets marginSmall = paddingSmall;
  static const EdgeInsets marginDefault = paddingDefault;
  static const EdgeInsets marginMedium = paddingMedium;
  static const EdgeInsets marginLarge = paddingLarge;
  static const EdgeInsets marginHuge = paddingHuge;

  static const EdgeInsets hBigPaddingTiny = EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0);
  static const EdgeInsets hBigPaddingSmall = EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);
  static const EdgeInsets hBigPaddingDefault = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );
  static const EdgeInsets hBigPaddingMedium = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 12.0,
  );
  static const EdgeInsets hBigPaddingLarge = EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
  static const EdgeInsets hBigPaddingHuge = EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0);

  static const EdgeInsets hBigMarginTiny = hBigPaddingTiny;
  static const EdgeInsets hBigMarginSmall = hBigPaddingSmall;
  static const EdgeInsets hBigMarginDefault = hBigPaddingDefault;
  static const EdgeInsets hBigMarginMedium = hBigPaddingMedium;
  static const EdgeInsets hBigMarginLarge = hBigPaddingLarge;
  static const EdgeInsets hBigMarginHuge = hBigPaddingHuge;

  static const EdgeInsets vBigPaddingTiny = EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0);
  static const EdgeInsets vBigPaddingSmall = EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0);
  static const EdgeInsets vBigPaddingDefault = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 16.0,
  );
  static const EdgeInsets vBigPaddingMedium = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 24.0,
  );
  static const EdgeInsets vBigPaddingLarge = EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0);
  static const EdgeInsets vBigPaddingHuge = EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0);

  static const EdgeInsets vBigMarginTiny = vBigPaddingTiny;
  static const EdgeInsets vBigMarginSmall = vBigPaddingSmall;
  static const EdgeInsets vBigMarginDefault = vBigPaddingDefault;
  static const EdgeInsets vBigMarginMedium = vBigPaddingMedium;
  static const EdgeInsets vBigMarginLarge = vBigPaddingLarge;
  static const EdgeInsets vBigMarginHuge = vBigPaddingHuge;

  static const BorderRadius borderRadiusTiny = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(6.0));
  static const BorderRadius borderRadiusDefault = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(20.0));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(28.0));
  static const BorderRadius borderRadiusHuge = BorderRadius.all(Radius.circular(40.0));

  static const double widthTiny = 4.0;
  static const double widthSmall = 8.0;
  static const double widthDefault = 16.0;
  static const double widthMedium = 24.0;
  static const double widthLarge = 32.0;
  static const double widthHuge = 64.0;

  static const double heightTiny = 4.0;
  static const double heightSmall = 8.0;
  static const double heightDefault = 16.0;
  static const double heightMedium = 24.0;
  static const double heightLarge = 32.0;
  static const double heightHuge = 64.0;

  static const int gridMobile = 1;
  static const int gridTablet = 2;
  static const int gridDesktop = 3;
  static const int gridWide = 4;
  static const int gridStats = 4;

  static const double breakpointMobile = 640.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;
  static const double breakpointWide = 1280.0;
}
