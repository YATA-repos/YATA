import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_badge.dart";
import "../../../../shared/widgets/common/app_button.dart";
import "../../../../shared/widgets/common/app_card.dart";

/// 注文優先度列挙型
enum OrderPriority {
  low, // 低
  normal, // 通常
  high, // 高
  urgent, // 緊急
}

/// 注文キューカード
///
/// 注文キュー画面の右側で使用され、進行中の注文を表示します。
class OrderQueueCard extends StatelessWidget {
  const OrderQueueCard({
    required this.orderNumber,
    required this.orderTime,
    required this.status,
    super.key,
    this.tableNumber,
    this.customerName,
    this.estimatedTime,
    this.elapsedTime,
    this.priority = OrderPriority.normal,
    this.itemCount,
    this.isOverdue = false,
    this.onTap,
    this.onCancel,
    this.onComplete,
    this.onPriorityChange,
    this.isCompact = false,
  });

  /// 注文番号
  final String orderNumber;

  /// 注文時刻
  final DateTime orderTime;

  /// 注文ステータス
  final OrderStatus status;

  /// テーブル番号
  final String? tableNumber;

  /// 顧客名
  final String? customerName;

  /// 推定時間（分）
  final int? estimatedTime;

  /// 経過時間（分）
  final int? elapsedTime;

  /// 優先度
  final OrderPriority priority;

  /// アイテム数
  final int? itemCount;

  /// 時間超過フラグ
  final bool isOverdue;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  /// キャンセル時のコールバック
  final VoidCallback? onCancel;

  /// 完了時のコールバック
  final VoidCallback? onComplete;

  /// 優先度変更時のコールバック
  final void Function(OrderPriority priority)? onPriorityChange;

