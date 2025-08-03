import "package:flutter/material.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";
import "../common/loading_indicator.dart";

/// AppButton - 統一されたボタンコンポーネント
///
/// 既存のAppColors・AppTextThemeを完全活用し、
/// 業務固有のバリアント（complete等）も含む統一されたボタンUIを提供します。
class AppButton extends StatelessWidget {
  const AppButton({
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isEnabled = true,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final bool effectivelyEnabled = isEnabled && !isLoading && onPressed != null;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: effectivelyEnabled ? onPressed : null,
        style: _getButtonStyle(),
        child: isLoading
            ? SizedBox(
                height: _getIconSize(),
                width: _getIconSize(),
                child: InlineLoadingIndicator(color: _getForegroundColor(), size: _getIconSize()),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[icon!, SizedBox(width: _getIconSpacing())],
                  Text(text),
                ],
              ),
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    final (Color backgroundColor, Color foregroundColor, TextStyle textStyle) = _getVariantColors();
    final EdgeInsets padding = _getPadding();
    final double borderRadius = _getBorderRadius();

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: AppColors.muted,
      disabledForegroundColor: AppColors.mutedForeground,
      textStyle: textStyle,
      padding: padding,
      elevation: variant == ButtonVariant.outline ? 0 : 2,
      shadowColor: variant == ButtonVariant.outline ? Colors.transparent : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: variant == ButtonVariant.outline
            ? BorderSide(color: _getOutlineColor())
            : BorderSide.none,
      ),
    ).copyWith(
      overlayColor: _getPressedOverlayColor(),
    );
  }

  (Color, Color, TextStyle) _getVariantColors() => switch (variant) {
    ButtonVariant.primary => (
      AppColors.primary,
      AppColors.primaryForeground,
      AppTextTheme.buttonText,
    ),
    ButtonVariant.secondary => (
      AppColors.secondary,
      AppColors.secondaryForeground,
      AppTextTheme.buttonText,
    ),
    ButtonVariant.outline => (
      Colors.transparent,
      AppColors.primary,
      AppTextTheme.buttonTextSecondary,
    ),
    ButtonVariant.danger => (AppColors.danger, AppColors.dangerForeground, AppTextTheme.buttonText),
    // 業務固有バリアント
    ButtonVariant.complete => (
      AppColors.complete,
      AppColors.completeForeground,
      AppTextTheme.buttonText,
    ),
    ButtonVariant.cooking => (
      AppColors.cooking,
      AppColors.cookingForeground,
      AppTextTheme.buttonText,
    ),
    ButtonVariant.cancel => (AppColors.cancel, AppColors.cancelForeground, AppTextTheme.buttonText),
  };

  Color _getForegroundColor() {
    final (_, Color foregroundColor, _) = _getVariantColors();
    return foregroundColor;
  }

  Color _getOutlineColor() => switch (variant) {
    ButtonVariant.outline => AppColors.primary,
    ButtonVariant.danger => AppColors.danger,
    ButtonVariant.complete => AppColors.complete,
    ButtonVariant.cooking => AppColors.cooking,
    ButtonVariant.cancel => AppColors.cancel,
    _ => AppColors.border,
  };

  /// 押下時のオーバーレイ色を取得（薄い色で押下時の視覚効果を提供）
  WidgetStateProperty<Color?> _getPressedOverlayColor() =>
    WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return _getPressedColor();
      }
      return null; // デフォルトの hover 効果を保持
    });

  /// 各バリアントに対応した押下時の薄い色を取得
  Color _getPressedColor() => switch (variant) {
    ButtonVariant.primary => Colors.white.withValues(alpha: 0.1),
    ButtonVariant.secondary => Colors.white.withValues(alpha: 0.1),
    ButtonVariant.outline => AppColors.primary.withValues(alpha: 0.1),
    ButtonVariant.danger => Colors.white.withValues(alpha: 0.1),
    ButtonVariant.complete => Colors.white.withValues(alpha: 0.1),
    ButtonVariant.cooking => Colors.white.withValues(alpha: 0.1),
    ButtonVariant.cancel => Colors.white.withValues(alpha: 0.1),
  };

  EdgeInsets _getPadding() => switch (size) {
    ButtonSize.small => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ButtonSize.medium => const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ButtonSize.large => const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  };

  double _getBorderRadius() => switch (size) {
    ButtonSize.small => 6.0,
    ButtonSize.medium => 8.0,
    ButtonSize.large => 10.0,
  };

  double _getIconSize() => switch (size) {
    ButtonSize.small => 14.0,
    ButtonSize.medium => 16.0,
    ButtonSize.large => 18.0,
  };

  double _getIconSpacing() => switch (size) {
    ButtonSize.small => 6.0,
    ButtonSize.medium => 8.0,
    ButtonSize.large => 10.0,
  };
}

/// アイコンボタン - アイコンのみのコンパクトなボタン
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.tooltip,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget button = SizedBox(
      width: _getButtonSize(),
      height: _getButtonSize(),
      child: AppButton(
        text: "",
        onPressed: onPressed,
        variant: variant,
        size: size,
        icon: isLoading ? null : icon,
        isLoading: isLoading,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }

  double _getButtonSize() => switch (size) {
    ButtonSize.small => 32.0,
    ButtonSize.medium => 40.0,
    ButtonSize.large => 48.0,
  };
}
