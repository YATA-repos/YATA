import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../core/constants/constants.dart";
import "../shared/themes/app_theme.dart";
import "router/app_router.dart";

/// YATAアプリケーションのメインクラス
class YataApp extends ConsumerWidget {
  const YataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: AppStrings.titleApp,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.light,
    routerConfig: AppRouter.getRouter(ref),
    debugShowCheckedModeBanner: false,
    builder: (BuildContext context, Widget? child) {
      final Widget resolvedChild = child ?? const SizedBox.shrink();

      if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
        return resolvedChild;
      }

      final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) {
        return resolvedChild;
      }

      final WindowsScaleSettings settings = WindowsScaleSettings.fromEnvironment();
      final WindowsScaleResolution resolution = settings.resolve(mediaQuery.devicePixelRatio);
      if (!resolution.shouldTransform) {
        return resolvedChild;
      }

      return _buildWindowsScaledChild(
        child: resolvedChild,
        mediaQuery: mediaQuery,
        resolution: resolution,
      );
    },
  );
}

Widget _buildWindowsScaledChild({
  required Widget child,
  required MediaQueryData mediaQuery,
  required WindowsScaleResolution resolution,
}) {
  MediaQueryData buildScaledMediaQuery(MediaQueryData data) {
    EdgeInsets scaleEdgeInsets(EdgeInsets value, double multiplier) => EdgeInsets.only(
      left: value.left * multiplier,
      top: value.top * multiplier,
      right: value.right * multiplier,
      bottom: value.bottom * multiplier,
    );

    final double sizeMultiplier = resolution.logicalSizeMultiplier;

    return data.copyWith(
      size: Size(
        data.size.width * sizeMultiplier,
        data.size.height * sizeMultiplier,
      ),
      devicePixelRatio: resolution.targetDevicePixelRatio,
      padding: scaleEdgeInsets(data.padding, sizeMultiplier),
      viewInsets: scaleEdgeInsets(data.viewInsets, sizeMultiplier),
      viewPadding: scaleEdgeInsets(data.viewPadding, sizeMultiplier),
      systemGestureInsets: scaleEdgeInsets(data.systemGestureInsets, sizeMultiplier),
      textScaler: data.textScaler,
    );
  }

  return MediaQuery(
    data: buildScaledMediaQuery(mediaQuery),
    child: Transform.scale(
      scale: resolution.scaleFactor,
      alignment: Alignment.topLeft,
      child: child,
    ),
  );
}
