import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart" as core_enums;
import "../../../../core/logging/logger_mixin.dart";
import "../../../../shared/layouts/main_layout.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../auth/models/user_profile.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
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

class _OrderStatusScreenState extends ConsumerState<OrderStatusScreen> with LoggerMixin {
  @override
  String get componentName => "OrderStatusScreen";
  core_enums.OrderStatus? _selectedStatusFilter;
  List<Order> _selectedOrders = <Order>[];
  bool _showBulkActions = false;

  @override
  Widget build(BuildContext context) {
    final UserProfile? currentUser = ref.watch(currentUserProvider);
    final String? userId = ref.watch(currentUserIdProvider);

    if (currentUser == null) {
      logWarning("注文状況画面: ユーザーがログインしていません");
      return const MainLayout(
        title: "注文状況",
        child: Center(child: Text("ログインが必要です")),
      );
    }

    if (userId == null) {
      logWarning("注文状況画面: userIdがnullです");
      return const MainLayout(
        title: "注文状況",
        child: Center(child: Text("ユーザー情報の取得に失敗しました")),
      );
    }

    // リアルタイム注文データを取得
    return ref
        .watch(realTimeOrdersStreamProvider(userId))
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
          loading: () {
            logTrace("リアルタイム注文データ読み込み中");
            return const MainLayout(
              title: "注文状況",
              child: Center(child: CircularProgressIndicator()),
            );
          },
          error: (Object error, StackTrace stack) {
            logError("リアルタイム注文データの読み込みでエラーが発生", error, stack);
            return MainLayout(
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
            );
          },
        );
  }

  /// ステータス更新を処理
  void _handleStatusUpdate(String orderId, core_enums.OrderStatus newStatus) {
    logDebug("注文ステータス更新: orderId=$orderId, newStatus=$newStatus");
    try {
      ref.read(orderStatusManagerProvider.notifier).updateOrderStatus(orderId, newStatus);
      logInfo("注文ステータス更新が完了: orderId=$orderId, newStatus=$newStatus");
    } catch (e, stackTrace) {
      logError("注文ステータス更新中にエラーが発生: orderId=$orderId", e, stackTrace);
      rethrow;
    }
  }

  /// 一括ステータス更新を処理
  void _handleBulkStatusUpdate(List<Order> orders) {
    logDebug("一括ステータス更新を開始: ${orders.length}件の注文");
    try {
      for (final Order order in orders) {
        if (order.id != null) {
          _handleStatusUpdate(order.id!, order.status);
        } else {
          logWarning("注文IDがnullのためスキップ: orderNumber=${order.orderNumber}");
        }
      }
      logInfo("一括ステータス更新が完了: ${orders.length}件");
    } catch (e, stackTrace) {
      logError("一括ステータス更新中にエラーが発生", e, stackTrace);
      rethrow;
    }
  }

  /// 一括アクションを処理
  void _handleBulkAction(BulkOrderAction action) {
    logDebug("一括アクションを開始: action=$action, 選択中の注文数=${_selectedOrders.length}");
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

    try {
      for (final Order order in _selectedOrders) {
        if (order.id != null) {
          _handleStatusUpdate(order.id!, targetStatus);
        } else {
          logWarning("注文IDがnullのためスキップ: orderNumber=${order.orderNumber}");
        }
      }
      logInfo("一括アクションが完了: action=$action, 処理件数=${_selectedOrders.length}");
      setState(() {
        _selectedOrders.clear();
      });
    } catch (e, stackTrace) {
      logError("一括アクション中にエラーが発生: action=$action", e, stackTrace);
      rethrow;
    }
  }

  /// 全選択/解除を処理
  void _handleSelectAll(List<Order> orders) {
    final bool isSelectingAll = _selectedOrders.length != orders.length;
    logDebug("${isSelectingAll ? '全選択' : '全解除'}を実行: 対象注文数=${orders.length}");
    setState(() {
      if (_selectedOrders.length == orders.length) {
        _selectedOrders.clear();
      } else {
        _selectedOrders = List<Order>.from(orders);
      }
      _showBulkActions = _selectedOrders.isNotEmpty;
    });
    logDebug("${isSelectingAll ? '全選択' : '全解除'}が完了: 選択中の注文数=${_selectedOrders.length}");
  }

  /// リフレッシュを処理
  void _handleRefresh() {
    logDebug("注文状況リフレッシュを開始");
    try {
      // Riverpodプロバイダーを再取得
      ref.invalidate(realTimeOrdersStreamProvider);
      setState(() {
        _selectedOrders.clear();
        _showBulkActions = false;
      });
      logInfo("注文状況リフレッシュが完了しました");
    } catch (e, stackTrace) {
      logError("注文状況リフレッシュ中にエラーが発生", e, stackTrace);
    }
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
