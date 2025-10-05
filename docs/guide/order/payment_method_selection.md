# 会計時の支払い方法選択ガイド

## 概要
- 対象画面: `OrderManagementPage`
- 対象機能: カート会計時の支払い方法（現金 / カード / その他）切り替え
- 関連コード: `OrderPaymentMethodSelector` ウィジェット、`OrderManagementController.updatePaymentMethod`

このガイドでは、会計画面で支払い方法を選択・保存するフローと注意点をまとめます。実装の背景となった計画は `docs/plan/2025-09-28-order-payment-method-plan.md` を参照してください。

## UI の挙動
- 会計カード内に支払い方法の選択チップが表示されます。
- 利用可能な選択肢は `PaymentMethod` enum の内容（現金 / カード / その他）です。
- チップをタップすると即座に `OrderManagementController` の状態が更新され、選択中のチップにハイライトが付きます。
- 会計処理実行中やカート再取得中は、読み込みインジケータとともにチップがタップ不可になり、操作による競合を防ぎます。

## データ保持
- 選択した支払い方法は `CartService.updateCartPaymentMethod` を介して Supabase 上のアクティブカートに保存されます。
- カートの再読込や画面再訪問時には、カートに保存された値が初期選択として適用されます。
- 会計完了後に付与される新しいカート（draft）にも `paymentMethod` が引き継がれ、次回会計時の初期値となります。

## 失敗時のハンドリング
- ネットワーク障害などで支払い方法の更新 API が失敗した場合は、操作前の状態へ自動的に戻ります。
- UI では `SnackBar` を通じてエラーメッセージを表示し、再試行を促します。
- 再試行時はチップを再選択してください。状態に差分があるときのみ API が呼ばれます。

## 手動確認手順
1. 会計画面を開き、支払い方法チップが表示されていることを確認します。
2. 任意の支払い方法に切り替え、ハイライトとトースト表示を確認します。
3. 同一の支払い方法を再び選択しても API が呼ばれない（ログや Supabase 側に更新が発生しない）ことを検証します。
4. 会計を完了した後、新しいカートに切り替わり、選択した支払い方法が維持されているかを確認します。
5. 画面を再読込またはアプリを再起動し、保存された支払い方法が初期状態として表示されることを確認します。

## 自動テスト
- `test/features/order/services/cart_management_service_test.dart`
  - カート更新 API が `payment_method` に期待値を保存することを検証
- `test/features/order/presentation/controllers/order_management_controller_test.dart`
  - UI 操作で支払い方法を変更した際に状態・サービス呼び出しが行われることを確認
- `test/features/order/presentation/widgets/order_payment_method_selector_test.dart`
  - ウィジェット単体での選択操作がハンドラーを呼び出すことを保証

`flutter test` および `flutter analyze` でグリーンになることをリリース条件としています。