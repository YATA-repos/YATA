import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_badge.dart";
import "../../../../shared/widgets/common/app_button.dart";
import "../../../../shared/widgets/common/app_card.dart";
import "../../../../shared/widgets/common/app_progress_bar.dart";

/// 注文カードコンポーネント
///
/// 進行中注文の表示、AppProgressBar + AppButton統合
class OrderCard extends StatelessWidget {
  const OrderCard({
    required this.orderNumber,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.progress,
    super.key,
    this.tableNumber,
    this.orderTime,
    this.estimatedTime,
    this.actions,
    this.onTap,
    this.onStatusChange,
    this.priorityLevel,
    this.specialInstructions,
  });

  /// 注文番号
  final String orderNumber;

  /// 顧客名
  final String customerName;

  /// 注文アイテム一覧
  final List<OrderCardItem> items;

  /// 合計金額
  final num totalAmount;

  /// 注文状態
  final OrderStatus status;

  /// 進捗率（0.0 - 1.0）
  final double progress;

  /// テーブル番号
  final String? tableNumber;

  /// 注文時刻
  final DateTime? orderTime;

  /// 予想完了時刻
  final DateTime? estimatedTime;

  /// アクションボタン
  final List<Widget>? actions;

  /// タップ処理
  final VoidCallback? onTap;

  /// ステータス変更処理
  final void Function(OrderStatus newStatus)? onStatusChange;

  /// 優先レベル
  final OrderPriority? priorityLevel;

