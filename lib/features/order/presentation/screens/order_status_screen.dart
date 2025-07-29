import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
// ? このインポートの正当性検証
import "package:gotrue/gotrue.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart" as core_enums;
import "../../../../core/providers/auth_providers.dart";
import "../../../../shared/layouts/main_layout.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../models/order_model.dart";
import "../../models/order_ui_extensions.dart";
import "../providers/order_status_providers.dart";
import "../widgets/active_orders_grid.dart";
import "../widgets/order_actions.dart";
import "../widgets/order_status_header.dart";

/// 注文状況画面
///
/// リアルタイムで進行中の注文状況を表示
/// KitchenServiceと統合してステータス更新機能を提供
class OrderStatusScreen extends ConsumerStatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  ConsumerState<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends ConsumerState<OrderStatusScreen> {
  core_enums.OrderStatus? _selectedStatusFilter;
  List<Order> _selectedOrders = <Order>[];
  bool _showBulkActions = false;

  @override
  Widget build(BuildContext context) {
    final User? currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const MainLayout(
        title: "注文状況",
        child: Center(child: Text("ログインが必要です")),
      );
    }

    // リアルタイム注文データを取得
    return ref
        .watch(realTimeOrdersStreamProvider(currentUser.id))
        .when(
          data: (List<Order> orders) {
            // アクティブな注文のみフィルタリング
            List<Order> activeOrders = orders.where((Order order) => order.isActive).toList();

            // ステータスフィルターを適用
            if (_selectedStatusFilter != null) {
              activeOrders = activeOrders
                  .where((Order order) => order.status == _selectedStatusFilter)
                  .toList();
            }

            return MainLayout(
              title: "注文状況",
              child: Column(
                children: <Widget>[
                  // 注文状況ヘッダー
                  OrderStatusHeader(
                    orders: activeOrders,
                    selectedStatus: _selectedStatusFilter,
                    onRefresh: _handleRefresh,
                    onFilterChanged: (core_enums.OrderStatus? status) {
                      setState(() {
                        _selectedStatusFilter = status;
                        _selectedOrders.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // アクション
                  OrderActions(
                    orders: activeOrders,
                    selectedOrders: _selectedOrders,
                    showBulkActions: _showBulkActions,
                    onStatusUpdate: _handleBulkStatusUpdate,
                    onBulkAction: _handleBulkAction,
                    onSelectAll: () => _handleSelectAll(activeOrders),
                  ),

                  const SizedBox(height: 16),

                  // 進行中注文グリッド
                  Expanded(
                    child: activeOrders.isEmpty
                        ? _buildEmptyState()
                        : ActiveOrdersGrid(
                            orders: activeOrders,
                            onStatusUpdate: (Order order, core_enums.OrderStatus newStatus) {
                              _handleStatusUpdate(order.id!, newStatus);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
          loading: () => const MainLayout(
            title: "注文状況",
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object error, StackTrace stack) => MainLayout(
            title: "注文状況",
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(LucideIcons.alertCircle, size: 64, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text("データの読み込みに失敗しました", style: AppTextTheme.cardTitle),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: AppTextTheme.cardDescription,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
  }

  /// ステータス更新を処理
  void _handleStatusUpdate(String orderId, core_enums.OrderStatus newStatus) {
    ref.read(orderStatusManagerProvider.notifier).updateOrderStatus(orderId, newStatus);
  }

  /// 一括ステータス更新を処理
  void _handleBulkStatusUpdate(List<Order> orders) {
    for (final Order order in orders) {
      if (order.id != null) {
        _handleStatusUpdate(order.id!, order.status);
      }
    }
  }

  /// 一括アクションを処理
  void _handleBulkAction(BulkOrderAction action) {
    core_enums.OrderStatus? targetStatus;

    switch (action) {
      case BulkOrderAction.startCooking:
        targetStatus = core_enums.OrderStatus.preparing;
        break;
      case BulkOrderAction.markReady:
        targetStatus = core_enums.OrderStatus.ready;
        break;
      case BulkOrderAction.markDelivered:
        targetStatus = core_enums.OrderStatus.delivered;
        break;
      case BulkOrderAction.cancel:
        targetStatus = core_enums.OrderStatus.cancelled;
        break;
    }

    for (final Order order in _selectedOrders) {
      if (order.id != null) {
        _handleStatusUpdate(order.id!, targetStatus);
      }
    }
    setState(() {
      _selectedOrders.clear();
    });
    }

  /// 全選択/解除を処理
  void _handleSelectAll(List<Order> orders) {
    setState(() {
      if (_selectedOrders.length == orders.length) {
        _selectedOrders.clear();
      } else {
        _selectedOrders = List<Order>.from(orders);
      }
      _showBulkActions = _selectedOrders.isNotEmpty;
    });
  }

  /// リフレッシュを処理
  void _handleRefresh() {
    // Riverpodプロバイダーを再取得
    ref.invalidate(realTimeOrdersStreamProvider);
    setState(() {
      _selectedOrders.clear();
      _showBulkActions = false;
    });
  }

  /// 空の状態表示
  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(LucideIcons.coffee, size: 64, color: AppColors.mutedForeground),
        const SizedBox(height: 16),
        Text(
          "進行中の注文がありません",
          style: AppTextTheme.cardTitle.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 8),
        Text(
          "新しい注文が入ると、ここに表示されます",
          style: AppTextTheme.cardDescription,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
