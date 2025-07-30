import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart" as core_enums;
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/cards/app_card.dart";
import "../../../../shared/widgets/common/app_badge.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../models/order_model.dart";
import "../../models/order_ui_extensions.dart";
import "../providers/order_providers.dart";
import "order_progress.dart";

/// 注文ステータスカード
///
/// 個別の注文情報とステータス更新機能を提供
/// 既存のAppCard、AppBadge、AppButtonを活用
class OrderStatusCard extends ConsumerWidget {
  const OrderStatusCard({required this.order, this.onTap, this.onStatusUpdate, super.key});

  final Order order;
  final VoidCallback? onTap;
  final ValueChanged<core_enums.OrderStatus>? onStatusUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? userId = ref.read(currentUserProvider)?.id;

    if (userId == null || order.id == null) {
      return _buildBasicCard();
    }

    return ref
        .watch(orderWithItemsProvider(order.id!, userId))
        .when(
          data: _buildCardWithItems,
          loading: _buildBasicCard,
          error: (Object error, StackTrace stack) => _buildBasicCard(),
        );
  }

  /// 基本カード（OrderItemなし）
  Widget _buildBasicCard() => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ヘッダー行（注文番号・ステータス）
        Row(
          children: <Widget>[
            Text("No.${order.orderNumber}", style: AppTextTheme.cardTitle.copyWith(fontSize: 16)),
            const Spacer(),
            AppBadge(text: order.statusText, variant: _getStatusBadgeVariant(order.status)),
          ],
        ),

        const SizedBox(height: 8),

        // 顧客名・合計金額
        Row(
          children: <Widget>[
            Icon(LucideIcons.user, size: 16, color: AppColors.mutedForeground),
            const SizedBox(width: 4),
            Text(order.displayCustomerName, style: AppTextTheme.cardDescription),
            const Spacer(),
            Text(
              "¥${order.totalAmount.toStringAsFixed(0)}",
              style: AppTextTheme.priceText.copyWith(fontSize: 14),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 注文時刻・経過時間
        Row(
          children: <Widget>[
            Icon(LucideIcons.clock, size: 16, color: AppColors.mutedForeground),
            const SizedBox(width: 4),
            Text(order.formatTime(order.orderedAt), style: AppTextTheme.cardDescription),
            const Spacer(),
            Text(
              order.formatElapsedTime(order.elapsedTime),
              style: AppTextTheme.cardDescription.copyWith(
                color: order.getElapsedTimeColor(order.elapsedTime),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 注文進行状況
        OrderProgress(order: order, isCompact: true, showSteps: false),

        const SizedBox(height: 12),

        // 注文アイテム
        _buildOrderItems(),

        const SizedBox(height: 12),

        // アクションボタン
        _buildActionButtons(),
      ],
    ),
  );

  /// ステータスバッジのバリアントを取得
  BadgeVariant _getStatusBadgeVariant(core_enums.OrderStatus status) {
    switch (status) {
      case core_enums.OrderStatus.pending:
        return BadgeVariant.warning;
      case core_enums.OrderStatus.confirmed:
        return BadgeVariant.primary;
      case core_enums.OrderStatus.preparing:
        return BadgeVariant.cooking;
      case core_enums.OrderStatus.ready:
        return BadgeVariant.complete;
      case core_enums.OrderStatus.delivered:
        return BadgeVariant.success;
      case core_enums.OrderStatus.completed:
        return BadgeVariant.success;
      case core_enums.OrderStatus.cancelled:
        return BadgeVariant.danger;
      case core_enums.OrderStatus.refunded:
        return BadgeVariant.secondary;
    }
  }

  /// 注文アイテムを表示（一時的なダミーデータ）
  Widget _buildOrderItems() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(4)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _getTemporaryItems()
          .map(
            (String item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: <Widget>[
                  Icon(LucideIcons.circle, size: 6, color: AppColors.mutedForeground),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item, style: AppTextTheme.cardDescription.copyWith(fontSize: 12)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );

  /// OrderItemありのカード
  Widget _buildCardWithItems(Map<String, dynamic>? orderData) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ヘッダー行（注文番号・ステータス）
        Row(
          children: <Widget>[
            Text("No.${order.orderNumber}", style: AppTextTheme.cardTitle.copyWith(fontSize: 16)),
            const Spacer(),
            AppBadge(text: order.statusText, variant: _getStatusBadgeVariant(order.status)),
          ],
        ),

        const SizedBox(height: 8),

        // 顧客名・合計金額
        Row(
          children: <Widget>[
            Icon(LucideIcons.user, size: 16, color: AppColors.mutedForeground),
            const SizedBox(width: 4),
            Text(order.displayCustomerName, style: AppTextTheme.cardDescription),
            const Spacer(),
            Text(
              "¥${order.totalAmount.toStringAsFixed(0)}",
              style: AppTextTheme.priceText.copyWith(fontSize: 14),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 注文時刻・経過時間
        Row(
          children: <Widget>[
            Icon(LucideIcons.clock, size: 16, color: AppColors.mutedForeground),
            const SizedBox(width: 4),
            Text(order.formatTime(order.orderedAt), style: AppTextTheme.cardDescription),
            const Spacer(),
            Text(
              order.formatElapsedTime(order.elapsedTime),
              style: AppTextTheme.cardDescription.copyWith(
                color: order.priority >= 3 ? AppColors.danger : AppColors.mutedForeground,
                fontWeight: order.priority >= 3 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),

        // 注文アイテムリスト
        if (orderData != null && orderData["items"] != null) ...<Widget>[
          const SizedBox(height: 12),
          _buildOrderItemsList(orderData["items"] as List<OrderItem>),
        ],

        const SizedBox(height: 12),

        // 進行状況
        OrderProgress(order: order),

        const SizedBox(height: 16),

        // アクションボタン
        _buildActionButtons(),
      ],
    ),
  );

  /// 注文アイテムリストを構築
  Widget _buildOrderItemsList(List<OrderItem> items) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "注文アイテム:",
            style: AppTextTheme.cardDescription.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ...items
              .map(
                (OrderItem item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          "×${item.quantity} ${item.menuItemId}", // 実際にはmenu_item名を取得する必要あり
                          style: AppTextTheme.cardDescription.copyWith(fontSize: 12),
                        ),
                      ),
                      Text(
                        "¥${item.subtotal}",
                        style: AppTextTheme.cardDescription.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
              ,
        ],
      ),
    );

  /// 一時的なアイテムリスト（後でOrderItemから取得）
  List<String> _getTemporaryItems() => <String>[
    "アイテム ${order.id?.substring(0, 4) ?? '???'}",
    "合計 ${order.formattedTotalAmount}",
  ];

  /// アクションボタンを表示
  Widget _buildActionButtons() {
    switch (order.status) {
      case core_enums.OrderStatus.pending:
        return AppButton(
          text: "調理開始",
          variant: ButtonVariant.cooking,
          size: ButtonSize.small,
          isFullWidth: true,
          icon: const Icon(LucideIcons.play),
          onPressed: () => onStatusUpdate?.call(core_enums.OrderStatus.preparing),
        );

      case core_enums.OrderStatus.preparing:
        return AppButton(
          text: "調理完了",
          variant: ButtonVariant.complete,
          size: ButtonSize.small,
          isFullWidth: true,
          icon: const Icon(LucideIcons.check),
          onPressed: () => onStatusUpdate?.call(core_enums.OrderStatus.ready),
        );

      case core_enums.OrderStatus.ready:
        return AppButton(
          text: "提供完了",
          size: ButtonSize.small,
          isFullWidth: true,
          icon: const Icon(LucideIcons.heart),
          onPressed: () => onStatusUpdate?.call(core_enums.OrderStatus.delivered),
        );

      case core_enums.OrderStatus.confirmed:
      case core_enums.OrderStatus.delivered:
      case core_enums.OrderStatus.completed:
      case core_enums.OrderStatus.cancelled:
      case core_enums.OrderStatus.refunded:
        return const SizedBox.shrink();
    }
  }
}
