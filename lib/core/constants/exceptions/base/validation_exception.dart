import "yata_exception.dart";

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
