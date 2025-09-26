import "package:flutter/material.dart";

import "../../../core/constants/enums.dart";
import "../../../features/order/models/order_model.dart";
import "../../components/data_display/status_badge.dart";
import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// 注文履歴一覧で使用する注文行コンポーネント。
class YataOrderHistoryTile extends StatelessWidget {
  /// [YataOrderHistoryTile]を生成する。
  const YataOrderHistoryTile({
    required this.order,
    super.key,
    this.onTap,
    this.showDivider = true,
  });

  /// 注文データ。
  final Order order;

  /// タップ時のコールバック。
  final VoidCallback? onTap;

  /// 下部に区切り線を表示するかどうか。
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    
    // 簡単な日時フォーマット関数
    String formatDateTime(DateTime dateTime, {bool full = false}) {
      if (full) {
        return "${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} "
               "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      } else {
        return "${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} "
               "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      }
    }
    
    // 通貨フォーマット関数
    String formatCurrency(int amount) {
      return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match match) => "${match[1]},",
      );
    }

    // ステータスバッジのタイプを決定
    YataStatusBadgeType badgeType;
    switch (order.status) {
      case OrderStatus.completed:
        badgeType = YataStatusBadgeType.success;
        break;
      case OrderStatus.cancelled:
        badgeType = YataStatusBadgeType.error;
        break;
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        badgeType = YataStatusBadgeType.warning;
        break;
      case OrderStatus.ready:
      case OrderStatus.delivered:
        badgeType = YataStatusBadgeType.info;
        break;
      case OrderStatus.refunded:
        badgeType = YataStatusBadgeType.neutral;
        break;
    }

    // 支払い方法の表示名
    String paymentMethodName;
    switch (order.paymentMethod) {
      case PaymentMethod.cash:
        paymentMethodName = "現金";
        break;
      case PaymentMethod.card:
        paymentMethodName = "カード";
        break;
      case PaymentMethod.other:
        paymentMethodName = "その他";
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: onTap,
          borderRadius: YataRadiusTokens.borderRadiusSmall,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: YataSpacingTokens.md,
              horizontal: YataSpacingTokens.sm,
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isNarrow = constraints.maxWidth < 640;

                if (isNarrow) {
                  // 狭い画面用のレイアウト
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            order.orderNumber ?? "No.${order.id.substring(0, 8)}",
                            style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          YataStatusBadge(
                            label: order.status.displayName,
                            type: badgeType,
                          ),
                        ],
                      ),
                      const SizedBox(height: YataSpacingTokens.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            formatDateTime(order.orderedAt),
                            style: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall)
                                .copyWith(color: YataColorTokens.textSecondary),
                          ),
                          Text(
                            "¥${formatCurrency(order.totalAmount)}",
                            style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (order.customerName != null) ...<Widget>[
                        const SizedBox(height: YataSpacingTokens.xs),
                        Text(
                          order.customerName!,
                          style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium)
                              .copyWith(color: YataColorTokens.textPrimary),
                        ),
                      ],
                      if (order.notes != null && order.notes!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: YataSpacingTokens.xs),
                        Text(
                          order.notes!,
                          style: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall)
                              .copyWith(color: YataColorTokens.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  );
                }

                // 広い画面用のレイアウト
                return Row(
                  children: <Widget>[
                    // 注文番号とステータス
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            order.orderNumber ?? "No.${order.id.substring(0, 8)}",
                            style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: YataSpacingTokens.xs),
                          YataStatusBadge(
                            label: order.status.displayName,
                            type: badgeType,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: YataSpacingTokens.md),
                    // 注文日時
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "注文日時",
                            style: (textTheme.labelSmall ?? YataTypographyTokens.labelSmall)
                                .copyWith(color: YataColorTokens.textSecondary),
                          ),
                          const SizedBox(height: YataSpacingTokens.xs),
                          Text(
                            formatDateTime(order.orderedAt, full: true),
                            style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: YataSpacingTokens.md),
                    // 顧客名
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "顧客名",
                            style: (textTheme.labelSmall ?? YataTypographyTokens.labelSmall)
                                .copyWith(color: YataColorTokens.textSecondary),
                          ),
                          const SizedBox(height: YataSpacingTokens.xs),
                          Text(
                            order.customerName ?? "-",
                            style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: YataSpacingTokens.md),
                    // 支払い方法
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "支払い",
                            style: (textTheme.labelSmall ?? YataTypographyTokens.labelSmall)
                                .copyWith(color: YataColorTokens.textSecondary),
                          ),
                          const SizedBox(height: YataSpacingTokens.xs),
                          Text(
                            paymentMethodName,
                            style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: YataSpacingTokens.md),
                    // 合計金額
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            "合計",
                            style: (textTheme.labelSmall ?? YataTypographyTokens.labelSmall)
                                .copyWith(color: YataColorTokens.textSecondary),
                          ),
                          const SizedBox(height: YataSpacingTokens.xs),
                          Text(
                            "¥${formatCurrency(order.totalAmount)}",
                            style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null) ...<Widget>[
                      const SizedBox(width: YataSpacingTokens.sm),
                      const Icon(
                        Icons.chevron_right,
                        color: YataColorTokens.textSecondary,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: YataSpacingTokens.lg,
            thickness: 1,
            color: YataColorTokens.divider,
          ),
      ],
    );
  }
}