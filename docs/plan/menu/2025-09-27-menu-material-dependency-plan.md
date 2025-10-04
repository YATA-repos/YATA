# メニュー材料依存関係 実装計画（2025-09-27）

本ドキュメントは、YATA のメニュー機能に「材料依存関係（レシピ）」を付与し、メニューアイテム単位で必要材料と使用量を定義・更新できるようにするための実装計画をまとめたものです。UI 層から在庫管理までを貫く機能追加を対象とします。

## 背景と現状整理

- メニューアイテム（`MenuItem`）モデルには材料情報を保持するフィールドがなく、材料との関連は在庫ドメインの `Recipe` テーブルで管理している（`lib/features/menu/models/menu_model.dart:45`、`lib/features/inventory/models/inventory_model.dart:108`）。
- `MenuService` は在庫可用性判定時に `RecipeRepository` と `MaterialRepository` を参照し、必要材料の在庫量から提供可否・最大提供数を算出している（`lib/features/menu/services/menu_service.dart:384` 付近、`lib/features/menu/services/menu_service.dart:852` 付近）。
- しかし UI／サービス層にはレシピの CRUD を行う手段がなく、材料依存関係の設定・更新は Supabase コンソールなど外部手段に依存している。
- メニュー管理画面（`lib/features/menu/presentation/pages/menu_management_page.dart`）は在庫可用性を表示するが、材料構成の閲覧・編集 UI は未実装。

## 解決したい課題

1. メニュー編集フローから材料依存関係（必須／任意、使用量）を定義・変更できるようにする。
2. 在庫判定ロジックと整合の取れたレシピ情報を UI、サービス、リポジトリで一貫して扱えるようにする。
3. レシピ更新後に在庫可用性を再評価し、最新状態を画面へ反映する。

## 目標とスコープ

- **対象**: メニュー管理 UI、`MenuManagementController`、`MenuService`、`RecipeRepository` 経由のドメイン層、関連 DTO／ViewData。
- **非対象**: Supabase スキーマの変更（既存の `recipes` テーブルを前提とする）、在庫機能側の大幅な仕様変更、オフライン同期。

## 要求仕様

### 機能要件

- メニューアイテムごとに以下を管理できること。
  - 既存の材料依存関係（レシピ）の一覧表示（材料名・単位・必要量・必須/任意・備考）。
  - 新規材料依存関係の追加（材料選択、必要量、任意フラグ、備考）。
  - 既存依存関係の編集（必要量・任意フラグ・備考）。
  - 依存関係の削除。
- 材料選択時には利用可能な材料のみを提示し、検索フィルタを提供する。
- レシピ更新後に `MenuService` が在庫可用性を再計算し、UI を更新する。
- 不正な入力（負数、未入力、材料重複など）は検証で阻止する。

### 非機能要件

- UI は既存のメニュー管理画面のデザイン言語（Yata コンポーネント）に従う。
- 操作ログ（create/update/delete）は `log.i` / `log.w` で記録する。
- Riverpod の状態管理を踏襲し、`MenuManagementState` の整合性を保つ。
- 既存の在庫計算ロジックに影響を与えない形で拡張する。

## 設計方針

### データ・ドメイン層

- `RecipeRepositoryContract` をそのまま利用し、追加で必要な検索は `findByMenuItemId` を活用する。
- メニュー側で扱いやすいよう、`MenuRecipeDetail`（仮称）の DTO を新設し、`Recipe` と `Material` 情報をマージして提供する。
- `MenuService` に以下のメソッド群を追加:
  - `Future<List<MenuRecipeDetail>> getMenuRecipes(String menuItemId, String userId)`
  - `Future<MenuRecipeDetail> upsertMenuRecipe(...)`
  - `Future<void> deleteMenuRecipe(String recipeId, String userId)`
  - 必要に応じてバルク保存（複数一括更新）も検討。
- バリデーションは `InputValidator` を用い、材料重複チェックはサービス層で実施。

### プレゼンテーション層

- `MenuManagementState` に以下を追加:
  - 選択中メニューの材料依存関係リスト。
  - 材料一覧キャッシュ／検索クエリ。
  - レシピ操作中のローディング・エラーステータス。
- `MenuItemDetailPanel` に新しいタブ「材料」を追加し、一覧表示と操作導線を配置。
- 依存関係の追加／編集はモーダルダイアログで実装し、材料検索フィールド、単位表示、必要量入力（数値 + スピンボックス等）を提供。
- `MenuManagementController` にレシピ取得・保存・削除のハンドラを追加し、サービス呼び出しと state 更新を担う。

### UX 補足

- 材料が未設定の場合はガイドテキストを表示し、可用性が「レシピなし」であることを明示。
- 任意材料は UI 上でタグまたはバッジで区別。
- レシピ更新完了後に Snackbar でフィードバック。

## 実装ステップ案

1. **基盤整備**
   - DTO `MenuRecipeDetail` とマッピングユーティリティを追加。
   - `MenuService` にレシピ CRUD メソッドとバリデーションロジックを実装。
   - 単体テストでサービスの振る舞いを検証。

2. **状態管理の拡張**
   - `MenuManagementState` / `MenuManagementController` に材料依存関係用の state とアクションを追加。
   - レシピ取得・保存・削除フローのテストを追加。

3. **UI 更新**
   - 詳細パネルに「材料」タブ、一覧ウィジェット、モーダルを実装。
   - 材料検索／選択コンポーネントを作成し、Material リポジトリ呼び出しを統合。

4. **在庫可用性再計算の連携**
   - レシピ変更後に `MenuService.bulkCheckMenuAvailability` もしくは `checkMenuAvailability` を呼び直し、state を更新。
   - UI の在庫バッジ／コメントを更新。

5. **仕上げとドキュメント**
   - ログ、エラー表示、ローディングインジケータを整備。
   - 追加テスト（UI コンポーネントのゴールデン/Widget テスト）を検討。
   - 必要に応じてガイド／リファレンス文書への追記案をまとめる。

## テスト戦略

- **サービス層**: モックリポジトリを用いた CRUD テスト、バリデーション（重複・非数値・負数）の網羅。
- **コントローラ**: StateNotifier テストで材料一覧と在庫再計算フローを確認。
- **UI**: Widget テストで材料タブ表示、モーダル動作、フィードバック表示を確認。
- **回帰チェック**: 既存の在庫可用性計算テストが通ること、エラーケースのログ出力を検証。

## リスクと対策

- **材料リスト肥大化**: ページング未対応の場合、初期ロードが重くなる可能性 → 遅延検索/API 検討、初期ロードはカテゴリ単位で限定。
- **同時編集競合**: 複数クライアントがレシピを更新するケース → Supabase のリアルタイムイベントをフックし、変更検出で再取得。
- **データ不整合**: メニュー削除時にレシピが残存する恐れ → サービス層にメニュー削除時のレシピ一括削除（既存処理に追加）を検討。

## 未決定事項・フォローアップ

- 材料選択ダイアログを新規実装するか、既存在庫 UI コンポーネントを再利用するか。
- 必要量の単位整合（グラム/個数）表示フォーマットの詳細。
- 将来的なオフライン編集・一括インポートへの対応範囲。

## 参考

- メニュー在庫可否判定ロジック: `lib/features/menu/services/menu_service.dart`
- 材料／レシピモデル: `lib/features/inventory/models/inventory_model.dart`
- メニュー管理 UI: `lib/features/menu/presentation/pages/menu_management_page.dart`
