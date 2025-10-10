import "dart:async";
import "dart:io";
import "dart:math";
import "package:path_provider/path_provider.dart";

import "../../../infra/config/runtime_overrides.dart";
import "../../../infra/logging/log_config.dart";
import "../../../infra/logging/logger.dart" as app_logger;
import "../../../core/constants/exceptions/settings/settings_exception.dart";
import "../../../core/contracts/logging/logger.dart" as log_contract;
import "../../auth/services/auth_service.dart";
import "../data/settings_repository.dart";
import "../domain/app_settings.dart";

/// アプリ全体の設定を管理するサービス。
class SettingsService {
  SettingsService({
    required SettingsRepository repository,
    required AuthService authService,
    required log_contract.LoggerContract logger,
  }) : _repository = repository,
       _authService = authService,
       _logger = logger,
       _controller = StreamController<AppSettings>.broadcast(),
       _current = AppSettings.defaults() {
    _controller.add(_current);
  }

  static const String _loggerComponent = "SettingsService";
  static const String _runtimeDeveloperModeKey = "runtime.settings.developer_mode";
  static const String _runtimeLogLevelKey = "runtime.settings.log_level";

  final SettingsRepository _repository;
  final AuthService _authService;
  final log_contract.LoggerContract _logger;
  final StreamController<AppSettings> _controller;

  AppSettings _current;
  bool _isLoaded = false;

  /// 現在の設定スナップショット。
  AppSettings get current => _current;

  /// 設定変更のストリーム。購読時に直近の状態も通知する。
  Stream<AppSettings> watch() =>
      Stream<AppSettings>.multi((StreamController<AppSettings> observer) {
        observer.add(_current);
        final StreamSubscription<AppSettings> subscription = _controller.stream.listen(
          observer.add,
          onError: observer.addError,
          onDone: observer.close,
        );
        observer.onCancel = subscription.cancel;
      });

  /// 設定を読み込み、関連コンポーネントに適用する。
  Future<AppSettings> loadAndApply() async {
    final AppSettings loaded = await _repository.load();
    await _applySettings(loaded, previous: _isLoaded ? _current : null, source: "load");
    _setCurrent(loaded);
    _isLoaded = true;
    return loaded;
  }

  /// 設定を再読込し、現在値とストリームへ反映する。
  Future<AppSettings> reload() => loadAndApply();

  /// 消費税率を更新する。
  Future<AppSettings> updateTaxRate(double nextRate) async {
    await _ensureLoaded();
    final double normalized = _normalizeTaxRate(nextRate);
    if ((normalized - _current.taxRate).abs() < 0.0001) {
      return _current;
    }

    final AppSettings updated = _current.copyWith(taxRate: normalized);
    final AppSettings persisted = await _repository.save(updated);
    _setCurrent(persisted);
    _logger.i(
      "Tax rate updated to ${(normalized * 100).toStringAsFixed(2)}%",
      tag: _loggerComponent,
    );
    return persisted;
  }

  /// デバッグ設定を更新する。
  Future<AppSettings> updateDebugOptions(DebugOptions next) async {
    await _ensureLoaded();
    final DebugOptions previous = _current.debug;
    if (previous == next) {
      return _current;
    }

    await _applyDebugOptions(next, previous: previous);
    final AppSettings persisted = await _repository.save(_current.copyWith(debug: next));
    _setCurrent(persisted);
    return persisted;
  }

  /// ログディレクトリを更新する。
  Future<AppSettings> updateLogDirectory(String? directoryPath) async {
    await _ensureLoaded();
    final String? sanitized = await _sanitizeDirectory(directoryPath);
    if (sanitized == _current.logDirectory) {
      return _current;
    }

    await _applyLogDirectory(sanitized, previous: _current.logDirectory);
    final AppSettings persisted = await _repository.save(
      _current.copyWith(logDirectory: sanitized),
    );
    _setCurrent(persisted);
    return persisted;
  }

  /// ログディレクトリをデフォルトに戻す。
  Future<AppSettings> resetLogDirectory() => updateLogDirectory(null);

  /// ログアウトを実行し、設定を初期化する。
  Future<void> signOut({bool allDevices = false}) async {
    await _authService.signOut(allDevices: allDevices);
    await _repository.clear();
    final AppSettings defaults = AppSettings.defaults();
    await _applySettings(defaults, previous: _current, source: "signOut");
    _setCurrent(defaults);
  }

  /// デフォルトのログディレクトリパスを解決する。
  Future<String> resolveDefaultLogDirectory() async {
    final Directory directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  /// 資源を解放する。
  Future<void> dispose() async {
    await _controller.close();
  }

  Future<void> _ensureLoaded() async {
    if (_isLoaded) {
      return;
    }
    await loadAndApply();
  }

  void _setCurrent(AppSettings next) {
    _current = next;
    _controller.add(next);
  }

  Future<void> _applySettings(
    AppSettings next, {
    AppSettings? previous,
    required String source,
  }) async {
    try {
      await _applyDebugOptions(next.debug, previous: previous?.debug);
      await _applyLogDirectory(next.logDirectory, previous: previous?.logDirectory);
    } catch (error, stackTrace) {
      _logger.e("Failed to apply settings", tag: _loggerComponent, error: error, st: stackTrace);
      throw SettingsException.apply(source, error);
    }
  }

  Future<void> _applyDebugOptions(DebugOptions next, {DebugOptions? previous}) async {
    if (previous == null || previous.globalLogLevel != next.globalLogLevel) {
      _logger.i("Updating global log level to ${next.globalLogLevel.name}", tag: _loggerComponent);
      app_logger.setGlobalLevel(next.globalLogLevel);
      RuntimeOverrides.setInt(_runtimeLogLevelKey, value: next.globalLogLevel.index);
    }

    if (previous == null || previous.developerMode != next.developerMode) {
      if (next.developerMode) {
        RuntimeOverrides.setBool(_runtimeDeveloperModeKey, value: true);
      } else {
        RuntimeOverrides.clear(_runtimeDeveloperModeKey);
      }
      _logger.d("Developer mode set to ${next.developerMode}", tag: _loggerComponent);
    }
  }

  Future<void> _applyLogDirectory(String? nextDirectory, {String? previous}) async {
    if (nextDirectory == previous) {
      return;
    }

    app_logger.updateLoggerConfig((LogConfig config) {
      final String path = nextDirectory ?? "";
      return config.copyWith(fileDirPath: path);
    });
  }

  double _normalizeTaxRate(double candidate) {
    if (candidate.isNaN || candidate.isNegative) {
      throw SettingsException.validation("taxRate", "Value must be a positive number");
    }
    if (candidate > 0.2) {
      throw SettingsException.validation("taxRate", "Value must be 20% or less");
    }
    return (candidate * 1000).roundToDouble() / 1000;
  }

  Future<String?> _sanitizeDirectory(String? path) async {
    if (path == null || path.isEmpty) {
      return null;
    }

    final String normalized = path.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final Directory directory = Directory(normalized).absolute;
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      await _writeProbeFile(directory);
    } on Object catch (error) {
      throw SettingsException.validation("logDirectory", "${error.toString()}");
    }
    return directory.path;
  }

  Future<void> _writeProbeFile(Directory directory) async {
    final int suffix = Random().nextInt(99999);
    final Uri probeUri = directory.uri.resolve(".yata_probe_$suffix");
    final File probe = File.fromUri(probeUri);
    await probe.writeAsString("probe", flush: true);
    try {
      await probe.delete();
    } on Object {
      // ignore deletion failure
    }
  }
}
