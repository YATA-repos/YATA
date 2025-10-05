/// 日時範囲（契約）
class DateTimeRange {
  const DateTimeRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

/// バッチ処理リクエスト（契約・汎用）
class BatchRequest<T> {
  const BatchRequest({
    required this.type,
    required this.userId,
    this.dateRange,
    this.filters,
    this.options,
  });

  /// 任意のバッチ種別識別子（ドメイン固有の文字列など）
  final String type;
  final String userId;
  final DateTimeRange? dateRange;
  final Map<String, dynamic>? filters;
  final Map<String, dynamic>? options;
}

/// バッチ処理結果（契約・汎用）
class BatchResult<T> {
  const BatchResult({required this.success, this.data, this.error, this.duration});

  final bool success;
  final T? data;
  final String? error;
  final Duration? duration;
}

/// バッチ処理サービス契約（汎用）
abstract class BatchProcessingServiceContract {
  /// サービスの識別子。
  String get loggerComponent;

  Future<BatchResult<T>> run<T>(BatchRequest<T> request);
}
