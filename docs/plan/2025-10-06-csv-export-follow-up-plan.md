# CSVエクスポート残タスク整理 (2025-10-06)

## 1. 現状サマリー
- `lib/features/export/` 配下に `CsvExportRepository` / `CsvExportService` を追加し、売上明細CSV向けのアプリ内ユースケースをプロトタイプ済み。
- Supabase 側の 5 種ビュー、`analytics.fn_export_csv` RPC、`export_jobs` テーブル DDL を `supabase/migrations/20251006_csv_export_phase1.sql` で作成し、サービス層からのメタデータ連携まで完了。
- Flutter UI、RLS設定、エクスポート履歴画面、Analytics/Telemetry の詳細設計は未着手。
- 参考資料: `docs/plan/2025-10-02-csv-export-implementation-plan.md`、`docs/draft/analysis/csv_export_design_draft.md`。

### 1.1 最小リリース仕様スナップショット (2025-10-06更新)
- 対応データセットは `sales_line_items` / `purchases_line_items` / `inventory_transactions` / `waste_log` / `menu_engineering_daily` の5種。列順・カラム名・型は `supabase/migrations/20251006_csv_export_phase1.sql` と `docs/draft/analysis/csv_export_auth_notes.md` に従い凍結済み。
- 日時は全て JST (UTC+9) 固定。CSV内のタイムスタンプは ISO 8601 基本表記 (`20251006T103015+09:00`)、日付は `YYYY-MM-DD`。
- アプリは Supabase RPC からCSV文字列を受け取り、即時ダウンロード処理で端末ファイラー/ファイルピッカーに保存させる。
- `export_jobs` レコードは 7 日間保持し再ダウンロードを許可。7日経過後はアプリとバックエンドから自動削除し、ファイル本体の保管は行わない。
- レートリミット: 組織ごとに 1 日 5 リクエスト、同時実行 1 ジョブ。リトライは UI で明示操作し、レート枠を消費する。
- 障害時は Supabase/アプリ双方でログ出力のみ。通知・自動復旧は Phase 1 scope 外。
- CSV生成後に logging の PII マーキングロジックで機微情報を走査。ヒット時は AES-256 暗号化 ZIP を生成し、画面に16文字ワンタイムパスワードを表示 (セッション終了時に破棄)。

## 2. 直近 1-2 週間で抑えるべき優先アクション
| 優先度 | アクション | 所属トラック | メモ |
| --- | --- | --- | --- |
| ✅ | Supabaseビュー (`sales_line_items_view` など5種) の定義と試験データ検証 | Data Access | `analytics.*` ビューを追加、UTC→JST整形とCSV生成用ヘルパーを実装済み |
| ✅ | `fn_export_csv` RPC 実装（期間・店舗フィルタ、行数制限、BOM付CSV返却） | Data Access | 31日上限バリデーション・BOM付与・`export_jobs` 挿入を実装済み |
| ✅ | `ExportService` → Supabase RPC 連携テスト・`export_jobs` ログテーブルスキーマ確定 | Service Layer | RPCから返却された `export_job_id` を尊重し、アプリ側の重複ロギングを抑制 |
| P1 | FlutterエクスポートUIモック確定・Widgetテスト設計 | Flutter UI | JST固定の日付選択、CSV種別ラジオ、即時ダウンロード(ファイルピッカー)と暗号化ケースのOTP表示を含める |
| ✅ | サービス層の制御ロジック実装 | Service Layer | 日次5件・同時実行1件の制限、7日間の再DLメタ保持、PIIヒット時の暗号化ZIP生成を実装済み |
| P1 | Security WG とのRLSレビュー用ドラフト作成 (`store_manager` ロール) | Security & Ops | JWTクレーム(ロール+org)、レートリミット仕様、export_jobsアクセス制御を含めたドラフト |

## 3. トラック別残タスク

### 3.1 Data Access (Supabase)
- [x] 5種ビューのDDL草案作成 + レビュアー割当 (`sales_line_items_view`, `purchases_line_items_view`, `inventory_movements_view`, `waste_log_view`, `menu_engineering_daily_view`).
- [x] 大規模出力を想定した `fn_export_csv(dataset_id, params jsonb)` 実装。
  - `filters` JSONのバリデーション、期間上限 (31日) チェック、`COPY`/`SELECT ... CSV` オプション比較。
  - 1.5倍換算のテストデータでパフォーマンス計測し、timeout / row limit ガードを決定。
- [x] Exportジョブ用テーブル `export_jobs` のDDL確定 (`status`, `requested_by`, `dataset_id`, `period`, `row_count`, `duration_ms`, `error_details`).
- [x] JST固定のタイムゾーン整形と ISO8601 基本表記が全データセットで満たされているかの統合テスト。
- [x] `export_jobs` の7日ローテーション用 SQL (削除スケジュール/マテビュー) を設計し、Supabase cron へ登録。
- [x] `fn_export_csv` から返却するメタデータに `encryption_required` フラグと暗号化実施根拠(PII検知結果)を含める。

