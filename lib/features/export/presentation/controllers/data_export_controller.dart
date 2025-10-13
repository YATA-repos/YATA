import "dart:async";
import "dart:math" as math;

import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:package_info_plus/package_info_plus.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/constants/exceptions/base/validation_exception.dart";
import "../../../../core/constants/exceptions/repository/repository_exception.dart";
import "../../../../core/constants/exceptions/service/service_exception.dart";
import "../../../../core/constants/log_enums/service.dart";
import "../../../../core/contracts/export/export_contracts.dart";
import "../../../../core/contracts/logging/logger.dart";
import "../../../../core/contracts/repositories/export/csv_export_jobs_repository_contract.dart";
import "../../../../core/logging/levels.dart";
import "../../../auth/models/auth_state.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../services/csv_export_service.dart";
import "../utils/csv_export_file_saver.dart";

/// CSVエクスポート画面の状態。
class DataExportState {
  const DataExportState({
    required this.status,
    required this.dateRange,
    required this.dataset,
    required this.datasetOptions,
    required this.locationOptions,
    required this.includeHeaders,
    this.organizationId,
    this.selectedLocationId,
    this.quota,
    this.progressMessage,
    this.errorMessage,
    this.lastResult,
    this.savedFilePath,
    this.showOtpSheet = false,
    this.isOffline = false,
    this.packageVersion,
    this.requestedBy,
  });

  factory DataExportState.initial({
    required DateTimeRange dateRange,
    required List<CsvExportDataset> datasetOptions,
  }) => DataExportState(
        status: DataExportStatus.idle,
        dateRange: dateRange,
        dataset: datasetOptions.first,
        datasetOptions: datasetOptions,
        locationOptions: const <ExportLocationOption>[],
        includeHeaders: true,
      );

  final DataExportStatus status;
  final DateTimeRange dateRange;
  final CsvExportDataset dataset;
  final List<CsvExportDataset> datasetOptions;
  final List<ExportLocationOption> locationOptions;
  final String? organizationId;
  final String? selectedLocationId;
  final bool includeHeaders;
  final DataExportQuota? quota;
  final String? progressMessage;
  final String? errorMessage;
  final CsvExportResult? lastResult;
  final String? savedFilePath;
  final bool showOtpSheet;
  final bool isOffline;
  final String? packageVersion;
  final String? requestedBy;

  bool get requiresLocation => _requiresLocation(dataset);

  bool get canSubmit {
    if (status == DataExportStatus.exporting || status == DataExportStatus.saving) {
      return false;
    }
    if (organizationId == null || organizationId!.isEmpty) {
      return false;
    }
    if (isOffline) {
      return false;
    }
    if (requiresLocation) {
      return selectedLocationId != null && selectedLocationId!.isNotEmpty;
    }
    return true;
  }

  DataExportState copyWith({
    DataExportStatus? status,
    DateTimeRange? dateRange,
    CsvExportDataset? dataset,
    List<CsvExportDataset>? datasetOptions,
    List<ExportLocationOption>? locationOptions,
    String? organizationId,
    String? selectedLocationId,
    bool? includeHeaders,
    Object? quota = _sentinel,
    Object? progressMessage = _sentinel,
    Object? errorMessage = _sentinel,
    Object? lastResult = _sentinel,
    Object? savedFilePath = _sentinel,
    bool? showOtpSheet,
    bool? isOffline,
    String? packageVersion,
    String? requestedBy,
  }) => DataExportState(
        status: status ?? this.status,
        dateRange: dateRange ?? this.dateRange,
        dataset: dataset ?? this.dataset,
        datasetOptions: datasetOptions ?? this.datasetOptions,
        locationOptions: locationOptions ?? this.locationOptions,
        organizationId: organizationId ?? this.organizationId,
        selectedLocationId: selectedLocationId ?? this.selectedLocationId,
        includeHeaders: includeHeaders ?? this.includeHeaders,
        quota: identical(quota, _sentinel) ? this.quota : quota as DataExportQuota?,
        progressMessage:
            identical(progressMessage, _sentinel) ? this.progressMessage : progressMessage as String?,
        errorMessage:
            identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
        lastResult: identical(lastResult, _sentinel) ? this.lastResult : lastResult as CsvExportResult?,
        savedFilePath:
            identical(savedFilePath, _sentinel) ? this.savedFilePath : savedFilePath as String?,
        showOtpSheet: showOtpSheet ?? this.showOtpSheet,
        isOffline: isOffline ?? this.isOffline,
        packageVersion: packageVersion ?? this.packageVersion,
        requestedBy: requestedBy ?? this.requestedBy,
      );
}

