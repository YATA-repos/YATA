import "dart:async";
import "dart:convert";

import "package:intl/intl.dart";

import "../../../core/constants/app_constants.dart";
import "../../../core/constants/exceptions/base/validation_exception.dart";
import "../../../core/constants/exceptions/repository/repository_exception.dart";
import "../../../core/constants/exceptions/service/service_exception.dart";
import "../../../core/constants/log_enums/service.dart";
import "../../../core/contracts/cache/cache.dart" as cache_contract;
import "../../../core/contracts/export/export_contracts.dart";
import "../../../core/contracts/export/export_job_contracts.dart";
import "../../../core/contracts/logging/analytics_logger.dart";
import "../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../core/contracts/repositories/export/csv_export_jobs_repository_contract.dart";
import "../../../core/contracts/repositories/export/csv_export_repository_contract.dart";
import "csv_export_encryption_service.dart";

typedef Clock = DateTime Function();

/// CSV エクスポートユースケースを担うサービス
class CsvExportService {
  CsvExportService({
    required log_contract.LoggerContract logger,
    required CsvExportRepositoryContract repository,
    required CsvExportJobsRepositoryContract jobsRepository,
    AnalyticsLoggerContract? analyticsLogger,
    cache_contract.Cache<String, dynamic>? rateLimitCache,
    CsvExportEncryptionService? encryptionService,
    Clock? clock,
  })  : _logger = logger,
        _repository = repository,
        _jobsRepository = jobsRepository,
        _analytics = analyticsLogger,
        _rateLimitCache = rateLimitCache,
        _encryptionService = encryptionService ?? CsvExportEncryptionService(),
        _clock = clock ?? DateTime.now;

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRangeDays = 31;
  static const int _jobLogMaxAttempts = 3;
  static const Duration _jobLogRetryDelay = Duration(milliseconds: 200);
  static const int _dailyRateLimit = 5;
  static const String _rateLimitCachePrefix = "csv_export_rate_limit";
  static const Duration _jstOffset = Duration(hours: 9);
  static const Map<CsvExportDataset, _DatasetValidationRule> _datasetRules =
      <CsvExportDataset, _DatasetValidationRule>{
        CsvExportDataset.salesLineItems: _DatasetValidationRule(
          maxRangeDays: _maxRangeDays,
          requiresLocation: true,
        ),
        CsvExportDataset.purchasesLineItems: _DatasetValidationRule(
          maxRangeDays: _maxRangeDays,
          requiresLocation: true,
        ),
        CsvExportDataset.inventoryTransactions: _DatasetValidationRule(
          maxRangeDays: _maxRangeDays,
          requiresLocation: true,
        ),
        CsvExportDataset.wasteLog: _DatasetValidationRule(
          maxRangeDays: _maxRangeDays,
          requiresLocation: true,
        ),
        CsvExportDataset.menuEngineeringDaily: _DatasetValidationRule(
          maxRangeDays: _maxRangeDays,
        ),
      };
  static final DateFormat _fileNameFormatter = DateFormat("yyyyMMdd");
  static final DateFormat _dateKeyFormatter = DateFormat("yyyyMMdd");

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final CsvExportRepositoryContract _repository;
  final CsvExportJobsRepositoryContract _jobsRepository;
  final AnalyticsLoggerContract? _analytics;

  final cache_contract.Cache<String, dynamic>? _rateLimitCache;
  final CsvExportEncryptionService _encryptionService;

  final Clock _clock;

  final Set<String> _activeOrganizations = <String>{};

  /// 売上明細CSVをエクスポート
  Future<CsvExportResult> exportSalesLineItems({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? organizationId,
    String? locationId,
    bool includeHeaders = true,
    CsvExportFilters filters = const <String, dynamic>{},
    String? requestedBy,
    Duration? timeout,
  }) {
    final CsvExportRequest request = CsvExportRequest(
      dataset: CsvExportDataset.salesLineItems,
      dateFrom: dateFrom,
      dateTo: dateTo,
      organizationId: organizationId,
      locationId: locationId,
      includeHeaders: includeHeaders,
      filters: filters,
      requestedBy: requestedBy,
      timeout: timeout,
    );
    return export(request);
  }

