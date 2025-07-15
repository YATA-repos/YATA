import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart";
import "../../../../routing/route_constants.dart";
import "../../../../shared/layouts/responsive_padding.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "../../services/order_service.dart";

/// 注文一覧画面
///
/// すべての注文の一覧表示と管理機能を提供します。
class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  List<Order> _orders = <Order>[];
  String _selectedFilter = "all";
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          _currentPage = 1;
          _hasMoreData = true;
          _error = null;
        });
      }

      setState(() {
        _isLoading = isRefresh ? false : _isLoading;
        _isSearching = isRefresh;
      });

      // TODO: 実際のユーザーIDを取得
      const String userId = "current-user-id";

      // 検索リクエストを構築
      final OrderSearchRequest request = OrderSearchRequest(
        page: _currentPage,
        limit: 20,
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        statusFilter: _selectedFilter == "all" ? null : _getStatusFilter(),
      );

      final Map<String, dynamic> result = await _orderService.getOrderHistory(request, userId);

      final List<Order> orders = (result["orders"] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic order) => Order.fromJson(order as Map<String, dynamic>))
          .toList();

      setState(() {
        if (isRefresh) {
          _orders = orders;
        } else {
          _orders.addAll(orders);
        }
        _hasMoreData = orders.length == 20; // ページサイズと同じ場合はまだデータがある可能性
        _isLoading = false;
        _isSearching = false;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _error = "注文データの取得に失敗しました: $e";
        _isLoading = false;
        _isSearching = false;
      });
    }
  }

  List<OrderStatus>? _getStatusFilter() {
    switch (_selectedFilter) {
      case "active":
        return <OrderStatus>[
          OrderStatus.pending,
          OrderStatus.confirmed,
          OrderStatus.preparing,
          OrderStatus.ready,
        ];
      case "completed":
        return <OrderStatus>[OrderStatus.completed, OrderStatus.delivered];
      default:
        return null;
    }
  }

  Future<void> _refreshOrders() async {
    await _loadOrders(isRefresh: true);
  }

  void _onSearchChanged() {
    // デバウンス実装（500ms後に検索実行）
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _refreshOrders();
      }
    });
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _refreshOrders();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("注文一覧"),
      actions: <Widget>[
        IconButton(
          icon: const Icon(LucideIcons.refreshCw),
          onPressed: _isLoading ? null : _refreshOrders,
          tooltip: "更新",
        ),
        IconButton(
          icon: const Icon(LucideIcons.plus),
          onPressed: () => context.go(AppRoutes.orderCreate),
          tooltip: "新規注文",
        ),
      ],
    ),
    body: _buildBody(),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.go(AppRoutes.orderCreate),
      icon: const Icon(LucideIcons.plus),
      label: const Text("新規注文"),
    ),
  );

  Widget _buildBody() {
    if (_isLoading && _orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("注文一覧を読み込み中..."),
          ],
        ),
      );
    }

    if (_error != null && _orders.isEmpty) {
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
            ElevatedButton(onPressed: _refreshOrders, child: const Text("再試行")),
          ],
        ),
      );
    }

    return ResponsivePadding(
      child: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: CustomScrollView(
          slivers: <Widget>[
            // フィルター・検索バー
            _buildFilterSection(),

            // 注文リスト
            _buildOrderList(),

            // ローディングインジケーター（ページネーション）
            if (_isSearching)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// フィルターセクションを構築
  Widget _buildFilterSection() => SliverToBoxAdapter(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "注文番号や顧客名で検索...",
                    prefixIcon: const Icon(LucideIcons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x),
                            onPressed: () {
                              _searchController.clear();
                              _refreshOrders();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (String value) => _onSearchChanged(),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.filter,
                  color: _selectedFilter != "all" ? Theme.of(context).colorScheme.primary : null,
                ),
                onSelected: _onFilterChanged,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: "all",
                    child: Row(
                      children: <Widget>[
                        if (_selectedFilter == "all")
                          const Icon(LucideIcons.check, size: 16)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        const Text("すべて"),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: "active",
                    child: Row(
                      children: <Widget>[
                        if (_selectedFilter == "active")
                          const Icon(LucideIcons.check, size: 16)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        const Text("進行中"),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: "completed",
                    child: Row(
                      children: <Widget>[
                        if (_selectedFilter == "completed")
                          const Icon(LucideIcons.check, size: 16)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        const Text("完了済み"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_error != null && _orders.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    LucideIcons.alertTriangle,
                    size: 16,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "データの更新に失敗しました",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _refreshOrders, child: const Text("再試行")),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );

  /// 注文リストを構築
  Widget _buildOrderList() {
    if (_orders.isEmpty && !_isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              Icon(
                LucideIcons.inbox,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text("注文がありません", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty ? "検索条件に一致する注文が見つかりません" : "新しい注文を作成してください",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.orderCreate),
                icon: const Icon(LucideIcons.plus),
                label: const Text("新規注文"),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        if (index >= _orders.length) {
          // 最後のアイテムに到達した場合、さらにデータを読み込む
          if (_hasMoreData && !_isSearching) {
            Future<void>.microtask(_loadOrders);
          }
          return null;
        }

        final Order order = _orders[index];
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildOrderCard(order));
      }, childCount: _orders.length + (_hasMoreData ? 1 : 0)),
    );
  }

  /// 注文カードを構築
  Widget _buildOrderCard(Order order) {
    final Color statusColor = _getStatusColor(order.status);
    final IconData statusIcon = _getStatusIcon(order.status);
    final String formattedTime = _formatDateTime(order.orderedAt);
    final String formattedAmount =
        "¥${order.totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => "${match[1]},")}";

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (order.id != null) {
            context.go(AppRoutes.orderDetail.replaceFirst(":orderId", order.id!));
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              // ステータスインジケーター
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 16),

              // 注文情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "#${order.id?.substring(0, 8) ?? "unknown"}",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          formattedAmount,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          order.customerName ?? "顧客名なし",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          formattedTime,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        order.status.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 詳細アイコン
              Icon(LucideIcons.chevronRight, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  /// ステータスに応じた色を取得
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.grey;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green.shade700;
      case OrderStatus.canceled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.grey.shade600;
    }
  }

  /// ステータスに応じたアイコンを取得
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return LucideIcons.clock;
      case OrderStatus.confirmed:
        return LucideIcons.checkCircle;
      case OrderStatus.preparing:
        return LucideIcons.chefHat;
      case OrderStatus.ready:
        return LucideIcons.bell;
      case OrderStatus.delivered:
        return LucideIcons.truck;
      case OrderStatus.completed:
        return LucideIcons.check;
      case OrderStatus.canceled:
        return LucideIcons.x;
      case OrderStatus.refunded:
        return LucideIcons.rotateCcw;
    }
  }

  /// 日時フォーマット
  String _formatDateTime(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime orderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (orderDate == today) {
      // 今日の場合は時間のみ
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else {
      // 今日以外は日付と時間
      return "${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
  }
}