const Object _sentinel = Object();

/// エクスポート画面の進行ステータス。
enum DataExportStatus { idle, preparing, exporting, saving, completed, error }

/// 表示用の店舗選択肢。
class ExportLocationOption {
  const ExportLocationOption({
    required this.id,
    required this.label,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String label;
  final String? description;
  final bool isActive;
}

/// レートリミット情報。
class DataExportQuota {
  const DataExportQuota({
    required this.dailyLimit,
    required this.usedCount,
    required this.resetAt,
  });

  final int dailyLimit;
  final int usedCount;
  final DateTime resetAt;

  int get remaining => math.max(0, dailyLimit - usedCount);

  DataExportQuota incremented() => DataExportQuota(
        dailyLimit: dailyLimit,
        usedCount: math.min(dailyLimit, usedCount + 1),
        resetAt: resetAt,
      );

  DataExportQuota copyWith({int? dailyLimit, int? usedCount, DateTime? resetAt}) => DataExportQuota(
        dailyLimit: dailyLimit ?? this.dailyLimit,
        usedCount: usedCount ?? this.usedCount,
        resetAt: resetAt ?? this.resetAt,
      );
}

bool _requiresLocation(CsvExportDataset dataset) => switch (dataset) {
      CsvExportDataset.menuEngineeringDaily => false,
      _ => true,
    };

/// CSVエクスポート画面のコントローラ。
class DataExportController extends StateNotifier<DataExportState> {
  DataExportController({
    required this.ref,
    required CsvExportService exportService,
    required CsvExportJobsRepositoryContract jobsRepository,
    required CsvExportFileSaver fileSaver,
    required LoggerContract logger,
    Connectivity? connectivity,
    DateTime Function()? clock,
    Future<PackageInfo> Function()? packageInfoLoader,
  })  : _exportService = exportService,
        _jobsRepository = jobsRepository,
        _fileSaver = fileSaver,
        _logger = logger,
        _connectivity = connectivity ?? Connectivity(),
        _clock = clock ?? DateTime.now,
        _loadPackageInfo = packageInfoLoader ?? PackageInfo.fromPlatform,
        super(DataExportState.initial(
          dateRange: _buildDefaultRange(clock ?? DateTime.now),
          datasetOptions: CsvExportDataset.values,
        )) {
    ref.listen<AuthState>(authStateNotifierProvider, _handleAuthChanged, fireImmediately: true);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChanged);
    _initializeConnectivity();
    unawaited(_initializePackageVersion());
  }

  final Ref ref;
  final CsvExportService _exportService;
  final CsvExportJobsRepositoryContract _jobsRepository;
  final CsvExportFileSaver _fileSaver;
  final LoggerContract _logger;
  final Connectivity _connectivity;
  final DateTime Function() _clock;
  final Future<PackageInfo> Function() _loadPackageInfo;

  static const Duration _jstOffset = Duration(hours: 9);
  static const int _dailyLimit = 5;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void updateDateRange(DateTimeRange range) {
    state = state.copyWith(dateRange: range);
  }

  void updateDataset(CsvExportDataset dataset) {
    if (state.dataset == dataset) {
      return;
    }
    final bool requiresLocation = _requiresLocation(dataset);
    final String? resolvedLocation = requiresLocation
        ? _resolveLocationSelection(state.selectedLocationId, state.locationOptions)
        : null;
    state = state.copyWith(
      dataset: dataset,
      selectedLocationId: resolvedLocation,
    );
  }

  void updateLocation(String? locationId) {
    state = state.copyWith(selectedLocationId: locationId);
  }

  void updateIncludeHeaders(bool value) {
    state = state.copyWith(includeHeaders: value);
  }

  void dismissError() {
    state = state.copyWith(errorMessage: null);
  }

  void dismissOtpSheet() {
    state = state.copyWith(showOtpSheet: false);
  }

  Future<void> refreshQuota() async {
    final String? organizationId = state.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      state = state.copyWith(quota: null);
      return;
    }

    try {
      final _RateLimitWindow window = _buildRateLimitWindow();
      final int used = await _jobsRepository.countDailyExports(
        organizationId: organizationId,
        from: window.startUtc,
        to: window.endUtc,
      );

      state = state.copyWith(
        quota: DataExportQuota(
          dailyLimit: _dailyLimit,
          usedCount: used,
          resetAt: window.endUtc,
        ),
      );
    } on RepositoryException catch (error, stackTrace) {
      _logger.log(
        Level.warn,
        "レートリミット情報の取得に失敗",
        tag: "DataExportController",
        error: error,
        st: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      _logger.log(
        Level.warn,
        "レートリミット情報の取得で不明なエラー",
        tag: "DataExportController",
        error: error,
        st: stackTrace,
      );
    }
  }

  Future<void> submitExport() async {
    if (!state.canSubmit) {
      return;
    }

    final String? organizationId = state.organizationId;
    final CsvExportDataset dataset = state.dataset;
    final DateTimeRange range = state.dateRange;
    final bool requiresLocation = state.requiresLocation;
    final String? locationId = state.selectedLocationId;

    if (organizationId == null || organizationId.isEmpty) {
      state = state.copyWith(errorMessage: "組織情報を取得できません。再ログイン後にお試しください。");
      return;
    }
    if (requiresLocation && (locationId == null || locationId.isEmpty)) {
      state = state.copyWith(errorMessage: "店舗を選択してください。");
      return;
    }

    final DateTime dateFrom = DateTime(range.start.year, range.start.month, range.start.day);
    final DateTime dateTo = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);

    final CsvExportRequest request = CsvExportRequest(
      dataset: dataset,
      dateFrom: dateFrom,
      dateTo: dateTo,
      organizationId: organizationId,
      locationId: locationId,
      includeHeaders: state.includeHeaders,
      requestedBy: state.requestedBy,
      generatedByAppVersion: state.packageVersion,
    );

    state = state.copyWith(
      status: DataExportStatus.preparing,
      progressMessage: "エクスポートの準備中…",
      errorMessage: null,
      savedFilePath: null,
      showOtpSheet: false,
    );

    try {
      state = state.copyWith(
        status: DataExportStatus.exporting,
        progressMessage: "Supabaseにリクエストしています…",
      );

      final CsvExportResult result = await _exportService.export(request);

      state = state.copyWith(
        status: DataExportStatus.saving,
        progressMessage: "ファイルを保存しています…",
        lastResult: result,
      );

      final CsvFileSaveSummary summary = await _fileSaver.save(result);

      final DataExportQuota? updatedQuota =
          state.quota != null ? state.quota!.incremented() : state.quota;

      state = state.copyWith(
        status: DataExportStatus.completed,
        progressMessage: summary.saved
            ? "エクスポートが完了しました"
            : "エクスポートが完了しました（保存はキャンセルされました）",
        savedFilePath: summary.path,
        showOtpSheet: result.encryption?.required ?? false,
        quota: updatedQuota,
      );

      if (updatedQuota == null) {
        unawaited(refreshQuota());
      }
    } on ValidationException catch (error, stackTrace) {
      _logger.log(
        Level.warn,
        "CSVエクスポートのバリデーションエラー",
        tag: "DataExportController",
        error: error,
        st: stackTrace,
      );
      state = state.copyWith(
        status: DataExportStatus.error,
        errorMessage: _translateValidationError(error.errors),
        progressMessage: null,
      );
    } on ServiceException catch (error, stackTrace) {
      _logger.log(
        Level.warn,
        "CSVエクスポートのサービスエラー",
        tag: "DataExportController",
        error: error,
        st: stackTrace,
      );
      state = state.copyWith(
        status: DataExportStatus.error,
        errorMessage: _translateServiceError(error),
        progressMessage: null,
      );

      if (error.error == ServiceError.exportRateLimitExceeded) {
        final DateTime? resetAt = error.params["resetAt"] != null
            ? DateTime.tryParse(error.params["resetAt"]!)
            : null;
        if (resetAt != null) {
          state = state.copyWith(
            quota: DataExportQuota(
              dailyLimit: _dailyLimit,
              usedCount: _dailyLimit,
              resetAt: resetAt,
            ),
          );
        }
      }
    } on RepositoryException catch (error, stackTrace) {
      _logger.e(
        "CSVエクスポートのリポジトリエラー",
        tag: "DataExportController",
        error: error,
        st: stackTrace,
      );
      state = state.copyWith(
        status: DataExportStatus.error,
        errorMessage: "エクスポート処理に失敗しました。時間をおいて再度お試しください。",
        progressMessage: null,
      );
    } on CsvFileSaveException catch (error, stackTrace) {
      _logger.log(
        Level.warn,
        "CSVファイル保存に失敗",
        tag: "DataExportController",
        error: error,
        st: stackTrace,
      );
      state = state.copyWith(
        status: DataExportStatus.error,
        errorMessage: error.message,
        progressMessage: null,
      );
    } on Object catch (error, stackTrace) {
      _logger.e(
        "CSVエクスポートで予期しないエラー",
        tag: "DataExportController",
        error: error,
        st: stackTrace,
      );
      state = state.copyWith(
        status: DataExportStatus.error,
        errorMessage: "予期しないエラーが発生しました。サポートへお問い合わせください。",
        progressMessage: null,
      );
    }
  }

