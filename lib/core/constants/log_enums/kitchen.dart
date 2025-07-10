import "../../base/base_error_msg.dart";

/// キッチンサービス関連の情報メッセージ定義
enum KitchenInfo implements LogMessage {
  /// 調理開始処理開始
  preparationStarted,

  /// 調理開始成功
  preparationStartedSuccessfully,

  /// 調理完了処理開始
  preparationCompletionStarted,

  /// 調理完了成功
  preparationCompletedSuccessfully,

  /// 配達処理開始
  deliveryStarted,

  /// 配達成功
  deliverySuccessful;

  @override
  String get message {
    switch (this) {
      case KitchenInfo.preparationStarted:
        return "Started order preparation process";
      case KitchenInfo.preparationStartedSuccessfully:
        return "Order preparation started successfully";
      case KitchenInfo.preparationCompletionStarted:
        return "Started completing order preparation";
      case KitchenInfo.preparationCompletedSuccessfully:
        return "Order preparation completed successfully";
      case KitchenInfo.deliveryStarted:
        return "Started delivering order";
      case KitchenInfo.deliverySuccessful:
        return "Order delivered successfully";
    }
  }
}

/// キッチンサービス関連の警告メッセージ定義
enum KitchenWarning implements LogMessage {
  /// 調理開始済み
  preparationAlreadyStarted,

  /// 調理開始失敗
  preparationStartFailed,

  /// 注文完了済み
  orderAlreadyCompleted,

  /// 調理完了失敗
  preparationCompletionFailed,

  /// 注文配達済み
  orderAlreadyDelivered,

  /// 配達失敗
  deliveryFailed;

  @override
  String get message {
    switch (this) {
      case KitchenWarning.preparationAlreadyStarted:
        return "Order preparation already started";
      case KitchenWarning.preparationStartFailed:
        return "Failed to start order preparation";
      case KitchenWarning.orderAlreadyCompleted:
        return "Order already completed";
      case KitchenWarning.preparationCompletionFailed:
        return "Failed to complete order preparation";
      case KitchenWarning.orderAlreadyDelivered:
        return "Order already delivered";
      case KitchenWarning.deliveryFailed:
        return "Failed to deliver order";
    }
  }
}

/// キッチンサービス関連のエラーメッセージ定義
enum KitchenError implements LogMessage {
  /// 注文アクセス拒否
  orderAccessDenied,

  /// 注文が調理待ち状態でない
  orderNotInPreparingStatus,

  /// 調理未開始
  preparationNotStarted,

  /// 配達準備未完了
  orderNotReadyForDelivery,

  /// 調理開始失敗
  startPreparationFailed,

  /// 調理完了失敗
  completePreparationFailed,

  /// 配達失敗
  deliverOrderFailed;

  @override
  String get message {
    switch (this) {
      case KitchenError.orderAccessDenied:
        return "Order access denied or order not found";
      case KitchenError.orderNotInPreparingStatus:
        return "Order is not in preparing status";
      case KitchenError.preparationNotStarted:
        return "Order preparation not started yet";
      case KitchenError.orderNotReadyForDelivery:
        return "Order not ready for delivery";
      case KitchenError.startPreparationFailed:
        return "Failed to start order preparation";
      case KitchenError.completePreparationFailed:
        return "Failed to complete order preparation";
      case KitchenError.deliverOrderFailed:
        return "Failed to deliver order";
    }
  }
}