  /// 仕入明細CSVをエクスポート
  Future<CsvExportResult> exportPurchasesLineItems({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? organizationId,
    String? locationId,
    bool includeHeaders = true,
    CsvExportFilters filters = const <String, dynamic>{},
    String? requestedBy,
    Duration? timeout,
  }) {
    final CsvExportRequest request = CsvExportRequest(
      dataset: CsvExportDataset.purchasesLineItems,
      dateFrom: dateFrom,
      dateTo: dateTo,
      organizationId: organizationId,
      locationId: locationId,
      includeHeaders: includeHeaders,
      filters: filters,
      requestedBy: requestedBy,
      timeout: timeout,
    );
    return export(request);
  }

  /// 在庫トランザクションCSVをエクスポート
  Future<CsvExportResult> exportInventoryTransactions({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? organizationId,
    String? locationId,
    bool includeHeaders = true,
    CsvExportFilters filters = const <String, dynamic>{},
    String? requestedBy,
    Duration? timeout,
  }) {
    final CsvExportRequest request = CsvExportRequest(
      dataset: CsvExportDataset.inventoryTransactions,
      dateFrom: dateFrom,
      dateTo: dateTo,
      organizationId: organizationId,
      locationId: locationId,
      includeHeaders: includeHeaders,
      filters: filters,
      requestedBy: requestedBy,
      timeout: timeout,
    );
    return export(request);
  }

  /// 廃棄ログCSVをエクスポート
  Future<CsvExportResult> exportWasteLog({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? organizationId,
    String? locationId,
    bool includeHeaders = true,
    CsvExportFilters filters = const <String, dynamic>{},
    String? requestedBy,
    Duration? timeout,
  }) {
    final CsvExportRequest request = CsvExportRequest(
      dataset: CsvExportDataset.wasteLog,
      dateFrom: dateFrom,
      dateTo: dateTo,
      organizationId: organizationId,
      locationId: locationId,
      includeHeaders: includeHeaders,
      filters: filters,
      requestedBy: requestedBy,
      timeout: timeout,
    );
    return export(request);
  }

  /// メニュー工学日次CSVをエクスポート
  Future<CsvExportResult> exportMenuEngineeringDaily({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? organizationId,
    String? locationId,
    bool includeHeaders = true,
    CsvExportFilters filters = const <String, dynamic>{},
    String? requestedBy,
    Duration? timeout,
  }) {
    final CsvExportRequest request = CsvExportRequest(
      dataset: CsvExportDataset.menuEngineeringDaily,
      dateFrom: dateFrom,
      dateTo: dateTo,
      organizationId: organizationId,
      locationId: locationId,
      includeHeaders: includeHeaders,
      filters: filters,
      requestedBy: requestedBy,
      timeout: timeout,
    );
    return export(request);
  }

  /// 汎用CSVエクスポート
  Future<CsvExportResult> export(CsvExportRequest request) => _executeExport(request, operation: _ExportOperation.fresh);

  /// 既存エクスポートジョブの再ダウンロード
  Future<CsvExportResult> redownload(String exportJobId) async {
    final String trimmedId = exportJobId.trim();
    if (trimmedId.isEmpty) {
      throw ValidationException(<String>["export_job_id must not be empty"]);
    }

    final CsvExportJobRecord? job = await _jobsRepository.findJobById(trimmedId);
    if (job == null) {
      throw ServiceException.exportJobNotFound(trimmedId);
    }

    if (job.status != CsvExportJobStatus.completed) {
      throw ServiceException.operationFailed(
        "csv_export_redownload",
        "job $trimmedId is not completed (status=${job.status.value})",
      );
    }

    final DateTime now = _clock();
    if (!job.isWithinRetention(now)) {
      throw ServiceException.redownloadExpired(trimmedId, job.expiresAt);
    }

    final CsvExportRequest request = _requestFromExportJob(job);
    return _executeExport(
      request,
      operation: _ExportOperation.redownload,
      redownloadOf: trimmedId,
      countTowardsLimit: false,
    );
  }

