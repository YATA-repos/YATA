import "../../base/base_error_msg.dart";

/// 注文関連のエラーメッセージ定義
enum OrderError implements LogMessage {
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

  @override
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
}

/// 注文関連の警告メッセージ定義
enum OrderWarning implements LogMessage {
  /// 注文処理が遅延する可能性
  orderProcessingDelay,

  /// 高い注文量を検出
  highOrderVolume,

  /// キッチンの処理能力が低下
  kitchenCapacityLow,

  /// 推定調理時間が増加
  estimatedDelayIncreased;

  @override
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
}
