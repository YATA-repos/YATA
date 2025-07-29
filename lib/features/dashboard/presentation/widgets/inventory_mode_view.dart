import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/constants.dart";
import "../../../../core/providers/auth_providers.dart";
import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/cards/app_card.dart";
import "../../../../shared/widgets/cards/stats_card.dart";
import "../../../../shared/widgets/common/loading_indicator.dart";
import "../../../inventory/dto/inventory_dto.dart";
import "../../../inventory/presentation/providers/inventory_providers.dart";

/// 在庫状況モードビュー
///
/// リアルタイム在庫状況と統計情報を表示
/// 在庫アラートや低在庫アイテムの確認が可能
class InventoryModeView extends ConsumerWidget {
  const InventoryModeView({super.key});

  String? _getUserId(WidgetRef ref) => ref.read(currentUserProvider)?.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? userId = _getUserId(ref);

    if (userId == null) {
      return const Center(child: Text(AppStrings.textUserInfoNotAvailable));
    }

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 在庫統計サマリー
          Text("在庫状況サマリー", style: AppTextTheme.cardTitle),
          const SizedBox(height: 16),

          _buildInventoryStatsRow(context, ref, userId),

          const SizedBox(height: 24),

          // 在庫状況一覧
          Text("在庫アイテム", style: AppTextTheme.cardTitle),
          const SizedBox(height: 16),

          Expanded(child: _buildInventoryList(context, ref, userId)),
        ],
      ),
    );
  }

  /// 在庫統計行
  Widget _buildInventoryStatsRow(BuildContext context, WidgetRef ref, String userId) => ref
        .watch(materialsWithStockInfoProvider(null, userId))
        .when(
          data: (List<MaterialStockInfo> materials) {
            final int totalItems = materials.length;
            final int inStock = materials
                .where((MaterialStockInfo item) => item.stockLevel == StockLevel.sufficient)
                .length;
            final int lowStock = materials
                .where((MaterialStockInfo item) => item.stockLevel == StockLevel.low)
                .length;
            final int outOfStock = materials
                .where((MaterialStockInfo item) => item.stockLevel == StockLevel.critical)
                .length;

            return ResponsiveHelper.shouldShowSideNavigation(context)
                ? Row(
                    children: <Widget>[
                      _buildStatsCard(
                        "総アイテム数",
                        totalItems.toString(),
                        LucideIcons.package,
                        StatsCardVariant.default_,
                      ),
                      const SizedBox(width: 16),
                      _buildStatsCard(
                        "在庫あり",
                        inStock.toString(),
                        LucideIcons.checkCircle,
                        StatsCardVariant.stock,
                      ),
                      const SizedBox(width: 16),
                      _buildStatsCard(
                        "低在庫",
                        lowStock.toString(),
                        LucideIcons.alertTriangle,
                        StatsCardVariant.lowStock,
                      ),
                      const SizedBox(width: 16),
                      _buildStatsCard(
                        "欠品",
                        outOfStock.toString(),
                        LucideIcons.xCircle,
                        StatsCardVariant.danger,
                      ),
                    ],
                  )
                : Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _buildStatsCard(
                            "総アイテム数",
                            totalItems.toString(),
                            LucideIcons.package,
                            StatsCardVariant.default_,
                          ),
                          const SizedBox(width: 16),
                          _buildStatsCard(
                            "在庫あり",
                            inStock.toString(),
                            LucideIcons.checkCircle,
                            StatsCardVariant.stock,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          _buildStatsCard(
                            "低在庫",
                            lowStock.toString(),
                            LucideIcons.alertTriangle,
                            StatsCardVariant.lowStock,
                          ),
                          const SizedBox(width: 16),
                          _buildStatsCard(
                            "欠品",
                            outOfStock.toString(),
                            LucideIcons.xCircle,
                            StatsCardVariant.danger,
                          ),
                        ],
                      ),
                    ],
                  );
          },
          loading: () => const LoadingIndicator(),
          error: (Object error, StackTrace stack) => Center(child: Text("エラー: $error")),
        );

  /// 統計カード
  Widget _buildStatsCard(String title, String value, IconData icon, StatsCardVariant variant) =>
      Expanded(
        child: StatsCard(title: title, value: value, icon: icon, variant: variant),
      );

  /// 在庫アイテムリスト
  Widget _buildInventoryList(BuildContext context, WidgetRef ref, String userId) => ref
        .watch(materialsWithStockInfoProvider(null, userId))
        .when(
          data: (List<MaterialStockInfo> materials) => GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.getGridColumns(context),
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: materials.length,
            itemBuilder: (BuildContext context, int index) {
              final MaterialStockInfo item = materials[index];
              return _buildInventoryItemCard(item);
            },
          ),
          loading: () => const LoadingIndicator(),
          error: (Object error, StackTrace stack) => Center(child: Text("エラー: $error")),
        );

  /// 在庫アイテムカード
  Widget _buildInventoryItemCard(MaterialStockInfo item) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              _getStatusIconFromStockLevel(item.stockLevel),
              color: _getStatusColorFromStockLevel(item.stockLevel),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.material.name,
                style: AppTextTheme.cardTitle.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "現在庫: ${item.material.currentStock.toStringAsFixed(1)}",
          style: AppTextTheme.cardDescription,
        ),
        Text(
          "アラート闾値: ${item.material.alertThreshold.toStringAsFixed(1)}",
          style: AppTextTheme.cardDescription,
        ),
        if (item.estimatedUsageDays != null) ...<Widget>[
          Text("推定使用日数: ${item.estimatedUsageDays}日", style: AppTextTheme.cardDescription),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColorFromStockLevel(item.stockLevel).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.stockLevel.displayName,
            style: AppTextTheme.cardDescription.copyWith(
              color: _getStatusColorFromStockLevel(item.stockLevel),
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );


  IconData _getStatusIconFromStockLevel(StockLevel stockLevel) {
    switch (stockLevel) {
      case StockLevel.sufficient:
        return LucideIcons.checkCircle;
      case StockLevel.low:
        return LucideIcons.alertTriangle;
      case StockLevel.critical:
        return LucideIcons.xCircle;
    }
  }

  Color _getStatusColorFromStockLevel(StockLevel stockLevel) {
    switch (stockLevel) {
      case StockLevel.sufficient:
        return AppColors.inStock;
      case StockLevel.low:
        return AppColors.lowStock;
      case StockLevel.critical:
        return AppColors.outOfStock;
    }
  }
}
