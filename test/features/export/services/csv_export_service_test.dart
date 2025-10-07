import "dart:math";

import "package:mocktail/mocktail.dart";
import "package:test/test.dart";

import "package:yata/core/constants/app_constants.dart";
import "package:yata/core/constants/exceptions/base/validation_exception.dart";
import "package:yata/core/constants/exceptions/repository/repository_exception.dart";
import "package:yata/core/constants/exceptions/service/service_exception.dart";
import "package:yata/core/constants/log_enums/service.dart";
import "package:yata/core/contracts/export/export_contracts.dart";
import "package:yata/core/contracts/export/export_job_contracts.dart";
import "package:yata/core/contracts/logging/analytics_logger.dart";
import "package:yata/core/contracts/logging/logger.dart" as log_contract;
import "package:yata/core/contracts/repositories/export/csv_export_jobs_repository_contract.dart";
import "package:yata/core/contracts/repositories/export/csv_export_repository_contract.dart";
import "package:yata/features/export/services/csv_export_encryption_service.dart";
import "package:yata/features/export/services/csv_export_service.dart";

class _MockLogger extends Mock implements log_contract.LoggerContract {}

class _MockCsvExportRepository extends Mock implements CsvExportRepositoryContract {}

class _MockCsvExportJobsRepository extends Mock implements CsvExportJobsRepositoryContract {}

class _MockAnalyticsLogger extends Mock implements AnalyticsLoggerContract {}

class _FakeAnalyticsProperties extends Fake implements Map<String, Object?> {}

