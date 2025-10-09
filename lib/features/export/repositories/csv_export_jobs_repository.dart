import "dart:async";

import "package:supabase_flutter/supabase_flutter.dart";

import "../../../core/constants/exceptions/repository/repository_exception.dart";
import "../../../core/contracts/export/export_job_contracts.dart";
import "../../../core/contracts/repositories/export/csv_export_jobs_repository_contract.dart";
import "../../../infra/supabase/supabase_client.dart";

/// `export_jobs` テーブルへログを記録するリポジトリ実装
class CsvExportJobsRepository implements CsvExportJobsRepositoryContract {
  CsvExportJobsRepository({SupabaseClient? client, Duration? timeout})
    : _client = client ?? SupabaseClientService.client,
      _timeout = timeout ?? const Duration(seconds: 5);

  final SupabaseClient _client;
  final Duration _timeout;

  static const String _tableName = "export_jobs";

  @override
  Future<void> insertJob(CsvExportJobLogEntry entry) async {
    try {
      final PostgrestFilterBuilder<dynamic> builder =
          _client.from(_tableName).insert(entry.toJson());
      if (_timeout == Duration.zero) {
        await builder;
      } else {
        await builder.timeout(_timeout);
      }
    } on TimeoutException {
      throw RepositoryException.transactionFailed(
        "insert into $_tableName timed out after ${_timeout.inSeconds}s",
      );
    } on PostgrestException catch (error) {
      throw RepositoryException.insertFailed(error.message, table: _tableName);
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw RepositoryException.insertFailed(error.toString(), table: _tableName);
    }
  }

  @override
  Future<int> countDailyExports({
    required String organizationId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final Future<dynamic> future = _client
          .from(_tableName)
          .select("id")
          .eq("org_id", organizationId)
          .gte("requested_at", from.toIso8601String())
          .lt("requested_at", to.toIso8601String())
          .order("requested_at", ascending: false)
          .limit(16);

      final dynamic response = _timeout == Duration.zero
          ? await future
          : await future.timeout(_timeout);
      if (response is List) {
        return response.length;
      }
      return 0;
    } on TimeoutException {
      throw RepositoryException.transactionFailed(
        "select from $_tableName timed out after ${_timeout.inSeconds}s",
      );
    } on PostgrestException catch (error) {
      throw RepositoryException.transactionFailed(error.message);
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw RepositoryException.transactionFailed(error.toString());
    }
  }

  @override
  Future<bool> hasActiveJob(
    String organizationId, {
    Duration lookback = const Duration(minutes: 10),
  }) async {
    try {
      final DateTime threshold = DateTime.now().toUtc().subtract(lookback);
      final Future<dynamic> future = _client
          .from(_tableName)
          .select("id")
          .eq("org_id", organizationId)
          .gte("requested_at", threshold.toIso8601String())
          .inFilter("status", <String>["queued", "running"])
          .limit(1);

      final dynamic response = _timeout == Duration.zero
          ? await future
          : await future.timeout(_timeout);

      if (response is List) {
        return response.isNotEmpty;
      }
      return false;
    } on TimeoutException {
      throw RepositoryException.transactionFailed(
        "select from $_tableName timed out after ${_timeout.inSeconds}s",
      );
    } on PostgrestException catch (error) {
      throw RepositoryException.transactionFailed(error.message);
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw RepositoryException.transactionFailed(error.toString());
    }
  }

  @override
  Future<CsvExportJobRecord?> findJobById(String jobId) async {
    try {
      final Future<dynamic> future = _client
          .from(_tableName)
          .select()
          .eq("id", jobId)
          .limit(1)
          .maybeSingle();

      final dynamic response = _timeout == Duration.zero
          ? await future
          : await future.timeout(_timeout);

      if (response == null) {
        return null;
      }

      if (response is Map<String, dynamic>) {
        return CsvExportJobRecord.fromJson(response);
      }

      if (response is Map) {
        return CsvExportJobRecord.fromJson(Map<String, dynamic>.from(response));
      }

      throw RepositoryException.validationFailed(
        "export_job",
        value: response.runtimeType.toString(),
      );
    } on TimeoutException {
      throw RepositoryException.transactionFailed(
        "select from $_tableName timed out after ${_timeout.inSeconds}s",
      );
    } on PostgrestException catch (error) {
      throw RepositoryException.transactionFailed(error.message);
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw RepositoryException.transactionFailed(error.toString());
    }
  }
}