### 3.2 Service Layer
- [x] `CsvExportService` へ `export_jobs` ログ書き込み/失敗時リトライ制御を追加。
- [x] データセット拡張 (`purchasesLineItems`, `inventoryTransactions`, `wasteLog`, `menuEngineeringDaily`) 対応のロジックとバリデーション共通化。
- [ ] サービスレイヤー向け Integration Test (Supabaseローカル or Testcontainers) の計画を策定。
  - 方針: `scripts/test/export_service_it.fish` で Supabase CLI の `supabase start` を起動し、ローカル Postgres に最新マイグレーションとシードデータ (`test_cache/export_seed.sql`) を適用してから `dart test integration/export_service_test.dart` を実行。
  - CI: GitHub Actions では service container で Supabase を起動し、`INTEGRATION_TEST=1` 設定時のみ走らせる。`Makefile` に `integration-test` ターゲットを追加し、ローカル/CI の手順差分をなくす。
  - スコープ: 正常系(全5データセット)、レートリミット429、暗号化ZIP生成、再ダウンロード動作までを網羅。異常系はモックテストに委譲。
  - 現状: `scripts/test/export_service_it.fish` / `test_cache/export_seed.sql` / `test/integration/export/export_service_test.dart` を追加済み。各スクリプト・SQLはまだ未実行で、Supabase ローカル環境でも検証前。
- [ ] `CsvExportResult` のメタ情報 (`source_view_version`, `generated_by_app_version`) 付与方針を決める。
  - `source_view_version`: Supabase ビューの COMMENT にバージョン文字列を保持し、`fn_export_csv` から返却するメタに含める。`export_jobs` ログにも保存してトレーサビリティを確保。
  - `generated_by_app_version`: クライアント側で `package_info_plus` から取得したビルドバージョンを RPC 呼び出し時にヘッダーへ渡し、サービス層で `CsvExportResult` に格納。UI には暗号化ZIP時のみ補足情報として表示。
  - 追加検討: バージョン変更時のリリースノート連動や互換性警告は Phase 2 で議論する。
- [x] 1日5件・同時1件のレートリミットを `export_jobs` とクライアントキャッシュで判定し、429エラーと再試行案内に統一。
- [x] 再ダウンロードAPI/ユースケースを追加し、7日以内の `export_jobs` メタデータから再取得できるようにする。
- [x] CSV取得後のPIIスキャン＋暗号化ZIP生成処理をサービス層に実装し、パスワード生成と返却値に連携。

### 3.3 Flutter UI / UX
- [ ] `Settings > Data Export` 画面モックのレビュー完了、JST固定カレンダー、CSV種別選択、暗号化時のOTP表示領域を含める。
  - レイアウト: `Scaffold` + `CustomScrollView`、ヘッダーに対象店舗概要とレート残数チップ、ボディは `Card` 3枚構成 (期間選択・データ種別・出力オプション)。
  - デザイン原則: 既存の Settings セクションと同じカラー/タイポグラフィを踏襲し、暗号化フローはワンタイムパスワードパネルをモーダルで表示。
  - モック承認者: モバイル担当 + Security WG + 会計担当。2025-10-15 のUIレビュー会議で最終合意。
- [ ] 期間・店舗フィルター、CSV種別ラジオボタン (Phase 1は単一選択) のForm実装。レートリミット残数のラベル/警告を表示。
  - フォーム: `FormBuilder` + `Riverpod` 管理、期間は `showDateRangePicker` をJSTに固定、店舗は `DropdownMenu<Store>`。
  - CSV種別: `SegmentedButton` で単一選択、説明テキストでデータセットのカラム概要を表示。
  - レート残数表示: `InfoChip` で残回数/リセット時刻を表示し、残0時は `FilledButton.tonal` を disable して retry 手順リンクを表示。
- [ ] エクスポート中プログレス + 完了トースト/429や権限不足時の管理者向けメッセージ(再試行/開発者連絡)を実装。
  - 進行表示: `showModalBottomSheet` に `LinearProgressIndicator` を表示し、暗号化処理中は段階的メッセージを切替。
  - 完了通知: `ScaffoldMessenger` の `SnackBar` + 成功時は保存先ショートカット、429/権限エラー時は `AlertDialog` で次アクションを提示。
  - メッセージ原本: Security WG と共有し、監査ログの案内文と整合させる。
- [ ] Androidファイル保存 ( `path_provider` + `share_plus`) と Windows保存ダイアログで即時ダウンロードし、保存成功/失敗をユーザーに通知。
  - Android: `path_provider` で `Download/yata/exports` 配下へ一時保存後、`share_plus` の `shareXFiles` でユーザーに保存先を明示。
  - Windows: `file_selector` パッケージを採用し、デフォルトディレクトリを `Documents\Yata\Exports` に設定。保存完了時は Explorer を開くオプションを提示。
  - 共通: 保存失敗時は再試行/問い合わせナレッジベースへのリンクを `SnackBar` に同梱。
