# CSVエクスポート データセット辞書

最終更新: 2025-10-06

本ドキュメントは Phase 0 で実施する CSV エクスポート基盤整備の一環として、YATA が提供予定の主要データセットのカラム仕様とキー方針を整理したものです。実装計画の全体像は [`docs/plan/2025-10-02-csv-export-implementation-plan.md`](../plan/2025-10-02-csv-export-implementation-plan.md)、詳細な背景と追加ユースケースは [`docs/draft/analysis/csv_export_design_draft.md`](../draft/analysis/csv_export_design_draft.md) を参照してください。

## 共通仕様

| 項目 | 内容 |
| --- | --- |
| ファイル形式 | CSV (UTF-8, BOM 付き, RFC4180 準拠, ヘッダ行あり) |
| タイムゾーン | `Asia/Tokyo` 固定。日時列は `timestamp with time zone` を ISO8601 形式 (`YYYY-MM-DDTHH:MM:SS+09:00`) で出力 |
| 数値フォーマット | 金額: `numeric(12,2)`、数量: `numeric(12,3)` もしくは `integer`。通貨記号は含めない |
| マルチテナントキー | `org_id` / `location_id` をすべてのデータセットに含める |
| フィルタパラメータ | `date_from`, `date_to`, `location_id`。将来的に `dataset_id` やタグフィルタを追加予定 |
| 文字列 | 基本は `text`。エンコードは UTF-8、改行は `\n` |
| 真偽値 | `boolean` (`true`/`false`) で出力 |

### 共通列

| 列名 | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `org_id` | uuid | ✔ | 事業者識別子。Supabase 認証からトークン連携 |
| `location_id` | uuid | ✔ | 店舗／屋台の識別子 |
| `exported_at` | timestamp with time zone | ✔ | エクスポート処理時刻 (`ExportJob.started_at`) |
| `export_job_id` | uuid | ✔ | `export_jobs` テーブルのジョブ ID。再現性確保用 |

> **補足**: `exported_at` / `export_job_id` は `ExportService` で横断的に付与する。既存データモデルに未追加の場合は Supabase ビュー側で定数列として拡張する。

## Phase 1 対象データセット

以降では Phase 1 (V1) で提供する 5 本のデータセット仕様を記載します。各データセットは Supabase 上では `analytics` スキーマ配下のビュー／マテリアライズドビューとして公開し、`fn_export_csv(dataset_id, params jsonb)` から呼び出します。

### 1. 売上明細 (sales_line_items.csv)

| 項目 | 内容 |
| --- | --- |
| ファイル名 | `sales_line_items.csv` |
| ビュー | `analytics.sales_line_items_view` |
| 主キー | `(org_id, location_id, order_id, line_id)` |
| 並び順 | `business_date ASC, ordered_at ASC, line_sequence ASC` |
| 主用途 | 売上計上、人気メニュー分析、時帯別集計 |

#### カラム定義

