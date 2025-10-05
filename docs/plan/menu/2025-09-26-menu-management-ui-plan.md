# メニュー管理 UI 実装計画（2025-09-26）

本ドキュメントは、YATA アプリケーションにメニュー管理画面（Menu Management Page）を追加するための具体的な計画を示します。既存の注文管理・在庫管理との整合性を保ちつつ、店舗オペレーション担当者がメニューカテゴリ／商品／オプションを一元管理できるようにすることが目的です。

- 対象: `lib/features/menu/presentation/pages/menu_management_page.dart`
- 付随: `lib/features/menu/presentation/controllers/menu_management_controller.dart`、`lib/features/menu/presentation/widgets/*`
- 連携サービス: `MenuService`、`MenuItemRepository`、`MenuCategoryRepository`、`RecipeRepository`、`MaterialRepository`

## 背景と目的

- 現状の注文管理ページでは「販売する商品」の閲覧・選択のみが可能であり、商品そのものの管理は Supabase ダッシュボード等に依存している。
- メニューの在庫可否判定（`MenuService.checkMenuAvailability` など）は実装済みで、UI から操作できれば販売停止や価格変更をより迅速に行える。
- 将来的なオフライン対応を見据え、メニュー情報の編集と同期ステータス確認を UI 上で完結できる設計が求められる。

## スコープ

### Phase 1（このスプリントで実施）

1. **メインレイアウト構築**
   - 左カラム: カテゴリリスト + 検索/フィルター + 可用性ステータスサマリ。
   - 右カラム: アイテムテーブル（名称、価格、表示順、可用性、在庫可否など）と詳細パネル。
   - レスポンシブ対応: 幅 960px 未満では縦積み表示にフォールバック。

2. **カテゴリ管理機能**
   - 一覧表示（`MenuService.getMenuCategories`）。
   - 追加/編集/削除ダイアログ（名称・表示順・有効状態）。
   - ドラッグ & ドロップによる表示順更新（Optimistic UI → `MenuCategoryRepository.updateById`）。

3. **メニューアイテム管理機能**
   - カテゴリ別/全文検索（`MenuService.getMenuItemsByCategory` + クライアント検索）。
   - 詳細編集モーダル（名称、価格、説明、画像 URL、可用性、表示順）。
   - トグルボタンで `isAvailable` 切り替え（在庫不足時は警告表示）。
   - オプション編集への導線（モーダル内タブ）。

4. **在庫可用性インジケータ**
   - 列内バッジでリアルタイム在庫可否を表示（`MenuService.bulkCheckMenuAvailability`）。
   - 非同期取得中はローディングスピナー、失敗時は再試行ボタン。

5. **リアルタイム更新対応**
   - `MenuService.startRealtimeMonitoring` をページ初期化で呼び出し、破棄時に停止。
   - Supabase からのイベントで一覧を再フェッチする最小限のフローを構築。

6. **テレメトリ/ログ出力**
   - 主要操作（作成/更新/削除/可用性チェック）で `log.i` / `log.w` を送出。

### Phase 2（別イシューで対応）

- オフライン編集キューと差分適用 UI。
- レシピ（材料構成）とのリンク編集 UI。
- 複数店舗（マルチテナント）切り替え UI。

## 受け入れ条件（Acceptance Criteria）

- カテゴリ/アイテムの追加・編集・削除が UI から完了し、`MenuService` 経由で永続化される。
- 可用性トグルを OFF にすると、注文管理ページのメニュー一覧から該当アイテムが除外される（Riverpod Provider 経由で反映）。
- `bulkCheckMenuAvailability` に基づく在庫不足表示が UI 上で確認できる。
- Lints/Analyzer に新たなエラー・警告を増やさない。
- 画面幅 768px〜1200px で主要要素のレイアウトが崩れない。

## UI 構成とインタラクション

