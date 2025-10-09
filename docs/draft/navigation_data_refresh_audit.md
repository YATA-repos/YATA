# ページ遷移時の情報更新調査メモ (2025-09-30)

## 調査概要

- **目的**: GoRouter を用いた画面遷移時に、各ページが最新データへ更新されるかを把握し、必要な改善点を抽出する。
- **対象**: `lib/app/router/app_router.dart` に登録されている全 8 ページ。
- **前提/仮定**:
  - すべての `StateNotifierProvider` は `AutoDispose` なしで定義されており、利用者がいなくてもプロバイダーは生存し続ける (Riverpod v2 の既定挙動)。
  - ページ遷移は `GoRouter` による push/replace を基本とし、Navigator のポップ時にプロバイダーが破棄されることはない。
  - Supabase などのバックエンド連携はモック/実装途上の箇所があるが、本調査では UI 層の実装とコントローラ層の挙動に限定する。

## 調査対象ページ一覧

| ルート | ウィジェット | データ取得元 | 主な更新 API |
| --- | --- | --- | --- |
| `/auth` | `AuthPage` | `authStateNotifierProvider` | `signInWithGoogle()` |
| `/order` | `OrderManagementPage` | `orderManagementControllerProvider` | `loadInitialData()`, `refresh()` |
| `/order-status` | `OrderStatusPage` | `orderStatusControllerProvider` | `loadOrders()` |
| `/history` | `OrderHistoryPage` | `orderHistoryControllerProvider` | `loadHistory()`, `refreshHistory()` |
| `/inventory` | `InventoryManagementPage` | `inventoryManagementControllerProvider` | `loadInventory()`, `refresh()` |
| `/menu` | `MenuManagementPage` | `menuManagementControllerProvider` | `_loadInitialData()`, `refreshAll()`, `refreshAvailability()` |
| `/analytics` | `SalesAnalyticsPage` | データなし (モック) | なし |
| `/settings` | `SettingsPage` | データなし (モック) | なし |

## 2025-09-30 更新: 自動リフレッシュ実装状況

- `RouteObserver<PageRoute>` を `AppRouter` で公開し、`MaterialApp.router` から参照できるようにした。
- `shared/mixins/route_aware_refresh_mixin.dart` を新設し、`RouteAware` の `didPush` / `didPopNext` をフックして `onRouteReentered()` を一元管理。
- 対象 5 ページ（`OrderManagementPage` / `OrderStatusPage` / `OrderHistoryPage` / `InventoryManagementPage` / `MenuManagementPage`）に mixin を適用し、ページ復帰時に各コントローラの `load...` / `refresh...` 系メソッドを実行。
   - 初回表示は既存のコントローラ初期化処理でカバーされているため、`shouldRefreshOnPush` は `false` に設定し二重ロードを回避。
   - リフレッシュ中 (`isLoading` など) は新規フェッチをスキップして多重実行を防止。
- `RouteAwareRefreshMixin` のユニットテストおよび `OrderStatusPage` を利用したウィジェットテストを追加し、ページ戻りで `OrderManagementService.getOrdersByStatuses` が再呼び出しされることを検証。

## ページ別の観察結果

