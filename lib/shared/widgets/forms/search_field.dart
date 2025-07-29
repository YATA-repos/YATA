import "dart:async";

import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";
import "app_text_field.dart";

/// SearchField - 検索専用テキストフィールド
///
/// AppTextFieldをベースとし、検索機能に特化した機能
/// （候補表示、履歴、フィルター等）を提供します。
class SearchField extends StatefulWidget {
  const SearchField({
    this.controller,
    this.hintText = "検索...",
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.suggestions = const <String>[],
    this.recentSearches = const <String>[],
    this.showSuggestions = false,
    this.debounceMs = 300,
    this.prefixIcon,
    this.filterOptions = const <FilterOption>[],
    this.selectedFilter,
    this.onFilterChanged,
    this.variant = SearchFieldVariant.standard,
    super.key,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final List<String> suggestions;
  final List<String> recentSearches;
  final bool showSuggestions;
  final int debounceMs;
  final Widget? prefixIcon;
  final List<FilterOption> filterOptions;
  final String? selectedFilter;
  final ValueChanged<String?>? onFilterChanged;
  final SearchFieldVariant variant;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;

  bool get _hasText => _controller.text.isNotEmpty;
  bool get _shouldShowOverlay =>
      _focusNode.hasFocus &&
      widget.showSuggestions &&
      (_getFilteredSuggestions().isNotEmpty || widget.recentSearches.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onChanged?.call(_controller.text);
    });

    if (_shouldShowOverlay) {
      _updateOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onSuggestionTap(String suggestion) {
    _controller.text = suggestion;
    _focusNode.unfocus();
    widget.onSubmitted?.call(suggestion);
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  List<String> _getFilteredSuggestions() {
    if (_controller.text.isEmpty) {
      return <String>[];
    }

    final String query = _controller.text.toLowerCase();
    return widget.suggestions
        .where((String suggestion) => suggestion.toLowerCase().contains(query))
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _layerLink,
    child: Column(
      children: <Widget>[
        // フィルターチップ（compact以外）
        if (widget.variant != SearchFieldVariant.compact &&
            widget.filterOptions.isNotEmpty) ...<Widget>[
          _buildFilterChips(),
          const SizedBox(height: 8),
        ],

        // 検索フィールド
        AppTextField(
          controller: _controller,
          focusNode: _focusNode,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon ?? const Icon(LucideIcons.search),
          suffixIcon: _hasText
              ? IconButton(icon: const Icon(LucideIcons.x), onPressed: _onClear, tooltip: "クリア")
              : null,
          onSubmitted: widget.onSubmitted,
          variant: _getTextFieldVariant(),
        ),
      ],
    ),
  );

  Widget _buildFilterChips() => SizedBox(
    height: 32,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.filterOptions.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
      itemBuilder: (BuildContext context, int index) {
        final FilterOption option = widget.filterOptions[index];
        final bool isSelected = widget.selectedFilter == option.value;

        return FilterChip(
          label: Text(option.label),
          selected: isSelected,
          onSelected: (bool selected) {
            widget.onFilterChanged?.call(selected ? option.value : null);
          },
          backgroundColor: AppColors.muted,
          selectedColor: AppColors.primaryHover,
          labelStyle: AppTextTheme.cardDescription.copyWith(
            color: isSelected ? AppColors.primary : AppColors.foreground,
          ),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        );
      },
    ),
  );

  TextFieldVariant _getTextFieldVariant() => switch (widget.variant) {
    SearchFieldVariant.standard => TextFieldVariant.outlined,
    SearchFieldVariant.filled => TextFieldVariant.filled,
    SearchFieldVariant.compact => TextFieldVariant.outlined,
  };

  void _showOverlay() {
    if (_overlayEntry != null) {
      return;
    }

    _overlayEntry = OverlayEntry(builder: (BuildContext context) => _buildOverlay());

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay() => CompositedTransformFollower(
    link: _layerLink,
    showWhenUnlinked: false,
    offset: const Offset(0, 60),
    child: Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: _buildSuggestionsList(),
      ),
    ),
  );

  Widget _buildSuggestionsList() {
    final List<String> filteredSuggestions = _getFilteredSuggestions();
    final List<String> recentSearches = widget.recentSearches;

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: <Widget>[
        // 検索候補
        if (filteredSuggestions.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "検索候補",
              style: AppTextTheme.cardDescription.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          ...filteredSuggestions.map(
            (String suggestion) => _buildSuggestionItem(suggestion, LucideIcons.search),
          ),
        ],

        // 最近の検索
        if (recentSearches.isNotEmpty && _controller.text.isEmpty) ...<Widget>[
          if (filteredSuggestions.isNotEmpty) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "最近の検索",
              style: AppTextTheme.cardDescription.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          ...recentSearches.map((String search) => _buildSuggestionItem(search, LucideIcons.clock)),
        ],
      ],
    );
  }

  Widget _buildSuggestionItem(String text, IconData icon) => InkWell(
    onTap: () => _onSuggestionTap(text),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.mutedForeground),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextTheme.cardDescription)),
        ],
      ),
    ),
  );
}

/// メニュー検索フィールド
class MenuSearchField extends StatelessWidget {
  const MenuSearchField({
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.suggestions = const <String>[],
    super.key,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) => SearchField(
    controller: controller,
    hintText: "メニューを検索...",
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    suggestions: suggestions,
    showSuggestions: true,
    prefixIcon: const Icon(LucideIcons.utensils),
    filterOptions: const <FilterOption>[
      FilterOption(value: "all", label: "すべて"),
      FilterOption(value: "main", label: "メイン"),
      FilterOption(value: "side", label: "サイド"),
      FilterOption(value: "drink", label: "ドリンク"),
      FilterOption(value: "dessert", label: "デザート"),
    ],
  );
}

/// 在庫検索フィールド
class InventorySearchField extends StatelessWidget {
  const InventorySearchField({
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.suggestions = const <String>[],
    super.key,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) => SearchField(
    controller: controller,
    hintText: "在庫を検索...",
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    suggestions: suggestions,
    showSuggestions: true,
    prefixIcon: const Icon(LucideIcons.package),
    filterOptions: const <FilterOption>[
      FilterOption(value: "all", label: "すべて"),
      FilterOption(value: "in_stock", label: "在庫あり"),
      FilterOption(value: "low_stock", label: "在庫少"),
      FilterOption(value: "out_of_stock", label: "在庫切れ"),
    ],
  );
}

/// 注文検索フィールド
class OrderSearchField extends StatelessWidget {
  const OrderSearchField({this.controller, this.onChanged, this.onSubmitted, super.key});

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => SearchField(
    controller: controller,
    hintText: "注文を検索...",
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    prefixIcon: const Icon(LucideIcons.receipt),
    variant: SearchFieldVariant.compact,
  );
}

/// フィルターオプション
class FilterOption {
  const FilterOption({required this.value, required this.label});

  final String value;
  final String label;
}
