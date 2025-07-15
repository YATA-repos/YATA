import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.controller,
    this.variant = InputVariant.standard,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final InputVariant variant;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isFocused = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _validateInput(String value) {
    if (widget.validator != null) {
      setState(() {
        _validationError = widget.validator!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final InputDecoration decoration = _buildInputDecoration();
    final TextInputType keyboardType = _getKeyboardType();
    final List<TextInputFormatter> formatters = _getInputFormatters();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _isFocused ? AppColors.primary : AppColors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppLayout.spacing2),
        ],
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: decoration,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          onChanged: (String value) {
            _validateInput(value);
            widget.onChanged?.call(value);
          },
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          validator: widget.validator,
        ),
        if (widget.helperText != null || _validationError != null) ...<Widget>[
          const SizedBox(height: AppLayout.spacing1),
          Text(
            _validationError ?? widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _validationError != null ? AppColors.danger : AppColors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration() {
    final bool hasError = _validationError != null || widget.errorText != null;
    final IconData? leadingIcon = _getLeadingIcon();
    final Widget? suffixWidget = _getSuffixWidget();

    return InputDecoration(
      hintText: widget.hintText,
      errorText: widget.errorText ?? _validationError,
      prefixIcon: leadingIcon != null
          ? Icon(
              leadingIcon,
              size: AppLayout.iconSize,
              color: _isFocused
                  ? AppColors.primary
                  : hasError
                  ? AppColors.danger
                  : AppColors.mutedForeground,
            )
          : null,
      suffixIcon: suffixWidget,
      filled: true,
      fillColor: widget.enabled
          ? (_isFocused ? AppColors.background : AppColors.muted)
          : AppColors.muted,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: hasError ? AppColors.danger : AppColors.border),
        borderRadius: AppLayout.radiusMd,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: hasError ? AppColors.danger : AppColors.border),
        borderRadius: AppLayout.radiusMd,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: hasError ? AppColors.danger : AppColors.primary, width: 2),
        borderRadius: AppLayout.radiusMd,
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger),
        borderRadius: AppLayout.radiusMd,
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: 2),
        borderRadius: AppLayout.radiusMd,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppLayout.spacing3,
        vertical: AppLayout.spacing3,
      ),
      hintStyle: TextStyle(color: AppColors.mutedForeground),
      errorStyle: TextStyle(color: AppColors.danger),
    );
  }

  IconData? _getLeadingIcon() {
    if (widget.prefixIcon != null) {
      return widget.prefixIcon;
    }

    switch (widget.variant) {
      case InputVariant.search:
        return LucideIcons.search;
      case InputVariant.number:
        return LucideIcons.hash;
      case InputVariant.standard:
        return null;
    }
  }

  Widget? _getSuffixWidget() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    switch (widget.variant) {
      case InputVariant.search:
        if (_controller.text.isNotEmpty) {
          return IconButton(
            icon: const Icon(LucideIcons.x, size: AppLayout.iconSizeSm),
            onPressed: () {
              _controller.clear();
              widget.onChanged?.call("");
            },
            color: AppColors.mutedForeground,
          );
        }
        return null;
      case InputVariant.standard:
      case InputVariant.number:
        return null;
    }
  }

  TextInputType _getKeyboardType() {
    if (widget.keyboardType != null) {
      return widget.keyboardType!;
    }

    switch (widget.variant) {
      case InputVariant.number:
        return TextInputType.number;
      case InputVariant.search:
        return TextInputType.text;
      case InputVariant.standard:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    final List<TextInputFormatter> formatters = widget.inputFormatters ?? <TextInputFormatter>[];

    switch (widget.variant) {
      case InputVariant.number:
        formatters.add(FilteringTextInputFormatter.digitsOnly);
      case InputVariant.search:
      case InputVariant.standard:
        break;
    }

    return formatters;
  }
}
