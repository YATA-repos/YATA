import "../../log_enums/log_enums.dart";
import "../base/base_context_exception.dart";
import "../base/exception_types.dart";

/// サービス関連の例外クラス
///
/// サービス層で発生するエラーを管理します。
/// ServiceErrorと連携して、型安全なエラーハンドリングを提供します。
class ServiceException extends BaseContextException<ServiceError> {
  /// ServiceErrorを使用したコンストラクタ
  ServiceException(super.error, {super.params, super.code});

  /// 操作失敗例外の作成
  factory ServiceException.operationFailed(String operationType, String error) => ServiceException(
    ServiceError.operationFailed,
    params: <String, String>{"operationType": operationType, "error": error},
  );

  /// 材料作成失敗例外の作成
  factory ServiceException.materialCreationFailed(String materialName, String error) =>
      ServiceException(
        ServiceError.materialCreationFailed,
        params: <String, String>{"materialName": materialName, "error": error},
      );

  /// 在庫更新失敗例外の作成
  factory ServiceException.stockUpdateFailed(String materialName, String error) => ServiceException(
    ServiceError.stockUpdateFailed,
    params: <String, String>{"materialName": materialName, "error": error},
  );

  /// 仕入記録失敗例外の作成
  factory ServiceException.purchaseRecordingFailed(String error, {int? itemCount}) =>
      ServiceException(
        ServiceError.purchaseRecordingFailed,
        params: <String, String>{
          "error": error,
          if (itemCount != null) "itemCount": itemCount.toString(),
        },
      );

  /// 材料消費失敗例外の作成
  factory ServiceException.materialConsumptionFailed(String orderId, String error) =>
      ServiceException(
        ServiceError.materialConsumptionFailed,
        params: <String, String>{"orderId": orderId, "error": error},
      );

  /// 材料復元失敗例外の作成
  factory ServiceException.materialRestorationFailed(String orderId, String error) =>
      ServiceException(
        ServiceError.materialRestorationFailed,
        params: <String, String>{"orderId": orderId, "error": error},
      );

  /// CSVエクスポートの同時実行制限に抵触した場合
  factory ServiceException.concurrentExportInProgress(String organizationId) => ServiceException(
    ServiceError.concurrentExportInProgress,
    params: <String, String>{"organizationId": organizationId},
  );

  /// CSVエクスポートのレートリミットに到達した場合
  factory ServiceException.rateLimitExceeded({
    required String organizationId,
    required int dailyLimit,
    required DateTime resetAt,
  }) => ServiceException(
    ServiceError.exportRateLimitExceeded,
    params: <String, String>{
      "organizationId": organizationId,
      "dailyLimit": dailyLimit.toString(),
      "resetAt": resetAt.toIso8601String(),
    },
  );

  /// 指定されたエクスポートジョブが存在しない場合
  factory ServiceException.exportJobNotFound(String exportJobId) => ServiceException(
    ServiceError.exportJobNotFound,
    params: <String, String>{"exportJobId": exportJobId},
  );

  /// エクスポートジョブの再ダウンロード期限が切れている場合
  factory ServiceException.redownloadExpired(String exportJobId, DateTime expiresAt) =>
      ServiceException(
        ServiceError.exportRedownloadExpired,
        params: <String, String>{
          "exportJobId": exportJobId,
          "expiresAt": expiresAt.toIso8601String(),
        },
      );

  /// 在庫更新失敗（数量指定）例外の作成
  factory ServiceException.stockUpdateFailedWithQuantity(
    String materialName,
    int oldQuantity,
    int newQuantity,
    String error,
  ) => ServiceException(
    ServiceError.stockUpdateFailed,
    params: <String, String>{
      "materialName": materialName,
      "oldQuantity": oldQuantity.toString(),
      "newQuantity": newQuantity.toString(),
      "error": error,
    },
  );

  /// 材料消費失敗（数量指定）例外の作成
  factory ServiceException.materialConsumptionFailedWithQuantity(
    String materialName,
    int requiredQuantity,
    int availableQuantity,
    String error,
  ) => ServiceException(
    ServiceError.materialConsumptionFailed,
    params: <String, String>{
      "materialName": materialName,
      "requiredQuantity": requiredQuantity.toString(),
      "availableQuantity": availableQuantity.toString(),
      "error": error,
    },
  );

  /// 例外タイプ
  ExceptionType get type => ExceptionType.service;

  /// エラーの重要度を取得
  ExceptionSeverity get severity => switch (error) {
        ServiceError.operationFailed ||
        ServiceError.materialCreationFailed ||
        ServiceError.stockUpdateFailed ||
        ServiceError.purchaseRecordingFailed => ExceptionSeverity.critical,
        ServiceError.materialConsumptionFailed ||
        ServiceError.materialRestorationFailed => ExceptionSeverity.high,
        ServiceError.concurrentExportInProgress ||
        ServiceError.exportRateLimitExceeded => ExceptionSeverity.medium,
        ServiceError.exportJobNotFound ||
        ServiceError.exportRedownloadExpired => ExceptionSeverity.low,
      };
}
