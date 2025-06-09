/// 支払い方法
enum PaymentMethod {
  cash('cash'),
  card('card'),
  other('other');

  const PaymentMethod(this.value);
  final String value;

  @override
  String toString() => value;
}

/// 取引タイプ
enum TransactionType {
  purchase('purchase'), // 仕入れ
  sale('sale'), // 販売
  adjustment('adjustment'), // 在庫調整
  waste('waste'); // 廃棄

  const TransactionType(this.value);
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
  String get displayName {
    switch (this) {
      case TransactionType.purchase:
        return '仕入れ';
      case TransactionType.sale:
        return '販売';
      case TransactionType.adjustment:
        return '在庫調整';
      case TransactionType.waste:
        return '廃棄';
    }
  }
}

/// 参照タイプ
enum ReferenceType {
  order('order'), // 注文
  purchase('purchase'), // 仕入れ
  adjustment('adjustment'); // 在庫調整

  const ReferenceType(this.value);
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
  String get displayName {
    switch (this) {
      case ReferenceType.order:
        return '注文';
      case ReferenceType.purchase:
        return '仕入れ';
      case ReferenceType.adjustment:
        return '在庫調整';
    }
  }
}

/// 在庫管理の単位タイプ
enum UnitType {
  piece('piece'), // 個数管理（厳密）
  gram('gram'); // グラム管理（目安 <- TODO: たまに実際に確認をさせないとだめ？それようの処理？）

  const UnitType(this.value);
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
  String get displayName {
    switch (this) {
      case UnitType.piece:
        return '個数';
      case UnitType.gram:
        return 'グラム';
    }
  }

  /// 単位記号を取得
  String get symbol {
    switch (this) {
      case UnitType.piece:
        return '個';
      case UnitType.gram:
        return 'g';
    }
  }
}

/// 在庫レベル
enum StockLevel {
  sufficient('sufficient'), // 在庫あり（緑）
  low('low'), // 在庫少（黄）
  critical('critical'); // 緊急（赤）

  const StockLevel(this.value);
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
  String get displayName {
    switch (this) {
      case StockLevel.sufficient:
        return '在庫あり';
      case StockLevel.low:
        return '在庫少';
      case StockLevel.critical:
        return '緊急';
    }
  }

  /// 在庫レベルに対応する色を取得（Flutter用）
  /// 実際のColorオブジェクトは呼び出し側で定義する
  String get colorName {
    switch (this) {
      case StockLevel.sufficient:
        return 'green';
      case StockLevel.low:
        return 'yellow';
      case StockLevel.critical:
        return 'red';
    }
  }
}

/// 注文ステータス
enum OrderStatus {
  preparing('preparing'), // 準備中
  completed('completed'), // 完了
  canceled('canceled'); // キャンセル

  const OrderStatus(this.value);
  final String value;

  @override
  String toString() => value;

  /// 日本語での表示名を取得
  String get displayName {
    switch (this) {
      case OrderStatus.preparing:
        return '準備中';
      case OrderStatus.completed:
        return '完了';
      case OrderStatus.canceled:
        return 'キャンセル';
    }
  }

  // TODO: ここはFlutterのColorオブジェクトを返すようにする
  /// 注文ステータスに対応する色を取得（Flutter用）
  String get colorName {
    switch (this) {
      case OrderStatus.preparing:
        return 'blue';
      case OrderStatus.completed:
        return 'green';
      case OrderStatus.canceled:
        return 'red';
    }
  }

  /// ステータスがアクティブかどうかを判定
  bool get isActive {
    return this == OrderStatus.preparing;
  }

  /// ステータスが完了しているかどうかを判定
  bool get isFinished {
    return this == OrderStatus.completed || this == OrderStatus.canceled;
  }
}
