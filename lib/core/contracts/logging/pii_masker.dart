/// PII（個人情報）マスキング契約
abstract class PiiMaskerContract {
  /// 任意オブジェクト/マップ内のPIIをマスクして返す
  Object? mask(Object? value);

  /// 文字列をマスクして返す
  String maskString(String input);
}
