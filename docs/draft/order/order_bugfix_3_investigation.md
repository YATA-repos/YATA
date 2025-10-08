# Order-Bugfix-3 調査メモ

- 日付: 2025-09-28
- 対象タスク: Bugfix - 会計後にメニュー選択をリセットする (Order-Bugfix-3)
- 作成者: GitHub Copilot

## 1. 現状の挙動

- 会計ボタン (注文管理画面右下) は `lib/features/order/presentation/pages/order_management_page.dart` の `ElevatedButton.icon` 内で実装されており、押下時に `context.push("/history")` を呼び出すのみで、バックエンドのチェックアウト処理やカート初期化は呼ばれていない。
- そのため、会計後に注文管理ページへ戻ると、前回のカート内容・選択状態がそのまま残っており、新規注文を空状態から開始できない。
- `StateNotifierProvider` (`orderManagementControllerProvider`) は `autoDispose` 指定がなく、一度生成された `OrderManagementController` インスタンスがナビゲーション遷移後も保持されるため、UI状態も継続して残る。

## 2. コード調査結果

### 2.1 フロントエンド (注文管理ページ)
- `lib/features/order/presentation/pages/order_management_page.dart` では会計ボタン押下時の処理が `context.push("/history")` のみ。
- 注文コントローラ (`lib/features/order/presentation/controllers/order_management_controller.dart`) にはチェックアウトや会計完了をトリガーするメソッドが存在せず、`OrderService.checkoutCart` や `CartService.clearCart` を呼ぶ導線が無い。
- コントローラはコンストラクタで `loadInitialData()` を一度だけ実行し、アクティブなカートを読み込む。ページ離脱後もプロバイダが破棄されないため、メモリ上の `state` が維持される。

### 2.2 サービス層
- `OrderManagementService.checkoutCart` (`lib/features/order/services/order/order_management_service.dart`) は
  - バリデーション / 在庫確認後に `_orderRepository.generateNextOrderNumber()` を呼ぶが、戻り値を利用せず注文へ割り当てもしていない。
  - 注文の `status` を `OrderStatus.preparing` のまま更新しており、カートと正式注文の区別が付かない。
  - チェックアウト完了後に新しいカートを生成する処理は存在しない。
- ※ 2025-10-08 時点では UI 層は `OrderManagementService` を直接注入し、旧 `OrderService` ラッパは削除済み。

### 2.3 カート管理
- `CartManagementService.getActiveCart` (`lib/features/order/services/cart/cart_management_service.dart`) は `OrderRepository.findActiveDraftByUser()` を呼び出し、`status = preparing` の注文を「アクティブなカート」として再利用する。
- `OrderRepository.findActiveDraftByUser()` (`lib/features/order/repositories/order_repository.dart`) も `status = preparing` の最新注文を返すだけで、会計完了後に `completed` 等へステータスを変えない限り同じ注文が返る。
- `CartService.clearCart` は注文明細を削除し合計金額を 0 に戻すが、注文レコード自体や `CartManagementService` のキャッシュは更新しない。

### 2.4 状態管理 / ライフサイクル
- `orderManagementControllerProvider` が `autoDispose` ではないため、画面遷移でウィジェットがツリーから外れてもコントローラインスタンスは残存し、メモリ上のカート情報がリセットされない。
- さらに、画面へ戻っても `loadInitialData()` が再実行されないため、バックエンドで状態を修正しても UI が更新されない。

## 3. 根本原因の整理

1. **会計ボタンがチェックアウト処理を呼び出していない**: UI が `OrderManagementService.checkoutCart` を実行していないため、カートは正式注文へ変換されず、初期化ロジックも動かない。
2. **会計完了後のステート遷移が未設計**: サービス層でも `status` を `preparing` のまま保っているため、「下書きカート」と「会計済み注文」の区別が付かず、次回起動時も同じ注文が「アクティブカート」として再利用される。
3. **UI 状態のリセット機構がない**: Provider が `autoDispose` でない + 会計成功時に `state` を初期値へ戻す処理がないため、フロントエンドの表示が自然にリセットされない。

## 4. 影響範囲と懸念事項

- 現状の会計フローでは正式な注文確定が行われず、注文履歴・分析・在庫連携が正しく動作しない可能性が高い。
- 注文番号生成 (`_orderRepository.generateNextOrderNumber()`) の結果が実際の注文へ反映されないため、Order-Bugfix-1 の前提条件も満たせない。
- 会計後にカートが残り続けることで、連続注文時に混同や誤会計が発生しやすい。

## 5. 改善に向けた提案 (概要)

1. **UI からのチェックアウト導線整備**
   - `OrderManagementController` に「会計処理」を追加し、`OrderManagementService.checkoutCart` を呼び出す。
   - 成功時に `CartService.clearCart` もしくは新規カート生成処理を呼んで `state` を初期化する。

2. **会計済み注文のステータス設計**
   - `checkoutCart` 完了後に `OrderStatus.confirmed` もしくは `completed` 等、`preparing` と区別できる状態へ遷移させる。
   - 新規カート作成 or `getActiveCart` の絞り込み条件を調整し、既存注文が再取得されないようにする。

3. **状態管理のライフサイクル改善**
   - `orderManagementControllerProvider.autoDispose` 化や、`GoRouter` の遷移完了時に `refresh()` を走らせる等、画面復帰時に最新状態を再読込する仕組みを検討する。

4. **検証タスクの追加**
   - 実際の会計シナリオ (会計 → 履歴表示 → 再度注文開始) を E2E で確認できるテスト or 手動チェックリストを整備する。

## 6. 未解決の論点 / 次の調査事項

- `_orderRepository.generateNextOrderNumber()` の戻り値利用方法 / 永続化タイミングの確認。
- `OrderManagementService.checkoutCart` が期待する「カートと正式注文の境界」をどう設計するか (別テーブルに分けるか、ステータス管理で切り替えるか)。
- 会計後にリアルタイムチャンネル (`OrderManagementService` の realtime 機能) を用いて他画面へ通知する必要性の有無。

---

> 以上の内容を踏まえ、UI・サービス層の会計導線とステート管理の再設計が Order-Bugfix-3 の本質的な解決につながると考えられる。
