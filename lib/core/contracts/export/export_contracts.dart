import "dart:collection";

import "package:intl/intl.dart";

/// CSVエクスポートでサポートされるデータセット種類
///
/// v1 では売上明細のみをターゲットとし、将来的な拡張を想定した列挙体構成とする。
enum CsvExportDataset {
  /// 売上明細 (order line items)
  salesLineItems("sales_line_items"),

  /// 仕入明細
  purchasesLineItems("purchases_line_items"),

  /// 在庫トランザクション
  inventoryTransactions("inventory_transactions"),

  /// 廃棄ログ
  wasteLog("waste_log"),

  /// メニュー工学用日次集計
  menuEngineeringDaily("menu_engineering_daily");

  const CsvExportDataset(this.id);

  /// Supabase 側の dataset_id
  final String id;

  /// ダウンロードファイル名の基本 prefix
  String get filePrefix => id;
}

/// CSV エクスポートで利用する日付期間とフィルター条件
typedef CsvExportFilters = Map<String, dynamic>;

/// CSV エクスポート実行時の入力情報
class CsvExportRequest {
  const CsvExportRequest({
    required this.dataset,
    required this.dateFrom,
    required this.dateTo,
    this.organizationId,
    this.locationId,
    this.includeHeaders = true,
    this.filters = const <String, dynamic>{},
    this.timeZone = "Asia/Tokyo",
    this.requestedBy,
    this.generatedByAppVersion,
    this.timeout,
  });

  /// 対象データセット
  final CsvExportDataset dataset;

  /// 抽出開始日 (inclusive)
  final DateTime dateFrom;

  /// 抽出終了日 (inclusive)
  final DateTime dateTo;

  /// 組織ID (org_id)
  final String? organizationId;

  /// 店舗ID (location_id)
  final String? locationId;

  /// CSV にヘッダー行を含めるかどうか
  final bool includeHeaders;

  /// 追加フィルタ条件 (Json 化され Supabase へ渡される)
  final CsvExportFilters filters;

  /// タイムゾーン (Supabase RPC 側のフォーマット統一用)
  final String timeZone;

  /// リクエスト実行者情報 (audit 用)
  final String? requestedBy;

  /// RPC 実行のタイムアウト (未指定時は上位層で決定)
  final Duration? timeout;

  /// クライアントアプリで認識しているビルドバージョン
  final String? generatedByAppVersion;

  CsvExportRequest copyWith({
    CsvExportDataset? dataset,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? organizationId,
    String? locationId,
    bool? includeHeaders,
    CsvExportFilters? filters,
    String? timeZone,
    String? requestedBy,
    String? generatedByAppVersion,
    Duration? timeout,
  }) => CsvExportRequest(
    dataset: dataset ?? this.dataset,
    dateFrom: dateFrom ?? this.dateFrom,
    dateTo: dateTo ?? this.dateTo,
    organizationId: organizationId ?? this.organizationId,
    locationId: locationId ?? this.locationId,
    includeHeaders: includeHeaders ?? this.includeHeaders,
    filters: filters ?? this.filters,
    timeZone: timeZone ?? this.timeZone,
    requestedBy: requestedBy ?? this.requestedBy,
    generatedByAppVersion: generatedByAppVersion ?? this.generatedByAppVersion,
    timeout: timeout ?? this.timeout,
  );

  /// 期間の日数差を計算 (inclusive)
  int get inclusiveDaySpan => dateTo.difference(dateFrom).inDays + 1;

  /// Supabase RPC へ渡す payload
  Map<String, dynamic> toRpcPayload() {
    final Map<String, dynamic> payload = <String, dynamic>{
      "date_from": _formatDate(dateFrom),
      "date_to": _formatDate(dateTo),
      "time_zone": timeZone,
      "include_headers": includeHeaders,
      if (organizationId != null && organizationId!.isNotEmpty) "org_id": organizationId,
      if (locationId != null && locationId!.isNotEmpty) "location_id": locationId,
      if (requestedBy != null && requestedBy!.isNotEmpty) "requested_by": requestedBy,
      if (generatedByAppVersion != null && generatedByAppVersion!.isNotEmpty)
        "generated_by_app_version": generatedByAppVersion,
    };

    if (filters.isNotEmpty) {
      payload["filters"] = HashMap<String, dynamic>.from(filters);
    }

    return payload;
  }

