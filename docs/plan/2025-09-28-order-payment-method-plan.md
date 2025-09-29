# 会計時の支払い方法選択 実装計画（2025-09-28）

- 対象タスク: Order-Feature-1
- 目的: 会計フローで支払い手段を選択・保存し、履歴から追跡できるようにする。
- 関連領域: `lib/features/order` 配下の UI / 状態管理 / サービス / リポジトリ、および Supabase `orders` テーブル

## 現状整理

### モデル / データ
- `PaymentMethod` 列挙（`cash` / `card` / `other`）は `lib/core/constants/enums.dart` に定義済み。
- `Order` / `OrderItem` モデル（`lib/features/order/models/order_model.dart`）は `paymentMethod` フィールドを保持し、JSON シリアライズも対応済み。
- `OrderCheckoutRequest`（`lib/features/order/dto/order_dto.dart`）は `paymentMethod` を必須入力として受け取る。
- Supabase テーブル `orders.payment_method` カラムは既存想定。互換性確認が未実施のため、本実装前にスキーマと既存データの値整合性をレビューする必要がある。

### UI / 状態管理
- `OrderManagementState` / `OrderManagementController`（`presentation/controllers/order_management_controller.dart`）に支払い方法を表すフィールドが存在せず、`checkout()` 時に `PaymentMethod.cash` を固定値として送信している。
- 会計画面（`presentation/pages/order_management_page.dart`）にも支払い手段を選択する UI がない。
- カート取得処理 `_loadCartSnapshot` では `Order.paymentMethod` を読み込んでいないため、バックエンド側が値を持っていても UI に反映されない。
- 注文履歴画面（`order_history_page.dart`）では `paymentMethod` をラベル表示しており、履歴側の表示は受け入れ準備済み。

### サービス / リポジトリ
- `OrderManagementService.checkoutCart` は `request.paymentMethod.value` を `orders.payment_method` に保存している。
- `CartManagementService.getOrCreateActiveCart` で新規下書き注文を作成する際、`paymentMethod` を `PaymentMethod.cash` に初期化している。
- カート更新用のサービス API に支払い方法を更新する手段がないため、選択内容を確定するには checkout 時のリクエストに頼るのみとなっている。

## 目的
1. 会計画面で `PaymentMethod` を選択できる UI を提供する。
2. 選択した支払い方法がカート状態に保持され、checkout 時に Supabase へ保存される。
3. 注文履歴および詳細表示で保存された支払い方法が正しく表示されることを保証する。
4. 将来的な決済手段拡張（例: QR 決済追加）が容易な状態管理・サービス構造を整備する。

## スコープ

### 含む
- `OrderManagementState` / `OrderManagementController` への `selectedPaymentMethod`（仮称）追加と同期処理。
- 会計画面 UI における支払い方法選択コンポーネント実装（選択肢: 現金 / カード / その他）。
- カート存在時に既存の `payment_method` 値を読み込み初期選択を反映する処理。
- カート内支払い方法を更新するサービス層 API 追加と、選択操作時の永続化。
- checkout フローで選択値を `OrderCheckoutRequest` に渡し、`OrderManagementService` へ保存する処理確認。
- ユニットテスト / ウィジェットテスト / サービステストの整備。
- ドキュメント更新（本計画、必要に応じて `docs/guide/order/` などへの追記）。

### 含まない
- 新たな支払い手段の追加や、`PaymentMethod` enum の拡張。
- 外部決済サービス連携（例: カード決済 API との接続）。
- 既存注文履歴データのマイグレーション作業（必要時は別タスク化）。

## 実装フェーズ

### Phase 1: 状態管理・データ取得の下準備
- `OrderManagementState` に `PaymentMethod currentPaymentMethod` プロパティを追加。`OrderManagementState.initial()` は `PaymentMethod.cash` をデフォルトにするが、ロード時にカートの値で上書きする。
- `_CartSnapshot` や `_loadCartSnapshot()` に `order.paymentMethod` を取り込み、状態へ反映。
- `loadInitialData()` と `_refreshCart()` の完了後に `state` の支払い方法が最新化されることを確認。

### Phase 2: 選択 UI と操作イベント
- `order_management_page.dart` の現在の注文セクションに、`PaymentMethod` 選択 UI（Radio / Segmented control / Dropdown）の配置を追加。モバイルとデスクトップ双方で視認性・操作性を考慮した配置にする。
- UI 変更時に `OrderManagementController.updatePaymentMethod(PaymentMethod method)`（新規メソッド）を呼び出し、`state` とバックエンド側のカート状態を更新する。
- 選択 UI には現在の選択状態、操作不可条件（例: checkout 中・カート初期化中）を連動させる。

