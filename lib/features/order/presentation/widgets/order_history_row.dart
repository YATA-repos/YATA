import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/app_config.dart";
import "../../../../core/constants/enums.dart" show OrderStatus;
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_chip.dart";
import "../../../../shared/widgets/common/app_icon_button.dart";
import "../../../../shared/widgets/common/app_list_tile.dart";

/// 注文履歴行表示コンポーネント
///
/// 注文履歴画面で使用され、過去の注文情報を表示します。
class OrderHistoryRow extends StatelessWidget {
  const OrderHistoryRow({
    required this.orderNumber,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    super.key,
    this.customerName,
    this.tableNumber,
    this.itemCount,
    this.paymentMethod,
    this.notes,
    this.onTap,
    this.onReorder,
    this.onViewDetails,
    this.selected = false,
    this.enabled = true,
  });

  /// 注文番号
  final String orderNumber;

  /// 注文日時
  final DateTime orderDate;

  /// 注文ステータス
  final OrderStatus status;

  /// 合計金額
  final double totalAmount;

  /// 顧客名
  final String? customerName;

  /// テーブル番号
  final String? tableNumber;

  /// アイテム数
  final int? itemCount;

  /// 支払い方法
  final String? paymentMethod;

  /// メモ
  final String? notes;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  /// 再注文時のコールバック
  final VoidCallback? onReorder;

  /// 詳細表示時のコールバック
  final VoidCallback? onViewDetails;

  /// 選択状態
  final bool selected;

  /// 有効状態
  final bool enabled;

  @override
  Widget build(BuildContext context) => AppListTile(
    leading: _buildLeadingIcon(),
    title: _buildTitle(context),
    subtitle: _buildSubtitle(context),
    trailing: _buildTrailing(context),
    onTap: onTap ?? onViewDetails,
    selected: selected,
    enabled: enabled,
  );

