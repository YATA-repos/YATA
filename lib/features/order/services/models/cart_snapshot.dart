import "../../../menu/models/menu_model.dart";
import "../../models/order_model.dart";

/// カートの最新状態を表現するサービス層スナップショット。
class CartSnapshotData {
  CartSnapshotData({required this.order, required this.orderItems, required this.menuItems});

  /// 更新後のカート本体。
  final Order order;

  /// 注文明細の一覧。
  final List<OrderItem> orderItems;

  /// 明細に対応するメニュー情報。
  final List<MenuItem> menuItems;
}

/// カート操作結果の種別。
enum CartMutationKind { add, update, remove, clear, refresh }

/// カート操作の結果と最新スナップショット。
class CartMutationResult {
  CartMutationResult({
    required this.kind,
    required this.snapshot,
    this.stockStatus,
    this.highlightMenuItemId,
  });

  /// 操作種別。
  final CartMutationKind kind;

  /// 操作後の最新スナップショット。
  final CartSnapshotData snapshot;

  /// 在庫判定結果。キーは menuItemId。
  final Map<String, bool>? stockStatus;

  /// UI ハイライト対象のメニューID。
  final String? highlightMenuItemId;

  /// 在庫不足が含まれているかどうか。
  bool get hasStockIssue => stockStatus?.values.any((bool sufficient) => !sufficient) ?? false;
}
