/// カスタム例外の基底クラス
abstract class YataException implements Exception {
  const YataException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'YataException: $message${code != null ? ' (Code: $code)' : ''}';
}
