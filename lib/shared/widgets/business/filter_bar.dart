import "package:flutter/material.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_layout.dart";
import "../common/app_date_picker.dart";
import "../common/app_dropdown.dart";
import "../common/app_search_bar.dart";

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    this.onSearchChanged,
    this.onCategoryChanged,
    this.onDateChanged,
    this.onClear,
    this.searchController,
    this.searchHint = "検索...",
    this.categoryItems = const <DropdownMenuItem<String>>[],
    this.selectedCategory,
    this.categoryHint = "カテゴリを選択",
    this.dateValue,
    this.dateHint = "日付を選択",
    this.showDatePicker = true,
    this.showCategoryFilter = true,
    this.isCompact = false,
    this.actions,
  });

  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String?>? onCategoryChanged;
  final ValueChanged<DateTime?>? onDateChanged;
  final VoidCallback? onClear;
  final TextEditingController? searchController;
  final String searchHint;
  final List<DropdownMenuItem<String>> categoryItems;
  final String? selectedCategory;
  final String categoryHint;
  final DateTime? dateValue;
  final String dateHint;
  final bool showDatePicker;
  final bool showCategoryFilter;
  final bool isCompact;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppLayout.isMobile(MediaQuery.of(context).size.width);

    if (isMobile || isCompact) {
      return _buildCompactLayout();
    } else {
      return _buildStandardLayout();
    }
  }

  Widget _buildStandardLayout() => Container(
    padding: AppLayout.padding4,
    child: Row(
      children: <Widget>[
        // 検索バー
        Expanded(
          flex: 3,
          child: AppSearchBar(
            controller: searchController,
            hintText: searchHint,
            onChanged: onSearchChanged,
          ),
        ),

        if (showCategoryFilter) ...<Widget>[
          const SizedBox(width: AppLayout.spacing4),
          // カテゴリフィルター
          Expanded(
            flex: 2,
            child: AppDropdown<String>(
              items: categoryItems,
              value: selectedCategory,
              onChanged: onCategoryChanged,
              hint: Text(categoryHint),
            ),
          ),
        ],

        if (showDatePicker) ...<Widget>[
          const SizedBox(width: AppLayout.spacing4),
          // 日付フィルター
          Expanded(
            flex: 2,
            child: AppDatePicker(
              initialDate: dateValue,
              hintText: dateHint,
              onDateChanged: onDateChanged,
            ),
          ),
        ],

        if (actions != null) ...<Widget>[
          const SizedBox(width: AppLayout.spacing4),
          // アクションボタン
          Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ],
      ],
    ),
  );

  Widget _buildCompactLayout() => Container(
    padding: AppLayout.padding4,
    child: Column(
      children: <Widget>[
        // 第1行: 検索バー
        AppSearchBar(
          controller: searchController,
          hintText: searchHint,
          onChanged: onSearchChanged,
          variant: SearchBarVariant.compact,
        ),

        if (showCategoryFilter || showDatePicker) ...<Widget>[
          const SizedBox(height: AppLayout.spacing3),
          // 第2行: フィルター
          Row(
            children: <Widget>[
              if (showCategoryFilter)
                Expanded(
                  child: AppDropdown<String>(
                    items: categoryItems,
                    value: selectedCategory,
                    onChanged: onCategoryChanged,
                    hint: Text(categoryHint),
                  ),
                ),

              if (showCategoryFilter && showDatePicker) const SizedBox(width: AppLayout.spacing4),

              if (showDatePicker)
                Expanded(
                  child: AppDatePicker(
                    initialDate: dateValue,
                    hintText: dateHint,
                    onDateChanged: onDateChanged,
                    variant: DatePickerVariant.compact,
                  ),
                ),
            ],
          ),
        ],

        if (actions != null && actions!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppLayout.spacing3),
          // 第3行: アクション
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
        ],
      ],
    ),
  );
}

class FilterBarController {
  FilterBarController({String? initialSearch, String? initialCategory, DateTime? initialDate})
    : _search = initialSearch ?? "",
      _category = initialCategory,
      _date = initialDate;

  String _search;
  String? _category;
  DateTime? _date;

  String get search => _search;
  String? get category => _category;
  DateTime? get date => _date;

  void updateSearch(String value) {
    _search = value;
  }

  void updateCategory(String? value) {
    _category = value;
  }

  void updateDate(DateTime? value) {
    _date = value;
  }

  void clear() {
    _search = "";
    _category = null;
    _date = null;
  }

  bool get hasActiveFilters => _search.isNotEmpty || _category != null || _date != null;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "search": _search,
    "category": _category,
    "date": _date?.toIso8601String(),
  };

  void fromMap(Map<String, dynamic> map) {
    _search = map["search"]?.toString() ?? "";
    _category = map["category"]?.toString();

    final String? dateString = map["date"]?.toString();
    _date = dateString != null ? DateTime.tryParse(dateString) : null;
  }

  FilterBarController copyWith({String? search, String? category, DateTime? date}) =>
      FilterBarController(
        initialSearch: search ?? _search,
        initialCategory: category ?? _category,
        initialDate: date ?? _date,
      );
}
