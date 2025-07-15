import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../models/alert_model.dart";
import "../../models/dashboard_stats_model.dart";
import "../../models/quick_stat_model.dart";

/// 統計カードセクションウィジェット
///
/// ダッシュボードの統計情報とクイック統計を表示します。
class StatsCardsSection extends StatelessWidget {
  const StatsCardsSection({required this.stats, super.key, this.quickStats});

  final DashboardStatsModel stats;
  final List<QuickStatModel>? quickStats;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "今日の統計",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 16),

        // メイン統計カード
        Row(
          children: <Widget>[
            Expanded(
              child: _buildMainStatCard(
                context,
                icon: LucideIcons.shoppingBag,
                title: "注文数",
                value: stats.todayOrders.toString(),
                subtitle: "今日",
                color: Colors.blue,
                trend: stats.ordersChangeRate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMainStatCard(
                context,
                icon: LucideIcons.dollarSign,
                title: "売上",
                value: "¥${_formatCurrency(stats.todayRevenue)}",
                subtitle: "今日",
                color: Colors.green,
                trend: stats.revenueChangeRate,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // サブ統計カード
        Row(
          children: <Widget>[
            Expanded(
              child: _buildSubStatCard(
                context,
                icon: LucideIcons.clock,
                title: "アクティブ注文",
                value: stats.activeOrders.toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSubStatCard(
                context,
                icon: LucideIcons.alertTriangle,
                title: "在庫不足",
                value: stats.lowStockItems.toString(),
                color: stats.lowStockItems > 0 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),

        // クイック統計（オプション）
        if (quickStats != null && quickStats!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          Text(
            "トレンド",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildQuickStatsGrid(context),
        ],
      ],
    );

  Widget _buildMainStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    double? trend,
  }) => Card(
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[color.withValues(alpha: 0.05), color.withValues(alpha: 0.02)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trend != null) _buildTrendIndicator(context, trend),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildSubStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );

  Widget _buildQuickStatsGrid(BuildContext context) => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: quickStats!.length,
      itemBuilder: (BuildContext context, int index) {
        final QuickStatModel stat = quickStats![index];
        return _buildQuickStatCard(context, stat);
      },
    );

  Widget _buildQuickStatCard(BuildContext context, QuickStatModel stat) {
    final Color trendColor = _getTrendColor(stat.trend);
    final IconData trendIcon = _getTrendIcon(stat.trend);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              stat.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            Text(
              stat.displayValue,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            Row(
              children: <Widget>[
                Icon(trendIcon, color: trendColor, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    stat.trendText,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: trendColor, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, double trend) {
    final Color color = trend > 0
        ? Colors.green
        : trend < 0
        ? Colors.red
        : Colors.grey;
    final IconData icon = trend > 0
        ? LucideIcons.trendingUp
        : trend < 0
        ? LucideIcons.trendingDown
        : LucideIcons.minus;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            "${trend.abs().toStringAsFixed(1)}%",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return Colors.green;
      case TrendDirection.down:
        return Colors.red;
      case TrendDirection.stable:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return LucideIcons.trendingUp;
      case TrendDirection.down:
        return LucideIcons.trendingDown;
      case TrendDirection.stable:
        return LucideIcons.minus;
    }
  }

  String _formatCurrency(double amount) => amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match match) => "${match[1]},");
}
