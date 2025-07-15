/// カスタム例外の基底クラス
abstract class YataException implements Exception {
  const YataException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'YataException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// 無効なID型例外
class InvalidIdTypeException extends YataException {
  const InvalidIdTypeException(this.providedType, this.expectedTypes)
    : super("Invalid ID type provided");

  final Type providedType;
  final List<Type> expectedTypes;

  @override
  String toString() =>
      "InvalidIdTypeException: Expected ${expectedTypes.join(', ')}, got $providedType";
}

/// 検証例外
class ValidationException extends YataException {
  const ValidationException(this.errors, {String? code}) : super("Validation failed", code: code);

  final List<String> errors;

  @override
  String toString() => "ValidationException: ${errors.join(', ')}";
}

/// 認証例外
class AuthenticationException extends YataException {
  const AuthenticationException(super.message, {super.code});
}

/// 権限例外
class PermissionException extends YataException {
  const PermissionException(super.message, {super.code});
}
