# 注文管理フロー パフォーマンス調査レポート（2025-10-08）

## 背景
- `_logs/app-20251008-04.log` を対象に、注文管理 UI の一連の操作（初期読み込み → カート操作 → 会計）へユーザーが体感した遅延の原因を確認した。
- 調査契機は UI レベルで 1〜3 秒台の待ち時間が発生しているという報告。
- 解析にはログに記録されている `flow_id` / `span_id` / `eventId` を活用し、処理ごとのタイムスタンプ差分から実行時間を算出した。

## 調査範囲と方法
- 対象ログ: `_logs/app-20251008-04.log`（2025-10-08T13:11Z 前後、開発環境）
- 対象フロー:
  1. `ui.order.load_initial_data`（初回ロード）
  2. `ui.order.add_menu_item`（カート追加）
  3. `ui.order.update_item_quantity`（数量を 1→3 に段階増加）
  4. `ui.order.update_payment_method`
  5. `ui.order.checkout`
- 分析手法:
  - `ts` の差分から UI 表示までの体感時間を算出。
  - 同一フロー内のサブサービス（`AuthService`、`CartManagementService`、`OrderInventoryIntegrationService` など）の時系列を追い、ボトルネック候補を抽出。
  - `QueryUtils` の `Qxxxxx` シーケンスから Supabase への往復回数を推定。

## 主な計測結果
| フロー | 所要時間 (UI) | 主な発生時刻 | 主要なサブフェーズ | 備考 |
| --- | --- | --- | --- | --- |
| 初期読み込み<br>`ui.order.load_initial_data` | **3113 ms** | 13:11:46.375 → 13:11:48.698 | 1) `AuthService` セッション再同期 (972 ms)<br>2) カテゴリ/メニュー/カート取得（`QueryUtils` Q00001〜Q00003, 約1.1 s） | 開始直後に `AuthService` が同期を要求し、Supabase リクエストが完了するまで UI が待機。 |
| カートにメニュー追加<br>`ui.order.add_menu_item` | **1242 ms** | 13:11:54.719 → 13:11:55.958 | 1) アクティブカート検索 (Q00004, 150 ms)<br>2) 新規カート生成 (Q00005, 243 ms)<br>3) 在庫確認・計算 (Q00006〜Q00012, 合計 ~640 ms) | 在庫確認フローが完全シリアルで 7 回の Supabase クエリを実行。 |
| 数量更新 (1→2)<br>`ui.order.update_item_quantity` | **572 ms** | 13:11:57.348 → 13:11:57.918 | 1) カート＆アイテム読み出し (Q00013〜Q00016)<br>2) 在庫再確認 (Q00017〜Q00020)<br>3) 合計更新 | 4 ステップで 8 クエリを直列実行。 |
| 数量更新 (2→3)<br>`ui.order.update_item_quantity` | **597 ms** | 13:11:58.458 → 13:11:59.055 | ほぼ同構成 | 追加増分でも全クエリを再実行。 |
| 支払い方法更新<br>`ui.order.update_payment_method` | **312 ms** | 13:12:01.389 → 13:12:01.700 | カート再取得 (Q00029〜Q00030) | 小さな操作でも毎回カート全体を再読込。 |
| 会計処理<br>`ui.order.checkout` | **1547 ms** | 13:12:01.978 → 13:12:03.526 | 1) カート読み出し & 在庫検証 (Q00031〜Q00038, ~700 ms)<br>2) 原材料消費計算 (Q00035〜Q00037, ~321 ms)<br>3) 合計計算と新カート発行 (Q00039〜Q00044, ~380 ms)<br>4) UI 初期化リロード (追加 378 ms) | Supabase への直列リクエストが 18 回発生。最終段の UI リロードでも再度カート探索が入り 5 クエリを消費。 |

## ボトルネック要約
1. **初期セッション更新の同期実行 (約 1.0 s)**
   - `AuthService` が起動直後に `Supabase session warm-up` を実行し、`tokenRefreshed` イベント完了まで UI がブロックされている。
   - ログ: `AuthService` `Supabase session warm-up started` (13:11:46.634) → `Session refreshed successfully` (13:11:47.606)。
2. **Supabase へのシリアルクエリ乱発**
   - 各操作が平均 6〜18 クエリを完全直列で実行している。`QueryUtils` のログから `user_id` フィルタが重複追加され「Skipping duplicate filter」が多発しており、フィルタ生成の重複とクエリ発行の冗長さが読み取れる。
   - 特に在庫チェックとカート集計 (`OrderInventoryIntegrationService` / `OrderCalculationService`) で、同一 `menu_item_id` に対して同じクエリが操作の度に再実行されている。
3. **カート再取得のオーバーヘッド**
   - ほぼ全アクションで `CartManagementService` が「アクティブカートを探す → 存在しなければ作る」を走らせており、会計完了後も新カート作成→初期読み込みが連鎖。（13:12:02.944 以降）

## 推奨アクション
| 優先度 | 内容 | 期待効果 | 根拠ログ |
| --- | --- | --- | --- |
| 高 | **セッション更新を非同期化またはキャッシュ有効期限を延ばす** | 初回表示の 1 秒短縮 | `AuthService` warm-up (13:11:46.634〜13:11:47.606) |
| 高 | **初期ロード用 RPC（Supabase Function）でカテゴリ＋メニュー＋カートを一括取得** | `load_initial_data` を 3.1 s → ~1.5 s へ短縮（クエリ並列化） | `QueryUtils` Q00001〜Q00003 の連続実行 |
| 中 | **在庫・価格計算での重複クエリ削減（キャッシュ or JOIN）** | カート追加/更新操作の 600 ms → 250 ms 程度を想定 | `OrderInventoryIntegrationService` による同一 `menu_item_id` 連続照会 (例: 13:11:55.133〜55.688) |
| 中 | **`CartManagementService.getOrCreateActiveCart` の再取得をメモ化** | 会計完了後の再ロード 378 ms 削減 | 13:12:03.146〜13:12:03.526 の再読込シーケンス |
| 低 | **`QueryUtils` での重複フィルタ抑制ロジック改善** | ログノイズ削減＋わずかな CPU 削減 | `Skipping duplicate filter` メッセージ群 |

## 今後の検証案
- Supabase RPC の PoC を作成し、同一データセットを 1 リクエストで返す API を検証。
- `OrderInventoryIntegrationService` に対し、Riverpod キャッシュまたはアプリ内メモリキャッシュでメニュー単価・在庫を短期保持する実験を行う。
- `AuthService` のトークン更新をバックグラウンド Future に切り出し、UI レベルでは既存セッションで即時応答できるかを検証。
- 計測の自動化として、主要フローの `duration_ms` をメトリクス収集サーバへ送る仕組み（例: Supabase Edge Functions + InfluxDB）を検討。

## 参考
- 元ログ: `_logs/app-20251008-04.log`
- 関連機能: `CartManagementService`, `OrderInventoryIntegrationService`, `OrderCalculationService`, `AuthService`
