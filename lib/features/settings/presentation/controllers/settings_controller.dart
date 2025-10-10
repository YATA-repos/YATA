import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../domain/app_settings.dart";
import "../../services/settings_service.dart";
import "../../../../app/wiring/provider.dart" show loggerProvider, settingsServiceProvider;
import "../../../../core/constants/exceptions/settings/settings_exception.dart";
import "../../../../infra/logging/log_level.dart";

class SettingsState {
  const SettingsState({
    required this.settings,
    this.isLoading = false,
    this.error,
    this.logoutStatus = const AsyncData<void>(null),
    this.debugStatus = const AsyncData<void>(null),
    this.taxStatus = const AsyncData<void>(null),
    this.logDirectoryStatus = const AsyncData<void>(null),
  });

  factory SettingsState.initial(AppSettings settings) => SettingsState(settings: settings);

  final AppSettings settings;
  final bool isLoading;
  final Object? error;
  final AsyncValue<void> logoutStatus;
  final AsyncValue<void> debugStatus;
  final AsyncValue<void> taxStatus;
  final AsyncValue<void> logDirectoryStatus;

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    AsyncValue<void>? logoutStatus,
    AsyncValue<void>? debugStatus,
    AsyncValue<void>? taxStatus,
    AsyncValue<void>? logDirectoryStatus,
  }) => SettingsState(
        settings: settings ?? this.settings,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        logoutStatus: logoutStatus ?? this.logoutStatus,
        debugStatus: debugStatus ?? this.debugStatus,
        taxStatus: taxStatus ?? this.taxStatus,
        logDirectoryStatus: logDirectoryStatus ?? this.logDirectoryStatus,
      );
}

class SettingsFormState {
  const SettingsFormState({
    required this.taxRateText,
    required this.signOutAllDevices,
    this.validationMessage,
  });

  factory SettingsFormState.fromSettings(AppSettings settings) => SettingsFormState(
        taxRateText: formatTaxRate(settings.taxRate),
        signOutAllDevices: false,
      );

  final String taxRateText;
  final bool signOutAllDevices;
  final String? validationMessage;

  SettingsFormState copyWith({
    String? taxRateText,
    bool? signOutAllDevices,
    String? validationMessage,
    bool clearValidationMessage = false,
  }) => SettingsFormState(
        taxRateText: taxRateText ?? this.taxRateText,
        signOutAllDevices: signOutAllDevices ?? this.signOutAllDevices,
        validationMessage: clearValidationMessage ? null : validationMessage ?? this.validationMessage,
      );

  static String formatTaxRate(double value) {
    final double percent = value * 100;
    if (percent == percent.roundToDouble()) {
      return percent.toStringAsFixed(0);
    }
    return percent.toStringAsFixed(2);
  }
}

class SettingsFormController extends StateNotifier<SettingsFormState> {
  SettingsFormController({required AppSettings initialSettings})
    : super(SettingsFormState.fromSettings(initialSettings));

  void syncFrom(AppSettings settings) {
    state = state.copyWith(
      taxRateText: SettingsFormState.formatTaxRate(settings.taxRate),
      clearValidationMessage: true,
    );
  }

  void setTaxRateText(String value) {
    state = state.copyWith(taxRateText: value, clearValidationMessage: true);
  }

  void setSignOutAllDevices(bool value) {
    state = state.copyWith(signOutAllDevices: value);
  }

  void setValidationMessage(String? message) {
    state = state.copyWith(validationMessage: message);
  }

  void reset(AppSettings settings) {
    state = SettingsFormState.fromSettings(settings);
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController({required Ref ref, required SettingsService service})
    : _ref = ref,
      _service = service,
      super(SettingsState.initial(service.current)) {
    _subscription = _service.watch().listen(_handleServiceUpdate, onError: _handleServiceError);
    unawaited(_initialize());
  }

  final Ref _ref;
  final SettingsService _service;
  late final StreamSubscription<AppSettings> _subscription;

  SettingsFormController get _form => _ref.read(settingsFormProvider.notifier);

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppSettings settings = await _service.loadAndApply();
      _form.reset(settings);
      state = SettingsState.initial(settings);
    } catch (error, stackTrace) {
      state = state.copyWith(isLoading: false, error: error);
      _reportError("initialize", error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppSettings refreshed = await _service.reload();
      _form.reset(refreshed);
      state = state.copyWith(settings: refreshed, isLoading: false);
    } catch (error, stackTrace) {
      state = state.copyWith(isLoading: false, error: error);
      _reportError("refresh", error, stackTrace);
    }
  }

