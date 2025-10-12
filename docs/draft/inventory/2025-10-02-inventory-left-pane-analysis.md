# 在庫カテゴリ左ペイン挙動分析（2025-10-02）

## 概要

在庫管理ページ（`inventory_management_page.dart`）の左ペインでは、カテゴリ別の在庫集計を表示している。一方、メニュー管理ページ（`menu_management_page.dart`）の左ペインではカテゴリの検索・並び替え・編集操作が統合されており、よりリッチな体験を提供している。本書では両者の機能差を整理し、実装計画立案の前提となる調査結果をまとめる。

## 現状整理

### 在庫管理ページの左ペイン

- 状態ソース
  - `InventoryManagementState.categories`: 先頭"すべて" + カテゴリ名の配列。
  - カテゴリ名称は `MaterialCategory` と `InventoryItemViewData` の両方から収集し、アルファベット順ソート。
  - 選択状態は `selectedCategoryIndex`（int）で保持。
- UI
  - `ListView.separated` で集計カード `_CategoryTile` を描画。
  - カテゴリ単位の件数・注意数・危険数をバッジ表示。
  - クリックで `controller.selectCategory(index)` を呼び出すのみ。
  - 検索、ドラッグ&ドロップ、編集、削除は未対応。
  - 「カテゴリ追加」ボタンは在庫アイテム追加ダイアログと共用する簡易ダイアログ。
- データ操作
  - カテゴリ作成のみ `InventoryServiceContract.createMaterialCategory` を利用。
  - 既存カテゴリの名称変更・削除・並び替え API は未定義。

### メニュー管理ページの左ペイン

- 状態ソース
  - `MenuManagementState.categories`: `MenuCategoryViewData` のリスト（ID、表示順、件数含む）。
  - 検索クエリ、選択カテゴリID、可視カテゴリ一覧 `visibleCategories` を保持。
- UI
  - 検索フィールド + ステータスバッジ群。
  - 「すべてのカテゴリ」カードでは提供可/要確認数を集計表示。
  - `ReorderableListView` + カスタムタイルでドラッグ並び替え対応。
  - 各カテゴリに編集・削除アクションボタンを提供。
  - 選択カテゴリは `MenuManagementController.selectCategory` で制御。
- データ操作
  - コントローラが `MenuService` 経由で CRUD / 並び替え / 楽観的更新を実装。
  - 非同期処理中のカテゴリIDセット（`savingCategoryIds` など）でUIを制御。

## ギャップ一覧

| 機能 | 在庫左ペイン | メニュー左ペイン | 差分/課題 |
|------|--------------|------------------|-----------|
| 検索 | 非対応 | テキスト検索（リアルタイム） | 在庫カテゴリ検索フィールドを追加する必要あり。
| 並び順 | アルファベット固定 | displayOrder + DnD | MaterialCategory.displayOrder を尊重し、ドラッグ並び替えと永続化が必要。
| CRUD 操作 | 新規作成のみ（簡易ダイアログ） | 新規/編集/削除に対応 | カテゴリ編集・削除UIとサービス契約の拡張が必要。
| 選択指標 | 選択色 + 件数バッジ | 選択色 + itemCount表示 | 在庫でも件数/閾値バッジを保持しつつ、Hover/Tooltip改善が必要。
| 集計 | 適正/注意/危険バッジ | 提供可/販売停止/在庫注意バッジ | 状態項目が異なるため変換ルールを定義する必要あり。
| 状態管理 | indexベース | IDベース、非同期状態管理 | 在庫カテゴリも ID 主体の ViewData 構造へ移行する必要あり。
| 読み込み | `loadInventory()` 内で一括 | カテゴリ API + アイテム API | カテゴリ取得の責務を整理し、カテゴリ単体更新を許容する必要あり。

## 制約・前提

1. `InventoryServiceContract` にはカテゴリ更新/削除/並び替えが未定義。
2. 材料カテゴリは在庫アイテムと1:Nで紐づくため、削除時の棚卸しロジック要検討。
3. 在庫アイテムのカテゴリは `Material.categoryId` で管理されており、カテゴリ表示名は `MaterialCategory` に依存。
4. 左ペインの集計は `state.items` をベースに算出している。カテゴリ ViewData への集計移行にはパフォーマンス面の配慮が必要。

## 改修に向けたチェックポイント

- [ ] カテゴリ ViewData モデルの導入（ID / 名称 / displayOrder / 集計値）。
- [ ] `InventoryManagementState` のカテゴリ管理ロジック再設計。
- [ ] `InventoryServiceContract` と実装（`InventoryService`）への CRUD 拡張方針確認。
- [ ] 並び替え API（`updateMaterialCategoryOrder` 仮）追加の是非。
- [ ] カテゴリ削除時のバリデーション（空でない場合の警告）ポリシー策定。
- [ ] UI レイアウト更新（検索フィールド、ドラッグハンドル、アクションボタン配置）。
- [ ] 「すべて」カテゴリの集計UIをメニュー画面準拠に刷新。

## 未解決事項 / 要確認

- Supabase 側テーブル `material_categories` に論理削除列や `updated_at` の自動更新トリガーが存在するか。
- Category reorder API を導入する場合、既存クライアントとの互換性をどう担保するか。
- 在庫カテゴリにおける `displayOrder` の現在使用状況（他画面で依存していないか）。

## 次ステップメモ

1. `InventoryServiceContract` 拡張案をサーバー担当と調整。
2. カテゴリ ViewData 変換のユニットテスト下書きを先に用意する。
3. UI 実装前にステート再構築 → Riverpod 状態テストを進める。
