import "../../log_enums/log_enums.dart";
import "../base/base_context_exception.dart";
import "../base/exception_types.dart";

/// キッチン関連の例外クラス
///
/// キッチンサービス中に発生するエラーを管理します。
/// KitchenErrorと連携して、型安全なエラーハンドリングを提供します。
class KitchenException extends BaseContextException<KitchenError> {
  /// KitchenErrorを使用したコンストラクタ
  KitchenException(super.error, {super.params, super.code});

  /// 注文アクセス拒否例外の作成
  factory KitchenException.orderAccessDenied(String orderId) => KitchenException(
    KitchenError.orderAccessDenied,
    params: <String, String>{"orderId": orderId},
  );

  /// 注文が調理待ち状態でない例外の作成
  factory KitchenException.orderNotInPreparingStatus(String orderId, String currentStatus) =>
      KitchenException(
        KitchenError.orderNotInPreparingStatus,
        params: <String, String>{"orderId": orderId, "currentStatus": currentStatus},
      );

  /// 調理未開始例外の作成
  factory KitchenException.preparationNotStarted(String orderId) => KitchenException(
    KitchenError.preparationNotStarted,
    params: <String, String>{"orderId": orderId},
  );

  /// 配達準備未完了例外の作成
  factory KitchenException.orderNotReadyForDelivery(String orderId, String currentStatus) =>
      KitchenException(
        KitchenError.orderNotReadyForDelivery,
        params: <String, String>{"orderId": orderId, "currentStatus": currentStatus},
      );

  /// 調理開始失敗例外の作成
  factory KitchenException.startPreparationFailed(String orderId, String error) => KitchenException(
    KitchenError.startPreparationFailed,
    params: <String, String>{"orderId": orderId, "error": error},
  );

  /// 調理完了失敗例外の作成
  factory KitchenException.completePreparationFailed(String orderId, String error) =>
      KitchenException(
        KitchenError.completePreparationFailed,
        params: <String, String>{"orderId": orderId, "error": error},
      );

  /// 配達失敗例外の作成
  factory KitchenException.deliverOrderFailed(String orderId, String error) => KitchenException(
    KitchenError.deliverOrderFailed,
    params: <String, String>{"orderId": orderId, "error": error},
  );

  /// 例外タイプ
  ExceptionType get type => ExceptionType.kitchen;

  /// エラーの重要度を取得
  ExceptionSeverity get severity {
    switch (error) {
      case KitchenError.startPreparationFailed:
      case KitchenError.completePreparationFailed:
      case KitchenError.deliverOrderFailed:
        return ExceptionSeverity.critical;
      case KitchenError.orderAccessDenied:
        return ExceptionSeverity.high;
      case KitchenError.orderNotInPreparingStatus:
      case KitchenError.preparationNotStarted:
      case KitchenError.orderNotReadyForDelivery:
        return ExceptionSeverity.medium;
    }
  }
}