  Future<void> setDeveloperMode(bool enabled) async {
    state = state.copyWith(debugStatus: const AsyncLoading<void>());
    try {
      final DebugOptions next = state.settings.debug.copyWith(developerMode: enabled);
      final AppSettings updated = await _service.updateDebugOptions(next);
      _form.reset(updated);
      state = state.copyWith(
        settings: updated,
        debugStatus: const AsyncData<void>(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(debugStatus: AsyncError<void>(error, stackTrace));
      _reportError("setDeveloperMode", error, stackTrace);
    }
  }

  Future<void> setLogLevel(LogLevel level) async {
    state = state.copyWith(debugStatus: const AsyncLoading<void>());
    try {
      final DebugOptions next = state.settings.debug.copyWith(globalLogLevel: level);
      final AppSettings updated = await _service.updateDebugOptions(next);
      _form.reset(updated);
      state = state.copyWith(
        settings: updated,
        debugStatus: const AsyncData<void>(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(debugStatus: AsyncError<void>(error, stackTrace));
      _reportError("setLogLevel", error, stackTrace);
    }
  }

  Future<void> submitTaxRate(String input) async {
    state = state.copyWith(taxStatus: const AsyncLoading<void>());
    try {
      final double percent = _parseTaxRatePercent(input);
      final AppSettings updated = await _service.updateTaxRate(percent / 100);
      _form.reset(updated);
      state = state.copyWith(
        settings: updated,
        taxStatus: const AsyncData<void>(null),
      );
    } catch (error, stackTrace) {
      _form.setValidationMessage(_describeTaxError(error));
      state = state.copyWith(taxStatus: AsyncError<void>(error, stackTrace));
      _reportError("submitTaxRate", error, stackTrace);
    }
  }

  Future<void> applyPresetTaxRate(double percent) async {
    state = state.copyWith(taxStatus: const AsyncLoading<void>());
    try {
      final AppSettings updated = await _service.updateTaxRate(percent / 100);
      _form.reset(updated);
      state = state.copyWith(
        settings: updated,
        taxStatus: const AsyncData<void>(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(taxStatus: AsyncError<void>(error, stackTrace));
      _reportError("applyPresetTaxRate", error, stackTrace);
    }
  }

  Future<void> chooseLogDirectory(String path) async {
    state = state.copyWith(logDirectoryStatus: const AsyncLoading<void>());
    try {
      final AppSettings updated = await _service.updateLogDirectory(path);
      state = state.copyWith(
        settings: updated,
        logDirectoryStatus: const AsyncData<void>(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(logDirectoryStatus: AsyncError<void>(error, stackTrace));
      _reportError("chooseLogDirectory", error, stackTrace);
    }
  }

  Future<void> resetLogDirectory() async {
    state = state.copyWith(logDirectoryStatus: const AsyncLoading<void>());
    try {
      final AppSettings updated = await _service.resetLogDirectory();
      state = state.copyWith(
        settings: updated,
        logDirectoryStatus: const AsyncData<void>(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(logDirectoryStatus: AsyncError<void>(error, stackTrace));
      _reportError("resetLogDirectory", error, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(logoutStatus: const AsyncLoading<void>());
    try {
      final bool allDevices = _form.state.signOutAllDevices;
      await _service.signOut(allDevices: allDevices);
      final AppSettings defaults = _service.current;
      _form.reset(defaults);
      state = SettingsState.initial(defaults).copyWith(
        logoutStatus: const AsyncData<void>(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(logoutStatus: AsyncError<void>(error, stackTrace));
      _reportError("signOut", error, stackTrace);
    }
  }

  void updateSignOutAllDevices(bool value) {
    _form.setSignOutAllDevices(value);
  }

  void handleTaxFieldChanged(String value) {
    _form.setTaxRateText(value);
  }

  void _handleServiceUpdate(AppSettings settings) {
    state = state.copyWith(settings: settings, clearError: true);
    _form.syncFrom(settings);
  }

  void _handleServiceError(Object error, StackTrace stackTrace) {
    state = state.copyWith(error: error);
    _reportError("serviceStream", error, stackTrace);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  double _parseTaxRatePercent(String input) {
    final String sanitized = input.replaceAll("％", "%").replaceAll("%", "").trim();
    if (sanitized.isEmpty) {
      throw SettingsException.validation("taxRate", "入力値が空です");
    }
    final double? parsed = double.tryParse(sanitized.replaceAll(",", "."));
    if (parsed == null) {
      throw SettingsException.validation("taxRate", "数値として解釈できません");
    }
    return parsed;
  }

  String? _describeTaxError(Object error) {
    if (error is SettingsException) {
      return error.message;
    }
    return error.toString();
  }

  void _reportError(String action, Object error, StackTrace stackTrace) {
    final logger = _ref.read(loggerProvider);
    logger.e(
      "SettingsController action failed: $action",
      tag: "SettingsController",
      error: error,
      st: stackTrace,
    );
  }
}

final StateNotifierProvider<SettingsController, SettingsState> settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((Ref ref) {
      final SettingsService service = ref.read(settingsServiceProvider);
      return SettingsController(ref: ref, service: service);
    });

final StateNotifierProvider<SettingsFormController, SettingsFormState> settingsFormProvider =
    StateNotifierProvider<SettingsFormController, SettingsFormState>((Ref ref) {
      final SettingsService service = ref.read(settingsServiceProvider);
      return SettingsFormController(initialSettings: service.current);
    });

final StreamProvider<AppSettings> settingsUpdatesProvider = StreamProvider<AppSettings>((Ref ref) {
  final SettingsService service = ref.read(settingsServiceProvider);
  return service.watch();
});
