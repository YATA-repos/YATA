import "../../../core/constants/enums.dart";
import "../../../shared/components/data_display/status_badge.dart";
import "order_status_mapper.dart";

/// 注文ステータスの表示定義を一元管理するユーティリティ。
class OrderStatusPresentation {
  OrderStatusPresentation._();

  /// 画面上に表示する基本ラベル。
  static String label(OrderStatus status) => OrderStatusMapper.normalize(status).displayName;

  /// セクションなどで利用する表示順序を返す。
  static const List<OrderStatus> displayOrder = <OrderStatus>[
    OrderStatus.inProgress,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  /// ステータスに応じたバッジ種別を返す。
  static YataStatusBadgeType badgeType(OrderStatus status) {
    final OrderStatus normalized = OrderStatusMapper.normalize(status);
    if (normalized == OrderStatus.inProgress) {
      return YataStatusBadgeType.warning;
    }
    if (normalized == OrderStatus.completed) {
      return YataStatusBadgeType.success;
    }
    if (normalized == OrderStatus.cancelled) {
      return YataStatusBadgeType.danger;
    }
    return YataStatusBadgeType.warning;
  }

  /// フィルターなどで使用するヒント文。
  static String filterLabel(OrderStatus status) {
    final OrderStatus normalized = OrderStatusMapper.normalize(status);
    if (normalized == OrderStatus.inProgress) {
      return "準備中のみ";
    }
    if (normalized == OrderStatus.completed) {
      return "完了のみ";
    }
    if (normalized == OrderStatus.cancelled) {
      return "キャンセルのみ";
    }
    return "準備中のみ";
  }

  /// セグメントコントロール用の値一覧（「全て」を除く）。
  static List<(String label, OrderStatus status)> segmentOptions() => displayOrder
      .map<(String, OrderStatus)>(
        (OrderStatus status) => (label(status), status),
      )
      .toList(growable: false);
}
