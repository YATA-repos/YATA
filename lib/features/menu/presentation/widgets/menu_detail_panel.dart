import "package:flutter/material.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../dto/menu_recipe_detail.dart";
import "../controllers/menu_management_state.dart";

/// メニュー詳細を表示するサイドパネル。
class MenuDetailPanel extends StatelessWidget {
  /// [MenuDetailPanel]を生成する。
  const MenuDetailPanel({
    required this.detail,
    super.key,
    this.onClose,
    this.onEditMenu,
    this.onEditRecipes,
    this.onDuplicateMenu,
    this.onDeleteMenu,
    this.isBusy = false,
    this.enableInternalScroll = true,
    this.contentPadding,
  });

  /// 表示する詳細データ。
  final MenuDetailViewData? detail;

  /// 閉じるボタンのコールバック。
  final VoidCallback? onClose;

  /// メニュー編集を開くコールバック。
  final VoidCallback? onEditMenu;

  /// レシピ編集を開くコールバック。
  final VoidCallback? onEditRecipes;

  /// メニュー複製を実行するコールバック。
  final VoidCallback? onDuplicateMenu;

  /// メニュー削除を実行するコールバック。
  final VoidCallback? onDeleteMenu;

  /// アクションがビジー状態かどうか。
  final bool isBusy;

  /// 内部でスクロールを有効にするかどうか。
  final bool enableInternalScroll;

