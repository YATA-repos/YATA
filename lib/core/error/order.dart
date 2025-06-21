/// 注文関連のエラーメッセージ定義
enum OrderError {
  /// 注文が見つからない
  orderNotFound,

  /// 決済処理に失敗
  paymentFailed,

  /// 無効な注文ステータス
  invalidOrderStatus,

  /// 注文処理に失敗
  orderProcessingFailed,

  /// 注文キャンセルに失敗
  orderCancellationFailed,

  /// メニューアイテムが利用不可
  menuItemNotAvailable,

  /// 注文は既に完了している
  orderAlreadyCompleted,

  /// 無効な顧客情報
  invalidCustomerInfo;

  /// 英語エラーメッセージを取得
  String get message {
    switch (this) {
      case OrderError.orderNotFound:
        return "Order not found";
      case OrderError.paymentFailed:
        return "Payment processing failed";
      case OrderError.invalidOrderStatus:
        return "Invalid order status";
      case OrderError.orderProcessingFailed:
        return "Order processing failed";
      case OrderError.orderCancellationFailed:
        return "Order cancellation failed";
      case OrderError.menuItemNotAvailable:
        return "Menu item is not available";
      case OrderError.orderAlreadyCompleted:
        return "Order is already completed";
      case OrderError.invalidCustomerInfo:
        return "Invalid customer information";
    }
  }

  /// 日本語エラーメッセージを取得
  String get messageJa {
    switch (this) {
      case OrderError.orderNotFound:
        return "注文が見つかりません";
      case OrderError.paymentFailed:
        return "決済処理に失敗しました";
      case OrderError.invalidOrderStatus:
        return "無効な注文ステータスです";
      case OrderError.orderProcessingFailed:
        return "注文処理に失敗しました";
      case OrderError.orderCancellationFailed:
        return "注文キャンセルに失敗しました";
      case OrderError.menuItemNotAvailable:
        return "メニューアイテムが利用できません";
      case OrderError.orderAlreadyCompleted:
        return "注文は既に完了しています";
      case OrderError.invalidCustomerInfo:
        return "無効な顧客情報です";
    }
  }

  /// 組み合わせメッセージ（英語 + 日本語）を取得
  String get combinedMessage => "$message ($messageJa)";
}

/// 注文関連の警告メッセージ定義
enum OrderWarning {
  /// 注文処理が遅延する可能性
  orderProcessingDelay,

  /// 高い注文量を検出
  highOrderVolume,

  /// キッチンの処理能力が低下
  kitchenCapacityLow,

  /// 推定調理時間が増加
  estimatedDelayIncreased;

  /// 英語警告メッセージを取得
  String get message {
    switch (this) {
      case OrderWarning.orderProcessingDelay:
        return "Order processing may be delayed";
      case OrderWarning.highOrderVolume:
        return "High order volume detected";
      case OrderWarning.kitchenCapacityLow:
        return "Kitchen capacity is low";
      case OrderWarning.estimatedDelayIncreased:
        return "Estimated preparation time increased";
    }
  }

  /// 日本語警告メッセージを取得
  String get messageJa {
    switch (this) {
      case OrderWarning.orderProcessingDelay:
        return "注文処理が遅延する可能性があります";
      case OrderWarning.highOrderVolume:
        return "高い注文量を検出しました";
      case OrderWarning.kitchenCapacityLow:
        return "キッチンの処理能力が低下しています";
      case OrderWarning.estimatedDelayIncreased:
        return "推定調理時間が増加しました";
    }
  }

  /// 組み合わせメッセージ（英語 + 日本語）を取得
  String get combinedMessage => "$message ($messageJa)";
}
