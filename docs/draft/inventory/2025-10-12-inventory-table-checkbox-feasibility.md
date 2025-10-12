# 在庫・メニューテーブルのチェックボックス廃止検討（2025-10-12）

## 背景
- 在庫管理ページとメニュー管理ページはいずれも `YataDataTable.fromSpecs` を介してテーブルを構築している。
- `DataRow.onSelectChanged` を設定すると Flutter の `DataTable` は自動でチェックボックス列を描画する仕様になっており、両テーブルにも視覚的なチェックボックスが表示されている。
- しかし実際には選択状態を保持していないためチェックボックスとしての機能を果たしておらず、クライアントもチェックボックスを不要と判断している。

## 現状整理
- 共通ラッパー `YataDataTable` が `DataTable` を生成しており、行タップを有効化する際に `onSelectChanged` を委譲している（`lib/shared/components/data_display/data_table.dart:137`）。
- メニュー管理テーブルは `MenuItemTable` 内で `onRowTap` を渡し、行タップでモーダルを開いている（`lib/features/menu/presentation/widgets/menu_item_table.dart:63`）。
- 在庫管理テーブルも同様に `onRowTap` を渡しており、ビジー状態と存在チェックの後に編集モーダルを開いている（`lib/features/inventory/presentation/pages/inventory_management_page.dart:1082`）。
- いずれの画面も `selected` 状態やチェックボックスウィジェットを保持しておらず、チェックボックスの見た目のみが残っている。

## 実現可能性評価
- Flutter の `DataTable` には `showCheckboxColumn` 引数があり、これを `false` に設定することでチェックボックス列を抑制できる。
- `showCheckboxColumn` を `false` にしても `onSelectChanged` 自体は利用可能のため、行タップ挙動は維持できる。
- `YataDataTable` の利用箇所はメニューと在庫のテーブルのみで、どちらもチェックボックス機能を前提としていないため副作用は限定的。
- 自動テスト（`test/shared/components/data_display/data_table_test.dart`）でもチェックボックス有無に依存した検証は行っていない。

## 推奨アプローチ
1. `YataDataTable` に `showCheckboxColumn` を制御するオプションを追加し、既定値を `false` に設定する。
2. 既存呼び出し側（在庫・メニュー）では追加対応不要とし、既定値でチェックボックスを非表示にする。
3. 必要に応じて将来チェックボックスを利用したいテーブルが現れた場合に備え、`YataDataTable` の新規引数で明示的に `true` を指定できるようにする。

## 影響・リスク
- 行が選択状態になる視覚表現が無くなるため、アクセシビリティ面ではタップ時のフィードバックがホバーや InkWell の色変化に依存する。必要に応じてフォーカス時のスタイル調整を追加検討。
- 複数選択やチェックボックスによる一括操作が今後必要になった場合は再導入か別コンポーネントの検討が必要。

## 残課題
- UX チームと調整し、チェックボックス廃止後のアクセシビリティ要件（フォーカスリング等）が満たされているか確認する。
- 行タップに依存するテストや自動化シナリオが存在する場合は、スクリーンショット比較などで期待通り表示されるかの確認を追加する。
