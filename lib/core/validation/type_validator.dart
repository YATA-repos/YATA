import "../constants/exceptions/base/validation_exception.dart";
import "../logging/logger_binding.dart";

/// 型検証用ヘルパークラス
class TypeValidator {
  static const String _tag = "TypeValidator";

  static void _trace(String message) {
    LoggerBinding.instance.t(message, tag: _tag);
  }

  static void _error(String message) {
    LoggerBinding.instance.e(message, tag: _tag);
  }

  /// IDが有効な型かどうかを確認
  static bool isValidIdType(dynamic id) => id is String || id is int || id is Map<String, dynamic>;

  /// IDの型を検証し、無効な場合は例外を投げる
  static void validateId(dynamic id) {
    if (!isValidIdType(id)) {
      _error(
        "ID型検証エラー: 無効な型 ${id.runtimeType}が渡されました。expectedTypes: [String, int, Map<String, dynamic>], actualType: ${id.runtimeType}, value: $id",
      );
      throw InvalidIdTypeException(id.runtimeType, <Type>[String, int, Map]);
    }
  }

  /// ID値を安全に取得（型検証付き）
  static T getValidatedId<T>(dynamic id) {
    try {
      validateId(id);
      _trace("ID型検証成功: 型=${id.runtimeType}, 値=$id");
      return id as T;
    } catch (e) {
      _error(
        "ID型キャストエラー: $T型へのキャストに失敗。sourceType: ${id.runtimeType}, targetType: $T, value: $id",
      );
      rethrow;
    }
  }
}