  /// コンパクト表示
  final bool isCompact;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: _getCardVariant(),
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(border: _getBorderDecoration()),
      child: Padding(
        padding: isCompact ? AppLayout.padding3 : AppLayout.padding4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildHeader(context),
            if (!isCompact) ...<Widget>[
              const SizedBox(height: AppLayout.spacing3),
              _buildInfo(context),
            ],
            const SizedBox(height: AppLayout.spacing3),
            _buildTimeBadges(context),
            if (!isCompact && (onComplete != null || onCancel != null)) ...<Widget>[
              const SizedBox(height: AppLayout.spacing4),
              _buildActions(context),
            ],
          ],
        ),
      ),
    ),
  );

  /// ヘッダーセクション（注文番号、ステータス、優先度）
  Widget _buildHeader(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "#$orderNumber",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            if (tableNumber != null || customerName != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                _getSubtitleText(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(width: AppLayout.spacing2),
      _buildStatusAndPriorityBadges(),
    ],
  );

  /// 情報セクション（アイテム数など）
  Widget _buildInfo(BuildContext context) {
    if (itemCount == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: <Widget>[
        Icon(LucideIcons.package, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: AppLayout.spacing2),
        Text(
          "$itemCount点",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 時間バッジセクション
  Widget _buildTimeBadges(BuildContext context) => Row(
    children: <Widget>[
      // 経過時間バッジ
      if (elapsedTime != null)
        AppBadge.text(
          "$elapsedTime分経過",
          variant: isOverdue ? BadgeVariant.danger : BadgeVariant.count,
          size: BadgeSize.small,
        ),
      if (elapsedTime != null && estimatedTime != null) const SizedBox(width: AppLayout.spacing2),
      // 推定時間バッジ
      if (estimatedTime != null)
        AppBadge.text("予定$estimatedTime分", variant: BadgeVariant.success, size: BadgeSize.small),
      const Spacer(),
      // 注文時刻
      Text(
        _formatOrderTime(orderTime),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
      ),
    ],
  );

  /// ステータスと優先度バッジ
  Widget _buildStatusAndPriorityBadges() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      AppBadge.text(
        _getStatusText(status),
        variant: _getStatusBadgeVariant(status),
        size: BadgeSize.small,
      ),
      if (priority != OrderPriority.normal) ...<Widget>[
        const SizedBox(height: AppLayout.spacing1),
        AppBadge.text(
          _getPriorityText(priority),
          variant: _getPriorityBadgeVariant(priority),
          size: BadgeSize.small,
        ),
      ],
    ],
  );

  /// アクションボタンセクション
  Widget _buildActions(BuildContext context) => Row(
    children: <Widget>[
      if (onCancel != null) ...<Widget>[
        AppButton(
          onPressed: onCancel,
          variant: ButtonVariant.ghost,
          size: ButtonSize.small,
          child: const Text("キャンセル"),
        ),
        const SizedBox(width: AppLayout.spacing2),
      ],
      if (onComplete != null)
        Expanded(
          child: AppButton(
            onPressed: onComplete,
            variant: _getCompleteButtonVariant(),
            size: ButtonSize.small,
            isFullWidth: true,
            child: Text(_getCompleteButtonText()),
          ),
        ),
    ],
  );

  /// カードバリアントを取得
  CardVariant _getCardVariant() {
    if (isOverdue) {
      return CardVariant.highlighted;
    }
    if (priority == OrderPriority.urgent) {
      return CardVariant.highlighted;
    }
    return CardVariant.basic;
  }

  /// ボーダー装飾を取得
  Border? _getBorderDecoration() {
    if (isOverdue) {
      return Border.all(color: AppColors.danger.withValues(alpha: 0.3));
    }
    if (priority == OrderPriority.urgent) {
      return Border.all(color: AppColors.warning.withValues(alpha: 0.3));
    }
    return null;
  }

  /// サブタイトルテキストを取得
  String _getSubtitleText() {
    final List<String> parts = <String>[];
    if (tableNumber != null) {
      parts.add("テーブル $tableNumber");
    }
    if (customerName != null) {
      parts.add(customerName!);
    }
    return parts.join(" • ");
  }

  /// 注文時刻のフォーマット
  String _formatOrderTime(DateTime dateTime) =>
      "${dateTime.hour.toString().padLeft(2, "0")}:${dateTime.minute.toString().padLeft(2, "0")}";

  /// ステータステキストを取得（OrderHistoryRowから再利用）
  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return "待機中";
      case OrderStatus.confirmed:
        return "確認済み";
      case OrderStatus.preparing:
        return "調理中";
      case OrderStatus.ready:
        return "準備完了";
      case OrderStatus.delivered:
        return "配達済み";
      case OrderStatus.completed:
        return "完了";
      case OrderStatus.canceled:
        return "キャンセル";
      case OrderStatus.refunded:
        return "返金済み";
    }
  }

  /// ステータスバッジバリアントを取得
  BadgeVariant _getStatusBadgeVariant(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return BadgeVariant.warning;
      case OrderStatus.confirmed:
        return BadgeVariant.success;
      case OrderStatus.preparing:
        return BadgeVariant.warning;
      case OrderStatus.ready:
        return BadgeVariant.success;
      case OrderStatus.delivered:
        return BadgeVariant.success;
      case OrderStatus.completed:
        return BadgeVariant.success;
      case OrderStatus.canceled:
        return BadgeVariant.danger;
      case OrderStatus.refunded:
        return BadgeVariant.danger;
    }
  }

  /// 優先度テキストを取得
  String _getPriorityText(OrderPriority priority) {
    switch (priority) {
      case OrderPriority.low:
        return "低";
      case OrderPriority.normal:
        return "通常";
      case OrderPriority.high:
        return "高";
      case OrderPriority.urgent:
        return "緊急";
    }
  }

  /// 優先度バッジバリアントを取得
  BadgeVariant _getPriorityBadgeVariant(OrderPriority priority) {
    switch (priority) {
      case OrderPriority.low:
        return BadgeVariant.success;
      case OrderPriority.normal:
        return BadgeVariant.count;
      case OrderPriority.high:
        return BadgeVariant.warning;
      case OrderPriority.urgent:
        return BadgeVariant.danger;
    }
  }

  /// 完了ボタンのバリアントを取得
  ButtonVariant _getCompleteButtonVariant() {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return ButtonVariant.primary;
      case OrderStatus.preparing:
        return ButtonVariant.warning;
      case OrderStatus.ready:
        return ButtonVariant.primary;
      default:
        return ButtonVariant.secondary;
    }
  }

  /// 完了ボタンのテキストを取得
  String _getCompleteButtonText() {
    switch (status) {
      case OrderStatus.pending:
        return "確認";
      case OrderStatus.confirmed:
        return "調理開始";
      case OrderStatus.preparing:
        return "調理完了";
      case OrderStatus.ready:
        return "配達完了";
      default:
        return "完了";
    }
  }
}

/// 注文キュー情報用データクラス
class OrderQueueInfo {
  const OrderQueueInfo({
    required this.id,
    required this.orderNumber,
    required this.orderTime,
    required this.status,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.estimatedTime,
    this.priority = OrderPriority.normal,
    this.itemCount,
    this.totalAmount,
    this.specialInstructions,
    this.allergyInfo,
    this.items,
  });

  /// 注文ID
  final String id;

  /// 注文番号
  final String orderNumber;

  /// 注文時刻
  final DateTime orderTime;

  /// 注文ステータス
  final OrderStatus status;

  /// テーブル番号
  final String? tableNumber;

  /// 顧客名
  final String? customerName;

  /// 顧客電話番号
  final String? customerPhone;

  /// 推定時間（分）
  final int? estimatedTime;

  /// 優先度
  final OrderPriority priority;

  /// アイテム数
  final int? itemCount;

  /// 合計金額
  final double? totalAmount;

  /// 特別指示
  final String? specialInstructions;

  /// アレルギー情報
  final String? allergyInfo;

  /// 注文アイテムリスト
  final List<String>? items;

  /// 経過時間を計算（分）
  int get elapsedMinutes => DateTime.now().difference(orderTime).inMinutes;

  /// 時間超過かどうかを判定
  bool get isOverdue {
    if (estimatedTime == null) {
      return false;
    }
    return elapsedMinutes > estimatedTime!;
  }

