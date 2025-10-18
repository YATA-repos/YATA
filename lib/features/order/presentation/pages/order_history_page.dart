import "dart:async";

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
import "../../../../shared/mixins/route_aware_refresh_mixin.dart";
import "../../../../shared/patterns/patterns.dart";
import "../../../settings/presentation/pages/settings_page.dart";
import "../../../shared/utils/payment_method_label.dart";
import "../../shared/order_status_presentation.dart";
import "../controllers/order_history_controller.dart";
import "../view_data/order_history_view_data.dart";
import "../widgets/order_detail_dialog.dart";
import "order_status_page.dart";

/// 注文履歴ページ。
class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  static const String routeName = "/history";

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage>
    with RouteAwareRefreshMixin<OrderHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _orderDetailOverlayEntry;
  OrderHistoryViewData? _currentOverlayOrder;

  @override
  void dispose() {
    _removeOrderDetailOverlay();
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get shouldRefreshOnPush => false;

  @override
  Duration? get refreshCooldown => const Duration(seconds: 5);

  @override
  Future<void> onRouteReentered() async {
    if (!mounted) {
      return;
    }

    final OrderHistoryController controller = ref.read(orderHistoryControllerProvider.notifier);
    await _waitForStateIdle<OrderHistoryState>(
      controller,
      ref.read(orderHistoryControllerProvider),
      (OrderHistoryState state) => !state.isLoading,
    );

    if (!mounted) {
      return;
    }

    await controller.loadHistory();
  }

  Future<void> _waitForStateIdle<S>(
    StateNotifier<S> controller,
    S currentState,
    bool Function(S state) isIdle,
  ) async {
    if (isIdle(currentState)) {
      return;
    }

    final Completer<void> completer = Completer<void>();
    bool cancelled = false;
    late final StreamSubscription<S> subscription;

    subscription = controller.stream.listen(
      (S next) {
        if (isIdle(next) && !cancelled) {
          cancelled = true;
          unawaited(subscription.cancel());
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      },
      onError: (Object _, StackTrace __) {
        if (!cancelled) {
          cancelled = true;
          unawaited(subscription.cancel());
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onDone: () {
        if (!cancelled) {
          cancelled = true;
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      cancelOnError: false,
    );

    try {
      await completer.future;
    } finally {
      if (!cancelled) {
        await subscription.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrderHistoryState state = ref.watch(orderHistoryControllerProvider);
    final OrderHistoryController controller = ref.watch(orderHistoryControllerProvider.notifier);
    final List<(String label, OrderStatus status)> statusOptions =
        OrderStatusPresentation.segmentOptions();

    final OrderHistoryViewData? selectedOrder = state.selectedOrder;
    if (selectedOrder != null && _currentOverlayOrder?.id != selectedOrder.id) {
      _showOrderDetailOverlay(selectedOrder, controller);
    } else if (selectedOrder == null && _currentOverlayOrder != null) {
      _removeOrderDetailOverlay();
    }

    return Scaffold(
      backgroundColor: YataColorTokens.background,
      appBar: YataAppTopBar(
        navItems: <YataNavItem>[
          YataNavItem(
            label: "注文",
            icon: Icons.shopping_cart_outlined,
            onTap: () => context.go("/order"),
          ),
          YataNavItem(
            label: "注文状況",
            icon: Icons.dashboard_customize_outlined,
            onTap: () => context.go(OrderStatusPage.routeName),
          ),
          const YataNavItem(label: "履歴", icon: Icons.receipt_long_outlined, isActive: true),
          YataNavItem(
            label: "在庫管理",
            icon: Icons.inventory_2_outlined,
            onTap: () => context.go("/inventory"),
          ),
          YataNavItem(
            label: "メニュー管理",
            icon: Icons.restaurant_menu_outlined,
            onTap: () => context.go("/menu"),
          ),
          YataNavItem(
            label: "売上分析",
            icon: Icons.query_stats_outlined,
            onTap: () => context.go("/analytics"),
          ),
        ],
        trailing: <Widget>[
          YataIconButton(
            icon: Icons.refresh,
            tooltip: "履歴を再取得",
            onPressed: state.isLoading ? null : controller.refreshHistory,
          ),
          YataIconButton(
            icon: Icons.settings,
            onPressed: () => context.go(SettingsPage.routeName),
            tooltip: "設定",
          ),
        ],
      ),
      body: YataPageContainer(
        scrollable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: YataSpacingTokens.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: state.isLoading ? const LinearProgressIndicator() : const SizedBox.shrink(),
            ),
            if (state.isLoading) const SizedBox(height: YataSpacingTokens.md),
            if (state.errorMessage != null) ...<Widget>[
              _HistoryErrorBanner(message: state.errorMessage!, onRetry: controller.refreshHistory),
              const SizedBox(height: YataSpacingTokens.md),
            ],

            // ページヘッダー
            Column(
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
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
                    hintText: "受付コード、顧客名、メニュー名、支払い方法で検索...",
                    onChanged: controller.setSearchQuery,
                  ),

                  const SizedBox(height: YataSpacingTokens.lg),

                  // ステータスフィルター
                  YataSegmentedFilter(
                    segments: <YataFilterSegment>[
                      const YataFilterSegment(label: "全て", value: 0),
                      ...List<YataFilterSegment>.generate(
                        statusOptions.length,
                        (int index) =>
                            YataFilterSegment(label: statusOptions[index].$1, value: index + 1),
                      ),
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
    );
  }

  void _showOrderDetailOverlay(OrderHistoryViewData order, OrderHistoryController controller) {
    if (!mounted) {
      return;
    }

    if (_currentOverlayOrder?.id == order.id && _orderDetailOverlayEntry != null) {
      return;
    }

    _orderDetailOverlayEntry?.remove();
    _orderDetailOverlayEntry = null;
    _currentOverlayOrder = order;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentOverlayOrder?.id != order.id) {
        return;
      }

      final OverlayState? overlayState = Overlay.maybeOf(context, rootOverlay: true);
      if (overlayState == null) {
        return;
      }

      _orderDetailOverlayEntry = OverlayEntry(
        builder: (BuildContext context) =>
            createOrderDetailDialog(order: order, onClose: controller.clearSelectedOrder),
      );

      overlayState.insert(_orderDetailOverlayEntry!);
    });
  }

  void _removeOrderDetailOverlay() {
    _currentOverlayOrder = null;
    _orderDetailOverlayEntry?.remove();
    _orderDetailOverlayEntry = null;
  }
}

/// 注文履歴リストウィジェット。
class _OrderHistoryList extends StatelessWidget {
  const _OrderHistoryList({required this.orders, required this.controller});

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
              color: YataColorTokens.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: YataSpacingTokens.md),
            Text(
              "該当する注文履歴が見つかりません",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: YataSpacingTokens.sm),
      itemBuilder: (BuildContext context, int index) {
        final OrderHistoryViewData order = orders[index];
        return _OrderHistoryCard(order: order, onTap: () => controller.selectOrder(order));
      },
    );
  }
}

class _HistoryErrorBanner extends StatelessWidget {
  const _HistoryErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(YataSpacingTokens.md),
    decoration: BoxDecoration(
      color: YataColorTokens.dangerSoft,
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
      border: Border.all(color: YataColorTokens.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.error_outline, color: YataColorTokens.danger),
        const SizedBox(width: YataSpacingTokens.sm),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: YataColorTokens.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text("再試行"),
        ),
      ],
    ),
  );
}

