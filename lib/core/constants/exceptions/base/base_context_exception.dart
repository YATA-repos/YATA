import "../../../base/base_error_msg.dart";
import "yata_exception.dart";

/// コンテキスト別例外の基底クラス
///
/// すべてのコンテキスト別例外クラス（AuthException、InventoryExceptionなど）が
/// 継承する抽象基底クラス。Error enumとの型安全な連携とパラメータ化された
/// エラーメッセージをサポートします。
abstract class BaseContextException<T extends LogMessage> extends YataException {
  BaseContextException(this.error, {this.params = const <String, String>{}, String? code})
    : super(error.withParams(params), code: code);

  /// エラー種別
  final T error;

  /// エラーメッセージのパラメータ
  final Map<String, String> params;

  /// エラー種別の型を取得
  Type get errorType => T;

  @override
  String toString() {
    final String className = runtimeType.toString();
    return '$className: ${error.withParams(params)}${code != null ? ' (Code: $code)' : ''}';
  }
}