| 列名 | 型 | 必須 | ソース / ロジック | 説明 |
| --- | --- | --- | --- | --- |
| `org_id` | uuid | ✔ | `orders.org_id` | 事業者識別子 |
| `location_id` | uuid | ✔ | `orders.location_id` | 店舗識別子 |
| `business_date` | date | ✔ | `ordered_at::date` | 営業日 (タイムゾーン補正後) |
| `order_id` | uuid | ✔ | `orders.id` | 注文 ID |
| `line_id` | uuid | ✔ | `order_items.id` | 注文明細 ID |
| `line_sequence` | integer | ✔ | `order_items` の `created_at` 昇順で採番 | 行表示順 |
| `order_number` | text |  | `orders.order_number` | 伝票番号。未運用の場合は null |
| `order_status` | text | ✔ | `orders.status` | `in_progress` / `completed` / `cancelled` |
| `channel` | text |  | `orders.channel` (将来拡張) | 店内 / デリバリー等。未指定は `in_store` |
| `table_no` | text |  | `orders.table_number` (想定列) | 着席テーブル。テーブル管理未利用なら null |
| `menu_item_id` | uuid | ✔ | `order_items.menu_item_id` | メニュー ID |
| `menu_item_code` | text |  | `menu_items.external_code` | 外部 POS 連携コード (任意) |
| `menu_item_name` | text | ✔ | `menu_items.name` | メニュー名 |
| `menu_category_id` | uuid |  | `menu_items.category_id` | カテゴリ ID |
| `menu_category_name` | text |  | `menu_categories.name` | カテゴリ名 |
| `qty` | integer | ✔ | `order_items.quantity` | 注文数量 |
| `unit_price` | numeric(12,2) | ✔ | `order_items.unit_price` | 税抜価格 (円)。税込出力時は別列で調整 |
| `line_subtotal` | numeric(12,2) | ✔ | `qty * unit_price` | 割引・税計算前小計 |
| `discount_amount` | numeric(12,2) | ✔ | `orders.discount_amount` を数量比で按分 | 行別割引額 (負数) |
| `tax_rate` | numeric(5,2) |  | `menu_items.tax_rate` (想定) | 適用税率 (%) |
| `tax_amount` | numeric(12,2) | ✔ | `line_subtotal - discount_amount` × `tax_rate` | 消費税額 |
| `line_total` | numeric(12,2) | ✔ | `line_subtotal - discount_amount + tax_amount` | 税込合計 |
| `ordered_at` | timestamp with time zone | ✔ | `orders.ordered_at` | 注文受付時刻 |
| `served_at` | timestamp with time zone |  | `orders.completed_at` | 提供完了時刻 |
| `canceled_flag` | boolean | ✔ | `orders.status = 'cancelled'` | true の場合はキャンセル行 |
| `void_reason` | text |  | `orders.cancel_reason` (想定) | キャンセル理由 |
| `special_request` | text |  | `order_items.special_request` | アレルギー等の備考 |
| `options_json` | jsonb |  | `order_items.selected_options` | 選択オプション (キー=option_name) |
| `ordered_by` | uuid |  | `orders.user_id` | 操作ユーザー |
| `exported_at` | timestamp with time zone | ✔ | 共通列 | エクスポート時刻 |
| `export_job_id` | uuid | ✔ | 共通列 | ジョブ ID |

#### 派生ロジック・備考

- 割引の按分は `order_items.subtotal / Σsubtotal` 比率を用いる。端数は最後の行で調整。
- キャッシュレス還元など税区分が複数ある場合は、追加列 `tax_code` を拡張予定。
- 返品 (negative line) は `qty < 0` として表現し、`line_total` も負数で出力。

### 2. 仕入明細 (purchases_line_items.csv)

| 項目 | 内容 |
| --- | --- |
| ファイル名 | `purchases_line_items.csv` |
| ビュー | `analytics.purchases_line_items_view` |
| 主キー | `(org_id, location_id, purchase_id, line_id)` |
| 並び順 | `purchase_date ASC, supplier_name ASC, line_sequence ASC` |
| 主用途 | 仕入原価の確認、支払管理、賞味期限トラッキング |

#### カラム定義

