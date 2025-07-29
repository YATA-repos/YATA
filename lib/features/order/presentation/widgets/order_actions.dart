import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart" as core_enums;
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../models/order_model.dart";

/// 注文アクションボタン群
///
/// 注文に対する操作（ステータス更新、キャンセル、一括操作）を提供
class OrderActions extends StatelessWidget {
  const OrderActions({
    required this.orders,
    this.selectedOrders = const <Order>[],
    this.onStatusUpdate,
    this.onCancelOrder,
    this.onBulkAction,
    this.onSelectAll,
    this.showBulkActions = false,
    this.isCompact = false,
    super.key,
  });

  final List<Order> orders;
  final List<Order> selectedOrders;
  final ValueChanged<List<Order>>? onStatusUpdate;
  final ValueChanged<Order>? onCancelOrder;
  final ValueChanged<BulkOrderAction>? onBulkAction;
  final VoidCallback? onSelectAll;
  final bool showBulkActions;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (showBulkActions && selectedOrders.isNotEmpty) {
      return _buildBulkActions();
    } else {
      return _buildQuickActions();
    }
  }

  /// 一括操作アクション
  Widget _buildBulkActions() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 選択状況
        Row(
          children: <Widget>[
            Icon(LucideIcons.checkSquare, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              "${selectedOrders.length}件の注文を選択中",
              style: AppTextTheme.cardDescription.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(
              onPressed: onSelectAll,
              child: Text(
                selectedOrders.length == orders.length ? "選択解除" : "全て選択",
                style: AppTextTheme.cardDescription.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 一括操作ボタン
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            AppButton(
              text: "一括調理開始",
              icon: const Icon(LucideIcons.play, size: 16),
              variant: ButtonVariant.cooking,
              size: ButtonSize.small,
              onPressed: _canBulkStart()
                  ? () => onBulkAction?.call(BulkOrderAction.startCooking)
                  : null,
            ),
            AppButton(
              text: "一括調理完了",
              icon: const Icon(LucideIcons.check, size: 16),
              variant: ButtonVariant.complete,
              size: ButtonSize.small,
              onPressed: _canBulkComplete()
                  ? () => onBulkAction?.call(BulkOrderAction.markReady)
                  : null,
            ),
            AppButton(
              text: "一括提供完了",
              icon: const Icon(LucideIcons.heart, size: 16),
              size: ButtonSize.small,
              onPressed: _canBulkDeliver()
                  ? () => onBulkAction?.call(BulkOrderAction.markDelivered)
                  : null,
            ),
            AppButton(
              text: "選択キャンセル",
              icon: const Icon(LucideIcons.x, size: 16),
              variant: ButtonVariant.danger,
              size: ButtonSize.small,
              onPressed: () => onBulkAction?.call(BulkOrderAction.cancel),
            ),
          ],
        ),
      ],
    ),
  );

  /// クイックアクション
  Widget _buildQuickActions() => Container(
    padding: EdgeInsets.all(isCompact ? 12 : 16),
    decoration: BoxDecoration(
      color: AppColors.card,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // タイトル
        Row(
          children: <Widget>[
            Icon(LucideIcons.zap, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text("クイックアクション", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
          ],
        ),

        SizedBox(height: isCompact ? 8 : 12),

        // アクションボタン
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            AppButton(
              text: "待機中→調理開始",
              icon: const Icon(LucideIcons.play, size: 16),
              variant: ButtonVariant.cooking,
              size: isCompact ? ButtonSize.small : ButtonSize.medium,
              onPressed: _getPendingOrders().isNotEmpty
                  ? () => _bulkUpdateStatus(core_enums.OrderStatus.preparing)
                  : null,
            ),
            AppButton(
              text: "調理中→完了",
              icon: const Icon(LucideIcons.check, size: 16),
              variant: ButtonVariant.complete,
              size: isCompact ? ButtonSize.small : ButtonSize.medium,
              onPressed: _getPreparingOrders().isNotEmpty
                  ? () => _bulkUpdateStatus(core_enums.OrderStatus.ready)
                  : null,
            ),
            AppButton(
              text: "完了→提供",
              icon: const Icon(LucideIcons.heart, size: 16),
              size: isCompact ? ButtonSize.small : ButtonSize.medium,
              onPressed: _getReadyOrders().isNotEmpty
                  ? () => _bulkUpdateStatus(core_enums.OrderStatus.delivered)
                  : null,
            ),
          ],
        ),

        if (!isCompact) ...<Widget>[
          const SizedBox(height: 8),

          // 統計情報
          Text(
            "待機中: ${_getPendingOrders().length}件 | "
            "調理中: ${_getPreparingOrders().length}件 | "
            "完了: ${_getReadyOrders().length}件",
            style: AppTextTheme.cardDescription.copyWith(fontSize: 12),
          ),
        ],
      ],
    ),
  );

  /// 一括調理開始が可能かチェック
  bool _canBulkStart() =>
      selectedOrders.any((Order order) => order.status == core_enums.OrderStatus.pending);

  /// 一括調理完了が可能かチェック
  bool _canBulkComplete() =>
      selectedOrders.any((Order order) => order.status == core_enums.OrderStatus.preparing);

  /// 一括提供完了が可能かチェック
  bool _canBulkDeliver() =>
      selectedOrders.any((Order order) => order.status == core_enums.OrderStatus.ready);

  /// ステータス別注文取得
  List<Order> _getPendingOrders() =>
      orders.where((Order order) => order.status == core_enums.OrderStatus.pending).toList();

  List<Order> _getPreparingOrders() =>
      orders.where((Order order) => order.status == core_enums.OrderStatus.preparing).toList();

  List<Order> _getReadyOrders() =>
      orders.where((Order order) => order.status == core_enums.OrderStatus.ready).toList();

  /// 一括ステータス更新
  void _bulkUpdateStatus(core_enums.OrderStatus newStatus) {
    final List<Order> targetOrders = switch (newStatus) {
      core_enums.OrderStatus.preparing => _getPendingOrders(),
      core_enums.OrderStatus.ready => _getPreparingOrders(),
      core_enums.OrderStatus.delivered => _getReadyOrders(),
      _ => <Order>[],
    };

    if (targetOrders.isNotEmpty) {
      onStatusUpdate?.call(targetOrders);
    }
  }
}

/// 一括操作の種類
enum BulkOrderAction { startCooking, markReady, markDelivered, cancel }
