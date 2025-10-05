# UI層とバックエンド接続状況レビュー

本書は、現時点のYATAアプリにおける各UIページとSupabaseバックエンドの接続状況を整理した調査メモです。主要なUIからサービス層・リポジトリ層を経由してSupabaseへ到達するかを確認し、未接続の領域や今後の課題を明示します。

## 全体構成の確認ポイント

- **Supabase初期化**: `lib/main.dart` にて `.env` から `SUPABASE_URL` と `SUPABASE_ANON_KEY` を読み込み、`SupabaseClientService.initialize()` を実行。値が無効な場合は初期化をスキップするため、環境変数未設定時はUIからバックエンドへ到達しない。
- **DIと依存線**: `lib/app/wiring/provider.dart` で Riverpod Provider を定義。UI層のStateNotifierはサービスを参照し、サービス層は契約 (`core/contracts/...`) を介してリポジトリを受け取る構造になっている。
- **リポジトリ実装**: `lib/infra/repositories/generic_crud_repository.dart` は `BaseRepository` を継承し、`SupabaseClientService.client` 経由で `from(tableName)` を発行。ユーザーIDフィルタは `BaseRepository` で自動注入される。
- **リアルタイム監視**: `lib/infra/realtime/realtime_manager.dart` が Supabase Realtime API を扱い、サービス層（Inventory/Menu/Order）から `RealtimeManagerAdapter` 経由で利用される。

## 主要画面別の接続状況

### `/` 注文管理ページ
- **UI → 状態管理**: `OrderManagementPage` → `OrderManagementController`。
- **サービス連携**:
  - メニュー一覧取得・カテゴリ同期は `MenuService` → `MenuItemRepository` / `MenuCategoryRepository`。
  - カート操作は `CartService` → `CartManagementService` → `OrderRepository` / `OrderItemRepository`（`GenericCrudRepository` 経由で Supabase と通信）。
  - 在庫確認は `OrderStockService` が材料・レシピリポジトリを通じてSupabaseを参照。
- **所感**: CRUD 操作と在庫計算はいずれもSupabase経由で実行され、UI操作が直接データベースに反映される実装になっている。

### `/history` 注文履歴ページ
- **UI → 状態管理**: `OrderHistoryPage` → `OrderHistoryController`。
- **サービス連携**: `OrderService.getOrderHistory()` が `OrderManagementService` を呼び出し、`OrderRepository`・`OrderItemRepository` からデータを取得。検索・日付フィルタの一部はサービス層でメモリフィルタされるが、元データはSupabaseから取得している。
- **所感**: バックエンド接続は成立。今後は Supabase 側でのフィルタリング最適化が検討余地。

### `/inventory` 在庫管理ページ
- **UI → 状態管理**: `InventoryManagementPage` → `InventoryManagementController`。
- **サービス連携**:
  - 初期ロードで `InventoryService` 経由でカテゴリ・在庫情報を取得。`MaterialManagementService` や `StockLevelService` が材料系リポジトリを呼び出す。
  - 在庫調整は `InventoryService.updateMaterialStock()` → `StockOperationService` → `MaterialRepository` / `StockTransactionRepository` 等を介して Supabase に反映。
- **所感**: データ取得・更新ともにSupabaseと直結。`deleteSelected()` が未接続でUI内のダミー動作に留まる点のみ要改善。

### `/menu` メニュー管理ページ
- **UI → 状態管理**: `MenuManagementPage` → `MenuManagementController`。
- **サービス連携**: `MenuService` がカテゴリ・メニューのCRUDを担当し、`MenuItemRepository` / `MenuCategoryRepository` を通じてSupabaseへアクセス。可用性再計算やレシピ照会も同様にリポジトリを経由。
- **所感**: CRUD操作・リアルタイム監視ともに接続済み。UI操作が即時にSupabaseへ反映される。

## サービス層・リポジトリの要点

- **共通CRUD実装**: `GenericCrudRepository<T>` が `BaseRepository` を通じてSupabaseクエリを実行し、UI層からのほぼ全てのデータアクセスの窓口になっている。
- **マルチテナント制御**: `BaseRepository` が `user_id` フィルタを自動付与し、`currentUserIdProvider`（`features/auth/presentation/providers/auth_providers.dart`）から取得したユーザーIDで分離。
- **リアルタイム**: Inventory/Menu/Order のサービスは `RealtimeServiceContractMixin` を実装し、`RealtimeManagerAdapter` を介して Supabase Realtime Channel を購読している。現状はイベントログ出力が主だが、UIへの状態反映を行うための仕組みは接続済み。

## 未接続または部分実装の領域

- **認証UI**: `AuthRepository` は Supabase Auth を直接利用する実装だが、ログイン画面などUIレイヤーは未実装。`AuthState` はモック初期値のまま。
- **分析UI**: `AnalyticsService` と `DailySummaryRepository` はSupabaseと連携しているものの、`features/analytics/presentation` 配下にページやコントローラは未作成。
- **在庫一括削除**: `InventoryManagementController.deleteSelected()` はUI上の差分更新のみで、まだ `InventoryService` 経由の削除APIには接続されていない。
- **環境変数依存**: `.env` にSupabaseのURL/キーが未設定の場合、アプリは警告を出して初期化をスキップする。その状態ではUIとバックエンドの接続は成立しない。

## 参考ソース一覧

- `lib/main.dart` — Supabase初期化およびアプリ起動。
- `lib/app/wiring/provider.dart` — RiverpodによるDI構成とサービス/リポジトリの合成。
- `lib/infra/repositories/base_repository.dart` — Supabaseクエリ実装・マルチテナント制御。
- `lib/features/inventory/services/*` — 在庫系サービス経由でのSupabase操作。
- `lib/features/order/services/*` — 注文・カート・履歴処理のサービス郡。
- `lib/features/menu/services/menu_service.dart` — メニュー管理におけるCRUDとリアルタイム対応。
- `lib/infra/realtime/realtime_manager.dart` — Supabase Realtime Channel とのブリッジ実装。

---

以上の通り、公開済みの主要UIページ（注文・履歴・在庫・メニュー）はいずれもサービス層を介してSupabaseバックエンドと接続済みです。一方、認証画面や分析ダッシュボードについてはUI層未実装のため、今後の接続作業が必要です。
