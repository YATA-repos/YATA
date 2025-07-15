import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../providers/device_info_provider.dart";
import "../widgets/navigation_rail.dart";

part "adaptive_layout.g.dart";

/// デバイスタイプを表す列挙型
enum DeviceType { phone, tablet, desktop }

/// 画面サイズに応じたレスポンシブレイアウトを提供するウィジェット
///
/// デバイスタイプとオリエンテーションに基づいて、
/// 適切なレイアウト（ボトムナビ、サイドナビなど）を選択します。
class AdaptiveLayout extends ConsumerWidget {
  const AdaptiveLayout({required this.child, super.key});

  /// レイアウト内に表示するメインコンテンツ
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceType deviceType = ref.watch(deviceTypeProvider);
    final Orientation orientation = MediaQuery.of(context).orientation;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => _buildLayout(
        context: context,
        deviceType: deviceType,
        orientation: orientation,
        constraints: constraints,
        child: child,
      ),
    );
  }

  /// デバイスタイプに応じたレイアウトを構築
  Widget _buildLayout({
    required BuildContext context,
    required DeviceType deviceType,
    required Orientation orientation,
    required BoxConstraints constraints,
    required Widget child,
  }) {
    switch (deviceType) {
      case DeviceType.phone:
        return _buildPhoneLayout(child);

      case DeviceType.tablet:
        return _buildTabletLayout(child: child, orientation: orientation, constraints: constraints);

      case DeviceType.desktop:
        return _buildDesktopLayout(child, constraints);
    }
  }

  /// スマートフォン用レイアウト
  ///
  /// 常にボトムナビゲーションを使用
  Widget _buildPhoneLayout(Widget child) => child;

  /// タブレット用レイアウト
  ///
  /// 横向きの場合はサイドナビゲーション、縦向きの場合はボトムナビゲーション
  Widget _buildTabletLayout({
    required Widget child,
    required Orientation orientation,
    required BoxConstraints constraints,
  }) {
    // 横向きかつ十分な幅がある場合はサイドナビゲーション
    if (orientation == Orientation.landscape && constraints.maxWidth >= 700) {
      return Row(
        children: <Widget>[
          const AppNavigationRail(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      );
    }

    // その他の場合はボトムナビゲーション
    return child;
  }

  /// デスクトップ用レイアウト
  ///
  /// 常にサイドナビゲーションを使用
  Widget _buildDesktopLayout(Widget child, BoxConstraints constraints) => Row(
    children: <Widget>[
      const AppNavigationRail(),
      const VerticalDivider(thickness: 1, width: 1),
      Expanded(child: child),
    ],
  );
}

/// レスポンシブ設計のためのブレークポイント定数
class BreakPoints {
  BreakPoints._();

  /// スマートフォンの最大幅
  static const double phone = 600;

  /// タブレットの最大幅
  static const double tablet = 1024;

  /// デスクトップの最小幅
  static const double desktop = 1025;

  /// コンパクトレイアウトの境界
  static const double compact = 600;

  /// ミディアムレイアウトの境界
  static const double medium = 840;

  /// エキスパンドレイアウトの境界
  static const double expanded = 1200;
}

/// 画面サイズに基づくレイアウト情報
class LayoutInfo {
  const LayoutInfo({
    required this.deviceType,
    required this.isCompact,
    required this.isMedium,
    required this.isExpanded,
    required this.columns,
  });

  /// デバイスタイプ
  final DeviceType deviceType;

  /// コンパクトレイアウトかどうか
  final bool isCompact;

  /// ミディアムレイアウトかどうか
  final bool isMedium;

  /// エキスパンドレイアウトかどうか
  final bool isExpanded;

  /// グリッドのカラム数
  final int columns;
}

/// レイアウト情報を計算するProvider
@riverpod
LayoutInfo layoutInfo(Ref ref) {
  final DeviceType deviceType = ref.watch(deviceTypeProvider);
  final Size screenSize = ref.watch(screenSizeProvider);

  final double width = screenSize.width;

  return LayoutInfo(
    deviceType: deviceType,
    isCompact: width < BreakPoints.compact,
    isMedium: width >= BreakPoints.compact && width < BreakPoints.medium,
    isExpanded: width >= BreakPoints.expanded,
    columns: _calculateColumns(width),
  );
}

/// 画面幅に基づいてグリッドのカラム数を計算
int _calculateColumns(double width) {
  if (width < BreakPoints.compact) {
    return 1; // スマートフォン: 1カラム
  } else if (width < BreakPoints.medium) {
    return 2; // タブレット縦: 2カラム
  } else if (width < BreakPoints.expanded) {
    return 3; // タブレット横: 3カラム
  } else {
    return 4; // デスクトップ: 4カラム
  }
}

/// レスポンシブな余白を提供するウィジェット
class ResponsivePadding extends ConsumerWidget {
  const ResponsivePadding({
    required this.child,
    this.compact = const EdgeInsets.all(16),
    this.medium = const EdgeInsets.all(24),
    this.expanded = const EdgeInsets.all(32),
    super.key,
  });

  final Widget child;
  final EdgeInsets compact;
  final EdgeInsets medium;
  final EdgeInsets expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LayoutInfo layoutInfo = ref.watch(layoutInfoProvider);

    EdgeInsets padding;
    if (layoutInfo.isCompact) {
      padding = compact;
    } else if (layoutInfo.isMedium) {
      padding = medium;
    } else {
      padding = expanded;
    }

    return Padding(padding: padding, child: child);
  }
}

/// レスポンシブなコンテナ幅を提供するウィジェット
class ResponsiveContainer extends ConsumerWidget {
  const ResponsiveContainer({required this.child, this.maxWidth = 1200, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
