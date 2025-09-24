import "../../log_enums/log_enums.dart";
import "../base/base_context_exception.dart";
import "../base/exception_types.dart";

/// メニュー関連の例外クラス
///
/// メニューサービス中に発生するエラーを管理します。
/// MenuErrorと連携して、型安全なエラーハンドリングを提供します。
class MenuException extends BaseContextException<MenuError> {
  /// MenuErrorを使用したコンストラクタ
  MenuException(super.error, {super.params, super.code});

  /// メニュー検索失敗例外の作成
  factory MenuException.searchFailed(String keyword, String error) => MenuException(
    MenuError.searchFailed,
    params: <String, String>{"keyword": keyword, "error": error},
  );

  /// 在庫チェック失敗例外の作成
  factory MenuException.availabilityCheckFailed(String menuId, String error) => MenuException(
    MenuError.availabilityCheckFailed,
    params: <String, String>{"menuId": menuId, "error": error},
  );

  /// 可否切り替え失敗例外の作成
  factory MenuException.toggleAvailabilityFailed(String menuId, String itemName, String error) =>
      MenuException(
        MenuError.toggleAvailabilityFailed,
        params: <String, String>{"menuId": menuId, "itemName": itemName, "error": error},
      );

  /// 在庫チェック失敗（数量指定）例外の作成
  factory MenuException.availabilityCheckFailedWithQuantity(
    String menuId,
    int quantity,
    String error,
  ) => MenuException(
    MenuError.availabilityCheckFailed,
    params: <String, String>{"menuId": menuId, "quantity": quantity.toString(), "error": error},
  );

  /// メニュー検索失敗（結果なし）例外の作成
  factory MenuException.searchFailedNoResults(String keyword) => MenuException(
    MenuError.searchFailed,
    params: <String, String>{
      "keyword": keyword,
      "error": "No menu items found matching the search criteria",
    },
  );

  /// 例外タイプ
  ExceptionType get type => ExceptionType.menu;

  /// エラーの重要度を取得
  ExceptionSeverity get severity {
    switch (error) {
      case MenuError.searchFailed:
      case MenuError.availabilityCheckFailed:
      case MenuError.toggleAvailabilityFailed:
        return ExceptionSeverity.high;
    }
  }
}
