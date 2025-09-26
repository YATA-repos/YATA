import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/components/buttons/icon_button.dart";
import "../../../../shared/components/data_display/status_badge.dart";
import "../../../../shared/components/inputs/search_field.dart";
import "../../../../shared/components/inputs/segmented_filter.dart";
import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/components/layout/section_card.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/patterns/patterns.dart";
import "../controllers/order_history_controller.dart";

/// 注文履歴ページ。
class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  static const String routeName = "/history";

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OrderHistoryState state = ref.watch(orderHistoryControllerProvider);
    final OrderHistoryController controller = ref.watch(orderHistoryControllerProvider.notifier);

    return Scaffold(
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
            
            // ページヘッダー
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "注文履歴",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: YataColorTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: YataSpacingTokens.xs),
                      Text(
                        "過去の注文履歴を確認できます（全${state.totalCount}件）",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: YataColorTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                YataIconButton(
                  icon: Icons.refresh,
                  onPressed: controller.refreshHistory,
                  tooltip: "履歴を更新",
                ),
              ],
            ),

            const SizedBox(height: YataSpacingTokens.xl),

            // フィルターセクション
            YataSectionCard(
              title: "絞り込み",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 検索フィールド
                  YataSearchField(
                    controller: _searchController,
                    hintText: "注文番号、顧客名、メニュー名で検索...",
                    onChanged: controller.setSearchQuery,
                  ),
                  
                  const SizedBox(height: YataSpacingTokens.lg),
                  
                  // ステータスフィルター
                  YataSegmentedFilter(
                    segments: const <YataFilterSegment>[
                      YataFilterSegment(label: "全て", value: 0),
                      YataFilterSegment(label: "完了", value: 1),
                      YataFilterSegment(label: "キャンセル", value: 2),
                      YataFilterSegment(label: "返金済み", value: 3),
                    ],
                    selectedIndex: state.selectedStatusFilter,
                    onSegmentSelected: controller.setStatusFilter,
                  ),
                ],
              ),
            ),

            const SizedBox(height: YataSpacingTokens.xl),

            // 注文履歴リスト
            Expanded(
              child: YataSectionCard(
                title: "注文一覧",
                expandChild: true,
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _OrderHistoryList(
                        orders: state.filteredOrders,
                        controller: controller,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 注文履歴リストウィジェット。
class _OrderHistoryList extends StatelessWidget {
  const _OrderHistoryList({
    required this.orders,
    required this.controller,
  });

  final List<OrderHistoryViewData> orders;
  final OrderHistoryController controller;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: YataColorTokens.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: YataSpacingTokens.md),
            Text(
              "該当する注文履歴が見つかりません",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: YataColorTokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: YataSpacingTokens.md),
      itemBuilder: (BuildContext context, int index) {
        final OrderHistoryViewData order = orders[index];
        return _OrderHistoryCard(
          order: order,
          onTap: () => controller.selectOrder(order),
        );
      },
    );
  }
}

/// 注文履歴カードウィジェット。
class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({
    required this.order,
    required this.onTap,
  });

  final OrderHistoryViewData order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MM/dd HH:mm');
    final NumberFormat currencyFormat = NumberFormat('#,###');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(YataSpacingTokens.lg),
        decoration: BoxDecoration(
          color: YataColorTokens.surface,
          borderRadius: YataRadiusTokens.borderRadiusCard,
          border: Border.all(color: YataColorTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ヘッダー行
            Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Text(
                        order.orderNumber ?? "注文番号なし",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: YataColorTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: YataSpacingTokens.sm),
                      _OrderStatusBadge(status: order.status),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      "¥${currencyFormat.format(order.actualAmount)}",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: YataColorTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getPaymentMethodLabel(order.paymentMethod),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: YataColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: YataSpacingTokens.md),

            // 顧客名・注文日時
            Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: YataColorTokens.textSecondary,
                      ),
                      const SizedBox(width: YataSpacingTokens.xs),
                      Text(
                        order.customerName ?? "名前なし",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: YataColorTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: YataColorTokens.textSecondary,
                    ),
                    const SizedBox(width: YataSpacingTokens.xs),
                    Text(
                      dateFormat.format(order.orderedAt),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: YataColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: YataSpacingTokens.md),

            // 注文明細（最大3件まで表示）
            ...order.items.take(3).map((OrderItemViewData item) => Padding(
              padding: const EdgeInsets.only(bottom: YataSpacingTokens.xs),
              child: Row(
                children: <Widget>[
                  Text(
                    "${item.quantity}x",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: YataColorTokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: YataSpacingTokens.sm),
                  Expanded(
                    child: Text(
                      item.menuItemName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: YataColorTokens.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    "¥${currencyFormat.format(item.subtotal)}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: YataColorTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            )),

            // 項目が3件より多い場合の表示
            if (order.items.length > 3) ...<Widget>[
              const SizedBox(height: YataSpacingTokens.xs),
              Text(
                "他${order.items.length - 3}件",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: YataColorTokens.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // 備考（ある場合のみ表示）
            if (order.notes != null && order.notes!.isNotEmpty) ...<Widget>[
              const SizedBox(height: YataSpacingTokens.md),
              Container(
                padding: const EdgeInsets.all(YataSpacingTokens.sm),
                decoration: BoxDecoration(
                  color: YataColorTokens.surfaceAlt,
                  borderRadius: YataRadiusTokens.borderRadiusSmall,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: YataColorTokens.textSecondary,
                    ),
                    const SizedBox(width: YataSpacingTokens.xs),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: YataColorTokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
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

/// 注文ステータスバッジウィジェット。
class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final YataStatusBadgeType badgeType = switch (status) {
      OrderStatus.completed => YataStatusBadgeType.success,
      OrderStatus.cancelled => YataStatusBadgeType.danger,
      OrderStatus.refunded => YataStatusBadgeType.warning,
      OrderStatus.delivered => YataStatusBadgeType.success,
      OrderStatus.pending => YataStatusBadgeType.neutral,
      OrderStatus.confirmed => YataStatusBadgeType.info,
      OrderStatus.preparing => YataStatusBadgeType.warning,
      OrderStatus.ready => YataStatusBadgeType.info,
    };

    return YataStatusBadge(
      label: status.displayName,
      type: badgeType,
    );
  }
}
