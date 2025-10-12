import "package:flutter/foundation.dart";

import "../../../infra/logging/log_level.dart";

/// デバッグ関連設定を保持する不変モデル。
@immutable
class DebugOptions {
  /// [DebugOptions] を生成する。
  const DebugOptions({
    required this.developerMode,
    required this.globalLogLevel,
  });

  /// デフォルト値を返す。
  factory DebugOptions.defaults() => DebugOptions(
        developerMode: !kReleaseMode,
        globalLogLevel: kReleaseMode ? LogLevel.info : LogLevel.debug,
      );

  /// デベロッパーモードを有効にするか。
  final bool developerMode;

  /// ログ全体の出力レベル。
  final LogLevel globalLogLevel;

  /// コピーを生成する。
  DebugOptions copyWith({
    bool? developerMode,
    LogLevel? globalLogLevel,
  }) => DebugOptions(
        developerMode: developerMode ?? this.developerMode,
        globalLogLevel: globalLogLevel ?? this.globalLogLevel,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DebugOptions && developerMode == other.developerMode && globalLogLevel == other.globalLogLevel;

  @override
  int get hashCode => Object.hash(developerMode, globalLogLevel);

  @override
  String toString() => "DebugOptions(developerMode: $developerMode, globalLogLevel: ${globalLogLevel.name})";
}

/// アプリ全体の設定値を表現するドメインモデル。
@immutable
class AppSettings {
  /// [AppSettings] を生成する。
  const AppSettings({
    required this.schemaVersion,
    required this.taxRate,
    required this.debug,
    this.logDirectory,
    this.updatedAt,
  });

  /// デフォルト設定。
  factory AppSettings.defaults() => AppSettings(
        schemaVersion: currentSchemaVersion,
        taxRate: 0.10,
        debug: DebugOptions.defaults(),
        updatedAt: DateTime.now(),
      );

  /// 設定スキーマのバージョン番号。
  final int schemaVersion;

  /// 課税率（例: 0.1 = 10%）。
  final double taxRate;

  /// デバッグ設定。
  final DebugOptions debug;

  /// ログ保存先ディレクトリ。`null` の場合はデフォルトを利用。
  final String? logDirectory;

  /// 最終更新日時。
  final DateTime? updatedAt;

  /// 現行スキーマバージョン。
  static const int currentSchemaVersion = 1;

  /// 設定値を更新したコピーを返す。
  AppSettings copyWith({
    double? taxRate,
    DebugOptions? debug,
    String? logDirectory,
    DateTime? updatedAt,
    int? schemaVersion,
  }) => AppSettings(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        taxRate: taxRate ?? this.taxRate,
        debug: debug ?? this.debug,
        logDirectory: logDirectory ?? this.logDirectory,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  /// 課税率をパーセンテージ表記で返す。
  double get taxRatePercent => taxRate * 100;

  /// ディレクトリが指定されているか。
  bool get hasCustomLogDirectory => logDirectory != null && logDirectory!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! AppSettings) {
      return false;
    }
    return schemaVersion == other.schemaVersion &&
        taxRate == other.taxRate &&
        debug == other.debug &&
        logDirectory == other.logDirectory;
  }

  @override
  int get hashCode => Object.hash(schemaVersion, taxRate, debug, logDirectory);

  @override
  String toString() =>
      "AppSettings(schemaVersion: $schemaVersion, taxRate: $taxRate, debug: $debug, logDirectory: $logDirectory)";
}
