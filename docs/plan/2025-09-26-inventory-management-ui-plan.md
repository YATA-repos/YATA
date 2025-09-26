# 在庫管理 UI 改善 実装計画（2025-09-26）

本書は Intent 文書に基づき、在庫管理ページへ反映する具体的な計画を示します。現行コードに対して小さく安全に適用できる順序で構成します。

- 対象: `lib/features/inventory/presentation/pages/inventory_management_page.dart`
- 付随: `lib/features/inventory/presentation/controllers/inventory_management_controller.dart`

## スコープ

Phase 1（非破壊）で以下を実装。Phase 2 は別イシューで追う。

### Phase 1（このスプリント）

1. 選択ツールバーを拡張
   - 追加ボタン:
     - 一括適用（選択）: `applySelected()` 呼び出し
     - 一括適用（表示中全件）: `applyAllVisible()` 呼び出し
     - 選択行の差分クリア: `clearAdjustmentsForSelected()` 呼び出し
   - すべて確認ダイアログを挟む。
   - ボタンは右側の「未適用: N件 / 合計: ±X」の前後に配置。横幅が足りない場合は `OverflowBar` にフォールバック。

2. 更新者情報のツールチップ
   - 「更新日時」セルに `Tooltip` を付与し `updatedBy` を表示（例: `最終更新: 2025-09-24 07:59 / by tanaka`）。

3. ヘルプ/アクセシビリティの微調整
   - ステータスピルとテーブル操作ボタンに `tooltip` 文言を追加。

4. ドキュメント整備
   - `docs/intent/*` と本計画書を追加（本 PR）。

### Phase 2（別イシュー）

- 差分型を `int -> double` に拡張し、`UnitConfig` の `step/decimals` を尊重する UI へ刷新。
- キーボードショートカットと `Semantics` 整備。

## 受け入れ条件（Acceptance Criteria）

- 一括適用（選択/表示中）が UI から実行でき、適用後に該当行の差分がクリアされる。
- 適用不可の行（負在庫になる）は内部でスキップされる（現状仕様を踏襲）。
- 「更新日時」ホバー時に更新者が確認できる。
- Lints/Analyzer に警告・エラーを追加発生させない（既存の unrelated 警告はこのスコープ外）。

## 実装タスク

- [ ] ツールバー UI 追記（`_InventoryTableState` 内 `actions` 部）。
- [ ] 「更新日時」セルの Tooltip 化。
- [ ] テキスト文言・Tooltip の日本語レビュー。
- [ ] 単体テスト（State のみ）: `applySelected/applyAllVisible/clearAdjustmentsForSelected` の幸せ/境界ケース。

## 変更影響

- UI のみ。コントローラ API は既存を再利用。破壊的変更なし。

## ロールバック方針

- 追加した UI コンポーネントの revert で元に戻せる（状態モデルの変更なし）。

## 今後の拡張メモ

- サービス/リポジトリ接続時、UI の適用ボタンにローディング/エラーハンドリングを追加。
- バッチ適用の結果サマリを Snackbar/Toast で通知。
