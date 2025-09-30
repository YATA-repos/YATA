# 注文番号表示フロー調査メモ

- 日付: 2025-09-30
- 作成者: GitHub Copilot
- 関連タスク: 注文ページの注文番号表示調査

## 1. 背景と目的

注文管理画面（`lib/features/order/presentation/pages/order_management_page.dart`）で表示される注文番号が、どのように取得・生成されているのかを整理した。UI 上のバッジ表示と会計完了時の案内に使われる番号の入手元を明らかにし、サービス層〜リポジトリ層までの流れを俯瞰することが目的。

## 2. UI 側の表示ポイント

- 注文ページは `OrderManagementPage` が `orderManagementControllerProvider` から `OrderManagementState` を受け取る構成。
- 右ペインヘッダで `_OrderNumberBadge` が `state.orderNumber` を表示する。値が `null` または空文字のときはラベルを「未割り当て」にフォールバックする。
- 会計ボタンの完了ハンドラでは、`CheckoutActionResult.order?.orderNumber` を参照し、`SnackBar` に「注文番号 xxx」を含めて通知する。こちらは会計確定済みオーダーの番号で、バッジが示す「現在のカート」の番号とは切り離されていることに注意。

## 3. 注文番号の取得フロー

### 3.1 初期ロード

1. `OrderManagementController` 初期化時に `loadInitialData()` が走る。
2. `CartService.getActiveCart(userId)` が Supabase 上のアクティブカート（`orders.is_cart = true` の行）を取得。
3. カートが見つかった場合、`OrderService.getOrderWithItems(cartId, userId)` を通じて `OrderManagementService.getOrderWithItems()` が呼ばれ、`Order` と紐づく `OrderItem` 一覧を読み出す。
4. `_loadCartSnapshot()` が取得データを `_CartSnapshot` に詰め直し、`orderNumber`（`order.orderNumber`）を含めて `OrderManagementState` に流し込む。
5. UI は `state.orderNumber` を購読し、バッジ表示を更新する。

### 3.2 カート操作時の更新契機

- メニュー追加時などに呼ばれる `_ensureCart()` が `CartService.getOrCreateActiveCart()` を経由してカートを確保し、返却された `Order` の `orderNumber` をステートへ書き戻す。
- `clearCart()` → `_refreshCart()` でも `_loadCartSnapshot()` を再実行して最新番号を反映。
- `checkout()` 成功後は、一旦結果の `newCart` でステートを書き換えつつ、`loadInitialData(reset: true)` を再実行してバックエンドのカート状態を同期する。

## 4. 注文番号生成ロジック（会計時）

- 会計処理 `OrderManagementService.checkoutCart()` は `OrderRepository.generateNextOrderNumber()` を呼び出して一意な番号を生成する。
- `OrderRepository.generateNextOrderNumber()` は `OrderIdentifierGenerator.generateOrderNumber()` を利用し、`YYYYMMDDThhmmss+0900-<Base62 11桁>` 形式の文字列を生成。最大 5 回まで Supabase に対して重複チェックを行う。
- 生成した番号は `orders.order_number` カラムへ書き込み、同時に `is_cart` を `false` にして正式注文へ昇格させる。
- `checkoutCart()` の戻り値 `OrderCheckoutResult` に確定済みオーダー（`order`）と新しいカート（`newCart`）が含まれる。UI のスナックバーは前者の `orderNumber` を表示し、`OrderManagementState` の更新は後者で実施。

## 5. 補足・留意点

- カート段階では `order_number` が未設定のため、画面上は「未割り当て」表示がデフォルトとなる。会計後に新カートへ遷移しても引き続き未割り当てとなるのは仕様通り。
- `OrderManagementState.orderNumber` が「直近のカート番号」を示し、完了した注文番号を保持しない点を理解しておくとデバッグ時に混乱しにくい。
- 番号生成はサービス層より下位（リポジトリ＋ユーティリティ）で完結しているため、UI 側で追加の番号生成ロジックを実装する必要はない。
