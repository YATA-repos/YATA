import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart" as core_enums;
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/cards/app_card.dart";
import "../../../../shared/widgets/filters/category_filter.dart";
import "../../models/order_model.dart";

/// 注文状況画面用ヘッダー
///
/// 統計情報、フィルター、リフレッシュ機能を提供
class OrderStatusHeader extends StatelessWidget {
  const OrderStatusHeader({
    required this.orders,
    this.onRefresh,
    this.onFilterChanged,
    this.selectedStatus,
    super.key,
  });

  final List<Order> orders;
  final VoidCallback? onRefresh;
  final ValueChanged<core_enums.OrderStatus?>? onFilterChanged;
  final core_enums.OrderStatus? selectedStatus;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      // 統計サマリー
      _buildStatsSummary(),

      const SizedBox(height: 16),

      // フィルターとアクション
      _buildFilterAndActions(context),
    ],
  );

  /// 統計サマリー
  Widget _buildStatsSummary() => Row(
    children: <Widget>[
      _buildStatCard(
        "待機中",
        _getOrderCountByStatus(core_enums.OrderStatus.pending),
        LucideIcons.clock,
        AppColors.warning,
      ),
      const SizedBox(width: 12),
      _buildStatCard(
        "調理中",
        _getOrderCountByStatus(core_enums.OrderStatus.preparing),
        LucideIcons.chefHat,
        AppColors.cooking,
      ),
      const SizedBox(width: 12),
      _buildStatCard(
        "提供準備完了",
        _getOrderCountByStatus(core_enums.OrderStatus.ready),
        LucideIcons.bellRing,
        AppColors.complete,
      ),
      const SizedBox(width: 12),
      _buildStatCard("合計", orders.length, LucideIcons.listOrdered, AppColors.primary),
    ],
  );

  /// 統計カード
  Widget _buildStatCard(String title, int count, IconData icon, Color color) => Expanded(
    child: AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title, style: AppTextTheme.cardDescription.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: AppTextTheme.cardTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );

  /// フィルターとアクション
  Widget _buildFilterAndActions(BuildContext context) => Row(
    children: <Widget>[
      // ステータスフィルター
      Expanded(
        child: CategoryFilter(
          categories: <CategoryOption>[
            CategoryOption(
              value: core_enums.OrderStatus.pending.value,
              label: "待機中",
              icon: LucideIcons.clock,
            ),
            CategoryOption(
              value: core_enums.OrderStatus.preparing.value,
              label: "調理中",
              icon: LucideIcons.chefHat,
            ),
            CategoryOption(
              value: core_enums.OrderStatus.ready.value,
              label: "提供準備完了",
              icon: LucideIcons.bellRing,
            ),
            CategoryOption(
              value: core_enums.OrderStatus.delivered.value,
              label: "提供済み",
              icon: LucideIcons.checkCircle,
            ),
          ],
          selectedCategories: selectedStatus != null ? <String>[selectedStatus!.value] : <String>[],
          onSelectionChanged: (List<String> selected) {
            if (selected.isEmpty) {
              onFilterChanged?.call(null);
            } else {
              final String statusValue = selected.first;
              final core_enums.OrderStatus? status = _getStatusFromValue(statusValue);
              onFilterChanged?.call(status);
            }
          },
          allOptionText: "全て",
        ),
      ),

      const SizedBox(width: 12),

      // リフレッシュボタン
      AppButton(
        text: "更新",
        icon: const Icon(LucideIcons.refreshCw, size: 16),
        variant: ButtonVariant.secondary,
        size: ButtonSize.small,
        onPressed: onRefresh,
      ),
    ],
  );

  /// ステータス別注文数を取得
  int _getOrderCountByStatus(core_enums.OrderStatus status) =>
      orders.where((Order order) => order.status == status).length;

  /// 文字列値からOrderStatusを取得
  core_enums.OrderStatus? _getStatusFromValue(String value) => switch (value) {
    "pending" => core_enums.OrderStatus.pending,
    "preparing" => core_enums.OrderStatus.preparing,
    "ready" => core_enums.OrderStatus.ready,
    "delivered" => core_enums.OrderStatus.delivered,
    _ => null,
  };
}