/// 注文履歴カードウィジェット。
class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order, required this.onTap});

  final OrderHistoryViewData order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat("MM/dd HH:mm");
    final NumberFormat currencyFormat = NumberFormat("#,###");

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(YataSpacingTokens.md),
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
                        order.orderNumber ?? "受付コード未設定",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: YataColorTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: YataSpacingTokens.sm),
                      YataStatusBadge(
                        label: OrderStatusPresentation.label(order.status),
                        type: OrderStatusPresentation.badgeType(order.status),
                      ),
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
                      paymentMethodLabel(order.paymentMethod),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: YataSpacingTokens.sm),

            // 顧客・日時・注文明細サマリー
            Row(
              children: <Widget>[
                const Icon(Icons.person_outline, size: 14, color: YataColorTokens.textSecondary),
                const SizedBox(width: YataSpacingTokens.xs),
                Text(
                  order.customerName ?? "名前なし",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary),
                ),
                const SizedBox(width: YataSpacingTokens.sm),
                Text(
                  "|",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary),
                ),
                const SizedBox(width: YataSpacingTokens.sm),
                const Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: YataColorTokens.textSecondary,
                ),
                const SizedBox(width: YataSpacingTokens.xs),
                Text(
                  dateFormat.format(order.orderedAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary),
                ),
                const SizedBox(width: YataSpacingTokens.sm),
                Text(
                  "|",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary),
                ),
                const SizedBox(width: YataSpacingTokens.sm),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 14,
                        color: YataColorTokens.textSecondary,
                      ),
                      const SizedBox(width: YataSpacingTokens.xs),
                      Expanded(
                        child: Text(
                          orderHistoryItemsSummary(order.items),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 注文明細のサマリーテキストを生成する。
@visibleForTesting
String orderHistoryItemsSummary(List<OrderItemViewData> items) {
  if (items.isEmpty) {
    return "商品なし";
  }

  final List<String> displayItems = items
      .take(3)
      .map((OrderItemViewData item) => item.menuItemName)
      .toList();

  final String summary = displayItems.join(", ");

  if (items.length > 3) {
    return "$summary, 他${items.length - 3}件";
  }

  return summary;
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(YataSpacingTokens.md),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: YataColorTokens.border)),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
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
