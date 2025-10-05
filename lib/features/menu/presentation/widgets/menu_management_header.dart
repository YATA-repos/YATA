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
    final List<OverviewStatData> overviewStats = <OverviewStatData>[
      OverviewStatData(
        title: "要確認",
        value: "${state.attentionMenuCount}",
        indicatorColor: YataColorTokens.warning,
        indicatorLabel: "要対応メニューの数",
      ),
      OverviewStatData(
        title: "提供可能",
        value: "${state.availableMenuCount}",
        indicatorColor: YataColorTokens.success,
        indicatorLabel: "現在提供できるメニューの数",
      ),
      OverviewStatData(
        title: "登録メニュー",
        value: "${state.totalMenuCount}",
        indicatorColor: YataColorTokens.info,
        indicatorLabel: "登録済みメニューの総数",
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
        OverviewStatCards(stats: overviewStats),
        const SizedBox(height: YataSpacingTokens.lg),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stacked = constraints.maxWidth < 720;
            final Widget searchField = YataSearchField(
              controller: searchController,
              hintText: "メニュー名・説明で検索",
              onChanged: onSearchChanged,
            );
            final Widget filter = YataSegmentedFilter(
              segments: segments,
              selectedIndex: selectedIndex,
              onSegmentSelected: (int index) =>
                  onFilterChanged(MenuAvailabilityFilter.values[index]),
              compact: !stacked,
            );
            final Widget? createButton = onCreateMenu == null
                ? null
                : YataIconLabelButton(icon: Icons.add, label: "メニューを追加", onPressed: onCreateMenu);

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(width: double.infinity, child: searchField),
                  const SizedBox(height: YataSpacingTokens.sm),
                  filter,
                  if (createButton != null) ...<Widget>[
                    const SizedBox(height: YataSpacingTokens.sm),
                    createButton,
                  ],
                ],
              );
            }

            return Row(
              children: <Widget>[
                Expanded(child: SizedBox(height: 48, child: searchField)),
                const SizedBox(width: YataSpacingTokens.md),
                filter,
                if (createButton != null) ...<Widget>[
                  const SizedBox(width: YataSpacingTokens.md),
                  createButton,
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