| 列名 | 型 | 必須 | ソース / ロジック | 説明 |
| --- | --- | --- | --- | --- |
| `org_id` | uuid | ✔ | `purchases.org_id` | 事業者識別子 |
| `location_id` | uuid | ✔ | `purchases.location_id` | 店舗識別子 |
| `purchase_id` | uuid | ✔ | `purchases.id` | 仕入 ID |
| `line_id` | uuid | ✔ | `purchase_items.id` | 仕入明細 ID |
| `line_sequence` | integer | ✔ | `purchase_items.created_at` 順 | 行表示順 |
| `purchase_date` | date | ✔ | `purchases.purchase_date` | 仕入日 |
| `supplier_id` | uuid |  | `purchases.supplier_id` | 仕入先 ID |
| `supplier_name` | text |  | `suppliers.name` | 仕入先名称 |
| `po_number` | text |  | `purchases.po_number` | 発注番号。未運用なら null |
| `sku_id` | uuid | ✔ | `purchase_items.material_id` | SKU (材料) ID |
| `sku_code` | text |  | `materials.external_code` | 任意のコード体系 |
| `sku_name` | text | ✔ | `materials.name` | 材料名 |
| `unit_of_measure` | text | ✔ | `materials.unit_type` | `piece` / `gram` 等 |
| `conversion_ratio` | numeric(12,3) |  | 在庫単位↔購入単位の換算率 | 例: 1 ケース = 12 本 |
| `qty` | numeric(12,3) | ✔ | `purchase_items.quantity` | 購入数量 (仕入単位) |
| `stock_qty` | numeric(12,3) | ✔ | `qty * conversion_ratio` | 在庫単位換算数量 |
| `unit_cost` | numeric(12,2) | ✔ | `purchase_items.unit_cost` | 単価 (税抜) |
| `ext_cost` | numeric(12,2) | ✔ | `qty * unit_cost` | 小計 |
| `tax_amount` | numeric(12,2) | ✔ | `ext_cost × tax_rate` | 消費税額 |
| `tax_rate` | numeric(5,2) |  | `purchases.tax_rate` | 税率 (%) |
| `currency` | text | ✔ | `purchases.currency` (デフォルト `JPY`) | 通貨コード |
| `batch_no` | text |  | `purchase_items.batch_no` | ロット番号 |
| `expiry_date` | date |  | `purchase_items.expiry_date` | 消費/賞味期限 |
| `received_by` | uuid |  | `purchases.received_by` | 受領担当者 |
| `notes` | text |  | `purchase_items.notes` | 備考 |
| `exported_at` | timestamp with time zone | ✔ | 共通列 | エクスポート時刻 |
| `export_job_id` | uuid | ✔ | 共通列 | ジョブ ID |

#### 派生ロジック・備考

- 締処理での原価計算は `stock_qty` を利用して在庫単位で管理する。
- 税率が行ごとに異なる場合は、将来的に `tax_code` 列で区別する。
- `unit_cost` が未入力の場合は `materials.last_purchase_unit_cost` をフォールバックする。

### 3. 在庫トランザクション (inventory_movements.csv)

| 項目 | 内容 |
| --- | --- |
| ファイル名 | `inventory_movements.csv` |
| ビュー | `analytics.inventory_movements_view` |
| 主キー | `(org_id, location_id, tx_id)` |
| 並び順 | `tx_time ASC` |
| 主用途 | 実地棚卸の照合作業、在庫差異分析、リアルタイム監査 |

#### カラム定義

| 列名 | 型 | 必須 | ソース / ロジック | 説明 |
| --- | --- | --- | --- | --- |
| `org_id` | uuid | ✔ | `stock_transactions.org_id` | 事業者識別子 |
| `location_id` | uuid | ✔ | `stock_transactions.location_id` | 店舗識別子 |
| `tx_id` | uuid | ✔ | `stock_transactions.id` | トランザクション ID |
| `tx_time` | timestamp with time zone | ✔ | `stock_transactions.created_at` | 取引発生時刻 |
| `business_date` | date | ✔ | `tx_time::date` | 営業日 |
| `tx_type` | text | ✔ | `stock_transactions.transaction_type` | `purchase` / `sale` / `adjustment` / `waste` |
| `ref_type` | text |  | `stock_transactions.reference_type` | 参照元 (`order` 等) |
| `ref_id` | uuid |  | `stock_transactions.reference_id` | 参照レコード ID |
| `sku_id` | uuid | ✔ | `stock_transactions.material_id` | SKU ID |
| `sku_name` | text | ✔ | `materials.name` | 材料名 |
| `unit_of_measure` | text | ✔ | `materials.unit_type` | 単位 |
| `quantity_delta` | numeric(12,3) | ✔ | `stock_transactions.change_amount` | 在庫増減 (正=入庫) |
| `quantity_after` | numeric(12,3) |  | 在庫スナップショット | 取引後の在庫水準。ロールアップで算出 |
| `reason_code` | text |  | `stock_transactions.reason` | 廃棄／調整理由 |
| `notes` | text |  | `stock_transactions.notes` | 備考 |
| `performed_by` | uuid |  | `stock_transactions.user_id` | 操作ユーザー |
| `exported_at` | timestamp with time zone | ✔ | 共通列 | エクスポート時刻 |
| `export_job_id` | uuid | ✔ | 共通列 | ジョブ ID |