  Future<void> _initializePackageVersion() async {
    try {
      final PackageInfo info = await _loadPackageInfo();
      state = state.copyWith(packageVersion: info.version);
    } on Object catch (error, stackTrace) {
      _logger.log(
        Level.warn,
        "アプリバージョンの取得に失敗",
        tag: "DataExportController",
        error: error,
        st: stackTrace,
      );
    }
  }

  Future<void> _initializeConnectivity() async {
    try {
      final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
      _handleConnectivityChanged(result);
    } on Object catch (error, stackTrace) {
      _logger.log(
        Level.warn,
        "ネットワーク状態の取得に失敗",
        tag: "DataExportController",
        error: error,
        st: stackTrace,
      );
    }
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final bool offline = results.every((ConnectivityResult result) => result == ConnectivityResult.none);
    state = state.copyWith(isOffline: offline);
  }

  void _handleAuthChanged(AuthState? _, AuthState next) {
    final _OrganizationContext context = _resolveOrganizationContext(next);
    final bool requiresLocation = state.requiresLocation;
    final String? resolvedLocation = requiresLocation
        ? _resolveLocationSelection(state.selectedLocationId, context.locations)
        : null;

    state = state.copyWith(
      organizationId: context.organizationId,
      locationOptions: context.locations,
      selectedLocationId: resolvedLocation,
      requestedBy: context.requestedBy,
    );

    unawaited(refreshQuota());
  }

