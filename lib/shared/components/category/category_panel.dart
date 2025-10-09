import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../buttons/icon_button.dart";
import "../data_display/status_badge.dart";
import "../layout/section_card.dart";

/// カテゴリ一覧を統一スタイルで表示するパネル。
class CategoryPanel<T> extends StatelessWidget {
  const CategoryPanel({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.title = "カテゴリ",
    this.subtitle,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.isLoading = false,
    this.emptyMessage = "カテゴリが登録されていません",
    super.key,
  });

  /// 表示するカテゴリアイテム一覧。
  final List<CategoryPanelItem<T>> items;

  /// 選択中のカテゴリID。`null` の場合は疑似「すべて」。
  final String? selectedId;

  /// カテゴリ選択時のコールバック。
  final ValueChanged<String?> onSelect;

  /// パネルタイトル。
  final String title;

  /// パネルサブタイトル。
  final String? subtitle;

  /// カテゴリ追加押下時のコールバック。
  final VoidCallback? onAdd;

  /// カテゴリ編集押下時のコールバック。
  final ValueChanged<T>? onEdit;

  /// カテゴリ削除押下時のコールバック。
  final ValueChanged<T>? onDelete;

  /// 読み込み中かどうか。
  final bool isLoading;

  /// アイテム未存在時に表示するメッセージ。
  final String emptyMessage;

  @override
  Widget build(BuildContext context) => YataSectionCard(
    title: title,
    subtitle: subtitle,
    expandChild: true,
    borderColor: Colors.transparent,
    actions: <Widget>[
      if (onAdd != null)
        YataIconButton(icon: Icons.add, tooltip: "カテゴリを追加", onPressed: isLoading ? null : onAdd),
    ],
    child: isLoading ? const Center(child: CircularProgressIndicator()) : _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    if (items.isEmpty) {
      return SizedBox(height: 160, child: Center(child: Text(emptyMessage)));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: YataSpacingTokens.xs),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: YataSpacingTokens.sm),
      itemBuilder: (BuildContext context, int index) {
        final CategoryPanelItem<T> item = items[index];
        final bool selected = item.isAll ? selectedId == null : item.id == selectedId;
        return _CategoryTile<T>(
          item: item,
          selected: selected,
          onTap: () => onSelect(item.isAll ? null : item.id),
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}

/// カテゴリパネルで表示する個別アイテムのデータ。
class CategoryPanelItem<T> {
  const CategoryPanelItem({
    required this.payload,
    required this.name,
    this.id,
    this.isAll = false,
    this.headerBadge,
    this.trailingLabel,
    this.trailingLabelColor,
    this.badges = const <CategoryPanelBadgeData>[],
    this.metrics = const <CategoryPanelMetricData>[],
    this.enableActions = true,
  });

  /// 呼び出し元へ返す元データ。
  final T payload;

  /// カテゴリID。疑似「すべて」の場合は `null`。
  final String? id;

  /// 表示名。
  final String name;

  /// 疑似「すべて」カテゴリかどうか。
  final bool isAll;

  /// タイトル行右側に表示するバッジ。
  final CategoryPanelBadgeData? headerBadge;

  /// タイトル行右側に表示するテキスト。
  final String? trailingLabel;

  /// タイトル行右側テキスト色。
  final Color? trailingLabelColor;

  /// 名称下に表示するバッジ一覧。
  final List<CategoryPanelBadgeData> badges;

  /// 追加情報として表示する行データ。
  final List<CategoryPanelMetricData> metrics;

  /// 操作メニュー（編集/削除）を表示するかどうか。
  final bool enableActions;
}

/// バッジ表示用データ。
class CategoryPanelBadgeData {
  const CategoryPanelBadgeData({required this.label, required this.type});

  final String label;
  final YataStatusBadgeType type;
}

/// 詳細行表示用データ。
class CategoryPanelMetricData {
  const CategoryPanelMetricData({
    required this.icon,
    required this.label,
    this.iconColor,
    this.iconSize,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final double? iconSize;
}

class _CategoryTile<T> extends StatelessWidget {
  const _CategoryTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final CategoryPanelItem<T> item;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<T>? onEdit;
  final ValueChanged<T>? onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
      color: selected ? YataColorTokens.primary : YataColorTokens.textPrimary,
    );
    final Color borderColor = selected ? YataColorTokens.primary : YataColorTokens.neutral200;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(YataRadiusTokens.medium),
        child: Ink(
          padding: const EdgeInsets.all(YataSpacingTokens.md),
          decoration: BoxDecoration(
            color: YataColorTokens.neutral0,
            borderRadius: BorderRadius.circular(YataRadiusTokens.medium),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: YataColorTokens.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(item.name, style: titleStyle.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (item.headerBadge != null)
                    YataStatusBadge(label: item.headerBadge!.label, type: item.headerBadge!.type)
                  else if (item.trailingLabel != null)
                    Text(
                      item.trailingLabel!,
                      style: titleStyle.copyWith(
                        color: item.trailingLabelColor ?? titleStyle.color,
                      ),
                    ),
                  if (!item.isAll && item.enableActions && (onEdit != null || onDelete != null))
                    PopupMenuButton<_CategoryTileAction>(
                      tooltip: "カテゴリ操作",
                      onSelected: (_CategoryTileAction action) {
                        switch (action) {
                          case _CategoryTileAction.edit:
                            onEdit?.call(item.payload);
                            break;
                          case _CategoryTileAction.delete:
                            onDelete?.call(item.payload);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<_CategoryTileAction>>[
                        if (onEdit != null)
                          const PopupMenuItem<_CategoryTileAction>(
                            value: _CategoryTileAction.edit,
                            child: Text("名称を変更"),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem<_CategoryTileAction>(
                            value: _CategoryTileAction.delete,
                            child: Text("削除"),
                          ),
                      ],
                    ),
                ],
              ),
              if (item.badges.isNotEmpty) ...<Widget>[
                const SizedBox(height: YataSpacingTokens.xs),
                Wrap(
                  spacing: YataSpacingTokens.xs,
                  runSpacing: YataSpacingTokens.xs,
                  children: item.badges
                      .map(
                        (CategoryPanelBadgeData badge) =>
                            YataStatusBadge(label: badge.label, type: badge.type),
                      )
                      .toList(growable: false),
                ),
              ],
              if (item.metrics.isNotEmpty) ...<Widget>[
                const SizedBox(height: YataSpacingTokens.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List<Widget>.generate(item.metrics.length, (int index) {
                    final CategoryPanelMetricData metric = item.metrics[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == item.metrics.length - 1 ? 0 : YataSpacingTokens.xxs,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            metric.icon,
                            size: metric.iconSize ?? 12,
                            color: metric.iconColor ?? YataColorTokens.textSecondary,
                          ),
                          const SizedBox(width: YataSpacingTokens.xs),
                          Expanded(child: Text(metric.label, style: theme.textTheme.bodySmall)),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _CategoryTileAction { edit, delete }
