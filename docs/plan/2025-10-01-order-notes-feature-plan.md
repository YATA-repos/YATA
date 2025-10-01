# 注文メモ機能 実装計画（2025-10-01）

- 対象タスク: Order-Feature-2
- 目的: 注文管理画面と注文履歴画面で、注文に対してメモを付与・表示できるようにする。
- 関連領域: `lib/features/order` 配下の UI / 状態管理 / サービス、および Supabase `orders` テーブル

## 現状整理

### モデル / データ
- `Order` モデル（`lib/features/order/models/order_model.dart`）は `notes` フィールドを保持済み。
  - 型: `String?`
  - JSON シリアライズ対応済み
- `OrderCheckoutRequest`（`lib/features/order/dto/order_dto.dart`）は `notes` を受け取る構造あり。
- Supabase テーブル `orders.notes` カラムは既存想定（問題文より）。

### UI / 状態管理
- `OrderManagementState` / `OrderManagementController`（`presentation/controllers/order_management_controller.dart`）:
  - メモを表す状態フィールドが存在しない。
  - `checkout()` 時に `OrderCheckoutRequest` の `notes` に `null` を固定で送信している（L649-652）。
  - カート取得処理 `_loadCartSnapshot` では `Order.notes` を読み込んでいない。
- 注文管理画面（`presentation/pages/order_management_page.dart`）:
  - メモ入力 UI が存在しない。
- 注文履歴画面（`presentation/pages/order_history_page.dart`）:
  - `order.notes` が存在する場合、詳細表示とカード表示の両方で「備考」として表示している（L450-467, L625-639）。
  - 表示実装は完了済み。
- 注文状況画面（`presentation/pages/order_status_page.dart`）:
  - `order.notes` を表示している（L283-287, L380-384, L457-461）。

### サービス / リポジトリ
- `OrderManagementService.checkoutCart` は `request.notes` を `orders.notes` に保存している（L64）。
- `CartManagementService`:
  - 新規カート作成時に `notes` を初期化していない（デフォルト `null`）。
  - カート更新用のメソッドに `notes` を更新する機能がない。
- `KitchenOperationService.adjustEstimatedCompletionTime`:
  - 完成予定時刻の調整理由を `notes` に追記する実装あり（L68-70）。
  - 既存の `notes` に追記する形で更新している。

## 目的
1. 注文管理画面でメモを入力できる UI を提供する。
2. 入力したメモがカート状態に保持され、checkout 時に Supabase へ保存される。
3. 注文履歴および注文状況画面で保存されたメモが正しく表示されることを保証する（既に実装済み）。
4. メモの編集・削除が可能な状態管理・サービス構造を整備する。

## スコープ

### 含む
- `OrderManagementState` / `OrderManagementController` への `currentNotes`（仮称）追加と同期処理。
- 注文管理画面 UI におけるメモ入力コンポーネント実装。
  - テキストフィールド（複数行対応）
  - 入力時のリアルタイム保存または明示的な保存ボタン
- カート存在時に既存の `notes` 値を読み込み初期表示を反映する処理。
- カート内メモを更新するサービス層 API 追加と、入力操作時の永続化。
- checkout フローで入力値を `OrderCheckoutRequest` に渡し、`OrderManagementService` へ保存する処理確認。
- ドキュメント更新（本計画、必要に応じて `docs/guide/order/` などへの追記）。

### 含まない
- 注文履歴・注文状況画面でのメモ表示機能（既に実装済み）。
- メモの履歴管理（編集履歴の保存）。
- メモのテンプレート機能。
- 既存注文のメモを後から編集する機能（将来的な拡張として検討）。

## 実装フェーズ

### Phase 1: 状態管理・データ取得の下準備
- `OrderManagementState` に `String? currentNotes` プロパティを追加。
  - `OrderManagementState.initial()` はデフォルトで `null` を設定。
  - ロード時にカートの値で上書きする。
- `_CartSnapshot` と `_loadCartSnapshot()` に `order.notes` を取り込み、状態へ反映。
- `loadInitialData()` と `_refreshCart()` の完了後に `state` のメモが最新化されることを確認。

### Phase 2: 入力 UI と操作イベント
- `order_management_page.dart` の現在の注文セクションに、メモ入力 UI の配置を追加。
  - 配置位置: カートアイテムリストの下部、合計金額表示の上
  - UI 要素: 複数行対応のテキストフィールド（`TextField` with `maxLines`）
  - ラベル: "備考・メモ"
  - プレースホルダー: "注文に関するメモを入力..."
- UI 変更時に `OrderManagementController.updateNotes(String? notes)`（新規メソッド）を呼び出し、`state` とバックエンド側のカート状態を更新する。
  - デバウンス処理を検討（頻繁な保存を避ける）
- 入力 UI には現在の入力状態、操作不可条件（例: checkout 中・カート初期化中）を連動させる。

### Phase 3: 永続化と checkout フロー連携
- `CartManagementService` にアクティブカートのメモを更新する API を追加。
  - メソッド名: `updateCartNotes(String cartId, String? notes, String userId)`
  - `OrderRepository.updateById` を通じて Supabase に反映する。
- `CartService` にも委譲メソッドを追加し、`OrderManagementController.updateNotes` から呼べるようにする。
- `OrderCheckoutRequest` 生成箇所を `state.currentNotes` を参照するよう変更（L649-652）。
- checkout 成功後、新しいカート (`result.newCart`) の `notes` を state に取り込み、UI 遷移後もデフォルトが維持されるようにする。

