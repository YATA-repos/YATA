import "package:flutter/material.dart";

import "../../constants/app_constants.dart";
import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateChanged,
    this.variant = DatePickerVariant.standard,
    this.enabled = true,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.dateFormat,
  });

  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime?>? onDateChanged;
  final DatePickerVariant variant;
  final bool enabled;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(DateTime?)? validator;
  final String Function(DateTime)? dateFormat;

  @override
  Widget build(BuildContext context) {
    final _DatePickerStyle datePickerStyle = _getDatePickerStyle();

    return AnimatedContainer(
      duration: AppConstants.animationFast,
      curve: AppConstants.defaultCurve,
      child: _buildDatePickerField(context, datePickerStyle),
    );
  }

  Widget _buildDatePickerField(BuildContext context, _DatePickerStyle style) {
    switch (variant) {
      case DatePickerVariant.standard:
      case DatePickerVariant.compact:
        return _buildSingleDatePicker(context, style);
      case DatePickerVariant.range:
        return _buildDateRangePicker(context, style);
    }
  }

  Widget _buildSingleDatePicker(BuildContext context, _DatePickerStyle style) => TextFormField(
    readOnly: true,
    enabled: enabled,
    onTap: enabled ? () => _showDatePicker(context) : null,
    decoration: InputDecoration(
      hintText: hintText ?? "日付を選択",
      prefixIcon: prefixIcon ?? const Icon(Icons.calendar_today),
      suffixIcon: suffixIcon,
      border: _buildBorder(style),
      enabledBorder: _buildBorder(style),
      focusedBorder: _buildBorder(style, focused: true),
      filled: style.filled,
      fillColor: style.fillColor,
      contentPadding: variant == DatePickerVariant.compact
          ? AppLayout.paddingHorizontal4.copyWith(
              top: AppLayout.spacing2,
              bottom: AppLayout.spacing2,
            )
          : AppLayout.paddingHorizontal4.copyWith(
              top: AppLayout.spacing3,
              bottom: AppLayout.spacing3,
            ),
    ),
    style: TextStyle(
      color: enabled ? style.textColor : AppColors.mutedForeground,
      fontSize: variant == DatePickerVariant.compact ? 14 : 16,
    ),
    controller: TextEditingController(
      text: initialDate != null ? dateFormat?.call(initialDate!) ?? _formatDate(initialDate!) : "",
    ),
    validator: validator != null ? (String? value) => validator!(initialDate) : null,
  );

  Widget _buildDateRangePicker(BuildContext context, _DatePickerStyle style) => TextFormField(
    readOnly: true,
    enabled: enabled,
    onTap: enabled ? () => _showDateRangePicker(context) : null,
    decoration: InputDecoration(
      hintText: hintText ?? "期間を選択",
      prefixIcon: prefixIcon ?? const Icon(Icons.date_range),
      suffixIcon: suffixIcon,
      border: _buildBorder(style),
      enabledBorder: _buildBorder(style),
      focusedBorder: _buildBorder(style, focused: true),
      filled: style.filled,
      fillColor: style.fillColor,
      contentPadding: AppLayout.paddingHorizontal4.copyWith(
        top: AppLayout.spacing3,
        bottom: AppLayout.spacing3,
      ),
    ),
    style: TextStyle(color: enabled ? style.textColor : AppColors.mutedForeground, fontSize: 16),
    validator: validator != null ? (String? value) => validator!(initialDate) : null,
  );

  InputBorder _buildBorder(_DatePickerStyle style, {bool focused = false}) => OutlineInputBorder(
    borderRadius: AppLayout.radiusMd,
    borderSide: BorderSide(
      color: focused ? style.focusedBorderColor : style.borderColor,
      width: focused ? 2 : 1,
    ),
  );

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      builder: (BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: AppColors.primaryForeground,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && onDateChanged != null) {
      onDateChanged!(pickedDate);
    }
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      builder: (BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: AppColors.primaryForeground,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedRange != null && onDateChanged != null) {
      onDateChanged!(pickedRange.start);
    }
  }

  String _formatDate(DateTime date) =>
      "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";

  _DatePickerStyle _getDatePickerStyle() {
    switch (variant) {
      case DatePickerVariant.standard:
        return _DatePickerStyle(
          borderColor: AppColors.border,
          focusedBorderColor: AppColors.primary,
          textColor: AppColors.foreground,
          filled: false,
        );
      case DatePickerVariant.range:
        return _DatePickerStyle(
          borderColor: AppColors.border,
          focusedBorderColor: AppColors.primary,
          textColor: AppColors.foreground,
          filled: false,
        );
      case DatePickerVariant.compact:
        return _DatePickerStyle(
          borderColor: AppColors.border,
          focusedBorderColor: AppColors.primary,
          textColor: AppColors.foreground,
          filled: true,
          fillColor: AppColors.muted,
        );
    }
  }
}

class _DatePickerStyle {
  const _DatePickerStyle({
    required this.borderColor,
    required this.focusedBorderColor,
    required this.textColor,
    required this.filled,
    this.fillColor,
  });

  final Color borderColor;
  final Color focusedBorderColor;
  final Color textColor;
  final bool filled;
  final Color? fillColor;
}
