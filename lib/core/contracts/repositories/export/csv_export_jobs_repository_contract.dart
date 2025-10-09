import "../../export/export_job_contracts.dart";

/// エクスポートジョブログのデータアクセス契約
abstract interface class CsvExportJobsRepositoryContract {
  /// `export_jobs` テーブルへログレコードを挿入する。
  Future<void> insertJob(CsvExportJobLogEntry entry);

  /// 指定日のリクエスト件数を集計する。
  /// [from] と [to] はタイムゾーンを正規化した境界値を想定。
  Future<int> countDailyExports({
    required String organizationId,
    required DateTime from,
    required DateTime to,
  });

  /// 指定組織で実行中のジョブが存在するか確認する。
  Future<bool> hasActiveJob(
    String organizationId, {
    Duration lookback = const Duration(minutes: 10),
  });

  /// エクスポートジョブIDからレコードを取得する。
  Future<CsvExportJobRecord?> findJobById(String jobId);
}
