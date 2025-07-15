import "package:flutter/material.dart";

import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_badge.dart";
import "../../../../shared/widgets/common/app_card.dart";
import "../../../../shared/widgets/common/app_progress_bar.dart";

class KitchenStatusCard extends StatelessWidget {
  const KitchenStatusCard({
    required this.data,
    super.key,
    this.onTap,
    this.showDetails = true,
    this.variant = CardVariant.basic,
  });

  final KitchenStatusData data;
  final VoidCallback? onTap;
  final bool showDetails;
  final CardVariant variant;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: variant,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(),
        const SizedBox(height: AppLayout.spacing4),
        _buildMetrics(),
        if (showDetails) ...<Widget>[
          const SizedBox(height: AppLayout.spacing4),
          _buildProgressSection(),
          const SizedBox(height: AppLayout.spacing4),
          _buildAlertSection(),
        ],
      ],
    ),
  );

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      const Row(
        children: <Widget>[
          Icon(Icons.kitchen, color: AppColors.mutedForeground, size: AppLayout.iconSize),
          SizedBox(width: AppLayout.spacing2),
          Text(
            "キッチン状況",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
      AppBadge.text(_getStatusText(), variant: _getStatusBadgeVariant()),
    ],
  );

  Widget _buildMetrics() => Row(
    children: <Widget>[
      Expanded(
        child: _buildMetricItem(
          label: "待機中",
          value: data.pendingOrders.toString(),
          icon: Icons.schedule,
          color: AppColors.warning,
        ),
      ),
      const SizedBox(width: AppLayout.spacing4),
      Expanded(
        child: _buildMetricItem(
          label: "調理中",
          value: data.cookingOrders.toString(),
          icon: Icons.local_fire_department,
          color: AppColors.danger,
        ),
      ),
      const SizedBox(width: AppLayout.spacing4),
      Expanded(
        child: _buildMetricItem(
          label: "完了",
          value: data.completedOrders.toString(),
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
      ),
    ],
  );

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) => Container(
    padding: AppLayout.padding3,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppLayout.radiusMd,
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: <Widget>[
        Icon(icon, color: color, size: AppLayout.iconSizeMd),
        const SizedBox(height: AppLayout.spacing2),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
      ],
    ),
  );

  Widget _buildProgressSection() {
    final double totalOrders = (data.pendingOrders + data.cookingOrders + data.completedOrders)
        .toDouble();
    final double efficiency = totalOrders > 0 ? data.completedOrders / totalOrders : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              "調理効率",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
            Text(
              "${(efficiency * 100).toInt()}%",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.spacing2),
        AppProgressBar(
          value: efficiency,
          valueColor: _getEfficiencyColor(efficiency),
          backgroundColor: AppColors.muted,
        ),
        const SizedBox(height: AppLayout.spacing3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildTimeInfo(
              label: "平均調理時間",
              value: "${data.averageCookingTime}分",
              icon: Icons.timer,
            ),
            _buildTimeInfo(
              label: "最長待機",
              value: "${data.longestWaitTime}分",
              icon: Icons.hourglass_empty,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeInfo({required String label, required String value, required IconData icon}) =>
      Row(
        children: <Widget>[
          Icon(icon, size: AppLayout.iconSizeSm, color: AppColors.mutedForeground),
          const SizedBox(width: AppLayout.spacing1),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildAlertSection() {
    if (data.alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          "アラート",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground),
        ),
        const SizedBox(height: AppLayout.spacing2),
        ...data.alerts.map(_buildAlertItem),
      ],
    );
  }

  Widget _buildAlertItem(KitchenAlert alert) => Container(
    margin: const EdgeInsets.only(bottom: AppLayout.spacing2),
    padding: AppLayout.padding3,
    decoration: BoxDecoration(
      color: _getAlertColor(alert.type).withValues(alpha: 0.1),
      borderRadius: AppLayout.radiusSm,
      border: Border.all(color: _getAlertColor(alert.type).withValues(alpha: 0.3)),
    ),
    child: Row(
      children: <Widget>[
        Icon(
          _getAlertIcon(alert.type),
          size: AppLayout.iconSizeSm,
          color: _getAlertColor(alert.type),
        ),
        const SizedBox(width: AppLayout.spacing2),
        Expanded(
          child: Text(
            alert.message,
            style: TextStyle(fontSize: 12, color: _getAlertColor(alert.type)),
          ),
        ),
      ],
    ),
  );

  String _getStatusText() {
    final int totalActiveOrders = data.pendingOrders + data.cookingOrders;

    if (totalActiveOrders == 0) {
      return "アイドル";
    } else if (totalActiveOrders <= 5) {
      return "正常";
    } else if (totalActiveOrders <= 10) {
      return "忙しい";
    } else {
      return "過負荷";
    }
  }

  BadgeVariant _getStatusBadgeVariant() {
    final int totalActiveOrders = data.pendingOrders + data.cookingOrders;

    if (totalActiveOrders == 0) {
      return BadgeVariant.info;
    } else if (totalActiveOrders <= 5) {
      return BadgeVariant.success;
    } else if (totalActiveOrders <= 10) {
      return BadgeVariant.warning;
    } else {
      return BadgeVariant.danger;
    }
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 0.8) {
      return AppColors.success;
    } else if (efficiency >= 0.6) {
      return AppColors.warning;
    } else {
      return AppColors.danger;
    }
  }

  Color _getAlertColor(KitchenAlertType type) {
    switch (type) {
      case KitchenAlertType.warning:
        return AppColors.warning;
      case KitchenAlertType.error:
        return AppColors.danger;
      case KitchenAlertType.info:
        return AppColors.stockInfo;
    }
  }

  IconData _getAlertIcon(KitchenAlertType type) {
    switch (type) {
      case KitchenAlertType.warning:
        return Icons.warning;
      case KitchenAlertType.error:
        return Icons.error;
      case KitchenAlertType.info:
        return Icons.info;
    }
  }
}

