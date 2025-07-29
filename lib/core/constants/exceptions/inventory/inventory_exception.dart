import "../../log_enums/log_enums.dart";
import "../base/base_context_exception.dart";
import "../base/exception_types.dart";

/// 在庫管理関連の例外クラス
///
/// 在庫管理プロセス中に発生するエラーを管理します。
/// InventoryErrorと連携して、型安全なエラーハンドリングを提供します。
class InventoryException extends BaseContextException<InventoryError> {
  /// InventoryErrorを使用したコンストラクタ
  InventoryException(
    super.error, {
    super.params,
    super.code,
  });

  /// アイテム未発見例外の作成
  factory InventoryException.itemNotFound(String itemId) =>
      InventoryException(InventoryError.itemNotFound, params: <String, String>{"itemId": itemId});

  /// 在庫不足例外の作成
  factory InventoryException.insufficientStock(String itemName, int available, int required) =>
      InventoryException(
        InventoryError.insufficientStock,
        params: <String, String>{
          "itemName": itemName,
          "available": available.toString(),
          "required": required.toString(),
        },
      );

  /// 期限切れアイテム例外の作成
  factory InventoryException.expiredItem(String itemName, String expiryDate) => InventoryException(
    InventoryError.expiredItem,
    params: <String, String>{"itemName": itemName, "expiryDate": expiryDate},
  );

  /// 無効な数量例外の作成
  factory InventoryException.invalidQuantity(String quantity) => InventoryException(
    InventoryError.invalidQuantity,
    params: <String, String>{"quantity": quantity},
  );

  /// 在庫更新失敗例外の作成
  factory InventoryException.stockUpdateFailed(String itemName, String error) => InventoryException(
    InventoryError.stockUpdateFailed,
    params: <String, String>{"itemName": itemName, "error": error},
  );

  /// カテゴリ未発見例外の作成
  factory InventoryException.categoryNotFound(String categoryId) => InventoryException(
    InventoryError.categoryNotFound,
    params: <String, String>{"categoryId": categoryId},
  );

  /// 重複アイテム例外の作成
  factory InventoryException.duplicateItem(String itemName) => InventoryException(
    InventoryError.duplicateItem,
    params: <String, String>{"itemName": itemName},
  );

  /// 在庫レベル危険例外の作成
  factory InventoryException.stockLevelCritical(
    String itemName,
    int currentLevel,
    int minimumLevel,
  ) => InventoryException(
    InventoryError.stockLevelCritical,
    params: <String, String>{
      "itemName": itemName,
      "currentLevel": currentLevel.toString(),
      "minimumLevel": minimumLevel.toString(),
    },
  );

  /// 例外タイプ
  ExceptionType get type => ExceptionType.inventory;

  /// エラーの重要度を取得
  ExceptionSeverity get severity {
    switch (error) {
      case InventoryError.stockLevelCritical:
        return ExceptionSeverity.critical;
      case InventoryError.insufficientStock:
      case InventoryError.stockUpdateFailed:
        return ExceptionSeverity.high;
      case InventoryError.itemNotFound:
      case InventoryError.expiredItem:
      case InventoryError.categoryNotFound:
        return ExceptionSeverity.medium;
      case InventoryError.invalidQuantity:
      case InventoryError.duplicateItem:
        return ExceptionSeverity.low;
    }
  }
}