### Phase 3: 永続化と checkout フロー連携
- `CartManagementService` にアクティブカートの支払い方法を更新する API（例: `updateCartPaymentMethod(String cartId, PaymentMethod method, String userId)`）を追加し、`OrderRepository.updateById` を通じて Supabase に反映する。
- `CartService` にも委譲メソッドを追加し、`OrderManagementController.updatePaymentMethod` から呼べるようにする。
- `OrderCheckoutRequest` 生成箇所を `state.currentPaymentMethod` を参照するよう変更。
- 会計成功後、新しいカート (`result.newCart`) の `paymentMethod` を state に取り込み、UI 遷移後もデフォルトが維持されるようにする。

### Phase 4: 検証・テスト・ドキュメント
- Riverpod のユニットテストで `updatePaymentMethod` が状態とサービス呼び出しを正しく行うことを確認。
- サービス層のモックテストで `CartManagementService.updateCartPaymentMethod` が Supabase に正しい payload を渡すか検証。
- ウィジェットテスト（Golden / Interaction）で UI の選択操作とバリデーションを確認。
- 手動検証手順（在庫有り/無し、複数端末、再読込時の状態保持）を整理し、必要に応じて `docs/guide/order/` や `docs/reference/` に追加記載。

## 技術検討メモ
- `PaymentMethod` は enum なので、UI 側では `PaymentMethod.values` を列挙し、表示名は `order_history_page.dart` 同様のヘルパー関数を共通化する予定。共通化には `shared` 配下へ `PaymentMethod` のラベリングメソッドを移す案を検討。
- `CartManagementService` で支払い方法更新を行う場合、カートが存在しないケース（`null`）に備えて `getOrCreateActiveCart` を再利用するか、UI 操作を無効化する。
- Supabase で `payment_method` が `text` or `enum` か確認。不整合がある場合、Plan 内のリスク節に記載した migration 手順を別途起票する。
- 既存の `OrderManagementController.checkout()` では成功時に `loadInitialData(reset: true)` を呼ぶため、支払い方法も新カート状態に置き換えられる想定。

## テスト戦略
- **ユニット**: `OrderManagementController` の `updatePaymentMethod` / `checkout` を対象に、選択値が checkout request に反映されることを確認。
- **サービス**: `CartManagementService.updateCartPaymentMethod` が `OrderRepository.updateById` を期待通り呼び出すか（モックリポジトリで検証）。
- **ウィジェット**: 支払い方法 UI の選択操作が状態変更イベントを発火し、checkout ボタンのハンドラーに反映されることをテスト。
- **回帰**: 既存の `checkout` シナリオテスト（Order-Bugfix-3 計画で想定）の再実行により副作用がないことを確認。

## 受け入れ条件
- 会計画面で 3 種類の支払い方法から選択でき、選択内容が即座に UI に反映される。
- 選択値が Supabase `orders.payment_method` に保存され、履歴画面で表示される。
- 会計後に新しい注文を開始しても、直前に選んだ手段が保持または適切に初期化され（要件に応じて定義、デフォルトは現金）、二重変更が発生しない。
- `flutter analyze` / `flutter test` がグリーンで完了する。

## リスクと緩和策

| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| Supabase 側で `payment_method` カラムが欠損・enum 不一致 | 会計処理が失敗、または値が保存されない | 実装前に Supabase スキーマを検証。必要であれば migration を別タスク化し先行実施。 |
| UI の状態と Supabase の保存状態が乖離する | 会計時に意図しない支払い方法が保存される | 支払い方法更新 API を同期（await）で呼び出し、失敗時はスナックバー等でユーザーに再入力を促す。 |
| 複数端末で同一ユーザーがカートを操作した場合の競合 | 上書き競合で意図しない値が保存される | `updated_at` タイムスタンプを利用し、後勝ち運用を明記。必要に応じて追加のコンフリクト検出ロジックを検討。 |
| 将来の支払い方法追加時に UI レイアウトが破綻 | 拡張時の改修コスト増 | UI 実装を柔軟に（Flex / Wrap）しておき、新しい選択肢追加に耐えられる余裕を確保。 |

## 依存関係・準備事項
- Supabase スキーマレビュー（`orders.payment_method` の型・制約確認）。
- `docs/draft/` にある関連メモの確認（未整備なら本計画で補足）。
- Order-Bugfix-3 計画との整合性チェック（checkout フロー刷新の影響確認）。

## 次のアクション
1. Supabase スキーマ確認タスクを割り当て、必要に応じて migration の要否を判断する。
2. `feature/order-payment-method` ブランチを作成し、Phase 1 から順次実装を進める。
3. 実装開始前に本計画をレビューし、関係者（UI/バックエンド担当）からフィードバックを収集する。
4. 実装完了後、`docs/guide/order/` へ運用手順を追記する（必要に応じてシナリオベースの操作説明を追加）。