void main() {
  late _MockLogger logger;
  late _MockCsvExportRepository repository;
  late _MockCsvExportJobsRepository jobsRepository;
  late _MockAnalyticsLogger analyticsLogger;
  late CsvExportService service;

  final DateTime fixedNow = DateTime(2025, 10, 6, 12);

  final CsvExportRequest fallbackRequest = CsvExportRequest(
    dataset: CsvExportDataset.salesLineItems,
    dateFrom: DateTime(2025, 10, 5),
    dateTo: DateTime(2025, 10, 5),
    organizationId: "org-1",
    locationId: "loc-1",
  );

  setUpAll(() {
    registerFallbackValue(fallbackRequest);
    registerFallbackValue(
      CsvExportJobLogEntry(
        status: CsvExportJobStatus.completed,
        dataset: CsvExportDataset.salesLineItems,
        periodFrom: DateTime(2025, 10, 5),
        periodTo: DateTime(2025, 10, 5),
        loggedAt: DateTime(2025, 10, 6),
        organizationId: "org-1",
      ),
    );
    registerFallbackValue(_FakeAnalyticsProperties());
    registerFallbackValue(const Duration());
    registerFallbackValue(DateTime(2025, 10, 5));
  });

  setUp(() {
    logger = _MockLogger();
    repository = _MockCsvExportRepository();
    jobsRepository = _MockCsvExportJobsRepository();
    analyticsLogger = _MockAnalyticsLogger();

  when(() => jobsRepository.hasActiveJob(any())).thenAnswer((_) async => false);
    when(
      () => jobsRepository.countDailyExports(
        organizationId: any(named: "organizationId"),
        from: any(named: "from"),
        to: any(named: "to"),
      ),
    ).thenAnswer((_) async => 0);
    when(() => jobsRepository.insertJob(any())).thenAnswer((_) async {});
    when(() => jobsRepository.findJobById(any())).thenAnswer((_) async => null);
    when(
      () => analyticsLogger.track(
        any(),
        properties: any(named: "properties"),
        error: any(named: "error"),
        stackTrace: any(named: "stackTrace"),
      ),
    ).thenAnswer((_) {});

    service = CsvExportService(
      logger: logger,
      repository: repository,
      jobsRepository: jobsRepository,
      analyticsLogger: analyticsLogger,
      encryptionService: CsvExportEncryptionService(random: Random(42)),
      clock: () => fixedNow,
    );
  });

  group("export", () {
    test("returns BOM-prefixed bytes with metadata and analytics", () async {
      late CsvExportRequest capturedRequest;
      when(() => repository.export(any())).thenAnswer((Invocation invocation) async {
        capturedRequest = invocation.positionalArguments.first as CsvExportRequest;
        return const CsvExportRawResult(
          csvContent: "order_id,line_id\n1,10\n",
          rowCount: 2,
          metadata: <String, dynamic>{"source_view_version": "v20251005"},
        );
      });

      final CsvExportResult result = await service.exportSalesLineItems(
        dateFrom: DateTime(2025, 10, 5),
        dateTo: DateTime(2025, 10, 5),
        organizationId: "org-1",
        locationId: "loc-1",
      );

      expect(capturedRequest.organizationId, equals("org-1"));
      expect(result.bytes.take(3), orderedEquals(<int>[0xEF, 0xBB, 0xBF]));
      expect(result.generatedAt, equals(fixedNow));
      expect(result.sourceViewVersion, equals("v20251005"));
      expect(result.generatedByAppVersion, equals(AppConstants.appVersion));
      expect(result.metadata, isNotNull);
      expect(result.metadata!["generated_by_app_version"], equals(AppConstants.appVersion));
      expect(result.metadata!["operation"], equals("fresh"));

      verify(() => jobsRepository.insertJob(any())).called(1);
      verify(
        () => analyticsLogger.track(
          "csv_export_started",
          properties: any(named: "properties"),
          error: any(named: "error"),
          stackTrace: any(named: "stackTrace"),
        ),
      ).called(1);

      final VerificationResult completedCall = verify(
        () => analyticsLogger.track(
          "csv_export_completed",
          properties: captureAny(named: "properties"),
          error: captureAny(named: "error"),
          stackTrace: captureAny(named: "stackTrace"),
        ),
      );
      completedCall.called(1);
      final List<dynamic> completedArgs = completedCall.captured;
      final Map<String, Object?> completedProps = completedArgs[0] as Map<String, Object?>;
      expect(completedProps["encrypted"], isFalse);
      expect(completedProps["operation"], equals("fresh"));
    });

    test("throws ValidationException when organizationId is missing", () async {
      await expectLater(
        () => service.export(
          CsvExportRequest(
            dataset: CsvExportDataset.salesLineItems,
            dateFrom: DateTime(2025, 10, 5),
            dateTo: DateTime(2025, 10, 5),
            locationId: "loc-1",
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test("throws ServiceException when rate limit exceeded", () async {
      when(
        () => jobsRepository.countDailyExports(
          organizationId: any(named: "organizationId"),
          from: any(named: "from"),
          to: any(named: "to"),
        ),
      ).thenAnswer((_) async => 5);

      final Future<CsvExportResult> future = service.exportSalesLineItems(
        dateFrom: DateTime(2025, 10, 5),
        dateTo: DateTime(2025, 10, 5),
        organizationId: "org-1",
        locationId: "loc-1",
      );

      await expectLater(
        future,
        throwsA(
          isA<ServiceException>().having(
            (ServiceException e) => e.error,
            "error",
            ServiceError.exportRateLimitExceeded,
          ),
        ),
      );

      verifyNever(() => repository.export(any()));
      verify(
        () => analyticsLogger.track(
          "csv_export_rate_limit_blocked",
          properties: any(named: "properties"),
          error: any(named: "error"),
          stackTrace: any(named: "stackTrace"),
        ),
      ).called(1);
    });

    test("throws ServiceException when concurrent export detected", () async {
      when(() => jobsRepository.hasActiveJob(any())).thenAnswer((_) async => true);

      await expectLater(
        service.exportSalesLineItems(
          dateFrom: DateTime(2025, 10, 5),
          dateTo: DateTime(2025, 10, 5),
          organizationId: "org-1",
          locationId: "loc-1",
        ),
        throwsA(
          isA<ServiceException>().having(
            (ServiceException e) => e.error,
            "error",
            ServiceError.concurrentExportInProgress,
          ),
        ),
      );

      verifyNever(() => repository.export(any()));
      verifyNever(() => jobsRepository.insertJob(any()));
    });

    test("wraps repository errors into ServiceException", () async {
      when(() => repository.export(any())).thenThrow(
        RepositoryException.transactionFailed("db timeout"),
      );

      await expectLater(
        service.exportSalesLineItems(
          dateFrom: DateTime(2025, 10, 5),
          dateTo: DateTime(2025, 10, 5),
          organizationId: "org-1",
          locationId: "loc-1",
        ),
        throwsA(isA<ServiceException>()),
      );

      final VerificationResult failedCall = verify(
        () => analyticsLogger.track(
          "csv_export_failed",
          properties: captureAny(named: "properties"),
          error: captureAny(named: "error"),
          stackTrace: captureAny(named: "stackTrace"),
        ),
      );
      failedCall.called(1);
      final List<dynamic> captured = failedCall.captured;
      final Map<String, Object?> properties = captured[0] as Map<String, Object?>;
      expect(properties["dataset_id"], equals("sales_line_items"));
      expect(captured[1], isA<RepositoryException>());
    });

    test("retries job logging up to three times", () async {
      when(() => repository.export(any())).thenAnswer((_) async {
        return const CsvExportRawResult(csvContent: "id\n1\n", rowCount: 1);
      });

      int attempts = 0;
      when(() => jobsRepository.insertJob(any())).thenAnswer((Invocation invocation) async {
        attempts += 1;
        if (attempts < 3) {
          throw RepositoryException.insertFailed("network");
        }
      });

      await service.exportSalesLineItems(
        dateFrom: DateTime(2025, 10, 5),
        dateTo: DateTime(2025, 10, 5),
        organizationId: "org-1",
        locationId: "loc-1",
      );

      expect(attempts, equals(3));
    });

    test("encrypts result when metadata requires it", () async {
      when(() => repository.export(any())).thenAnswer((_) async {
        return const CsvExportRawResult(
          csvContent: "order_id,line_id\n1,10\n",
          rowCount: 1,
          metadata: <String, dynamic>{
            "encryption_required": true,
            "encryption_reasons": <Map<String, dynamic>>[
              <String, dynamic>{"rule": "pii_email"},
            ],
          },
        );
      });

      final CsvExportResult result = await service.exportSalesLineItems(
        dateFrom: DateTime(2025, 10, 5),
        dateTo: DateTime(2025, 10, 5),
        organizationId: "org-1",
        locationId: "loc-1",
      );

      expect(result.isEncrypted, isTrue);
      expect(result.fileName.endsWith(".csv.enc.zip"), isTrue);
      expect(result.contentType, equals("application/zip"));
      expect(result.encryption, isNotNull);
      expect(result.encryption!.password, hasLength(16));
      expect(result.metadata!["encryption_required"], isTrue);
      expect(result.metadata!["encrypted_file_name"], equals(result.fileName));

      final VerificationResult completedCall = verify(
        () => analyticsLogger.track(
          "csv_export_completed",
          properties: captureAny(named: "properties"),
          error: captureAny(named: "error"),
          stackTrace: captureAny(named: "stackTrace"),
        ),
      );
      completedCall.called(1);
      final Map<String, Object?> completedProps =
          completedCall.captured.first as Map<String, Object?>;
      expect(completedProps["encrypted"], isTrue);
    });

    test("skips export_jobs insert when RPC metadata includes export_job_id", () async {
      when(() => repository.export(any())).thenAnswer((_) async {
        return const CsvExportRawResult(
          csvContent: "id\n1\n",
          metadata: <String, dynamic>{"export_job_id": "job-123"},
        );
      });

      await service.exportSalesLineItems(
        dateFrom: DateTime(2025, 10, 5),
        dateTo: DateTime(2025, 10, 5),
        organizationId: "org-1",
        locationId: "loc-1",
      );

      verifyNever(() => jobsRepository.insertJob(any()));
    });
  });

  group("redownload", () {
    test("replays export using existing job metadata", () async {
      final CsvExportJobRecord record = CsvExportJobRecord(
        id: "job-1",
        dataset: CsvExportDataset.salesLineItems,
        status: CsvExportJobStatus.completed,
        requestedAt: fixedNow.subtract(const Duration(days: 2)),
        periodFrom: DateTime(2025, 10, 1),
        periodTo: DateTime(2025, 10, 3),
        organizationId: "org-1",
        locationId: "loc-1",
        requestedBy: "user-1",
        rowCount: 100,
        durationMs: 1200,
        metadata: <String, dynamic>{
          "filters": <String, dynamic>{"channel": "delivery"},
          "include_headers": true,
          "time_zone": "Asia/Tokyo",
        },
      );
      when(() => jobsRepository.findJobById("job-1")).thenAnswer((_) async => record);

      late CsvExportRequest capturedRequest;
      when(() => repository.export(any())).thenAnswer((Invocation invocation) async {
        capturedRequest = invocation.positionalArguments.first as CsvExportRequest;
        return const CsvExportRawResult(csvContent: "order_id\n1\n", rowCount: 1);
      });

      final CsvExportResult result = await service.redownload("job-1");

      expect(capturedRequest.dataset, equals(record.dataset));
      expect(capturedRequest.organizationId, equals("org-1"));
      expect(capturedRequest.filters, equals(<String, dynamic>{"channel": "delivery"}));
      expect(result.metadata, isNotNull);
      expect(result.metadata!["redownload_of"], equals("job-1"));

      verify(
        () => analyticsLogger.track(
          "csv_export_redownload_started",
          properties: any(named: "properties"),
          error: any(named: "error"),
          stackTrace: any(named: "stackTrace"),
        ),
      ).called(1);
      verify(
        () => analyticsLogger.track(
          "csv_export_redownload_completed",
          properties: any(named: "properties"),
          error: any(named: "error"),
          stackTrace: any(named: "stackTrace"),
        ),
      ).called(1);
    });

    test("throws when export job is not found", () async {
  when(() => jobsRepository.findJobById("missing")).thenAnswer((_) async => null);

      await expectLater(
        service.redownload("missing"),
        throwsA(
          isA<ServiceException>().having(
            (ServiceException e) => e.error,
            "error",
            ServiceError.exportJobNotFound,
          ),
        ),
      );
    });

    test("throws when export job is expired", () async {
      final CsvExportJobRecord expiredRecord = CsvExportJobRecord(
        id: "job-2",
        dataset: CsvExportDataset.salesLineItems,
        status: CsvExportJobStatus.completed,
        requestedAt: fixedNow.subtract(const Duration(days: 8)),
        periodFrom: DateTime(2025, 9, 20),
        periodTo: DateTime(2025, 9, 21),
        organizationId: "org-1",
        metadata: const <String, dynamic>{},
      );
      when(() => jobsRepository.findJobById("job-2")).thenAnswer((_) async => expiredRecord);

      await expectLater(
        service.redownload("job-2"),
        throwsA(
          isA<ServiceException>().having(
            (ServiceException e) => e.error,
            "error",
            ServiceError.exportRedownloadExpired,
          ),
        ),
      );
    });

    test("throws when export job is not completed", () async {
      final CsvExportJobRecord runningRecord = CsvExportJobRecord(
        id: "job-3",
        dataset: CsvExportDataset.salesLineItems,
        status: CsvExportJobStatus.running,
        requestedAt: fixedNow.subtract(const Duration(days: 1)),
        periodFrom: DateTime(2025, 10, 4),
        periodTo: DateTime(2025, 10, 5),
        organizationId: "org-1",
      );
      when(() => jobsRepository.findJobById("job-3")).thenAnswer((_) async => runningRecord);

      await expectLater(
        service.redownload("job-3"),
        throwsA(isA<ServiceException>()),
      );
    });
  });
}