  /// 先頭アイコン
  Widget _buildLeadingIcon() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: _getStatusColor().withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
  );

  /// タイトルセクション
  Widget _buildTitle(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          "注文 #$orderNumber",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: enabled ? AppColors.foreground : AppColors.mutedForeground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: AppLayout.spacing2),
      AppChip(label: _getStatusText(), variant: _getStatusChipVariant(), size: ChipSize.small),
    ],
  );

  /// サブタイトルセクション
  Widget _buildSubtitle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color subtitleColor = enabled
        ? AppColors.mutedForeground
        : AppColors.mutedForeground.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 4),
        // 顧客情報とテーブル番号
        Row(
          children: <Widget>[
            if (customerName != null) ...<Widget>[
              Icon(LucideIcons.user, size: 12, color: subtitleColor),
              const SizedBox(width: 4),
              Text(customerName!, style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor)),
              if (tableNumber != null) ...<Widget>[
                const SizedBox(width: AppLayout.spacing3),
                Text("•", style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor)),
                const SizedBox(width: AppLayout.spacing3),
              ],
            ],
            if (tableNumber != null) ...<Widget>[
              Icon(LucideIcons.mapPin, size: 12, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                "テーブル $tableNumber",
                style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        // 注文日時と金額
        Row(
          children: <Widget>[
            Icon(LucideIcons.clock, size: 12, color: subtitleColor),
            const SizedBox(width: 4),
            Text(
              _formatOrderDate(orderDate),
              style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
            ),
            const Spacer(),
            Text(
              "${AppConfig.currencySymbol}${totalAmount.toStringAsFixed(0)}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (itemCount != null) ...<Widget>[
              const SizedBox(width: AppLayout.spacing2),
              Text(
                "($itemCount点)",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtitleColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 末尾セクション
  Widget? _buildTrailing(BuildContext context) {
    if (onReorder == null) {
      return null;
    }

    return AppIconButton(
      icon: LucideIcons.repeat,
      onPressed: enabled && _canReorder() ? onReorder : null,
      tooltip: "再注文",
    );
  }

  /// ステータスに基づく色を取得
  Color _getStatusColor() {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.preparing:
        return AppColors.cooking;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.delivered:
        return AppColors.complete;
      case OrderStatus.completed:
        return AppColors.complete;
      case OrderStatus.canceled:
        return AppColors.cancel;
      case OrderStatus.refunded:
        return AppColors.danger;
    }
  }

  /// ステータスに基づくアイコンを取得
  IconData _getStatusIcon() {
    switch (status) {
      case OrderStatus.pending:
        return LucideIcons.clock;
      case OrderStatus.confirmed:
        return LucideIcons.checkCircle;
      case OrderStatus.preparing:
        return LucideIcons.loader;
      case OrderStatus.ready:
        return LucideIcons.bell;
      case OrderStatus.delivered:
        return LucideIcons.truck;
      case OrderStatus.completed:
        return LucideIcons.checkCircle2;
      case OrderStatus.canceled:
        return LucideIcons.xCircle;
      case OrderStatus.refunded:
        return LucideIcons.rotateCcw;
    }
  }

  /// ステータステキストを取得
  String _getStatusText() {
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

  /// ステータスに基づくチップバリアントを取得
  ChipVariant _getStatusChipVariant() {
    switch (status) {
      case OrderStatus.pending:
        return ChipVariant.warning;
      case OrderStatus.confirmed:
        return ChipVariant.success;
      case OrderStatus.preparing:
        return ChipVariant.warning;
      case OrderStatus.ready:
        return ChipVariant.success;
      case OrderStatus.delivered:
        return ChipVariant.success;
      case OrderStatus.completed:
        return ChipVariant.success;
      case OrderStatus.canceled:
        return ChipVariant.danger;
      case OrderStatus.refunded:
        return ChipVariant.danger;
    }
  }

  /// 再注文可能かどうかを判定
  bool _canReorder() => status == OrderStatus.completed || status == OrderStatus.delivered;

  /// 注文日時のフォーマット
  String _formatOrderDate(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // 今日
      return "今日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays == 1) {
      // 昨日
      return "昨日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays < 7) {
      // 今週
      final List<String> weekdays = <String>["月", "火", "水", "木", "金", "土", "日"];
      final String weekday = weekdays[dateTime.weekday - 1];
      return "$weekday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else {
      // それ以外
      return "${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
  }
}

/// 注文履歴情報用データクラス
class OrderHistoryInfo {
  const OrderHistoryInfo({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    this.customerName,
    this.customerPhone,
    this.tableNumber,
    this.itemCount,
    this.paymentMethod,
    this.paymentStatus,
    this.notes,
    this.items,
    this.discountAmount,
    this.taxAmount,
    this.tipAmount,
    this.estimatedTime,
    this.actualTime,
    this.rating,
  });

  /// 注文ID
  final String id;

  /// 注文番号
  final String orderNumber;

  /// 注文日時
  final DateTime orderDate;

  /// 注文ステータス
  final OrderStatus status;

  /// 合計金額
  final double totalAmount;

  /// 顧客名
  final String? customerName;

  /// 顧客電話番号
  final String? customerPhone;

  /// テーブル番号
  final String? tableNumber;

  /// アイテム数
  final int? itemCount;

  /// 支払い方法
  final String? paymentMethod;

  /// 支払いステータス
  final String? paymentStatus;

  /// メモ
  final String? notes;

  /// 注文アイテムリスト
  final List<OrderItemInfo>? items;

  /// 割引金額
  final double? discountAmount;

  /// 税金額
  final double? taxAmount;

  /// チップ金額
  final double? tipAmount;

  /// 推定時間（分）
  final int? estimatedTime;

  /// 実際の時間（分）
  final int? actualTime;

  /// 評価（1-5）
  final int? rating;

  /// 注文から経過した時間を計算
  Duration get elapsedTime => DateTime.now().difference(orderDate);

  /// 注文の年数を取得
  int get ageInDays => elapsedTime.inDays;

  /// 小計金額を計算
  double get subtotalAmount {
    double subtotal = totalAmount;
    if (taxAmount != null) {
      subtotal -= taxAmount!;
    }
    if (tipAmount != null) {
      subtotal -= tipAmount!;
    }
    if (discountAmount != null) {
      subtotal += discountAmount!;
    }
    return subtotal;
  }

  /// 注文が完了しているかどうか
  bool get isCompleted => status == OrderStatus.completed || status == OrderStatus.delivered;

  /// 注文がキャンセルされているかどうか
  bool get isCancelled => status == OrderStatus.canceled || status == OrderStatus.refunded;

  /// 再注文可能かどうか
  bool get canReorder => isCompleted;
}

/// 注文アイテム情報用データクラス
class OrderItemInfo {
  const OrderItemInfo({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.options,
    this.specialInstructions,
  });

  /// アイテムID
  final String id;

  /// アイテム名
  final String name;

  /// 数量
  final int quantity;

  /// 単価
  final double unitPrice;

  /// オプション
  final List<String>? options;

  /// 特別指示
  final String? specialInstructions;

  /// 小計を計算
  double get subtotal => unitPrice * quantity;
}

/// 注文履歴リスト表示用ウィジェット
class OrderHistoryList extends StatelessWidget {
  const OrderHistoryList({
    required this.orders,
    super.key,
    this.onOrderTap,
    this.onReorder,
    this.onViewDetails,
    this.selectedOrders = const <String>{},
    this.showDividers = true,
    this.groupByDate = false,
  });

  /// 注文リスト
  final List<OrderHistoryInfo> orders;

  /// 注文タップ時のコールバック
  final void Function(OrderHistoryInfo order)? onOrderTap;

  /// 再注文時のコールバック
  final void Function(OrderHistoryInfo order)? onReorder;

  /// 詳細表示時のコールバック
  final void Function(OrderHistoryInfo order)? onViewDetails;

  /// 選択された注文IDセット
  final Set<String> selectedOrders;

  /// 区切り線表示
  final bool showDividers;

  /// 日付でグループ化
  final bool groupByDate;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _buildEmptyState(context);
    }

    if (groupByDate) {
      return _buildGroupedList(context);
    }

    return _buildSimpleList(context);
  }

  /// シンプルなリスト表示
  Widget _buildSimpleList(BuildContext context) => ListView.separated(
    itemCount: orders.length,
    separatorBuilder: (BuildContext context, int index) =>
        showDividers ? const Divider(height: 1, indent: 56) : const SizedBox.shrink(),
    itemBuilder: (BuildContext context, int index) {
      final OrderHistoryInfo order = orders[index];
      final bool isSelected = selectedOrders.contains(order.id);

      return OrderHistoryRow(
        orderNumber: order.orderNumber,
        orderDate: order.orderDate,
        status: order.status,
        totalAmount: order.totalAmount,
        customerName: order.customerName,
        tableNumber: order.tableNumber,
        itemCount: order.itemCount,
        selected: isSelected,
        onTap: onOrderTap != null ? () => onOrderTap!(order) : null,
        onReorder: onReorder != null ? () => onReorder!(order) : null,
        onViewDetails: onViewDetails != null ? () => onViewDetails!(order) : null,
      );
    },
  );

  /// 日付でグループ化されたリスト表示
  Widget _buildGroupedList(BuildContext context) {
    final Map<String, List<OrderHistoryInfo>> groupedOrders = <String, List<OrderHistoryInfo>>{};

    for (final OrderHistoryInfo order in orders) {
      final String dateKey =
          "${order.orderDate.year}/${order.orderDate.month}/${order.orderDate.day}";
      groupedOrders.putIfAbsent(dateKey, () => <OrderHistoryInfo>[]).add(order);
    }

    final List<String> sortedKeys = groupedOrders.keys.toList()
      ..sort((String a, String b) => b.compareTo(a)); // 新しい日付順

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (BuildContext context, int index) {
        final String dateKey = sortedKeys[index];
        final List<OrderHistoryInfo> dayOrders = groupedOrders[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: AppLayout.padding4,
              child: Text(
                _formatDateHeader(dayOrders.first.orderDate),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...dayOrders.map((OrderHistoryInfo order) {
              final bool isSelected = selectedOrders.contains(order.id);
              return OrderHistoryRow(
                orderNumber: order.orderNumber,
                orderDate: order.orderDate,
                status: order.status,
                totalAmount: order.totalAmount,
                customerName: order.customerName,
                tableNumber: order.tableNumber,
                itemCount: order.itemCount,
                selected: isSelected,
                onTap: onOrderTap != null ? () => onOrderTap!(order) : null,
                onReorder: onReorder != null ? () => onReorder!(order) : null,
                onViewDetails: onViewDetails != null ? () => onViewDetails!(order) : null,
              );
            }),
            const SizedBox(height: AppLayout.spacing4),
          ],
        );
      },
    );
  }

  /// 空状態の表示
  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          LucideIcons.fileText,
          size: 64,
          color: AppColors.mutedForeground.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          "注文履歴がありません",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 8),
        Text(
          "過去の注文がここに表示されます",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground.withValues(alpha: 0.7)),
        ),
      ],
    ),
  );

  /// 日付ヘッダーのフォーマット
  String _formatDateHeader(DateTime date) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date);

    if (difference.inDays == 0) {
      return "今日";
    } else if (difference.inDays == 1) {
      return "昨日";
    } else if (difference.inDays < 7) {
      final List<String> weekdays = <String>["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日"];
      return weekdays[date.weekday - 1];
    } else {
      return "${date.year}年${date.month}月${date.day}日";
    }
  }
}
