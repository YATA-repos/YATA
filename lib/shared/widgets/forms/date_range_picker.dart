import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";
import "../cards/app_card.dart";

/// 日付範囲選択ウィジェット
///
/// プリセットと手動選択をサポート
class AppDateRangePicker extends StatefulWidget {
  const AppDateRangePicker({
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
    this.presets = const <DateRangePreset>[],
    this.enablePresets = true,
    this.label = "期間選択",
    super.key,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime? startDate, DateTime? endDate) onDateRangeChanged;
  final List<DateRangePreset> presets;
  final bool enablePresets;
  final String label;

  @override
  State<AppDateRangePicker> createState() => _AppDateRangePickerState();
}

class _AppDateRangePickerState extends State<AppDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  void didUpdateWidget(AppDateRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate || widget.endDate != oldWidget.endDate) {
      _startDate = widget.startDate;
      _endDate = widget.endDate;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.label, style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
        const SizedBox(height: 8),

        // プリセット選択
        if (widget.enablePresets && widget.presets.isNotEmpty) ...<Widget>[
          _buildPresetSelection(),
          const SizedBox(height: 12),
        ],

        // 手動日付選択
        _buildManualSelection(),
      ],
    );

  Widget _buildPresetSelection() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: widget.presets.map((DateRangePreset preset) {
      final bool isSelected = _selectedPreset == preset.key;
      return FilterChip(
        label: Text(preset.label),
        selected: isSelected,
        onSelected: (bool selected) => _handlePresetSelection(preset),
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        checkmarkColor: AppColors.primary,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      );
    }).toList(),
  );

  Widget _buildManualSelection() => AppCard(
    child: Row(
      children: <Widget>[
        // 開始日
        Expanded(
          child: _buildDateField(
            label: "開始日",
            date: _startDate,
            onTap: () => _selectStartDate(context),
          ),
        ),

        const SizedBox(width: 16),

        // 区切り文字
        Icon(LucideIcons.arrowRight, size: 16, color: AppColors.mutedForeground),

        const SizedBox(width: 16),

        // 終了日
        Expanded(
          child: _buildDateField(
            label: "終了日",
            date: _endDate,
            onTap: () => _selectEndDate(context),
          ),
        ),
      ],
    ),
  );

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTextTheme.cardDescription.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Icon(LucideIcons.calendar, size: 16, color: AppColors.mutedForeground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date != null
                      ? "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}"
                      : "選択してください",
                  style: date != null
                      ? AppTextTheme.cardDescription
                      : AppTextTheme.cardDescription.copyWith(color: AppColors.mutedForeground),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _handlePresetSelection(DateRangePreset preset) {
    final DateTimeRange range = preset.getDateRange();
    setState(() {
      _selectedPreset = preset.key;
      _startDate = range.start;
      _endDate = range.end;
    });
    widget.onDateRangeChanged(_startDate, _endDate);
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _selectedPreset = null; // プリセット選択をクリア

        // 終了日が開始日より前の場合は調整
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _selectedPreset = null; // プリセット選択をクリア
      });
      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }
}

/// 日付範囲プリセット
class DateRangePreset {
  const DateRangePreset({required this.key, required this.label, required this.getDateRange});

  final String key;
  final String label;
  final DateTimeRange Function() getDateRange;

  /// 今日
  static DateRangePreset get today => DateRangePreset(
    key: "today",
    label: "今日",
    getDateRange: () {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      return DateTimeRange(start: today, end: today);
    },
  );

  /// 昨日
  static DateRangePreset get yesterday => DateRangePreset(
    key: "yesterday",
    label: "昨日",
    getDateRange: () {
      final DateTime now = DateTime.now();
      final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
      return DateTimeRange(start: yesterday, end: yesterday);
    },
  );

  /// 過去7日間
  static DateRangePreset get last7Days => DateRangePreset(
    key: "last7Days",
    label: "過去7日間",
    getDateRange: () {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime week = today.subtract(const Duration(days: 6));
      return DateTimeRange(start: week, end: today);
    },
  );

  /// 過去30日間
  static DateRangePreset get last30Days => DateRangePreset(
    key: "last30Days",
    label: "過去30日間",
    getDateRange: () {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime month = today.subtract(const Duration(days: 29));
      return DateTimeRange(start: month, end: today);
    },
  );

  /// 今月
  static DateRangePreset get thisMonth => DateRangePreset(
    key: "thisMonth",
    label: "今月",
    getDateRange: () {
      final DateTime now = DateTime.now();
      final DateTime startOfMonth = DateTime(now.year, now.month);
      final DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);
      return DateTimeRange(start: startOfMonth, end: endOfMonth);
    },
  );

  /// 先月
  static DateRangePreset get lastMonth => DateRangePreset(
    key: "lastMonth",
    label: "先月",
    getDateRange: () {
      final DateTime now = DateTime.now();
      final DateTime startOfLastMonth = DateTime(now.year, now.month - 1);
      final DateTime endOfLastMonth = DateTime(now.year, now.month, 0);
      return DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
    },
  );

  /// デフォルトプリセット
  static List<DateRangePreset> get defaultPresets => <DateRangePreset>[
    today,
    yesterday,
    last7Days,
    last30Days,
    thisMonth,
    lastMonth,
  ];
}
