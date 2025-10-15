import "dart:math" as math;

import "package:flutter/material.dart";

import "../../../../../shared/components/inputs/search_field.dart";
import "../../../../../shared/components/inputs/segmented_filter.dart";
import "../../../../../shared/components/layout/section_card.dart";
import "../../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../../shared/patterns/patterns.dart";
import "../../controllers/order_management_state.dart";
import "../../performance/order_management_tracing.dart";

class MenuSelectionSection extends StatefulWidget {
  const MenuSelectionSection({
    required this.state,
    required this.searchController,
    required this.onSearchQueryChanged,
    required this.onSelectCategory,
    required this.onUpdateItemQuantity,
    required this.onAddMenuItem,
    super.key,
  });

  final OrderManagementState state;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchQueryChanged;
  final ValueChanged<int> onSelectCategory;
  final void Function(String menuItemId, int quantity) onUpdateItemQuantity;
  final void Function(String menuItemId) onAddMenuItem;

  @override
  State<MenuSelectionSection> createState() => _MenuSelectionSectionState();
}

class _MenuSelectionSectionState extends State<MenuSelectionSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OrderManagementState state = widget.state;
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
            onChanged: widget.onSearchQueryChanged,
          ),
          const SizedBox(height: YataSpacingTokens.md),
          YataSegmentedFilter(
            segments: segments,
            selectedIndex: state.selectedCategoryIndex,
            onSegmentSelected: widget.onSelectCategory,
          ),
          const SizedBox(height: YataSpacingTokens.lg),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                int itemCount = 0;
                int sampledCrossAxisCount = 1;
                double sampledTileHeight = 0;

                return OrderManagementTracer.traceSync<Widget>(
                  "page.menuGrid.build",
                  () {
                    final List<MenuItemViewData> items = state.filteredMenuItems;
                    itemCount = items.length;
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.lg),
                          child: Text(
                            "メニューが見つかりません",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: YataColorTokens.textSecondary),
                          ),
                        ),
                      );
                    }
                    // レイアウト計算
                    const double spacing = YataSpacingTokens.xl;
                    const double scrollbarThickness = 8;
                    const double scrollPad = scrollbarThickness + YataSpacingTokens.xs;
                    final double availableWidth =
                        (constraints.maxWidth - scrollPad).clamp(0, double.infinity);

                    final int crossAxisCount = availableWidth >= 900
                        ? 3
                        : availableWidth >= 600
                            ? 2
                            : 1;
                    final double itemWidth = crossAxisCount <= 0
                        ? availableWidth
                        : (availableWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
                    final double tileHeight = _estimateMenuTileHeight(itemWidth, context);
                    final int safeCrossAxisCount = crossAxisCount <= 0 ? 1 : crossAxisCount;
                    sampledCrossAxisCount = safeCrossAxisCount;
                    sampledTileHeight = tileHeight;

                    return RawScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: scrollbarThickness,
                      radius: const Radius.circular(8),
                      thumbColor: YataColorTokens.textSecondary.withValues(alpha: 0.6),
                      trackColor: YataColorTokens.divider,
                      child: GridView.builder(
                        controller: _scrollController,
                        primary: false,
                        padding: const EdgeInsets.only(
                          right: scrollPad,
                          bottom: YataSpacingTokens.lg,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: safeCrossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          mainAxisExtent: tileHeight,
                        ),
                        itemCount: items.length,
                        itemBuilder: (BuildContext context, int index) {
                          final MenuItemViewData item = items[index];
                          final bool isSelected = state.isInCart(item.id);
                          final int? quantity = state.quantityFor(item.id);

                          Widget buildTile() => YataMenuItemTile(
                                key: ValueKey<String>(item.id),
                                name: item.name,
                                priceLabel: state.formatPrice(item.price),
                                isSelected: isSelected,
                                minQuantity: 0,
                                quantity: quantity,
                                onQuantityChanged: state.isLoading
                                    ? null
                                    : (int value) => widget.onUpdateItemQuantity(item.id, value),
                                onTap: state.isLoading ? null : () => widget.onAddMenuItem(item.id),
                              );

                          if (OrderManagementTracer.shouldSample(index)) {
                            return OrderManagementTracer.traceSync<Widget>(
                              "page.menuTile.build",
                              buildTile,
                              startArguments: () => <String, dynamic>{
                                "index": index,
                                "menuItemId": item.id,
                                "selected": isSelected,
                              },
                              finishArguments: () => <String, dynamic>{
                                "quantity": quantity ?? 0,
                              },
                              logThreshold: const Duration(milliseconds: 2),
                            );
                          }

                          return buildTile();
                        },
                      ),
                    );
                  },
                  startArguments: () => <String, dynamic>{"maxWidth": constraints.maxWidth},
                  finishArguments: () => <String, dynamic>{
                    "itemCount": itemCount,
                    "crossAxis": sampledCrossAxisCount,
                    "tileHeight": sampledTileHeight,
                  },
                  logThreshold: const Duration(milliseconds: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const double _menuTileMinHeight = 92;
const double _menuTileTrailingMinHeight = 32 + YataSpacingTokens.md * 2;

double _lineHeight(TextStyle style, TextStyle fallback) {
  final double baseFontSize = style.fontSize ?? fallback.fontSize ?? 14;
  final double heightFactor = style.height ?? fallback.height ?? 1.4;
  return baseFontSize * heightFactor;
}

double _estimateMenuTileHeight(double itemWidth, BuildContext context) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  final TextStyle titleStyle = textTheme.titleMedium ?? YataTypographyTokens.titleMedium;
  final TextStyle priceStyle = textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium;

  final double titleLineHeight = _lineHeight(titleStyle, YataTypographyTokens.titleMedium);
  final double priceLineHeight = _lineHeight(priceStyle, YataTypographyTokens.bodyMedium);
  const double verticalPadding = YataSpacingTokens.md * 2;
  const double textSpacing = YataSpacingTokens.xs;

  final bool allowTwoLines = itemWidth < 320;
  final int titleLines = allowTwoLines ? 2 : 1;
  final double heightFromText =
      verticalPadding + titleLineHeight * titleLines + textSpacing + priceLineHeight;

  return math.max(math.max(heightFromText, _menuTileTrailingMinHeight), _menuTileMinHeight);
}
