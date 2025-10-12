import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/components/data_display/status_badge.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../shared/utils/payment_method_label.dart";
import "../../shared/order_status_presentation.dart";
import "../view_data/order_history_view_data.dart";

/// 注文詳細ダイアログを生成する。
Widget createOrderDetailDialog({
  required OrderHistoryViewData order,
  required VoidCallback onClose,
}) => _OrderDetailDialog(order: order, onClose: onClose);

class _OrderDetailDialog extends StatelessWidget {
  const _OrderDetailDialog({required this.order, required this.onClose});

  final OrderHistoryViewData order;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      Positioned.fill(
        child: GestureDetector(
          key: const Key("orderDetailOverlay"),
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
      ),
      Center(
        child: GestureDetector(
          key: const Key("orderDetailDialogSurface"),
          behavior: HitTestBehavior.translucent,
          onTap: () {},
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Material(
              borderRadius: YataRadiusTokens.borderRadiusCard,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: YataColorTokens.surface,
                  borderRadius: YataRadiusTokens.borderRadiusCard,
                ),
                child: Column(
                  children: <Widget>[
                    // ダイアログヘッダー
                    Container(
                      padding: const EdgeInsets.all(YataSpacingTokens.lg),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: YataColorTokens.border)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              "注文詳細",
                              style:
                                  Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: YataColorTokens.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ) ??
                                  YataTypographyTokens.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close),
                            color: YataColorTokens.textSecondary,
                          ),
                        ],
                      ),
                    ),

                    // ダイアログコンテンツ
                    Expanded(child: _OrderDetailContent(order: order)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({required this.order});

  final OrderHistoryViewData order;

  @override
  Widget build(BuildContext context) {
    final DateFormat detailDateFormat = DateFormat("yyyy/MM/dd HH:mm:ss");
    final NumberFormat currencyFormat = NumberFormat("#,###");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(YataSpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 注文基本情報
          _DetailSection(
            title: "注文情報",
            child: Column(
              children: <Widget>[
                _DetailRow(label: "受付コード", value: order.orderNumber ?? "未設定"),
                _DetailRow(
                  label: "ステータス",
                  value: OrderStatusPresentation.label(order.status),
                  valueWidget: _OrderStatusBadge(status: order.status),
                ),
                _DetailRow(label: "顧客名", value: order.customerName ?? "名前なし"),
                _DetailRow(label: "支払い方法", value: paymentMethodLabel(order.paymentMethod)),
                _DetailRow(label: "注文日時", value: detailDateFormat.format(order.orderedAt)),
                if (order.completedAt != null)
                  _DetailRow(label: "完了日時", value: detailDateFormat.format(order.completedAt!)),
              ],
            ),
          ),

          const SizedBox(height: YataSpacingTokens.xl),

          // 注文明細
          _DetailSection(
            title: "注文明細",
            child: Column(
              children: <Widget>[
                ...order.items.map((OrderItemViewData item) => _OrderItemRow(item: item)),

                const Divider(height: YataSpacingTokens.lg),

                // 合計金額
                _DetailRow(
                  label: "小計",
                  value: "¥${currencyFormat.format(order.totalAmount)}",
                  isSubtotal: true,
                ),
                if (order.discountAmount > 0)
                  _DetailRow(
                    label: "割引",
                    value: "-¥${currencyFormat.format(order.discountAmount)}",
                    isDiscount: true,
                  ),
                _DetailRow(
                  label: "合計",
                  value: "¥${currencyFormat.format(order.actualAmount)}",
                  isTotal: true,
                ),
              ],
            ),
          ),

          // 備考（ある場合のみ）
          if (order.notes != null && order.notes!.isNotEmpty) ...<Widget>[
            const SizedBox(height: YataSpacingTokens.xl),
            _DetailSection(
              title: "備考",
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(YataSpacingTokens.md),
                decoration: BoxDecoration(
                  color: YataColorTokens.surfaceAlt,
                  borderRadius: YataRadiusTokens.borderRadiusSmall,
                ),
                child: Text(
                  order.notes!,
                  style:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: YataColorTokens.textPrimary) ??
                      YataTypographyTokens.bodyMedium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final YataStatusBadgeType badgeType = OrderStatusPresentation.badgeType(status);
    return YataStatusBadge(label: OrderStatusPresentation.label(status), type: badgeType);
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style:
            Theme.of(context).textTheme.titleMedium?.copyWith(
              color: YataColorTokens.textPrimary,
              fontWeight: FontWeight.w600,
            ) ??
            YataTypographyTokens.titleMedium,
      ),
      const SizedBox(height: YataSpacingTokens.md),
      child,
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueWidget,
    this.isSubtotal = false,
    this.isDiscount = false,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
  final bool isSubtotal;
  final bool isDiscount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: YataColorTokens.textSecondary,
          fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
        ) ??
        YataTypographyTokens.bodyMedium;

    final TextStyle valueStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDiscount ? YataColorTokens.warning : YataColorTokens.textPrimary,
          fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
        ) ??
        YataTypographyTokens.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 2, child: Text(label, style: labelStyle)),
          Expanded(
            flex: 3,
            child: valueWidget ?? Text(value, style: valueStyle, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItemViewData item;

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat("#,###");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 数量
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              "${item.quantity}x",
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: YataColorTokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ) ??
                  YataTypographyTokens.bodyMedium,
            ),
          ),

          const SizedBox(width: YataSpacingTokens.md),

          // メニュー名と詳細
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.menuItemName,
                  style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: YataColorTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ) ??
                      YataTypographyTokens.bodyMedium,
                ),
                if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: YataSpacingTokens.xs),
                  Text(
                    item.selectedOptions!.entries
                        .map((MapEntry<String, String> e) => "${e.key}: ${e.value}")
                        .join(", "),
                    style:
                        Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary) ??
                        YataTypographyTokens.bodySmall,
                  ),
                ],
                if (item.specialRequest != null && item.specialRequest!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: YataSpacingTokens.xs),
                  Text(
                    "リクエスト: ${item.specialRequest}",
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: YataColorTokens.textSecondary,
                          fontStyle: FontStyle.italic,
                        ) ??
                        YataTypographyTokens.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: YataSpacingTokens.md),

          // 単価と小計
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                "¥${currencyFormat.format(item.unitPrice)}",
                style:
                    Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary) ??
                    YataTypographyTokens.bodySmall,
              ),
              Text(
                "¥${currencyFormat.format(item.subtotal)}",
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: YataColorTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ) ??
                    YataTypographyTokens.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
