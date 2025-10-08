import "../../../../core/contracts/logging/logger.dart" as log_contract;
import "../../models/order_model.dart";

/// 注文関連サービスで共通的に利用するバリデーションユーティリティ。
class OrderValidationUtils {
  const OrderValidationUtils._();

  /// 注文が指定ユーザーに属しているか検証し、問題がなければ非nullの [Order] を返す。
  ///
  /// 注文が存在しない、またはユーザーが一致しない場合はログを出力し、例外を投げる。
  /// 既定では [Exception] を投げるが、必要であれば [exceptionBuilder] で任意の例外を返せる。
  static Order requireOrderOwnedByUser({
    required Order? order,
    required String orderId,
    required String userId,
    required log_contract.LoggerContract logger,
    required String loggerComponent,
    void Function()? onFailureLog,
    Object Function()? exceptionBuilder,
  }) {
    if (order == null || order.userId != userId) {
      if (onFailureLog != null) {
        onFailureLog();
      } else {
        logger.e(
          "Order access denied or order not found",
          tag: loggerComponent,
          fields: <String, Object?>{
            "orderId": orderId,
            "userId": userId,
          },
        );
      }

      final Object exception = exceptionBuilder?.call() ??
          Exception("Order $orderId not found or access denied");
      throw exception;
    }

    return order;
  }

  /// 注文の所有者を検証し、所有者が一致しない場合は `null` を返す。
  ///
  /// 例外を投げずに呼び出し側で分岐させたいケース向けのユーティリティ。
  static Order? getOrderIfOwnedByUser({
    required Order? order,
    required String orderId,
    required String userId,
    required log_contract.LoggerContract logger,
    required String loggerComponent,
    void Function()? onFailureLog,
    void Function()? onSuccessLog,
  }) {
    if (order == null || order.userId != userId) {
      if (onFailureLog != null) {
        onFailureLog();
      } else {
        logger.w(
          "Order access denied or order not found",
          tag: loggerComponent,
          fields: <String, Object?>{
            "orderId": orderId,
            "userId": userId,
          },
        );
      }
      return null;
    }

    onSuccessLog?.call();
    return order;
  }
}
