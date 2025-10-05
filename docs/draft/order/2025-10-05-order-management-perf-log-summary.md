# 注文管理パフォーマンスログサマリ（2025-10-05）

- **観測結果**
  - `[OMPerf]` タグ付きログは本ファイルに存在せず、代替としてサービス層ログの開始・完了行を時系列で突き合わせて計測値を算出。
  - `CartManagementService.addItem`: 1件, 平均/中央値/最大 819ms (P95≈819ms)。
  - `CartManagementService.updateQuantity`: 2件, 平均 770ms, 中央 770ms, 最大 824ms, P95≈716ms。
  - `CartManagementService.updatePaymentMethod`: 1件, 239ms。
  - `OrderManagementService.retrieveOrderWithItems`: 16件, 平均 143ms, 中央 130ms, P95≈191ms, 最大 233ms。
  - `OrderManagementService.retrieveOrderDetails`: 16件, 平均 60ms, 中央 58ms, P95≈74ms, 最大 81ms。
  - ログ内のエラーは検出されず、10:16:20 の `OrderRepository` WARN で `order_status_enum` に `canceled` が流入し互換モード再取得が発生。

- **ボトルネック候補**
  - カート更新系（追加/数量変更）が 700ms 超と長く、同一操作内で Supabase クエリ（`QueryUtils` 連続呼び出し）が多重化していることが遅延要因と推測。
  - 注文取得処理の P95 が 50ms を大きく超過し（約191ms）、UI 更新や後続処理のレスポンス低下につながる可能性。
  - `canceled` → `cancelled` の互換処理により全件再取得が走っており、稼働中に同様のデータ汚染が増えると照会遅延が累積するリスク。

- **推奨アクション**
  - [1] `[OMPerf]` 計測の出力が欠落しているため、ロガー設定/フィルタリングの再確認と計測復帰を最優先で実施し、正確な操作別パフォーマンス指標を取得する。
  - [2] カート更新フローのサービス層を見直し、在庫チェック・計算クエリの並列化またはキャッシュ化（例: メニュー/在庫スナップショット保持）により 50ms 以内への短縮を検討する。
  - [3] `order_status_enum` の値不整合を修正（データ移行 + バリデーション強化）し、fallback クエリを排除してリクエスト毎の無駄な再走査を防止する。

---

**追記 (2025-10-05):** `.env` に `ORDER_MANAGEMENT_PERF_TRACING=true` を追加し、`OrderManagementTracer.configureFromEnvironment` でデバッグ時にトレーシングを強制有効化できるよう調整済み。以降の計測で `[OMPerf]` 出力が復帰する想定。
