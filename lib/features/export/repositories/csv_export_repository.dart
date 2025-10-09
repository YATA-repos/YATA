import "dart:async";
import "dart:convert";

import "package:supabase_flutter/supabase_flutter.dart";

import "../../../core/constants/exceptions/repository/repository_exception.dart";
import "../../../core/contracts/export/export_contracts.dart";
import "../../../core/contracts/repositories/export/csv_export_repository_contract.dart";
import "../../../infra/supabase/supabase_client.dart";

/// Supabase RPC を利用した CSV エクスポートリポジトリ
class CsvExportRepository implements CsvExportRepositoryContract {
  CsvExportRepository({SupabaseClient? client}) : _client = client ?? SupabaseClientService.client;

  final SupabaseClient _client;

  static const String _rpcName = "fn_export_csv";

  @override
  Future<CsvExportRawResult> export(CsvExportRequest request) async {
    try {
      final Map<String, dynamic> rpcParams = <String, dynamic>{
        "dataset_id": request.dataset.id,
        "params": request.toRpcPayload(),
      };

      final PostgrestFilterBuilder<dynamic> builder = _client.rpc(_rpcName, params: rpcParams);
      final Future<dynamic> future = builder.maybeSingle();
      final dynamic response = request.timeout != null
          ? await future.timeout(request.timeout!)
          : await future;

      return _normalizeResponse(response);
    } on TimeoutException {
      throw RepositoryException.transactionFailed(
        "RPC $_rpcName timeout after ${request.timeout?.inSeconds}s",
      );
    } on PostgrestException catch (error) {
      throw RepositoryException.transactionFailed(error.message);
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw RepositoryException.transactionFailed(error.toString());
    }
  }

  CsvExportRawResult _normalizeResponse(dynamic response) {
    if (response == null) {
      throw RepositoryException.validationFailed("rpc_response", value: "null");
    }

    if (response is String) {
      return CsvExportRawResult(csvContent: response);
    }

    if (response is Map<String, dynamic>) {
      return _rawResultFromMap(response);
    }

    if (response is List && response.isNotEmpty) {
      final dynamic first = response.first;
      if (first is String) {
        return CsvExportRawResult(csvContent: first);
      }
      if (first is Map<String, dynamic>) {
        return _rawResultFromMap(first);
      }
    }

    final String typeName = response.runtimeType.toString();
    throw RepositoryException.validationFailed("rpc_response", value: typeName);
  }

  CsvExportRawResult _rawResultFromMap(Map<String, dynamic> raw) {
    final String? csv = _extractCsvContent(raw);
    if (csv == null) {
      throw RepositoryException.validationFailed("rpc_response.csv", value: raw.toString());
    }

    return CsvExportRawResult(
      csvContent: csv,
      fileName: _stringOrNull(raw["file_name"]),
      contentType: _stringOrNull(raw["content_type"]),
      rowCount: _intOrNull(raw["row_count"]),
      metadata: _metadataFromRaw(raw),
    );
  }

  String? _extractCsvContent(Map<String, dynamic> map) {
    final Object? direct = map["csv"] ?? map["csv_content"] ?? map["content"];
    if (direct is String) {
      return direct;
    }

    final Object? base64 = map["csv_base64"] ?? map["base64"];
    if (base64 is String) {
      try {
        return utf8.decode(base64Decode(base64));
      } on FormatException {
        return null;
      }
    }

    return null;
  }

  String? _stringOrNull(Object? value) => value is String ? value : null;

  int? _intOrNull(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic>? _metadataFromRaw(Map<String, dynamic> raw) {
    final Object? embeddedMetadata = raw["metadata"];
    if (embeddedMetadata is Map<String, dynamic>) {
      return Map<String, dynamic>.from(embeddedMetadata);
    }

    final Map<String, dynamic> shallowCopy = Map<String, dynamic>.from(raw);
    shallowCopy.remove("csv");
    shallowCopy.remove("csv_content");
    shallowCopy.remove("csv_base64");
    shallowCopy.remove("content");
    return shallowCopy.isEmpty ? null : shallowCopy;
  }
}