  static DateTimeRange _buildDefaultRange(DateTime Function() clock) {
    final DateTime now = clock();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime start = today.subtract(const Duration(days: 6));
    final DateTimeRange range = DateTimeRange(start: start, end: today);
    return range;
  }

  static String? _resolveLocationSelection(String? current, List<ExportLocationOption> options) {
    if (options.isEmpty) {
      return null;
    }
    if (current != null && options.any((ExportLocationOption option) => option.id == current)) {
      return current;
    }
    return options.first.id;
  }

  _RateLimitWindow _buildRateLimitWindow() {
    final DateTime nowUtc = _clock().toUtc();
    final DateTime nowJst = nowUtc.add(_jstOffset);
    final DateTime startOfDayJst = DateTime(nowJst.year, nowJst.month, nowJst.day);
    final DateTime startUtc = startOfDayJst.subtract(_jstOffset);
    final DateTime endUtc = startUtc.add(const Duration(days: 1));
    return _RateLimitWindow(startUtc: startUtc, endUtc: endUtc);
  }

  String _translateValidationError(List<String> errors) {
    if (errors.isEmpty) {
      return "入力内容を確認してください。";
    }
    final Set<String> messages = errors.map((String error) {
      if (error.contains("date range")) {
        return "期間指定が長すぎます。31日以内に収めてください。";
      }
      if (error.contains("organization")) {
        return "組織IDが設定されていません。再ログインをお試しください。";
      }
      if (error.contains("location")) {
        return "店舗を選択してください。";
      }
      if (error.contains("date_from")) {
        return "開始日が終了日より後になっています。";
      }
      return error;
    }).toSet();
    return messages.join("\n");
  }

