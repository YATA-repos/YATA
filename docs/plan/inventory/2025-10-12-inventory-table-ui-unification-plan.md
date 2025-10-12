# 在庫テーブル UI メニュー調和実装計画 (2025-10-12)

在庫管理ページ (`InventoryManagementPage`) の一覧テーブルをメニュー管理ページの `MenuItemTable` に寄せるための実装計画。列構成・スタイリング・状態表示・操作フィードバックを揃え、ユーザーがページ間で一貫した体験を得られる状態を目指す。メニュー側の設計調査結果（`docs/survey/menu/2025-10-11-menu-item-table-ui-alignment.md`）をベースに、UI 実装の差分吸収と再利用の具体策を整理する。

- 対象: `lib/features/inventory/presentation/pages/inventory_management_page.dart`（特に `_InventoryTable` セクション）
- 連動: `lib/features/inventory/presentation/controllers/inventory_management_controller.dart`, `lib/features/inventory/presentation/controllers/inventory_management_state.dart`
- 参照: `lib/features/menu/presentation/widgets/menu_item_table.dart`, `lib/features/menu/presentation/controllers/menu_management_state.dart`
- 既存計画との関係: 2025-10-11 UI 調和計画（ヘッダー/カテゴリ）を後続で補完し、テーブル領域にフォーカス

## 1. 背景
- 在庫テーブルは `YataDataTable` のデフォルト密度（行 52/56px, `columnSpacing: YataSpacingTokens.lg`）で構築され、タイトルセルも単一行テキストのまま。
- メニュー管理テーブルは `YataDataTable` に対して `dataRowMinHeight: 60`, `dataRowMaxHeight: 68`, `columnSpacing: YataSpacingTokens.xl` を適用し、強調ラベル・サブテキスト・複数ステータスバッジ・空状態デザインを最適化している。
- 在庫テーブルは操作列（数量ステッパー、適用ボタン等）が多い一方で、ステータス表示や日付フォーマットが画面ごとにばらついており、横断利用時に「同じパターンなのに見た目が違う」違和感が発生している。
- 処理中フィードバック（トグルのローディング、エラー表示）が行単位で整備されておらず、利用者が状態変化を追いづらい。

## 2. 目的
1. テーブル密度・タイポグラフィ・列余白を `MenuItemTable` と揃え、見た目の一貫性を担保する。
2. ステータス/空状態/日付・価格整形などの UI パターンを共通化し、在庫テーブルからの再利用を容易にする。
3. 行内操作（数量更新、販売可否トグル等）の Busy/エラー表示を統一し、ユーザーのフィードバック体験を改善する。
4. UI 変更に伴う状態管理・データ整形の責務を整理し、継続的な改善が可能な構造にする。

## 3. スコープ
### 3.1 対象範囲
- `_InventoryTable` の `YataDataTable` 設定値（行高さ、列余白、ヘッダー文字スタイル）。
- テーブル行に表示しているラベル／ステータス／日付／メモ列の内容と整形ロジック。
- 行末操作列（数量ステッパー、適用ボタン、販売切替など）のレイアウトと非同期フィードバック表現。
- 空データ時の描画コンポーネントおよび行エラー表示（在庫不足、適用失敗等）。
- `InventoryManagementController` が提供する ViewData／DTO の見直し。

### 3.2 スコープ外
- 在庫 API・ドメインロジックの挙動変更（在庫計算、バッチ処理）。
- テーブル外のヘッダーやカテゴリパネル（別計画で対応）。
- 数量編集モーダルや一括操作ダイアログの UX 変更多く。
- メニュー管理側の追加改修（必要なコンポーネント抽出のみ）。

## 4. 成果物
- 在庫テーブル向けの共通テーブルスタイルプリセット（例: `InventoryTableStyleConfig`）。
- `InventoryRowViewData`（仮称）と整形ユーティリティ（価格/日付/メモ生成）。
- `YataStatusBadge` / 空状態コンポーネントの再利用 or shared 化された新コンポーネント。
- 行内操作の Busy/エラー用共通ウィジェット（例: `YataRowActionOverlay`）。
- 更新されたウィジェット・ユニットテスト、ゴールデン（任意）による UI 差分検証。
- 更新ドキュメント（ガイド or リリースノート下書き）。

## 5. ワークストリーム概要

