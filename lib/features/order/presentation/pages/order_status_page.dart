import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/components/buttons/icon_button.dart";
import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/components/layout/section_card.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/patterns/navigation/app_top_bar.dart";
import "../../../settings/presentation/pages/settings_page.dart";
import "../controllers/order_status_controller.dart";
import "../../shared/order_status_presentation.dart";

/// 注文状況更新ページ。
class OrderStatusPage extends ConsumerStatefulWidget {
  /// [OrderStatusPage]を生成する。
  const OrderStatusPage({super.key});

  /// ルート名。
  static const String routeName = "/order-status";

  @override
  ConsumerState<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends ConsumerState<OrderStatusPage> {
  final NumberFormat _currencyFormat = NumberFormat("#,###");
  final DateFormat _timeFormat = DateFormat("HH:mm");
  final DateFormat _dateTimeFormat = DateFormat("yyyy/MM/dd HH:mm");

  @override
  Widget build(BuildContext context) {
    final OrderStatusState state = ref.watch(orderStatusControllerProvider);
    final OrderStatusController controller = ref.read(orderStatusControllerProvider.notifier);
    final Map<OrderStatus, List<OrderStatusOrderViewData>> sections =
        <OrderStatus, List<OrderStatusOrderViewData>>{
          OrderStatus.inProgress: state.inProgressOrders,
          OrderStatus.completed: state.completedOrders,
          OrderStatus.cancelled: state.cancelledOrders,
        };

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
            isActive: true,
            onTap: () => context.go(OrderStatusPage.routeName),
          ),
          YataNavItem(
            label: "履歴",
            icon: Icons.receipt_long_outlined,
            onTap: () => context.go("/history"),
          ),
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
            tooltip: "最新の注文を再取得",
            onPressed: state.isLoading ? null : controller.loadOrders,
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
              _StatusErrorBanner(message: state.errorMessage!, onRetry: controller.loadOrders),
              const SizedBox(height: YataSpacingTokens.md),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool isWide = constraints.maxWidth >= 900;

                  final List<Widget> sectionWidgets = <Widget>[
                    _OrderStatusSection(
                      title: OrderStatusPresentation.label(OrderStatus.inProgress),
                      subtitle: "提供に向けて進行中の注文",
                      child: _InProgressOrderList(
                        orders:
                            sections[OrderStatus.inProgress] ?? const <OrderStatusOrderViewData>[],
                        updatingOrderIds: state.updatingOrderIds,
                        isBusy: state.isLoading,
                        currencyFormat: _currencyFormat,
                        timeFormat: _timeFormat,
                        onMarkCompleted: (OrderStatusOrderViewData order) async {
                          final String? error = await controller.markOrderCompleted(order.id);
                          if (!mounted) {
                            return;
                          }
                          final String message = error ?? "${order.orderNumber ?? "注文"} を完了に更新しました";
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        },
                      ),
                    ),
                    _OrderStatusSection(
                      title: OrderStatusPresentation.label(OrderStatus.completed),
                      subtitle: "最近完了した注文",
                      child: _CompletedOrderList(
                        orders:
                            sections[OrderStatus.completed] ?? const <OrderStatusOrderViewData>[],
                        currencyFormat: _currencyFormat,
                        timeFormat: _timeFormat,
                        dateTimeFormat: _dateTimeFormat,
                      ),
                    ),
                    _OrderStatusSection(
                      title: OrderStatusPresentation.label(OrderStatus.cancelled),
                      subtitle: "キャンセルされた注文",
                      child: _CancelledOrderList(
                        orders:
                            sections[OrderStatus.cancelled] ?? const <OrderStatusOrderViewData>[],
                        currencyFormat: _currencyFormat,
                        timeFormat: _timeFormat,
                      ),
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: sectionWidgets[0]),
                        const SizedBox(width: YataSpacingTokens.lg),
                        Expanded(child: sectionWidgets[1]),
                        const SizedBox(width: YataSpacingTokens.lg),
                        Expanded(child: sectionWidgets[2]),
                      ],
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        sectionWidgets[0],
                        const SizedBox(height: YataSpacingTokens.lg),
                        sectionWidgets[1],
                        const SizedBox(height: YataSpacingTokens.lg),
                        sectionWidgets[2],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusSection extends StatelessWidget {
  const _OrderStatusSection({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      YataSectionCard(title: title, subtitle: subtitle, expandChild: true, child: child);
}

class _InProgressOrderList extends StatelessWidget {
  const _InProgressOrderList({
    required this.orders,
    required this.updatingOrderIds,
    required this.isBusy,
    required this.currencyFormat,
    required this.timeFormat,
    required this.onMarkCompleted,
  });

  final List<OrderStatusOrderViewData> orders;
  final Set<String> updatingOrderIds;
  final bool isBusy;
  final NumberFormat currencyFormat;
  final DateFormat timeFormat;
  final Future<void> Function(OrderStatusOrderViewData order) onMarkCompleted;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyIndicator(message: "現在、進行中の注文はありません");
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: YataSpacingTokens.md),
      itemBuilder: (BuildContext context, int index) {
        final OrderStatusOrderViewData order = orders[index];
        final bool isUpdating = updatingOrderIds.contains(order.id) || isBusy;
        final TextTheme textTheme = Theme.of(context).textTheme;

        return Container(
          padding: const EdgeInsets.all(YataSpacingTokens.md),
          decoration: BoxDecoration(
            color: YataColorTokens.surfaceAlt,
            borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
            border: Border.all(color: YataColorTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          order.orderNumber ?? "注文番号未設定",
                          style:
                              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) ??
                              YataTypographyTokens.titleMedium,
                        ),
                        const SizedBox(height: YataSpacingTokens.xs),
                        Text(
                          "${order.customerName ?? "名前なし"} ・ ${timeFormat.format(order.orderedAt)}",
                          style:
                              textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary) ??
                              YataTypographyTokens.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: YataSpacingTokens.sm),
                  Text(
                    "¥${currencyFormat.format(order.totalAmount)}",
                    style:
                        textTheme.titleMedium?.copyWith(color: YataColorTokens.textPrimary) ??
                        YataTypographyTokens.titleMedium,
                  ),
                ],
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...<Widget>[
                const SizedBox(height: YataSpacingTokens.sm),
                Text(
                  order.notes!,
                  style:
                      textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary) ??
                      YataTypographyTokens.bodySmall,
                ),
              ],
              const SizedBox(height: YataSpacingTokens.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("完了にする"),
                  onPressed: isUpdating ? null : () => onMarkCompleted(order),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompletedOrderList extends StatelessWidget {
  const _CompletedOrderList({
    required this.orders,
    required this.currencyFormat,
    required this.timeFormat,
    required this.dateTimeFormat,
  });

  final List<OrderStatusOrderViewData> orders;
  final NumberFormat currencyFormat;
  final DateFormat timeFormat;
  final DateFormat dateTimeFormat;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyIndicator(message: "完了した注文はまだありません");
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: YataSpacingTokens.md),
      itemBuilder: (BuildContext context, int index) {
        final OrderStatusOrderViewData order = orders[index];
        final TextTheme textTheme = Theme.of(context).textTheme;

        return Container(
          padding: const EdgeInsets.all(YataSpacingTokens.md),
          decoration: BoxDecoration(
            color: YataColorTokens.surface,
            borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
            border: Border.all(color: YataColorTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      order.orderNumber ?? "注文番号未設定",
                      style:
                          textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) ??
                          YataTypographyTokens.titleMedium,
                    ),
                  ),
                  Text(
                    "¥${currencyFormat.format(order.totalAmount)}",
                    style:
                        textTheme.titleMedium?.copyWith(color: YataColorTokens.textPrimary) ??
                        YataTypographyTokens.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: YataSpacingTokens.xs),
              Text(
                "${order.customerName ?? "名前なし"} ・ ${timeFormat.format(order.orderedAt)}",
                style:
                    textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary) ??
                    YataTypographyTokens.bodySmall,
              ),
              if (order.completedAt != null) ...<Widget>[
                const SizedBox(height: YataSpacingTokens.xs),
                Text(
                  "提供完了: ${dateTimeFormat.format(order.completedAt!)}",
                  style:
                      textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary) ??
                      YataTypographyTokens.bodySmall,
                ),
              ],
              if (order.notes != null && order.notes!.isNotEmpty) ...<Widget>[
                const SizedBox(height: YataSpacingTokens.sm),
                Text(
                  order.notes!,
                  style:
                      textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary) ??
                      YataTypographyTokens.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CancelledOrderList extends StatelessWidget {
  const _CancelledOrderList({
    required this.orders,
    required this.currencyFormat,
    required this.timeFormat,
  });

  final List<OrderStatusOrderViewData> orders;
  final NumberFormat currencyFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyIndicator(message: "キャンセル済みの注文はありません");
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: YataSpacingTokens.md),
      itemBuilder: (BuildContext context, int index) {
        final OrderStatusOrderViewData order = orders[index];
        final TextTheme textTheme = Theme.of(context).textTheme;

        return Container(
          padding: const EdgeInsets.all(YataSpacingTokens.md),
          decoration: BoxDecoration(
            color: YataColorTokens.surfaceAlt,
            borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
            border: Border.all(color: YataColorTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      order.orderNumber ?? "注文番号未設定",
                      style:
                          textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) ??
                          YataTypographyTokens.titleMedium,
                    ),
                  ),
                  Text(
                    "¥${currencyFormat.format(order.totalAmount)}",
                    style:
                        textTheme.titleMedium?.copyWith(color: YataColorTokens.textPrimary) ??
                        YataTypographyTokens.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: YataSpacingTokens.xs),
              Text(
                "${order.customerName ?? "名前なし"} ・ ${timeFormat.format(order.orderedAt)}",
                style:
                    textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary) ??
                    YataTypographyTokens.bodySmall,
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...<Widget>[
                const SizedBox(height: YataSpacingTokens.sm),
                Text(
                  order.notes!,
                  style:
                      textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary) ??
                      YataTypographyTokens.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusErrorBanner extends StatelessWidget {
  const _StatusErrorBanner({required this.message, required this.onRetry});

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
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: YataColorTokens.danger,
                  fontWeight: FontWeight.w600,
                ) ??
                YataTypographyTokens.bodyMedium,
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

class _EmptyIndicator extends StatelessWidget {
  const _EmptyIndicator({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: YataColorTokens.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: YataSpacingTokens.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary) ??
                YataTypographyTokens.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
