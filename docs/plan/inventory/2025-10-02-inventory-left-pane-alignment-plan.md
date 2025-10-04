# 在庫管理 左ペイン挙動統合計画（2025-10-02）

本計画は、在庫管理ページのカテゴリ表示ペインをメニュー管理ページと同等のユーザー体験に揃えるための改修指針をまとめる。カテゴリ検索、並び替え、CRUD 操作を統合し、在庫担当者がメニュー管理と同じ操作感で在庫カテゴリを扱えるようにすることを目的とする。

- 対象: `lib/features/inventory/presentation/pages/inventory_management_page.dart`
- 関連: `lib/features/inventory/presentation/controllers/inventory_management_controller.dart`、`lib/features/inventory/services/*`、`lib/features/inventory/models/inventory_model.dart`
- 参考: `docs/draft/2025-10-02-inventory-left-pane-analysis.md`

## 背景と課題

- 現状の左ペインはカテゴリ集計の参照専用であり、カテゴリ検索・並び替え・編集ができない。
- `MaterialCategory.displayOrder` が UI で活かされておらず、アルファベット順で固定。
- カテゴリの作成のみ UI から可能で、名称変更や削除は Supabase ダッシュボード依存になっている。
- メニュー管理ページでは、カテゴリ検索・ドラッグ並び替え・編集/削除が統合されており、在庫管理との差異がユーザー混乱を招いている。

## ゴール

1. 在庫カテゴリ左ペインで以下の操作を提供する:
   - テキスト検索（リアルタイムフィルタ）
   - ドラッグ&ドロップによる表示順変更（`displayOrder` に永続化）
   - カテゴリの編集・削除
   - 「すべて」の集計カードをメニュー管理と近いトーンに刷新
2. `InventoryManagementState` を ID ベースの ViewData 管理にリファクタし、カテゴリ更新のリアクティブ連動を実現する。
3. 既存の在庫カテゴリ集計（適正/要注意/危険件数）を維持しつつ、UI/UX を統一感のあるものに再設計する。

## スコープ

### Phase 1（今回実装）

1. **ドメイン/サービスの拡張**
   - `InventoryServiceContract` に以下を追加:
     - `Future<MaterialCategory?> updateMaterialCategory(MaterialCategory category)`
     - `Future<void> deleteMaterialCategory(String categoryId)`
     - `Future<void> reorderMaterialCategories(List<MaterialCategory> categories)`
   - Supabase 実装（`InventoryService`）を対応させ、表示順更新を一括バッチで永続化。
   - 既存 API 呼び出し箇所の互換維持。

2. **状態モデルの再設計**
   - 新たに `InventoryCategoryViewData`（id/name/displayOrder/itemCount/lowCount/criticalCountなど）を導入。
   - `InventoryManagementState` に以下を追加:
     - `categoryQuery`（検索テキスト）
     - `visibleCategories`（フィルタ適用後の ViewData）
     - `savingCategoryIds` / `deletingCategoryIds` / `reordering` フラグ
     - `selectedCategoryId`（ID ベース）
   - `loadInventory()` で `MaterialCategory` を displayOrder 昇順で並べ、ViewData として構築。
   - 既存の index ベース選択 (`selectedCategoryIndex`) を廃止し、UI 側（テーブルフィルタ）と整合。

3. **UI 刷新**
   - 左ペインを `MenuCategoryPanel` に倣った構造へ置き換え:
     - 検索フィールド（`YataSearchField`）
     - ステータスバッジ群（カテゴリ数 / 表示件数 / 在庫ステータス集計）
     - 「すべてのカテゴリ」カードの文言・カウント更新
     - `ReorderableListView` によるタイル表示（ドラッグハンドル、編集/削除アイコン、件数バッジ）
   - カテゴリ編集・削除ダイアログを追加。
   - 並び替え不可条件（フィルタ適用中、API 送信中）の制御を UI に反映。

4. **Controller メソッド追加**
   - `updateCategorySearch(String query)` / `selectCategory(String? id)` / `reorderCategories(int oldIndex, int newIndex)` / `editCategory(...)` / `deleteCategory(...)` を実装。
   - 表示順更新時に楽観的 UI 更新 + ロールバック処理。
   - カテゴリ削除時に、当該カテゴリに属する在庫が存在する場合のガード（確認ダイアログ）。

5. **在庫テーブルとの連携調整**
   - `filteredItems` のカテゴリフィルタを `selectedCategoryId` に合わせて更新。
   - カテゴリ削除後の選択状態リセットとテーブルの自動再フィルタ。

6. **テレメトリ/ログ対応**
   - カテゴリ作成/更新/削除/並び替えイベントで `log.i/log.w` を送出（在庫サービスで既に利用中のロガーを流用）。

### Phase 2（別チケット）

- カテゴリ削除時の一括リマップ（別カテゴリへの移動）機能。
- カテゴリのアーカイブ/非表示機能。
- オフライン編集キュー対応。

