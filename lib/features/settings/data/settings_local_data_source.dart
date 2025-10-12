import "package:shared_preferences/shared_preferences.dart";

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

/// SharedPreferences を使用してアプリ設定を永続化するローカルデータソース。
class SettingsLocalDataSource {
  SettingsLocalDataSource({SharedPreferencesLoader? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const String _prefix = "settings.app";
  static const String _schemaKey = "$_prefix.schema";
  static const String _taxRateKey = "$_prefix.tax_rate";
  static const String _developerModeKey = "$_prefix.debug.developer_mode";
  static const String _logLevelKey = "$_prefix.debug.log_level";
  static const String _logDirectoryKey = "$_prefix.log_directory";
  static const String _updatedAtKey = "$_prefix.updated_at";

  final SharedPreferencesLoader _preferencesLoader;

  Future<SharedPreferences> _prefs() => _preferencesLoader();

  /// 設定を読み込む。存在しない場合は `null` を返す。
  Future<SettingsCacheModel?> load() async {
    final SharedPreferences prefs = await _prefs();
    if (!prefs.containsKey(_schemaKey)) {
      return null;
    }

    final int? schemaVersion = prefs.getInt(_schemaKey);
    final double? taxRate = prefs.getDouble(_taxRateKey);
    final bool? developerMode = prefs.getBool(_developerModeKey);
    final String? logLevel = prefs.getString(_logLevelKey);
    final String? logDirectory = prefs.getString(_logDirectoryKey);
    final int? updatedAtEpoch = prefs.getInt(_updatedAtKey);

    if (schemaVersion == null || taxRate == null || developerMode == null || logLevel == null) {
      return null;
    }

    return SettingsCacheModel(
      schemaVersion: schemaVersion,
      taxRate: taxRate,
      developerMode: developerMode,
      globalLogLevel: logLevel,
      logDirectory: logDirectory,
      updatedAt: updatedAtEpoch != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtEpoch, isUtc: true).toLocal()
          : null,
    );
  }

  /// 設定を保存する。
  Future<void> save(SettingsCacheModel cache) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setInt(_schemaKey, cache.schemaVersion);
    await prefs.setDouble(_taxRateKey, cache.taxRate);
    await prefs.setBool(_developerModeKey, cache.developerMode);
    await prefs.setString(_logLevelKey, cache.globalLogLevel);

    if (cache.logDirectory != null && cache.logDirectory!.isNotEmpty) {
      await prefs.setString(_logDirectoryKey, cache.logDirectory!);
    } else {
      await prefs.remove(_logDirectoryKey);
    }

    if (cache.updatedAt != null) {
      await prefs.setInt(
        _updatedAtKey,
        cache.updatedAt!.toUtc().millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_updatedAtKey);
    }
  }

  /// 永続化された設定を削除する。
  Future<void> clear() async {
    final SharedPreferences prefs = await _prefs();
    await prefs.remove(_schemaKey);
    await prefs.remove(_taxRateKey);
    await prefs.remove(_developerModeKey);
    await prefs.remove(_logLevelKey);
    await prefs.remove(_logDirectoryKey);
    await prefs.remove(_updatedAtKey);
  }
}

/// SharedPreferences へ保存する際のプリミティブモデル。
class SettingsCacheModel {
  const SettingsCacheModel({
    required this.schemaVersion,
    required this.taxRate,
    required this.developerMode,
    required this.globalLogLevel,
    this.logDirectory,
    this.updatedAt,
  });

  final int schemaVersion;
  final double taxRate;
  final bool developerMode;
  final String globalLogLevel;
  final String? logDirectory;
  final DateTime? updatedAt;

  SettingsCacheModel copyWith({
    int? schemaVersion,
    double? taxRate,
    bool? developerMode,
    String? globalLogLevel,
    String? logDirectory,
    DateTime? updatedAt,
  }) => SettingsCacheModel(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        taxRate: taxRate ?? this.taxRate,
        developerMode: developerMode ?? this.developerMode,
        globalLogLevel: globalLogLevel ?? this.globalLogLevel,
        logDirectory: logDirectory ?? this.logDirectory,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
