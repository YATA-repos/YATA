import "package:flutter/material.dart";

import "../../constants/app_constants.dart";
import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    required this.items,
    required this.onChanged,
    super.key,
    this.value,
    this.variant = DropdownVariant.standard,
    this.hint,
    this.isExpanded = true,
    this.enabled = true,
    this.icon,
    this.iconSize,
    this.dropdownColor,
    this.borderRadius,
    this.validator,
    this.itemBuilder,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final DropdownVariant variant;
  final Widget? hint;
  final bool isExpanded;
  final bool enabled;
  final Widget? icon;
  final double? iconSize;
  final Color? dropdownColor;
  final BorderRadius? borderRadius;
  final String? Function(T?)? validator;
  final Widget Function(T)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final _DropdownStyle dropdownStyle = _getDropdownStyle();

    return AnimatedContainer(
      duration: AppConstants.animationFast,
      curve: AppConstants.defaultCurve,
      decoration: BoxDecoration(
        color: dropdownStyle.backgroundColor,
        border: Border.all(color: dropdownStyle.borderColor),
        borderRadius: borderRadius ?? AppLayout.radiusMd,
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        hint: hint,
        isExpanded: isExpanded,
        icon: icon ?? const Icon(Icons.keyboard_arrow_down),
        iconSize: iconSize ?? AppLayout.iconSize,
        dropdownColor: dropdownColor ?? dropdownStyle.backgroundColor,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: AppLayout.paddingHorizontal4.copyWith(
            top: AppLayout.spacing3,
            bottom: AppLayout.spacing3,
          ),
          filled: variant == DropdownVariant.filled,
          fillColor: dropdownStyle.fillColor,
        ),
        style: TextStyle(
          color: enabled ? dropdownStyle.textColor : AppColors.mutedForeground,
          fontSize: 16,
        ),
        validator: validator,
        borderRadius: borderRadius ?? AppLayout.radiusMd,
      ),
    );
  }

  _DropdownStyle _getDropdownStyle() {
    switch (variant) {
      case DropdownVariant.standard:
        return _DropdownStyle(
          backgroundColor: AppColors.background,
          borderColor: AppColors.border,
          textColor: AppColors.foreground,
        );
      case DropdownVariant.outlined:
        return _DropdownStyle(
          backgroundColor: AppColors.background,
          borderColor: AppColors.primary,
          textColor: AppColors.foreground,
        );
      case DropdownVariant.filled:
        return _DropdownStyle(
          backgroundColor: AppColors.muted,
          borderColor: AppColors.border,
          textColor: AppColors.foreground,
          fillColor: AppColors.muted,
        );
    }
  }
}

class _DropdownStyle {
  const _DropdownStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.fillColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color? fillColor;
}
