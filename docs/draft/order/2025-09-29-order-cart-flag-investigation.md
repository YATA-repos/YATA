# カート状態フラグ導入の現状調査メモ

- 日付: 2025-09-29
- 作成者: GitHub Copilot
- 関連タスク: "注文履歴から未会計カートを除外する" 機能検討

## 1. 背景

アプリ起動直後または最初のカート操作時に、Supabase の `orders` テーブルへ「下書き注文（カート）」が即時作成される。これらのレコードは `status = in_progress`、`order_number = null`、`total_amount = 0` 等の未確定値を保持したまま残り、注文履歴や集計処理に混入する。

現状の UI / サービス層では下記のような挙動を取る:

- `OrderManagementController._ensureCart()` は初回操作で `CartService.getOrCreateActiveCart()` を呼び出し、新規注文レコードを生成。
- `CartManagementService.getOrCreateActiveCart()` は `OrderRepository.create()` を呼び出し、即座に Supabase へ挿入。
- 会計 (`checkout`) 完了時にも `getOrCreateActiveCart()` が呼び出され、新たなカート用注文レコードが自動発行される。

結果としてデータベース上に「まだ会計されていないカート」が多数存在し、注文履歴画面や分析機能でノイズとなっている。

## 2. 現行仕様の整理

| 項目 | 現状 | 課題 |
| --- | --- | --- |
| カート判定基準 | `status = in_progress`, `order_number = null` の組み合わせ | 過去の実注文が同条件になり得る可能性があり、明確な識別子がない |
| 注文履歴 (`OrderHistoryController`) | 取得 API にフィルター無しで `OrderStatusMapper.normalize(order.status)` をそのまま表示 | 未会計カートが表示され、履歴が汚れる |
| サービス層 | カート操作は全て DB 上の `orders` レコードに対して直接実行 | ローカルキャッシュが無いため、カート判定のための追加情報は DB 側に持たせる必要がある |
| 分析・在庫連携 | 将来の在庫分析も `orders` テーブルを参照する設計 | フラグを導入しないと、未確定レコードが集計の妨げになる |

## 3. フラグ導入の方向性

### 3.1 候補案

1. **専用ブール列 `is_cart` を追加**
   - カート生成時に `true` をセットし、会計成功時に `false` に更新。
   - 注文履歴・分析では `is_cart = false` を条件に追加。
2. **`order_lifecycle` のような enum 列を追加**
   - `cart | finalized | canceled` など。状態遷移の柔軟性が高い一方で、導入が大掛かり。
3. **関連テーブル分離 (`cart_orders` テーブル)**
   - 既存アーキテクチャ（UI→Service→Repository 直線）との整合を取るには大改修が必要。現段階では除外。

### 3.2 推奨案

- 最小変更で導入できる **`is_cart` ブール列** 案を採用するのが現実的。
- Supabase マイグレーションでは既存レコードを一括更新し、`order_number IS NULL` & `status = 'in_progress'` のものだけ `true` にセットする。
- アプリケーション側は `Order` モデルに `@JsonKey(defaultValue: false)` で `isCart` を追加し、`CartManagementService` / `OrderManagementService` で適切に更新する。

## 4. 想定される変更点

| レイヤー | 変更例 |
| --- | --- |
| データベース | `orders` に `is_cart boolean not null default false` を追加。既存データの初期化クエリを用意。 |
| モデル (`Order`) | `bool isCart` フィールドを追加。`json_serializable` 対応。 |
| リポジトリ | `findActiveDraftByUser` などに `is_cart = true` の条件を追加。 |
| サービス | `CartManagementService.getOrCreateActiveCart` で `is_cart = true` を設定し、`checkoutCart` 完了時に `false` へ更新。 |
| UI | 注文履歴コントローラで `isCart` が `true` のものを除外。必要に応じてフィルター UI も拡張。 |
| テスト | 新フィールドの取り扱いとフィルタリングのテストケースを追加。 |

## 5. オープン課題

- Supabase マイグレーションの適用タイミング（本番データ初期化手順）。
- `is_cart` が `true` の注文をユーザーが閲覧できる導線が必要か（デバッグや調査用途）。
- `CartManagementService.clearCart` などで `is_cart` のまま `total_amount = 0` に戻す際の扱い。
- リアルタイム通知（`OrderService.startRealtimeMonitoring`）との連携可否。`is_cart = true` のイベントを購読側で無視する処理が必要か要検討。

## 6. 次のアクション

- `docs/plan/` に実装計画を作成し、作業ブレークダウンを明確化する。
- Supabase マイグレーション担当と連携し、テーブル変更案をレビュー。
- UI フロー（履歴、分析、キッチン表示）で `is_cart` をどこまで利用するか議論。
