import "../../../core/contracts/logging/logger.dart" as log_contract;
import "../domain/app_settings.dart";
import "settings_local_data_source.dart";
import "settings_mapper.dart";

/// アプリ設定の永続化を司るリポジトリ。
class SettingsRepository {
  SettingsRepository({
    required SettingsLocalDataSource localDataSource,
    SettingsMapper? mapper,
    log_contract.LoggerContract? logger,
  }) : _localDataSource = localDataSource,
       _mapper = mapper ?? const SettingsMapper(),
       _logger = logger;

  final SettingsLocalDataSource _localDataSource;
  final SettingsMapper _mapper;
  final log_contract.LoggerContract? _logger;

  static const String _loggerComponent = "SettingsRepository";

  /// 設定を読み込む。存在しない場合や読み取りに失敗した場合はデフォルト値を返す。
  Future<AppSettings> load() async {
    try {
      final SettingsCacheModel? cache = await _localDataSource.load();
      if (cache == null) {
        return AppSettings.defaults();
      }

      final AppSettings mapped = _mapper.fromCache(cache);

      if (cache.schemaVersion != AppSettings.currentSchemaVersion) {
        _logger?.w(
          "Schema mismatch detected. Falling back to defaults.",
          tag: _loggerComponent,
          fields: <String, Object?>{"schema": cache.schemaVersion},
        );
        final AppSettings defaults = AppSettings.defaults();
        return defaults.copyWith(
          taxRate: cache.taxRate,
          debug: defaults.debug.copyWith(
            developerMode: cache.developerMode,
            globalLogLevel: mapped.debug.globalLogLevel,
          ),
          logDirectory: cache.logDirectory,
        );
      }

      return mapped;
    } catch (error, stackTrace) {
      _logger?.e(
        "Failed to load app settings.",
        tag: _loggerComponent,
        error: error,
        st: stackTrace,
      );
      return AppSettings.defaults();
    }
  }

  /// 設定を保存し、保存後のスナップショットを返す。
  Future<AppSettings> save(AppSettings settings) async {
    final AppSettings next = settings.copyWith(
      schemaVersion: AppSettings.currentSchemaVersion,
      updatedAt: DateTime.now(),
    );
    final SettingsCacheModel cache = _mapper.toCache(next);
    await _localDataSource.save(cache);
    return next;
  }

  /// 永続化された設定を削除する。
  Future<void> clear() => _localDataSource.clear();
}
