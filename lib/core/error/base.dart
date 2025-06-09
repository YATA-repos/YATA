/// ログメッセージの基底インターフェース
///
/// 全てのエラー・警告・情報メッセージenumが実装すべきインターフェース
abstract class LogMessage {
  /// 英語メッセージを取得
  String get message;

  /// 日本語メッセージを取得
  String get messageJa;

  /// 組み合わせメッセージ（英語 + 日本語）を取得
  String get combinedMessage;
}

/// エラーメッセージの拡張
extension ErrorMessageExtension on LogMessage {
  /// メッセージパラメータを置換
  ///
  /// 例: "User {userId} not found" → "User 123 not found"
  String withParams(Map<String, String> params) {
    String result = message;
    String resultJa = messageJa;

    for (final MapEntry<String, String> entry in params.entries) {
      final String placeholder = "{${entry.key}}";
      result = result.replaceAll(placeholder, entry.value);
      resultJa = resultJa.replaceAll(placeholder, entry.value);
    }

    return "$result ($resultJa)";
  }
}
