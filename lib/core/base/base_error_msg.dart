/// ログメッセージの基底インターフェース
///
/// 全てのエラー・警告・情報メッセージenumが実装すべきインターフェース
abstract class LogMessage {
  /// メッセージを取得
  String get message;
}

/// エラーメッセージの拡張
extension ErrorMessageExtension on LogMessage {
  /// メッセージパラメータを置換
  ///
  /// 例: "User {userId} not found" → "User 123 not found"
  String withParams(Map<String, String> params) {
    String result = message;

    for (final MapEntry<String, String> entry in params.entries) {
      final String placeholder = "{${entry.key}}";
      result = result.replaceAll(placeholder, entry.value);
    }

    return result;
  }
}
