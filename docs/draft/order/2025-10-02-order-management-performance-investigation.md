# 注文画面パフォーマンス調査（2025-10-02）

## 背景
- 注文画面（`OrderManagementPage`）での操作全般が重いとの報告を受け、コードレベルでボトルネックになり得る箇所を洗い出した。
- 実計測やプロファイル結果は未取得。発見事項はコードリーディングと構造分析に基づく仮説である。

## 観察したボトルネック候補
- **メニュー一覧を全件描画している**
  - メニューは `SingleChildScrollView` + `Wrap` で全アイテムを一括ビルドしており、件数が増えるほどレイアウト計算とリビルド負荷が直線的に増大する。
  - 参照: `lib/features/order/presentation/pages/order_management_page.dart:323`
- **カート情報参照が O(メニュー数 × カート数) になっている**
  - 各メニューカードで `state.isInCart` と `quantityFor` がループを回しており、メニュー数やカートアイテム数が増えると毎フレームの計算量が急増する。
  - 参照: `lib/features/order/presentation/pages/order_management_page.dart:328`
- **絞り込みリストの都度ソート**
  - `OrderManagementState.filteredMenuItems` が呼ばれるたびに `toList` と `sort` を実行しており、リビルド毎に全件ソートが走る。メニュー数が多いほど UI スレッドを占有しやすい。
  - 参照: `lib/features/order/presentation/controllers/order_management_controller.dart:237`
- **注文メモ入力で全画面が再構築される**
  - `TextField` の `onChanged` で `updateOrderNotes`（StateNotifier更新）を直呼びしており、1 文字入力ごとに注文画面全体が再ビルドされてメニュー側まで再描画される。
  - 参照: `lib/features/order/presentation/pages/order_management_page.dart:570`, `lib/features/order/presentation/controllers/order_management_controller.dart:747`
- **カート更新ごとに全データ再取得**
  - アイテム追加・数量変更・削除後に `_refreshCart` で `getOrderWithItems` を呼び直し、メニューリストまで再ソートしている。通信往復とリビルドが連続するため、操作レスポンスが低下しやすい。
  - 参照: `lib/features/order/presentation/controllers/order_management_controller.dart:476`, `lib/features/order/presentation/controllers/order_management_controller.dart:895`

## 補足メモ
- 上記のうち UI レイヤのループ構造とノンバーチャルスクロールは即座に改善効果が見込める可能性が高い。メニュー件数が多い環境では `GridView.builder` などの利用を検討したい。
- `updateOrderNotes` については、コミットタイミングを `onEditingComplete` 等に限定する、もしくは別プロバイダーに分離して局所的なリビルドに抑える方式が考えられる。
- `_refreshCart` の再取得はデータ整合性上必要な可能性があるが、差分更新やローカルキャッシュで不要な描画更新を減らせないか確認したい。