#### 派生ロジック・備考

- `quantity_after` は Supabase 側でウィンドウ関数 `sum(quantity_delta) over (partition by org, location, sku order by tx_time)` を用いて算出する。
- `tx_type = 'sale'` の行は `sales_line_items_view` とキーで連携可能 (order_id/line_id)。

### 4. 廃棄ログ (waste_log.csv)

| 項目 | 内容 |
| --- | --- |
| ファイル名 | `waste_log.csv` |
| ビュー | `analytics.waste_log_view` |
| 主キー | `(org_id, location_id, waste_id)` |
| 並び順 | `waste_time ASC` |
| 主用途 | 廃棄原価の算出、ロス率の分析、原因分類 |

#### カラム定義

| 列名 | 型 | 必須 | ソース / ロジック | 説明 |
| --- | --- | --- | --- | --- |
| `org_id` | uuid | ✔ | `waste_logs.org_id` | 事業者識別子 |
| `location_id` | uuid | ✔ | `waste_logs.location_id` | 店舗識別子 |
| `waste_id` | uuid | ✔ | `waste_logs.id` | 廃棄記録 ID |
| `waste_time` | timestamp with time zone | ✔ | `waste_logs.recorded_at` | 廃棄日時 |
| `business_date` | date | ✔ | `waste_time::date` | 営業日 |
| `sku_id` | uuid | ✔ | `waste_logs.material_id` | 材料 ID |
| `sku_name` | text | ✔ | `materials.name` | 材料名 |
| `unit_of_measure` | text | ✔ | `materials.unit_type` | 単位 |
| `qty` | numeric(12,3) | ✔ | `waste_logs.quantity` | 廃棄数量 |
| `unit_cost` | numeric(12,2) | ✔ | `materials.last_purchase_unit_cost` or `waste_logs.unit_cost` | 廃棄時点原価 |
| `waste_cost` | numeric(12,2) | ✔ | `qty * unit_cost` | 廃棄原価 |
| `reason` | text | ✔ | `waste_logs.reason_code` | `expired` / `prep_error` / `leftover` / `damage` |
| `lot_no` | text |  | `waste_logs.lot_no` | ロット番号 |
| `recorded_by` | uuid | ✔ | `waste_logs.user_id` | 記録担当者 |
| `notes` | text |  | `waste_logs.notes` | 備考 |
| `linked_order_id` | uuid |  | `waste_logs.order_id` | 返品に紐づく注文 ID |
| `exported_at` | timestamp with time zone | ✔ | 共通列 | エクスポート時刻 |
| `export_job_id` | uuid | ✔ | 共通列 | ジョブ ID |

#### 派生ロジック・備考

- 原価は最新仕入単価を既定とし、廃棄記録に単価が入力されていればそちらを優先する。
- `reason` は Enum `expired` / `prep_error` / `leftover` / `damage` に統一。追加理由はコード表で管理。

### 5. メニュー工学 日次集計 (menu_engineering_daily.csv)

| 項目 | 内容 |
| --- | --- |
| ファイル名 | `menu_engineering_daily.csv` |
| ビュー | `analytics.menu_engineering_daily_view` |
| 主キー | `(org_id, location_id, business_date, menu_item_id)` |
| 並び順 | `business_date ASC, contribution_margin DESC` |
| 主用途 | メニュー工学分析 (人気 × 収益性)、日次ダッシュボード連携 |

#### カラム定義

