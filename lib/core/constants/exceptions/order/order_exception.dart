import "../../log_enums/log_enums.dart";
import "../base/base_context_exception.dart";
import "../base/exception_types.dart";

/// 注文関連の例外クラス
///
/// 注文プロセス中に発生するエラーを管理します。
/// OrderErrorと連携して、型安全なエラーハンドリングを提供します。
class OrderException extends BaseContextException<OrderError> {
  /// OrderErrorを使用したコンストラクタ
  OrderException(super.error, {super.params, super.code});

  /// 注文既完了例外の作成
  factory OrderException.orderAlreadyCompleted(String orderId, String completedAt) =>
      OrderException(
        OrderError.orderAlreadyCompleted,
        params: <String, String>{"orderId": orderId, "completedAt": completedAt},
      );

  /// 注文未発見例外の作成
  factory OrderException.orderNotFound(String orderId) =>
      OrderException(OrderError.orderNotFound, params: <String, String>{"orderId": orderId});

  /// 決済失敗例外の作成
  factory OrderException.paymentFailed(String reason, {String? transactionId}) => OrderException(
    OrderError.paymentFailed,
    params: <String, String>{
      "reason": reason,
      if (transactionId != null) "transactionId": transactionId,
    },
  );

  /// 無効な注文ステータス例外の作成
  factory OrderException.invalidOrderStatus(String currentStatus, String expectedStatus) =>
      OrderException(
        OrderError.invalidOrderStatus,
        params: <String, String>{"currentStatus": currentStatus, "expectedStatus": expectedStatus},
      );

  /// 注文処理失敗例外の作成
  factory OrderException.orderProcessingFailed(String orderId, String error) => OrderException(
    OrderError.orderProcessingFailed,
    params: <String, String>{"orderId": orderId, "error": error},
  );

  /// 注文キャンセル失敗例外の作成
  factory OrderException.orderCancellationFailed(String orderId, String reason) => OrderException(
    OrderError.orderCancellationFailed,
    params: <String, String>{"orderId": orderId, "reason": reason},
  );

  /// メニューアイテム利用不可例外の作成
  factory OrderException.menuItemNotAvailable(String itemName, String menuId) => OrderException(
    OrderError.menuItemNotAvailable,
    params: <String, String>{"itemName": itemName, "menuId": menuId},
  );

  /// 無効な顧客情報例外の作成
  factory OrderException.invalidCustomerInfo(String field, String value) => OrderException(
    OrderError.invalidCustomerInfo,
    params: <String, String>{"field": field, "value": value},
  );

  /// 例外タイプ
  ExceptionType get type => ExceptionType.order;

  /// エラーの重要度を取得
  ExceptionSeverity get severity {
    switch (error) {
      case OrderError.paymentFailed:
      case OrderError.orderProcessingFailed:
        return ExceptionSeverity.critical;
      case OrderError.orderNotFound:
      case OrderError.orderCancellationFailed:
      case OrderError.menuItemNotAvailable:
        return ExceptionSeverity.high;
      case OrderError.invalidOrderStatus:
      case OrderError.orderAlreadyCompleted:
        return ExceptionSeverity.medium;
      case OrderError.invalidCustomerInfo:
        return ExceptionSeverity.low;
    }
  }
}
