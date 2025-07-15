import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../layouts/adaptive_layout.dart";

part "device_info_provider.g.dart";

/// デバイスタイプを判定するProvider
@riverpod
DeviceType deviceType(Ref ref) {
  final Size screenSize = ref.watch(screenSizeProvider);
  final double width = screenSize.width;

  if (width < BreakPoints.phone) {
    return DeviceType.phone;
  } else if (width < BreakPoints.tablet) {
    return DeviceType.tablet;
  } else {
    return DeviceType.desktop;
  }
}

/// 画面サイズを監視するProvider
// ! FIXME
// 実際の実装では MediaQuery.of(context).size を使用
// ここでは初期値として設定
@riverpod
Size screenSize(Ref ref) => const Size(390, 844);

/// デバイスの向きを監視するProvider
@riverpod
Orientation deviceOrientation(Ref ref) {
  final Size screenSize = ref.watch(screenSizeProvider);
  return screenSize.width > screenSize.height ? Orientation.landscape : Orientation.portrait;
}

/// デバイスがタブレットかどうかを判定するProvider
@riverpod
bool isTablet(Ref ref) {
  final DeviceType deviceType = ref.watch(deviceTypeProvider);
  return deviceType == DeviceType.tablet;
}

/// デバイスがデスクトップかどうかを判定するProvider
@riverpod
bool isDesktop(Ref ref) {
  final DeviceType deviceType = ref.watch(deviceTypeProvider);
  return deviceType == DeviceType.desktop;
}

/// デバイスがモバイル（スマートフォン）かどうかを判定するProvider
@riverpod
bool isMobile(Ref ref) {
  final DeviceType deviceType = ref.watch(deviceTypeProvider);
  return deviceType == DeviceType.phone;
}

/// サイドナビゲーションを使用すべきかどうかを判定するProvider
@riverpod
bool shouldUseSideNavigation(Ref ref) {
  final DeviceType deviceType = ref.watch(deviceTypeProvider);
  final Orientation orientation = ref.watch(deviceOrientationProvider);

  // デスクトップでは常にサイドナビゲーション
  if (deviceType == DeviceType.desktop) {
    return true;
  }

  // タブレットの横向きでサイドナビゲーション
  if (deviceType == DeviceType.tablet && orientation == Orientation.landscape) {
    return true;
  }

  return false;
}

/// デバイス情報を包括的に提供するProvider
@riverpod
DeviceInfo deviceInfo(Ref ref) {
  final DeviceType deviceType = ref.watch(deviceTypeProvider);
  final Size screenSize = ref.watch(screenSizeProvider);
  final Orientation orientation = ref.watch(deviceOrientationProvider);
  final bool shouldUseSideNav = ref.watch(shouldUseSideNavigationProvider);

  return DeviceInfo(
    type: deviceType,
    size: screenSize,
    orientation: orientation,
    shouldUseSideNavigation: shouldUseSideNav,
    isCompact: screenSize.width < BreakPoints.compact,
    isMedium: screenSize.width >= BreakPoints.compact && screenSize.width < BreakPoints.medium,
    isExpanded: screenSize.width >= BreakPoints.expanded,
  );
}

/// デバイス情報を格納するデータクラス
class DeviceInfo {
  const DeviceInfo({
    required this.type,
    required this.size,
    required this.orientation,
    required this.shouldUseSideNavigation,
    required this.isCompact,
    required this.isMedium,
    required this.isExpanded,
  });

  /// デバイスタイプ
  final DeviceType type;

  /// 画面サイズ
  final Size size;

  /// デバイスの向き
  final Orientation orientation;

  /// サイドナビゲーションを使用すべきかどうか
  final bool shouldUseSideNavigation;

  /// コンパクトレイアウトかどうか
  final bool isCompact;

  /// ミディアムレイアウトかどうか
  final bool isMedium;

  /// エキスパンドレイアウトかどうか
  final bool isExpanded;

  /// デバイスがモバイルかどうか
  bool get isMobile => type == DeviceType.phone;

  /// デバイスがタブレットかどうか
  bool get isTablet => type == DeviceType.tablet;

  /// デバイスがデスクトップかどうか
  bool get isDesktop => type == DeviceType.desktop;

  /// 画面幅
  double get width => size.width;

  /// 画面高さ
  double get height => size.height;

  /// アスペクト比
  double get aspectRatio => size.aspectRatio;

  /// 横向きかどうか
  bool get isLandscape => orientation == Orientation.landscape;

  /// 縦向きかどうか
  bool get isPortrait => orientation == Orientation.portrait;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfo &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          size == other.size &&
          orientation == other.orientation &&
          shouldUseSideNavigation == other.shouldUseSideNavigation &&
          isCompact == other.isCompact &&
          isMedium == other.isMedium &&
          isExpanded == other.isExpanded;

  @override
  int get hashCode =>
      type.hashCode ^
      size.hashCode ^
      orientation.hashCode ^
      shouldUseSideNavigation.hashCode ^
      isCompact.hashCode ^
      isMedium.hashCode ^
      isExpanded.hashCode;

  @override
  String toString() =>
      "DeviceInfo{"
      "type: $type, "
      "size: $size, "
      "orientation: $orientation, "
      "shouldUseSideNavigation: $shouldUseSideNavigation, "
      "isCompact: $isCompact, "
      "isMedium: $isMedium, "
      "isExpanded: $isExpanded"
      "}";
}
