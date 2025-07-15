import "package:flutter/material.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

/// アイコンボタンコンポーネント
///
/// 統一されたアイコンボタン、3つのバリアント対応
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.variant = IconButtonVariant.standard,
    this.size = ButtonSize.medium,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.isLoading = false,
    this.enabled = true,
    this.splashRadius,
    this.visualDensity,
    this.padding,
    this.constraints,
    this.style,
  });

  /// 標準ボタン
  factory AppIconButton.standard(
    IconData icon,
    VoidCallback? onPressed, {
    Key? key,
    ButtonSize size = ButtonSize.medium,
    String? tooltip,
    Color? color,
    bool isLoading = false,
    bool enabled = true,
  }) => AppIconButton(
    icon: icon,
    onPressed: onPressed,
    size: size,
    tooltip: tooltip,
    color: color,
    isLoading: isLoading,
    enabled: enabled,
    key: key,
  );

  /// フローティングアクションボタン
  factory AppIconButton.floating(
    IconData icon,
    VoidCallback? onPressed, {
    Key? key,
    ButtonSize size = ButtonSize.medium,
    String? tooltip,
    Color? backgroundColor,
    bool isLoading = false,
    bool enabled = true,
  }) => AppIconButton(
    icon: icon,
    onPressed: onPressed,
    variant: IconButtonVariant.floating,
    size: size,
    tooltip: tooltip,
    backgroundColor: backgroundColor,
    isLoading: isLoading,
    enabled: enabled,
    key: key,
  );

  /// ナビゲーションボタン
  factory AppIconButton.navigation(
    IconData icon,
    VoidCallback? onPressed, {
    Key? key,
    ButtonSize size = ButtonSize.medium,
    String? tooltip,
    Color? color,
    bool isLoading = false,
    bool enabled = true,
  }) => AppIconButton(
    icon: icon,
    onPressed: onPressed,
    variant: IconButtonVariant.navigation,
    size: size,
    tooltip: tooltip,
    color: color,
    isLoading: isLoading,
    enabled: enabled,
    key: key,
  );

  /// アイコン
  final IconData icon;

  /// 押下処理
  final VoidCallback? onPressed;

  /// バリアント
  final IconButtonVariant variant;

  /// サイズ
  final ButtonSize size;

  /// ツールチップ
  final String? tooltip;

  /// アイコン色
  final Color? color;

  /// 背景色
  final Color? backgroundColor;

  /// 境界色
  final Color? borderColor;

  /// ローディング状態
  final bool isLoading;

  /// 有効状態
  final bool enabled;

  /// スプラッシュ半径
  final double? splashRadius;

  /// 視覚密度
  final VisualDensity? visualDensity;

  /// パディング
  final EdgeInsetsGeometry? padding;

  /// 制約
  final BoxConstraints? constraints;

  /// カスタムスタイル
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = enabled && !isLoading;
    final VoidCallback? effectiveOnPressed = isEnabled ? onPressed : null;

    if (isLoading) {
      return _buildLoadingButton(context);
    }

    switch (variant) {
      case IconButtonVariant.standard:
        return _buildStandardButton(context, effectiveOnPressed);
      case IconButtonVariant.floating:
        return _buildFloatingButton(context, effectiveOnPressed);
      case IconButtonVariant.navigation:
        return _buildNavigationButton(context, effectiveOnPressed);
    }
  }

  Widget _buildStandardButton(BuildContext context, VoidCallback? onPressed) => IconButton(
    icon: Icon(icon),
    onPressed: onPressed,
    tooltip: tooltip,
    color: color ?? _getDefaultColor(context),
    iconSize: _getIconSize(),
    splashRadius: splashRadius ?? _getSplashRadius(),
    visualDensity: visualDensity,
    padding: padding ?? _getPadding(),
    constraints: constraints ?? _getConstraints(),
    style: style ?? _getStandardStyle(context),
  );

  Widget _buildFloatingButton(BuildContext context, VoidCallback? onPressed) {
    final double buttonSize = _getFloatingButtonSize();

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: Icon(icon, size: _getIconSize()),
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context, VoidCallback? onPressed) => DecoratedBox(
    decoration: BoxDecoration(
      color: backgroundColor,
      border: borderColor != null ? Border.all(color: borderColor!) : null,
      borderRadius: BorderRadius.circular(AppLayout.spacing2),
    ),
    child: IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
      color: color ?? AppColors.mutedForeground,
      iconSize: _getIconSize(),
      splashRadius: splashRadius ?? _getSplashRadius(),
      visualDensity: visualDensity,
      padding: padding ?? _getPadding(),
      constraints: constraints ?? _getConstraints(),
      style: style ?? _getNavigationStyle(context),
    ),
  );

  Widget _buildLoadingButton(BuildContext context) {
    final double indicatorSize = _getLoadingIndicatorSize();

    return Container(
      width: _getButtonSize(),
      height: _getButtonSize(),
      alignment: Alignment.center,
      child: SizedBox(
        width: indicatorSize,
        height: indicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? _getDefaultColor(context)),
        ),
      ),
    );
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return AppLayout.iconSizeSm;
      case ButtonSize.medium:
        return AppLayout.iconSize;
      case ButtonSize.large:
        return AppLayout.iconSizeLg;
    }
  }

  double _getButtonSize() {
    switch (size) {
      case ButtonSize.small:
        return 32;
      case ButtonSize.medium:
        return 40;
      case ButtonSize.large:
        return 48;
    }
  }

  double _getFloatingButtonSize() {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 56;
      case ButtonSize.large:
        return 72;
    }
  }

  double _getSplashRadius() {
    switch (size) {
      case ButtonSize.small:
        return 20;
      case ButtonSize.medium:
        return 24;
      case ButtonSize.large:
        return 28;
    }
  }

  double _getLoadingIndicatorSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return AppLayout.padding2;
      case ButtonSize.medium:
        return AppLayout.padding3;
      case ButtonSize.large:
        return AppLayout.padding4;
    }
  }

  BoxConstraints _getConstraints() {
    final double minSize = _getButtonSize();
    return BoxConstraints(minWidth: minSize, minHeight: minSize);
  }

  Color _getDefaultColor(BuildContext context) {
    switch (variant) {
      case IconButtonVariant.standard:
        return AppColors.foreground;
      case IconButtonVariant.floating:
        return Colors.white;
      case IconButtonVariant.navigation:
        return AppColors.mutedForeground;
    }
  }

  ButtonStyle _getStandardStyle(BuildContext context) => IconButton.styleFrom(
    foregroundColor: color ?? AppColors.foreground,
    overlayColor: AppColors.muted,
  );

  ButtonStyle _getNavigationStyle(BuildContext context) => IconButton.styleFrom(
    foregroundColor: color ?? AppColors.mutedForeground,
    overlayColor: AppColors.muted.withValues(alpha: 0.5),
  );
}
