# 在庫管理 UI メニュー調和計画（2025-10-11）

在庫管理ページ（`InventoryManagementPage`）の UI/UX をメニュー管理ページと揃えるための実装計画。トップ統計カード・検索/フィルター操作・カテゴリペイン・一覧テーブル操作をメニュー管理と同等のルック&フィールに寄せ、利用者が画面間で迷わない体験を目指す。

- 対象: `lib/features/inventory/presentation/pages/inventory_management_page.dart`
- 連動: `lib/features/inventory/presentation/controllers/inventory_management_controller.dart`、`lib/features/inventory/presentation/widgets/inventory_category_panel.dart`
- 参照: `lib/features/menu/presentation/pages/menu_management_page.dart`、`lib/features/menu/presentation/widgets/menu_management_header.dart`
- 本計画に先立つドラフト/調査: 現段階では未作成（必要に応じて `docs/draft/` へ追加）

## 1. 背景と課題
- 在庫管理ページはステータスカード・ステータスフィルター・検索/操作ボタンが個別配置されており、視線移動が多い。
- メニュー管理ページは `MenuManagementHeader` により統計カード・検索・フィルターが一体化され、視覚的な一貫性と操作導線が整理されている。
- カテゴリパネルやテーブルのアクション配置、フィードバックモーダルのスタイルにも差異があり、ユーザーが画面間で混乱する。
- 両画面で共通するデザインパターン（OverviewStatCards、SegmentedFilter、CategoryPanel）が重複利用されていないため、保守コストが高い。

## 2. 目的
1. 在庫管理画面のレイアウト・操作感をメニュー管理画面と揃え、UI の統一感と学習コスト低減を実現する。
2. 既存ビジネスロジックを崩さずに、ヘッダー/カテゴリ/一覧の UI コンポーネントを共通化・再利用できる構造へ整理する。
3. 将来の UX 調整（例: 検索フィルター追加、カテゴリ権限制御）に備えてコンポーネント境界を明確にする。

## 3. スコープと非スコープ
### 3.1 対象範囲
- ヘッダー領域（統計カード、在庫ステータスフィルター、検索/アクションボタン）。
- カテゴリパネルのレイアウト・インタラクション（検索欄の導入は Phase 2 検討）。
- 在庫一覧テーブルの操作ボタン配置、空状態・フィードバックのトーン。
- `InventoryManagementController`／State のプロパティ命名とフィルター連携の整理。

### 3.2 スコープ外
- 在庫 API の仕様変更やバックエンドの並び替えアルゴリズム改善（既存挙動を前提）。
- 在庫調整モーダル・カテゴリ CRUD の挙動変更（UI コンポーネント位置のみ調整）。
- 権限管理やマルチウィンドウ対応など UX 以外の機能拡張。

## 4. 現状差分の分析
- **ヘッダー構造**: 在庫は `_HeaderStats` + `_ControlsRow` として分離。メニューは `MenuManagementHeader` で検索・フィルター・CTA を一括管理。
- **フィルター UI**: 在庫は `_StatusPill`（Wrap + Chip）でフィルター、メニューは `YataSegmentedFilter` を使用。
- **カテゴリパネル**: 在庫 `InventoryCategoryPanel` は `CategoryPanel` を直接利用し、メニューは `MenuCategoryPanel`（検索入力、カテゴリー総数バッジ、編集アクション強化）。
- **一覧テーブル**: 在庫はヘッダー右上に「全てクリア」「表示を適用」ボタン、メニューはテーブル直下にフィードバック行がなく、主要 CTA はヘッダーに集約。
- **ローディング/エラー表示**: 在庫は LinearProgressIndicator + Snackbar、メニューは Header 内でセマンティクス対応済みの再取得ボタン制御を持つ。

## 5. 実装アプローチ（ワークストリーム）

| WS | 概要 | 主要成果物 | 依存 |
| --- | --- | --- | --- |
| WS-A | 在庫ヘッダーの再構成 | 新規 `InventoryManagementHeader`（MenuHeader と類似構造） | `MenuManagementHeader`, OverviewStatCards |
| WS-B | ステータスフィルターの統一 | `YataSegmentedFilter` を使った在庫ステータス切替 UI、Controller 連携調整 | WS-A |
| WS-C | カテゴリパネル整備 | `InventoryCategoryPanel` のスタイル調整、カードレイアウト/バッジのメニュー準拠化 | 既存 CategoryPanel |
| WS-D | 在庫一覧セクション調整 | テーブル上部のアクション帯・エンプティ状態のトーン調整、Snackbar メッセージ整理 | Controller, `_InventoryTable` |

## 6. 詳細タスク

### WS-A: 在庫ヘッダー再構成
1. `MenuManagementHeader` の構造を参考に、在庫専用の `InventoryManagementHeader` コンポーネントを新設。
   - 入力: `InventoryManagementState`, `TextEditingController`, コールバック（検索・ステータス・追加・再取得）。
   - 出力: OverviewStatCards（総在庫 / 適正 / 注意 / 危険）、SegmentedFilter、検索フィールド、`再取得`・`在庫を追加` ボタンを直列配置。
2. `_HeaderStats` と `_ControlsRow` を削除 or 代替し、`InventoryManagementPage` から新コンポーネントを呼び出す。
3. メニュー側同様に `LayoutBuilder` で 720px ブレークポイントを使い、狭幅時は縦並びに切り替える。
4. LinearProgressIndicator/エラーバナーがヘッダーと干渉しないよう、余白を統一（SpacingTokens）。