| WS | 概要 | 主要成果物 | 依存 |
| --- | --- | --- | --- |
| WS-A | テーブル構造・密度統一 | `YataDataTable` 設定値の更新、ヘッダースタイル調整 | 既存 `_InventoryTable` | 
| WS-B | ステータス/バッジ整備 | `_StatusChip` の `YataStatusBadge` 化、在庫ステータスマッピング | WS-A |
| WS-C | データ整形・フォーマット共通化 | `InventoryRowViewData`、価格/日付/メモフォーマッタ | WS-A |
| WS-D | 行内操作の Busy/エラー統一 | Busy オーバーレイ、エラーメッセージ表示ガイドライン | WS-B, WS-C |
| WS-E | 空状態 & テーブル付帯 UI 再設計 | 空状態コンポーネント、適用ボタン位置見直し | WS-A |

## 6. 詳細タスク

### WS-A: テーブル構造・密度統一
1. `_InventoryTable` の `YataDataTable` 初期化で `dataRowMinHeight: 60`, `dataRowMaxHeight: 68`, `columnSpacing: YataSpacingTokens.xl` を導入し、ヘッダーテキストを `theme.titleSmall.copyWith(fontWeight: FontWeight.w600)` に変更。
2. 行 1 列目（商品名）に `RichText` or `Column` を用い、メニュー名 + サブテキスト（SKU/メモ）を 12px/セカンダリカラーで表示可能にするレイアウトへ移行。
3. `YataDataTable` 側にオプション化できる項目（SpacingToken, RowHeight Token）があれば shared 設定 (`MenuLikeTableTheme`) 化を検討し、在庫/メニューで共通利用。
4. テーブル横スクロールと列幅バランスを確認し、数量ステッパー列が狭くならないよう `flex` や `SizedBox` を調整。

### WS-B: ステータス/バッジ整備
1. 現行 `_StatusChip` を `YataStatusBadge` ベースにリファクタし、在庫ステータス (`在庫不足`, `在庫良好`, `確認中` など) を `MenuItemTable` の配色ポリシーに合わせる。
2. バッジ列を `Wrap(spacing: YataSpacingTokens.sm)` で表示し、複数バッジが折り返す際の高さが 68px 内に収まるよう検証。
3. 在庫ステータスを算出するロジックを `InventoryRowViewData.statusBadges` に集約し、UI 側は ViewData のみ描画する形へ変更。
4. 既存の Snackbar ベースエラーを、必要に応じて行内バッジ（危険色）や行下メッセージへ移行。

### WS-C: データ整形・フォーマット共通化
1. `InventoryManagementController` に `_composeInventoryRowViewData`（仮称）を追加し、価格 (`NumberFormat.currency(locale: "ja_JP", symbol: "¥", decimalDigits: 0)`)、日付 (`DateFormat("MM/dd HH:mm")`)、メモ（欠品素材 join / デフォルト文言）を事前整形。
2. `MenuItemViewData` と同様のフィールド構成（`title`, `subtitle`, `price`, `statusBadges`, `memo`, `updatedAtText`, `availability`) を在庫向けに定義し、UI の責務を軽量化。
3. フォーマットユーティリティを `lib/shared/formatters/` 配下へ切り出し、両画面から再利用できるようにする。
4. 数値/日付フォーマットのテストを追加し、ロケール変更やゼロ/空値の扱いを明確にする。

### WS-D: 行内操作の Busy/エラー統一
1. メニュー側 `_AvailabilityToggle` の Busy 表現 (`AnimatedOpacity` + `Stack`) を参考に、在庫の数量更新・販売切替操作にも適用できる共通 `YataRowActionOverlay`（仮称）を導入。
2. 操作中は行全体に半透明オーバーレイ + 進捗インジケータを表示し、ボタン/ステッパーのタップをブロック。
3. エラー状態は行下部に `Text`（danger color）を表示し、複数エラーがある場合は `List` 表示 or バッジ化を検討。
4. コントローラ側で操作ごとに `availabilityErrors` 相当のフィールドを持つよう整備し、UI は ViewData 経由で反映。

### WS-E: 空状態 & テーブル付帯 UI 再設計
1. メニュー側空状態コンポーネント（ボーダー付き白背景）を shared 化し、在庫側 `state.items.isEmpty` 時に同コンポーネントを使用。
2. 「全てクリア」「表示を適用」などのテーブル外 CTA をヘッダー/テーブル直下に再配置し、メニュー画面とボタンレイアウトを揃える。
3. 空状態文言を「在庫登録がまだありません」などメニュー寄りのトーンに統一。必要に応じて CTA ボタン（在庫追加）を配置。
4. デザイン判断が必要な箇所は UI/UX チームとデザインレビューを実施し、コンポーネント仕様を決定。