  /// コンテンツ全体のパディング。
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) => YataSectionCard(
    title: "メニュー詳細",
    borderColor: Colors.transparent,
    expandChild: true,
    padding: contentPadding ?? YataSpacingTokens.cardPadding,
    actions: <Widget>[
      if (onClose != null)
        Semantics(
          button: true,
          label: "詳細を閉じる",
          child: YataIconButton(icon: Icons.close, tooltip: "閉じる", onPressed: onClose),
        ),
    ],
    child: detail == null
        ? _EmptyState()
        : _DetailContent(
            detail: detail!,
            isBusy: isBusy,
            onEditMenu: onEditMenu,
            onEditRecipes: onEditRecipes,
            onDuplicateMenu: onDuplicateMenu,
            onDeleteMenu: onDeleteMenu,
            enableScroll: enableInternalScroll,
          ),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: "詳細は未選択",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Icon(Icons.info_outline, color: YataColorTokens.textSecondary),
          SizedBox(height: YataSpacingTokens.sm),
          Text("行を選択して詳細を表示"),
        ],
      ),
    ),
  );
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.isBusy,
    this.onEditMenu,
    this.onEditRecipes,
    this.onDuplicateMenu,
    this.onDeleteMenu,
    this.enableScroll = true,
  });

  final MenuDetailViewData detail;
  final bool isBusy;
  final VoidCallback? onEditMenu;
  final VoidCallback? onEditRecipes;
  final VoidCallback? onDuplicateMenu;
  final VoidCallback? onDeleteMenu;
  final bool enableScroll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MenuItemViewData menu = detail.menu;
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(header: true, child: Text(menu.name, style: theme.textTheme.titleLarge)),
        const SizedBox(height: YataSpacingTokens.xs),
        Wrap(
          spacing: YataSpacingTokens.xs,
          children: <Widget>[
            YataStatusBadge(
              label: detail.availabilityLabel,
              type: menu.isAvailable && menu.isStockAvailable
                  ? YataStatusBadgeType.success
                  : YataStatusBadgeType.warning,
            ),
            if (!menu.hasRecipe)
              const YataStatusBadge(label: "レシピ未登録", type: YataStatusBadgeType.warning),
          ],
        ),
        const SizedBox(height: YataSpacingTokens.sm),
        if (_hasActionButtons)
          Padding(
            padding: const EdgeInsets.only(bottom: YataSpacingTokens.md),
            child: _DetailActionButtons(
              isBusy: isBusy,
              onEditMenu: onEditMenu,
              onEditRecipes: onEditRecipes,
              onDuplicateMenu: onDuplicateMenu,
              onDeleteMenu: onDeleteMenu,
            ),
          ),
        _InfoRow(label: "カテゴリ", value: menu.categoryName),
        _InfoRow(label: "価格", value: "¥${menu.price}"),
        _InfoRow(
          label: "在庫メモ",
          value: menu.missingMaterials.isEmpty
              ? (menu.isStockAvailable ? "在庫良好" : "-")
              : menu.missingMaterials.join(", "),
        ),
        if (detail.maxServings != null) _InfoRow(label: "最大提供可能数", value: "${detail.maxServings}"),
        const SizedBox(height: YataSpacingTokens.md),
        Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text("レシピ", style: theme.textTheme.titleMedium),
              ),
            ),
            if (onEditRecipes != null)
              TextButton.icon(
                onPressed: isBusy ? null : onEditRecipes,
                icon: const Icon(Icons.edit_outlined),
                label: const Text("編集"),
              ),
          ],
        ),
        const SizedBox(height: YataSpacingTokens.sm),
        if (detail.recipes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(YataSpacingTokens.md),
            decoration: BoxDecoration(
              color: YataColorTokens.neutral100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text("レシピが未登録です"),
          )
        else
          Column(
            children: detail.recipes
                .map<Widget>(
                  (MenuRecipeDetail recipe) => Container(
                    margin: const EdgeInsets.only(bottom: YataSpacingTokens.sm),
                    padding: const EdgeInsets.all(YataSpacingTokens.md),
                    decoration: BoxDecoration(
                      color: YataColorTokens.neutral100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(recipe.materialName, style: theme.textTheme.titleSmall),
                        const SizedBox(height: YataSpacingTokens.xs),
                        Text("必要量: ${recipe.requiredAmount}"),
                        Text(
                          recipe.isOptional ? "任意" : "必須",
                          style: TextStyle(
                            color: recipe.isOptional
                                ? YataColorTokens.textSecondary
                                : YataColorTokens.textPrimary,
                          ),
                        ),
                        if (recipe.notes != null && recipe.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
                            child: Text(
                              recipe.notes!,
                              style: const TextStyle(color: YataColorTokens.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );

    if (!enableScroll) {
      return content;
    }

    return SingleChildScrollView(child: content);
  }

  bool get _hasActionButtons =>
      onEditMenu != null ||
      onEditRecipes != null ||
      onDuplicateMenu != null ||
      onDeleteMenu != null;
}

class _DetailActionButtons extends StatelessWidget {
  const _DetailActionButtons({
    required this.isBusy,
    this.onEditMenu,
    this.onEditRecipes,
    this.onDuplicateMenu,
    this.onDeleteMenu,
  });

  final bool isBusy;
  final VoidCallback? onEditMenu;
  final VoidCallback? onEditRecipes;
  final VoidCallback? onDuplicateMenu;
  final VoidCallback? onDeleteMenu;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[
      if (onEditMenu != null)
        Semantics(
          button: true,
          enabled: !isBusy,
          label: "メニューを編集",
          child: FilledButton.icon(
            onPressed: isBusy ? null : onEditMenu,
            icon: const Icon(Icons.edit_outlined),
            label: const Text("編集"),
          ),
        ),
      if (onEditRecipes != null)
        Semantics(
          button: true,
          enabled: !isBusy,
          label: "レシピを編集",
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onEditRecipes,
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text("レシピ"),
          ),
        ),
      if (onDuplicateMenu != null)
        Semantics(
          button: true,
          enabled: !isBusy,
          label: "メニューを複製",
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onDuplicateMenu,
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text("複製"),
          ),
        ),
      if (onDeleteMenu != null)
        Semantics(
          button: true,
          enabled: !isBusy,
          label: "メニューを削除",
          child: FilledButton.icon(
            onPressed: isBusy ? null : onDeleteMenu,
            style: FilledButton.styleFrom(
              backgroundColor: YataColorTokens.danger,
              foregroundColor: YataColorTokens.neutral0,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text("削除"),
          ),
        ),
    ];

    return Wrap(spacing: YataSpacingTokens.xs, runSpacing: YataSpacingTokens.xs, children: buttons);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: YataSpacingTokens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
