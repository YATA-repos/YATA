# メニュー管理ページ実装計画（2025-10-03）

## 目的
- `/menu` ルートに表示するメニュー管理ページを新規実装し、カテゴリ・メニュー・レシピ・在庫可用性を同一画面で統合的に操作できるようにする。
- 既存の `MenuService` / リアルタイム機構をUIに接続し、販売可否や在庫状況の変化を運用者が即座に把握できる状態を作る。
- 在庫・注文管理との一貫性を保ちつつ、将来的な分析機能の土台となるメニュー基盤を整備する。

## 背景・既存資産
- ルーターには `/menu` が登録済みだが、`MenuManagementPage` 本体は未実装。
- `MenuService` には以下のドメイン操作が提供されている：
  - カテゴリ CRUD と表示順更新：`createCategory` / `updateCategory` / `deleteCategory` / `updateCategoryOrder`
  - メニュー CRUD：`createMenuItem` / `updateMenuItem` / `deleteMenuItem`
  - 在庫可用性判定：`checkMenuAvailability` / `bulkCheckMenuAvailability` / `autoUpdateMenuAvailabilityByStock`
  - 販売可否切替：`toggleMenuItemAvailability` / `bulkUpdateMenuAvailability`
  - レシピ連携：`getMenuRecipes` / `upsertMenuRecipe` / `deleteMenuRecipe`
  - 補助API：`getMenuCategories` / `getMenuItemsByCategory` / `searchMenuItems` / `getMaterialCandidates` / `calculateMaxServings`
- リアルタイム通知は `menuRealtimeEventCounterProvider` を介してUI層へ伝搬する構成が既に存在する。
- 既存ドキュメント（`docs/draft/menu_management_page_review_20251003.md`）から、カード＋リスト＋詳細パネル構成、およびUI改善要望が確認できる。

## 想定ユーザーストーリー
1. **カテゴリ整備**: 店舗管理者はカテゴリを追加・名称変更し、表示順をドラッグ&ドロップで調整したい。
2. **メニュー登録**: 料理を新規登録し、価格・説明・写真・カテゴリを設定する。必要に応じて販売可否を即時切り替えたい。
3. **在庫可用性確認**: 材料在庫に基づき販売可否が自動判定され、提供不可のメニューを検索・フィルタしたい。
4. **レシピ調整**: メニューに紐づく材料・必要量（レシピ）を編集し、在庫可用性が自動再計算されることを確認したい。
5. **リアルタイム監視**: 他端末での更新やSupabaseリアルタイムイベントを受け取り、画面が自動更新されることで情報の整合性を保ちたい。

## 機能要件（サービスからの推測を含む）
### 1. カテゴリ管理
- `getMenuCategories` の結果を表示順でリスト化し、件数・提供中数などの指標を表示。
- カテゴリ追加フォーム（名称、表示順初期値）を提供し、`createCategory` を実行。
- 各カテゴリカードから名称編集、並び替え（`updateCategory` / `updateCategoryOrder`）、削除（`deleteCategory`）を提供。
- 「すべてのカテゴリ」疑似項目を用意し、`getMenuItemsByCategory(null)` 呼び出しで全件表示できるようにする。

### 2. メニューアイテム管理
- 選択したカテゴリに紐づく `getMenuItemsByCategory` の結果をテーブル表示。
- 新規作成モーダルで `createMenuItem` を呼び出し、入力値は `InputValidator` のバリデーション要件（名称文字数、価格範囲、説明長など）を満たすUI制約を設ける。
- 行ごとの編集／削除操作から `updateMenuItem` / `deleteMenuItem` を実行し、更新後はテーブルを再フェッチ。
- 行アクションで `toggleMenuItemAvailability` を利用して販売可否バッジを即時更新。複数選択に対しては `bulkUpdateMenuAvailability` を後続課題として検討。
- 検索バーで `searchMenuItems` を呼び出し、カテゴリフィルタと組み合わせた結果を表示。

### 3. レシピ・材料連動
- メニュー選択時に `getMenuRecipes` をロードし、材料名称・必要量・任意フラグを一覧表示。
- 材料追加モーダルから `getMaterialCandidates` を利用して材料検索／選択を行い、`upsertMenuRecipe` で登録。登録後は `refreshMenuAvailabilityForMenu` で可用性を再取得。
- レシピ行に削除ボタンを設け、`deleteMenuRecipe` 実行後に可用性情報を更新。
- 必要量入力では負数禁止・0許容など `MenuService` のバリデーション仕様をUIで補助。

### 4. 在庫可用性と統計カード
- 画面上部に以下のステータスカードを表示：登録メニュー数、提供可能数、要確認（在庫不足）数。`bulkCheckMenuAvailability` と `getUnavailableMenuItems` を組み合わせて算出。
- `calculateMaxServings` を利用し、メニュー詳細に最大提供可能数を表示。
- 「在庫状況を再取得」ボタンから `autoUpdateMenuAvailabilityByStock` を実行し、完了後に一覧を更新。

### 5. リアルタイム更新・フェイルセーフ
- `menuRealtimeEventCounterProvider` の変化を監視し、イベント発生時にカテゴリ・メニュー・可用性データを再フェッチ。
- `MenuService.enableRealtimeFeatures` / `disableRealtimeFeatures` をライフサイクルで管理し、画面表示中のみ購読する。
- エラー発生時は `BaseErrorMsg` のメッセージを用いたダイアログ／トースト表示を行い、再試行導線を提供。

