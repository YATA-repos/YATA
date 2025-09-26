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
      body: Stack(
        children: <Widget>[
          YataPageContainer(
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
                    : Column(
                        children: <Widget>[
                          Expanded(
                            child: _OrderHistoryList(
                              orders: state.filteredOrders,
                              controller: controller,
                            ),
                          ),
                          if (state.totalPages > 1)
                            _PaginationControls(
                              currentPage: state.currentPage,
                              totalPages: state.totalPages,
                              onPageChanged: controller.setPage,
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      
      // 注文詳細ダイアログ
      if (state.selectedOrder != null)
        _OrderDetailDialog(
          order: state.selectedOrder!,
          onClose: controller.clearSelectedOrder,
        ),
    ],
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

/// 注文詳細ダイアログウィジェット。
class _OrderDetailDialog extends StatelessWidget {
  const _OrderDetailDialog({
    required this.order,
    required this.onClose,
  });

  final OrderHistoryViewData order;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: Material(
            borderRadius: YataRadiusTokens.borderRadiusCard,
            child: Container(
              decoration: BoxDecoration(
                color: YataColorTokens.surface,
                borderRadius: YataRadiusTokens.borderRadiusCard,
              ),
              child: Column(
                children: <Widget>[
                  // ダイアログヘッダー
                  Container(
                    padding: const EdgeInsets.all(YataSpacingTokens.lg),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: YataColorTokens.border),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            "注文詳細",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: YataColorTokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close),
                          color: YataColorTokens.textSecondary,
                        ),
                      ],
                    ),
                  ),

                  // ダイアログコンテンツ
                  Expanded(
                    child: _OrderDetailContent(order: order),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 注文詳細コンテンツウィジェット。
class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({required this.order});

  final OrderHistoryViewData order;

  @override
  Widget build(BuildContext context) {
    final DateFormat detailDateFormat = DateFormat('yyyy/MM/dd HH:mm:ss');
    final NumberFormat currencyFormat = NumberFormat('#,###');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(YataSpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 注文基本情報
          _DetailSection(
            title: "注文情報",
            child: Column(
              children: <Widget>[
                _DetailRow(
                  label: "注文番号",
                  value: order.orderNumber ?? "番号なし",
                ),
                _DetailRow(
                  label: "ステータス",
                  value: order.status.displayName,
                  valueWidget: _OrderStatusBadge(status: order.status),
                ),
                _DetailRow(
                  label: "顧客名",
                  value: order.customerName ?? "名前なし",
                ),
                _DetailRow(
                  label: "支払い方法",
                  value: _getPaymentMethodLabel(order.paymentMethod),
                ),
                _DetailRow(
                  label: "注文日時",
                  value: detailDateFormat.format(order.orderedAt),
                ),
                if (order.completedAt != null)
                  _DetailRow(
                    label: "完了日時",
                    value: detailDateFormat.format(order.completedAt!),
                  ),
              ],
            ),
          ),

          const SizedBox(height: YataSpacingTokens.xl),

          // 注文明細
          _DetailSection(
            title: "注文明細",
            child: Column(
              children: <Widget>[
                ...order.items.map((OrderItemViewData item) => _OrderItemRow(item: item)),
                
                const Divider(height: YataSpacingTokens.lg),

                // 合計金額
                _DetailRow(
                  label: "小計",
                  value: "¥${currencyFormat.format(order.totalAmount)}",
                  isSubtotal: true,
                ),
                if (order.discountAmount > 0)
                  _DetailRow(
                    label: "割引",
                    value: "-¥${currencyFormat.format(order.discountAmount)}",
                    isDiscount: true,
                  ),
                _DetailRow(
                  label: "合計",
                  value: "¥${currencyFormat.format(order.actualAmount)}",
                  isTotal: true,
                ),
              ],
            ),
          ),

          // 備考（ある場合のみ）
          if (order.notes != null && order.notes!.isNotEmpty) ...<Widget>[
            const SizedBox(height: YataSpacingTokens.xl),
            _DetailSection(
              title: "備考",
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(YataSpacingTokens.md),
                decoration: BoxDecoration(
                  color: YataColorTokens.surfaceAlt,
                  borderRadius: YataRadiusTokens.borderRadiusSmall,
                ),
                child: Text(
                  order.notes!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: YataColorTokens.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
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

/// 詳細セクションウィジェット。
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: YataColorTokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: YataSpacingTokens.md),
        child,
      ],
    );
  }
}

/// 詳細行ウィジェット。
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueWidget,
    this.isSubtotal = false,
    this.isDiscount = false,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
  final bool isSubtotal;
  final bool isDiscount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: YataColorTokens.textSecondary,
      fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
    ) ?? YataTypographyTokens.bodyMedium;

    final TextStyle valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: isDiscount ? YataColorTokens.warning : YataColorTokens.textPrimary,
      fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
    ) ?? YataTypographyTokens.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(label, style: labelStyle),
          ),
          Expanded(
            flex: 3,
            child: valueWidget ?? Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// 注文明細行ウィジェット。
class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItemViewData item;

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 数量
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              "${item.quantity}x",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: YataColorTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(width: YataSpacingTokens.md),
          
          // メニュー名と詳細
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.menuItemName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: YataColorTokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
                    child: Text(
                      item.selectedOptions!.entries
                          .map((MapEntry<String, String> e) => "${e.key}: ${e.value}")
                          .join(", "),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: YataColorTokens.textSecondary,
                      ),
                    ),
                  ),
                if (item.specialRequest != null && item.specialRequest!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: YataSpacingTokens.sm,
                        vertical: YataSpacingTokens.xs,
                      ),
                      decoration: BoxDecoration(
                        color: YataColorTokens.warningSoft,
                        borderRadius: YataRadiusTokens.borderRadiusSmall,
                      ),
                      child: Text(
                        "特別リクエスト: ${item.specialRequest}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: YataColorTokens.warning,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: YataSpacingTokens.md),
          
          // 単価と小計
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                "¥${currencyFormat.format(item.unitPrice)}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: YataColorTokens.textSecondary,
                ),
              ),
              Text(
                "¥${currencyFormat.format(item.subtotal)}",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: YataColorTokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ページネーションコントロールウィジェット。
class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(YataSpacingTokens.md),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: YataColorTokens.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // 前のページボタン
          IconButton(
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            color: YataColorTokens.textSecondary,
          ),
          const SizedBox(width: YataSpacingTokens.sm),
          
          // ページ情報
          Text(
            "$currentPage / $totalPages ページ",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: YataColorTokens.textSecondary,
            ),
          ),
          
          const SizedBox(width: YataSpacingTokens.sm),
          
          // 次のページボタン
          IconButton(
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            color: YataColorTokens.textSecondary,
          ),
        ],
      ),
    );
  }
}