| セクション | 概要 | 主なコンポーネント |
|-------------|------|----------------------|
| ヘッダー | 画面タイトル「メニュー管理」、最終同期時刻、操作ショートカット | `YataAppTopBar`/カスタムアクションボタン |
| カテゴリパネル | カテゴリリスト + フィルター、追加ボタン、ドラッグソート | `ReorderableListView` + `YataListTile` |
| アイテムテーブル | 名前、価格、カテゴリ、在庫可用性、表示順、更新日時 | `PaginatedDataTable` 相当のカスタムテーブル |
| 詳細パネル | 編集フォーム、在庫サマリ、関連レシピ一覧 | `YataSectionCard` + フォームウィジェット |
| オプション編集 | タブ切り替えでオプションリスト・追加モーダル | `YataTabBar`, `YataBadge` |

- **アクセシビリティ**: すべてのアイコンボタンに `tooltip`、キーボード操作（Tab/Enter/Escape）対応を確保。
- **フィードバック**: 成功時は `YataSnackbar`, エラー時はダイアログで詳細表示。
- **リッチテキスト**: 価格は `NumberFormat.currency(locale: "ja_JP", symbol: "¥")` を利用。

## データフローと契約

1. ページ初期化時に以下を並列取得し `MenuManagementState` に格納:
   - `MenuService.getMenuCategories`
   - `MenuService.getMenuItemsByCategory(null)`
   - `MenuService.bulkCheckMenuAvailability(currentUserId)`
2. 変更操作（CRUD）後は、成功時にクライアントキャッシュを更新し、必要に応じて再フェッチ。
3. Riverpod 構成:
   - `menuManagementControllerProvider`（`StateNotifierProvider`）
   - `menuCategoryListProvider` / `menuItemListProvider` は内部で管理し、他画面とは分離。
   - リアルタイムイベント受信は `ProviderSubscription` で `ref.listen` し、差分適用。
4. エラーハンドリング:
   - Validation error → ダイアログでフィールド単位メッセージ表示。
   - Repository 例外 → `BaseErrorMessage` を `MenuError` にマッピングし Snackbar 表示。

## 実装タスク

- [ ] `MenuManagementState` と `MenuManagementController` の基本骨格を定義。
- [ ] 初期データ取得ロジックとリアルタイム購読のセットアップ。
- [ ] カテゴリパネル（リスト表示、CRUD、並び替え）実装。
- [ ] アイテムテーブル（検索、フィルタ、可用性表示）実装。
- [ ] アイテム編集モーダル + オプション編集 UI 実装。
- [ ] サービス呼び出し・入力検証・エラーハンドリング統合。
- [ ] テレメトリ/ログ、Snackbar、Tooltip など UX 細部調整。
- [ ] 単体テスト：StateNotifier、サービス連携のモックテスト、在庫表示ロジック。
- [ ] ドキュメント更新（guide/reference/intent への波及は別 PR で実施）。

## 変更影響

- ルーティング: `GoRouter` に `/menu` (仮) パスを追加し、サイドナビから遷移できるようにする。
- 共有コンポーネント: テーブル用の新規ウィジェットを `lib/shared/components/tables/` に追加する可能性あり。
- 権限: 現状は全ユーザーが編集可能。将来的なロール制御を見据え、Service 層でロールチェック用メソッドを用意する。

## ロールバック方針

- UI 追加のみでドメイン層を変更しないため、新規ページと関連プロバイダを削除すれば元の状態に戻る。
- 既存ルーティングの変更は最小化し、`GoRouter` の差分 revert で即時復旧可能。

## 今後の検討事項

- 画像アップロードとプレビューの UX 改善（サーバサイドリサイズ、サムネイル生成）。
- 可用性判定のキャッシュ有効期限と再取得間隔の調整。
- 在庫不足時の自動アクション（関連材料の発注リクエスト）検討。
- 多言語対応（英語 UI 切り替え）時のラベル管理方式。
