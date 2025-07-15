import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../models/alert_model.dart";

/// アラートセクションウィジェット
///
/// ダッシュボードにシステムアラートを表示します。
class AlertsSection extends StatelessWidget {
  const AlertsSection({
    required this.alerts,
    required this.onAlertTap,
    required this.onMarkAsRead,
    required this.onDismiss,
    super.key,
  });

  final List<AlertModel> alerts;
  final void Function(String alertId, String? actionUrl) onAlertTap;
  final void Function(String alertId) onMarkAsRead;
  final void Function(String alertId) onDismiss;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "アラート",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (alerts.isNotEmpty)
            TextButton.icon(
              onPressed: () => _markAllAsRead(context),
              icon: const Icon(LucideIcons.checkCheck, size: 16),
              label: const Text("すべて既読"),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            ),
        ],
      ),

      const SizedBox(height: 16),

      if (alerts.isEmpty) _buildNoAlertsState(context) else _buildAlertsList(context),
    ],
  );

  Widget _buildNoAlertsState(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.checkCircle, color: Colors.green, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "すべて正常",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "現在、アラートはありません",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildAlertsList(BuildContext context) {
    // 重要度順でソート
    final List<AlertModel> sortedAlerts = List<AlertModel>.from(alerts)
      ..sort(
        (AlertModel a, AlertModel b) =>
            _getSeverityPriority(b.severity).compareTo(_getSeverityPriority(a.severity)),
      );

    return Column(
      children: sortedAlerts.map((AlertModel alert) => _buildAlertCard(context, alert)).toList(),
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertModel alert) {
    final _AlertInfo alertInfo = _getAlertInfo(alert.severity);

    return Dismissible(
      key: Key(alert.id!),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: <Widget>[
            Icon(LucideIcons.check, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "既読",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              "削除",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(LucideIcons.trash2, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (DismissDirection direction) {
        if (direction == DismissDirection.startToEnd) {
          onMarkAsRead(alert.id!);
        } else {
          onDismiss(alert.id!);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: alertInfo.backgroundColor,
        child: InkWell(
          onTap: () => onAlertTap(alert.id!, alert.actionUrl),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                // アラートアイコン
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alertInfo.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getAlertTypeIcon(alert.type), color: alertInfo.color, size: 20),
                ),

                const SizedBox(width: 16),

                // アラート内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              alert.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: alertInfo.textColor,
                              ),
                            ),
                          ),
                          if (!alert.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: alertInfo.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        alert.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: alertInfo.textColor.withValues(alpha: 0.8),
                        ),
                      ),

                      if (alert.createdAt != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          _formatAlertTime(alert.createdAt!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: alertInfo.textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // アクションボタン
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    color: alertInfo.textColor.withValues(alpha: 0.7),
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    if (!alert.isRead)
                      const PopupMenuItem<String>(
                        value: "mark_read",
                        child: Row(
                          children: <Widget>[
                            Icon(LucideIcons.check, size: 16),
                            SizedBox(width: 8),
                            Text("既読にする"),
                          ],
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: "dismiss",
                      child: Row(
                        children: <Widget>[
                          Icon(LucideIcons.x, size: 16),
                          SizedBox(width: 8),
                          Text("非表示"),
                        ],
                      ),
                    ),
                    if (alert.actionUrl != null)
                      const PopupMenuItem<String>(
                        value: "view_details",
                        child: Row(
                          children: <Widget>[
                            Icon(LucideIcons.externalLink, size: 16),
                            SizedBox(width: 8),
                            Text("詳細を見る"),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (String value) {
                    switch (value) {
                      case "mark_read":
                        onMarkAsRead(alert.id!);
                        break;
                      case "dismiss":
                        onDismiss(alert.id!);
                        break;
                      case "view_details":
                        onAlertTap(alert.id!, alert.actionUrl);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _markAllAsRead(BuildContext context) {
    final List<AlertModel> unreadAlerts = alerts
        .where((AlertModel alert) => !alert.isRead)
        .toList();
    if (unreadAlerts.isNotEmpty) {
      for (final AlertModel alert in unreadAlerts) {
        onMarkAsRead(alert.id!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${unreadAlerts.length}件のアラートを既読にしました"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  _AlertInfo _getAlertInfo(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return _AlertInfo(
          color: Colors.blue,
          backgroundColor: Colors.blue.withValues(alpha: 0.05),
          textColor: Colors.blue.shade800,
        );
      case AlertSeverity.warning:
        return _AlertInfo(
          color: Colors.orange,
          backgroundColor: Colors.orange.withValues(alpha: 0.05),
          textColor: Colors.orange.shade800,
        );
      case AlertSeverity.error:
        return _AlertInfo(
          color: Colors.red,
          backgroundColor: Colors.red.withValues(alpha: 0.05),
          textColor: Colors.red.shade800,
        );
      case AlertSeverity.critical:
        return _AlertInfo(
          color: Colors.red.shade700,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          textColor: Colors.red.shade900,
        );
    }
  }

  IconData _getAlertTypeIcon(String type) {
    switch (type) {
      case "low_stock":
        return LucideIcons.packageX;
      case "old_orders":
        return LucideIcons.clock;
      case "system_error":
        return LucideIcons.alertCircle;
      case "maintenance":
        return LucideIcons.wrench;
      default:
        return LucideIcons.alertTriangle;
    }
  }

  int _getSeverityPriority(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return 4;
      case AlertSeverity.error:
        return 3;
      case AlertSeverity.warning:
        return 2;
      case AlertSeverity.info:
        return 1;
    }
  }

  String _formatAlertTime(DateTime time) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes}分前";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}時間前";
    } else {
      return "${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }
}

/// アラート情報クラス
class _AlertInfo {
  const _AlertInfo({required this.color, required this.backgroundColor, required this.textColor});

  final Color color;
  final Color backgroundColor;
  final Color textColor;
}
