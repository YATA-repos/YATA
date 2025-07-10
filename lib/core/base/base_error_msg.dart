abstract class LogMessage {
  String get message;
}

extension ErrorMessageExtension on LogMessage {
  /// メッセージパラメータを置換して返す
  String withParams(Map<String, String> params) {
    String result = message;

    for (final MapEntry<String, String> entry in params.entries) {
      final String placeholder = "{${entry.key}}";
      result = result.replaceAll(placeholder, entry.value);
    }

    return result;
  }
}
