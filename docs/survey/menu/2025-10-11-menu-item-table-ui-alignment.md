# MenuItemTable UI 実装調査

## 背景 / Context
- 在庫管理画面（`InventoryManagementPage`）のテーブルをメニュー管理画面のビジュアルに寄せる要望が挙がった。
- メニュー管理画面の `MenuItemTable` は、価格表示・ステータスバッジ・販売トグルなど UI の一貫性が高く、在庫画面側の刷新指針として詳細な構造把握が必要。
- 既存の調査メモ（`2025-10-11-menu-management-table-implementation.md`）を補完し、特に UI 観点と差分解消に必要な実装ポイントを整理する。

## 目的 / Goal
- `MenuItemTable` が提供する見た目・体験の要素を分解し、在庫テーブルに移植すべき UI パターンを明確化する。
- 在庫テーブルが現在保持する UI 仕様との差異を明示し、寄せるための対応方針を提示する。

## 手法 / Method
- `lib/features/menu/presentation/widgets/menu_item_table.dart` を精読し、列構成・スタイリング・状態表示・空表示の実装詳細を抽出。
- 表示データ提供元である `MenuItemViewData`（`menu_management_state.dart`）と `_composeMenuItemViewData`（`menu_management_controller.dart`）を確認し、UI へのデータ流入を把握。
- 在庫画面の `_InventoryTable`（`inventory_management_page.dart`）と比較し、既存 UI の差異 (row height, column styling, アクション配置など) を洗い出した。

## 結果 / Findings

### MenuItemTable の UI 要素分解
- **骨格:** 共通コンポーネント `YataDataTable` を利用。`dataRowMinHeight: 60`, `dataRowMaxHeight: 68`, `columnSpacing: YataSpacingTokens.xl` を指定し、行の余白と視認性を高めている。
- **列構成:** 7 列（メニュー名/カテゴリ/価格/ステータス/在庫メモ/更新日時/販売状態）。列ヘッダーは `Text` のみでアイコンや操作は未配置。
- **行内容:**
  - 1列目（メニュー名）: 太字ラベル＋説明 (サブテキスト, 12px, セカンダリカラー)。行の高さは説明有無に合わせて 60-68px に収まる。
  - 3列目（価格）: `NumberFormat.decimalPattern("ja_JP")` を利用し、`¥` プレフィックスで一貫した通貨表示。
  - 4列目（ステータス）: `YataStatusBadge` を複数個並べ `Wrap` で折り返し。提供可否/販売停止/在庫不足/レシピ未登録を色付きバッジで表現。
  - 5列目（在庫メモ）: 欠品材料を `join(", ")` して簡潔に表示。データが空のときは "適切" または "在庫未取得"。
  - 7列目（販売状態）: `_AvailabilityToggle` を内包。`Switch.adaptive` とラベル (`販売中`/`販売停止`) の組み合わせ。処理中は `AnimatedOpacity` + `Stack` でスピナーオーバーレイ。
- **空状態:** テーブルが空の場合は `Container` (背景: `neutral0`, 枠線: `border` 色, borderRadius 12) で単純メッセージを表示。アイコンやアクション誘導は無し。
- **インタラクション:**
  - 行タップ: `onRowTap` 経由で詳細ダイアログを開く。`YataDataTable` の `onRowTap` を利用し、行全体がホバー/フォーカス可能。
  - 販売トグル: 行内の非同期アクション。ビジー状態・エラーメッセージを行単位で表示 (`availabilityErrors` → 赤字テキスト)。
- **タイポグラフィ:**
  - 見出し: `Theme.of(context).textTheme.titleSmall` + 太字。
  - 行: `Theme.of(context).textTheme.bodyMedium`。
  - サブテキスト: 12px, `YataColorTokens.textSecondary`。

### 在庫テーブル（現状）との比較

