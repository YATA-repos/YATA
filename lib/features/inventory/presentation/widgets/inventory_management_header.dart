import "package:flutter/material.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../controllers/inventory_management_controller.dart";

/// 在庫管理ページ上部の指標カードと検索・アクション群。
class InventoryManagementHeader extends StatelessWidget {
  /// [InventoryManagementHeader]を生成する。
  const InventoryManagementHeader({
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    super.key,
    this.onAddItem,
  });

  /// 現在の画面状態。
  final InventoryManagementState state;

  /// 検索用テキストコントローラ。
  final TextEditingController searchController;

  /// 検索文字列変更ハンドラ。
  final ValueChanged<String> onSearchChanged;

  /// ステータスフィルター変更ハンドラ。
  final ValueChanged<StockStatus?> onStatusFilterChanged;

  /// 在庫追加モーダルを開くコールバック。
  final VoidCallback? onAddItem;

  @override
  Widget build(BuildContext context) {
    final int adequateCount = state.totalItems - state.lowCount - state.criticalCount;
    final int adequateSafe = adequateCount < 0 ? 0 : adequateCount;

    final List<OverviewStatData> overviewStats = <OverviewStatData>[
      OverviewStatData(
        title: "総在庫アイテム",
        value: "${state.totalItems}",
        indicatorColor: YataColorTokens.primary,
        indicatorLabel: "登録済み在庫アイテムの総数",
      ),
      OverviewStatData(
        title: "適正在庫",
        value: "$adequateSafe",
        indicatorColor: YataColorTokens.success,
        indicatorLabel: "警告なしの在庫アイテム数",
      ),
      OverviewStatData(
        title: "要注意",
        value: "${state.lowCount}",
        indicatorColor: YataColorTokens.warning,
        indicatorLabel: "閾値警告に達した在庫アイテム数",
      ),
      OverviewStatData(
        title: "緊急補充",
        value: "${state.criticalCount}",
        indicatorColor: YataColorTokens.danger,
        indicatorLabel: "致命的閾値を下回る在庫アイテム数",
      ),
    ];

    final List<YataFilterSegment> segments = <YataFilterSegment>[
      const YataFilterSegment(label: "すべて"),
      const YataFilterSegment(label: "適正在庫"),
      const YataFilterSegment(label: "要注意"),
      const YataFilterSegment(label: "緊急補充"),
    ];

    final int selectedIndex = _getFilterIndex(state.selectedStatusFilter);

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
              hintText: "在庫アイテム、カテゴリで検索",
              onChanged: onSearchChanged,
            );
            final Widget filter = YataSegmentedFilter(
              segments: segments,
              selectedIndex: selectedIndex,
              onSegmentSelected: (int index) => onStatusFilterChanged(_getStatusFromIndex(index)),
              compact: !stacked,
            );

            final List<Widget> actionButtons = <Widget>[];
            if (onAddItem != null) {
              actionButtons.add(
                YataIconLabelButton(
                  icon: Icons.add,
                  label: "在庫を追加",
                  onPressed: state.isLoading ? null : onAddItem,
                ),
              );
            }

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(width: double.infinity, child: searchField),
                  const SizedBox(height: YataSpacingTokens.sm),
                  filter,
                  if (actionButtons.isNotEmpty) ...<Widget>[
                    const SizedBox(height: YataSpacingTokens.sm),
                    ...actionButtons.map((Widget btn) => Padding(
                      padding: const EdgeInsets.only(bottom: YataSpacingTokens.xs),
                      child: btn,
                    )),
                  ],
                ],
              );
            }

            return Row(
              children: <Widget>[
                Expanded(child: SizedBox(height: 48, child: searchField)),
                const SizedBox(width: YataSpacingTokens.md),
                filter,
                if (actionButtons.isNotEmpty) ...<Widget>[
                  const SizedBox(width: YataSpacingTokens.md),
                  ...actionButtons.map((Widget btn) => Padding(
                    padding: const EdgeInsets.only(left: YataSpacingTokens.xs),
                    child: btn,
                  )),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  /// フィルター状態からセグメントインデックスを取得。
  int _getFilterIndex(StockStatus? filter) {
    if (filter == null) {
      return 0; // すべて
    }
    switch (filter) {
      case StockStatus.sufficient:
        return 1; // 適正在庫
      case StockStatus.low:
        return 2; // 要注意
      case StockStatus.critical:
        return 3; // 緊急補充
    }
  }

  /// セグメントインデックスからフィルター状態を取得。
  StockStatus? _getStatusFromIndex(int index) {
    switch (index) {
      case 0:
        return null; // すべて
      case 1:
        return StockStatus.sufficient; // 適正在庫
      case 2:
        return StockStatus.low; // 要注意
      case 3:
        return StockStatus.critical; // 緊急補充
      default:
        return null;
    }
  }
}
