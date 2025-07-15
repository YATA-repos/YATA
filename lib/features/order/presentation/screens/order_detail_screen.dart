import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/layouts/responsive_padding.dart";
import "../../models/order_model.dart";
import "../../services/order_service.dart";

/// 注文詳細画面
///
/// 特定の注文の詳細情報を表示します。
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  Map<String, dynamic>? _orderData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // TODO: 実際のユーザーIDを取得
      const String userId = "current-user-id";

      final Map<String, dynamic>? orderData = await _orderService.getOrderWithItems(
        widget.orderId,
        userId,
      );

      setState(() {
        _orderData = orderData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "注文詳細の取得に失敗しました: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("注文詳細: #${widget.orderId}"),
      actions: <Widget>[
        if (_orderData != null && _canCancelOrder())
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: _showCancelDialog,
            tooltip: "注文をキャンセル",
          ),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("注文詳細を読み込み中..."),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(LucideIcons.alertTriangle, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadOrderDetails, child: const Text("再試行")),
          ],
        ),
      );
    }

    if (_orderData == null) {
      return const Center(child: Text("注文が見つかりません"));
    }

    return ResponsivePadding(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildOrderHeader(),
            const SizedBox(height: 24),
            _buildOrderItems(),
            const SizedBox(height: 24),
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildOrderTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    final Order order = Order.fromJson(_orderData!["order"] as Map<String, dynamic>);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "注文 #${widget.orderId}",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),
            if (order.customerName != null) ...<Widget>[
              Row(
                children: <Widget>[
                  const Icon(LucideIcons.user, size: 16),
                  const SizedBox(width: 8),
                  Text("顧客: ${order.customerName}"),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: <Widget>[
                const Icon(LucideIcons.clock, size: 16),
                const SizedBox(width: 8),
                Text("注文時刻: ${_formatDateTime(order.orderedAt)}"),
              ],
            ),
            if (order.notes != null) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(LucideIcons.messageSquare, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text("備考: ${order.notes}")),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.grey;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.preparing:
        color = Colors.orange;
        break;
      case OrderStatus.ready:
        color = Colors.green;
        break;
      case OrderStatus.delivered:
        color = Colors.purple;
        break;
      case OrderStatus.completed:
        color = Colors.green.shade700;
        break;
      case OrderStatus.canceled:
        color = Colors.red;
        break;
      case OrderStatus.refunded:
        color = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildOrderItems() {
    final List<dynamic> orderItems = _orderData!["order_items"] as List<dynamic>? ?? <dynamic>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "注文内容",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (orderItems.isEmpty)
              const Text("注文アイテムがありません")
            else
              ...orderItems.map((dynamic item) => _buildOrderItem(item as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item["menu_item_name"]?.toString() ?? "不明なアイテム",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (item["notes"] != null)
                Text(
                  item["notes"]?.toString() ?? "",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text("x${item["quantity"] ?? 1}", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 16),
        Text(
          "¥${item["price"] ?? 0}",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _buildOrderSummary() {
    final Order order = Order.fromJson(_orderData!["order"] as Map<String, dynamic>);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "支払い情報",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("小計:"),
                Text("¥${order.totalAmount + order.discountAmount}"),
              ],
            ),
            if (order.discountAmount > 0) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("割引:"),
                  Text("-¥${order.discountAmount}", style: const TextStyle(color: Colors.red)),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "合計:",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  "¥${order.totalAmount}",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Icon(LucideIcons.creditCard, size: 16),
                const SizedBox(width: 8),
                Text("支払い方法: ${_getPaymentMethodName(order.paymentMethod)}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline() {
    final Order order = Order.fromJson(_orderData!["order"] as Map<String, dynamic>);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "注文履歴",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem("注文受付", _formatDateTime(order.orderedAt), true),
            if (order.startedPreparingAt != null)
              _buildTimelineItem("調理開始", _formatDateTime(order.startedPreparingAt!), true),
            if (order.readyAt != null)
              _buildTimelineItem("調理完了", _formatDateTime(order.readyAt!), true),
            if (order.completedAt != null)
              _buildTimelineItem("配達完了", _formatDateTime(order.completedAt!), true),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isCompleted) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  bool _canCancelOrder() {
    if (_orderData == null) {
      return false;
    }
    final Order order = Order.fromJson(_orderData!["order"] as Map<String, dynamic>);
    return order.status == OrderStatus.pending || order.status == OrderStatus.confirmed;
  }

  void _showCancelDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("注文キャンセル"),
        content: const Text("この注文をキャンセルしますか？"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("いいえ")),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelOrder();
            },
            child: const Text("はい"),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    try {
      // TODO: 実際のユーザーIDを取得
      const String userId = "current-user-id";

      final (Order?, bool) result = await _orderService.cancelOrder(
        widget.orderId,
        "顧客都合により",
        userId,
      );

      if (result.$2) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("注文がキャンセルされました")));
          await _loadOrderDetails(); // 画面を更新
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("注文のキャンセルに失敗しました")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("エラー: $e")));
      }
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      "${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} "
      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return "現金";
      case PaymentMethod.card:
        return "カード";
      case PaymentMethod.other:
        return "その他";
    }
  }
}
