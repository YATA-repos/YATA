import "../../../infra/logging/log_level.dart";
import "../domain/app_settings.dart";
import "settings_local_data_source.dart";

/// ドメインモデルと永続化モデルを相互変換するマッパー。
class SettingsMapper {
  const SettingsMapper();

  AppSettings fromCache(SettingsCacheModel cache) => AppSettings(
        schemaVersion: cache.schemaVersion,
        taxRate: cache.taxRate,
        debug: DebugOptions(
          developerMode: cache.developerMode,
          globalLogLevel: _parseLogLevel(cache.globalLogLevel),
        ),
        logDirectory: cache.logDirectory,
        updatedAt: cache.updatedAt,
      );

  SettingsCacheModel toCache(AppSettings settings) => SettingsCacheModel(
        schemaVersion: settings.schemaVersion,
        taxRate: settings.taxRate,
        developerMode: settings.debug.developerMode,
        globalLogLevel: settings.debug.globalLogLevel.name,
        logDirectory: settings.logDirectory,
        updatedAt: settings.updatedAt,
      );

  LogLevel _parseLogLevel(String raw) => LogLevel.values.firstWhere(
      (LogLevel level) => level.name == raw,
      orElse: () => LogLevel.info,
    );
}
