import "package:json_annotation/json_annotation.dart";

/// 統合ログレベル定義
/// 
/// 従来の LogLevel と Level を統合し、包括的なログレベル管理を提供します。
/// JSON シリアライゼーション、日本語表示、開発者ログ対応、優先度管理などの
/// 機能を統一したインターフェースで提供します。
@JsonEnum()
enum Level {
  /// トレースレベル（最も詳細なデバッグ情報）
  trace(10, "trace"),

  /// デバッグレベル（開発時のデバッグ情報）
  debug(20, "debug"),

  /// 情報レベル（通常の情報）
  info(30, "info"),

  /// 警告レベル（注意が必要な情報）
  warn(40, "warning"),

  /// エラーレベル（処理可能なエラー）
  error(50, "error"),

  /// 致命的レベル（致命的なエラー）
  fatal(60, "fatal");

  const Level(this.severity, this.value);

  /// ログレベルの重要度（数値が大きいほど重要）
  final int severity;

  /// JSON シリアライゼーション用の値
  final String value;

  /// 文字列からログレベルを解析
  /// 
  /// [s] 解析する文字列
  /// 戻り値: 対応するログレベル（解析できない場合は info）
  static Level fromString(String s) {
    switch (s.toLowerCase()) {
      case "trace":
        return Level.trace;
      case "debug":
        return Level.debug;
      case "info":
        return Level.info;
      case "warn":
      case "warning":
        return Level.warn;
      case "error":
        return Level.error;
      case "fatal":
        return Level.fatal;
      default:
        return Level.info;
    }
  }

  /// 日本語での表示名
  String get displayName {
    switch (this) {
      case Level.trace:
        return "トレース";
      case Level.debug:
        return "デバッグ";
      case Level.info:
        return "情報";
      case Level.warn:
        return "警告";
      case Level.error:
        return "エラー";
      case Level.fatal:
        return "致命的";
    }
  }

  /// developer.log() で使用する数値レベル
  int get developerLevel {
    switch (this) {
      case Level.trace:
        return 400;
      case Level.debug:
        return 500;
      case Level.info:
        return 800;
      case Level.warn:
        return 900;
      case Level.error:
        return 1000;
      case Level.fatal:
        return 1200;
    }
  }

  /// リリースビルドで保存するかどうか
  bool get shouldPersistInRelease {
    switch (this) {
      case Level.trace:
      case Level.debug:
      case Level.info:
        return false;
      case Level.warn:
      case Level.error:
      case Level.fatal:
        return true;
    }
  }

  /// ログレベルの優先度（数値が大きいほど重要）
  /// 
  /// severity と同じ値ですが、より明示的な意味を持ちます。
  int get priority => severity;

  @override
  String toString() => value.toUpperCase();
}