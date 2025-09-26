import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/components/inputs/search_field.dart";
import "../../../../shared/components/inputs/segmented_filter.dart";
import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/components/layout/section_card.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/patterns/patterns.dart";
import "../../../../core/constants/enums.dart";
import "../../data/mock_order_history_data.dart";
import "../../models/order_model.dart";

/// 注文履歴ページ。
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  static const String routeName = "/history";

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  OrderStatus? _selectedStatus;
  List<Order> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _filteredOrders = MockOrderHistoryData.mockOrderHistory;
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      List<Order> orders = MockOrderHistoryData.mockOrderHistory;

      // ステータスフィルタ
      if (_selectedStatus != null) {
        orders = orders.where((Order order) => order.status == _selectedStatus).toList();
      }

      // 検索フィルタ
      if (_searchController.text.isNotEmpty) {
        final String searchTerm = _searchController.text.toLowerCase();
        orders = orders.where((Order order) {
          return (order.orderNumber?.toLowerCase().contains(searchTerm) ?? false) ||
                 (order.customerName?.toLowerCase().contains(searchTerm) ?? false) ||
                 (order.notes?.toLowerCase().contains(searchTerm) ?? false);
        }).toList();
      }

      // 日時の降順でソート
      orders.sort((Order a, Order b) => b.orderedAt.compareTo(a.orderedAt));
      _filteredOrders = orders;
    });
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _selectedStatus = value != null ? OrderStatus.values.firstWhere((OrderStatus s) => s.value == value) : null;
    });
    _applyFilters();
  }

  void _onOrderTap(Order order) {
    _showOrderDetails(order);
  }

  void _showOrderDetails(Order order) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _OrderDetailsDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: YataColorTokens.background,
    appBar: YataAppTopBar(
      navItems: <YataNavItem>[
        YataNavItem(label: "注文", icon: Icons.shopping_cart_outlined, onTap: () => context.go("/")),
        const YataNavItem(label: "履歴", icon: Icons.receipt_long_outlined, isActive: true),
        YataNavItem(
          label: "在庫管理",
          icon: Icons.inventory_2_outlined,
          onTap: () => context.go("/inventory"),
        ),
        const YataNavItem(label: "売上分析", icon: Icons.query_stats_outlined),
      ],
    ),
    body: YataPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: YataSpacingTokens.lg),
          // 統計情報カード
          _StatisticsSection(),
          const SizedBox(height: YataSpacingTokens.lg),
          // フィルターセクション
          _FiltersSection(
            searchController: _searchController,
            selectedStatus: _selectedStatus,
            onStatusChanged: _onStatusFilterChanged,
          ),
          const SizedBox(height: YataSpacingTokens.lg),
          // 注文履歴一覧
          Expanded(
            child: _OrderHistoryList(
              orders: _filteredOrders,
              onOrderTap: _onOrderTap,
            ),
          ),
        ],
      ),
    ),
  );
}

