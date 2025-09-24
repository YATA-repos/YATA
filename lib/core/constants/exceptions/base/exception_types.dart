/// 例外のタイプを表すenum
///
/// 例外の分類やログレベルの判定などに使用されます。
enum ExceptionType {
  /// 認証関連の例外
  authentication("auth"),

  /// 在庫管理関連の例外
  inventory("inventory"),

  /// 注文関連の例外
  order("order"),

  /// キッチン関連の例外
  kitchen("kitchen"),

  /// メニュー関連の例外
  menu("menu"),

  /// サービス関連の例外
  service("service"),

  /// 分析関連の例外
  analytics("analytics"),

  /// リポジトリ関連の例外
  repository("repository");

  const ExceptionType(this.value);

  /// 例外タイプの文字列値
  final String value;

  @override
  String toString() => value;

  /// 文字列値から例外タイプを取得
  static ExceptionType? fromString(String value) {
    for (final ExceptionType type in ExceptionType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}

/// 例外の重要度レベル
enum ExceptionSeverity {
  /// 低レベル - 通常の処理で発生する可能性がある例外
  low,

  /// 中レベル - システムの動作に影響を与える可能性がある例外
  medium,

  /// 高レベル - システムの重要な機能に影響を与える例外
  high,

  /// 重大 - システム全体の動作に深刻な影響を与える例外
  critical;

  /// 重要度の数値表現（ログフィルタリングなどに使用）
  int get level {
    switch (this) {
      case ExceptionSeverity.low:
        return 1;
      case ExceptionSeverity.medium:
        return 2;
      case ExceptionSeverity.high:
        return 3;
      case ExceptionSeverity.critical:
        return 4;
    }
  }
}
