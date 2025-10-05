# 注文管理パフォーマンス計測計画（2025-10-03）

## 背景と目的

- `OrderManagementPage` のパフォーマンス改善を進めてきたが、体感レベルで明確な改善が得られていない。
- どの処理がボトルネックになっているかを特定するため、処理フロー各所に計測ポイントを設置し、定量データを収集する。
- 計測データをもとに優先度の高い改善対象を決定し、最終的に UI 応答時間の短縮とフレームレート安定化を図る。

## 計測方針

- 「ユーザー操作から UI 更新まで」のレイテンシを把握することを重視し、UI スレッド・サービス呼び出し・データ変換を段階的に分解して測定する。
- Flutter 側では `TimelineTask` / `Timeline.timeSync` の埋め込みで DevTools のフレームタイムに連携しつつ、`debugPrint` によるログ出力を併用する。
- 長期的には `package:logging` 経由で Supabase などの外部ストレージへ送信できる仕組みを検討するが、本計画ではローカル収集（ログ + DevTools トレース）を範囲とする。

## 計測対象ポイント

1. **初期データロード**
   - `OrderManagementController.loadInitialData`
   - メニューカテゴリ取得 (`getMenuCategories`)、メニュー一覧取得 (`getMenuItemsByCategory`)、カート取得 (`getActiveCart` + `_loadCartSnapshot`) の各区間
   - 目的: ネットワーク遅延とデータ整形のバランスを把握
2. **メニュー絞り込み処理**
   - `filteredMenuItems` アクセス時
   - `searchQuery` / `selectCategory` ハンドラでフィルタ後のリスト再計算まで
   - 目的: 状態更新→Grid再描画までの遅延を確認
3. **Grid ビルド**
   - `_MenuSelectionSectionState` 内 `GridView.builder` の `itemBuilder`
   - 代表的な `YataMenuItemTile` ビルド時間のサンプリング
   - 目的: UI スレッドのレンダリング負荷を把握
4. **カート更新フロー**
   - `_addMenuItem` / `_updateItemQuantity` / `_removeItem` の開始〜`_refreshCart` 完了まで
   - `_refreshCart` における `getOrderWithItems` 呼び出しと状態マッピング
   - 目的: サービス呼び出し / 状態同期のボトルネック特定
5. **注文メモ更新**
   - `updateOrderNotes` 呼び出し時の処理時間とリビルド発火まで
   - 目的: フィールド入力によるUI全体負荷を確認

## 実装タスク

### Phase 1: ロギング基盤整備
- `lib/features/order/presentation/controllers/order_management_controller.dart`
  - タイムライン計測ヘルパー（`_traceSection(String name, FutureOr<void> Function())` など）を追加。
  - 非同期処理に `TimelineTask` を挿入し、完了時に `debugPrint` で計測結果を出力。
- `lib/features/order/presentation/pages/order_management_page.dart`
  - Grid ビルドで計測可能な軽量ラッパー（`_ProfiledMenuTile`）を検討。
- 設定で計測有無を切り替えられるよう `bool enablePerformanceTracing` を Provider / 定数で制御。

### Phase 2: 個別処理への計測適用
- 初期ロード系 (`loadInitialData`, `_refreshCart`) に区間計測を追加。
- UI イベントハンドラ (`addMenuItem`, `updateItemQuantity`, `selectCategory`, `updateSearchQuery`) に開始/終了ログを挿入。
- `filteredMenuItems` でフィルタリング前後の件数と処理時間を測定。
- Grid `itemBuilder` で 1/N サンプリング（例: index % 20 == 0 のときのみ計測）を導入し、過度なオーバーヘッドを避ける。

### Phase 3: データ収集と可視化
- DevTools `Performance` タブで計測イベントを確認し、代表的な操作（初期表示、検索、数量更新）それぞれのシナリオを記録。
- ログを解析し、以下の観点で集計:
  - API 呼び出し時間、状態更新時間、UI 再描画時間の中央値 / P95
  - 操作別（追加、削除、検索）における全体レイテンシ
- 必要に応じて簡易レポート（CSV or Markdown）を作成し、改善対象を優先順位付け。

## リスクと対策

- **オーバーヘッドの増加**: 計測コードが UI フレーム時間を悪化させる可能性 → サンプリングと切替フラグで抑制。
- **ログノイズの増加**: `debugPrint` が多すぎると解析が困難 → プレフィックス付与 (`[OMPerf] ...`) と閾値フィルタを追加。
- **本番ビルドへの混入**: 計測コードがリリースに残るリスク → `kDebugMode` / `assert` ガードで除外。

## 成果物

- 計測コードとトレースが有効になった `OrderManagementController` / ページ実装
- 計測ログのサンプル (`/logs/perf/order-management-YYYYMMDD.txt` など任意) ※ファイル出力は任意
- 計測結果のサマリ（別ドキュメント/スプレッドシート）
- 次フェーズの改善項目リスト

## スケジュール目安

| フェーズ | 期間 | 主な成果 |
|----------|------|----------|
| Phase 1  | 1日 | 計測ヘルパー導入・フラグ制御実装 |
| Phase 2  | 2日 | 各処理への計測適用・ログ整形 |
| Phase 3  | 1-2日 | データ収集・分析メモ作成 |

## 次のアクション

1. 計測コードの導入可否とトグル方式（ビルド設定かメニュー設定か）をチームで決定。
2. 計測データの保存形式（ログファイル/DevTools トレース）の標準化を決める。
3. Phase 1 を実装し、予備計測を行ってオーバーヘッドを確認。