  /// 期間の検証 (dateFrom <= dateTo)
  bool get isChronological => !dateFrom.isAfter(dateTo);

  /// Asia/Tokyo などのタイムゾーンで ISO8601 文字列を生成
  ///
  /// Dart の `toIso8601String` はローカルタイムのオフセットを自動付与するため、
  /// ミリ秒部分を除去して RFC4180 に近いフォーマットへそろえる。
  static String _formatDate(DateTime date) {
    final DateTime local = date.isUtc ? date.toLocal() : date;
    final DateFormat formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    final String main = formatter.format(local);
    final Duration offset = local.timeZoneOffset;
    final String sign = offset.isNegative ? "-" : "+";
    final int totalMinutes = offset.inMinutes.abs();
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    final String offsetString =
        "$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
    return "$main$offsetString";
  }
}

/// Supabase RPC から返却される生データ
class CsvExportRawResult {
  const CsvExportRawResult({
    required this.csvContent,
    this.fileName,
    this.contentType,
    this.rowCount,
    this.metadata,
  });

  /// CSV 文字列 (UTF-8想定)
  final String csvContent;

  /// 推奨ファイル名
  final String? fileName;

  /// コンテントタイプ (明示される場合)
  final String? contentType;

  /// 推定レコード件数（Supabase 側で提供される場合）
  final int? rowCount;

  /// 任意のメタ情報
  final Map<String, dynamic>? metadata;
}

/// 暗号化が必要な場合の付帯情報
class CsvExportEncryptionInfo {
  const CsvExportEncryptionInfo({
    required this.required,
    this.password,
    this.originalFileName,
    this.reasons = const <Map<String, dynamic>>[],
  });

  /// 暗号化が必要かどうか
  final bool required;

  /// 暗号化ZIP解除用のワンタイムパスワード
  final String? password;

  /// 暗号化前のファイル名
  final String? originalFileName;

  /// 暗号化判断の根拠（PII検知ルールなど）
  final List<Map<String, dynamic>> reasons;

  bool get hasPassword => password != null && password!.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        "required": required,
        if (password != null) "password": password,
        if (originalFileName != null) "original_file_name": originalFileName,
        "reasons": reasons,
      };
}

/// アプリで利用する整形済みエクスポート結果
class CsvExportResult {
  const CsvExportResult({
    required this.dataset,
    required this.fileName,
    required this.contentType,
    required this.bytes,
    required this.generatedAt,
    required this.dateFrom,
    required this.dateTo,
    this.rowCount,
    this.metadata,
    this.encryption,
    this.exportJobId,
    this.sourceViewVersion,
    this.generatedByAppVersion,
  });

  /// 対象データセット
  final CsvExportDataset dataset;

  /// 出力ファイル名
  final String fileName;

  /// コンテントタイプ (デフォルト text/csv)
  final String contentType;

  /// CSV バイト列 (UTF-8 + BOM)
  final List<int> bytes;

  /// サービスでエクスポートしたタイムスタンプ
  final DateTime generatedAt;

  /// 抽出期間
  final DateTime dateFrom;
  final DateTime dateTo;

  /// 推定レコード件数
  final int? rowCount;

  /// その他メタ情報
  final Map<String, dynamic>? metadata;

  /// 暗号化関連情報
  final CsvExportEncryptionInfo? encryption;

  /// Supabase で付与された export_job_id
  final String? exportJobId;

  /// データセット元ビューのバージョン
  final String? sourceViewVersion;

  /// 本アプリのバージョン
  final String? generatedByAppVersion;

  bool get isEncrypted => encryption?.required ?? false;
}
