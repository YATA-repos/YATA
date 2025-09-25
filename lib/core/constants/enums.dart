import "package:json_annotation/json_annotation.dart";

@JsonEnum()
enum PaymentMethod {
  /// 現金支払い
  cash("cash"),

  /// クレジットカード・デビットカード支払い
  card("card"),

  /// 電子マネー・QRコード決済など、そのほかの方法
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
  /// 待機中。注文が受け付けられ、まだ確認されていない状態。
  pending("pending"),

  /// 確認済み。注文が確認され、処理が開始される状態。
  confirmed("confirmed"),

  /// 準備中。オーダーが作成され、キッチンが未対応もしくは調理中である状態。
  preparing("preparing"),

  /// 準備完了。調理が完了し、提供準備ができた状態。
  ready("ready"),

  /// 配達済み。顧客に提供された状態。
  delivered("delivered"),

  /// 完了。オーダー内の全てのアイテムが提供された状態。
  completed("completed"),

  /// キャンセル。オーダーがキャンセルされた状態。基本的にはオーダー作成後即座に割り当てられる想定。
  cancelled("canceled"),

  /// 返金済み。キャンセルされた注文で返金が完了した状態。
  refunded("refunded");

  const OrderStatus(this.value);

  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return "待機中";
      case OrderStatus.confirmed:
        return "確認済み";
      case OrderStatus.preparing:
        return "準備中";
      case OrderStatus.ready:
        return "準備完了";
      case OrderStatus.delivered:
        return "配達済み";
      case OrderStatus.completed:
        return "完了";
      case OrderStatus.cancelled:
        return "キャンセル";
      case OrderStatus.refunded:
        return "返金済み";
    }
  }

  /// 注文ステータスに対応する色を取得（Flutter用）
  /// 実際のColorオブジェクトは呼び出し側で定義する
  String get colorName {
    switch (this) {
      case OrderStatus.pending:
        return "gray";
      case OrderStatus.confirmed:
        return "blue";
      case OrderStatus.preparing:
        return "orange";
      case OrderStatus.ready:
        return "green";
      case OrderStatus.delivered:
        return "purple";
      case OrderStatus.completed:
        return "green";
      case OrderStatus.cancelled:
        return "red";
      case OrderStatus.refunded:
        return "gray";
    }
  }

  /// ステータスがアクティブかどうかを判定
  bool get isActive =>
      this == OrderStatus.pending ||
      this == OrderStatus.confirmed ||
      this == OrderStatus.preparing ||
      this == OrderStatus.ready;

  /// ステータスが完了しているかどうかを判定
  bool get isFinished =>
      this == OrderStatus.delivered ||
      this == OrderStatus.completed ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.refunded;

  /// ステータスが処理中かどうかを判定
  bool get isProcessing => this == OrderStatus.confirmed || this == OrderStatus.preparing;

  /// ステータスが顧客に表示すべきかどうかを判定
  bool get isVisibleToCustomer => this != OrderStatus.refunded;
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
