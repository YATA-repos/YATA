# ページ遷移時自動リフレッシュ導入計画 (2025-09-30)

## 1. 背景
- 主要画面の `StateNotifierProvider` は `autoDispose` を使用していないため、ページから離脱しても状態が保持される。
- 戻ってきた際に自動で最新データへ更新されず、ユーザーは AppBar のリフレッシュ操作に依存している。
- Realtime 連携はメニュー管理のみであり、全画面での即時同期を実現する計画は現時点では優先度が低い。
- 利用者の「戻ってきたのに内容が古い」体験を改善するため、**画面遷移の復帰タイミングで `refresh()` を自動実行する仕組み**を整備する。

## 2. 目的
- GoRouter で管理するページにおいて、`didPush`/`didPopNext` をトリガーに最新データを取得する。
- 既存の手動リフレッシュ UI（AppBar ボタンなど）と併存可能な仕組みとする。
- 再利用可能な共通コンポーネント／Mixin を整備し、今後新しいページにも簡単に適用できる状態にする。

## 3. スコープ
### 3.1 対象ページ
| ルート | ウィジェット | リフレッシュ API |
| --- | --- | --- |
| `/order` | `OrderManagementPage` | `OrderManagementController.refresh()` |
| `/order-status` | `OrderStatusPage` | `OrderStatusController.loadOrders()` |
| `/history` | `OrderHistoryPage` | `OrderHistoryController.refreshHistory()` |
| `/inventory` | `InventoryManagementPage` | `InventoryManagementController.refresh()` |
| `/menu` | `MenuManagementPage` | `MenuManagementController.refreshAll()` |

> 備考: `/auth`, `/analytics`, `/settings` は今回非対象。Auth は Riverpod の状態監視で即時反映済み、Analytics/Settings はモック表示のため刷新は不要。

### 3.2 範囲外
- 30 秒ごとの周期更新や Realtime 連携の追加
- StateNotifierProvider の `autoDispose` 変更
- バックエンド API の改修

## 4. 要求事項
### 4.1 機能要件
1. ページ初回表示 (`didPush`) と復帰 (`didPopNext`) 時にデータ取得メソッドを自動実行する。
2. リフレッシュ中に追加のリフレッシュを抑止し、完了後にのみ再度実行可能とする（多重呼び出し防止）。
3. 例外発生時は既存のエラーハンドリング（StateNotifier 内の `errorMessage` 更新など）に委ねる。
4. 既存の手動リフレッシュボタンによる挙動と競合しない。

### 4.2 非機能要件
1. 各ページへの導入コストを最小化するため、`RouteAware` 登録を肩代わりする共通 Mixin / Widget を用意する。
2. 既存テストの破壊を避ける。必要に応じて Widget テストを追加し、挙動を検証する。
3. Dart/Flutter のライフサイクル（特に Web/Windows など複数プラットフォーム）でも問題が発生しないこと。

## 5. 技術アプローチ
### 5.1 RouteObserver の導入
- `MaterialApp.router` に `navigatorObservers: [routeObserver]` を設定する。GoRouter 利用のため、`GoRouterObserver` から `RouteObserver<PageRoute>` を提供する仕組みを追加。
- 既存の `AppRouter.getRouter` を拡張し、`routeObserver` を外部公開できるようにする。

### 5.2 共通 Mixin の実装
- `lib/shared/mixins/` に `RouteAwareRefreshMixin<T extends StatefulWidget>` を新設。
- 必須メンバー: `Future<void> onRouteReentered()` を各画面 `State` で実装。
- Mixin 側で `RouteAware` を実装し、`didPush` と `didPopNext` で `onRouteReentered()` を呼び出す。
- 二重実行防止用に内部で `bool _isRefreshing` を管理し、処理中はスキップする。
- `dispose` で `routeObserver.unsubscribe(this)` を呼び忘れないようにする。

### 5.3 ページ実装への組み込み
- 対象ページの `State` クラスに Mixin を追加し、`onRouteReentered` で該当コントローラの `refresh` 相当メソッドを呼ぶ。
- 既存の `initState` で初回ロードを呼んでいる画面と整合を取るため、`didPush` の実行タイミングと `initState` の呼び出し順を確認。必要であれば `didPush` での呼び出しを省略し、`didPopNext` のみ利用する（初回ロードが既に実行されているため）。
- `mounted` チェックを徹底し、ナビゲーション中断時の例外を避ける。

