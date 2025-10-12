import "package:json_annotation/json_annotation.dart";

@JsonEnum()
enum PaymentMethod {
  /// 現金支払い
  cash("cash"),

  /// QRコード決済 (PayPay)
  paypay("paypay"),

  /// 電子マネー・QRコード決済など、PayPay以外の方法
  other("other");

  const PaymentMethod(this.value);

  final String value;

  @override
  String toString() => value;
}

@JsonEnum()
enum TransactionType {
  /// 仕入れ・(店側の)購入
  purchase("purchase"),

  /// 販売
  sale("sale"),

  /// 在庫の手動調整の誤差を修正するときなど
  adjustment("adjustment"),

  /// 廃棄
  waste("waste");

  const TransactionType(this.value);

  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名
  String get displayName {
    switch (this) {
      case TransactionType.purchase:
        return "仕入れ";
      case TransactionType.sale:
        return "販売";
      case TransactionType.adjustment:
        return "在庫調整";
      case TransactionType.waste:
        return "廃棄";
    }
  }
}

@JsonEnum()
enum ReferenceType {
  /// 注文
  order("order"),

  /// 仕入れ
  purchase("purchase"),

  /// 在庫調整
  adjustment("adjustment");

  const ReferenceType(this.value);

  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名
  String get displayName {
    switch (this) {
      case ReferenceType.order:
        return "注文";
      case ReferenceType.purchase:
        return "仕入れ";
      case ReferenceType.adjustment:
        return "在庫調整";
    }
  }
}

@JsonEnum()
enum UnitType {
  /// 個数
  piece("piece"),

  /// グラム、重量。ただし、運用時に厳密に管理することは困難であるため、目安として使用
  /// 注意: 将来的に在庫確認アラート機能で定期的な実測確認を促す仕組みを検討
  gram("gram"),

  /// キログラム（重量）
  kilogram("kilogram"),

  /// リットル（体積）
  liter("liter");

  // NOTE: 将来的に液体系・長さ系の単位追加を検討（gramでの統一管理も可能）

  const UnitType(this.value);

  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名
  String get displayName {
    switch (this) {
      case UnitType.piece:
        return "個数";
      case UnitType.gram:
        return "グラム";
      case UnitType.kilogram:
        return "キログラム";
      case UnitType.liter:
        return "リットル";
    }
  }

  /// 単位記号を取得
  String get symbol {
    switch (this) {
      case UnitType.piece:
        return "個";
      case UnitType.gram:
        return "g";
      case UnitType.kilogram:
        return "kg";
      case UnitType.liter:
        return "L";
    }
  }
}

@JsonEnum()
enum StockLevel {
  /// 在庫あり（緑）
  sufficient("sufficient"),

  /// 在庫少（黄）
  low("low"),

  /// 緊急（赤）
  critical("critical");

  const StockLevel(this.value);

  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名
  String get displayName {
    switch (this) {
      case StockLevel.sufficient:
        return "在庫あり";
      case StockLevel.low:
        return "在庫少";
      case StockLevel.critical:
        return "緊急";
    }
  }

  /// 在庫レベルに対応する色を取得（Flutter用）
  /// 実際のColorオブジェクトは呼び出し側で定義する
  String get colorName {
    switch (this) {
      case StockLevel.sufficient:
        return "green";
      case StockLevel.low:
        return "yellow";
      case StockLevel.critical:
        return "red";
    }
  }
}

/// 注文ステータス
@JsonEnum()
enum OrderStatus {
  /// 調理・提供に向けて進行中の注文。旧 `pending` / `confirmed` / `preparing` / `ready` に相当。
  inProgress("in_progress"),

  /// キャンセル済み。旧 `cancelled` / `canceled` / `refunded` を包括。
  cancelled("cancelled"),

  /// 完了済み。旧 `ready` / `delivered` / `completed` を包括。
  completed("completed"),

  /// 以下の値は後方互換のため残存。
  @Deprecated("OrderStatus.inProgress を使用してください")
  pending("pending"),

  @Deprecated("OrderStatus.inProgress を使用してください")
  confirmed("confirmed"),

  @Deprecated("OrderStatus.inProgress を使用してください")
  preparing("preparing"),

  @Deprecated("OrderStatus.inProgress を使用してください")
  ready("ready"),

  @Deprecated("OrderStatus.completed を使用してください")
  delivered("delivered"),

  @Deprecated("OrderStatus.cancelled を使用してください")
  refunded("refunded");

  const OrderStatus(this.value);

  final String value;

  @override
  String toString() => value;

  /// 現在のステータスを新しい3状態に正規化する。
  OrderStatus get primaryStatus {
    switch (name) {
      case "inProgress":
      case "pending":
      case "confirmed":
      case "preparing":
      case "ready":
        return OrderStatus.inProgress;
      case "cancelled":
      case "refunded":
        return OrderStatus.cancelled;
      case "completed":
      case "delivered":
        return OrderStatus.completed;
      default:
        return OrderStatus.inProgress;
    }
  }

  /// 日本語での表示名
  String get displayName {
    final OrderStatus status = primaryStatus;
    if (status == OrderStatus.inProgress) {
      return "準備中";
    }
    if (status == OrderStatus.cancelled) {
      return "キャンセル済み";
    }
    return "完了";
  }

  /// 注文ステータスに対応する色を取得（Flutter用）
  /// 実際のColorオブジェクトは呼び出し側で定義する
  String get colorName {
    final OrderStatus status = primaryStatus;
    if (status == OrderStatus.inProgress) {
      return "orange";
    }
    if (status == OrderStatus.cancelled) {
      return "red";
    }
    return "green";
  }

  /// ステータスがアクティブ（進行中）かどうかを判定
  bool get isActive => primaryStatus == OrderStatus.inProgress;

  /// ステータスが完了しているかどうかを判定
  bool get isFinished => primaryStatus != OrderStatus.inProgress;

  /// ステータスが処理中かどうかを判定
  bool get isProcessing => primaryStatus == OrderStatus.inProgress;

  /// ステータスが顧客に表示すべきかどうかを判定
  bool get isVisibleToCustomer => name != "refunded";

  /// 新しい3状態セットを返す。
  static const List<OrderStatus> primaryStatuses = <OrderStatus>[
    OrderStatus.inProgress,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];
}

/// 優先度
@JsonEnum()
enum Priority {
  /// 低
  low("low"),

  /// 中
  medium("medium"),

  /// 高
  high("high"),

  /// 緊急
  urgent("urgent");

  const Priority(this.value);

  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名
  String get displayName {
    switch (this) {
      case Priority.low:
        return "低";
      case Priority.medium:
        return "中";
      case Priority.high:
        return "高";
      case Priority.urgent:
        return "緊急";
    }
  }

  /// 優先度の重要度（数値が大きいほど重要）
  int get importance {
    switch (this) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
      case Priority.urgent:
        return 4;
    }
  }
}

/// デバイスタイプ列挙型
enum DeviceType { mobile, tablet, desktop, largeDesktop }

/// メニュー表示モード
enum MenuDisplayMode {
  grid, // グリッド表示
  list, // リスト表示
}

/// 在庫表示モード
enum StockDisplayMode {
  grid, // グリッド表示
  list, // リスト表示
  alert, // アラートのみ表示
}

/// 在庫ステータス（ダッシュボード用）
enum InventoryStatus { inStock, lowStock, outOfStock }
