import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/components/buttons/icon_button.dart";
import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/mixins/route_aware_refresh_mixin.dart";
import "../../../../shared/patterns/navigation/app_top_bar.dart";
import "../../../settings/presentation/pages/settings_page.dart";
import "../controllers/order_management_controller.dart";
import "../controllers/order_management_state.dart";
import "../widgets/order_management/current_order_section.dart";
import "../widgets/order_management/menu_selection_section.dart";
import "../widgets/order_management/order_page_error_banner.dart";
import "order_status_page.dart";

/// 注文管理画面のメインページ。
class OrderManagementPage extends ConsumerStatefulWidget {
  /// [OrderManagementPage]を生成する。
  const OrderManagementPage({super.key});

  @override
  ConsumerState<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends ConsumerState<OrderManagementPage>
    with RouteAwareRefreshMixin<OrderManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get shouldRefreshOnPush => false;

  @override
  Future<void> onRouteReentered() async {
    if (!mounted) {
      return;
    }

    final OrderManagementController controller = ref.read(
      orderManagementControllerProvider.notifier,
    );
    await _waitForStateIdle<OrderManagementState>(
      controller,
      ref.read(orderManagementControllerProvider),
      (OrderManagementState state) => !state.isLoading && !state.isCheckoutInProgress,
    );

    if (!mounted) {
      return;
    }

    await controller.loadInitialData();
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
    final OrderManagementState state = ref.watch(orderManagementControllerProvider);
    final OrderManagementController controller = ref.watch(
      orderManagementControllerProvider.notifier,
    );

    return Scaffold(
      backgroundColor: YataColorTokens.background,
      appBar: YataAppTopBar(
        navItems: <YataNavItem>[
          YataNavItem(
            label: "注文",
            icon: Icons.shopping_cart_outlined,
            isActive: true,
            onTap: () => context.go("/order"),
          ),
          YataNavItem(
            label: "注文状況",
            icon: Icons.dashboard_customize_outlined,
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
            tooltip: "メニューとカートを再取得",
            onPressed: state.isLoading ? null : controller.refresh,
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
              OrderPageErrorBanner(message: state.errorMessage!, onRetry: controller.refresh),
              const SizedBox(height: YataSpacingTokens.md),
            ],
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: MenuSelectionSection(
                      state: state,
                      searchController: _searchController,
                      onSearchQueryChanged: controller.updateSearchQuery,
                      onSelectCategory: controller.selectCategory,
                      onUpdateItemQuantity: controller.updateItemQuantity,
                      onAddMenuItem: controller.addMenuItem,
                    ),
                  ),
                  const SizedBox(width: YataSpacingTokens.lg),
                  // 右ペインはカード内で内部スクロール + 下部固定バー
                  Expanded(
                    child: CurrentOrderSection(
                      state: state,
                      onUpdateItemQuantity: controller.updateItemQuantity,
                      onRemoveItem: controller.removeItem,
                      onPaymentMethodChanged: controller.updatePaymentMethod,
                      onOrderNotesChanged: controller.updateOrderNotes,
                      onClearCart: controller.clearCart,
                      onCheckout: controller.checkout,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