### 5.4 競合制御
- `StateNotifier` 側が `isLoading` フラグを提供している場合は、Mixin 内で `if (isLoading) return;` のように監視する。UI 側の `ref.read(provider)` を参照するか、`ref.listen` を活用して状態変化を追跡する。
- もしくは Mixin 内で `future = controller.refresh()` の結果を待ち、完了後に `_isRefreshing = false` とする仕組みを採用。

## 6. 実装タスク
1. **ルーター改修**
   - `lib/app/router/app_router.dart` へ `RouteObserver<PageRoute>` のインスタンス追加。
   - `MaterialApp.router` へオブザーバーを渡すためのエントリーポイント（`lib/main.dart`）更新。
2. **共通 Mixin 作成**
   - `RouteAwareRefreshMixin` の作成とテスト用スタブ実装。
   - Mixin のユニットテスト（`didPush`/`didPopNext` シナリオ、二重実行防止）を作成。
3. **ページごとの適用**
   - `OrderManagementPage`、`OrderStatusPage`、`OrderHistoryPage`、`InventoryManagementPage`、`MenuManagementPage` の `State` クラスを更新。
   - `onRouteReentered` 内で対応するコントローラメソッドを呼び出す実装を追加。
   - 既存 AppBar リフレッシュ等との相互作用を確認し、重複処理があれば共通化。
4. **ドキュメント更新**
   - `docs/draft/navigation_data_refresh_audit.md` に進捗を追記。
   - 実装後、`docs/guide/` または `docs/reference/` への正式反映を検討。

## 7. テスト戦略
- **ユニットテスト**: Mixin 単体で `didPush` / `didPopNext` が期待通り呼ばれるか（MockRouteObserver を利用）。
- **ウィジェットテスト**: `pumpWidget` で 2 画面構成のテストラッパーを作り、画面遷移 → 復帰で `refresh()` が呼ばれることを `FakeController` を通して検証。
- **回帰テスト**: 既存の注文/在庫等のフローが変わらないことを手動確認。特に、戻る操作を繰り返してもクラッシュしないこと。

## 8. ロールアウト方針
1. まずは **OrderStatusPage** と **InventoryManagementPage** の 2 画面で検証的に導入し、フィードバックを得る。
2. 問題なければ残りの対象ページに順次展開。
3. 全画面適用後、不要になった重複ロジック（個別の `NavigatorObserver` 実装など）があれば整理する。

## 9. リスクと対策
| リスク | 説明 | 対応策 |
| --- | --- | --- |
| 無限リフレッシュ | `refresh()` 内で `context.go()` などを呼ぶと再度 `didPush` が発火し続ける可能性 | Mixin 内で多重実行を抑止し、`refresh()` は UI 遷移を行わないようリファクタリングを確認 |
| 余計なトラフィック | ページに戻るたびに API を読みに行く | 必要であれば `lastFetchedAt` を参照し、一定時間以内の再取得をスキップする仕組みを追加検討 |
| 異常系の UX | エラー時に SnackBar が重複して表示される | StateNotifier 側で重複通知を防止する or Mixin でリトライポリシーを設ける |
| 非同期キャンセル | ページ離脱中に `refresh()` が走り、完了時に `setState` が呼ばれてクラッシュ | `if (!mounted) return;` を徹底し、StateNotifier 経由の更新であれば UI 側の `mounted` チェックを実装 |

## 10. 完了条件
- 対象 5 ページで、戻る/進む操作時に最新データが取得されることを確認。
- Mixin 化により、今後新しいページへも最小改修で適用できる。
- テストが全て成功し、CI で差分が問題ないこと。
- ドキュメントが最新状態に更新され、作業ログが残っていること。

---

### メモ
- 今回は「30 秒ごとの周期更新」を実装範囲から除外している。ユーザーのフィードバックや運用状況を見つつ、必要になれば別計画で検討する。
- `RouteAware` を利用する場合、Navigator の階層やモーダルダイアログの扱いに注意。モーダル表示後の `didPopNext` でもリフレッシュが発火することを想定し、必要であればホワイトリスト／ブラックリストを検討する。