- [ ] 暗号化ZIP生成時のダウンロード/パスワード表示UI、セッション終了時のパスワード破棄をハンドリング。
  - パスワード提示: エクスポート完了シートに16桁コードを表示し、「コピー」「QR表示」「閉じる」アクションを配置。閉じるとローカル状態をクリア。
  - 再表示制御: 再ダウンロード時のみ再発行、`Clipboard.setData` 後は `SnackBar` で注意喚起。セッション終了で `SecureStorage` から値を削除。
  - ドキュメント連携: ガイド (`docs/guide/csv_export.md` 仮) に手順を追記し、UIからリンクする。
- [ ] オフライン時のリトライUI設計 (Phase 3までの先行メモ)。
  - 検出: `Connectivity` プラグインでオンライン監視し、送信前に `ExportService.canSubmit` をチェック。
  - 表示: オフライン時は `Banner` で通知し、「端末がオンラインになったら再送」トグルを提供。
  - 振る舞い: Phase 1では手動リトライのみ、Phase 3で自動再送ワークフローを設計する旨をコメントとして残す。

### 3.4 Telemetry / Analytics
- [x] `analyticsLogger` へ `csv_export_started/completed/failed` イベントを追加し、`dataset_id`, `range_days`, `duration_ms`, `row_count` を記録。
- [ ] 期間上限超過、RLS拒否などエラーケースを含むメトリクスダッシュボード設計。
- [ ] レートリミット到達・再ダウンロード・暗号化発生イベントを追加し、週次レビュー用のLooker Studioダッシュボード要件を定義。

### 3.5 Security & 権限
- [ ] Supabase RLSポリシー案のドラフト (`store_manager` ロール) をJWTクレーム(`role`, `org_id`)チェックと `export_jobs` 再DL権限で具体化。
- [ ] レートリミット仕様 (日次5回/同時1回) の権限モデルへの織込みと監査ログ出力内容の定義。
- [ ] 監査ログとアクセス追跡要件 (誰がいつどのCSVを出力/再DL/暗号化したか) の明文化。
- [ ] Security WG レビュー実施とフィードバック反映 (`docs/plan/2025-10-02` セクション11-5)。

### 3.6 QA / ドキュメント
- [ ] `docs/reference/dataset_dictionary.md` の初版作成 (Phase 0-1)。5種データセットの列順・型・フォーマット(ISO8601/JST)・PII判定ルールを掲載。
- [ ] Supabase スキーマ差分とアプリ側モデルのマッピング表を `docs/plan/2025-10-02` に追記。
- [ ] `CsvExportService` の利用ガイド/トラブルシュート (`docs/guide/` 配下に新設) を草案。レートリミットFAQ、再ダウンロード手順、暗号化ZIP解除手順を含む。
- [ ] Tax/会計チーム向けのサンプルCSVレビュー会議のログを `docs/logging/` に記録。

### 3.7 フェーズ2/3 準備
- [ ] レシピ原価スナップショット/仕入価格履歴のデータソース調査と必要スキーマ拡張案。
- [ ] 発注点推定・欠品ログで必要なリアルタイムイベント取得の整備計画。
- [ ] 自動配信 (メール/Slack) のジョブ基盤要件定義 (`docs/plan/2025-10-02` Phase 3-項目)。

## 4. リスク・依存関係
- **データ品質**：現行スキーマの欠損・正規化不足が判明した場合、ビュー実装がブロックされる可能性。→ Phase 0 ギャップ分析を最優先で完了する。
- **パフォーマンス**：大量期間のCSV出力はSupabase負荷が高い。→ 期間制限とマテビュー導入検討を継続。
- **セキュリティ**：RLS未設定のままリリースすると個人情報/機密データ流出リスク。→ Security WGのレビューをリリースゲートに設定。
- **暗号化運用**：PII検出の誤検知/見逃しがあると暗号化が過不足になるリスク。→ ルールテストと監査ログで精度を継続検証、解除パスワード表示のUXをレビュー。

## 5. 次アクション担当案
| タスク | 暫定オーナー | 期日目安 |
| --- | --- | --- |
| Supabaseビュー & RPC プロトタイプ | Backendリード | 2025-10-12 |
| Export UI モック確定 + Flutter実装着手 | モバイル担当 | 2025-10-15 |
| レートリミット + 再DL + 暗号化サービス実装 | Backend/Service担当 | 2025-10-16 |
| RLSドラフト & Security WGレビュー | Security WG 連携 | 2025-10-18 |
| Dataset Dictionary ドラフト共有 | Data担当 | 2025-10-20 |

---
*本メモは `docs/plan/2025-10-02-csv-export-implementation-plan.md` の最新差分を取り込むための補助ドキュメントです。進捗更新時は本ファイルか元計画に反映してください。*
