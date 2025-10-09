# CSVエクスポート権限メモ (2025-10-06)

## 合意済みの方針
- Supabase 側ではロールベースの認可方式を採用する。
- 当面は `store_manager` 相当の単一ロールのみを用意し、現行ユーザー（屋台スタッフ2名）全員をこのロールに割り当てる。
- アプリ実装・RLS ポリシー・UI 表示はいずれも「対象ロールを持っているか」をチェックする形で進める。
- 将来的にスタッフ構成が増えた場合でも、ロールを分割・追加するだけで拡張できるようにする。

## メモ
- RLS ポリシー設計では `auth.role()` ではなく JWT に埋め込まれた `role` / `org_id` クレームを利用する想定。
- `export_jobs` を含む `analytics` スキーマのビュー／RPCに対し、最小権限でのアクセス制限を仕込む準備を進める。
- Security WG レビュー時には「単一ロール運用だがロールベース実装で将来の多段階認可に備えている」点を説明する。

## ユーザー意見（2025-10-06）
1. JWT クレームはミニマルな文字列フィールドで実装する方針を採用する。
2. ロール割当と更新は利便性重視でスクリプト（必要に応じて CLI 併用）を整備する。
3. RLS とサービス層の整備手順は提案内容をそのまま採用する。
4. 権限不足時の UI メッセージは管理者前提で再試行または開発者連絡を促す内容にする。
5. 監査ログ管理方針は提案通りとし、アクセス制御と通知設計を進める。

## 最小リリース決定事項（2025-10-06）

### データセット仕様
- 提供データセットは以下5種類とし、Supabase `analytics.fn_export_csv` の `dataset_id` も同一キーで固定する。
	- `sales_line_items`
		- 列順: `org_id`, `location_id`, `business_date`, `order_id`, `line_id`, `line_sequence`, `order_number`, `order_status`, `channel`, `table_no`, `menu_item_id`, `menu_item_code`, `menu_item_name`, `menu_category_id`, `menu_category_name`, `qty`, `unit_price`, `line_subtotal`, `discount_amount`, `tax_rate`, `tax_amount`, `line_total`, `ordered_at`, `served_at`, `canceled_flag`, `void_reason`, `special_request`, `options_json`, `ordered_by`, `exported_at`, `export_job_id`
		- 型: UUID／text／numeric(12,2〜3)／boolean／timestamptz (ビュー定義に準拠)。
	- `purchases_line_items`
		- 列順: `org_id`, `location_id`, `purchase_id`, `line_id`, `line_sequence`, `purchase_date`, `supplier_id`, `supplier_name`, `po_number`, `sku_id`, `sku_code`, `sku_name`, `unit_of_measure`, `conversion_ratio`, `qty`, `stock_qty`, `unit_cost`, `ext_cost`, `tax_amount`, `tax_rate`, `currency`, `batch_no`, `expiry_date`, `received_by`, `notes`, `exported_at`, `export_job_id`
		- 型: UUID／text／date／numeric(12,2〜3)／json整合 (ビュー定義に準拠)。
	- `inventory_transactions`
		- 列順: `org_id`, `location_id`, `tx_id`, `tx_time`, `business_date`, `tx_type`, `ref_type`, `ref_id`, `sku_id`, `sku_name`, `unit_of_measure`, `quantity_delta`, `quantity_after`, `reason_code`, `notes`, `performed_by`, `lot_no`, `exported_at`, `export_job_id`
		- 型: UUID／text／numeric(12,3)／timestamptz。
	- `waste_log`
		- 列順: `org_id`, `location_id`, `waste_id`, `waste_time`, `business_date`, `sku_id`, `sku_name`, `unit_of_measure`, `qty`, `unit_cost`, `waste_cost`, `reason`, `lot_no`, `recorded_by`, `notes`, `linked_order_id`, `exported_at`, `export_job_id`
		- 型: UUID／text／numeric(12,2〜3)／timestamptz。
	- `menu_engineering_daily`
		- 列順: `org_id`, `location_id`, `business_date`, `menu_item_id`, `menu_item_code`, `menu_item_name`, `menu_category_id`, `menu_category_name`, `sales_qty`, `sales_amount`, `avg_price`, `food_cost`, `recipe_unit_cost`, `contribution_margin`, `cm_rate`, `share_qty`, `popularity_quadrant`, `waste_qty`, `exported_at`, `export_job_id`
		- 型: UUID／text／date／numeric(12,2〜4)／分類テキスト。
- 列構成と型は本メモの記述を最優先し、以後の変更はリリース審議が必要。

### タイムゾーンとフォーマット
- すべての日時・日付は JST (UTC+9) 固定で出力する。
- 出力時刻は ISO 8601 基本表記（例: `20251006T103015+09:00`）で表現し、CSV上の `business_date` 等の日付列は `YYYY-MM-DD` とする。

### ファイル配信と保管
- アプリ側で即時ダウンロードとし、プラットフォーム標準のファイルピッカー／ファイラーで保存先をユーザーに指定させる。
- Supabase に保存は行わず、`export_jobs` テーブルにはメタデータと7日間の再ダウンロード用参照情報のみ保持（ファイル本体は端末任せ）。
- `export_jobs` レコードとアプリ内キャッシュは7日後に自動削除し、それ以降は再取得不可。期間内の再ダウンロードは `export_jobs` 経由で許可する。

### レートリミットとリトライ
- 1組織あたり1日5リクエストまで（UTC+9で日付切替）。
- 同時実行は1ジョブ/組織に制限し、並行リクエストは 429 相当エラーで返す。
- 失敗ジョブは UI 上に「再試行」ボタンを表示し、利用者が明示的にリトライできる。再試行はレートリミット消費対象（API 側で同一日5回を超えた場合は警告表示）。

### 障害時対応
- 最小リリースでは Supabase RPC の例外をアプリで受け取り、詳細ログを出力するのみ（通知や外部連携は未実装）。
- `export_jobs.status` と `error_details` には失敗内容を記録し、管理者確認用にアプリから参照できるようにする。

### 機微情報検出と暗号化
- 既存の logging PII マーキングと同等のテキスト検出処理を CSV 生成後に適用する。
- 検出ヒットがある場合、アプリ側で AES-256 で暗号化した ZIP (`*.csv.enc.zip`) を生成し、画面上にワンタイムパスワードを表示する。
- パスワードは 16 文字英数記号で生成し、セッション終了と同時に破棄。`export_jobs.metadata` にも保存しない。

### 監査・運用メモ
- `export_jobs` に記録したメタデータと `duration_ms` を用い、週次で運用レビューを行う。
- 監査ログ閲覧は `store_manager` ロールに限定し、Security WG 判定までは追加通知を実装しない。
