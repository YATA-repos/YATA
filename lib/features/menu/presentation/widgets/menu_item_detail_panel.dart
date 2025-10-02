import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../controllers/menu_management_controller.dart";
import "../../dto/menu_recipe_detail.dart";

/// 材料テーブルで利用する単位フォーマット。
final NumberFormat _amountFormat = NumberFormat("#,##0.###");

/// メニューアイテムの詳細/編集パネル。
class MenuItemDetailPanel extends StatelessWidget {
  /// [MenuItemDetailPanel]を生成する。
  const MenuItemDetailPanel({
    required this.item,
    required this.availability,
    required this.onEdit,
    required this.onOpenOptions,
    required this.onRefreshAvailability,
    required this.onDelete,
    required this.recipes,
    required this.isRecipeLoading,
    required this.recipeErrorMessage,
    required this.onReloadRecipes,
    required this.onOpenRecipeEditor,
    required this.onRequestRecipeDelete,
    required this.savingRecipeMaterialIds,
    required this.deletingRecipeIds,
    super.key,
  });

  /// 表示対象のメニューアイテム。
  final MenuItemViewData? item;

  /// 該当アイテムの在庫可用性情報。
  final MenuAvailabilityViewData? availability;

  /// 編集モーダルを開くコールバック。
  final VoidCallback onEdit;

  /// オプション編集モーダルを開くコールバック。
  final VoidCallback onOpenOptions;

  /// 在庫状況を再取得するコールバック。
  final VoidCallback onRefreshAvailability;

  /// 削除コールバック。
  final VoidCallback onDelete;

  /// レシピ一覧。
  final List<MenuRecipeDetail> recipes;

  /// レシピ読み込み中かどうか。
  final bool isRecipeLoading;

  /// レシピ関連のエラーメッセージ。
  final String? recipeErrorMessage;

  /// レシピを再読込するコールバック。
  final VoidCallback onReloadRecipes;

  /// レシピ編集モーダルを開くコールバック。
  final void Function(MenuRecipeDetail? recipe) onOpenRecipeEditor;

  /// レシピ削除を要求するコールバック。
  final void Function(MenuRecipeDetail recipe) onRequestRecipeDelete;

  /// 保存処理中の材料ID集合。
  final Set<String> savingRecipeMaterialIds;

  /// 削除処理中のレシピID集合。
  final Set<String> deletingRecipeIds;

