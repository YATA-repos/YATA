import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_button.dart";
import "../../../../shared/widgets/common/app_card.dart";

/// 注文サマリーカードコンポーネント
///
/// 注文内容・料金表示、計算機能付き
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    required this.items,
    super.key,
    this.title = "注文内容",
    this.tax = 0.1,
    this.serviceCharge,
    this.discount,
    this.onItemQuantityChanged,
    this.onItemRemoved,
    this.onCheckout,
    this.isEditable = true,
    this.showActions = true,
    this.currencySymbol = "¥",
  });

  /// タイトル
  final String title;

  /// 注文アイテム一覧
  final List<OrderSummaryItem> items;

  /// 税率
  final double tax;

  /// サービス料
  final num? serviceCharge;

  /// 割引額
  final num? discount;

  /// アイテム数量変更処理
  final void Function(int index, int newQuantity)? onItemQuantityChanged;

  /// アイテム削除処理
  final void Function(int index)? onItemRemoved;

  /// 会計処理
  final VoidCallback? onCheckout;

  /// 編集可能
  final bool isEditable;

  /// アクション表示
  final bool showActions;

  /// 通貨記号
  final String currencySymbol;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(context),
        const SizedBox(height: AppLayout.spacing4),
        _buildItemsList(context),
        const SizedBox(height: AppLayout.spacing4),
        _buildSummary(context),
        if (showActions) ...<Widget>[
          const SizedBox(height: AppLayout.spacing4),
          _buildActions(context),
        ],
      ],
    ),
  );

  Widget _buildHeader(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.spacing2,
          vertical: AppLayout.spacing1,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppLayout.spacing1),
        ),
        child: Text(
          "${items.length}件",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _buildItemsList(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: AppLayout.padding6,
        child: Column(
          children: <Widget>[
            Icon(
              LucideIcons.shoppingCart,
              size: AppLayout.iconSizeLg,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: AppLayout.spacing2),
            Text(
              "注文アイテムがありません",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((MapEntry<int, OrderSummaryItem> entry) {
        final int index = entry.key;
        final OrderSummaryItem item = entry.value;
        return _buildItemRow(context, index, item);
      }).toList(),
    );
  }

  Widget _buildItemRow(BuildContext context, int index, OrderSummaryItem item) {
    final num itemTotal = item.price * item.quantity;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.spacing2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: index == items.length - 1 ? Colors.transparent : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (item.note != null) ...<Widget>[
                  const SizedBox(height: AppLayout.spacing1),
                  Text(
                    item.note!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
                  ),
                ],
                const SizedBox(height: AppLayout.spacing1),
                Text(
                  "$currencySymbol${_formatCurrency(item.price)} × ${item.quantity}",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppLayout.spacing3),
          if (isEditable) ...<Widget>[
            _buildQuantityControls(context, index, item),
            const SizedBox(width: AppLayout.spacing2),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                "$currencySymbol${_formatCurrency(itemTotal)}",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (isEditable)
                IconButton(
                  icon: const Icon(LucideIcons.trash2),
                  iconSize: AppLayout.iconSizeSm,
                  color: AppColors.danger,
                  onPressed: () => onItemRemoved?.call(index),
                  tooltip: "削除",
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context, int index, OrderSummaryItem item) =>
      DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppLayout.spacing1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(LucideIcons.minus),
              iconSize: AppLayout.iconSizeSm,
              onPressed: item.quantity > 1
                  ? () => onItemQuantityChanged?.call(index, item.quantity - 1)
                  : null,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                item.quantity.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.plus),
              iconSize: AppLayout.iconSizeSm,
              onPressed: () => onItemQuantityChanged?.call(index, item.quantity + 1),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      );

  Widget _buildSummary(BuildContext context) {
    final num subtotal = _calculateSubtotal();
    final num taxAmount = subtotal * tax;
    final num serviceChargeAmount = serviceCharge ?? 0;
    final num discountAmount = discount ?? 0;
    final num total = subtotal + taxAmount + serviceChargeAmount - discountAmount;

    return Container(
      padding: AppLayout.padding3,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppLayout.spacing2),
      ),
      child: Column(
        children: <Widget>[
          _buildSummaryRow(context, "小計", subtotal),
          const SizedBox(height: AppLayout.spacing2),
          _buildSummaryRow(context, "税金 (${(tax * 100).toInt()}%)", taxAmount),
          if (serviceChargeAmount > 0) ...<Widget>[
            const SizedBox(height: AppLayout.spacing2),
            _buildSummaryRow(context, "サービス料", serviceChargeAmount),
          ],
          if (discountAmount > 0) ...<Widget>[
            const SizedBox(height: AppLayout.spacing2),
            _buildSummaryRow(context, "割引", -discountAmount, isDiscount: true),
          ],
          const Divider(height: AppLayout.spacing4),
          _buildSummaryRow(context, "合計", total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    num amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Text(
        label,
        style:
            (isTotal
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                  color: isDiscount ? AppColors.success : null,
                ),
      ),
      Text(
        "$currencySymbol${_formatCurrency(amount.abs())}",
        style:
            (isTotal
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                  color: isDiscount ? AppColors.success : null,
                ),
      ),
    ],
  );

  Widget _buildActions(BuildContext context) {
    final bool hasItems = items.isNotEmpty;

    return Row(
      children: <Widget>[
        Expanded(
          child: AppButton.text(
            "会計を確定",
            onPressed: hasItems ? onCheckout : null,
            variant: hasItems ? ButtonVariant.primary : ButtonVariant.ghost,
            isFullWidth: true,
            icon: LucideIcons.creditCard,
          ),
        ),
      ],
    );
  }

  num _calculateSubtotal() => items.fold<num>(
    0,
    (num total, OrderSummaryItem item) => total + (item.price * item.quantity),
  );

  String _formatCurrency(num amount) => amount.toInt().toString().replaceAllMapped(
    RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
    (Match match) => "${match[1]},",
  );
}

/// 注文サマリーアイテム
class OrderSummaryItem {
  const OrderSummaryItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.note,
    this.category,
    this.options,
  });

  /// アイテム名
  final String name;

  /// 単価
  final num price;

  /// 数量
  final int quantity;

  /// 備考
  final String? note;

  /// カテゴリ
  final String? category;

  /// オプション
  final List<String>? options;

  /// コピー作成
  OrderSummaryItem copyWith({
    String? name,
    num? price,
    int? quantity,
    String? note,
    String? category,
    List<String>? options,
  }) => OrderSummaryItem(
    name: name ?? this.name,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
    note: note ?? this.note,
    category: category ?? this.category,
    options: options ?? this.options,
  );
}