### WS-B: ステータスフィルター統一
1. `YataSegmentedFilter` を使用し、セグメントを `全て / 適正 / 注意 / 危険` に定義。
2. `InventoryManagementState.selectedStatusFilter` を `StockStatusFilter` enum (null を含めず enum 値 4 件) にリネーム検討、または `state.selectedStatusFilter` を Segment index で扱えるよう `StockStatus?` → `InventoryStatusFilter` に移行。
3. コントローラに `updateStatusFilter(InventoryStatusFilter filter)` を追加し、既存 `toggleStatusFilter` 呼び出し箇所を置き換え。
4. セマティクス・トークバック対応（MenuHeader 同様の `Semantics` ラッパー）を追加。

### WS-C: カテゴリパネル整備
1. `InventoryCategoryPanel` をカード全体で `MenuCategoryPanel` と揃う余白・角丸・ボタン配置に調整。
   - Header バッジを「合計 0件」の `YataStatusBadge` 風表現から、Menu と同サイズの `YataChipBadge` へ変更（必要に応じて shared コンポーネント拡張）。
2. カテゴリタイトル横に 3 点リーダー操作ボタンを追加済みであるため、CTA 配置のみ揃える（`MenuCategoryPanel` を再利用できるか検討）。
3. 将来のカテゴリ検索導入余地を残しつつ、`MenuCategoryPanel` で使われているセクションタイトル/総数バッジのトーンを反映。
4. 状態管理（`selectedCategoryIndex`）を ID ベースに移行する既存計画（2025-10-02 Plan）と重複しないよう、今回の変更はスタイル中心とし、ロジック変更は最小限に限定。

### WS-D: 在庫一覧セクション調整
1. テーブル上部に配置されている「全てクリア」「表示を適用」ボタンの表示場所・ラベルを見直し、ヘッダーまたはテーブル内トグルに統合。
2. 空状態カードのビジュアルをメニュー管理の「登録済みメニューがありません」に合わせ、`YataEmptyState` コンポーネント（存在しない場合は追加）で統一。
3. `state.isLoading` 時の中央スピナーではなく、テーブル上部に `LinearProgressIndicator` を重畳表示するなど視覚的な一貫性を持たせる。
4. Snackbar メッセージの定型文（「在庫を追加しました」「削除できません」等）を `MenuManagementPage` と同じトーン & 表記揺れに整理。

## 7. テクニカルノート
- `OverviewStatCards` は 3 カード前提に見えるが、List 受け取りのため 4 カードでも問題なし。横幅詰まりを避けるため、`Wrap`／レスポンシブ列数の確認が必要。
- SegmentedFilter の `MenuAvailabilityFilter` と同等の enum を在庫向けに追加すると、Widget の再利用性が向上する。
- カテゴリパネル調整で共通化を進める場合、`CategoryPanelItem` のレイアウトオプション拡張（b/Spacing/Font）を検討。
- テーブルセクションで `selectedIds` を使った一括操作を維持するため、UI 調整が state 管理に影響しないことを確認する。

## 8. テスト戦略
- **ユニットテスト**: `InventoryManagementController` のフィルター/検索更新メソッドを新 API に合わせて更新。
- **Widget テスト**:
  - `InventoryManagementHeader` のレンダリング（カード数・SegmentedFilter 選択）。
  - フィルター操作でコントローラメソッドが呼ばれることの検証（`pumpWidget` + `ProviderScope`）。
  - カテゴリパネルの選択状態が `selectedCategoryIndex` と同期するか。
- **スナップショット/Golden（任意）**: 在庫トップセクションのレイアウトをメニューと比較可能なようキャプチャ。
- **手動確認**:
  1. 画面幅 1280px / 720px / 480px でブレークポイント挙動を確認。
  2. ステータスフィルター切替 → テーブル内容・SegmentedFilter 表示の同期。
  3. 在庫追加・カテゴリ作成が新 UI から問題なく操作できること。

## 9. リスクと緩和策
| リスク | 内容 | 緩和策 |
| --- | --- | --- |
| 状態遷移の回帰 | フィルター API の差し替えで既存処理に影響 | コントローラのユニットテストを更新し、`filteredItems` の回帰テストを追加 |
| レイアウト崩れ | 4 枚カードが狭幅で折り返す際の見栄え低下 | `Wrap` + `SpacingTokens` の調整と Golden テストで検証 |
| コンポーネント重複 | Menu 側との共通化が不十分で二重メンテナンス | shared コンポーネント化の TODO を TODO.md に追記し、後続タスク化 |
| 作業重複 | 2025-10-02 在庫カテゴリ計画とのタスク衝突 | 既存計画のオーナーと調整し、変更ファイルの重複を事前に共有 |

## 10. ロールアウト手順
1. ワークストリーム単位で PR を分割（WS-A→WS-B→WS-C→WS-D の順に段階的マージ）。
2. 各 PR で `flutter analyze` / `flutter test`（該当ウィジェットテスト）を CI 条件に追加。
3. ステージングビルドで在庫・メニュー両画面を並行検証し、UI トーンが一致することを PM に確認してもらう。

## 11. 参考資料
- スクリーンショット: 在庫管理 vs メニュー管理（ユーザー提供画像、2025-10-xx）
- 既存ドキュメント: `docs/plan/inventory/2025-10-02-inventory-left-pane-alignment-plan.md`
- 実装参照: `lib/features/menu/presentation/widgets/menu_management_header.dart`、`lib/features/menu/presentation/widgets/menu_category_panel.dart`
