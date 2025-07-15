import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "adaptive_layout.dart";

/// レスポンシブな余白を提供するウィジェット
///
/// デバイスサイズに応じて適切な余白を自動的に調整します。
class ResponsivePadding extends ConsumerWidget {
  const ResponsivePadding({
    required this.child,
    this.compact,
    this.medium,
    this.expanded,
    this.horizontal,
    this.vertical,
    this.top,
    this.bottom,
    this.left,
    this.right,
    super.key,
  });

  /// 子ウィジェット
  final Widget child;

  /// コンパクトレイアウト用の余白
  final EdgeInsets? compact;

  /// ミディアムレイアウト用の余白
  final EdgeInsets? medium;

  /// エキスパンドレイアウト用の余白
  final EdgeInsets? expanded;

  /// 水平方向の余白
  final double? horizontal;

  /// 垂直方向の余白
  final double? vertical;

  /// 上部の余白
  final double? top;

  /// 下部の余白
  final double? bottom;

  /// 左側の余白
  final double? left;

  /// 右側の余白
  final double? right;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LayoutInfo layoutInfo = ref.watch(layoutInfoProvider);

    final EdgeInsets padding = _calculatePadding(layoutInfo);

    return Padding(padding: padding, child: child);
  }

  /// レイアウト情報に基づいて余白を計算
  EdgeInsets _calculatePadding(LayoutInfo layoutInfo) {
    EdgeInsets basePadding;

    // デバイスタイプに基づく基本余白
    if (layoutInfo.isCompact) {
      basePadding = compact ?? const EdgeInsets.all(16);
    } else if (layoutInfo.isMedium) {
      basePadding = medium ?? const EdgeInsets.all(24);
    } else {
      basePadding = expanded ?? const EdgeInsets.all(32);
    }

    // カスタム余白が指定されている場合は上書き
    if (horizontal != null ||
        vertical != null ||
        top != null ||
        bottom != null ||
        left != null ||
        right != null) {
      basePadding = EdgeInsets.only(
        top: top ?? vertical ?? basePadding.top,
        bottom: bottom ?? vertical ?? basePadding.bottom,
        left: left ?? horizontal ?? basePadding.left,
        right: right ?? horizontal ?? basePadding.right,
      );
    }

    return basePadding;
  }
}

/// 安全余白付きのレスポンシブパディング
class SafeResponsivePadding extends ConsumerWidget {
  const SafeResponsivePadding({
    required this.child,
    this.compact,
    this.medium,
    this.expanded,
    this.maintainBottomViewPadding = false,
    super.key,
  });

  final Widget child;
  final EdgeInsets? compact;
  final EdgeInsets? medium;
  final EdgeInsets? expanded;
  final bool maintainBottomViewPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    maintainBottomViewPadding: maintainBottomViewPadding,
    child: ResponsivePadding(compact: compact, medium: medium, expanded: expanded, child: child),
  );
}

/// 最大幅制限付きのレスポンシブパディング
class ConstrainedResponsivePadding extends ConsumerWidget {
  const ConstrainedResponsivePadding({
    required this.child,
    this.maxWidth = 1200,
    this.compact,
    this.medium,
    this.expanded,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets? compact;
  final EdgeInsets? medium;
  final EdgeInsets? expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ResponsivePadding(compact: compact, medium: medium, expanded: expanded, child: child),
    ),
  );
}

/// レスポンシブな余白設定のプリセット
class ResponsivePaddingPresets {
  ResponsivePaddingPresets._();

  /// 標準的な画面余白
  static const EdgeInsets standardCompact = EdgeInsets.all(16);
  static const EdgeInsets standardMedium = EdgeInsets.all(24);
  static const EdgeInsets standardExpanded = EdgeInsets.all(32);

  /// コンテンツエリア用の余白
  static const EdgeInsets contentCompact = EdgeInsets.all(12);
  static const EdgeInsets contentMedium = EdgeInsets.all(16);
  static const EdgeInsets contentExpanded = EdgeInsets.all(24);

  /// フォーム用の余白
  static const EdgeInsets formCompact = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets formMedium = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const EdgeInsets formExpanded = EdgeInsets.symmetric(horizontal: 32, vertical: 24);

  /// カード用の余白
  static const EdgeInsets cardCompact = EdgeInsets.all(12);
  static const EdgeInsets cardMedium = EdgeInsets.all(16);
  static const EdgeInsets cardExpanded = EdgeInsets.all(20);

  /// セクション用の余白
  static const EdgeInsets sectionCompact = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets sectionMedium = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets sectionExpanded = EdgeInsets.symmetric(horizontal: 32, vertical: 16);
}

/// レスポンシブ余白のヘルパー関数
extension ResponsivePaddingHelpers on EdgeInsets {
  /// デバイスサイズに応じて余白をスケールする
  EdgeInsets scaleForDevice(DeviceType deviceType) {
    double scaleFactor;
    switch (deviceType) {
      case DeviceType.phone:
        scaleFactor = 1.0;
        break;
      case DeviceType.tablet:
        scaleFactor = 1.25;
        break;
      case DeviceType.desktop:
        scaleFactor = 1.5;
        break;
    }

    return EdgeInsets.only(
      top: top * scaleFactor,
      right: right * scaleFactor,
      bottom: bottom * scaleFactor,
      left: left * scaleFactor,
    );
  }
}

/// レスポンシブな間隔を提供するウィジェット
class ResponsiveSpacing extends ConsumerWidget {
  const ResponsiveSpacing({this.compact = 8, this.medium = 12, this.expanded = 16, super.key});

  final double compact;
  final double medium;
  final double expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LayoutInfo layoutInfo = ref.watch(layoutInfoProvider);

    double spacing;
    if (layoutInfo.isCompact) {
      spacing = compact;
    } else if (layoutInfo.isMedium) {
      spacing = medium;
    } else {
      spacing = expanded;
    }

    return SizedBox(height: spacing, width: spacing);
  }
}

/// 水平方向のレスポンシブ間隔
class ResponsiveHorizontalSpacing extends ResponsiveSpacing {
  const ResponsiveHorizontalSpacing({super.compact, super.medium, super.expanded, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LayoutInfo layoutInfo = ref.watch(layoutInfoProvider);

    double spacing;
    if (layoutInfo.isCompact) {
      spacing = compact;
    } else if (layoutInfo.isMedium) {
      spacing = medium;
    } else {
      spacing = expanded;
    }

    return SizedBox(width: spacing);
  }
}

/// 垂直方向のレスポンシブ間隔
class ResponsiveVerticalSpacing extends ResponsiveSpacing {
  const ResponsiveVerticalSpacing({super.compact, super.medium, super.expanded, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LayoutInfo layoutInfo = ref.watch(layoutInfoProvider);

    double spacing;
    if (layoutInfo.isCompact) {
      spacing = compact;
    } else if (layoutInfo.isMedium) {
      spacing = medium;
    } else {
      spacing = expanded;
    }

    return SizedBox(height: spacing);
  }
}
