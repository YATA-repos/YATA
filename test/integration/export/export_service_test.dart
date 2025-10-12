import "dart:convert";
import "dart:io";

import "package:test/test.dart";

import "package:yata/core/constants/app_constants.dart";
import "package:yata/core/contracts/export/export_contracts.dart";
import "package:yata/features/export/repositories/csv_export_jobs_repository.dart";
import "package:yata/features/export/repositories/csv_export_repository.dart";
import "package:yata/features/export/services/csv_export_encryption_service.dart";
import "package:yata/features/export/services/csv_export_service.dart";
import "package:yata/infra/supabase/supabase_client.dart";

import "../../support/logging/fake_logger.dart";

void main() {
  final _IntegrationConfig config = _IntegrationConfig.load();

  if (!config.enabled) {
    test(
      "CsvExportService integration is disabled",
      () {},
      skip: config.skipReason ?? "Integration test flag is not enabled",
    );
    return;
  }

  final FakeLogger logger = FakeLogger();
  late CsvExportService service;

  setUpAll(() async {
    await SupabaseClientService.initialize();
    final bool reachable = await SupabaseClientService.testConnection();
    if (!reachable) {
      throw StateError(
        "Supabase connection test failed. Confirm that 'supabase start' is running.",
      );
    }

    service = CsvExportService(
      logger: logger,
      repository: CsvExportRepository(),
      jobsRepository: CsvExportJobsRepository(),
      encryptionService: CsvExportEncryptionService(),
    );
  });

  tearDownAll(() async {
    await logger.dispose();
    await SupabaseClientService.dispose();
  });

  test("exports ${config.dataset!.id} via Supabase fn_export_csv", () async {
    final CsvExportRequest request = CsvExportRequest(
      dataset: config.dataset!,
      dateFrom: config.dateFrom!,
      dateTo: config.dateTo!,
      organizationId: config.organizationId,
      locationId: config.locationId,
      includeHeaders: config.includeHeaders,
      filters: config.filters ?? const <String, dynamic>{},
      requestedBy: config.requestedBy,
      generatedByAppVersion: config.generatedByAppVersion,
      timeout: const Duration(seconds: 20),
    );

    final CsvExportResult result = await service.export(request);

    expect(result.dataset, equals(config.dataset));
    expect(result.bytes.length, greaterThanOrEqualTo(3));
    expect(result.metadata, isNotNull);
    expect(result.metadata!["dataset_id"], equals(config.dataset!.id));
    expect(
      result.generatedByAppVersion,
      equals(config.generatedByAppVersion ?? AppConstants.appVersion),
    );
  });
}

class _IntegrationConfig {
  const _IntegrationConfig._({
    required this.enabled,
    this.skipReason,
    this.dataset,
    this.organizationId,
    this.locationId,
    this.dateFrom,
    this.dateTo,
    this.filters,
    this.requestedBy,
    this.includeHeaders = true,
    this.generatedByAppVersion,
  });

  final bool enabled;
  final String? skipReason;
  final CsvExportDataset? dataset;
  final String? organizationId;
  final String? locationId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final Map<String, dynamic>? filters;
  final String? requestedBy;
  final bool includeHeaders;
  final String? generatedByAppVersion;

  static _IntegrationConfig load() {
    final Map<String, String> env = Platform.environment;
    final String flag = (env["INTEGRATION_TEST"] ?? "").toLowerCase();
    final bool enabled = flag == "1" || flag == "true";
    if (!enabled) {
      return _IntegrationConfig._(
        enabled: false,
        skipReason: "Set INTEGRATION_TEST=1 to enable integration tests",
      );
    }

    final String? orgId = env["CSV_EXPORT_IT_ORG_ID"];
    if (orgId == null || orgId.isEmpty) {
      return _IntegrationConfig._(
        enabled: false,
        skipReason: "CSV_EXPORT_IT_ORG_ID is required when INTEGRATION_TEST=1",
      );
    }

    final String? locationId = env["CSV_EXPORT_IT_LOCATION_ID"];
    if (locationId == null || locationId.isEmpty) {
      return _IntegrationConfig._(
        enabled: false,
        skipReason: "CSV_EXPORT_IT_LOCATION_ID is required when INTEGRATION_TEST=1",
      );
    }

    CsvExportDataset dataset;
    final String? datasetRaw = env["CSV_EXPORT_IT_DATASET"];
    try {
      dataset = _parseDataset(datasetRaw);
    } on FormatException catch (error) {
      return _IntegrationConfig._(enabled: false, skipReason: error.message);
    }

    final DateTime dateTo = _parseDate(
      env["CSV_EXPORT_IT_TO"],
      fallback: DateTime.now().toUtc(),
    );
    final DateTime dateFrom = _parseDate(
      env["CSV_EXPORT_IT_FROM"],
      fallback: dateTo,
    );

    if (dateFrom.isAfter(dateTo)) {
      return _IntegrationConfig._(
        enabled: false,
        skipReason: "CSV_EXPORT_IT_FROM must be before or equal to CSV_EXPORT_IT_TO",
      );
    }

    Map<String, dynamic>? filters;
    final String? filtersRaw = env["CSV_EXPORT_IT_FILTERS"];
    if (filtersRaw != null && filtersRaw.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(filtersRaw);
        if (decoded is Map<String, dynamic>) {
          filters = decoded;
        } else if (decoded is Map) {
          filters = decoded.map(
            (dynamic key, dynamic value) => MapEntry(key.toString(), value),
          );
        } else {
          throw const FormatException("CSV_EXPORT_IT_FILTERS must decode to a JSON object");
        }
      } on FormatException catch (error) {
        return _IntegrationConfig._(enabled: false, skipReason: error.message);
      }
    }

    final String? includeHeadersRaw = env["CSV_EXPORT_IT_INCLUDE_HEADERS"];
    final bool includeHeaders = includeHeadersRaw == null
        ? true
        : includeHeadersRaw.toLowerCase() != "false";

    final String? requestedBy = env["CSV_EXPORT_IT_REQUESTED_BY"];
    final String? appVersion = env["CSV_EXPORT_IT_APP_VERSION"];

    return _IntegrationConfig._(
      enabled: true,
      dataset: dataset,
      organizationId: orgId,
      locationId: locationId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      filters: filters,
      requestedBy: requestedBy,
      includeHeaders: includeHeaders,
      generatedByAppVersion: appVersion,
    );
  }

  static CsvExportDataset _parseDataset(String? raw) {
    if (raw == null || raw.isEmpty) {
      return CsvExportDataset.salesLineItems;
    }
    for (final CsvExportDataset dataset in CsvExportDataset.values) {
      if (dataset.id == raw || dataset.name == raw) {
        return dataset;
      }
    }
    throw FormatException("Unknown CSV dataset: $raw");
  }

  static DateTime _parseDate(String? raw, {required DateTime fallback}) {
    if (raw == null || raw.isEmpty) {
      return fallback;
    }
    return DateTime.parse(raw).toUtc();
  }
}
