import "dart:async";

/// 環境変数では表現しきれない一時的な設定をアプリ実行中に差し替えるための仕組み。
///
/// - UI のデバッグメニューやリモート設定実験で利用することを想定。
/// - 値はメモリ上で保持され、永続化は行わない（必要に応じて呼び出し側で処理する）。
/// - キーはケースセンシティブ。機能ごとに一意なキー名を割り当てること。
class RuntimeOverrides {
  RuntimeOverrides._();

  static final Map<String, Object?> _values = <String, Object?>{};
  static final StreamController<RuntimeOverrideEvent> _controller =
      StreamController<RuntimeOverrideEvent>.broadcast();

  /// 登録済みのオーバーライド値を取得する。
  static Object? getValue(String key) => _values[key];

  /// boolean 値として取得する。未設定の場合は `null`。
  static bool? getBool(String key) => _values[key] as bool?;

  /// int 値として取得する。未設定の場合は `null`。
  static int? getInt(String key) => _values[key] as int?;

  /// 任意の値変更を監視するストリーム。
  static Stream<RuntimeOverrideEvent> get changes => _controller.stream;

  /// boolean オーバーライドを更新する。
  static void setBool(String key, {bool? value}) => _setValue(key, value);

  /// 整数オーバーライドを更新する。
  static void setInt(String key, {int? value}) => _setValue(key, value);

  /// 既存の値を削除する。
  static void clear(String key) {
    if (!_values.containsKey(key)) {
      return;
    }
    _values.remove(key);
    _controller.add(RuntimeOverrideEvent(key: key));
  }

  static void _setValue(String key, Object? value) {
    final Object? previous = _values[key];
    if (previous == value) {
      return;
    }
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
    _controller.add(RuntimeOverrideEvent(key: key, value: value));
  }
}

class RuntimeOverrideEvent {
  const RuntimeOverrideEvent({required this.key, this.value});

  final String key;
  final Object? value;
}
