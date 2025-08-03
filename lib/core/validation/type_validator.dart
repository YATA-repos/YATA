import "../constants/exceptions/base/validation_exception.dart";
import "../logging/yata_logger.dart";

/// 型検証用ヘルパークラス
class TypeValidator {
  /// IDが有効な型かどうかを確認
  static bool isValidIdType(dynamic id) => id is String || id is int || id is Map<String, dynamic>;

  /// IDの型を検証し、無効な場合は例外を投げる
  static void validateId(dynamic id) {
    if (!isValidIdType(id)) {
      YataLogger.error("TypeValidator", "ID型検証エラー: 無効な型 ${id.runtimeType}が渡されました。expectedTypes: [String, int, Map<String, dynamic>], actualType: ${id.runtimeType}, value: $id");
      throw InvalidIdTypeException(id.runtimeType, <Type>[String, int, Map]);
    }
  }

  /// ID値を安全に取得（型検証付き）
  static T getValidatedId<T>(dynamic id) {
    try {
      validateId(id);
      YataLogger.trace("TypeValidator", "ID型検証成功: 型=${id.runtimeType}, 値=$id");
      return id as T;
    } catch (e) {
      YataLogger.error("TypeValidator", "ID型キャストエラー: $T型へのキャストに失敗。sourceType: ${id.runtimeType}, targetType: $T, value: $id");
      rethrow;
    }
  }
}
