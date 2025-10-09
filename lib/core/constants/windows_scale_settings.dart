import "dart:math" as math;

/// Windows版でのUIスケーリングを制御する設定値。
class WindowsScaleSettings {
  const WindowsScaleSettings({
    this.enabled = true,
    this.desiredDevicePixelRatio = 1.0,
    this.minimumScaleFactor = 0.75,
    this.maximumScaleFactor = 1.0,
    this.overrideScaleFactor,
  })  : assert(desiredDevicePixelRatio > 0, "desiredDevicePixelRatio must be positive"),
        assert(minimumScaleFactor > 0, "minimumScaleFactor must be positive"),
        assert(maximumScaleFactor >= minimumScaleFactor, "maximumScaleFactor must be >= minimumScaleFactor"),
        assert(overrideScaleFactor == null || overrideScaleFactor > 0, "overrideScaleFactor must be positive when provided");

  /// `--dart-define`または環境変数で指定された値から設定を初期化する。
  factory WindowsScaleSettings.fromEnvironment() {
    // ignore: do_not_use_environment
    final bool enabled = bool.fromEnvironment(_enabledKey, defaultValue: true);

    double parsePositiveDouble(String value, double defaultValue) {
      final double? parsed = double.tryParse(value.trim());
      return parsed != null && parsed.isFinite && parsed > 0 ? parsed : defaultValue;
    }

    double? parseOptionalPositiveDouble(String value) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final double? parsed = double.tryParse(trimmed);
      return parsed != null && parsed.isFinite && parsed > 0 ? parsed : null;
    }

    // ignore: do_not_use_environment
    const String targetDprRaw = String.fromEnvironment(_targetDevicePixelRatioKey, defaultValue: "1.0");
    // ignore: do_not_use_environment
    const String minScaleRaw = String.fromEnvironment(_minScaleFactorKey, defaultValue: "0.75");
    // ignore: do_not_use_environment
    const String maxScaleRaw = String.fromEnvironment(_maxScaleFactorKey, defaultValue: "1.0");
  // ignore: do_not_use_environment
  const String overrideRaw = String.fromEnvironment(_overrideScaleFactorKey);

    final double targetDpr = parsePositiveDouble(targetDprRaw, 1.0);
    final double minScale = parsePositiveDouble(minScaleRaw, 0.75);
    final double maxScale = parsePositiveDouble(maxScaleRaw, 1.0);
    final double constrainedMin = math.max(0.1, math.min(minScale, maxScale));
    final double constrainedMax = math.max(constrainedMin, maxScale);

    return WindowsScaleSettings(
      enabled: enabled,
      desiredDevicePixelRatio: targetDpr,
      minimumScaleFactor: constrainedMin,
      maximumScaleFactor: constrainedMax,
      overrideScaleFactor: parseOptionalPositiveDouble(overrideRaw),
    );
  }

  static const String _enabledKey = "YATA_WINDOWS_SCALE_ENABLED";
  static const String _targetDevicePixelRatioKey = "YATA_WINDOWS_TARGET_DPR";
  static const String _overrideScaleFactorKey = "YATA_WINDOWS_SCALE_FACTOR";
  static const String _minScaleFactorKey = "YATA_WINDOWS_MIN_SCALE";
  static const String _maxScaleFactorKey = "YATA_WINDOWS_MAX_SCALE";
  static const double _epsilon = 0.001;

  final bool enabled;
  final double desiredDevicePixelRatio;
  final double minimumScaleFactor;
  final double maximumScaleFactor;
  final double? overrideScaleFactor;

  bool get hasOverrideScaleFactor => overrideScaleFactor != null;

  WindowsScaleResolution resolve(double actualDevicePixelRatio) {
    if (!enabled || !(actualDevicePixelRatio.isFinite && actualDevicePixelRatio > 0)) {
      return WindowsScaleResolution.identity;
    }

    final double rawScaleFactor = hasOverrideScaleFactor
      ? overrideScaleFactor!
      : desiredDevicePixelRatio / actualDevicePixelRatio;

    if (!(rawScaleFactor.isFinite && rawScaleFactor > 0)) {
      return WindowsScaleResolution.identity;
    }

    final double clampedScaleFactor = math.min(
      maximumScaleFactor,
      math.max(minimumScaleFactor, rawScaleFactor),
    );

    final double targetDpr = hasOverrideScaleFactor
      ? actualDevicePixelRatio * clampedScaleFactor
      : desiredDevicePixelRatio;

    if ((clampedScaleFactor - 1.0).abs() <= _epsilon) {
      return WindowsScaleResolution.identity;
    }

    return WindowsScaleResolution(
      scaleFactor: clampedScaleFactor,
      targetDevicePixelRatio: targetDpr,
    );
  }
}

class WindowsScaleResolution {
  const WindowsScaleResolution({
    required this.scaleFactor,
    required this.targetDevicePixelRatio,
  })  : assert(scaleFactor > 0, "scaleFactor must be positive"),
        assert(targetDevicePixelRatio > 0, "targetDevicePixelRatio must be positive");

  static const WindowsScaleResolution identity = WindowsScaleResolution(
    scaleFactor: 1.0,
    targetDevicePixelRatio: 1.0,
  );

  final double scaleFactor;
  final double targetDevicePixelRatio;

  bool get shouldTransform => (scaleFactor - 1.0).abs() > WindowsScaleSettings._epsilon;

  double get logicalSizeMultiplier => 1.0 / scaleFactor;

  double get textScaleMultiplier => scaleFactor;
}
