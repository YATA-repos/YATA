# メニュー管理テーブル実装サーベイ

## 背景 / Context
- メニュー管理ページのテーブル部分がどこまで機能固有の実装なのか、共通コンポーネントとどのように境界を分けているのかを把握する必要があった。
- 将来的に他画面へ流用する際の再利用性評価、および改修インパクト見積りの前提情報として調査を実施。

## 目的 / Goal
- メニュー管理画面のテーブル表示を構成するコンポーネントとデータモデルを整理し、機能固有コードと共有コンポーネントの切り分けを明確にする。
- テーブル周辺の振る舞い（販売可否トグル、ステータス表示など）が他機能から依存していないことを確認し、再利用や抽象化の余地を検討する。

## 手法 / Method
- `lib/features/menu/presentation/widgets/menu_item_table.dart` を中心に UI 実装をコードリーディング。
- 依存している `MenuItemViewData`（`menu_management_state.dart`）と `MenuManagementController` の `_composeMenuItemViewData` を確認し、テーブルに必要な表示データの供給元を特定。
- テーブルが参照する共有 UI コンポーネント（`YataDataTable`、`YataStatusBadge` など）を `lib/shared/components/` 以下で確認。
- `MenuManagementPage` 内での組み込み方法を確認し、他画面からの参照状況を調査（`MenuItemTable` の参照は該当ページのみ）。

## 結果 / Findings

### 構成要素の分類

| 区分 | 部品 | ファイル | 役割 | 備考 |
|------|------|----------|------|------|
| 共通 | `YataDataTable` | `lib/shared/components/data_display/data_table.dart` | Flutter `DataTable` を YATA UI に合わせてテーマ化したラッパー。ホバー色や行高、横スクロール挙動などを共通化。 | テーブル表示の基本骨格はこれに依存。メニュー画面固有ではない。 |
| 共通 | `YataStatusBadge` | `lib/shared/components/data_display/status_badge.dart` | ステータス表示用バッジ。種別（success/warning/danger）ごとの色設定を共通化。 | メニュー以外の機能でも利用実績あり。 |
| 共通 | `YataSpacingTokens` / `YataColorTokens` | `lib/shared/foundations/tokens/` | スペーシング・カラーのデザイントークン。 | 画面全体のスタイル指標。 |
| 機能固有 | `MenuItemTable` | `lib/features/menu/presentation/widgets/menu_item_table.dart` | テーブル列定義、行生成、ステータスバッジ、在庫メモ文言、販売可否トグル制御を実装。 | メニュー画面専用ロジック。列構成（メニュー/カテゴリ/価格/ステータス/在庫メモ/更新日時/販売状態）はここで確定。 |
| 機能固有 | `_AvailabilityToggle`（`MenuItemTable` 内部） | 同上 | 行末の販売状態切り替え UI。ハンドラの有無やビジー状態に応じたローディング表示を制御。 | 他機能での再利用はなし。 |
| 機能固有 | `MenuItemViewData` | `lib/features/menu/presentation/controllers/menu_management_state.dart` | テーブル行描画に必要な情報（在庫可否、レシピ有無、欠品一覧など）を保持。 | `MenuManagementController._composeMenuItemViewData` で整形され、他機能とは共有されていない。 |
| 機能固有 | `pendingAvailabilityMenuIds` / `availabilityErrorMessages` | `MenuManagementState` | 行単位のビジー状態やエラー文言を紐づけ、テーブルのトグル表示に反映。 | テーブルからの操作（`toggleMenuAvailability`）専用に設計。 |

### テーブル表示の流れ（要約）
1. `MenuManagementController._composeMenuItemViewData` がメニュー API レスポンスと在庫・レシピ状況を付き合わせ、`MenuItemViewData` を生成。
2. `MenuManagementState.filteredMenuItems` がカテゴリ・検索・ステータスフィルタを適用したリストを返却。
3. `MenuManagementPage` で `MenuItemTable` を描画し、`state` からトグルのビジー・エラー情報（`pendingAvailabilityMenuIds` / `availabilityErrorMessages`）を受け取る。
4. `MenuItemTable` は共有の `YataDataTable` を土台にしつつ、各列セルをメニュー特有の情報で構築。ステータスバッジや在庫メモ表示は `MenuItemViewData` の派生情報を利用。
5. 行末の `_AvailabilityToggle` が `toggleMenuAvailability` を呼び出し、副作用の進行状況を `MenuManagementState` が更新して UI に反映する。

## 考察 / Discussion
- UI の骨格は `YataDataTable` に依存しているため、見た目や基本的な操作感を共有コンポーネント側で統制できる。一方で列構成やビジネスロジックは `MenuItemTable` が握っており、現状ではメニュー以外への即時流用は難しい。
- `_AvailabilityToggle` は販売状態に特化した挙動（処理中オーバーレイ、セマンティクス表現）を持ち、在庫系の機能であれば再利用余地はあるが、抽出には追加設計が必要。
- テーブルが必要とする情報は `MenuItemViewData` に閉じており、API/サービス層との依存も `MenuManagementController` に集約されているため、UI レベルで機能固有ロジックがリークしていない点は健全。

## 推奨アクション / Recommendations
- 販売状態トグルを他機能でも利用する予定がある場合、`_AvailabilityToggle` を `shared/components` へ抽出する案を検討（必要なら `YataAvailabilityToggle` などとして再設計）。
- 将来的に列構成が可変化する要件が出た場合に備え、`MenuItemTable` をビルダー受け取りにする余地を整理（現状は列定義が固定）。
- 再利用性の観点で `MenuItemViewData` を別 DTO として公開する必要が生じた際は、`menu` 機能内での API 依存を整理してから shared 化を検討する。

## 参考資料 / References
- `lib/features/menu/presentation/widgets/menu_item_table.dart`
- `lib/features/menu/presentation/pages/menu_management_page.dart`
- `lib/features/menu/presentation/controllers/menu_management_state.dart`
- `lib/features/menu/presentation/controllers/menu_management_controller.dart`
- `lib/shared/components/data_display/data_table.dart`
- `lib/shared/components/data_display/status_badge.dart`
