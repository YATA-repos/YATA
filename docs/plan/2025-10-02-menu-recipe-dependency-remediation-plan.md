# メニュー材料連動 復旧計画（2025-10-02）

## 目的
メニュー→レシピ→材料の依存関係を実装・運用レベルまで立ち上げ、在庫可用性表示と注文時の材料増減が正しく連動する状態を作る。2025-09-27 の先行計画を継承しつつ、今回の調査で判明した欠落点（レシピ CRUD 未実装、在庫ロジックの実働停止）を解消するための実行プランを定義する。

## 成果物
- アプリ内でレシピ（材料依存）を CRUD できる UI/サービス。
- `MenuService` / `OrderStockService` でレシピを活用した在庫可用性判定・在庫更新が動作することを示すテスト群。
- 既存メニューに対し最低限のレシピデータが登録された状態。
- 運用手順・ドキュメント更新。

## アプローチ概要
1. **ドメイン層の拡張**: DTO 追加、`MenuService` にレシピ CRUD API を実装し、`RecipeRepository` を通じた保存・削除を可能にする。
2. **状態管理・UI 更新**: `MenuManagementController` とメニュー管理画面にレシピ編集フローを組み込み、材料選択／必要量入力を提供する。
3. **在庫ロジックの再検証**: 注文時の材料減算・キャンセル時の復元、在庫可用性チェックをレシピ前提で網羅するテストを整備する。
4. **移行と補助ツール**: 初期レシピ投入スクリプト・ガイドラインを作成し、既存データの整合性を確保する。

## 詳細タスク

### フェーズ1: ドメイン層・サービス整備
- [ ] DTO `MenuRecipeDetail`（`Recipe` + `Material` 表示合わせ）を `lib/features/menu/dto/` に追加。
- [ ] `MenuService` に以下を実装。
  - `Future<List<MenuRecipeDetail>> getMenuRecipes(String menuItemId)`
  - `Future<MenuRecipeDetail> upsertMenuRecipe({required String menuItemId, required String materialId, required double requiredAmount, bool isOptional, String? notes})`
  - `Future<void> deleteMenuRecipe(String recipeId)`
  - レシピ更新後に `bulkCheckMenuAvailability` を呼び直すヘルパ。
- [ ] `RecipeRepository` に複合キー（`menu_item_id`, `material_id`）での検索と更新補助メソッドを追加（重複禁止のため）。
- [ ] `MenuService.deleteMenuItem` にレシピ一括削除をフック。
- [ ] 単体テストでバリデーション（負数不可・重複禁止）や例外処理を検証。

### フェーズ2: 状態管理拡張
- [ ] `MenuManagementState` にレシピリスト、材料候補、ローディング／エラーフラグを追加。
- [ ] `MenuManagementController` に以下のハンドラを実装。
  - レシピ一覧取得（メニュー選択時の自動ロード）。
  - レシピ追加・編集・削除。
  - レシピ変更後の在庫可用性再取得。
- [ ] Controller テストで state 遷移（成功／失敗パス）をカバー。

### フェーズ3: UI 実装
- [ ] `MenuItemDetailPanel` に新タブ「材料」を追加し、現在のレシピ一覧（材料名・単位・必要量・任意フラグ）を表示。
- [ ] レシピ編集モーダルを作成。
  - 材料検索フィールド（`MaterialRepository.findByCategoryId` 等を活用）。
  - 必要量入力（数値 + 単位表示）。
  - 任意フラグ・備考入力。
- [ ] 重複材料の警告、バリデーションエラー表示、保存成功時の Snackbar を実装。
- [ ] 主要 UI の Widget テストを追加。

### フェーズ4: 在庫・注文ロジック再検証
- [ ] `OrderStockService` の消費／復元処理に対するユニットテストを追加し、レシピが存在するケース／しないケースを分岐検証。
- [ ] `MenuService.checkMenuAvailability` の統合テストを追加（Material モック＋レシピモック）。
- [ ] 在庫数値の端数処理（小数点演算）と単位整合を確認、必要に応じて丸めルールを導入。

### フェーズ5: データ移行・運用整備
- [ ] 既存メニュー向けにレシピを作成するシードスクリプト（例: `tooling/seed_menu_recipes.dart`）を追加し、初期データを投入。
- [ ] 移行手順書（`docs/intent/` もしくは `docs/reference/`）に、手動登録手順と注意事項を記載。
- [ ] 運用監視: レシピ更新の監査ログ（`log.i`）整備と、Supabase リアルタイム通知を活用した再取得ロジック（オプション）。

## ロールアウト計画
1. **開発ブランチで段階的に実装**（フェーズ1→5）。
2. **Staging データベースでレシピ投入 → 注文処理 → 在庫減算をリハーサル**。
3. **Staging / Prod を同期**
   - 既存材料マスタを棚卸し。
   - メニューごとにレシピ構成を決定し、シードスクリプトで投入。
4. **本番リリース**
   - レシピ入力 UI を公開。
   - 初回導入後 1〜2 日は在庫減算ログを監視し、異常があればロールバック手順（レシピ削除と在庫補正）で対応。

## リスクと対策
| リスク | 影響 | 対策 |
| --- | --- | --- |
| レシピ未登録メニューが残る | 在庫減算が行われず乖離が継続 | UI に「レシピ未設定」警告を表示し、一覧にフィルタを用意。移行時に必須チェックリストを準備。 |
| 必要量の単位ミス | 在庫過小/過大計上 | 材料単位（個/グラム）を UI に明示し、`MenuRecipeDetail` に単位情報を含める。テストで単位変換を検証。 |
| 大量のレシピ更新による在庫再計算負荷 | メニュー管理画面のレスポンス低下 | Availability 再計算をデバウンスし、更新後の対象メニューのみ再評価する。必要に応じてバッチ API を検討。 |
| 旧注文との整合性 | 過去注文の在庫履歴が残らない | OrderStockService に取引履歴（`StockTransactionRepository`）を書き出す導線を段階的に統合し、履歴保持を強化。 |

## コミットメント
- フェーズ1〜3 で既存計画（2025-09-27）を具体化・実装する。
- フェーズ4 以降は在庫サイドとの統合を重視し、将来的な販売予測や発注提案ロジックの精度向上にも繋げる。
- 作業完了後、今回の調査レポート（`docs/draft/2025-10-02-menu-recipe-dependency-investigation.md`）をクローズし、進捗を README/TODO に反映する。
