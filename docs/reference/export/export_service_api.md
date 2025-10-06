# ExportService APIリファレンス

> 🚧 開発中 (Phase 1 / 2025-10-07〜2025-11-01)
>
> 最終更新: 2025-10-06

`ExportService` は CSV エクスポート機能のサービス層契約を提供し、Supabase 上の `fn_export_csv` RPC と連携して各データセットの CSV ファイルを生成します。本ドキュメントは Phase 1 (V1) リリースで提供する 5 つのデータセットを対象に、サービス API・Supabase RPC・ジョブトラッキング・エラーハンドリング方針を定義します。データセットの列仕様は [`docs/reference/dataset_dictionary.md`](../dataset_dictionary.md) を参照してください。

## 目次

1. [用語とコンポーネント](#用語とコンポーネント)
2. [サービスレイヤー契約](#サービスレイヤー契約)
3. [リポジトリ層契約とSupabase RPC](#リポジトリ層契約とsupabase-rpc)
4. [データセットID対応表](#データセットid対応表)
5. [バリデーションとビジネスルール](#バリデーションとビジネスルール)
6. [エラーハンドリング](#エラーハンドリング)
7. [認可・監査とログ](#認可監査とログ)
8. [運用・監視](#運用監視)
9. [既知の課題とフォローアップ](#既知の課題とフォローアップ)

## 用語とコンポーネント

| 用語 | 説明 |
| --- | --- |
| `ExportService` | Flutter サービスレイヤーのファサード。入力バリデーション、`export_jobs` 登録、Supabase RPC 呼び出しを担う。 |
| `CsvExportRepository` | `ExportService` から呼ばれるリポジトリ。Supabase RPC/Storage との通信を担当。 |
| `ExportJob` | エクスポート処理の履歴行。状態 (`queued`/`running`/`succeeded`/`failed`) とフィルタ、生成ファイルのメタ情報を保持。 |
| `ExportDataset` | `dataset_dictionary.md` に定義された各データセット。`datasetId` と Supabase ビューを1対1で対応付ける。 |
| `fn_export_csv` | Supabase RPC。指定データセットを CSV 文字列 (BOM 付 UTF-8) として返す。 |
| `ExportManifest` | 生成ファイル名やレコード数などのメタ情報。将来 `export_manifest.json` に拡張予定。 |

## サービスレイヤー契約

### Dartインターフェース

`lib/core/contracts` 配下に以下の契約を追加する想定です。

```dart
abstract class ExportService {
  /// CSVエクスポートを実行し、完了済みジョブの結果を返す。
  Future<ExportJobResult> export(ExportRequest request);

  /// export_jobs の状態を購読する。UI の進捗表示やリトライで利用。
  Stream<ExportJobProgress> watchJob(String exportJobId);
}

class ExportRequest {
  ExportRequest({
    required this.datasetId,
    required this.orgId,
    required this.dateFrom,
    required this.dateTo,
    this.locationId,
    required this.requestedBy,
    this.output,
    this.forceRegenerate = false,
  });

  final ExportDatasetId datasetId;
  final String orgId;
  final DateTime dateFrom; // inclusive
  final DateTime dateTo;   // inclusive
  final String? locationId; // null の場合はアクセス可能な全店舗
  final String requestedBy; // Supabase auth user id
  final ExportOutput? output; // 端末保存 / Supabase Storage など
  final bool forceRegenerate; // キャッシュ済み結果を無視するフラグ
}

class ExportJobResult {
  ExportJobResult({
    required this.job,
    required this.payload,
    required this.manifest,
  });

  final ExportJob job;
  final Uint8List payload; // UTF-8 BOM 付 CSV
  final ExportManifest manifest;
}

class ExportJob {
  ExportJob({
    required this.id,
    required this.datasetId,
    required this.status,
    required this.fileName,
    required this.requestedAt,
    required this.completedAt,
    required this.requestedBy,
    required this.params,
    this.error,
  });

  final String id;
  final ExportDatasetId datasetId;
  final ExportJobStatus status;
  final String fileName;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final String requestedBy;
  final ExportParams params;
  final ExportError? error;
}

enum ExportJobStatus { queued, running, succeeded, failed }

enum ExportErrorCode {
  invalidFilters,
  unauthorized,
  datasetNotSupported,
  upstreamTimeout,
  upstreamFailure,
  storageFailure,
  unknown,
}

class ExportError {
  const ExportError(this.code, {this.message, this.cause});
  final ExportErrorCode code;
  final String? message; // UI 表示メッセージ
  final Object? cause;   // ログ用詳細 (例: Supabaseエラーコード)
}

class ExportManifest {
  ExportManifest({
    required this.fileName,
    required this.contentType,
    required this.recordCount,
    required this.generatedAt,
    required this.exportedAt,
    required this.exportJobId,
    this.checksumSha256,
    this.metadata,
  });

  final String fileName;
  final String contentType; // text/csv; charset=UTF-8
  final int recordCount;
  final DateTime generatedAt; // Supabase 側での生成時刻
  final DateTime exportedAt;  // ExportService 側の付与時刻
  final String exportJobId;
  final String? checksumSha256;
  final Map<String, dynamic>? metadata; // 追加ヘッダ情報
}
```

### 入力パラメータ定義

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `datasetId` | `ExportDatasetId` | ✔ | `sales_line_items` などデータセット識別子。`dataset_dictionary.md` の定義と一致させる。 |
| `orgId` | `uuid` | ✔ | マルチテナント識別子。Supabase セッションと一致していることを確認する。 |
| `dateFrom` | `DateTime (UTC)` | ✔ | エクスポート開始日。サービス内で `Asia/Tokyo` に正規化。 |
| `dateTo` | `DateTime (UTC)` | ✔ | エクスポート終了日。`dateFrom` 以上で 31 日以内。 |
| `locationId` | `uuid?` |  | 店舗指定。null の場合はアクセス可能な全店舗を対象にし、`all_locations` 接尾辞をファイル名に付与。 |
| `requestedBy` | `uuid` | ✔ | エクスポート要求ユーザー。`export_jobs.requested_by` に格納。 |
| `output` | `ExportOutput?` |  | `device` (既定), `supabase-storage` など。将来的な配信方式拡張に備えた抽象。 |
| `forceRegenerate` | `bool` |  | 直近の成功ジョブがあっても再生成する場合は `true`。 |

### 戻り値

- `ExportJobResult.payload`: BOM 付き UTF-8 の CSV バイト列。
- `ExportJobResult.manifest.recordCount`: Supabase RPC の `row_count` から取得。`-1` の場合は未計測。
- `ExportJobResult.job.status`: `succeeded` 完了で返却。失敗時は例外をスローし、UI 側でリトライ誘導を行う。

### 例外

| 種別 | 説明 |
| --- | --- |
| `ValidationException` | 入力バリデーション (期間上限、必須フィルタ不足) で発生。 |
| `AuthorizationException` | ユーザーのロールや `orgId` が一致しない場合。 |
| `DatasetNotSupportedException` | 未対応の `datasetId` が指定された場合。 |
| `ExportJobFailedException` | Supabase RPC がエラーを返却、もしくは `export_jobs.status = failed` で終了した場合。 |

## リポジトリ層契約とSupabase RPC

### リポジトリ契約

```dart
abstract class CsvExportRepository {
  /// Supabase RPC を実行し、ジョブ情報と CSV データを受け取る。
  Future<CsvExportPayload> runExport({
    required ExportDatasetId datasetId,
    required String orgId,
    required DateTimeRange dateRange,
    String? locationId,
    required String requestedBy,
    bool forceRegenerate = false,
  });
}

class CsvExportPayload {
  CsvExportPayload({
    required this.jobId,
    required this.fileName,
    required this.bytes,
    required this.metadata,
  });

  final String jobId;
  final String fileName;
  final Uint8List bytes;
  final Map<String, dynamic> metadata; // row_count, checksum, exported_at 等
}
```

### RPC 仕様

| 項目 | 内容 |
| --- | --- |
| ファンクション名 | `analytics.fn_export_csv` |
| 引数 | `p_org_id uuid`, `p_dataset_id text`, `p_params jsonb`, `p_requested_by uuid`, `p_force_regenerate boolean default false` |
| 返却 | `record (job_id uuid, file_name text, payload bytea, exported_at timestamptz, row_count integer, checksum_sha256 text, metadata jsonb)` |
| タイムアウト | 25 秒 (クラウド Function タイムアウト 30 秒に合わせる) |
| バックオフ | 同一 `datasetId + params` で 60 秒以内の連続リクエストはキャッシュ結果を返却 (Phase 1 はメモリキャッシュ、将来は `export_jobs` 履歴再利用) |

`p_params` の JSON 形式:

```json
{
  "date_from": "2025-10-01",
  "date_to": "2025-10-05",
  "location_id": "1bf8d3b2-...",   // 任意
  "timezone": "Asia/Tokyo",
  "org_id": "a7c1...",              // RLS 二重チェック用
  "dataset_version": "2025-10-06"   // dataset_dictionary.md の更新日
}
```

#### RPC内部要件

1. `p_org_id` と `p_params.org_id` が一致しない場合は `RAISE EXCEPTION 'org mismatch' USING ERRCODE = '28000'`。
2. `p_dataset_id` に応じて該当ビュー (`analytics.sales_line_items_view` 等) を参照し、`COPY (SELECT ...) TO STDOUT WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8')` で CSV を生成。
3. 生成結果を `bytea` として返却し、BOM (`EF BB BF`) を先頭に付与。
4. `export_jobs` テーブルを以下のように更新:
   - `started_at`: RPC 開始時刻、`completed_at`: 成功時刻
   - `status`: `running` → (`succeeded` or `failed`)
   - `filters`: `p_params` を JSONB として保存
   - `row_count`: 取得件数
5. 失敗時は `status = failed`, `error_code`, `error_detail` を記録し、RPC は例外を再送。

### `export_jobs` テーブル拡張案

| 列名 | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `id` | uuid | ✔ | プライマリキー |
| `org_id` | uuid | ✔ | マルチテナント識別子 |
| `dataset_id` | text | ✔ | `ExportDatasetId` と一致 |
| `filters` | jsonb | ✔ | `p_params` を保存 |
| `status` | text | ✔ | `queued`/`running`/`succeeded`/`failed` |
| `requested_by` | uuid | ✔ | ユーザー ID |
| `requested_at` | timestamptz | ✔ | リクエスト時刻 (`now()` default) |
| `started_at` | timestamptz |  | RPC 実行開始 |
| `completed_at` | timestamptz |  | 実行完了 |
| `file_name` | text |  | 生成ファイル名 (`datasetId_dateFrom_dateTo[_all_locations].csv`) |
| `row_count` | integer |  | 抽出件数 |
| `checksum_sha256` | text |  | 出力ファイルの SHA-256 |
| `error_code` | text |  | `ExportErrorCode` に対応 |
| `error_detail` | text |  | Supabase ログ参照用 |
| `storage_path` | text |  | Supabase Storage に保管した場合のキー |

RLS は `org_id = auth.jwt() ->> 'org_id'` で制限し、`requested_by` が参照可能なレコードのみにアクセスさせます。

## データセットID対応表

| `ExportDatasetId` | CSVファイル名 | Supabaseビュー | 主用途 | 参照ドキュメント |
| --- | --- | --- | --- | --- |
| `sales_line_items` | `sales_line_items.csv` | `analytics.sales_line_items_view` | 売上明細 | [`dataset_dictionary.md`](../dataset_dictionary.md#1-売上明細-sales_line_itemscsv) |
| `purchases_line_items` | `purchases_line_items.csv` | `analytics.purchases_line_items_view` | 仕入明細 | [`dataset_dictionary.md`](../dataset_dictionary.md#2-仕入明細-purchases_line_itemscsv) |
| `inventory_movements` | `inventory_movements.csv` | `analytics.inventory_movements_view` | 在庫トランザクション | [`dataset_dictionary.md`](../dataset_dictionary.md#3-在庫トランザクション-inventory_movementscsv) |
| `waste_log` | `waste_log.csv` | `analytics.waste_log_view` | 廃棄ログ | [`dataset_dictionary.md`](../dataset_dictionary.md#4-廃棄ログ-waste_logcsv) |
| `menu_engineering_daily` | `menu_engineering_daily.csv` | `analytics.menu_engineering_daily_view` | メニュー工学 日次集計 | [`dataset_dictionary.md`](../dataset_dictionary.md#5-メニュー工学-日次集計-menu_engineering_dailycsv) |

`ExportDatasetId` は Dart の `sealed class` または `enum` で表現し、ビュー名・推奨ファイル名を紐付けるユーティリティを提供します。

## バリデーションとビジネスルール

1. **期間必須**: `dateFrom`/`dateTo` は必須。`dateFrom` > `dateTo` の場合は `ValidationException`。
2. **期間上限**: `dateTo.difference(dateFrom)` が 30 日を超える（31 日以上の範囲）場合は `invalidFilters` として拒否。
3. **店舗アクセス権**: `locationId` 指定時は、ユーザーがアクセス権を持つか `LocationAccessRepository` で検証。
4. **データセット制限**: Phase 1 では上表の 5 種類のみ許可。それ以外は `DatasetNotSupportedException`。
5. **CSV体裁**: 出力 CSV は BOM 付 UTF-8, RFC4180 準拠。`ExportService` 側で BOM を再確認し、不足していれば付与。
6. **ファイル名**: `"{datasetId}_{dateFrom}_{dateTo}{suffix}.csv"`。`suffix` は `locationId` 指定時 `_{locationId}`、未指定時 `_all_locations`。
7. **共通列の付与**: `exported_at`, `export_job_id` は RPC 側で付与し、サービス側でも `ExportManifest` に転記。
8. **キャッシュ再利用**: `forceRegenerate == false` かつ 24 時間以内に同じフィルタで成功済みジョブがある場合、ストレージに保管済みバイト列を再利用して I/O を削減。

## エラーハンドリング

| エラーコード | 発生条件 | ユーザー向けメッセージ例 | ログフィールド |
| --- | --- | --- | --- |
| `invalidFilters` | 期間不正・必須フィルタ欠落・期間上限超過 | `期間の指定が正しくありません。開始日と終了日を31日以内で設定してください。` | `reason=validation`, `fields=[dateFrom,dateTo]` |
| `unauthorized` | ロール不足 (`store_manager` 未満) / `orgId` ミスマッチ | `権限がありません。管理者に確認してください。` | `reason=authorization`, `requiredRole=store_manager` |
| `datasetNotSupported` | 未対応の `datasetId` | `選択されたデータセットは現在エクスポートできません。` | `datasetId` |
| `upstreamTimeout` | Supabase RPC タイムアウト (>25 秒) | `エクスポートがタイムアウトしました。再度お試しください。` | `durationMs`, `supabase.requestId` |
| `upstreamFailure` | Supabase 例外 (`RAISE EXCEPTION`) | `データ抽出に失敗しました。後ほど再度お試しください。` | `supabase.code`, `supabase.detail` |
| `storageFailure` | Supabase Storage 書き込み失敗 (将来) | `ファイルの保存に失敗しました。再試行してください。` | `storage.bucket`, `storage.path` |
| `unknown` | 上記以外の例外 | `予期せぬエラーが発生しました。サポートへお問い合わせください。` | `stackTrace`, `cause` |

`ExportService.export` は上記エラーを `ExportError` として `ExportJob` に保存し、UI 層には `ExportJobFailedException` で通知します。UI 側の `ExportJobProgress` 表示では、`ExportError.message` を優先的に表示し、詳細は `analyticsLogger` へ送信します。

## 認可・監査とログ

1. **ロール要件**: `store_manager` ロール以上のみ `ExportService` を実行可能。`AuthRepository` で検証し、ローカルチェックに加えて Supabase RPC の `SECURITY DEFINER` 内で再検証する。
2. **RLS**: `export_jobs`、各ビューは `org_id` で RLS を適用。RPC では実行直後に `SET LOCAL role` を使用して RLS を強制する。
3. **監査ログ**: 以下を `analyticsLogger` に記録。
   - `event: export_started`, `datasetId`, `orgId`, `locationId`, `dateRange`, `requestedBy`
   - `event: export_completed`, `durationMs`, `rowCount`, `fileName`, `exportJobId`
   - 失敗時は `event: export_failed`, `errorCode`, `errorDetail`
4. **PII制御**: CSV に個人情報が含まれないことを `dataset_dictionary.md` と照合。Service 層で追加フィルタやマスキングは行わない。

## 運用・監視

- **メトリクス**: Supabase 側で `export_jobs` を参照し以下をダッシュボード化。
  - 日次エクスポート回数 (`COUNT(*)`)
  - 失敗率 (`status = failed`)
  - 平均抽出所要時間 (`completed_at - started_at`)
- **アラート**: 10 分間で失敗が 5 回以上発生した場合に Slack 通知 (Security WG と共有)。
- **レート制限**: 同一ユーザーが 5 分以内に 5 ジョブ以上リクエストした場合は `429 Too Many Requests` を返す (Phase 1 実装範囲)。
- **バックアップ**: `forceRegenerate == false` の場合に Supabase Storage の `exports/{orgId}/{exportJobId}.csv` へ 24 時間保管し、Cloud Task で削除する。

## 既知の課題とフォローアップ

1. **複数データセット同時エクスポート**: Phase 1 では単一データセットのみ。将来的にバッチ実行 (`datasetIds[]`) を API に追加予定。
2. **進捗通知**: 現状はポーリングベースの `watchJob`。Supabase Realtime を利用した push 通知は Phase 2 で検討。
3. **圧縮**: 現行は生 CSV を返却。ダウンロード時間短縮のため `gzip` オプションを将来追加予定。
4. **`export_manifest.json`**: データセット間依存を表現するメタファイルは Phase 2 で提供予定。
5. **Dataset バージョニング**: `dataset_version` の自動付与と互換性チェックは Phase 1 では運用ルールで対応。Phase 2 で仕組み化する。