/// 統計情報セクション
class _StatisticsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> stats = MockOrderHistoryData.statistics;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            title: "総注文数",
            value: "${stats['totalOrders']}件",
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: YataSpacingTokens.md),
        Expanded(
          child: _StatCard(
            title: "完了注文",
            value: "${stats['completedOrders']}件",
            icon: Icons.check_circle_outline,
            color: YataColorTokens.success,
          ),
        ),
        const SizedBox(width: YataSpacingTokens.md),
        Expanded(
          child: _StatCard(
            title: "売上合計",
            value: "¥${_formatCurrency(stats['totalRevenue'] as int)}",
            icon: Icons.payments_outlined,
            color: YataColorTokens.primary,
          ),
        ),
        const SizedBox(width: YataSpacingTokens.md),
        Expanded(
          child: _StatCard(
            title: "平均単価",
            value: "¥${_formatCurrency(stats['averageOrderValue'] as int)}",
            icon: Icons.trending_up_outlined,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => "${match[1]},",
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color = YataColorTokens.textSecondary,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return YataSectionCard(
      padding: const EdgeInsets.all(YataSpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: YataSpacingTokens.xs),
              Expanded(
                child: Text(
                  title,
                  style: (textTheme.labelMedium ?? YataTypographyTokens.labelMedium)
                      .copyWith(color: YataColorTokens.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          Text(
            value,
            style: (textTheme.titleLarge ?? YataTypographyTokens.titleLarge)
                .copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

/// フィルターセクション
class _FiltersSection extends StatelessWidget {
  const _FiltersSection({
    required this.searchController,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final OrderStatus? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return YataSectionCard(
      title: "フィルター",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 検索フィールド
          YataSearchField(
            controller: searchController,
            hintText: "注文番号、顧客名、備考で検索...",
          ),
          const SizedBox(height: YataSpacingTokens.md),
          // ステータスフィルター
          YataSegmentedFilter<String>(
            label: "ステータス",
            value: selectedStatus?.value,
            items: <YataSegmentedFilterItem<String>>[
              const YataSegmentedFilterItem<String>(value: null, label: "すべて"),
              ...OrderStatus.values.map(
                (OrderStatus status) => YataSegmentedFilterItem<String>(
                  value: status.value,
                  label: status.displayName,
                ),
              ),
            ],
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

/// 注文履歴一覧
class _OrderHistoryList extends StatelessWidget {
  const _OrderHistoryList({
    required this.orders,
    required this.onOrderTap,
  });

  final List<Order> orders;
  final ValueChanged<Order> onOrderTap;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return YataSectionCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(YataSpacingTokens.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: YataColorTokens.textSecondary,
                ),
                const SizedBox(height: YataSpacingTokens.md),
                Text(
                  "該当する注文履歴がありません",
                  style: YataTypographyTokens.titleMedium.copyWith(
                    color: YataColorTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return YataSectionCard(
      title: "注文履歴 (${orders.length}件)",
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (BuildContext context, int index) {
          final Order order = orders[index];
          return YataOrderHistoryTile(
            order: order,
            onTap: () => onOrderTap(order),
            showDivider: index < orders.length - 1,
          );
        },
      ),
    );
  }
}

/// 注文詳細ダイアログ
class _OrderDetailsDialog extends StatelessWidget {
  const _OrderDetailsDialog({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final List<OrderItem> orderItems = MockOrderHistoryData.getOrderItems(order.id!);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(YataSpacingTokens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "注文詳細 - ${order.orderNumber ?? order.id}",
                  style: textTheme.titleLarge ?? YataTypographyTokens.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            // 注文基本情報
            _OrderBasicInfo(order: order),
            const SizedBox(height: YataSpacingTokens.lg),
            // 注文明細
            Text(
              "注文明細",
              style: textTheme.titleMedium ?? YataTypographyTokens.titleMedium,
            ),
            const SizedBox(height: YataSpacingTokens.md),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: orderItems.length,
                itemBuilder: (BuildContext context, int index) {
                  final OrderItem item = orderItems[index];
                  final String menuName = MockOrderHistoryData.getMenuItemName(item.menuItemId);
                  return _OrderItemRow(
                    menuName: menuName,
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                    subtotal: item.subtotal,
                  );
                },
              ),
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            // 合計
            _OrderTotal(order: order),
          ],
        ),
      ),
    );
  }
}

/// 注文基本情報
class _OrderBasicInfo extends StatelessWidget {
  const _OrderBasicInfo({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    
    String formatDateTime(DateTime dateTime) {
      return "${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} "
             "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    }

    String paymentMethodName;
    switch (order.paymentMethod) {
      case PaymentMethod.cash:
        paymentMethodName = "現金";
        break;
      case PaymentMethod.card:
        paymentMethodName = "カード";
        break;
      case PaymentMethod.other:
        paymentMethodName = "その他";
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _InfoRow(label: "ステータス", value: order.status.displayName),
        _InfoRow(label: "注文日時", value: formatDateTime(order.orderedAt)),
        if (order.customerName != null)
          _InfoRow(label: "顧客名", value: order.customerName!),
        _InfoRow(label: "支払い方法", value: paymentMethodName),
        if (order.notes != null && order.notes!.isNotEmpty)
          _InfoRow(label: "備考", value: order.notes!),
        if (order.completedAt != null)
          _InfoRow(label: "完了日時", value: formatDateTime(order.completedAt!)),
      ],
    );
  }
}

/// 情報行
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: (textTheme.labelMedium ?? YataTypographyTokens.labelMedium)
                  .copyWith(color: YataColorTokens.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// 注文明細行
class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String menuName;
  final int quantity;
  final int unitPrice;
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    
    String formatCurrency(int amount) {
      return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match match) => "${match[1]},",
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              menuName,
              style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
            ),
          ),
          const SizedBox(width: YataSpacingTokens.md),
          SizedBox(
            width: 60,
            child: Text(
              "${quantity}個",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
            ),
          ),
          const SizedBox(width: YataSpacingTokens.md),
          SizedBox(
            width: 80,
            child: Text(
              "¥${formatCurrency(unitPrice)}",
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
            ),
          ),
          const SizedBox(width: YataSpacingTokens.md),
          SizedBox(
            width: 80,
            child: Text(
              "¥${formatCurrency(subtotal)}",
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// 注文合計
class _OrderTotal extends StatelessWidget {
  const _OrderTotal({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    
    String formatCurrency(int amount) {
      return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match match) => "${match[1]},",
      );
    }

    return Container(
      padding: const EdgeInsets.all(YataSpacingTokens.md),
      decoration: BoxDecoration(
        color: YataColorTokens.backgroundSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        children: <Widget>[
          if (order.discountAmount > 0) ...<Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "小計",
                  style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
                ),
                Text(
                  "¥${formatCurrency(order.totalAmount + order.discountAmount)}",
                  style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "割引",
                  style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium)
                      .copyWith(color: YataColorTokens.error),
                ),
                Text(
                  "-¥${formatCurrency(order.discountAmount)}",
                  style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium)
                      .copyWith(color: YataColorTokens.error),
                ),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            const Divider(),
            const SizedBox(height: YataSpacingTokens.xs),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "合計",
                style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                "¥${formatCurrency(order.totalAmount)}",
                style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
