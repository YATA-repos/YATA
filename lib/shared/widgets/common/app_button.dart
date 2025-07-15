import "package:flutter/material.dart";

import "../../constants/app_constants.dart";
import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppButton extends StatelessWidget {
  const AppButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.iconPosition = IconPosition.leading,
  });

  AppButton.text(
    String text, {
    required this.onPressed,
    super.key,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.iconPosition = IconPosition.leading,
  }) : child = Text(text);

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final IconPosition iconPosition;

  @override
  Widget build(BuildContext context) {
    final _ButtonColorScheme colorScheme = _getColorScheme();
    final _ButtonSize buttonSize = _getButtonSize();
    final bool isEnabled = onPressed != null && !isLoading;

    Widget buttonChild = _buildButtonChild();

    if (isFullWidth) {
      buttonChild = SizedBox(width: double.infinity, child: buttonChild);
    }

    return AnimatedContainer(
      duration: AppConstants.animationFast,
      curve: AppConstants.defaultCurve,
      child: _buildButton(
        colorScheme: colorScheme,
        buttonSize: buttonSize,
        isEnabled: isEnabled,
        child: buttonChild,
      ),
    );
  }

  Widget _buildButton({
    required _ButtonColorScheme colorScheme,
    required _ButtonSize buttonSize,
    required bool isEnabled,
    required Widget child,
  }) {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
      case ButtonVariant.warning:
      case ButtonVariant.danger:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? colorScheme.background : AppColors.muted,
            foregroundColor: isEnabled ? colorScheme.foreground : AppColors.mutedForeground,
            elevation: variant == ButtonVariant.ghost ? 0 : AppLayout.elevationSm,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: AppLayout.radiusMd,
              side: variant == ButtonVariant.ghost
                  ? BorderSide(color: isEnabled ? colorScheme.border : AppColors.border)
                  : BorderSide.none,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: buttonSize.horizontalPadding,
              vertical: buttonSize.verticalPadding,
            ),
            minimumSize: Size(buttonSize.minWidth, buttonSize.height),
            maximumSize: Size(double.infinity, buttonSize.height),
          ),
          child: child,
        );
      case ButtonVariant.ghost:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: isEnabled ? colorScheme.foreground : AppColors.mutedForeground,
            side: BorderSide(color: isEnabled ? colorScheme.border : AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: AppLayout.radiusMd),
            padding: EdgeInsets.symmetric(
              horizontal: buttonSize.horizontalPadding,
              vertical: buttonSize.verticalPadding,
            ),
            minimumSize: Size(buttonSize.minWidth, buttonSize.height),
            maximumSize: Size(double.infinity, buttonSize.height),
          ),
          child: child,
        );
    }
  }

  Widget _buildButtonChild() {
    final List<Widget> children = <Widget>[];
    final _ButtonSize buttonSize = _getButtonSize();

    if (isLoading) {
      children.add(
        SizedBox(
          width: buttonSize.iconSize,
          height: buttonSize.iconSize,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
      if (child is Text) {
        children
          ..add(const SizedBox(width: AppLayout.spacing2))
          ..add(Opacity(opacity: 0.7, child: child));
      }
    } else {
      if (icon != null && iconPosition == IconPosition.leading) {
        children
          ..add(Icon(icon, size: buttonSize.iconSize))
          ..add(const SizedBox(width: AppLayout.spacing2));
      }

      children.add(child);

      if (icon != null && iconPosition == IconPosition.trailing) {
        children
          ..add(const SizedBox(width: AppLayout.spacing2))
          ..add(Icon(icon, size: buttonSize.iconSize));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  _ButtonColorScheme _getColorScheme() {
    switch (variant) {
      case ButtonVariant.primary:
        return _ButtonColorScheme(
          background: AppColors.primary,
          foreground: AppColors.primaryForeground,
          border: AppColors.primary,
        );
      case ButtonVariant.secondary:
        return _ButtonColorScheme(
          background: AppColors.secondary,
          foreground: AppColors.secondaryForeground,
          border: AppColors.secondary,
        );
      case ButtonVariant.warning:
        return _ButtonColorScheme(
          background: AppColors.warning,
          foreground: AppColors.warningForeground,
          border: AppColors.warning,
        );
      case ButtonVariant.danger:
        return _ButtonColorScheme(
          background: AppColors.danger,
          foreground: AppColors.dangerForeground,
          border: AppColors.danger,
        );
      case ButtonVariant.ghost:
        return _ButtonColorScheme(
          background: Colors.transparent,
          foreground: AppColors.foreground,
          border: AppColors.border,
        );
    }
  }

  _ButtonSize _getButtonSize() {
    switch (size) {
      case ButtonSize.small:
        return _ButtonSize(
          height: AppLayout.buttonHeightSm,
          horizontalPadding: AppLayout.spacing3,
          verticalPadding: AppLayout.spacing2,
          iconSize: AppLayout.iconSizeSm,
          minWidth: 80,
        );
      case ButtonSize.medium:
        return _ButtonSize(
          height: AppLayout.buttonHeight,
          horizontalPadding: AppLayout.spacing4,
          verticalPadding: AppLayout.spacing3,
          iconSize: AppLayout.iconSize,
          minWidth: 100,
        );
      case ButtonSize.large:
        return _ButtonSize(
          height: AppLayout.buttonHeightLg,
          horizontalPadding: AppLayout.spacing5,
          verticalPadding: AppLayout.spacing4,
          iconSize: AppLayout.iconSizeMd,
          minWidth: 120,
        );
    }
  }
}

class _ButtonColorScheme {
  const _ButtonColorScheme({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

class _ButtonSize {
  const _ButtonSize({
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.minWidth,
  });

  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double minWidth;
}
