/// アプリ内のアナリティクスイベントを記録するための契約。
///
/// Firebase Analytics や社内計測基盤など、送信先が変わっても
/// サービス層からはイベント名とプロパティを渡すだけで利用できるようにする。
abstract class AnalyticsLoggerContract {
  const AnalyticsLoggerContract();

  /// アナリティクスイベントを記録する。
  ///
  /// [eventName] は `snake_case` を推奨する。
  /// [properties] には計測するフィールドを指定する。
  /// 失敗系イベントでは [error] や [stackTrace] を補足として渡せる。
  void track(
    String eventName, {
    Map<String, Object?>? properties,
    Object? error,
    StackTrace? stackTrace,
  });
}