### Phase 4: 検証・テスト・ドキュメント
- Riverpod のユニットテストで `updateNotes` が状態とサービス呼び出しを正しく行うことを確認。
- サービス層のモックテストで `CartManagementService.updateCartNotes` が Supabase に正しい payload を渡すか検証。
- ウィジェットテスト（Interaction）で UI の入力操作とバリデーションを確認。
- 手動検証手順（複数注文での状態保持、再読込時の状態復元）を整理し、必要に応じて `docs/guide/order/` に追加記載。

## 技術検討メモ

### UI 配置とデザイン
- メモ入力フィールドは、既存の支払い方法選択 UI（`currentPaymentMethod`）の実装を参考にする。
- 配置位置の候補:
  1. カートアイテムリスト直下（合計金額の上）
  2. 支払い方法選択の近く
  3. checkout ボタンの近く
- モバイル・デスクトップ双方で視認性・操作性を考慮した配置にする。

### 保存タイミング
- リアルタイム保存 vs 明示的保存:
  - **推奨**: リアルタイム保存（デバウンス処理あり）
  - 理由: 支払い方法選択と同様、ユーザーが明示的に保存操作をする必要がないため
  - デバウンス時間: 500ms～1000ms を検討
- `CartManagementService.updateCartNotes` 呼び出し時の例外処理:
  - 失敗時はスナックバー等でユーザーに再入力を促す
  - state の値は更新せず、前回の正常値を保持

### 文字数制限
- Supabase の `notes` カラムの制約を確認する必要あり。
- UI 側でも文字数制限を設ける場合、最大文字数を検討（例: 500文字、1000文字）。
- 入力バリデーション: `InputValidator` を使用して文字数チェック。

### 既存実装との整合性
- `KitchenOperationService.adjustEstimatedCompletionTime` が `notes` に追記する実装があるため、上書きではなく追記の考慮が必要。
  - **方針**: 基本的には上書き保存とし、システム側の追記と区別する。
  - システム追記は `[...]` で囲むなど、ユーザー入力と区別できる形式にする。

## テスト戦略

### ユニットテスト
- `OrderManagementController` の `updateNotes` を対象に、選択値が state に反映され、サービスが呼ばれることを確認。
- checkout 時に `currentNotes` が `OrderCheckoutRequest` に含まれることを確認。

### サービステスト
- `CartManagementService.updateCartNotes` が `OrderRepository.updateById` を期待通り呼び出すか（モックリポジトリで検証）。

### ウィジェットテスト
- メモ入力 UI の入力操作が状態変更イベントを発火し、checkout ボタンのハンドラーに反映されることをテスト。

### 回帰テスト
- 既存の `checkout` シナリオテストの再実行により副作用がないことを確認。

## 受け入れ条件
- 注文管理画面でメモを入力でき、入力内容が即座に UI に反映される。
- 入力値が Supabase `orders.notes` に保存され、履歴画面・状況画面で表示される。
- checkout 後に新しい注文を開始しても、前回入力したメモがクリアされ、新しいカートのメモ（通常は空）が表示される。
- 長いメモ（複数行）を入力しても正しく保存・表示される。
- `flutter analyze` がグリーンで完了する（新規警告・エラーを追加しない）。

## リスクと緩和策

| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| Supabase 側で `notes` カラムが想定と異なる型・制約 | 保存処理が失敗、または値が保存されない | 実装前に Supabase スキーマを検証。 |
| UI の状態と Supabase の保存状態が乖離する | checkout 時に意図しないメモが保存される | メモ更新 API を同期（await）で呼び出し、失敗時はスナックバー等でユーザーに再入力を促す。 |
| デバウンス処理の不具合で保存されない | ユーザー入力が失われる | デバウンス実装を十分にテスト。checkout 前に強制保存を検討。 |
| 文字数制限を超えた入力 | 保存時にエラー | UI 側で文字数制限を設け、超過時は入力不可または警告表示。 |
| システム側の追記（`KitchenOperationService`）との競合 | ユーザー入力がシステム追記で上書きされる | システム追記は特定フォーマット（`[...]`）で区別し、上書きではなく追記とする。 |

## 依存関係・準備事項
- Supabase スキーマレビュー（`orders.notes` の型・制約・文字数上限確認）。
- `docs/draft/` にある関連メモの確認（未整備なら本計画で補足）。
- 支払い方法選択機能（Order-Feature-1）の実装パターンを参考にする。

## 参考資料
- TODO.md の Order-Feature-2 タスク定義
- `docs/plan/2025-09-28-order-payment-method-plan.md`: 支払い方法選択の実装計画（類似機能）
- `lib/features/order/services/kitchen_operation_service.dart`: `notes` への追記実装例

## 次のアクション
1. Supabase スキーマ確認タスクを割り当て、必要に応じて制約の確認・調整を行う。
2. `feature/order-notes` ブランチを作成し、Phase 1 から順次実装を進める。
3. 実装開始前に本計画をレビューし、関係者（UI担当）からフィードバックを収集する。
4. 実装完了後、`docs/guide/order/` へ運用手順を追記する（必要に応じてメモ入力のベストプラクティスを追加）。
