import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/layouts/responsive_padding.dart";
import "../../../../shared/widgets/error_view.dart";
import "../../dto/business_hours_dto.dart";
import "../../models/business_hours_model.dart";
import "../../models/operation_status_model.dart";
import "../providers/business_operations_providers.dart";
import "../widgets/index.dart";

/// 営業時間設定画面
///
/// 営業時間と営業状態の管理を行います。
class BusinessHoursScreen extends ConsumerStatefulWidget {
  const BusinessHoursScreen({super.key});

  @override
  ConsumerState<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends ConsumerState<BusinessHoursScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("営業時間管理"),
      actions: <Widget>[
        IconButton(
          onPressed: _showBusinessHoursHelp,
          icon: const Icon(LucideIcons.helpCircle),
          tooltip: "ヘルプ",
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const <Widget>[
          Tab(icon: Icon(LucideIcons.clock), text: "営業状態"),
          Tab(icon: Icon(LucideIcons.calendar), text: "営業時間設定"),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: <Widget>[_buildOperationStatusTab(), _buildBusinessHoursTab()],
    ),
  );

  Widget _buildOperationStatusTab() => ResponsivePadding(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 16),

          // 現在の営業状態
          const OperationStatusCard(),

          const SizedBox(height: 24),

          // クイックアクション
          Text(
            "クイックアクション",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          _buildQuickActions(),

          const SizedBox(height: 24),

          // 営業統計
          Text(
            "営業統計",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          _buildOperationStatistics(),
        ],
      ),
    ),
  );

  Widget _buildBusinessHoursTab() => ResponsivePadding(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 16),

          // 基本営業時間設定
          Text(
            "基本営業時間",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          const BusinessHoursEditor(),

          const SizedBox(height: 24),

          // 曜日別営業時間
          Text(
            "曜日別営業時間",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 4),

          Text(
            "曜日ごとに異なる営業時間を設定できます",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 16),

          const WeeklyHoursGrid(),

          const SizedBox(height: 24),

          // 営業時間テンプレート
          _buildBusinessHoursTemplates(),
        ],
      ),
    ),
  );

  Widget _buildQuickActions() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 2.5,
    children: <Widget>[
      _buildQuickActionCard(
        icon: LucideIcons.power,
        title: "営業状態切り替え",
        subtitle: "手動で営業/休業を切り替え",
        color: Colors.blue,
        onTap: _toggleOperationStatus,
      ),
      _buildQuickActionCard(
        icon: LucideIcons.clock,
        title: "臨時休業",
        subtitle: "一時的に休業状態に設定",
        color: Colors.orange,
        onTap: _setTemporaryClose,
      ),
      _buildQuickActionCard(
        icon: LucideIcons.zap,
        title: "緊急営業",
        subtitle: "営業時間外でも営業開始",
        color: Colors.green,
        onTap: _setEmergencyOpen,
      ),
      _buildQuickActionCard(
        icon: LucideIcons.rotateCcw,
        title: "自動設定に戻す",
        subtitle: "手動設定を解除",
        color: Colors.grey,
        onTap: _clearManualOverride,
      ),
    ],
  );

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildOperationStatistics() {
    final AsyncValue<Map<String, dynamic>> statisticsAsync = ref.watch(
      operationStatisticsProvider(30),
    );

    return statisticsAsync.when(
      data: (Map<String, dynamic> stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "過去30日の統計",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildStatItem(
                      "状態変更回数",
                      "${stats['total_status_changes']}回",
                      LucideIcons.activity,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      "手動変更率",
                      "${(stats['manual_override_rate'] * 100).toStringAsFixed(1)}%",
                      LucideIcons.hand,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (Object error, StackTrace stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorView(
            message: "統計の読み込みに失敗しました",
            onRetry: () => ref.invalidate(operationStatisticsProvider(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) => Column(
    children: <Widget>[
      Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 8),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _buildBusinessHoursTemplates() {
    final List<BusinessHoursTemplate> templates = ref.watch(businessHoursTemplatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "営業時間テンプレート",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 4),

        Text(
          "よく使用される営業時間設定から選択できます",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
          ),
          itemCount: templates.length,
          itemBuilder: (BuildContext context, int index) {
            final BusinessHoursTemplate template = templates[index];
            return _buildTemplateCard(template);
          },
        ),
      ],
    );
  }

  Widget _buildTemplateCard(BusinessHoursTemplate template) => Card(
    child: InkWell(
      onTap: () => _applyTemplate(template),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              template.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "${template.openTime} - ${template.closeTime}",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const Spacer(),
            Text(
              template.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _toggleOperationStatus() async {
    try {
      final Future<OperationStatusModel> Function({String? reason}) toggle = ref.read(
        toggleOperationStatusProvider,
      );
      await toggle();
      _showSnackBar("営業状態を切り替えました");
    } catch (e) {
      _showSnackBar("営業状態の切り替えに失敗しました: $e");
    }
  }

  Future<void> _setTemporaryClose() async {
    final DateTime? reopenTime = await _showReopenTimeDialog();
    if (reopenTime != null) {
      try {
        final Future<OperationStatusModel> Function({required DateTime reopenTime, String? reason})
        setClose = ref.read(setTemporaryCloseProvider);
        await setClose(reopenTime: reopenTime, reason: "臨時休業");
        _showSnackBar("臨時休業を設定しました");
      } catch (e) {
        _showSnackBar("臨時休業の設定に失敗しました: $e");
      }
    }
  }

  Future<void> _setEmergencyOpen() async {
    try {
      final Future<OperationStatusModel> Function({String? reason}) setOpen = ref.read(
        setEmergencyOpenProvider,
      );
      await setOpen(reason: "緊急営業");
      _showSnackBar("緊急営業を設定しました");
    } catch (e) {
      _showSnackBar("緊急営業の設定に失敗しました: $e");
    }
  }

  Future<void> _clearManualOverride() async {
    try {
      final Future<OperationStatusModel> Function() clear = ref.read(clearManualOverrideProvider);
      await clear();
      _showSnackBar("自動設定に戻しました");
    } catch (e) {
      _showSnackBar("設定の変更に失敗しました: $e");
    }
  }

  Future<void> _applyTemplate(BusinessHoursTemplate template) async {
    try {
      final Future<BusinessHoursModel> Function(BusinessHoursDto p1) update = ref.read(
        updateBusinessHoursProvider,
      );
      await update(template.toDto());
      _showSnackBar("営業時間テンプレートを適用しました");
    } catch (e) {
      _showSnackBar("テンプレートの適用に失敗しました: $e");
    }
  }

  Future<DateTime?> _showReopenTimeDialog() async {
    final DateTime now = DateTime.now();
    DateTime selectedDate = now.add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("再開予定時刻を設定"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(LucideIcons.calendar),
              title: Text("日付: ${selectedDate.year}/${selectedDate.month}/${selectedDate.day}"),
              onTap: () async {
                final DateTime? date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 30)),
                );
                if (date != null) {
                  selectedDate = date;
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.clock),
              title: Text("時間: ${selectedTime.format(context)}"),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (time != null) {
                  selectedTime = time;
                }
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () {
              final DateTime reopenDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              Navigator.of(context).pop(reopenDateTime);
            },
            child: const Text("設定"),
          ),
        ],
      ),
    );
  }

  void _showBusinessHoursHelp() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("営業時間管理について"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("【営業状態】"),
              Text("• 現在の営業状況を確認・変更できます"),
              Text("• 手動で営業/休業の切り替えが可能です"),
              SizedBox(height: 12),
              Text("【営業時間設定】"),
              Text("• 基本的な営業時間を設定できます"),
              Text("• 曜日ごとに異なる時間を設定可能です"),
              Text("• テンプレートから選択することもできます"),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("閉じる")),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}
