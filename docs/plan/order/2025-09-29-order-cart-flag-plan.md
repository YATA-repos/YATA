# カート状態フラグ導入計画（2025-09-29）

- 対象タスク: Order-Feature-2
- 作成者: GitHub Copilot
- 関連メモ: `../draft/2025-09-29-order-cart-flag-investigation.md`

## 1. 目的

注文テーブルに「カート（未会計）」状態を明示するフラグを追加し、注文履歴・分析・リアルタイム監視から未確定注文を除外できるようにする。これにより、アプリ起動直後に生成される空注文が履歴を汚す問題を解消し、将来的な会計フロー拡張にも備える。

## 2. スコープ

### 含む
- Supabase `orders` テーブルへの `is_cart` ブール列追加とマイグレーション。
- `Order` モデルおよび関連シリアライズ処理への `isCart` フィールド追加。
- リポジトリ／サービス／コントローラでの `is_cart` 参照ロジック実装。
- 注文履歴・分析系取得処理でのフィルタリング更新。
- 主要テストコードの修正（モデル、サービス、プレゼンテーション）。
- 影響範囲のドキュメント更新（guide/reference などは別タスクに分割しても可）。

### 含まない
- 完全なローカルカート実装（DB 書き込み遅延）。
- 支払い方法やステータス enum の再設計（別計画 `2025-09-28-order-status-unification-plan.md` を参照）。
- 既存レポート機能以外への拡張。

## 3. 現状整理

- `CartManagementService.getOrCreateActiveCart` がカート生成時に DB へ即挿入。
- `OrderManagementService.checkoutCart` は成功後に `getOrCreateActiveCart` を再呼び出し、新品のカートを発行。
- `OrderHistoryController` は `OrderStatus` のみでフィルタし、カートかどうかの判別が無い。
- リアルタイム監視 (`OrderManagementService.startRealtimeMonitoring`) は `orders` テーブルのイベントをすべて受け取る。

詳細な調査は `docs/draft/2025-09-29-order-cart-flag-investigation.md` を参照。

## 4. 実装方針

1. **DB スキーマ変更**
   - `ALTER TABLE orders ADD COLUMN is_cart boolean NOT NULL DEFAULT false;`
   - 既存レコードの初期値更新: `UPDATE orders SET is_cart = true WHERE order_number IS NULL AND status IN ('in_progress', 'pending', 'preparing');`
   - Supabase migration スクリプトを `supabase/migrations` に追加（`docs/guide/migrations/order_cart_flag_migration.md` に適用手順を記載）。

2. **モデル更新**
   - `Order` クラスに `bool isCart;` を追加し、`@JsonKey(name: "is_cart", defaultValue: false)` を設定。
   - `OrderModel.g.dart` 再生成 (`flutter pub run build_runner build`).

3. **リポジトリ改修**
   - `OrderRepository.findActiveDraftByUser` などカート関連ロジックに `is_cart = true` 条件を追加。
   - カート以外を取得するメソッドでは `is_cart = false` を明示。

4. **サービス更新**
   - `CartManagementService.getOrCreateActiveCart` で `is_cart: true` を挿入。
   - `OrderManagementService.checkoutCart` 完了時に `is_cart` を `false` に更新。
   - `CartManagementService.clearCart` などカート継続時は `is_cart` を変更しない。

5. **UI / コントローラ調整**
   - `OrderHistoryController.loadHistory` で `is_cart = false` を条件に追加。
   - 必要に応じてフィルタ UI に「未会計を含める」オプションを追加（初期リリースでは除外のみで可）。

6. **リアルタイム監視**
   - `OrderManagementService._handleOrderUpdate` などで `is_cart = true` イベントを無視するか、ログレベルを下げる。
   - 将来的にキッチンボードで未確定注文を表示する必要があるか検討。

7. **テスト整備**
   - モデルの JSON 変換テスト追加。
   - サービスの動作テスト（カート生成・チェックアウト時の `is_cart` 更新）。
   - `OrderHistoryController` のフィルタリングテストに `is_cart` ケースを追加。

## 5. タスクブレークダウン

| No. | カテゴリ | 内容 | 担当 | 見積り |
| --- | --- | --- | --- | --- |
| 1 | DB | Supabase マイグレーション作成・適用手順ドキュメント化 | TBD | 1d |
| 2 | モデル | `Order` モデルと生成コード更新 | TBD | 0.5d |
| 3 | リポジトリ | `OrderRepository` カート系メソッド改修 | TBD | 0.5d |
| 4 | サービス | `CartManagementService`, `OrderManagementService` 調整 | TBD | 1d |
| 5 | UI | `OrderHistoryController` などのフィルタ更新 | TBD | 0.5d |
| 6 | テスト | モデル・サービス・UI テスト修正 | TBD | 1d |
| 7 | Docs | guide/reference の更新、リリースノート草案 | TBD | 0.5d |

## 6. リスクと対策

| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| 既存レコードの分類ミス | 過去の実注文がカート扱いになる | マイグレーション前に `order_number IS NULL かつ total_amount = 0` のレコードを手動レビュー |
| `is_cart` 更新漏れ | カートが履歴に残り続ける | サービス層で `checkout` 成功時の更新をユニットテストで担保 |
| リアルタイム連携 | カートイベントが不要な通知を発生させる | クライアント側で `is_cart` を確認し無視する処理を追加 |
| 依存コードの見落とし | カスタムクエリ等で `is_cart` 条件を追加し忘れる | `grep` で `orders` テーブル参照箇所を洗い出しレビュー |

## 7. 受け入れ条件

- `orders` テーブルに `is_cart` 列が存在し、カート生成時は `true`、会計後は `false` に更新される。
- 注文履歴 UI は `is_cart = false` の注文のみ表示する。
- 既存テストおよび新規テストがすべて成功する。
- Supabase migration の適用手順が README または関連ドキュメントに追記されている。

## 8. 次のステップ

1. マイグレーションとモデル更新の PoC をローカルで実施。
2. フロント・バック双方の影響範囲レビューを通し、追加の要望がないか確認。
3. 実装ブランチ `feature/order-cart-flag` を作成し、タスク順に着手。
4. 実装後、QA 環境で注文履歴・分析の挙動を検証。