  String _translateServiceError(ServiceException error) {
    switch (error.error) {
      case ServiceError.exportRateLimitExceeded:
        final String resetLabel = error.params["resetAt"] != null
            ? _formatResetTime(error.params["resetAt"]!)
            : "翌日";
        return "エクスポートの上限回数に達しました。リセット時刻: $resetLabel";
      case ServiceError.concurrentExportInProgress:
        return "他のエクスポートが進行中です。完了を待ってから再度お試しください。";
      case ServiceError.exportJobNotFound:
        return "指定されたエクスポート履歴が見つかりませんでした。";
      case ServiceError.exportRedownloadExpired:
        return "再ダウンロード期限を過ぎています。新しくエクスポートしてください。";
      default:
        return "エクスポート処理でエラーが発生しました。時間をおいて再度お試しください。";
    }
  }

  String _formatResetTime(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final DateTime local = parsed.toLocal();
    return "${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }

  _OrganizationContext _resolveOrganizationContext(AuthState state) {
    final Map<String, dynamic>? metadata = state.user?.metadata;
    String? organizationId;
    final List<ExportLocationOption> locations = <ExportLocationOption>[];

    if (metadata != null) {
      organizationId = _stringOrNull(metadata["org_id"] ?? metadata["organization_id"]);
      final Object? rawLocations = metadata["locations"] ?? metadata["stores"];
      if (rawLocations is List) {
        for (final Object? item in rawLocations) {
          final ExportLocationOption? option = _parseLocation(item);
          if (option != null) {
            locations.add(option);
          }
        }
      }
    }

    return _OrganizationContext(
      organizationId: organizationId,
      requestedBy: state.user?.email ?? state.user?.id,
      locations: locations,
    );
  }

  ExportLocationOption? _parseLocation(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final String? id = _stringOrNull(raw["id"] ?? raw["location_id"] ?? raw["uuid"]);
      final String? name = _stringOrNull(raw["name"] ?? raw["label"] ?? raw["title"]);
      if (id == null || name == null) {
        return null;
      }
      final String? description = _stringOrNull(raw["address"] ?? raw["description"]);
      return ExportLocationOption(id: id, label: name, description: description);
    }
    if (raw is Map) {
      final Map<String, dynamic> map = raw.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
      return _parseLocation(map);
    }
    return null;
  }

  String? _stringOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    final String stringified = value.toString();
    return stringified.isEmpty ? null : stringified;
  }
}

class _OrganizationContext {
  const _OrganizationContext({
    required this.locations,
    this.organizationId,
    this.requestedBy,
  });

  final String? organizationId;
  final String? requestedBy;
  final List<ExportLocationOption> locations;
}

class _RateLimitWindow {
  const _RateLimitWindow({
    required this.startUtc,
    required this.endUtc,
  });

  final DateTime startUtc;
  final DateTime endUtc;
}

/// DataExportController のプロバイダー。
final AutoDisposeStateNotifierProvider<DataExportController, DataExportState>
    dataExportControllerProvider = StateNotifierProvider.autoDispose<DataExportController, DataExportState>(
  (AutoDisposeStateNotifierProviderRef<DataExportController, DataExportState> ref) {
    final CsvExportService exportService = ref.read(csvExportServiceProvider);
    final CsvExportJobsRepositoryContract jobsRepository = ref.read(csvExportJobsRepositoryProvider);
    final LoggerContract logger = ref.read(loggerProvider);
    final CsvExportFileSaver fileSaver = CsvExportFileSaver(logger: logger);

    return DataExportController(
      ref: ref,
      exportService: exportService,
      jobsRepository: jobsRepository,
      fileSaver: fileSaver,
      logger: logger,
    );
  },
);