class KitchenStatusData {
  const KitchenStatusData({
    required this.pendingOrders,
    required this.cookingOrders,
    required this.completedOrders,
    required this.averageCookingTime,
    required this.longestWaitTime,
    this.alerts = const <KitchenAlert>[],
    this.lastUpdate,
  });

  final int pendingOrders;
  final int cookingOrders;
  final int completedOrders;
  final double averageCookingTime; // minutes
  final double longestWaitTime; // minutes
  final List<KitchenAlert> alerts;
  final DateTime? lastUpdate;

  int get totalOrders => pendingOrders + cookingOrders + completedOrders;
  int get activeOrders => pendingOrders + cookingOrders;
  double get efficiency => totalOrders > 0 ? completedOrders / totalOrders : 0.0;

  KitchenStatusData copyWith({
    int? pendingOrders,
    int? cookingOrders,
    int? completedOrders,
    double? averageCookingTime,
    double? longestWaitTime,
    List<KitchenAlert>? alerts,
    DateTime? lastUpdate,
  }) => KitchenStatusData(
    pendingOrders: pendingOrders ?? this.pendingOrders,
    cookingOrders: cookingOrders ?? this.cookingOrders,
    completedOrders: completedOrders ?? this.completedOrders,
    averageCookingTime: averageCookingTime ?? this.averageCookingTime,
    longestWaitTime: longestWaitTime ?? this.longestWaitTime,
    alerts: alerts ?? this.alerts,
    lastUpdate: lastUpdate ?? this.lastUpdate,
  );
}

enum KitchenAlertType { warning, error, info }

class KitchenAlert {
  const KitchenAlert({required this.type, required this.message, this.timestamp});

  final KitchenAlertType type;
  final String message;
  final DateTime? timestamp;
}
