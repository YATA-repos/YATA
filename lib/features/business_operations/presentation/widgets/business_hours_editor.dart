import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/widgets/error_view.dart";
import "../../dto/business_hours_dto.dart";
import "../../models/business_hours_model.dart";
import "../providers/business_operations_providers.dart";

/// 基本営業時間を編集するウィジェット
class BusinessHoursEditor extends ConsumerStatefulWidget {
  const BusinessHoursEditor({super.key});

  @override
  ConsumerState<BusinessHoursEditor> createState() => _BusinessHoursEditorState();
}

class _BusinessHoursEditorState extends ConsumerState<BusinessHoursEditor> {
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  Set<int> _operatingDays = <int>{};
  bool _isModified = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BusinessHoursModel> businessHoursAsync = ref.watch(businessHoursProvider);

    return businessHoursAsync.when(
      data: (BusinessHoursModel businessHours) {
        if (_openTime == null) {
          _initializeFromBusinessHours(businessHours);
        }
        return _buildEditor(context, businessHours);
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (Object error, StackTrace stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorView(
            message: "営業時間の読み込みに失敗しました",
            onRetry: () => ref.invalidate(businessHoursProvider),
          ),
        ),
      ),
    );
  }

  void _initializeFromBusinessHours(BusinessHoursModel businessHours) {
    // String時刻をTimeOfDayに変換
    final List<String> openParts = businessHours.openTime.split(":");
    final List<String> closeParts = businessHours.closeTime.split(":");

    _openTime = TimeOfDay(hour: int.parse(openParts[0]), minute: int.parse(openParts[1]));
    _closeTime = TimeOfDay(hour: int.parse(closeParts[0]), minute: int.parse(closeParts[1]));
    _operatingDays = Set<int>.from(businessHours.operatingDays ?? <int>{});
  }

  Widget _buildEditor(BuildContext context, BusinessHoursModel businessHours) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(LucideIcons.clock, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  "基本営業時間",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_isModified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "未保存",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // 営業時間設定
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildTimeSelector(
                    context,
                    "開店時間",
                    _openTime!,
                    LucideIcons.sunrise,
                    _updateOpenTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    context,
                    "閉店時間",
                    _closeTime!,
                    LucideIcons.sunset,
                    _updateCloseTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 営業日設定
            Text("営業日", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),

            const SizedBox(height: 12),

            _buildDaySelector(context),

            const SizedBox(height: 24),

            // アクションボタン
            if (_isModified)
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(onPressed: _resetChanges, child: const Text("リセット")),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(onPressed: _saveChanges, child: const Text("保存")),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    TimeOfDay time,
    IconData icon,
    void Function(TimeOfDay) onTimeChanged,
  ) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(context, time, onTimeChanged),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  time.format(context),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(LucideIcons.chevronDown, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    final List<(int, String)> days = <(int, String)>[
      (1, "月"),
      (2, "火"),
      (3, "水"),
      (4, "木"),
      (5, "金"),
      (6, "土"),
      (7, "日"),
    ];

    return Wrap(
      spacing: 8,
      children: days.map(((int, String) day) => _buildDayChip(context, day.$1, day.$2)).toList(),
    );
  }

  Widget _buildDayChip(BuildContext context, int dayNumber, String dayName) {
    final ThemeData theme = Theme.of(context);
    final bool isSelected = _operatingDays.contains(dayNumber);

    return FilterChip(
      label: Text(dayName),
      selected: isSelected,
      onSelected: (bool selected) => _toggleOperatingDay(dayNumber),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
      side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay currentTime,
    void Function(TimeOfDay) onTimeChanged,
  ) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (selectedTime != null) {
      onTimeChanged(selectedTime);
    }
  }

  void _updateOpenTime(TimeOfDay time) {
    setState(() {
      _openTime = time;
      _isModified = true;
    });
  }

  void _updateCloseTime(TimeOfDay time) {
    setState(() {
      _closeTime = time;
      _isModified = true;
    });
  }

  void _toggleOperatingDay(int dayNumber) {
    setState(() {
      if (_operatingDays.contains(dayNumber)) {
        _operatingDays.remove(dayNumber);
      } else {
        _operatingDays.add(dayNumber);
      }
      _isModified = true;
    });
  }

  void _resetChanges() {
    final BusinessHoursModel? businessHours = ref
        .read<AsyncValue<BusinessHoursModel>>(businessHoursProvider)
        .value;
    if (businessHours != null) {
      setState(() {
        _initializeFromBusinessHours(businessHours);
        _isModified = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_openTime == null || _closeTime == null) {
      return;
    }

    try {
      final BusinessHoursDto dto = BusinessHoursDto(
        openTime:
            "${_openTime!.hour.toString().padLeft(2, '0')}:${_openTime!.minute.toString().padLeft(2, '0')}",
        closeTime:
            "${_closeTime!.hour.toString().padLeft(2, '0')}:${_closeTime!.minute.toString().padLeft(2, '0')}",
        isOpen: _operatingDays.isNotEmpty,
      );

      final Future<BusinessHoursModel> Function(BusinessHoursDto p1) update = ref.read(
        updateBusinessHoursProvider,
      );
      await update(dto);

      setState(() {
        _isModified = false;
      });

      _showSnackBar("営業時間を更新しました");
    } catch (e) {
      _showSnackBar("営業時間の更新に失敗しました: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}