| 列名 | 型 | 必須 | ソース / ロジック | 説明 |
| --- | --- | --- | --- | --- |
| `org_id` | uuid | ✔ | `orders.org_id` | 事業者識別子 |
| `location_id` | uuid | ✔ | `orders.location_id` | 店舗識別子 |
| `business_date` | date | ✔ | オーダー集計日 |
| `menu_item_id` | uuid | ✔ | `menu_items.id` | メニュー ID |
| `menu_item_code` | text |  | `menu_items.external_code` | 外部コード |
| `menu_item_name` | text | ✔ | `menu_items.name` | メニュー名称 |
| `menu_category_id` | uuid |  | `menu_items.category_id` | カテゴリ ID |
| `menu_category_name` | text |  | `menu_categories.name` | カテゴリ名 |
| `sales_qty` | integer | ✔ | `SUM(order_items.quantity)` | 日次販売数量 |
| `sales_amount` | numeric(12,2) | ✔ | `SUM(line_total)` | 売上金額 (税込 or 税抜をビューで統一) |
| `avg_price` | numeric(12,2) | ✔ | `sales_amount / NULLIF(sales_qty,0)` | 平均販売単価 |
| `food_cost` | numeric(12,2) | ✔ | `sales_qty × recipe_unit_cost` | 原価合計 |
| `recipe_unit_cost` | numeric(12,2) | ✔ | レシピ原価 (yield 補正後) |
| `contribution_margin` | numeric(12,2) | ✔ | `sales_amount - food_cost - variable_cost` | 限界利益 |
| `cm_rate` | numeric(5,4) | ✔ | `contribution_margin / NULLIF(sales_amount,0)` | 限界利益率 |
| `share_qty` | numeric(5,4) | ✔ | `sales_qty / Σsales_qty` | 販売数量シェア |
| `popularity_quadrant` | text | ✔ | `CASE WHEN share_qty >= threshold AND cm_rate >= threshold ...` | メニュー工学4象限 (Star等) |
| `waste_qty` | numeric(12,3) |  | `waste_logs` 連携 | 同メニュー起因の廃棄数量 |
| `exported_at` | timestamp with time zone | ✔ | 共通列 | エクスポート時刻 |
| `export_job_id` | uuid | ✔ | 共通列 | ジョブ ID |

#### 派生ロジック・備考

- `recipe_unit_cost` はレシピ表 (`recipes`) と材料最新単価を結合して算出。歩留まり (`yield_rate`) を考慮する。
- `variable_cost` は Phase 1 では 0 固定。Phase 2 で包装材／人件費配賦を検討。
- `popularity_quadrant` の閾値は店舗별設定を `export_params` の JSON で受け取る設計とする。

## コード表・辞書データ

CSV エクスポートでは参照コードの辞書を別ファイルとして提供する。最低限以下を整備する。

| ファイル名 | 内容 | 主キー |
| --- | --- | --- |
| `category_master.csv` | メニューカテゴリ、材料カテゴリのマスタ。`category_id`, `category_type`, `name`, `display_order` | `(category_id)` |
| `reason_master.csv` | 廃棄理由や在庫調整理由のコードセット。`reason_code`, `reason_type`, `display_name`, `description` | `(reason_code)` |
| `tax_master.csv` | 税区分。`tax_code`, `tax_rate`, `description`, `is_default` | `(tax_code)` |

> **運用ルール**: マスタ CSV はアプリ内コードと整合させるため、Supabase の `*_master` テーブルと 1:1 対応させる。更新時は ExportService 側でハッシュ値を比較し、変更があった場合のみ再出力する。

## フィルタとバリデーション

- `date_from` / `date_to` は必須。範囲は最大 31 日 (デフォルト) とし、それ以上は `400 Bad Request` を返す。
- `location_id` 未指定時は、ユーザーがアクセス可能な全店舗を対象にするが、出力ファイル名に `all_locations` を付与する。
- 各ビューは `org_id` で必ずフィルタリングし、他テナントのデータが混在しないよう Row Level Security を徹底する。

## 今後の拡張候補

- Phase 2 以降のデータセット (例: `inventory_snapshot.csv`, `purchase_price_history.csv`) は本ドキュメントのフォーマットに沿って追記する。
- Supabase RPC 側で `export_manifest.json` を返却し、複数ファイルの依存関係を明示する仕組みを検討。
- 将来的に `exported_at` と `export_job_id` の代わりに `export_batch_id` を導入し、複数ファイルを束ねた一括エクスポートをトラッキングできるようにする。

---

本辞書に関する改善提案やデータ項目の追加要望は `#yata-data-export` チャンネル、または `docs/plan/2025-10-02-csv-export-implementation-plan.md` の更新で管理してください。