  /// 特別指示
  final String? specialInstructions;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: priorityLevel == OrderPriority.high ? CardVariant.highlighted : CardVariant.basic,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(context),
        const SizedBox(height: AppLayout.spacing4),
        _buildProgress(context),
        const SizedBox(height: AppLayout.spacing4),
        _buildItems(context),
        if (specialInstructions != null) ...<Widget>[
          const SizedBox(height: AppLayout.spacing3),
          _buildSpecialInstructions(context),
        ],
        const SizedBox(height: AppLayout.spacing4),
        _buildFooter(context),
      ],
    ),
  );

  Widget _buildHeader(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  "注文 #$orderNumber",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppLayout.spacing2),
                StatusBadge(status: _getStatusText()),
                if (priorityLevel == OrderPriority.high) ...<Widget>[
                  const SizedBox(width: AppLayout.spacing2),
                  AppBadge.text("優先", variant: BadgeVariant.warning, size: BadgeSize.small),
                ],
              ],
            ),
            const SizedBox(height: AppLayout.spacing1),
            Row(
              children: <Widget>[
                Icon(
                  LucideIcons.user,
                  size: AppLayout.iconSizeSm,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: AppLayout.spacing1),
                Text(
                  customerName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
                ),
                if (tableNumber != null) ...<Widget>[
                  const SizedBox(width: AppLayout.spacing3),
                  Icon(
                    LucideIcons.mapPin,
                    size: AppLayout.iconSizeSm,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: AppLayout.spacing1),
                  Text(
                    "テーブル $tableNumber",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      if (orderTime != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              _formatTime(orderTime!),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
            ),
            if (estimatedTime != null) ...<Widget>[
              const SizedBox(height: AppLayout.spacing1),
              Text(
                "完了予定: ${_formatTime(estimatedTime!)}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
    ],
  );

  Widget _buildProgress(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "進捗状況",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            "${(progress * 100).toInt()}%",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      const SizedBox(height: AppLayout.spacing2),
      AppProgressBar(value: progress, height: 6, valueColor: _getProgressColor()),
    ],
  );

  Widget _buildItems(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      ...items
          .take(3)
          .map(
            (OrderCardItem item) => Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.spacing2),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(AppLayout.spacing1),
                    ),
                    child: Center(
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppLayout.spacing2),
                  Expanded(child: Text(item.name, style: const TextStyle(fontSize: 14))),
                  if (item.status != null) StatusBadge(status: item.status!, size: BadgeSize.small),
                ],
              ),
            ),
          ),
      if (items.length > 3)
        Text(
          "他 ${items.length - 3}件",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
        ),
    ],
  );

  Widget _buildSpecialInstructions(BuildContext context) => Container(
    padding: AppLayout.padding3,
    decoration: BoxDecoration(
      color: AppColors.warningMuted,
      borderRadius: BorderRadius.circular(AppLayout.spacing2),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: <Widget>[
        Icon(LucideIcons.messageSquare, size: AppLayout.iconSizeSm, color: AppColors.warning),
        const SizedBox(width: AppLayout.spacing2),
        Expanded(
          child: Text(
            specialInstructions!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
          ),
        ),
      ],
    ),
  );

  Widget _buildFooter(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "合計金額",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
            ),
            Text(
              "¥${_formatCurrency(totalAmount)}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      if (actions != null)
        Wrap(spacing: AppLayout.spacing2, children: actions!)
      else
        _buildDefaultActions(),
    ],
  );

  Widget _buildDefaultActions() {
    switch (status) {
      case OrderStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppButton.text(
              "開始",
              onPressed: () => onStatusChange?.call(OrderStatus.preparing),
              size: ButtonSize.small,
            ),
            const SizedBox(width: AppLayout.spacing2),
            AppButton.text(
              "キャンセル",
              onPressed: () => onStatusChange?.call(OrderStatus.canceled),
              variant: ButtonVariant.danger,
              size: ButtonSize.small,
            ),
          ],
        );
      case OrderStatus.confirmed:
        return AppButton.text(
          "調理開始",
          onPressed: () => onStatusChange?.call(OrderStatus.preparing),
          size: ButtonSize.small,
        );
      case OrderStatus.preparing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppButton.text(
              "完了",
              onPressed: () => onStatusChange?.call(OrderStatus.ready),
              size: ButtonSize.small,
            ),
            const SizedBox(width: AppLayout.spacing2),
            AppButton.text(
              "一時停止",
              onPressed: () => onStatusChange?.call(OrderStatus.pending),
              variant: ButtonVariant.ghost,
              size: ButtonSize.small,
            ),
          ],
        );
      case OrderStatus.ready:
        return AppButton.text(
          "提供済み",
          onPressed: () => onStatusChange?.call(OrderStatus.completed),
          size: ButtonSize.small,
        );
      case OrderStatus.delivered:
        return AppButton.text(
          "完了",
          onPressed: () => onStatusChange?.call(OrderStatus.completed),
          size: ButtonSize.small,
        );
      case OrderStatus.completed:
      case OrderStatus.canceled:
      case OrderStatus.refunded:
        return const SizedBox.shrink();
    }
  }

  Color _getProgressColor() {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.preparing:
        return AppColors.primary;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.canceled:
        return AppColors.danger;
      case OrderStatus.refunded:
        return AppColors.danger;
    }
  }

  String _getStatusText() {
    switch (status) {
      case OrderStatus.pending:
        return "待機中";
      case OrderStatus.confirmed:
        return "確認済み";
      case OrderStatus.preparing:
        return "調理中";
      case OrderStatus.ready:
        return "完了";
      case OrderStatus.delivered:
        return "配達済み";
      case OrderStatus.completed:
        return "提供済み";
      case OrderStatus.canceled:
        return "キャンセル";
      case OrderStatus.refunded:
        return "返金済み";
    }
  }

  String _formatTime(DateTime time) =>
      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

  String _formatCurrency(num amount) => amount.toInt().toString().replaceAllMapped(
    RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
    (Match match) => "${match[1]},",
  );
}

/// 注文アイテム情報
class OrderCardItem {
  const OrderCardItem({
    required this.name,
    required this.quantity,
    this.status,
    this.specialRequest,
  });

  /// アイテム名
  final String name;

  /// 数量
  final int quantity;

  /// アイテム状態
  final String? status;

  /// 特別要求
  final String? specialRequest;
}

/// 注文優先度列挙型
enum OrderPriority {
  low, // 低
  normal, // 標準
  high, // 高
}
