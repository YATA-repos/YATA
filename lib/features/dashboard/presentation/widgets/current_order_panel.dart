import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/constants.dart";
import "../../../../core/providers/auth_providers.dart";
import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/models/cart_models.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/cards/app_card.dart";
import "../../../../shared/widgets/common/app_badge.dart";
import "../../../order/models/order_model.dart";
import "../../../order/presentation/providers/cart_providers.dart";

/// 現在の注文パネル
///
/// カート内のアイテム表示・数量変更・注文完了機能を提供
/// CartServiceと統合してカート操作を管理
class CurrentOrderPanel extends ConsumerWidget {
  const CurrentOrderPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: ResponsiveHelper.getResponsivePadding(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ヘッダー
        Row(
          children: <Widget>[
            Text("現在の注文", style: AppTextTheme.cardTitle),
            const Spacer(),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final int itemCount = ref.watch(cartItemCountProvider);
                if (itemCount > 0) {
                  return CountBadge(count: itemCount);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        AppLayout.vSpacerDefault,

        // カート内容
        Expanded(
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final bool isEmpty = ref.watch(isCartEmptyProvider);
              return isEmpty ? _buildEmptyCart() : _buildCartItems(ref);
            },
          ),
        ),

        // 注文サマリー・アクション
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final bool isEmpty = ref.watch(isCartEmptyProvider);
            if (!isEmpty) {
              return Column(
                children: <Widget>[
                  AppLayout.vSpacerDefault,
                  _buildOrderSummary(ref),
                  AppLayout.vSpacerDefault,
                  _buildOrderActions(ref),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    ),
  );

  /// 空のカート表示
  Widget _buildEmptyCart() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(LucideIcons.shoppingCart, size: 64, color: AppColors.mutedForeground),
        AppLayout.vSpacerDefault,
        Text(AppStrings.textCartEmpty, style: AppTextTheme.cardTitle.copyWith(color: AppColors.mutedForeground)),
        AppLayout.vSpacerSmall,
        Text(
          AppStrings.textSelectFromMenu,
          style: AppTextTheme.cardDescription,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  /// カートアイテムリスト
  Widget _buildCartItems(WidgetRef ref) {
    final List<CartItem> items = ref.watch(cartItemsProvider);
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final CartItem item = items[index];
        return _buildCartItemCard(item, ref);
      },
    );
  }

  /// カートアイテムカード
  Widget _buildCartItemCard(CartItem item, WidgetRef ref) => AppCard(
    child: Row(
      children: <Widget>[
        // アイテム情報
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.name, style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text(item.formattedUnitPrice, style: AppTextTheme.priceText),
            ],
          ),
        ),

        // 数量操作
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              onPressed: () => _decreaseQuantity(item, ref),
              icon: const Icon(LucideIcons.minus),
              iconSize: 16,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Container(
              padding: AppLayout.hBigPaddingSmall,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${item.quantity}",
                style: AppTextTheme.cardDescription.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: () => _increaseQuantity(item, ref),
              icon: const Icon(LucideIcons.plus),
              iconSize: 16,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),

        AppLayout.hSpacerSmall,

        // 削除ボタン
        IconButton(
          onPressed: () => _removeFromCart(item, ref),
          icon: const Icon(LucideIcons.trash2),
          iconSize: 16,
          color: AppColors.danger,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    ),
  );

  /// 注文サマリー
  Widget _buildOrderSummary(WidgetRef ref) {
    final CartState cart = ref.watch(cartProvider);
    final double subtotal = cart.totalAmount.toDouble();
    final double tax = subtotal * 0.1;
    final double total = subtotal + tax;

    return AppCard(
      child: Column(
        children: <Widget>[
          _buildSummaryRow("小計", cart.formattedTotalAmount),
          AppLayout.vSpacerSmall,
          _buildSummaryRow("税込", "¥${tax.toStringAsFixed(0)}"),
          if (cart.discountAmount > 0) ...<Widget>[
            AppLayout.vSpacerSmall,
            _buildSummaryRow("割引", cart.formattedDiscountAmount ?? ""),
          ],
          const Divider(),
          _buildSummaryRow("合計", "¥${total.toStringAsFixed(0)}", isTotal: true),
        ],
      ),
    );
  }

  /// サマリー行
  Widget _buildSummaryRow(String label, String amount, {bool isTotal = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Text(
        label,
        style: isTotal
            ? AppTextTheme.cardTitle.copyWith(fontSize: 16)
            : AppTextTheme.cardDescription,
      ),
      Text(
        amount,
        style: isTotal
            ? AppTextTheme.priceText.copyWith(fontSize: 18, fontWeight: FontWeight.bold)
            : AppTextTheme.priceText,
      ),
    ],
  );

  /// 注文アクション
  Widget _buildOrderActions(WidgetRef ref) => Column(
    children: <Widget>[
      AppButton(
        onPressed: () => _processOrder(ref),
        size: ButtonSize.large,
        isFullWidth: true,
        text: "注文を確定",
        icon: const Icon(LucideIcons.check),
      ),
      AppLayout.vSpacerSmall,
      AppButton(
        onPressed: () => _clearCart(ref),
        variant: ButtonVariant.outline,
        size: ButtonSize.large,
        isFullWidth: true,
        text: "カートをクリア",
        icon: const Icon(LucideIcons.trash2),
      ),
    ],
  );

  /// 数量増加
  void _increaseQuantity(CartItem item, WidgetRef ref) {
    ref
        .read(cartProvider.notifier)
        .incrementQuantity(item.menuItemId, options: item.selectedOptions);
  }

  /// 数量減少
  void _decreaseQuantity(CartItem item, WidgetRef ref) {
    ref
        .read(cartProvider.notifier)
        .decrementQuantity(item.menuItemId, options: item.selectedOptions);
  }

  /// カートから削除
  void _removeFromCart(CartItem item, WidgetRef ref) {
    ref.read(cartProvider.notifier).removeItem(item.menuItemId, options: item.selectedOptions);
  }

  /// 注文処理
  Future<void> _processOrder(WidgetRef ref) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final Order? activeCart = await ref.read(activeCartProvider(userId).future);
    if (activeCart?.id == null) {
      return;
    }

    await ref
        .read(checkoutStateProvider.notifier)
        .processCheckout(cartId: activeCart!.id!, customerName: "店内注文");
  }

  /// カートクリア
  void _clearCart(WidgetRef ref) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final Order? activeCart = await ref.read(activeCartProvider(userId).future);
    await ref.read(cartProvider.notifier).clear(cartId: activeCart?.id);
  }
}
