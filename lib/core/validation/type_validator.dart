import "../constants/exceptions/base/validation_exception.dart";
import "../logging/compat.dart" as log;

/// 型検証用ヘルパークラス
class TypeValidator {
  /// IDが有効な型かどうかを確認
  static bool isValidIdType(dynamic id) => id is String || id is int || id is Map<String, dynamic>;

  /// IDの型を検証し、無効な場合は例外を投げる
  static void validateId(dynamic id) {
    if (!isValidIdType(id)) {
      log.e(
        "ID型検証エラー: 無効な型 ${id.runtimeType}が渡されました。expectedTypes: [String, int, Map<String, dynamic>], actualType: ${id.runtimeType}, value: $id",
        tag: "TypeValidator",
      );
      throw InvalidIdTypeException(id.runtimeType, <Type>[String, int, Map]);
    }
  }

  /// ID値を安全に取得（型検証付き）
  static T getValidatedId<T>(dynamic id) {
    try {
      validateId(id);
      log.t("ID型検証成功: 型=${id.runtimeType}, 値=$id", tag: "TypeValidator");
      return id as T;
    } catch (e) {
      log.e(
        "ID型キャストエラー: $T型へのキャストに失敗。sourceType: ${id.runtimeType}, targetType: $T, value: $id",
        tag: "TypeValidator",
      );
      rethrow;
    }
  }
}
