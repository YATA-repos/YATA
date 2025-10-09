import "package:flutter/material.dart";

import "../../../../../core/constants/enums.dart";
import "../../../../../shared/components/inputs/quantity_stepper.dart";
import "../../../../../shared/components/layout/section_card.dart";
import "../../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../controllers/order_management_controller.dart";
import "../../controllers/order_management_state.dart";
import "../order_payment_method_selector.dart";

class CurrentOrderSection extends StatefulWidget {
  const CurrentOrderSection({
    required this.state,
    required this.onUpdateItemQuantity,
    required this.onRemoveItem,
    required this.onPaymentMethodChanged,
    required this.onOrderNotesChanged,
    required this.onClearCart,
    required this.onCheckout,
    super.key,
  });

  final OrderManagementState state;
  final void Function(String menuItemId, int quantity) onUpdateItemQuantity;
  final void Function(String menuItemId) onRemoveItem;
  final Future<void> Function(PaymentMethod) onPaymentMethodChanged;
  final ValueChanged<String> onOrderNotesChanged;
  final VoidCallback onClearCart;
  final Future<CheckoutActionResult> Function() onCheckout;

  @override
  State<CurrentOrderSection> createState() => _CurrentOrderSectionState();
}

class _CurrentOrderSectionState extends State<CurrentOrderSection> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.state.orderNotes);
  }

  @override
  void didUpdateWidget(covariant CurrentOrderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.orderNotes != _notesController.text) {
      final TextEditingValue oldValue = _notesController.value;
      final String newText = widget.state.orderNotes;
      final int maxOffset = newText.length;
      final TextSelection newSelection = TextSelection(
        baseOffset: oldValue.selection.baseOffset.clamp(0, maxOffset),
        extentOffset: oldValue.selection.extentOffset.clamp(0, maxOffset),
      );
      _notesController.value = TextEditingValue(text: newText, selection: newSelection);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _checkoutFailureMessage(CheckoutActionResult result) {
    switch (result.status) {
      case CheckoutActionStatus.stockInsufficient:
        return result.message ?? "在庫が不足している商品があります。数量を調整して再度お試しください。";
      case CheckoutActionStatus.emptyCart:
        return result.message ?? "カートに商品がありません。";
      case CheckoutActionStatus.authenticationFailed:
        return result.message ?? "ユーザー情報を取得できませんでした。再度ログインしてください。";
      case CheckoutActionStatus.missingCart:
        return result.message ?? "カート情報の取得に失敗しました。再度読み込みを行ってください。";
      case CheckoutActionStatus.failure:
        return result.message ?? "会計処理に失敗しました。時間をおいて再度お試しください。";
      case CheckoutActionStatus.success:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrderManagementState state = widget.state;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SizedBox.expand(
      child: YataSectionCard(
        expandChild: true,
        title: "現在の注文",
        actions: <Widget>[OrderNumberBadge(orderNumber: state.orderNumber)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isNarrow = constraints.maxWidth < 640;
                if (isNarrow || state.cartItems.isEmpty) {
                  return const SizedBox.shrink();
                }
                final TextStyle headerStyle =
                    (textTheme.labelMedium ?? YataTypographyTokens.labelMedium).copyWith(
                  color: YataColorTokens.textSecondary,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(flex: 6, child: Text("品名", style: headerStyle)),
                        const SizedBox(width: YataSpacingTokens.md),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text("単価", style: headerStyle),
                          ),
                        ),
                        const SizedBox(width: YataSpacingTokens.md),
                        Text("数量", style: headerStyle),
                        const SizedBox(width: YataSpacingTokens.md),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text("小計", style: headerStyle),
                          ),
                        ),
                        const SizedBox(width: YataSpacingTokens.sm),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: YataSpacingTokens.xs),
                    const Divider(
                      height: YataSpacingTokens.md,
                      thickness: 1,
                      color: YataColorTokens.divider,
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: state.cartItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.lg),
                        child: Text(
                          "カートに商品が追加されていません",
                          style: textTheme.bodyMedium?.copyWith(
                            color: YataColorTokens.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : Builder(
                      builder: (BuildContext context) {
                        const double scrollbarThickness = 8;
                        return RawScrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: scrollbarThickness,
                          radius: const Radius.circular(8),
                          thumbColor: YataColorTokens.textSecondary.withValues(alpha: 0.6),
                          trackColor: YataColorTokens.divider,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                              right: scrollbarThickness + YataSpacingTokens.xs,
                            ),
                            itemCount: state.cartItems.length,
                            separatorBuilder: (BuildContext context, int index) => const Divider(
                              height: YataSpacingTokens.lg,
                              thickness: 1,
                              color: YataColorTokens.divider,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final CartItemViewData item = state.cartItems[index];
                              _itemKeys.putIfAbsent(item.menuItem.id, GlobalKey.new);
                              final bool isHighlighted =
                                  state.highlightedItemId == item.menuItem.id;
                              return KeyedSubtree(
                                key: _itemKeys[item.menuItem.id],
                                child: HighlightWrapper(
                                  highlighted: isHighlighted,
                                  child: OrderRow(
                                    name: item.menuItem.name,
                                    unitPriceLabel: state.formatPrice(item.menuItem.price),
                                    quantity: item.quantity,
                                    lineSubtotalLabel: state.formatPrice(item.subtotal),
                                    onQuantityChanged: (int value) =>
                                        widget.onUpdateItemQuantity(item.menuItem.id, value),
                                    onRemove: () => widget.onRemoveItem(item.menuItem.id),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: YataSpacingTokens.md),
            const Divider(),
            const SizedBox(height: YataSpacingTokens.md),
            OrderPaymentMethodSelector(
              selected: state.currentPaymentMethod,
              isDisabled: state.isCheckoutInProgress || state.isLoading,
              onChanged: widget.onPaymentMethodChanged,
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            TextField(
              controller: _notesController,
              onChanged: widget.onOrderNotesChanged,
              maxLength: 200,
              enabled: !state.isCheckoutInProgress && !state.isLoading,
              decoration: InputDecoration(
                labelText: "メモ",
                hintText: "例: アレルギー対応、調理指示など",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YataRadiusTokens.small),
                  borderSide: const BorderSide(color: YataColorTokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YataRadiusTokens.small),
                  borderSide: const BorderSide(color: YataColorTokens.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: YataSpacingTokens.md,
                  vertical: YataSpacingTokens.sm,
                ),
                counterStyle: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall).copyWith(
                  color: YataColorTokens.textSecondary,
                ),
              ),
              style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            SummaryRow(
              label: "小計",
              value: state.formatPrice(state.subtotal),
              textTheme: textTheme,
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            SummaryRow(
              label: "消費税 (10%)",
              value: state.formatPrice(state.tax),
              textTheme: textTheme,
            ),
            const SizedBox(height: YataSpacingTokens.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("合計", style: textTheme.titleMedium ?? YataTypographyTokens.titleMedium),
                Text(
                  state.formatPrice(state.total),
                  style: textTheme.headlineSmall ?? YataTypographyTokens.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.cartItems.isEmpty || state.isCheckoutInProgress
                        ? null
                        : widget.onClearCart,
                    icon: const Icon(Icons.close),
                    label: const Text("クリア"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: YataColorTokens.textPrimary,
                      side: const BorderSide(color: YataColorTokens.border),
                      backgroundColor: YataColorTokens.neutral0,
                      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.sm),
                    ),
                  ),
                ),
                const SizedBox(width: YataSpacingTokens.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.cartItems.isEmpty || state.isCheckoutInProgress
                        ? null
                        : () async {
                            final CheckoutActionResult result = await widget.onCheckout();
                            if (!context.mounted) {
                              return;
                            }
                            if (result.isSuccess) {
                              final String? orderNumber = result.order?.orderNumber;
                              final String orderNumberLabel =
                                  (orderNumber == null || orderNumber.isEmpty)
                                      ? "新規注文"
                                      : "受付コード $orderNumber";
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("会計が完了しました（$orderNumberLabel）。")),
                              );
                            } else {
                              final String message = _checkoutFailureMessage(result);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          },
                    icon: state.isCheckoutInProgress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(YataColorTokens.neutral0),
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(state.isCheckoutInProgress ? "会計中…" : "会計"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YataColorTokens.success,
                      foregroundColor: YataColorTokens.neutral0,
                      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.sm),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderNumberBadge extends StatelessWidget {
  const OrderNumberBadge({required this.orderNumber, super.key});

  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    final String label = (orderNumber == null || orderNumber!.isEmpty) ? "割り当て準備中" : orderNumber!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YataSpacingTokens.md,
        vertical: YataSpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: YataColorTokens.primarySoft,
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        border: Border.all(color: YataColorTokens.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        "受付コード: $label",
        style:
            Theme.of(context).textTheme.labelLarge?.copyWith(color: YataColorTokens.primary) ??
            YataTypographyTokens.labelLarge.copyWith(color: YataColorTokens.primary),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    required this.textTheme,
    super.key,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium).copyWith(
              color: YataColorTokens.textPrimary,
            ),
          ),
          Text(
            value,
            style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium).copyWith(
              color: YataColorTokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

class HighlightWrapper extends StatelessWidget {
  const HighlightWrapper({required this.highlighted, required this.child, super.key});

  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = highlighted ? YataColorTokens.selectionTint : Colors.transparent;
    final Color borderColor =
        highlighted ? YataColorTokens.primary.withValues(alpha: 0.22) : Colors.transparent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        border: Border.all(color: borderColor),
        boxShadow: highlighted
            ? <BoxShadow>[
                BoxShadow(
                  color: YataColorTokens.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 2),
                ),
              ]
            : const <BoxShadow>[],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: YataSpacingTokens.sm,
        vertical: YataSpacingTokens.xs,
      ),
      child: child,
    );
  }
}

class OrderRow extends StatelessWidget {
  const OrderRow({
    required this.name,
    required this.unitPriceLabel,
    required this.quantity,
    required this.lineSubtotalLabel,
    required this.onQuantityChanged,
    this.onRemove,
    super.key,
  });

  final String name;
  final String unitPriceLabel;
  final int quantity;
  final String lineSubtotalLabel;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle nameStyle = (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
        .copyWith(color: YataColorTokens.textPrimary);
    final TextStyle priceStyle = (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium).copyWith(
      color: YataColorTokens.textSecondary,
    );
    final TextStyle subtotalStyle = (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium)
        .copyWith(color: YataColorTokens.textPrimary, fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.sm),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isNarrow = constraints.maxWidth < 640;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(name, style: nameStyle, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: YataSpacingTokens.sm),
                    Text(unitPriceLabel, style: priceStyle, overflow: TextOverflow.fade),
                    const SizedBox(width: YataSpacingTokens.sm),
                    if (onRemove != null)
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close),
                        tooltip: "削除",
                        splashRadius: 18,
                        color: YataColorTokens.textSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: YataSpacingTokens.xs),
                Row(
                  children: <Widget>[
                    YataQuantityStepper(
                      value: quantity,
                      onChanged: onQuantityChanged,
                      compact: true,
                    ),
                    const SizedBox(width: YataSpacingTokens.md),
                    Expanded(
                      child: SubtotalDisplay(
                        value: lineSubtotalLabel,
                        textStyle: subtotalStyle,
                        quantity: quantity,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(
                flex: 6,
                child: Text(name, style: nameStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: YataSpacingTokens.md),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(unitPriceLabel, style: priceStyle, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: YataSpacingTokens.md),
              YataQuantityStepper(value: quantity, onChanged: onQuantityChanged, compact: true),
              const SizedBox(width: YataSpacingTokens.md),
              Expanded(
                flex: 2,
                child: SubtotalDisplay(
                  value: lineSubtotalLabel,
                  textStyle: subtotalStyle,
                  quantity: quantity,
                ),
              ),
              const SizedBox(width: YataSpacingTokens.sm),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                  tooltip: "削除",
                  splashRadius: 18,
                  color: YataColorTokens.textSecondary,
                ),
            ],
          );
        },
      ),
    );
  }
}

class SubtotalDisplay extends StatelessWidget {
  const SubtotalDisplay({
    required this.value,
    required this.textStyle,
    required this.quantity,
    super.key,
  });

  final String value;
  final TextStyle textStyle;
  final int quantity;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text("x$quantity", style: textStyle),
            const SizedBox(width: YataSpacingTokens.sm),
            Icon(Icons.arrow_forward, size: 18, color: YataColorTokens.textSecondary),
            const SizedBox(width: YataSpacingTokens.xs),
            Flexible(
              child: Text(
                value,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      );
}
