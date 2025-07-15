import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart";
import "../../../order/models/order_model.dart";

/// 最近の注文セクションウィジェット
///
/// ダッシュボードに最近の注文履歴を表示します。
class RecentOrdersSection extends StatelessWidget {
  const RecentOrdersSection({
    required this.orders,
    required this.onViewAll,
    required this.onOrderTap,
    super.key,
  });

  final List<Order> orders;
  final VoidCallback onViewAll;
  final void Function(String orderId) onOrderTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "最近の注文",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextButton.icon(
            onPressed: onViewAll,
            icon: const Icon(LucideIcons.externalLink, size: 16),
            label: const Text("すべて見る"),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),

      const SizedBox(height: 16),

      if (orders.isEmpty) _buildEmptyState(context) else _buildOrdersList(context),
    ],
  );

  Widget _buildEmptyState(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Icon(
            LucideIcons.inbox,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            "注文がありません",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "新しい注文を作成してください",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildOrdersList(BuildContext context) =>
      Column(children: orders.map((Order order) => _buildOrderCard(context, order)).toList());

  Widget _buildOrderCard(BuildContext context, Order order) {
    final _OrderStatusInfo statusInfo = _getOrderStatusInfo(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onOrderTap(order.id!),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              // ステータスアイコン
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusInfo.color.withValues(alpha: 0.3)),
                ),
                child: Icon(statusInfo.icon, color: statusInfo.color, size: 24),
              ),

              const SizedBox(width: 16),

              // 注文情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          order.orderNumber ?? "注文#${order.id?.substring(0, 8)}",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusInfo.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusInfo.label,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: statusInfo.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _getOrderItemsSummary(order),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: <Widget>[
                        Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatOrderTime(order.orderedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 金額と矢印
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "¥${_formatCurrency(order.totalAmount.toDouble())}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _OrderStatusInfo _getOrderStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _OrderStatusInfo(icon: LucideIcons.clock, label: "新規", color: Colors.blue);
      case OrderStatus.confirmed:
        return _OrderStatusInfo(
          icon: LucideIcons.checkCircle,
          label: "確認済み",
          color: Colors.blue.shade700,
        );
      case OrderStatus.preparing:
        return _OrderStatusInfo(icon: LucideIcons.chefHat, label: "調理中", color: Colors.orange);
      case OrderStatus.ready:
        return _OrderStatusInfo(icon: LucideIcons.checkCircle, label: "準備完了", color: Colors.green);
      case OrderStatus.delivered:
        return _OrderStatusInfo(icon: LucideIcons.utensils, label: "提供済み", color: Colors.teal);
      case OrderStatus.completed:
        return _OrderStatusInfo(icon: LucideIcons.check, label: "完了", color: Colors.green.shade700);
      case OrderStatus.canceled:
        return _OrderStatusInfo(icon: LucideIcons.x, label: "キャンセル", color: Colors.red);
      case OrderStatus.refunded:
        return _OrderStatusInfo(icon: LucideIcons.arrowLeft, label: "返金済み", color: Colors.grey);
    }
  }

  // ! FIXME
  // 実際の実装ではOrderItemsを取得する必要があります
  // ここでは仮の実装として簡単な説明を返します
  String _getOrderItemsSummary(Order order) => "注文アイテム ${order.totalAmount > 1000 ? '複数' : '1'}点";

  String _formatOrderTime(DateTime orderTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(orderTime);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes}分前";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}時間前";
    } else {
      return "${orderTime.month}/${orderTime.day} ${orderTime.hour.toString().padLeft(2, '0')}:${orderTime.minute.toString().padLeft(2, '0')}";
    }
  }

  String _formatCurrency(double amount) => amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match match) => "${match[1]},");
}

/// 注文ステータス情報クラス
class _OrderStatusInfo {
  const _OrderStatusInfo({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;
}
