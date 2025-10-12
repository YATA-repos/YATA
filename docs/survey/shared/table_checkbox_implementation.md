# テーブルのチェックボックス実装調査

## 調査目的
- メニュー管理画面と在庫管理画面のテーブル行に表示されるチェックボックスの表示・挙動がどのように実装されているかを整理する。

## 共通基盤 (`YataDataTable`)
- 両画面とも `YataDataTable.fromSpecs` を利用してテーブルを構築している。
- `YataDataTable` は `lib/shared/components/data_display/data_table.dart` で定義され、`_buildRowsFromSpecs` 内で `DataRow` を生成する。
- 行タップ用に `rowSpec.onTap` または `YataDataTable.onRowTap` が渡された場合、`DataRow.onSelectChanged` にコールバックを設定する。
- Flutter の `DataTable` は `onSelectChanged` が設定された行に対して標準でチェックボックス列を付与するため、明示的なチェックボックスウィジェットを各画面で描画していない。

## メニュー管理画面
- テーブル構築は `MenuItemTable` (`lib/features/menu/presentation/widgets/menu_item_table.dart`) が担当。
- `MenuItemTable.build` で、アイテムが存在する場合に `YataDataTable.fromSpecs` を呼び出し `onRowTap` を渡す。
- 行ごとの `YataTableRowSpec` ではステータスバッジや販売状態トグルなどをセルとして定義するが、チェックボックスは持たない。
- 結果として、DataTable が `MenuItemTable` の `onRowTap` を用いてチェックボックス列を自動描画し、行タップ時に詳細モーダルを開くための ID を渡す。

## 在庫管理画面
- `_InventoryTable` (`lib/features/inventory/presentation/pages/inventory_management_page.dart`) がテーブルを構築。
- 状態に応じて列スペックを定義し、`YataDataTable.fromSpecs` に `onRowTap` を渡す。
- `onRowTap` 内で対象行がビジーでないか、対応する `InventoryItemViewData` が存在するかを確認し、満たす場合に `widget.onEditItem` を呼び出してモーダルを表示する。
- 行ごとのセルは在庫情報・ステータスバッジ・調整操作などを提供し、チェックボックス自体は `YataDataTable` に委譲。

## まとめ
- チェックボックス表示は両画面とも共通コンポーネント `YataDataTable` が担っており、画面側で独自のチェックボックスウィジェットを描画していない。
- 各画面は `onRowTap` を渡すことで DataTable の標準チェックボックスを有効化し、タップ時の挙動（メニュー詳細モーダル／在庫編集モーダル）をそれぞれ制御している。
