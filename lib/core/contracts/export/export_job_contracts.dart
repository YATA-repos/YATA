import "export_contracts.dart";

/// CSVエクスポートジョブの状態
enum CsvExportJobStatus {
  queued("queued"),
  running("running"),
  completed("completed"),
  failed("failed");

  const CsvExportJobStatus(this.value);

  /// Supabase `export_jobs.status` に格納される文字列値
  final String value;

  bool get isFinal => this == CsvExportJobStatus.completed || this == CsvExportJobStatus.failed;

  bool get isInProgress => this == CsvExportJobStatus.queued || this == CsvExportJobStatus.running;
}

/// `export_jobs` テーブルへ書き込むログレコード
class CsvExportJobLogEntry {
  const CsvExportJobLogEntry({
    required this.status,
    required this.dataset,
    required this.periodFrom,
    required this.periodTo,
    required this.loggedAt,
    this.organizationId,
    this.locationId,
    this.requestedBy,
    this.rowCount,
    this.duration,
    this.errorDetails,
    this.metadata,
  });

  final CsvExportJobStatus status;
  final CsvExportDataset dataset;
  final DateTime periodFrom;
  final DateTime periodTo;
  final DateTime loggedAt;
  final String? organizationId;
  final String? locationId;
  final String? requestedBy;
  final int? rowCount;
  final Duration? duration;
  final String? errorDetails;
  final Map<String, dynamic>? metadata;

  /// Supabaseへ送信するためのJSON表現
  Map<String, dynamic> toJson() => <String, dynamic>{
      "status": status.value,
      "dataset_id": dataset.id,
      "period_from": periodFrom.toIso8601String(),
      "period_to": periodTo.toIso8601String(),
      "logged_at": loggedAt.toIso8601String(),
      if (organizationId != null && organizationId!.isNotEmpty) "org_id": organizationId,
      if (locationId != null && locationId!.isNotEmpty) "location_id": locationId,
      if (requestedBy != null && requestedBy!.isNotEmpty) "requested_by": requestedBy,
      if (rowCount != null) "row_count": rowCount,
      if (duration != null) "duration_ms": duration!.inMilliseconds,
      if (errorDetails != null && errorDetails!.isNotEmpty) "error_details": errorDetails,
      if (metadata != null && metadata!.isNotEmpty) "metadata": metadata,
    };
}

/// `export_jobs` テーブルに格納された既存ジョブのスナップショット
class CsvExportJobRecord {

  factory CsvExportJobRecord.fromJson(Map<String, dynamic> json) {
    return CsvExportJobRecord(
      id: json["id"]?.toString() ?? "",
      dataset: _datasetFromString(json["dataset_id"]?.toString() ?? ""),
      status: _statusFromString(json["status"]?.toString() ?? "completed"),
      requestedAt: DateTime.parse(json["requested_at"] as String),
      periodFrom: DateTime.parse(json["period_from"] as String),
      periodTo: DateTime.parse(json["period_to"] as String),
      organizationId: json["org_id"]?.toString(),
      locationId: json["location_id"]?.toString(),
      requestedBy: json["requested_by"]?.toString(),
      rowCount: json["row_count"] is int ? json["row_count"] as int : int.tryParse(json["row_count"]?.toString() ?? ""),
      durationMs: json["duration_ms"] is int
          ? json["duration_ms"] as int
          : int.tryParse(json["duration_ms"]?.toString() ?? ""),
      metadata: json["metadata"] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json["metadata"] as Map<String, dynamic>)
          : null,
      fileName: json["file_name"]?.toString(),
      sourceViewVersion: json["source_view_version"]?.toString(),
      generatedByAppVersion: json["generated_by_app_version"]?.toString(),
    );
  }
  const CsvExportJobRecord({
    required this.id,
    required this.dataset,
    required this.status,
    required this.requestedAt,
    required this.periodFrom,
    required this.periodTo,
    this.organizationId,
    this.locationId,
    this.requestedBy,
    this.rowCount,
    this.durationMs,
    this.metadata,
    this.fileName,
    this.sourceViewVersion,
    this.generatedByAppVersion,
  });

  final String id;
  final CsvExportDataset dataset;
  final CsvExportJobStatus status;
  final DateTime requestedAt;
  final DateTime periodFrom;
  final DateTime periodTo;
  final String? organizationId;
  final String? locationId;
  final String? requestedBy;
  final int? rowCount;
  final int? durationMs;
  final Map<String, dynamic>? metadata;
  final String? fileName;
  final String? sourceViewVersion;
  final String? generatedByAppVersion;

  DateTime get expiresAt => requestedAt.add(const Duration(days: 7));

  bool isWithinRetention(DateTime now) => !now.isAfter(expiresAt);

  static CsvExportJobStatus _statusFromString(String value) => CsvExportJobStatus.values.firstWhere(
      (CsvExportJobStatus status) => status.value == value,
      orElse: () => CsvExportJobStatus.completed,
    );

  static CsvExportDataset _datasetFromString(String value) => CsvExportDataset.values.firstWhere(
      (CsvExportDataset dataset) => dataset.id == value,
      orElse: () => CsvExportDataset.salesLineItems,
    );

  Map<String, dynamic> toJson() => <String, dynamic>{
      "id": id,
      "dataset_id": dataset.id,
      "status": status.value,
      "requested_at": requestedAt.toIso8601String(),
      "period_from": periodFrom.toIso8601String(),
      "period_to": periodTo.toIso8601String(),
      "org_id": organizationId,
      "location_id": locationId,
      "requested_by": requestedBy,
      "row_count": rowCount,
      "duration_ms": durationMs,
      "metadata": metadata,
      "file_name": fileName,
      "source_view_version": sourceViewVersion,
      "generated_by_app_version": generatedByAppVersion,
    };
}

/// 日次レートリミットの状態スナップショット
class CsvExportRateLimitSnapshot {

  factory CsvExportRateLimitSnapshot.fromJson(Map<String, dynamic> json) {
    return CsvExportRateLimitSnapshot(
      organizationId: json["organization_id"]?.toString() ?? "",
      dateKey: json["date_key"]?.toString() ?? "",
      count: json["count"] is int
          ? json["count"] as int
          : int.tryParse(json["count"]?.toString() ?? "") ?? 0,
      limit: json["limit"] is int
          ? json["limit"] as int
          : int.tryParse(json["limit"]?.toString() ?? "") ?? 0,
      resetAt: DateTime.parse(json["reset_at"] as String),
    );
  }
  const CsvExportRateLimitSnapshot({
    required this.organizationId,
    required this.dateKey,
    required this.count,
    required this.limit,
    required this.resetAt,
  });

  final String organizationId;
  final String dateKey;
  final int count;
  final int limit;
  final DateTime resetAt;

  bool get isExceeded => count >= limit;

  Map<String, dynamic> toJson() => <String, dynamic>{
        "organization_id": organizationId,
        "date_key": dateKey,
        "count": count,
        "limit": limit,
        "reset_at": resetAt.toIso8601String(),
      };
}
