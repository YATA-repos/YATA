import "package:flutter/material.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../controllers/menu_management_state.dart";

/// メニュー管理ページ上部の指標カードと検索・アクション群。
class MenuManagementHeader extends StatelessWidget {
  /// [MenuManagementHeader]を生成する。
  const MenuManagementHeader({
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterChanged,
    super.key,
    this.onCreateMenu,
  });

  /// 現在の画面状態。
  final MenuManagementState state;

  /// 検索用テキストコントローラ。
  final TextEditingController searchController;

  /// 検索文字列変更ハンドラ。
  final ValueChanged<String> onSearchChanged;

  /// フィルター変更ハンドラ。
  final ValueChanged<MenuAvailabilityFilter> onFilterChanged;

  /// メニュー追加モーダルを開くコールバック。
  final VoidCallback? onCreateMenu;

  @override
  Widget build(BuildContext context) {
    final List<Widget> statCards = <Widget>[
      YataStatCard(
        title: "登録メニュー",
        value: "${state.totalMenuCount}",
        indicatorColor: YataColorTokens.info,
        indicatorLabel: "登録メニューの状態",
      ),
      YataStatCard(
        title: "提供可能",
        value: "${state.availableMenuCount}",
        indicatorColor: YataColorTokens.success,
        indicatorLabel: "提供可能メニューの状態",
      ),
      YataStatCard(
        title: "要確認",
        value: "${state.attentionMenuCount}",
        indicatorColor: YataColorTokens.warning,
        indicatorLabel: "要確認メニューの状態",
      ),
    ];

    final List<YataFilterSegment> segments = <YataFilterSegment>[
      const YataFilterSegment(label: "すべて"),
      const YataFilterSegment(label: "提供可能"),
      const YataFilterSegment(label: "提供不可"),
      const YataFilterSegment(label: "要確認"),
    ];

    final int selectedIndex = state.availabilityFilter.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stacked = constraints.maxWidth < 900;
            if (stacked) {
              return Column(
                children: statCards
                    .map(
                      (Widget card) => Padding(
                        padding: const EdgeInsets.only(bottom: YataSpacingTokens.sm),
                        child: card,
                      ),
                    )
                    .toList(growable: false),
              );
            }

            final List<Widget> rowChildren = <Widget>[];
            for (int index = 0; index < statCards.length; index++) {
              rowChildren.add(
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == statCards.length - 1 ? 0 : YataSpacingTokens.md,
                    ),
                    child: statCards[index],
                  ),
                ),
              );
            }

            return Row(children: rowChildren);
          },
        ),
        const SizedBox(height: YataSpacingTokens.lg),
        Wrap(
          spacing: YataSpacingTokens.md,
          runSpacing: YataSpacingTokens.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 320,
              child: YataSearchField(
                controller: searchController,
                hintText: "メニュー名・説明で検索",
                onChanged: onSearchChanged,
              ),
            ),
            YataSegmentedFilter(
              segments: segments,
              selectedIndex: selectedIndex,
              onSegmentSelected: (int index) =>
                  onFilterChanged(MenuAvailabilityFilter.values[index]),
              compact: true,
            ),
            if (onCreateMenu != null)
              YataIconLabelButton(icon: Icons.add, label: "メニューを追加", onPressed: onCreateMenu),
          ],
        ),
      ],
    );
  }
}
