import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/widgets/cards/app_card.dart";
import "../../../../shared/widgets/common/loading_indicator.dart";
import "../../dto/inventory_dto.dart";
import "../providers/inventory_alert_providers.dart";

/// 拡張アラートパネル
class EnhancedAlertPanel extends ConsumerWidget {
  const EnhancedAlertPanel({
    required this.userId, super.key,
    this.showSettings = true,
    this.onMaterialTap,
    this.maxHeight,
  });

  final String userId;
  final bool showSettings;
  final void Function(MaterialStockInfo)? onMaterialTap;
  final double? maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AlertStatistics> alertStatistics = ref.watch(alertStatisticsProvider(userId));
    final InventoryAlertSettings settings = ref.watch(inventoryAlertSettingsNotifierProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ヘッダー
          Row(
            children: <Widget>[
              const Icon(LucideIcons.bell, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "在庫アラート",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showSettings)
                IconButton(
                  onPressed: () => _showAlertSettings(context, ref),
                  icon: const Icon(LucideIcons.settings),
                  tooltip: "アラート設定",
                ),
              IconButton(
                onPressed: () => ref.read(alertWatcherProvider.notifier).refresh(),
                icon: const Icon(LucideIcons.refreshCw),
                tooltip: "更新",
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 統計情報
          alertStatistics.when(
            data: (AlertStatistics stats) => _buildStatisticsRow(context, stats),
            loading: () => const LoadingIndicator(),
            error: (Object error, _) => _buildErrorWidget(error),
          ),
          const SizedBox(height: 16),

          // アラート一覧
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight ?? 300,
              ),
              child: _buildAlertList(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  /// 統計情報行を構築
  Widget _buildStatisticsRow(BuildContext context, AlertStatistics stats) => Row(
      children: <Widget>[
        _buildStatCard(
          "総計",
          "${stats.totalAlerts}",
          LucideIcons.alertCircle,
          stats.hasAlerts ? Colors.orange : Colors.green,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          "緊急",
          "${stats.criticalCount}",
          LucideIcons.alertTriangle,
          stats.hasCriticalAlerts ? Colors.red : Colors.grey,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          "低在庫",
          "${stats.lowStockCount}",
          LucideIcons.trendingDown,
          stats.lowStockCount > 0 ? Colors.yellow.shade700 : Colors.grey,
        ),
      ],
    );

  /// 統計カードを構築
  Widget _buildStatCard(String label, String value, IconData icon, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );

  /// アラート一覧を構築
  Widget _buildAlertList(BuildContext context, WidgetRef ref) {
    final AsyncValue<Map<String, List<MaterialStockInfo>>> filteredAlerts = ref.watch(filteredInventoryAlertsProvider(userId));

    return filteredAlerts.when(
      data: (Map<String, List<MaterialStockInfo>> alerts) {
        final List<MaterialStockInfo> allAlerts = <MaterialStockInfo>[
          ...alerts["critical"] ?? <MaterialStockInfo>[],
          ...alerts["low"] ?? <MaterialStockInfo>[],
        ];

        if (allAlerts.isEmpty) {
          return _buildNoAlertsWidget();
        }

        return ListView.separated(
          itemCount: allAlerts.length,
          separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final MaterialStockInfo alert = allAlerts[index];
            return _buildAlertItem(context, alert);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (Object error, _) => _buildErrorWidget(error),
    );
  }

  /// アラート項目を構築
  Widget _buildAlertItem(BuildContext context, MaterialStockInfo alert) {
    final String priority = _getAlertPriority(alert);
    final Color priorityColor = _getPriorityColor(priority);

    return InkWell(
      onTap: onMaterialTap != null ? () => onMaterialTap!(alert) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: <Widget>[
            // 優先度インジケーター
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // 材料情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    alert.material.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Text(
                        "在庫: ${alert.material.currentStock.toStringAsFixed(1)} ${alert.material.unitType.name}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (alert.estimatedUsageDays != null) ...<Widget>[
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.calendar,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "${alert.estimatedUsageDays}日",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ステータスアイコン
            Icon(
              _getStatusIcon(alert.stockLevel),
              color: priorityColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// アラートなしウィジェットを構築
  Widget _buildNoAlertsWidget() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            LucideIcons.checkCircle,
            size: 48,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            "アラートはありません",
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade700,
            ),
          ),
          Text(
            "在庫レベルは正常です",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );

  /// エラーウィジェットを構築
  Widget _buildErrorWidget(Object error) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            "アラート取得エラー",
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade700,
            ),
          ),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

  /// アラート設定ダイアログを表示
  void _showAlertSettings(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _AlertSettingsDialog(userId: userId),
    );
  }

  /// アラート優先度を取得
  String _getAlertPriority(MaterialStockInfo alert) {
    if (alert.stockLevel == StockLevel.critical) {
      return "緊急";
    } else if (alert.stockLevel == StockLevel.low) {
      return "警告";
    }
    return "注意";
  }

  /// 優先度色を取得
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case "緊急":
        return Colors.red;
      case "警告":
        return Colors.orange;
      case "注意":
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  /// ステータスアイコンを取得
  IconData _getStatusIcon(StockLevel level) {
    switch (level) {
      case StockLevel.critical:
        return LucideIcons.alertTriangle;
      case StockLevel.low:
        return LucideIcons.alertCircle;
      case StockLevel.sufficient:
        return LucideIcons.checkCircle;
    }
  }
}

/// アラート設定ダイアログ
class _AlertSettingsDialog extends ConsumerWidget {
  const _AlertSettingsDialog({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryAlertSettings settings = ref.watch(inventoryAlertSettingsNotifierProvider);
    final InventoryAlertSettingsNotifier notifier = ref.read(inventoryAlertSettingsNotifierProvider.notifier);

    return AlertDialog(
      title: const Text("アラート設定"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SwitchListTile(
            title: const Text("緊急アラート"),
            subtitle: const Text("危険閾値以下の材料を表示"),
            value: settings.enableCriticalAlerts,
            onChanged: (_) => notifier.toggleCriticalAlerts(),
          ),
          SwitchListTile(
            title: const Text("低在庫アラート"),
            subtitle: const Text("アラート閾値以下の材料を表示"),
            value: settings.enableLowStockAlerts,
            onChanged: (_) => notifier.toggleLowStockAlerts(),
          ),
          SwitchListTile(
            title: const Text("使用可能日数アラート"),
            subtitle: Text("${settings.usageDayThreshold}日以内に不足予想の材料を表示"),
            value: settings.enableUsageDayAlerts,
            onChanged: (_) => notifier.toggleUsageDayAlerts(),
          ),
          if (settings.enableUsageDayAlerts) ...<Widget>[
            const SizedBox(height: 16),
            Text("使用可能日数の閾値: ${settings.usageDayThreshold}日"),
            Slider(
              value: settings.usageDayThreshold.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (double value) => notifier.setUsageDayThreshold(value.round()),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text("自動更新"),
            subtitle: const Text("5分間隔で自動更新"),
            value: settings.autoRefreshEnabled,
            onChanged: (_) => notifier.toggleAutoRefresh(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("閉じる"),
        ),
      ],
    );
  }
}