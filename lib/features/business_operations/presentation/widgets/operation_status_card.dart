import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/widgets/error_view.dart";
import "../../models/operation_status_model.dart";
import "../providers/business_operations_providers.dart";

/// 現在の営業状態を表示するカード
class OperationStatusCard extends ConsumerWidget {
  const OperationStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OperationStatusModel> operationStatusAsync = ref.watch(
      operationStatusProvider,
    );

    return operationStatusAsync.when(
      data: (OperationStatusModel status) => _buildStatusCard(context, status),
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
            message: "営業状態の読み込みに失敗しました",
            onRetry: () => ref.invalidate(operationStatusProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, OperationStatusModel status) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status.isOpen).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status.isOpen),
                    color: _getStatusColor(status.isOpen),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        status.isOpen ? "営業中" : "休業中",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status.isOpen),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(status),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (status.hasManualOverride) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "手動設定中${status.manualOverrideReason != null ? ': ${status.manualOverrideReason}' : ''}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: <Widget>[
                Expanded(
                  child: _buildInfoItem(
                    context,
                    "営業時間",
                    "${status.businessHours.openTime} - ${status.businessHours.closeTime}",
                    LucideIcons.clock,
                  ),
                ),
                Container(width: 1, height: 40, color: colorScheme.outline.withValues(alpha: 0.3)),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    "更新日時",
                    _formatDateTime(status.lastUpdated!),
                    LucideIcons.refreshCw,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor(bool isOpen) => isOpen ? Colors.green : Colors.red;

  IconData _getStatusIcon(bool isOpen) => isOpen ? LucideIcons.checkCircle : LucideIcons.xCircle;

  String _getStatusDescription(OperationStatusModel status) {
    if (status.hasManualOverride) {
      return "手動で設定されています";
    }

    if (status.isOpen) {
      return "通常営業しています";
    } else {
      return "営業時間外です";
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return "たった今";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}分前";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}時間前";
    } else {
      return "${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
  }
}