  /// 残り時間を計算（分）
  int? get remainingMinutes {
    if (estimatedTime == null) {
      return null;
    }
    final int remaining = estimatedTime! - elapsedMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// 進捗率を計算（0.0-1.0）
  double? get progressRate {
    if (estimatedTime == null) {
      return null;
    }
    return (elapsedMinutes / estimatedTime!).clamp(0.0, 1.0);
  }

  /// コピーメソッド
  OrderQueueInfo copyWith({
    String? id,
    String? orderNumber,
    DateTime? orderTime,
    OrderStatus? status,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    int? estimatedTime,
    OrderPriority? priority,
    int? itemCount,
    double? totalAmount,
    String? specialInstructions,
    String? allergyInfo,
    List<String>? items,
  }) => OrderQueueInfo(
    id: id ?? this.id,
    orderNumber: orderNumber ?? this.orderNumber,
    orderTime: orderTime ?? this.orderTime,
    status: status ?? this.status,
    tableNumber: tableNumber ?? this.tableNumber,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    estimatedTime: estimatedTime ?? this.estimatedTime,
    priority: priority ?? this.priority,
    itemCount: itemCount ?? this.itemCount,
    totalAmount: totalAmount ?? this.totalAmount,
    specialInstructions: specialInstructions ?? this.specialInstructions,
    allergyInfo: allergyInfo ?? this.allergyInfo,
    items: items ?? this.items,
  );
}

/// 注文キューリスト表示用ウィジェット
class OrderQueueList extends StatelessWidget {
  const OrderQueueList({
    required this.orders,
    super.key,
    this.onOrderTap,
    this.onOrderCancel,
    this.onOrderComplete,
    this.onPriorityChange,
    this.compactMode = false,
    this.showCompleted = false,
    this.maxItems,
  });

  /// 注文リスト
  final List<OrderQueueInfo> orders;

  /// 注文タップ時のコールバック
  final void Function(OrderQueueInfo order)? onOrderTap;

  /// 注文キャンセル時のコールバック
  final void Function(OrderQueueInfo order)? onOrderCancel;

  /// 注文完了時のコールバック
  final void Function(OrderQueueInfo order)? onOrderComplete;

  /// 優先度変更時のコールバック
  final void Function(OrderQueueInfo order, OrderPriority priority)? onPriorityChange;

  /// コンパクトモード
  final bool compactMode;

  /// 完了した注文も表示
  final bool showCompleted;

  /// 最大表示件数
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final List<OrderQueueInfo> filteredOrders =
        orders
            .where((OrderQueueInfo order) => showCompleted || !_isCompleted(order.status))
            .toList()
          ..sort((OrderQueueInfo a, OrderQueueInfo b) {
            // 優先度順、次に経過時間順
            final int priorityCompare = _getPriorityValue(
              b.priority,
            ).compareTo(_getPriorityValue(a.priority));
            if (priorityCompare != 0) {
              return priorityCompare;
            }
            return a.orderTime.compareTo(b.orderTime);
          });

    final List<OrderQueueInfo> displayOrders = maxItems != null && filteredOrders.length > maxItems!
        ? filteredOrders.take(maxItems!).toList()
        : filteredOrders;

    if (displayOrders.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayOrders.length,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: compactMode ? AppLayout.spacing2 : AppLayout.spacing3),
      itemBuilder: (BuildContext context, int index) {
        final OrderQueueInfo order = displayOrders[index];

        return OrderQueueCard(
          orderNumber: order.orderNumber,
          orderTime: order.orderTime,
          status: order.status,
          tableNumber: order.tableNumber,
          customerName: order.customerName,
          estimatedTime: order.estimatedTime,
          elapsedTime: order.elapsedMinutes,
          priority: order.priority,
          itemCount: order.itemCount,
          isOverdue: order.isOverdue,
          isCompact: compactMode,
          onTap: onOrderTap != null ? () => onOrderTap!(order) : null,
          onCancel: onOrderCancel != null ? () => onOrderCancel!(order) : null,
          onComplete: onOrderComplete != null ? () => onOrderComplete!(order) : null,
          onPriorityChange: onPriorityChange != null
              ? (OrderPriority priority) => onPriorityChange!(order, priority)
              : null,
        );
      },
    );
  }

  /// 空状態の表示
  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(LucideIcons.clipboardCheck, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text(
          "キューに注文がありません",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 8),
        Text(
          "新しい注文をお待ちしています",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground.withValues(alpha: 0.7)),
        ),
      ],
    ),
  );

  /// ステータスが完了かどうかを判定
  bool _isCompleted(OrderStatus status) =>
      status == OrderStatus.completed ||
      status == OrderStatus.delivered ||
      status == OrderStatus.canceled ||
      status == OrderStatus.refunded;

  /// 優先度の数値を取得（ソート用）
  int _getPriorityValue(OrderPriority priority) {
    switch (priority) {
      case OrderPriority.low:
        return 0;
      case OrderPriority.normal:
        return 1;
      case OrderPriority.high:
        return 2;
      case OrderPriority.urgent:
        return 3;
    }
  }
}
