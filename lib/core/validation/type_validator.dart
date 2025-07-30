import "../constants/exceptions/base/validation_exception.dart";

/// 型検証用ヘルパークラス
class TypeValidator {
  /// IDが有効な型かどうかを確認
  static bool isValidIdType(dynamic id) => id is String || id is int || id is Map<String, dynamic>;

  /// IDの型を検証し、無効な場合は例外を投げる
  static void validateId(dynamic id) {
    if (!isValidIdType(id)) {
      throw InvalidIdTypeException(id.runtimeType, <Type>[String, int, Map]);
    }
  }

  /// ID値を安全に取得（型検証付き）
  static T getValidatedId<T>(dynamic id) {
    validateId(id);
    return id as T;
  }
}
