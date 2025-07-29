import "package:flutter/material.dart";

import "../../../../core/constants/enums.dart" as core_enums;
import "../../../../core/utils/responsive_helper.dart";
import "../../models/order_model.dart";
import "order_status_card.dart";

/// 進行中注文グリッド
///
/// アクティブな注文をカード形式でグリッド表示
/// レスポンシブ対応でデバイスサイズに応じてカラム数を調整
class ActiveOrdersGrid extends StatelessWidget {
  const ActiveOrdersGrid({required this.orders, this.onOrderTap, this.onStatusUpdate, super.key});

  final List<Order> orders;
  final ValueChanged<Order>? onOrderTap;
  final void Function(Order, core_enums.OrderStatus)? onStatusUpdate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: ResponsiveHelper.getResponsivePadding(context),
    child: GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridColumns(context),
        childAspectRatio: _getChildAspectRatio(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: orders.length,
      itemBuilder: (BuildContext context, int index) {
        final Order order = orders[index];
        return OrderStatusCard(
          order: order,
          onTap: () => onOrderTap?.call(order),
          onStatusUpdate: (core_enums.OrderStatus newStatus) =>
              onStatusUpdate?.call(order, newStatus),
        );
      },
    ),
  );

  /// グリッドカラム数を取得
  int _getGridColumns(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return 3; // デスクトップ: 3カラム
    } else if (ResponsiveHelper.isTablet(context)) {
      return 2; // タブレット: 2カラム
    } else {
      return 1; // モバイル: 1カラム
    }
  }

  /// 子ウィジェットのアスペクト比を取得
  double _getChildAspectRatio(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return 1.4; // モバイル: より横長
    } else {
      return 1.1; // デスクトップ・タブレット: ほぼ正方形
    }
  }
}