| ページ | 初回ロード | 遷移再入時の自動更新 | 手動リフレッシュ UI | 備考 |
| --- | --- | --- | --- | --- |
| AuthPage | `ref.watch(authStateNotifierProvider)` が最新状態を即時反映。追加フェッチなし。 | 認証状態が変われば Provider 経由で即時反映。ページ遷移自体は追加処理なし。 | なし | 認証操作は `GoogleSignInButton` から `signInWithGoogle()` を呼び出し。 |
| OrderManagementPage | `OrderManagementController` コンストラクタで `loadInitialData()` 実行。 | Provider が生存している限り再呼び出しなし。戻ってきても前回の状態を保持。 | AppBar の `Icons.refresh` ボタン。 | ユーザー切替 (`currentUserIdProvider` 変化) 時のみ自動再ロード。 |
| OrderStatusPage | `OrderStatusController` コンストラクタで `loadOrders()` 実行。 | ページ再入時に追加ロードなし。 | AppBar の `Icons.refresh` ボタン → `loadOrders()`。 | ステータス更新 (`markOrderCompleted` / `cancelOrder`) 成功時に非同期で再ロード。 |
| OrderHistoryPage | `OrderHistoryController` コンストラクタで `loadHistory()` 実行。 | ページ再入時に追加ロードなし。 | AppBar の `Icons.refresh` ボタン → `refreshHistory()`。フィルター変更時は再ロード。 | ページング・フィルター操作で `loadHistory()` を再発火。 |
| InventoryManagementPage | `InventoryManagementController` コンストラクタ内で `loadInventory()` 実行。 | ページ再入時の追加ロードなし。 | AppBar の `Icons.refresh` ボタン。ダイアログ操作後も必要に応じて `loadInventory()` 呼び出し。 | リアルタイム監視は未統合。カテゴリ追加ダイアログから成功時に `loadInventory()`。 |
| MenuManagementPage | `_initialize()` 内で `_loadInitialData()` 実行後、`_startRealtimeMonitoring()` を起動。 | プロバイダーが生存していればリアルタイムイベント (`menuRealtimeEventCounterProvider`) で `refreshAll()` が自動発火。単純なページ戻りだけでは追加ロード不要。 | AppBar の `Icons.refresh` (`refreshAll()`)、在庫再取得ボタン (`refreshAvailability()`)。 | 唯一リアルタイム連携が有効。ライフサイクル終了時に `_menuService.stopRealtimeMonitoring()` を呼び出し。 |
| SalesAnalyticsPage | 静的モック。データ取得処理なし。 | なし | AppBar の `Icons.refresh` は SnackBar によるモック通知のみ。 | 今後の実装待ち。 |
| SettingsPage | 静的モック。データ取得処理なし。 | なし | AppBar の `Icons.refresh` は SnackBar によるモック通知のみ。 | 今後の実装待ち。 |

## 全体所見

1. **StateNotifierProvider のライフサイクル依存**: `AutoDispose` を使っていないため、ページから離れてもコントローラは破棄されず、再入時に最新データへ更新されない。手動リフレッシュに依存している。
2. **手動リフレッシュ UI の乱立**: 多くのページで AppBar に `Icons.refresh` が並び、ユーザー体験として一貫性はあるが、自動更新との併用設計が曖昧。
3. **リアルタイム統合の不均衡**: Menu 管理のみ Supabase Realtime を取り込み済み。他ページは未実装のため、データ変更が他端末から行われても画面反映されない恐れ。
4. **GoRouter 連携不足**: `GoRouter` の `refreshListenable` や `NavigatorObserver` を用いたフォーカス復帰時のデータ更新が組み込まれていない。

## 推奨アクション

1. **ページ復帰時の再読み込みフローを統一** _→ RouteAware + RouteObserver ベースで実装済み (2025-09-30)_
   - 当面は mixin を通じてルート復帰時リフレッシュを実行。`autoDispose` 採用案は必要に応じて今後検討。
2. **リアルタイム連携の対象拡張**
   - Order/Inventory 領域でも Supabase Realtime の監視を有効化し、`OrderStatusController` 等で自動更新を行う。
3. **手動リフレッシュの UX 明確化**
   - リフレッシュ操作が必要な状況 (例: バックエンド更新されない場合) を SnackBar などで案内。
   - 端末復帰時・一定時間経過後の自動同期を検討。
4. **ドキュメント化/テスト導入**
   - 今回の調査結果を基に、UI レイヤーのライフサイクル期待値を `docs/guide/` へ正式化する。
   - ナビゲーション復帰時の挙動を検証するウィジェットテストを追加。

## 今後の検討事項

- Supabase Realtime を有効化した際のイベント雨乞い (大量発火) に対するデバウンス処理の要否。
- `GoRouter` のサブツリー単位で `ProviderScope` を分け、ページ破棄と同時に状態をリセットする設計の検討。
- オフライン対応方針が定まった後、ローカルキャッシュの鮮度更新ポリシーを定義し、ページ復帰時の同期要件を見直す。