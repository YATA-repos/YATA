import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_badge.dart";
import "../../../../shared/widgets/common/app_icon_button.dart";
import "../../../../shared/widgets/common/app_list_tile.dart";

/// 在庫ステータス列挙型
enum InventoryStatus {
  inStock, // 在庫あり
  lowStock, // 在庫少
  outOfStock, // 在庫切れ
  expired, // 期限切れ
}

/// 在庫アイテム行表示コンポーネント
///
/// 在庫一覧画面で使用され、アイテムの在庫情報を表示します。
class InventoryItemRow extends StatelessWidget {
  const InventoryItemRow({
    required this.name,
    required this.currentStock,
    required this.unit,
    required this.status,
    super.key,
    this.sku,
    this.category,
    this.lastUpdated,
    this.onEdit,
    this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  /// アイテム名
  final String name;

  /// SKUコード
  final String? sku;

  /// カテゴリー
  final String? category;

  /// 現在の在庫数
  final int currentStock;

  /// 在庫単位
  final String unit;

  /// 在庫ステータス
  final InventoryStatus status;

  /// 最後の更新日時
  final DateTime? lastUpdated;

  /// 編集時のコールバック
  final VoidCallback? onEdit;

  /// 詳細表示時のコールバック
  final VoidCallback? onTap;

  /// 選択状態
  final bool selected;

  /// 有効状態
  final bool enabled;

  @override
  Widget build(BuildContext context) => AppListTile(
    leading: _buildLeadingIcon(),
    title: _buildTitle(context),
    subtitle: _buildSubtitle(context),
    trailing: _buildTrailing(context),
    onTap: onTap,
    selected: selected,
    enabled: enabled,
  );

  /// 先頭アイコン
  Widget _buildLeadingIcon() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: _getStatusColor().withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(LucideIcons.package, color: _getStatusColor(), size: 20),
  );

  /// タイトルセクション
  Widget _buildTitle(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: enabled ? AppColors.foreground : AppColors.mutedForeground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: AppLayout.spacing2),
      _buildStatusBadge(),
    ],
  );

  /// サブタイトルセクション
  Widget _buildSubtitle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color subtitleColor = enabled
        ? AppColors.mutedForeground
        : AppColors.mutedForeground.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            if (sku != null) ...<Widget>[
              Text("SKU: $sku", style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor)),
              if (category != null) ...<Widget>[
                const SizedBox(width: AppLayout.spacing3),
                Text("•", style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor)),
                const SizedBox(width: AppLayout.spacing3),
              ],
            ],
            if (category != null)
              Text(category!, style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: <Widget>[
            Icon(LucideIcons.package2, size: 12, color: subtitleColor),
            const SizedBox(width: 4),
            Text(
              "$currentStock $unit",
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (lastUpdated != null) ...<Widget>[
              const Spacer(),
              Icon(LucideIcons.clock, size: 12, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                _formatLastUpdated(lastUpdated!),
                style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 末尾セクション
  Widget? _buildTrailing(BuildContext context) {
    if (onEdit == null) {
      return null;
    }

    return AppIconButton(
      icon: LucideIcons.edit3,
      onPressed: enabled ? onEdit : null,
      tooltip: "編集",
    );
  }

  /// ステータスバッジ
  Widget _buildStatusBadge() =>
      AppBadge.text(_getStatusText(), variant: _getStatusBadgeVariant(), size: BadgeSize.small);

  /// ステータスに基づく色を取得
  Color _getStatusColor() {
    switch (status) {
      case InventoryStatus.inStock:
        return AppColors.success;
      case InventoryStatus.lowStock:
        return AppColors.warning;
      case InventoryStatus.outOfStock:
        return AppColors.danger;
      case InventoryStatus.expired:
        return AppColors.danger;
    }
  }

  /// ステータステキストを取得
  String _getStatusText() {
    switch (status) {
      case InventoryStatus.inStock:
        return "在庫あり";
      case InventoryStatus.lowStock:
        return "在庫少";
      case InventoryStatus.outOfStock:
        return "在庫切れ";
      case InventoryStatus.expired:
        return "期限切れ";
    }
  }

  /// ステータスに基づくバッジバリアントを取得
  BadgeVariant _getStatusBadgeVariant() {
    switch (status) {
      case InventoryStatus.inStock:
        return BadgeVariant.success;
      case InventoryStatus.lowStock:
        return BadgeVariant.warning;
      case InventoryStatus.outOfStock:
        return BadgeVariant.danger;
      case InventoryStatus.expired:
        return BadgeVariant.danger;
    }
  }

  /// 最終更新日時のフォーマット
  String _formatLastUpdated(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return "${difference.inDays}日前";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}時間前";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}分前";
    } else {
      return "たった今";
    }
  }
}

/// 在庫アイテム情報用データクラス
class InventoryItemInfo {
  const InventoryItemInfo({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.unit,
    required this.status,
    this.sku,
    this.category,
    this.minStock,
    this.maxStock,
    this.lastUpdated,
    this.expiryDate,
    this.unitCost,
    this.supplier,
  });

  /// 在庫ステータスを自動計算
  factory InventoryItemInfo.withAutoStatus({
    required String id,
    required String name,
    required int currentStock,
    required String unit,
    String? sku,
    String? category,
    int? minStock,
    int? maxStock,
    DateTime? lastUpdated,
    DateTime? expiryDate,
    double? unitCost,
    String? supplier,
  }) {
    InventoryStatus status;

    // 期限切れチェック
    if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
      status = InventoryStatus.expired;
    }
    // 在庫切れチェック
    else if (currentStock <= 0) {
      status = InventoryStatus.outOfStock;
    }
    // 在庫少チェック
    else if (minStock != null && currentStock <= minStock) {
      status = InventoryStatus.lowStock;
    }
    // 在庫あり
    else {
      status = InventoryStatus.inStock;
    }

    return InventoryItemInfo(
      id: id,
      name: name,
      currentStock: currentStock,
      unit: unit,
      status: status,
      sku: sku,
      category: category,
      minStock: minStock,
      maxStock: maxStock,
      lastUpdated: lastUpdated,
      expiryDate: expiryDate,
      unitCost: unitCost,
      supplier: supplier,
    );
  }
  final String id;
  final String name;
  final String? sku;
  final String? category;
  final int currentStock;
  final int? minStock;
  final int? maxStock;
  final String unit;
  final InventoryStatus status;
  final DateTime? lastUpdated;
  final DateTime? expiryDate;
  final double? unitCost;
  final String? supplier;

  /// コストの合計を計算
  double? get totalValue {
    if (unitCost == null) {
      return null;
    }
    return unitCost! * currentStock;
  }

  /// 在庫回転率を計算（仮想的な実装）
  double? calculateTurnoverRate(int monthlyUsage) {
    if (currentStock <= 0) {
      return null;
    }
    return monthlyUsage / currentStock;
  }
}

/// 在庫アイテムリスト表示用ウィジェット
class InventoryItemList extends StatelessWidget {
  const InventoryItemList({
    required this.items,
    super.key,
    this.onItemEdit,
    this.onItemTap,
    this.selectedItems = const <String>{},
    this.showDividers = true,
  });

  /// 在庫アイテムリスト
  final List<InventoryItemInfo> items;

  /// アイテム編集時のコールバック
  final void Function(InventoryItemInfo item)? onItemEdit;

  /// アイテムタップ時のコールバック
  final void Function(InventoryItemInfo item)? onItemTap;

  /// 選択されたアイテムIDセット
  final Set<String> selectedItems;

  /// 区切り線表示
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (BuildContext context, int index) =>
          showDividers ? const Divider(height: 1, indent: 56) : const SizedBox.shrink(),
      itemBuilder: (BuildContext context, int index) {
        final InventoryItemInfo item = items[index];
        final bool isSelected = selectedItems.contains(item.id);

        return InventoryItemRow(
          name: item.name,
          sku: item.sku,
          category: item.category,
          currentStock: item.currentStock,
          unit: item.unit,
          status: item.status,
          lastUpdated: item.lastUpdated,
          selected: isSelected,
          onEdit: onItemEdit != null ? () => onItemEdit!(item) : null,
          onTap: onItemTap != null ? () => onItemTap!(item) : null,
        );
      },
    );
  }

  /// 空状態の表示
  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          LucideIcons.package,
          size: 64,
          color: AppColors.mutedForeground.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          "在庫アイテムがありません",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 8),
        Text(
          "新しいアイテムを追加してください",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground.withValues(alpha: 0.7)),
        ),
      ],
    ),
  );
}