  Future<CsvExportResult> _executeExport(
    CsvExportRequest request, {
    required _ExportOperation operation,
    String? redownloadOf,
    bool countTowardsLimit = true,
  }) async {
    _validateRequest(request);
    final CsvExportRequest effectiveRequest = request.timeout == null
        ? request.copyWith(timeout: _defaultTimeout)
        : request;

    final String organizationId = effectiveRequest.organizationId!.trim();
    final _OrgExportGuard guard = await _acquireOrganizationGuard(organizationId);

    _RateLimitTicket? ticket;
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      ticket = await _enforceRateLimit(
        organizationId,
        countTowardsLimit: countTowardsLimit,
      );

      final String startEvent =
          operation == _ExportOperation.fresh ? "csv_export_started" : "csv_export_redownload_started";
      _trackAnalyticsEvent(
        startEvent,
        effectiveRequest,
        extra: <String, Object?>{
          "operation": operation.name,
          "count_towards_limit": countTowardsLimit,
          if (redownloadOf != null) "redownload_of": redownloadOf,
        },
      );

      log.i(
        operation == _ExportOperation.fresh
            ? "CSV export started"
            : "CSV export redownload started",
        tag: "CsvExportService",
        fields: <String, Object?>{
          "dataset": effectiveRequest.dataset.id,
          "date_from": effectiveRequest.dateFrom.toIso8601String(),
          "date_to": effectiveRequest.dateTo.toIso8601String(),
          "location_id": effectiveRequest.locationId,
          "org_id": effectiveRequest.organizationId,
          if (redownloadOf != null) "redownload_of": redownloadOf,
        },
      );

      final CsvExportRawResult raw = await _repository.export(effectiveRequest);
      stopwatch.stop();

      final CsvExportResult result = await _buildResult(
        effectiveRequest,
        raw,
        operation: operation,
        redownloadOf: redownloadOf,
      );

      await _recordExportJob(
        request: effectiveRequest,
        status: CsvExportJobStatus.completed,
        duration: stopwatch.elapsed,
        rowCount: result.rowCount,
        metadata: result.metadata,
      );

      final String completeEvent = operation == _ExportOperation.fresh
          ? "csv_export_completed"
          : "csv_export_redownload_completed";
      _trackAnalyticsEvent(
        completeEvent,
        effectiveRequest,
        duration: stopwatch.elapsed,
        rowCount: result.rowCount,
        extra: <String, Object?>{
          "operation": operation.name,
          "encrypted": result.isEncrypted,
          if (result.encryption?.password != null)
            "encryption_password_length": result.encryption!.password!.length,
          if (redownloadOf != null) "redownload_of": redownloadOf,
        },
      );

      log.i(
        operation == _ExportOperation.fresh
            ? "CSV export completed"
            : "CSV export redownload completed",
        tag: "CsvExportService",
        fields: <String, Object?>{
          "dataset": result.dataset.id,
          "file_name": result.fileName,
          "bytes": result.bytes.length,
          "row_count": result.rowCount,
          "encrypted": result.isEncrypted,
          if (result.exportJobId != null) "export_job_id": result.exportJobId,
          if (redownloadOf != null) "redownload_of": redownloadOf,
        },
      );

      return result;
    } on RepositoryException catch (error, stackTrace) {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }
      await _recordExportJob(
        request: effectiveRequest,
        status: CsvExportJobStatus.failed,
        duration: stopwatch.elapsed,
        error: error,
      );
      final String failedEvent = operation == _ExportOperation.fresh
          ? "csv_export_failed"
          : "csv_export_redownload_failed";
      _trackAnalyticsEvent(
        failedEvent,
        effectiveRequest,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
        extra: <String, Object?>{
          "operation": operation.name,
          if (redownloadOf != null) "redownload_of": redownloadOf,
        },
      );
      log.e(
        operation == _ExportOperation.fresh
            ? "CSV export failed at repository"
            : "CSV export redownload failed at repository",
        tag: "CsvExportService",
        error: error,
        st: stackTrace,
        fields: <String, Object?>{
          "dataset": request.dataset.id,
          "operation": operation.name,
          if (redownloadOf != null) "redownload_of": redownloadOf,
        },
      );
      throw ServiceException.operationFailed("csv_export", error.toString());
    } on ServiceException catch (error, stackTrace) {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }

      final Map<String, Object?> baseFields = <String, Object?>{
        "dataset": request.dataset.id,
        "operation": operation.name,
        if (redownloadOf != null) "redownload_of": redownloadOf,
        if (error.params.containsKey("organizationId"))
          "org_id": error.params["organizationId"],
        if (error.params.containsKey("dailyLimit"))
          "daily_limit": error.params["dailyLimit"],
        if (error.params.containsKey("resetAt"))
          "reset_at": error.params["resetAt"],
        if (error.params.containsKey("exportJobId"))
          "export_job_id": error.params["exportJobId"],
      };

      switch (error.error) {
        case ServiceError.exportRateLimitExceeded:
          final Map<String, Object?> logFields = <String, Object?>{
            ...baseFields,
            "reason": "rate_limit",
            "error": error.toString(),
          };
          log.w(
            "CSV export blocked by rate limit",
            tag: "CsvExportService",
            fields: logFields,
          );
          _trackAnalyticsEvent(
            operation == _ExportOperation.fresh
                ? "csv_export_rate_limit_blocked"
                : "csv_export_redownload_rate_limit_blocked",
            effectiveRequest,
            extra: <String, Object?>{
              ...baseFields,
              "reason": "rate_limit",
            },
            error: error,
            stackTrace: stackTrace,
          );
          break;
        case ServiceError.concurrentExportInProgress:
          final Map<String, Object?> logFields = <String, Object?>{
            ...baseFields,
            "reason": "concurrency",
            "error": error.toString(),
          };
          log.w(
            "CSV export blocked by concurrent job",
            tag: "CsvExportService",
            fields: logFields,
          );
          _trackAnalyticsEvent(
            operation == _ExportOperation.fresh
                ? "csv_export_concurrency_blocked"
                : "csv_export_redownload_concurrency_blocked",
            effectiveRequest,
            extra: <String, Object?>{
              ...baseFields,
              "reason": "concurrency",
            },
            error: error,
            stackTrace: stackTrace,
          );
          break;
        case ServiceError.exportRedownloadExpired:
        case ServiceError.exportJobNotFound:
          final Map<String, Object?> logFields = <String, Object?>{
            ...baseFields,
            "reason": "redownload_unavailable",
            "error": error.toString(),
          };
          log.w(
            "CSV export redownload failed",
            tag: "CsvExportService",
            fields: logFields,
          );
          _trackAnalyticsEvent(
            "csv_export_redownload_failed",
            effectiveRequest,
            error: error,
            stackTrace: stackTrace,
            extra: <String, Object?>{
              ...baseFields,
              "reason": "redownload_unavailable",
            },
          );
          break;
        default:
          final Map<String, Object?> logFields = <String, Object?>{
            ...baseFields,
            "reason": "service_exception",
            "error": error.toString(),
          };
          log.w(
            "CSV export service exception",
            tag: "CsvExportService",
            fields: logFields,
          );
          _trackAnalyticsEvent(
            "csv_export_failed",
            effectiveRequest,
            error: error,
            stackTrace: stackTrace,
            extra: <String, Object?>{
              ...baseFields,
              "reason": "service_exception",
            },
          );
          break;
      }

      rethrow;
    } on Object catch (error, stackTrace) {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }
      await _recordExportJob(
        request: effectiveRequest,
        status: CsvExportJobStatus.failed,
        duration: stopwatch.elapsed,
        error: error,
      );
      final String failedEvent = operation == _ExportOperation.fresh
          ? "csv_export_failed"
          : "csv_export_redownload_failed";
      _trackAnalyticsEvent(
        failedEvent,
        effectiveRequest,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
        extra: <String, Object?>{
          "operation": operation.name,
          if (redownloadOf != null) "redownload_of": redownloadOf,
        },
      );
      log.e(
        operation == _ExportOperation.fresh
            ? "CSV export unexpected failure"
            : "CSV export redownload unexpected failure",
        tag: "CsvExportService",
        error: error,
        st: stackTrace,
        fields: <String, Object?>{
          "dataset": request.dataset.id,
          "operation": operation.name,
          if (redownloadOf != null) "redownload_of": redownloadOf,
        },
      );
      throw ServiceException.operationFailed("csv_export", error.toString());
    } finally {
      if (ticket != null) {
        await _commitRateLimit(ticket);
      }
      guard.release();
    }
  }

  Future<_OrgExportGuard> _acquireOrganizationGuard(String organizationId) async {
    if (_activeOrganizations.contains(organizationId)) {
      throw ServiceException.concurrentExportInProgress(organizationId);
    }

    try {
      final bool hasRemoteActive = await _jobsRepository.hasActiveJob(organizationId);
      if (hasRemoteActive) {
        throw ServiceException.concurrentExportInProgress(organizationId);
      }
    } on RepositoryException catch (error, stackTrace) {
      log.w(
        "Failed to check active export jobs",
        tag: "CsvExportService",
        fields: <String, Object?>{
          "org_id": organizationId,
          "error": error.toString(),
          "stack_trace": stackTrace.toString(),
        },
      );
    }

    _activeOrganizations.add(organizationId);
    return _OrgExportGuard(() => _activeOrganizations.remove(organizationId));
  }

  Future<_RateLimitTicket> _enforceRateLimit(
    String organizationId, {
    required bool countTowardsLimit,
  }) async {
    final DateTime nowUtc = _clock().toUtc();
    final DateTime nowJst = nowUtc.add(_jstOffset);
    final DateTime startOfDayJst = DateTime(nowJst.year, nowJst.month, nowJst.day);
    final DateTime startUtc = startOfDayJst.subtract(_jstOffset);
    final DateTime endUtc = startUtc.add(const Duration(days: 1));
    final _RateLimitWindow window = _RateLimitWindow(
      dateKey: _dateKeyFormatter.format(startOfDayJst),
      startUtc: startUtc,
      endUtc: endUtc,
    );
    final String cacheKey = "$_rateLimitCachePrefix:$organizationId:${window.dateKey}";

    int? current = await _readRateLimitCache(cacheKey);
    if (current == null) {
      current = await _jobsRepository.countDailyExports(
        organizationId: organizationId,
        from: window.startUtc,
        to: window.endUtc,
      );
      await _writeRateLimitCache(cacheKey, current, window, nowUtc);
    }

    if (countTowardsLimit && current >= _dailyRateLimit) {
      throw ServiceException.rateLimitExceeded(
        organizationId: organizationId,
        dailyLimit: _dailyRateLimit,
        resetAt: window.endUtc,
      );
    }

    return _RateLimitTicket(
      organizationId: organizationId,
      cacheKey: cacheKey,
      count: current,
      window: window,
      countTowardsLimit: countTowardsLimit,
    );
  }

  Future<void> _commitRateLimit(_RateLimitTicket ticket) async {
    if (!ticket.countTowardsLimit) {
      return;
    }

    final cache_contract.Cache<String, dynamic>? cache = _rateLimitCache;
    if (cache == null) {
      return;
    }

    final DateTime nowUtc = _clock().toUtc();
    final Duration ttl = ticket.window.remaining(nowUtc);
    if (ttl <= Duration.zero) {
      await cache.remove(ticket.cacheKey);
      return;
    }

    await cache.set(ticket.cacheKey, ticket.nextCount, ttl);
  }

  Future<int?> _readRateLimitCache(String cacheKey) async {
    final cache_contract.Cache<String, dynamic>? cache = _rateLimitCache;
    if (cache == null) {
      return null;
    }

    try {
      final Object? cached = await cache.get(cacheKey);
      if (cached is int) {
        return cached;
      }
      if (cached is String) {
        return int.tryParse(cached);
      }
      if (cached is Map<String, dynamic>) {
        final Object? value = cached["count"];
        if (value is int) {
          return value;
        }
        if (value is String) {
          return int.tryParse(value);
        }
      }
    } on Object catch (error, stackTrace) {
      log.w(
        "Failed to read rate limit cache",
        tag: "CsvExportService",
        fields: <String, Object?>{
          "cache_key": cacheKey,
          "error": error.toString(),
          "stack_trace": stackTrace.toString(),
        },
      );
    }

    return null;
  }

  Future<void> _writeRateLimitCache(
    String cacheKey,
    int value,
    _RateLimitWindow window,
    DateTime nowUtc,
  ) async {
    final cache_contract.Cache<String, dynamic>? cache = _rateLimitCache;
    if (cache == null) {
      return;
    }

    final Duration ttl = window.remaining(nowUtc);
    if (ttl <= Duration.zero) {
      await cache.remove(cacheKey);
      return;
    }

    try {
      await cache.set(cacheKey, value, ttl);
    } on Object catch (error, stackTrace) {
      log.w(
        "Failed to write rate limit cache",
        tag: "CsvExportService",
        fields: <String, Object?>{
          "cache_key": cacheKey,
          "error": error.toString(),
          "stack_trace": stackTrace.toString(),
        },
      );
    }
  }

  void _validateRequest(CsvExportRequest request) {
    final List<String> errors = <String>[];
    if (!request.isChronological) {
      errors.add("date_from must be before or equal to date_to");
    }
    if (request.organizationId == null || request.organizationId!.trim().isEmpty) {
      errors.add("organization_id is required for export");
    }
    final _DatasetValidationRule? rule = _datasetRules[request.dataset];
    if (rule == null) {
      errors.add("dataset ${request.dataset.id} is not supported yet");
    } else {
      if (request.inclusiveDaySpan > rule.maxRangeDays) {
        errors.add("date range must be within ${rule.maxRangeDays} days");
      }
      if (rule.requiresLocation && (request.locationId == null || request.locationId!.isEmpty)) {
        errors.add("location_id is required for export");
      }
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors);
    }
  }

  Future<CsvExportResult> _buildResult(
    CsvExportRequest request,
    CsvExportRawResult raw, {
    required _ExportOperation operation,
    String? redownloadOf,
  }) async {
    final DateTime generatedAt = _clock();
    final String baseFileName = raw.fileName ?? _buildDefaultFileName(request);
    final String baseContentType = raw.contentType ?? "text/csv";
    final List<int> baseBytes = _encodeWithBom(raw.csvContent);

    final Map<String, dynamic> metadata = raw.metadata != null
        ? Map<String, dynamic>.from(raw.metadata!)
        : <String, dynamic>{};

    metadata["dataset_id"] ??= request.dataset.id;
    metadata["operation"] ??= operation.name;
    metadata["generated_at"] ??= generatedAt.toIso8601String();
    metadata["generated_by_app_version"] ??= AppConstants.appVersion;
    if (redownloadOf != null) {
      metadata["redownload_of"] = redownloadOf;
    }

    final String? exportJobId = _stringFromObject(metadata["export_job_id"]);
    final String? sourceViewVersion = _stringFromObject(metadata["source_view_version"]);

    final CsvExportEncryptionResult? encryptionResult = await _encryptionService.maybeEncrypt(
      fileName: baseFileName,
      csvBytes: baseBytes,
      metadata: metadata,
    );

    if (encryptionResult != null) {
      metadata
        ..["encryption_required"] = true
        ..["encryption_reasons"] = encryptionResult.info.reasons
        ..["encrypted_file_name"] = encryptionResult.fileName;
    } else {
      metadata["encryption_required"] =
          _boolFromObject(metadata["encryption_required"]) ?? false;
    }

    final CsvExportEncryptionInfo? encryptionInfo = encryptionResult?.info;
    final List<int> bytes = encryptionResult?.bytes ?? baseBytes;
    final String fileName = encryptionResult?.fileName ?? baseFileName;
    final String contentType = encryptionResult?.contentType ?? baseContentType;

    final Map<String, dynamic>? finalMetadata = metadata.isEmpty ? null : metadata;

    return CsvExportResult(
      dataset: request.dataset,
      fileName: fileName,
      contentType: contentType,
      bytes: bytes,
      generatedAt: generatedAt,
      dateFrom: request.dateFrom,
      dateTo: request.dateTo,
      rowCount: raw.rowCount,
      metadata: finalMetadata,
      encryption: encryptionInfo,
      exportJobId: exportJobId,
      sourceViewVersion: sourceViewVersion,
      generatedByAppVersion: AppConstants.appVersion,
    );
  }

  CsvExportRequest _requestFromExportJob(CsvExportJobRecord job) {
    final String? organizationId = job.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      throw ServiceException.operationFailed(
        "csv_export_redownload",
        "export job ${job.id} is missing organization id",
      );
    }

    final Map<String, dynamic>? metadata = job.metadata;
    final CsvExportFilters filters = _filtersFromMetadata(metadata);
    final bool includeHeaders =
        _boolFromObject(_metadataValue(metadata, "include_headers")) ?? true;
    final String timeZone =
        _stringFromObject(_metadataValue(metadata, "time_zone")) ?? "Asia/Tokyo";

    return CsvExportRequest(
      dataset: job.dataset,
      dateFrom: job.periodFrom,
      dateTo: job.periodTo,
      organizationId: organizationId,
      locationId: job.locationId,
      includeHeaders: includeHeaders,
      filters: filters,
      timeZone: timeZone,
      requestedBy: job.requestedBy,
    );
  }

  CsvExportFilters _filtersFromMetadata(Map<String, dynamic>? metadata) {
    final Object? raw = _metadataValue(metadata, "filters");
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return raw.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
    return const <String, dynamic>{};
  }

  Object? _metadataValue(Map<String, dynamic>? metadata, String key) {
    if (metadata == null) {
      return null;
    }
    if (metadata.containsKey(key)) {
      return metadata[key];
    }

    for (final String nestedKey in <String>["request", "params", "request_params", "payload"]) {
      final Object? nested = metadata[nestedKey];
      if (nested is Map<String, dynamic>) {
        if (nested.containsKey(key)) {
          return nested[key];
        }
      } else if (nested is Map) {
        final Map<String, dynamic> converted = nested.map(
          (dynamic nestedMapKey, dynamic value) => MapEntry(nestedMapKey.toString(), value),
        );
        if (converted.containsKey(key)) {
          return converted[key];
        }
      }
    }

    return null;
  }

  bool? _boolFromObject(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == "true" || normalized == "1") {
        return true;
      }
      if (normalized == "false" || normalized == "0") {
        return false;
      }
    }
    return null;
  }

  String? _stringFromObject(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    final String stringified = value.toString();
    return stringified.isEmpty ? null : stringified;
  }

  String _buildDefaultFileName(CsvExportRequest request) {
    final String prefix = request.dataset.filePrefix;
    final String from = _fileNameFormatter.format(request.dateFrom);
    final String to = _fileNameFormatter.format(request.dateTo);
    return "${prefix}_${from}_$to.csv";
  }

  List<int> _encodeWithBom(String csv) {
    final List<int> encoded = utf8.encode(csv);
    if (encoded.length >= 3 && encoded[0] == 0xEF && encoded[1] == 0xBB && encoded[2] == 0xBF) {
      return encoded;
    }
    return <int>[0xEF, 0xBB, 0xBF, ...encoded];
  }

  Future<void> _recordExportJob({
    required CsvExportRequest request,
    required CsvExportJobStatus status,
    required Duration duration,
    int? rowCount,
    Object? error,
    Map<String, dynamic>? metadata,
  }) async {
    final Object? exportJobId = metadata != null ? metadata["export_job_id"] : null;
    if (exportJobId != null) {
      // Supabase RPC 側で `export_jobs` ログが作成済みの場合は二重登録を避ける
      return;
    }

    final CsvExportJobLogEntry entry = CsvExportJobLogEntry(
      status: status,
      dataset: request.dataset,
      periodFrom: request.dateFrom,
      periodTo: request.dateTo,
      loggedAt: _clock(),
      organizationId: request.organizationId,
      locationId: request.locationId,
      requestedBy: request.requestedBy,
      rowCount: rowCount,
      duration: duration,
      errorDetails: error?.toString(),
      metadata: metadata,
    );

    await _insertJobWithRetry(_jobsRepository, entry);
  }

  void _trackAnalyticsEvent(
    String eventName,
    CsvExportRequest request, {
    Duration? duration,
    int? rowCount,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) {
    final AnalyticsLoggerContract? analytics = _analytics;
    if (analytics == null) {
      return;
    }

    final Map<String, Object?> properties = <String, Object?>{
      "dataset_id": request.dataset.id,
      "range_days": request.inclusiveDaySpan,
    };

    final String? orgId = request.organizationId;
    if (orgId != null && orgId.isNotEmpty) {
      properties["organization_id"] = orgId;
    }

    final String? locationId = request.locationId;
    if (locationId != null && locationId.isNotEmpty) {
      properties["location_id"] = locationId;
    }

    final String? requestedBy = request.requestedBy;
    if (requestedBy != null && requestedBy.isNotEmpty) {
      properties["requested_by"] = requestedBy;
    }

    if (duration != null) {
      properties["duration_ms"] = duration.inMilliseconds;
    }

    if (rowCount != null) {
      properties["row_count"] = rowCount;
    }

    if (error != null) {
      properties["error_type"] = error.runtimeType.toString();
      properties["error_message"] = error.toString();
    }

    if (extra != null && extra.isNotEmpty) {
      properties.addAll(extra);
    }

    analytics.track(
      eventName,
      properties: properties,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _insertJobWithRetry(
    CsvExportJobsRepositoryContract jobsRepository,
    CsvExportJobLogEntry entry,
  ) async {
    for (int attempt = 1; attempt <= _jobLogMaxAttempts; attempt++) {
      try {
        await jobsRepository.insertJob(entry);
        return;
      } on RepositoryException catch (error, stackTrace) {
        log.w(
          "Failed to record export job (attempt $attempt)",
          tag: "CsvExportService",
          fields: <String, Object?>{
            "dataset": entry.dataset.id,
            "status": entry.status.value,
            "attempt": attempt,
            "max_attempts": _jobLogMaxAttempts,
            "error": error.toString(),
          },
        );
        if (attempt == _jobLogMaxAttempts) {
          log.e(
            "Giving up on export job logging",
            tag: "CsvExportService",
            error: error,
            st: stackTrace,
            fields: <String, Object?>{
              "dataset": entry.dataset.id,
              "status": entry.status.value,
            },
          );
          return;
        }
      } on Object catch (error, stackTrace) {
        log.w(
          "Unexpected error while logging export job (attempt $attempt)",
          tag: "CsvExportService",
          fields: <String, Object?>{
            "dataset": entry.dataset.id,
            "status": entry.status.value,
            "attempt": attempt,
            "max_attempts": _jobLogMaxAttempts,
            "error": error.toString(),
          },
        );
        if (attempt == _jobLogMaxAttempts) {
          log.e(
            "Giving up on export job logging",
            tag: "CsvExportService",
            error: error,
            st: stackTrace,
            fields: <String, Object?>{
              "dataset": entry.dataset.id,
              "status": entry.status.value,
            },
          );
          return;
        }
      }

      await Future<void>.delayed(_jobLogRetryDelay);
    }
  }
}

class _DatasetValidationRule {
  const _DatasetValidationRule({
    required this.maxRangeDays,
    this.requiresLocation = false,
  });

  final int maxRangeDays;
  final bool requiresLocation;
}

enum _ExportOperation { fresh, redownload }

class _OrgExportGuard {
  _OrgExportGuard(this._onRelease);

  final void Function() _onRelease;
  bool _released = false;

  void release() {
    if (_released) {
      return;
    }
    _released = true;
    _onRelease();
  }
}

class _RateLimitTicket {
  const _RateLimitTicket({
    required this.organizationId,
    required this.cacheKey,
    required this.count,
    required this.window,
    required this.countTowardsLimit,
  });

  final String organizationId;
  final String cacheKey;
  final int count;
  final _RateLimitWindow window;
  final bool countTowardsLimit;

  int get nextCount => count + 1;
}

class _RateLimitWindow {
  const _RateLimitWindow({
    required this.dateKey,
    required this.startUtc,
    required this.endUtc,
  });

  final String dateKey;
  final DateTime startUtc;
  final DateTime endUtc;

  Duration remaining(DateTime nowUtc) {
    final Duration remaining = endUtc.difference(nowUtc);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