### 6. 周辺要求
- 大画面ではカテゴリ一覧／メニュー表／詳細パネルの3ペイン構成、小画面ではタブ切り替えにフォールバック。
- 日時表示フォーマットや通貨表示は `shared` コンポーネントに合わせる。
- ロールベースアクセス（自ユーザーID整合性）は `MenuService` 内で検証されるため、UI側では認証状態変化時の遷移制御に注力。

## UI / UX 方針
- `docs/draft/menu_management_page_review_20251003.md` の改善提案を反映し、カード高さ・テーブル操作列・詳細パネルを最適化。
- 状態表示（同期中、エラー、処理中）をページ上部にまとめ、ローディングインジケータを各パネル単位で表示。
- 色覚多様性に配慮し、ステータスバッジにはアイコン＋テキストラベルを併用。
- モーダル・サイドシートの遷移は `shared/components/layout` の既存コンポーネント（`SectionCard` など）を活用して統一感を持たせる。

## データフローと状態管理
- Riverpod を用いて `MenuManagementController`（新規作成）を `StateNotifier` として実装し、以下の状態を管理：
  - カテゴリリスト＋選択状態
  - メニュー一覧（検索・カテゴリフィルタ・可用性メタ情報）
  - 選択メニュー詳細（メタ、レシピ、最大提供数）
  - フォーム状態（作成・編集モーダル）、ローディングフラグ、エラーメッセージ
  - リアルタイムイベントカウンタと同期ステータス
- Service 呼び出しは `app/wiring/provider.dart` で既存の `MenuService` プロバイダーを注入。
- 非同期操作にはキャンセル耐性と競合制御（最新リクエストのみ反映）を設ける。

## 実装フェーズ
1. **基盤整備**
   - ルート用スタブページを作成し、`MenuService` プロバイダーを読み込む。
   - `MenuManagementState` / `MenuManagementController` を定義し、カテゴリ＋メニュー取得の最小フローを構築。
2. **カテゴリ管理UI**
   - カテゴリ一覧コンポーネント、追加・編集モーダル、ドラッグ&ドロップによる順序変更を実装。
   - 単体テストで `updateCategoryOrder` 呼び出しと楽観的UIの整合性を検証。
3. **メニュー一覧・編集フロー**
   - テーブル表示、検索・フィルタ、メニュー CRUD モーダル、提供可否トグルを実装。
   - `bulkCheckMenuAvailability` で取得した可用性を行バッジへ反映。
4. **レシピパネルと材料連動**
   - 詳細パネルにレシピタブを用意し、`getMenuRecipes` / `upsertMenuRecipe` / `deleteMenuRecipe` を接続。
   - 材料検索UIと在庫再計算のフィードバックを実装。
5. **ステータスカード・リアルタイム対応**
   - KPI カード、在庫再取得ボタン、リアルタイムイベント購読を追加。
   - エラー時の通知とリトライ導線を整備し、統合テストでイベント駆動の再取得を検証。
6. **仕上げ**
   - レスポンシブ調整、アクセシビリティチェック、国際化（必要文言のローカライズキー整備）。
   - ドキュメント更新（運用ガイド、テストカバレッジ報告）。

## テスト戦略
- **ユニットテスト**: `MenuManagementController` の状態遷移、サービス呼び出し例外処理、リアルタイムイベント応答。
- **ウィジェットテスト**: カテゴリ操作／メニューCRUD／レシピ編集モーダルに対する操作フロー。
- **ゴールデンテスト**: ステータスカードと3ペインレイアウトのレイアウト確認を追加検討。
- **統合テスト**: fake リポジトリを用いた在庫可用性計算→UI反映の一連の流れ。

## リリース手順
1. `feature/menu-management-page` ブランチで段階的に実装し、フェーズごとに PR を分割。
2. Staging 環境で Supabase テーブル（`menu_items` / `menu_categories` / `recipes`）のサンプルデータで画面動作を確認。
3. オフライン挙動（キャッシュ）とリアルタイム切断時のフォールバックを手動検証。
4. 本番反映後、初日に在庫自動更新ログとリアルタイムサブスクの健全性をモニタリング。

## リスクと対策
| リスク | 影響 | 対策 |
| --- | --- | --- |
| 在庫・レシピAPIの遅延によりUIがブロックされる | 操作待ち時間の増加 | 各API呼び出しを並列化し、ローディングスケルトンとタイムアウト処理を導入。失敗時は部分的な再試行を提供。 |
| 並び替えと在庫再取得の同時実行で状態が競合 | 表示が古いままになる可能性 | リクエストIDによる最新反映制御と、処理完了後の再フェッチ（`bulkCheckMenuAvailability`）を徹底。 |
| レシピ未設定メニューで在庫判断が緩くなる | 運用上の判断ミス | UIで「レシピ未登録」タグを表示し、警告リスト（要確認カード）に集約。 |
| リアルタイムイベント多発時の無限ループ再フェッチ | パフォーマンス低下 | イベントカウンタにデバウンスを設け、同一テーブルイベントでは差分更新のみ行う。 |
| 新規UIが他ページのデザインシステムと乖離 | 統一感欠如 | `shared/components/` の既存パターンを再利用し、デザインレビューを実施。 |

## フォローアップ項目
- `bulkUpdateMenuAvailability` を用いた一括操作UI（複数選択チェックボックス）の実装検討。
- メニュー売上データとの連動ダッシュボード（トップカードの詳細化）。
- オフラインキャッシュ戦略（メニュー・カテゴリのローカル保存）の策定。