  static final NumberFormat _currency = NumberFormat.currency(locale: "ja_JP", symbol: "¥");
  static final DateFormat _dateTime = DateFormat("yyyy/MM/dd HH:mm");

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return YataSectionCard(
        title: "詳細",
        child: SizedBox(
          height: 240,
          child: Center(
            child: Text(
              "メニューを選択すると詳細が表示されます",
              style: Theme.of(context).textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
            ),
          ),
        ),
      );
    }

    final MenuItemViewData current = item!;
    final MenuAvailabilityViewData availabilityState =
        availability ?? const MenuAvailabilityViewData.idle();

    return YataSectionCard(
      title: "詳細",
      actions: <Widget>[
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text("削除"),
          style: TextButton.styleFrom(foregroundColor: YataColorTokens.danger),
        ),
        OutlinedButton.icon(
          onPressed: onRefreshAvailability,
          icon: const Icon(Icons.refresh_outlined),
          label: const Text("在庫再チェック"),
        ),
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text("編集"),
        ),
      ],
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TabBar(
              labelStyle: Theme.of(context).textTheme.titleSmall ?? YataTypographyTokens.titleSmall,
              tabs: const <Tab>[
                Tab(text: "基本情報"),
                Tab(text: "材料"),
                Tab(text: "オプション"),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.md),
            SizedBox(
              height: 420,
              child: TabBarView(
                children: <Widget>[
                  _BasicInfoTab(
                    item: current,
                    availability: availabilityState,
                    onOpenOptions: onOpenOptions,
                  ),
                  _RecipesTab(
                    item: current,
                    recipes: recipes,
                    isLoading: isRecipeLoading,
                    errorMessage: recipeErrorMessage,
                    onReloadRecipes: onReloadRecipes,
                    onOpenRecipeEditor: onOpenRecipeEditor,
                    onRequestDelete: onRequestRecipeDelete,
                    savingRecipeMaterialIds: savingRecipeMaterialIds,
                    deletingRecipeIds: deletingRecipeIds,
                  ),
                  _OptionsTab(onOpenOptions: onOpenOptions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicInfoTab extends StatelessWidget {
  const _BasicInfoTab({
    required this.item,
    required this.availability,
    required this.onOpenOptions,
  });

  final MenuItemViewData item;
  final MenuAvailabilityViewData availability;
  final VoidCallback onOpenOptions;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String availabilitySummary = _buildAvailabilitySummary();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: YataSpacingTokens.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          YataKeyValueRow(label: "カテゴリ", value: item.categoryName),
          const SizedBox(height: YataSpacingTokens.sm),
          YataKeyValueRow(label: "価格", value: MenuItemDetailPanel._currency.format(item.price)),
          const SizedBox(height: YataSpacingTokens.sm),
          YataKeyValueRow(
            label: "販売状態",
            value: item.isAvailable ? "販売中" : "停止中",
            divider: _buildAvailabilityBadge(),
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          YataKeyValueRow(label: "表示順", value: item.displayOrder.toString()),
          const SizedBox(height: YataSpacingTokens.sm),
          YataKeyValueRow(
            label: "最終更新",
            value: item.updatedAt != null
                ? MenuItemDetailPanel._dateTime.format(item.updatedAt!)
                : (item.createdAt != null
                      ? MenuItemDetailPanel._dateTime.format(item.createdAt!)
                      : "-"),
          ),
          const Divider(height: YataSpacingTokens.lg),
          Text("在庫コメント", style: textTheme.titleMedium ?? YataTypographyTokens.titleMedium),
          const SizedBox(height: YataSpacingTokens.xs),
          Text(availabilitySummary, style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium),
          if (availability.info?.missingMaterials.isNotEmpty ?? false) ...<Widget>[
            const SizedBox(height: YataSpacingTokens.sm),
            Wrap(
              spacing: YataSpacingTokens.sm,
              runSpacing: YataSpacingTokens.xs,
              children: <Widget>[
                for (final String material in availability.info!.missingMaterials)
                  YataStatusBadge(label: material, type: YataStatusBadgeType.warning),
              ],
            ),
          ],
          const Divider(height: YataSpacingTokens.lg),
          Text("説明", style: textTheme.titleMedium ?? YataTypographyTokens.titleMedium),
          const SizedBox(height: YataSpacingTokens.xs),
          Text(
            (item.description?.isNotEmpty ?? false) ? item.description! : "説明は登録されていません",
            style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
          ),
          const SizedBox(height: YataSpacingTokens.lg),
          FilledButton.icon(
            onPressed: onOpenOptions,
            icon: const Icon(Icons.tune_outlined),
            label: const Text("オプションを編集"),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge() {
    switch (availability.status) {
      case MenuAvailabilityStatus.available:
        return const YataStatusBadge(label: "提供可", type: YataStatusBadgeType.success);
      case MenuAvailabilityStatus.unavailable:
        return const YataStatusBadge(label: "要補充", type: YataStatusBadgeType.danger);
      case MenuAvailabilityStatus.loading:
        return const YataStatusBadge(label: "確認中", type: YataStatusBadgeType.info);
      case MenuAvailabilityStatus.error:
        return const YataStatusBadge(label: "取得失敗", type: YataStatusBadgeType.warning);
      case MenuAvailabilityStatus.idle:
        return const YataStatusBadge(label: "未取得");
    }
  }

  String _buildAvailabilitySummary() {
    switch (availability.status) {
      case MenuAvailabilityStatus.available:
        final int servings = availability.info?.estimatedServings ?? 0;
        return "在庫は十分です（推定提供可能数: $servings）";
      case MenuAvailabilityStatus.unavailable:
        return "材料在庫が不足しているため、販売停止を検討してください";
      case MenuAvailabilityStatus.loading:
        return "在庫状況を確認しています...";
      case MenuAvailabilityStatus.error:
        return availability.errorMessage ?? "在庫状況の取得に失敗しました";
      case MenuAvailabilityStatus.idle:
        return "在庫状況はまだ確認されていません";
    }
  }
}

class _OptionsTab extends StatelessWidget {
  const _OptionsTab({required this.onOpenOptions});

  final VoidCallback onOpenOptions;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.tune_outlined, size: 40, color: YataColorTokens.textSecondary),
          const SizedBox(height: YataSpacingTokens.md),
          Text(
            "オプション編集を開いて内容を確認してください",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
          ),
          const SizedBox(height: YataSpacingTokens.md),
          FilledButton.icon(
            onPressed: onOpenOptions,
            icon: const Icon(Icons.open_in_new),
            label: const Text("オプション編集"),
          ),
        ],
      ),
    );
  }
}

class _RecipesTab extends StatelessWidget {
  const _RecipesTab({
    required this.item,
    required this.recipes,
    required this.isLoading,
    required this.errorMessage,
    required this.onReloadRecipes,
    required this.onOpenRecipeEditor,
    required this.onRequestDelete,
    required this.savingRecipeMaterialIds,
    required this.deletingRecipeIds,
  });

  final MenuItemViewData item;
  final List<MenuRecipeDetail> recipes;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onReloadRecipes;
  final void Function(MenuRecipeDetail? recipe) onOpenRecipeEditor;
  final void Function(MenuRecipeDetail recipe) onRequestDelete;
  final Set<String> savingRecipeMaterialIds;
  final Set<String> deletingRecipeIds;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FilledButton.icon(
              onPressed: isLoading ? null : () => onOpenRecipeEditor(null),
              icon: const Icon(Icons.add),
              label: const Text("材料追加"),
            ),
            OutlinedButton.icon(
              onPressed: onReloadRecipes,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text("再読込"),
            ),
          ],
        ),
        const SizedBox(height: YataSpacingTokens.sm),
        if (errorMessage != null && errorMessage!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(YataSpacingTokens.sm),
            decoration: BoxDecoration(
              color: YataColorTokens.dangerSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: YataColorTokens.danger),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.error_outline, color: YataColorTokens.danger),
                const SizedBox(width: YataSpacingTokens.sm),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(color: YataColorTokens.danger) ??
                        YataTypographyTokens.bodyMedium.copyWith(color: YataColorTokens.danger),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: YataSpacingTokens.sm),
        Expanded(
          child: _buildTable(context),
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recipes.isEmpty) {
      return Center(
        child: Text(
          "材料が登録されていません。\n『材料追加』から登録してください。",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
        ),
      );
    }

    return YataDataTable(
      columns: const <DataColumn>[
        DataColumn(label: Text("材料")),
        DataColumn(label: Text("必要量")),
        DataColumn(label: Text("現在庫")),
        DataColumn(label: Text("任意")),
        DataColumn(label: Text("備考")),
        DataColumn(label: Text("操作")),
      ],
      rows: recipes
          .map((MenuRecipeDetail detail) => _buildRow(context, detail))
          .toList(growable: false),
      shrinkWrap: true,
    );
  }

  DataRow _buildRow(BuildContext context, MenuRecipeDetail detail) {
    final bool isSaving = savingRecipeMaterialIds.contains(detail.materialId);
    final bool isDeleting = detail.recipeId != null &&
        deletingRecipeIds.contains(detail.recipeId);
    final bool isBusy = isSaving || isDeleting;

    final String requiredAmount = _formatRequiredAmount(detail);
    final String stockAmount = _formatStock(detail);
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(detail.materialName)),
        DataCell(Text(requiredAmount)),
        DataCell(Text(stockAmount)),
        DataCell(
          detail.isOptional
              ? const YataStatusBadge(label: "任意", type: YataStatusBadgeType.info)
              : const YataStatusBadge(label: "必須", type: YataStatusBadgeType.success),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              detail.notes?.isNotEmpty ?? false ? detail.notes! : "-",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 160,
            child: isBusy
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Wrap(
                    spacing: YataSpacingTokens.sm,
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: () => onOpenRecipeEditor(detail),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text("編集"),
                      ),
                      TextButton.icon(
                        onPressed: detail.recipeId == null
                            ? null
                            : () => onRequestDelete(detail),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("削除"),
                        style: TextButton.styleFrom(foregroundColor: YataColorTokens.danger),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  static String _formatRequiredAmount(MenuRecipeDetail detail) {
    final String formatted = _amountFormat.format(detail.requiredAmount);
    final String unitSymbol = detail.materialUnitType?.symbol ?? "";
    if (unitSymbol.isEmpty) {
      return formatted;
    }
    return "$formatted $unitSymbol";
  }

  static String _formatStock(MenuRecipeDetail detail) {
    final double? stock = detail.materialCurrentStock;
    if (stock == null) {
      return "-";
    }
    final String formatted = _amountFormat.format(stock);
    final String unitSymbol = detail.materialUnitType?.symbol ?? "";
    if (unitSymbol.isEmpty) {
      return formatted;
    }
    return "$formatted $unitSymbol";
  }
}