## 7. 依存関係と調整事項
- 2025-10-11 在庫 UI 調和計画（ヘッダー/カテゴリ）の進捗に合わせ、共通トークンや shared コンポーネントの所在地を調整。
- `YataStatusBadge` や `YataDataTable` の共通化で設計変更が発生する場合、他利用箇所（注文一覧等）への影響範囲をレビュー。
- Busy オーバーレイ導入時、アクセシビリティ（スクリーンリーダーへの LiveRegion 通知）をメニュー側実装に合わせるため、`semanticsLabel` の追加が必要。
- 価格・日付フォーマット統一には `intl` ロケール設定が前提。`main.dart` での `initializeDateFormatting` 状態を確認し、必要に応じて初期化処理を整理。

## 8. 実装フェーズとマイルストーン

| フェーズ | 期間目安 | 完了条件 |
| --- | --- | --- |
| P1: 基礎整備 (WS-A/B) | 2 日 | テーブル密度・ステータス表示がメニューと同等、主要列の見た目が揃う |
| P2: データ整形 (WS-C) | 1.5 日 | `InventoryRowViewData` 導入、UI ロジックからフォーマット処理が排除 |
| P3: 操作系改善 (WS-D) | 2 日 | Busy/エラー表示が統一され、操作体験の差分が解消 |
| P4: 空状態・仕上げ (WS-E) | 1 日 | 空テーブル表示・テーブル付帯 CTA が刷新され、QA チェックリスト消化 |

> 総工数目安: 6.5 日（1 名フルタイム想定）。フェーズごとに 0.5 日のレビュー/調整バッファを確保。

## 9. テスト戦略
- **ユニット**: `InventoryManagementController` の ViewData 生成ロジック（価格/日付/ステータス）と Busy 状態トグル関数を網羅。
- **Widget**: `_InventoryTable`（改修後）を対象に、行高さ・バッジ表示・Busy オーバーレイの表示パターンを検証（`pumpWidget` + Golden）。
- **Golden（推奨）**: メニュー/在庫テーブルを並べた比較ショットを撮影し、主要ブレークポイント（1280px, 960px, 720px）で差分を確認。
- **手動確認**:
  1. 在庫数量編集→適用で Busy オーバーレイが表示されること。
  2. ステータスバッジ・メモ列が複数行でも行高さが 68px を超えないこと。
  3. 空状態で CTA が適切に表示されること（ライト/ダークテーマ両方）。

## 10. リスクと対策
| リスク | 内容 | 対応策 |
| --- | --- | --- |
| 列幅不足 | 列余白拡大により操作列が圧迫される | 列ごとの `flex` や最小幅を再調整、必要に応じて一部列を折りたたみメニュー化 |
| フォーマット差分 | 既存テスト/スクリーンショットと表示フォーマットが変わる | QA/運用と調整し、リリースノートで変更を明示。Golden テストで新基準を確立 |
| Busy 表示の副作用 | オーバーレイ導入で誤って操作をブロックし過ぎる | 操作ステータスを粒度細かく持ち、必要箇所のみロック。非同期完了時に確実に解除 |
| 既存バグの顕在化 | ViewData 化でロジックが顕在化し、他機能に影響が出る | リグレッションテストを追加し、旧ロジックとの比較を段階的に実施 |

## 11. ロールアウト
1. フェーズ単位のブランチ/PR を作成し、メニュー側の共通コンポーネント抽出→在庫適用の順でマージ。
2. 各 PR で `flutter analyze` / `flutter test`（該当 Widget/ユニット）を必須チェックとする。
3. ステージング環境でメニュー/在庫を並列確認し、PM/オペレーションチームから UI 同期 OK を取得。
4. リリースノートに UI 変更点と操作フロー変更の有無を記載し、カスタマーサクセスへ共有。

## 12. 参考資料
- `docs/survey/menu/2025-10-11-menu-item-table-ui-alignment.md`
- `lib/features/menu/presentation/widgets/menu_item_table.dart`
- `lib/features/inventory/presentation/pages/inventory_management_page.dart`
- `lib/shared/components/data_display/data_table.dart`
- `lib/shared/components/data_display/status_badge.dart`