## 成功条件（Acceptance Criteria）

- 左ペインでカテゴリ検索が機能し、入力に応じてリストと件数バッジがリアルタイム更新される。
- ドラッグ操作でカテゴリの表示順を変更でき、リロード後も順序が保持される。
- カテゴリ編集ダイアログから名称を変更すると、テーブル・フィルタに即時反映される。
- カテゴリ削除時には確認ダイアログが表示され、削除後に対象カテゴリの在庫が「未分類」などの扱いになるか、警告表示でキャンセルできる。
- Lints/Analyzer を通過し、既存の在庫テーブル操作（選択・差分適用）が影響を受けない。

## 設計メモ

- **ViewData 設計**: `InventoryCategoryViewData` に `fromModel` コンストラクタを用意し、`InventoryItemViewData` の集計結果を注入する。ステータス集計は状態更新毎にキャッシュ。
- **検索ロジック**: `state.categoryQuery` を `MenuManagementState` と同等の構造にし、`visibleCategories` でフィルタ済み配列を提供。フィルタ中は `ReorderableListView` の `onReorder` を no-op。
- **表示順更新**: 楽観的にローカル順を更新 → API 連携 → 失敗時に前状態へロールバックし Snackbar で通知。
- **削除ポリシー**: 当面は「紐づく在庫があるカテゴリは削除禁止」にし、エラーメッセージを UI へ返す。将来のマイグレーション（別カテゴリへ移動）は Phase 2。
- **State 移行**: 旧 `selectedCategoryIndex` を段階的に廃止。テーブル側とのフィルタ連携箇所を grep で洗い替えすること。

## タスク分解

1. **事前準備**
   - サービス契約・モデルの更新（`MaterialCategory` に `copyWith` 追加など）。
   - 単体テスト雛形：カテゴリ並び替えロジックのユニットテスト作成。
2. **Controller リファクタ**
   - 新しい State フィールドと ViewData 変換を導入。
   - 既存メソッド（`selectCategory`, `createCategory` など）を ID ベースへ刷新。
   - Reorder / Edit / Delete メソッドを追加しテスト。
3. **UI コンポーネント更新**
   - `_CategorySidebar` を分割し、新コンポーネント（例: `InventoryCategoryPanel`）を作成。
   - 検索フィールド、ステータスバッジ、Reorderable リストを実装。
   - 操作中インジケータ（ローディング/非活性状態）を追加。
4. **結合・調整**
   - テーブルフィルタの更新、ダイアログ導線の調整。
   - Snackbar とログ連携の確認。
5. **検証**
   - アナライザ / フォーマッタ。
   - `InventoryManagementController` のユニットテストを整備。
   - 左ペインのウィジェットテスト（検索・選択・ドラッグをモックで検証）。

## リスクと対策

| リスク | 対策 |
|--------|------|
| カテゴリ削除が既存在庫と競合する | 削除 API 前に在庫有無チェック → エラー時は UI で明示＆キャンセル |
| 並び替え API 未整備 | サーバー側と事前調整し、サンプル SQL を共有。暫定でクライアント並び替えのみ（Phase 1 で最低限サーバー対応） |
| 状態リファクタによる回帰 | 既存メソッドに対応するテスト追加し、旧フィールド参照を全面 grep |
| UI 差異が大きい | Menu UI を再利用可能な部品に分割し、スタイルトークンで整合性を確保 |

## マイルストーン

- **Day 0-1**: サービス契約・モデル調整 + テストベースライン作成
- **Day 2-3**: State/ViewData リファクタ & コントローラ新メソッド実装
- **Day 4-5**: UI 更新、ドラッグ＆編集導線統合
- **Day 6**: 結合テスト・回帰動作確認・コードレビュー準備

## 検証計画

- `flutter test`（コントローラ/ウィジェットのユニットテスト）
- `flutter analyze`
- 手動シナリオ:
  1. カテゴリ検索 → 文字列一致が機能すること。
  2. 並び替え実施 → ページリロード後も順序維持。
  3. カテゴリの名称変更 → テーブル・フィルタに即時反映。
  4. 在庫が存在するカテゴリ削除 → アラート表示でキャンセル可能。
  5. API エラー時 → Snackbar / ログ出力を確認。

## ロールバック方針

- 新規コンポーネントと State 拡張をリバートすれば旧 UI に戻れる。既存フィールドは一時的に残さない方針のため、リバート時は `git revert` で対応。
- サービス契約の変更は API 互換がないため、バックエンド側と同期して段階ロールバック手順（旧 API を保持する期間）をすり合わせる。

## 追加検討事項

- カテゴリに色・アイコンを割り当てる UI 強化（在庫種別を直感的に把握）。
- 在庫テーブルのカテゴリバッジ化（左ペインとの視覚的リンク強化）。
- 在庫カテゴリに説明フィールドを追加し、ツールチップで表示する案。
