import "package:json_annotation/json_annotation.dart";

/// 支払い方法
@JsonEnum()
enum PaymentMethod {
  /// 現金支払い
  cash("cash"),

  /// クレジットカード・デビットカード支払い
  card("card"),

  /// 電子マネー・QRコード決済など、そのほかの方法
  other("other");

  const PaymentMethod(this.value);

  /// 支払い方法の値
  final String value;

  @override
  String toString() => value;
}

/// 取引タイプ
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

  /// 取引タイプの値
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
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

/// 参照タイプ
@JsonEnum()
enum ReferenceType {
  /// 注文
  order("order"),

  /// 仕入れ
  purchase("purchase"),

  /// 在庫調整
  adjustment("adjustment");

  const ReferenceType(this.value);

  /// 参照タイプの値
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
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

/// 在庫管理の単位タイプ
@JsonEnum()
enum UnitType {
  /// 個数
  piece("piece"),

  // TODO(dev): グラム管理が目安であるなら、たまに実際に確認をさせないとだめ？そのための処理？
  /// グラム。ただし、運用時に厳密に管理することは困難であるため、目安として使用
  gram("gram");

  // ?将来的には液体系、長さ系なども追加する可能性あり <- ただおそらくこれらもgramで統一管理可能ではある。

  const UnitType(this.value);

  /// 在庫管理の単位の値
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
  String get displayName {
    switch (this) {
      case UnitType.piece:
        return "個数";
      case UnitType.gram:
        return "グラム";
    }
  }

  /// 単位記号を取得
  String get symbol {
    switch (this) {
      case UnitType.piece:
        return "個";
      case UnitType.gram:
        return "g";
    }
  }
}

/// 在庫レベル。あくまで段階を列挙するものであり、具体的な数値は商品によって異なるため、列挙しない。
@JsonEnum()
enum StockLevel {
  /// 在庫あり（緑）
  sufficient("sufficient"),

  /// 在庫少（黄）
  low("low"),

  /// 緊急（赤）
  critical("critical");

  const StockLevel(this.value);

  /// 在庫レベルの値
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
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
  /// 準備中。オーダーが作成され、キッチンが未対応もしくは調理中である状態。
  preparing("preparing"),

  /// 完了。オーダー内の全てのアイテムが提供された状態。
  completed("completed"),

  /// キャンセル。オーダーがキャンセルされた状態。基本的にはオーダー作成後即座に割り当てられる想定。
  canceled("canceled");

  const OrderStatus(this.value);

  /// 注文ステータスの値
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
  String get displayName {
    switch (this) {
      case OrderStatus.preparing:
        return "準備中";
      case OrderStatus.completed:
        return "完了";
      case OrderStatus.canceled:
        return "キャンセル";
    }
  }

  // TODO(ui): ここはFlutterのColorオブジェクトを返すようにする
  /// 注文ステータスに対応する色を取得（Flutter用）
  String get colorName {
    switch (this) {
      case OrderStatus.preparing:
        return "blue";
      case OrderStatus.completed:
        return "green";
      case OrderStatus.canceled:
        return "red";
    }
  }

  /// ステータスがアクティブかどうかを判定
  bool get isActive => this == OrderStatus.preparing;

  /// ステータスが完了しているかどうかを判定
  bool get isFinished => this == OrderStatus.completed || this == OrderStatus.canceled;
}

/// ログレベル
@JsonEnum()
enum LogLevel {
  /// デバッグ。リリースには含まない。
  debug("debug"),

  /// 情報。リリースには含まない。
  info("info"),

  /// 警告。リリースにも含む。
  warning("warning"),

  /// エラー。リリースにも含む。
  error("error");

  const LogLevel(this.value);

  /// ログレベルの値
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
  String get displayName {
    switch (this) {
      case LogLevel.debug:
        return "デバッグ";
      case LogLevel.info:
        return "情報";
      case LogLevel.warning:
        return "警告";
      case LogLevel.error:
        return "エラー";
    }
  }

  /// developer.log()で使用する数値レベル
  int get developerLevel {
    switch (this) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }

  /// リリースビルドで保存するかどうか
  bool get shouldPersistInRelease => this == LogLevel.warning || this == LogLevel.error;

  /// ログレベルの優先度（数値が大きいほど重要）
  int get priority {
    switch (this) {
      case LogLevel.debug:
        return 1;
      case LogLevel.info:
        return 2;
      case LogLevel.warning:
        return 3;
      case LogLevel.error:
        return 4;
    }
  }
}
