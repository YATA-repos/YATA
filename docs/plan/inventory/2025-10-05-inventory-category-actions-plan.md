# 在庫カテゴリ操作ポップアップ追加計画（2025-10-05）

## 背景
- メニュー管理画面ではカテゴリ一覧に「名称変更」「削除」を行うポップアップメニューが実装済み。
- 在庫管理画面のカテゴリペインはメニューのレイアウトを流用したが、操作メニューが未実装のため CRUD 一貫性が欠けている。
- 在庫カテゴリは `MaterialCategory` モデル／`InventoryService` を経由して Supabase 上で管理されており、現在 UI からの追加（作成）のみ対応。

## ゴール
1. 在庫カテゴリ一覧の各行から「名称変更」「削除」を選べるポップアップメニューを提供する。
2. カテゴリの編集／削除操作を `InventoryManagementController` 経由で呼び出し、成功時に UI を即時更新する。
3. 利用者に対し、エラーメッセージや確認ダイアログなど適切なフィードバックを表示する。
4. 既存のカテゴリ追加動線・在庫テーブルフィルタとの連携を維持する。

## 実装方針
### 1. サービスレイヤー
- `InventoryServiceContract` に以下を追加
  - `Future<MaterialCategory?> updateMaterialCategory(MaterialCategory category)`
  - `Future<void> deleteMaterialCategory(String categoryId)`
- `InventoryService` で上記を `MaterialManagementService` に委譲。
- `MaterialManagementService` に編集・削除メソッドを新設：
  - `updateCategory` では既存カテゴリ取得→バリデーション→ `updateById` 呼び出し→ログ出力。
  - `deleteCategory` では該当カテゴリと紐づく材料の存在チェック（削除禁止条件の検討）→ `deleteById` 実行。
- 既存の `MaterialCategoryRepository` を流用。削除前バリデーションで `MaterialRepository` を併用して紐づき件数を確認。

### 2. コントローラ層
- `InventoryManagementController` に以下を追加：
  - `Future<String?> renameCategory(String categoryId, String newName)`
  - `Future<String?> deleteCategory(String categoryId)`
  - どちらもサービス呼び出し前に `state.categoryEntities` を参照して対象検証／名前重複チェック。
  - 成功時は `loadInventory()` を再利用し、選択状態が削除／変更後に破綻しないよう調整。
  - 失敗時は返り値にエラーメッセージを載せ、UI で `SnackBar` 表示。
- 既存の `createCategory` と同様、`isLoading` フラグで UI ローディング制御を共有。

### 3. UI 層
- `InventoryCategoryPanel` に編集／削除コールバックを受けるプロパティを追加（メニュー側と同仕様）。
- 在庫側では `InventoryCategoryPanelData` を用意し、カテゴリ ID と表示件数を保持。
- `_InventoryCategorySummary` 相当のロジックを `InventoryManagementController` から取得した `state.categoryEntities` と `state.items` から構築。
- ポップアップ選択時の挙動：
  - **名称変更**: `showDialog` でテキストフィールド付きモーダルを表示。空文字／重複時はバリデーションメッセージ。
  - **削除**: `showDialog` で確認を行い、紐づく在庫アイテムが 0 件かをコントローラ側でチェック → 0 件以外は Snackbar で警告してキャンセル。
- 削除後のカテゴリ選択は「すべて」に戻す。

### 4. ロギングとユーザーフィードバック
- 成功／失敗時に `ScaffoldMessenger` で結果を通知。
- サービス層では既存のログカテゴリ (`ServiceInfo`, `ServiceWarning`, `ServiceError`) を使用して操作結果を記録。

### 5. テスト
- `InventoryManagementController` の新メソッドをユニットテスト：
  - 正常系（名称変更／削除）
  - バリデーション異常（空文字／重複、紐づき在庫あり削除）
  - サービス例外時のエラーハンドリング
- ウィジェットテスト（任意）：ポップアップ表示～ダイアログ操作の UI 検証。

## 作業ステップ（ドラフト）
1. サービス契約・実装に更新／削除メソッドを追加。
2. `MaterialManagementService` へロジック実装＆関連リポジトリ呼び出しを追加。
3. コントローラへ編集／削除メソッドを実装し、状態更新処理を拡張。
4. `InventoryCategoryPanel` を拡張し、在庫ページからコールバックを接続。ダイアログ UI を実装。
5. テスト追加、`flutter analyze` / `flutter test` を実行。
6. 手動確認：カテゴリ編集／削除 → 在庫テーブルフィルタ状態を確認。

## リスクとメモ
- 削除禁止条件：在庫が残っているカテゴリの扱いを要決定（今回は削除不可とし、エラーメッセージで案内）。
- 表示順 (`displayOrder`) の扱い：名称変更では保持。削除後の順序再計算は不要（Supabase 側で gap ありでも問題なし）。
- 既存のカテゴリ追加処理とローディングフラグが競合しないよう、UI 側で重複操作を抑止。
- 将来的なドラッグ＆ドロップ移行時は今回の `InventoryCategoryPanelData` を再利用予定。
