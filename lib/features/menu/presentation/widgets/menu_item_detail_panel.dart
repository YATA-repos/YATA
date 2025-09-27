import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../controllers/menu_management_controller.dart";

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
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TabBar(
              labelStyle: Theme.of(context).textTheme.titleSmall ?? YataTypographyTokens.titleSmall,
              tabs: const <Tab>[
                Tab(text: "基本情報"),
                Tab(text: "オプション"),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.md),
            SizedBox(
              height: 320,
              child: TabBarView(
                children: <Widget>[
                  _BasicInfoTab(
                    item: current,
                    availability: availabilityState,
                    onOpenOptions: onOpenOptions,
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
