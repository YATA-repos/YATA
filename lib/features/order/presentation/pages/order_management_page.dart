import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/components/buttons/icon_button.dart";
import "../../../../shared/components/inputs/quantity_stepper.dart";
import "../../../../shared/components/inputs/search_field.dart";
import "../../../../shared/components/inputs/segmented_filter.dart";
import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/components/layout/section_card.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/patterns/patterns.dart";
import "../controllers/order_management_controller.dart";

/// 注文管理画面のメインページ。
class OrderManagementPage extends ConsumerStatefulWidget {
  /// [OrderManagementPage]を生成する。
  const OrderManagementPage({super.key});

  @override
  ConsumerState<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends ConsumerState<OrderManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OrderManagementState state = ref.watch(orderManagementControllerProvider);
    final OrderManagementController controller = ref.watch(
      orderManagementControllerProvider.notifier,
    );

    return Scaffold(
      backgroundColor: YataColorTokens.background,
      appBar: YataAppTopBar(
        navItems: <YataNavItem>[
          YataNavItem(
            label: "注文",
            icon: Icons.shopping_cart_outlined,
            isActive: true,
            onTap: () => context.go("/order"),
          ),
          YataNavItem(
            label: "履歴",
            icon: Icons.receipt_long_outlined,
            onTap: () => context.go("/history"),
          ),
          YataNavItem(
            label: "在庫管理",
            icon: Icons.inventory_2_outlined,
            onTap: () => context.go("/inventory"),
          ),
          const YataNavItem(label: "売上分析", icon: Icons.query_stats_outlined),
        ],
        trailing: <Widget>[
          YataIconLabelButton(
            icon: Icons.dashboard_customize_outlined,
            label: "注文状況画面",
            onPressed: () {},
          ),
          YataIconButton(icon: Icons.settings, onPressed: () {}, tooltip: "設定"),
        ],
      ),
      body: YataPageContainer(
        scrollable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: YataSpacingTokens.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: state.isLoading ? const LinearProgressIndicator() : const SizedBox.shrink(),
            ),
            if (state.isLoading) const SizedBox(height: YataSpacingTokens.md),
            if (state.errorMessage != null) ...<Widget>[
              _OrderPageErrorBanner(message: state.errorMessage!, onRetry: controller.refresh),
              const SizedBox(height: YataSpacingTokens.md),
            ],
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: _MenuSelectionSection(
                      state: state,
                      controller: controller,
                      searchController: _searchController,
                    ),
                  ),
                  const SizedBox(width: YataSpacingTokens.lg),
                  // 右ペインはカード内で内部スクロール + 下部固定バー
                  Expanded(
                    child: _CurrentOrderSection(state: state, controller: controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSelectionSection extends StatefulWidget {
  const _MenuSelectionSection({
    required this.state,
    required this.controller,
    required this.searchController,
  });

  final OrderManagementState state;
  final OrderManagementController controller;
  final TextEditingController searchController;

  @override
  State<_MenuSelectionSection> createState() => _MenuSelectionSectionState();
}

class _MenuSelectionSectionState extends State<_MenuSelectionSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OrderManagementState state = widget.state;
    final OrderManagementController controller = widget.controller;
    final TextEditingController searchController = widget.searchController;
    final List<YataFilterSegment> segments = state.categories
        .map((MenuCategoryViewData category) => YataFilterSegment(label: category.label))
        .toList(growable: false);

    return YataSectionCard(
      title: "メニュー選択",
      subtitle: "商品をタップして注文に追加",
      expandChild: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          YataSearchField(
            controller: searchController,
            hintText: "メニュー検索...",
            onChanged: controller.updateSearchQuery,
          ),
          const SizedBox(height: YataSpacingTokens.md),
          YataSegmentedFilter(
            segments: segments,
            selectedIndex: state.selectedCategoryIndex,
            onSegmentSelected: controller.selectCategory,
          ),
          const SizedBox(height: YataSpacingTokens.lg),
          // * メニュー一覧エリア（内部スクロール）
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final List<MenuItemViewData> items = state.filteredMenuItems;
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.lg),
                      child: Text(
                        "該当するメニューが見つかりません",
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
                      ),
                    ),
                  );
                }

                const double spacing = YataSpacingTokens.xl;
                const double scrollbarThickness = 8;
                const double scrollPad = scrollbarThickness + YataSpacingTokens.xs;
                final double availableWidth = (constraints.maxWidth - scrollPad).clamp(
                  0,
                  double.infinity,
                );

                final int crossAxisCount = availableWidth >= 900
                    ? 3
                    : availableWidth >= 600
                    ? 2
                    : 1;
                final double itemWidth =
                    (availableWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

                return RawScrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: scrollbarThickness,
                  radius: const Radius.circular(8),
                  thumbColor: YataColorTokens.textSecondary.withValues(alpha: 0.6),
                  trackColor: YataColorTokens.divider,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    primary: false,
                    padding: const EdgeInsets.only(
                      right: scrollbarThickness + YataSpacingTokens.xs,
                    ),
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: <Widget>[
                        ...items.map((MenuItemViewData item) {
                          final bool isSelected = state.isInCart(item.id);
                          int? quantityFor(String id) {
                            for (final CartItemViewData ci in state.cartItems) {
                              if (ci.menuItem.id == id) {
                                return ci.quantity;
                              }
                            }
                            return null;
                          }

                          final int? quantity = quantityFor(item.id);
                          return SizedBox(
                            width: itemWidth,
                            child: YataMenuItemTile(
                              name: item.name,
                              priceLabel: state.formatPrice(item.price),
                              isSelected: isSelected,
                              minQuantity: 0,
                              quantity: quantity,
                              onQuantityChanged: state.isLoading
                                  ? null
                                  : (int value) => controller.updateItemQuantity(item.id, value),
                              onTap: state.isLoading ? null : () => controller.addMenuItem(item.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentOrderSection extends StatefulWidget {
  const _CurrentOrderSection({required this.state, required this.controller});

  final OrderManagementState state;
  final OrderManagementController controller;

  @override
  State<_CurrentOrderSection> createState() => _CurrentOrderSectionState();
}

class _CurrentOrderSectionState extends State<_CurrentOrderSection> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  @override
  void didUpdateWidget(covariant _CurrentOrderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 自動スクロールは無効化（ハイライトのみ有効）
  }

  // 自動スクロールは無効化

  @override
  Widget build(BuildContext context) {
    final OrderManagementState state = widget.state;
    final OrderManagementController controller = widget.controller;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SizedBox.expand(
      child: YataSectionCard(
        expandChild: true,
        title: "現在の注文",
        actions: <Widget>[_OrderNumberBadge(orderNumber: state.orderNumber)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 広幅時のみ列ヘッダを表示
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
            // リスト領域（内部スクロール）
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
                                child: _HighlightWrapper(
                                  highlighted: isHighlighted,
                                  child: _OrderRow(
                                    name: item.menuItem.name,
                                    unitPriceLabel: state.formatPrice(item.menuItem.price),
                                    quantity: item.quantity,
                                    lineSubtotalLabel: state.formatPrice(item.subtotal),
                                    onQuantityChanged: (int value) =>
                                        controller.updateItemQuantity(item.menuItem.id, value),
                                    onRemove: () => controller.removeItem(item.menuItem.id),
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
            _SummaryRow(
              label: "小計",
              value: state.formatPrice(state.subtotal),
              textTheme: textTheme,
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            _SummaryRow(
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
                    onPressed: state.cartItems.isEmpty ? null : controller.clearCart,
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
                    onPressed: state.cartItems.isEmpty
                        ? null
                        : () {
                            context.push("/history");
                          },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("会計"),
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

class _OrderNumberBadge extends StatelessWidget {
  const _OrderNumberBadge({required this.orderNumber});

  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    final String label = (orderNumber == null || orderNumber!.isEmpty) ? "未割り当て" : orderNumber!;
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
        "注文番号: $label",
        style:
            Theme.of(context).textTheme.labelLarge?.copyWith(color: YataColorTokens.primary) ??
            YataTypographyTokens.labelLarge.copyWith(color: YataColorTokens.primary),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, required this.textTheme});

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

class _HighlightWrapper extends StatelessWidget {
  const _HighlightWrapper({required this.highlighted, required this.child});

  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = highlighted ? YataColorTokens.selectionTint : Colors.transparent;
    final Color borderColor = highlighted
        ? YataColorTokens.primary.withValues(alpha: 0.22)
        : Colors.transparent;
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

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.name,
    required this.unitPriceLabel,
    required this.quantity,
    required this.lineSubtotalLabel,
    required this.onQuantityChanged,
    this.onRemove,
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
            // 2行レイアウト: 1行目=品名 | 単価 | ×, 2行目= [ステッパー] | 行小計
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
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          lineSubtotalLabel,
                          style: subtotalStyle,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // 1行レイアウト（できるだけ品名を優先して表示）
          return Row(
            children: <Widget>[
              // 品名
              Expanded(
                flex: 6,
                child: Text(name, style: nameStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: YataSpacingTokens.md),
              // 単価
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(unitPriceLabel, style: priceStyle, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: YataSpacingTokens.md),
              // 数量ステッパー（非フレックス）
              YataQuantityStepper(value: quantity, onChanged: onQuantityChanged, compact: true),
              const SizedBox(width: YataSpacingTokens.md),
              // 行小計
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    lineSubtotalLabel,
                    style: subtotalStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: YataSpacingTokens.sm),
              // 削除ボタン
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

class _OrderPageErrorBanner extends StatelessWidget {
  const _OrderPageErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(YataSpacingTokens.md),
    decoration: BoxDecoration(
      color: YataColorTokens.dangerSoft,
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
      border: Border.all(color: YataColorTokens.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.error_outline, color: YataColorTokens.danger),
        const SizedBox(width: YataSpacingTokens.sm),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: YataColorTokens.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text("再試行"),
        ),
      ],
    ),
  );
}
