import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/widgets/error_view.dart";
import "../../dto/business_hours_dto.dart";
import "../../models/business_hours_model.dart";
import "../providers/business_operations_providers.dart";

/// 曜日別営業時間を表示・編集するグリッド
class WeeklyHoursGrid extends ConsumerStatefulWidget {
  const WeeklyHoursGrid({super.key});

  @override
  ConsumerState<WeeklyHoursGrid> createState() => _WeeklyHoursGridState();
}

class _WeeklyHoursGridState extends ConsumerState<WeeklyHoursGrid> {
  final Map<int, DayHours> _weeklyHours = <int, DayHours>{};
  bool _isModified = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BusinessHoursModel> businessHoursAsync = ref.watch(businessHoursProvider);

    return businessHoursAsync.when(
      data: (BusinessHoursModel businessHours) {
        if (_weeklyHours.isEmpty) {
          _initializeWeeklyHours(businessHours);
        }
        return _buildGrid(context, businessHours);
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

  void _initializeWeeklyHours(BusinessHoursModel businessHours) {
    final Map<int, String>? weeklyHours = businessHours.weeklyHours;

    for (int day = 1; day <= 7; day++) {
      if (weeklyHours != null && weeklyHours.containsKey(day)) {
        // weeklyHoursの値はStringなので、パースしてDayHoursに変換
        final String timeRange = weeklyHours[day]!;
        final List<String> parts = timeRange.split(" - ");
        if (parts.length == 2) {
          final List<String> openParts = parts[0].split(":");
          final List<String> closeParts = parts[1].split(":");
          _weeklyHours[day] = DayHours(
            openTime: TimeOfDay(hour: int.parse(openParts[0]), minute: int.parse(openParts[1])),
            closeTime: TimeOfDay(hour: int.parse(closeParts[0]), minute: int.parse(closeParts[1])),
            isOpen: true,
          );
        } else {
          _weeklyHours[day] = const DayHours(isOpen: false);
        }
      } else {
        // 基本営業時間をデフォルトとして使用
        final bool isOperating = businessHours.operatingDays?.contains(day) ?? false;
        if (isOperating) {
          final List<String> openParts = businessHours.openTime.split(":");
          final List<String> closeParts = businessHours.closeTime.split(":");
          _weeklyHours[day] = DayHours(
            openTime: TimeOfDay(hour: int.parse(openParts[0]), minute: int.parse(openParts[1])),
            closeTime: TimeOfDay(hour: int.parse(closeParts[0]), minute: int.parse(closeParts[1])),
            isOpen: true,
          );
        } else {
          _weeklyHours[day] = const DayHours(isOpen: false);
        }
      }
    }
  }

  Widget _buildGrid(BuildContext context, BusinessHoursModel businessHours) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(LucideIcons.calendar, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  "曜日別営業時間",
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
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: "copy_basic",
                      child: Row(
                        children: <Widget>[
                          Icon(LucideIcons.copy),
                          SizedBox(width: 8),
                          Text("基本時間をコピー"),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: "reset_all",
                      child: Row(
                        children: <Widget>[
                          Icon(LucideIcons.rotateCcw),
                          SizedBox(width: 8),
                          Text("すべてリセット"),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (String value) {
                    switch (value) {
                      case "copy_basic":
                        _copyBasicHours(businessHours);
                        break;
                      case "reset_all":
                        _resetAllHours(businessHours);
                        break;
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 曜日グリッド
            Column(children: _buildDayRows(context)),

            if (_isModified) ...<Widget>[
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _resetAllHours(businessHours),
                      child: const Text("リセット"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(onPressed: _saveWeeklyHours, child: const Text("保存")),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDayRows(BuildContext context) {
    final List<(int, String, String)> days = <(int, String, String)>[
      (1, "月曜日", "月"),
      (2, "火曜日", "火"),
      (3, "水曜日", "水"),
      (4, "木曜日", "木"),
      (5, "金曜日", "金"),
      (6, "土曜日", "土"),
      (7, "日曜日", "日"),
    ];

    return days
        .map(((int, String, String) day) => _buildDayRow(context, day.$1, day.$2, day.$3))
        .toList();
  }

  Widget _buildDayRow(BuildContext context, int dayNumber, String dayName, String shortName) {
    final ThemeData theme = Theme.of(context);
    final DayHours dayHours = _weeklyHours[dayNumber]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _editDayHours(context, dayNumber, dayName),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
            color: dayHours.isOpen
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dayHours.isOpen
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    shortName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dayHours.isOpen
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      dayName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dayHours.isOpen
                          ? "${dayHours.openTime!.format(context)} - ${dayHours.closeTime!.format(context)}"
                          : "休業日",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: dayHours.isOpen
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                dayHours.isOpen ? LucideIcons.clock : LucideIcons.x,
                color: dayHours.isOpen
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editDayHours(BuildContext context, int dayNumber, String dayName) async {
    final DayHours currentHours = _weeklyHours[dayNumber]!;

    final DayHours? result = await showDialog<DayHours>(
      context: context,
      builder: (BuildContext context) =>
          _DayHoursDialog(dayName: dayName, initialHours: currentHours),
    );

    if (result != null) {
      setState(() {
        _weeklyHours[dayNumber] = result;
        _isModified = true;
      });
    }
  }

  void _copyBasicHours(BusinessHoursModel businessHours) {
    setState(() {
      for (int day = 1; day <= 7; day++) {
        final bool isOperating = businessHours.operatingDays?.contains(day) ?? false;
        if (isOperating) {
          final List<String> openParts = businessHours.openTime.split(":");
          final List<String> closeParts = businessHours.closeTime.split(":");
          _weeklyHours[day] = DayHours(
            openTime: TimeOfDay(hour: int.parse(openParts[0]), minute: int.parse(openParts[1])),
            closeTime: TimeOfDay(hour: int.parse(closeParts[0]), minute: int.parse(closeParts[1])),
            isOpen: true,
          );
        } else {
          _weeklyHours[day] = const DayHours(isOpen: false);
        }
      }
      _isModified = true;
    });
    _showSnackBar("基本営業時間をすべての曜日にコピーしました");
  }

  void _resetAllHours(BusinessHoursModel businessHours) {
    setState(() {
      _initializeWeeklyHours(businessHours);
      _isModified = false;
    });
  }

  Future<void> _saveWeeklyHours() async {
    try {
      // DayHoursをBusinessHoursDtoに変換
      final Map<int, BusinessHoursDto> weeklyHoursDto = <int, BusinessHoursDto>{};
      for (final MapEntry<int, DayHours> entry in _weeklyHours.entries) {
        final DayHours dayHours = entry.value;
        if (dayHours.isOpen && dayHours.openTime != null && dayHours.closeTime != null) {
          weeklyHoursDto[entry.key] = BusinessHoursDto(
            openTime:
                "${dayHours.openTime!.hour.toString().padLeft(2, '0')}:${dayHours.openTime!.minute.toString().padLeft(2, '0')}",
            closeTime:
                "${dayHours.closeTime!.hour.toString().padLeft(2, '0')}:${dayHours.closeTime!.minute.toString().padLeft(2, '0')}",
            isOpen: true,
            dayOfWeek: entry.key,
          );
        }
      }

      final Future<Map<int, BusinessHoursModel>> Function(Map<int, BusinessHoursDto> p1) update =
          ref.read(updateWeeklyBusinessHoursProvider);
      await update(weeklyHoursDto);

      setState(() {
        _isModified = false;
      });

      _showSnackBar("曜日別営業時間を更新しました");
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

/// 曜日の営業時間を表現するクラス
class DayHours {
  const DayHours({required this.isOpen, this.openTime, this.closeTime});
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final bool isOpen;

  DayHours copyWith({TimeOfDay? openTime, TimeOfDay? closeTime, bool? isOpen}) => DayHours(
    openTime: isOpen == false ? null : (openTime ?? this.openTime),
    closeTime: isOpen == false ? null : (closeTime ?? this.closeTime),
    isOpen: isOpen ?? this.isOpen,
  );
}

/// 曜日の営業時間編集ダイアログ
class _DayHoursDialog extends StatefulWidget {
  const _DayHoursDialog({required this.dayName, required this.initialHours});
  final String dayName;
  final DayHours initialHours;

  @override
  State<_DayHoursDialog> createState() => __DayHoursDialogState();
}

class __DayHoursDialogState extends State<_DayHoursDialog> {
  late bool _isOpen;
  late TimeOfDay _openTime;
  late TimeOfDay _closeTime;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.initialHours.isOpen;
    _openTime = widget.initialHours.openTime ?? const TimeOfDay(hour: 9, minute: 0);
    _closeTime = widget.initialHours.closeTime ?? const TimeOfDay(hour: 18, minute: 0);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text("${widget.dayName}の営業時間"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SwitchListTile(
          title: const Text("営業日"),
          subtitle: Text(_isOpen ? "営業します" : "休業日です"),
          value: _isOpen,
          onChanged: (bool value) {
            setState(() {
              _isOpen = value;
            });
          },
        ),

        if (_isOpen) ...<Widget>[
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(LucideIcons.sunrise),
            title: const Text("開店時間"),
            subtitle: Text(_openTime.format(context)),
            onTap: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: _openTime,
              );
              if (time != null) {
                setState(() {
                  _openTime = time;
                });
              }
            },
          ),

          ListTile(
            leading: const Icon(LucideIcons.sunset),
            title: const Text("閉店時間"),
            subtitle: Text(_closeTime.format(context)),
            onTap: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: _closeTime,
              );
              if (time != null) {
                setState(() {
                  _closeTime = time;
                });
              }
            },
          ),
        ],
      ],
    ),
    actions: <Widget>[
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("キャンセル")),
      ElevatedButton(
        onPressed: () {
          final DayHours result = DayHours(
            openTime: _isOpen ? _openTime : null,
            closeTime: _isOpen ? _closeTime : null,
            isOpen: _isOpen,
          );
          Navigator.of(context).pop(result);
        },
        child: const Text("保存"),
      ),
    ],
  );
}