| 項目 | メニュー管理 (`MenuItemTable`) | 在庫管理 (`_InventoryTable`) | 差分 / 課題 |
|------|--------------------------------|-----------------------------|-------------|
| ラッパー | `YataDataTable` を直接使用 | `YataSectionCard` 内で `YataDataTable` を表示 | 在庫はカード + サマリー（pending 合計）を持つ。見た目を寄せたい場合はカード外観を調整する必要あり。 |
| 行高さ | Min/Max (60/68) 指定 | デフォルト (`YataDataTable` 初期値: 52/56) | 行密度が異なる。メニューに寄せるなら `dataRowMin/MaxHeight` 指定が必要。 |
| 列数 | 7列 + トグル列 | 10 列 (チェックボックス + 数量編集 + ボタン) | 在庫は操作列が多いため列再構成の検討が必要。少なくとも文字列列のスタイルをメニュー側に寄せる。 |
| タイトルセル | 太字タイトル + サブテキスト | 単純 `Text` 表示 | 在庫でも説明文（例: メモ or SKU）をサブテキストとして表示する場合はレイアウト調整が必要。 |
| ステータス表示 | `YataStatusBadge`（成功/警告/危険） | `_StatusChip` 独自チップ | バッジの見た目統一のため `YataStatusBadge` 再利用を検討。 |
| 操作用 UI | `_AvailabilityToggle`（スイッチ + ラベル + Busy オーバーレイ） | `YataQuantityStepper`, `ElevatedButton` など | 在庫は数量調整の都合で複合操作が多い。見た目を寄せる場合でもボタン・ステッパーのスタイル調整が中心。 |
| 空状態 | シンプルな枠付きコンテナ | アイコン付きガイダンス（`YataSectionCard` 内） | メニューのスタイルに寄せるなら、在庫側の空状態をシンプル化するか、逆にメニュー側をカードに寄せるか要選択。 |
| 日付表示 | `DateFormat("MM/dd HH:mm")` | 独自整形 (`yyyy-MM-dd HH:mm`) | 日付のフォーマットが異なる。 |
| 列余白 | `columnSpacing: YataSpacingTokens.xl` | デフォルト (`YataSpacingTokens.lg`) | 列間隔を広げる必要あり。 |
| 行ホバー | 共有テーマ (`YataDataTable`) | 同上 | 共通テーマによりホバー色は一致。 |

### 見た目を寄せる上での必須要素
1. **テーブル密度の統一**: `MenuItemTable` と同じ `dataRowMinHeight`/`dataRowMaxHeight` を在庫側に設定し、余白感を合わせる。
2. **列余白・ヘッダー書式**: `columnSpacing: YataSpacingTokens.xl` と太字ラベル（`TextStyle(fontWeight: FontWeight.w600)`）を導入。
3. **ステータス表現**: `_StatusChip` を `YataStatusBadge` に置き換える、またはチップの色・フォントをバッジに寄せる。
4. **日付書式の統一**: `DateFormat("MM/dd HH:mm")` を共有化（ユーティリティへ切り出すと再利用しやすい）。
5. **空状態メッセージ**: 必要に応じてメニュー側のシンプルな状態か在庫側のリッチな状態か方針を決定。見た目を寄せるなら在庫側を簡素化する。
6. **操作列のスタイル**: `_AvailabilityToggle` と同様に、操作要素に `AnimatedOpacity` や `Stack` の Busy 表現を適用し、処理中のフィードバックを統一。

## 考察 / Discussion
- `MenuItemTable` は列の内容が読み物中心（状態表示が主）で、在庫テーブルは操作主体（数量編集・適用ボタン）であるため、完全一致は難しい。見た目を寄せる場合、在庫テーブルの操作 UI をカード下部に逃がす、または操作列をモーダルに移行するなど構造変更が必要になる可能性がある。
- ステータスバッジ・トグルなどの UI パターンを shared コンポーネント化しておけば、在庫側でも同一コードを使用できる。現状 `_AvailabilityToggle` はメニュー固有ファイル内にあるため、抽出する際は props の汎用化が必要。
- データ書式（価格、日付、メモ）は `MenuItemViewData` 側で整形されているため、在庫側も DTO で表示用文字列を準備して UI ロジックを薄くする方針にすると整合性が取りやすい。

## 推奨アクション / Recommendations
1. **UI トークン共有化**: テーブルで使用する `NumberFormat` / `DateFormat` / `YataStatusBadge` 等を共通ユーティリティ or mixin 化し、両画面で使えるようにする。
2. **テーブルレイアウトの共通オプション化**: `YataDataTable` 用のプリセット（`MenuLikeTableTheme`) を shared として提供し、在庫側で簡単に適用できるようにする。
3. **ステータス/操作 UI の再編**: `_AvailabilityToggle` の仕様を整理し、在庫側で流用できる形に再設計（`YataActionToggle` など）。同時に在庫の適用ボタンにも Busy オーバーレイを導入し、状態変化がわかりやすい UI に揃える。
4. **空状態コンポーネントの決定**: メニュー・在庫どちらの表現を標準とするか合意し、そのフォーマットを共通コンポーネントにする。
5. **比較調整タスクの切り出し**: 在庫テーブルの列再構成やカード外観変更が必要か検討するため、別途デザインディスカッションを実施。

## 参考資料 / References
- `lib/features/menu/presentation/widgets/menu_item_table.dart`
- `lib/features/menu/presentation/pages/menu_management_page.dart`
- `lib/features/menu/presentation/controllers/menu_management_state.dart`
- `lib/features/menu/presentation/controllers/menu_management_controller.dart`
- `lib/features/inventory/presentation/pages/inventory_management_page.dart`
- `lib/shared/components/data_display/data_table.dart`
- `lib/shared/components/data_display/status_badge.dart`
