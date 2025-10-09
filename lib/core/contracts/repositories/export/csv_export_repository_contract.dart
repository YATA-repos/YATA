import "../../export/export_contracts.dart";

/// CSV エクスポートのデータアクセス契約
abstract interface class CsvExportRepositoryContract {
  /// Supabase RPC を実行して CSV 文字列を取得する。
  ///
  /// 返り値は RPC から返却された生データを保持している。サービス層で BOM 付与や
  /// ファイル名組み立てなどの後処理を行う。
  Future<CsvExportRawResult> export(CsvExportRequest request);
}
