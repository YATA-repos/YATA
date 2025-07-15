import "package:flutter/material.dart";

import "../../constants/app_constants.dart";
import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.controller,
    this.variant = SearchBarVariant.standard,
    this.hintText,
    this.enabled = true,
    this.autofocus = false,
    this.showClearButton = true,
    this.leadingIcon,
    this.trailingActions,
    this.debounceTime,
  });

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final SearchBarVariant variant;
  final String? hintText;
  final bool enabled;
  final bool autofocus;
  final bool showClearButton;
  final Widget? leadingIcon;
  final List<Widget>? trailingActions;
  final Duration? debounceTime;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final bool hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    if (widget.onChanged != null) {
      widget.onChanged!("");
    }
  }

  @override
  Widget build(BuildContext context) {
    final _SearchBarStyle searchBarStyle = _getSearchBarStyle();

    return AnimatedContainer(
      duration: AppConstants.animationFast,
      curve: AppConstants.defaultCurve,
      decoration: _buildDecoration(searchBarStyle),
      child: TextFormField(
        controller: _controller,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        onFieldSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText ?? "検索...",
          hintStyle: TextStyle(color: searchBarStyle.hintColor, fontSize: _getFontSize()),
          prefixIcon:
              widget.leadingIcon ??
              Icon(Icons.search, color: searchBarStyle.iconColor, size: _getIconSize()),
          suffixIcon: _buildSuffixIcons(searchBarStyle),
          border: _buildBorder(searchBarStyle),
          enabledBorder: _buildBorder(searchBarStyle),
          focusedBorder: _buildBorder(searchBarStyle, focused: true),
          filled: searchBarStyle.filled,
          fillColor: searchBarStyle.fillColor,
          contentPadding: _getContentPadding(),
        ),
        style: TextStyle(
          color: widget.enabled ? searchBarStyle.textColor : AppColors.mutedForeground,
          fontSize: _getFontSize(),
        ),
      ),
    );
  }

  BoxDecoration? _buildDecoration(_SearchBarStyle style) {
    switch (widget.variant) {
      case SearchBarVariant.bordered:
        return BoxDecoration(
          color: style.backgroundColor,
          border: Border.all(color: style.borderColor),
          borderRadius: AppLayout.radiusMd,
        );
      case SearchBarVariant.standard:
      case SearchBarVariant.compact:
        return null;
    }
  }

  InputBorder _buildBorder(_SearchBarStyle style, {bool focused = false}) {
    switch (widget.variant) {
      case SearchBarVariant.standard:
      case SearchBarVariant.compact:
        return OutlineInputBorder(
          borderRadius: AppLayout.radiusMd,
          borderSide: BorderSide(
            color: focused ? style.focusedBorderColor : style.borderColor,
            width: focused ? 2 : 1,
          ),
        );
      case SearchBarVariant.bordered:
        return InputBorder.none;
    }
  }

  Widget? _buildSuffixIcons(_SearchBarStyle style) {
    final List<Widget> actions = <Widget>[];

    if (widget.showClearButton && _hasText) {
      actions.add(
        IconButton(
          onPressed: _onClear,
          icon: Icon(Icons.clear, color: style.iconColor, size: _getIconSize()),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      );
    }

    if (widget.trailingActions != null) {
      actions.addAll(widget.trailingActions!);
    }

    if (actions.isEmpty) {
      return null;
    }

    if (actions.length == 1) {
      return actions.first;
    }

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  EdgeInsets _getContentPadding() {
    switch (widget.variant) {
      case SearchBarVariant.standard:
        return AppLayout.paddingHorizontal4.copyWith(
          top: AppLayout.spacing3,
          bottom: AppLayout.spacing3,
        );
      case SearchBarVariant.compact:
        return AppLayout.paddingHorizontal4.copyWith(
          top: AppLayout.spacing2,
          bottom: AppLayout.spacing2,
        );
      case SearchBarVariant.bordered:
        return AppLayout.paddingHorizontal4.copyWith(
          top: AppLayout.spacing3,
          bottom: AppLayout.spacing3,
        );
    }
  }

  double _getFontSize() {
    switch (widget.variant) {
      case SearchBarVariant.standard:
      case SearchBarVariant.bordered:
        return 16;
      case SearchBarVariant.compact:
        return 14;
    }
  }

  double _getIconSize() {
    switch (widget.variant) {
      case SearchBarVariant.standard:
      case SearchBarVariant.bordered:
        return AppLayout.iconSize;
      case SearchBarVariant.compact:
        return AppLayout.iconSizeSm;
    }
  }

  _SearchBarStyle _getSearchBarStyle() {
    switch (widget.variant) {
      case SearchBarVariant.standard:
        return _SearchBarStyle(
          backgroundColor: AppColors.background,
          borderColor: AppColors.border,
          focusedBorderColor: AppColors.primary,
          textColor: AppColors.foreground,
          hintColor: AppColors.mutedForeground,
          iconColor: AppColors.mutedForeground,
          filled: false,
        );
      case SearchBarVariant.compact:
        return _SearchBarStyle(
          backgroundColor: AppColors.muted,
          borderColor: AppColors.border,
          focusedBorderColor: AppColors.primary,
          textColor: AppColors.foreground,
          hintColor: AppColors.mutedForeground,
          iconColor: AppColors.mutedForeground,
          filled: true,
          fillColor: AppColors.muted,
        );
      case SearchBarVariant.bordered:
        return _SearchBarStyle(
          backgroundColor: AppColors.background,
          borderColor: AppColors.primary,
          focusedBorderColor: AppColors.primary,
          textColor: AppColors.foreground,
          hintColor: AppColors.mutedForeground,
          iconColor: AppColors.primary,
          filled: false,
        );
    }
  }
}

class _SearchBarStyle {
  const _SearchBarStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.focusedBorderColor,
    required this.textColor,
    required this.hintColor,
    required this.iconColor,
    required this.filled,
    this.fillColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color textColor;
  final Color hintColor;
  final Color iconColor;
  final bool filled;
  final Color? fillColor;
}
