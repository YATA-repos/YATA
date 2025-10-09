import "package:flutter_test/flutter_test.dart";

import "package:yata/core/constants/windows_scale_settings.dart";

void main() {
  group("WindowsScaleSettings", () {
    test("returns identity when disabled", () {
      const WindowsScaleSettings settings = WindowsScaleSettings(enabled: false);

      final WindowsScaleResolution result = settings.resolve(1.5);

      expect(result.scaleFactor, equals(1.0));
      expect(result.shouldTransform, isFalse);
    });

    test("clamps scale factor within configured bounds", () {
      const WindowsScaleSettings settings = WindowsScaleSettings(
        minimumScaleFactor: 0.7,
        maximumScaleFactor: 0.95,
      );

      final WindowsScaleResolution result = settings.resolve(1.6);

      expect(result.scaleFactor, closeTo(0.7, 0.0001));
      expect(result.targetDevicePixelRatio, closeTo(1.0, 0.0001));
      expect(result.logicalSizeMultiplier, closeTo(1 / 0.7, 0.0001));
      expect(result.textScaleMultiplier, closeTo(0.7, 0.0001));
      expect(result.shouldTransform, isTrue);
    });

    test("respects override scale factor", () {
      const WindowsScaleSettings settings = WindowsScaleSettings(
        minimumScaleFactor: 0.6,
        maximumScaleFactor: 0.9,
        overrideScaleFactor: 0.8,
      );

      final WindowsScaleResolution result = settings.resolve(1.25);

      expect(result.scaleFactor, closeTo(0.8, 0.0001));
      expect(result.targetDevicePixelRatio, closeTo(1.0, 0.0001));
    });

    test("returns identity when actual devicePixelRatio is invalid", () {
      const WindowsScaleSettings settings = WindowsScaleSettings();

      final WindowsScaleResolution zeroResult = settings.resolve(0);
      final WindowsScaleResolution negativeResult = settings.resolve(-1.0);
      final WindowsScaleResolution nanResult = settings.resolve(double.nan);

      expect(zeroResult.shouldTransform, isFalse);
      expect(negativeResult.shouldTransform, isFalse);
      expect(nanResult.shouldTransform, isFalse);
    });
  });
}
