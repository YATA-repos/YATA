# 注文管理パフォーマンス計測サマリー

- 観測結果
    - [OMPerf] ログの主要操作を集計。閾値50ms超の処理が多い順に整理した統計は以下の通り。

      | 操作種別 | 計測件数 | 平均ms | 中央値ms | P95ms | 最大ms |
      |----------|----------|--------|---------|-------|--------|
      | controller.loadInitialData | 10 | 462.30 | 99.97 | 1992.42 | 2143.25 |
      | controller.addMenuItem | 4 | 514.39 | 506.98 | 669.27 | 690.60 |
      | controller.updateItemQuantity | 4 | 481.76 | 479.64 | 547.43 | 552.68 |
      | controller.removeItem | 2 | 309.44 | 309.44 | 341.40 | 344.95 |
      | controller.loadCartSnapshot | 14 | 102.64 | 110.13 | 138.50 | 138.97 |
      | controller.refreshCart | 10 | 106.81 | 110.44 | 139.84 | 140.43 |
      | page.menuGrid | 1 | 2.74 | 2.74 | 2.74 | 2.74 |
    - `state.filteredMenuItems` が24回発火しているが、処理時間が記録されておらず計測ギャップが存在。フィルタ再計算が多段で起きている可能性あり。
    - カート操作 1 回あたり Supabase への逐次クエリが 8〜12 本走っており、`OrderStockService`→`OrderCalculationService`→`OrderManagementService` が直列に同一 `cartId` と `userId` を再取得している（例: _logs/least.log:140-180, 420-483）。
    - チェックアウト完了後に `controller.loadInitialData reset=true` が 170ms で再実行されており、新規カート生成時も全データの再フェッチが走っている（_logs/least.log:560-611）。
    - ログ警告1: `WARN: FileSink write failed, disabling file sink. (Bad state: StreamSink is bound to a stream)`（_logs/least.log:89）。途中でファイル出力が無効化されており、以降のトレース欠落リスクがある。
    - ログ警告2: `OrderRepository` が `order_status_enum` に `canceled` を渡し `PostgrestException` を受けたため、互換モードで再取得している（_logs/least.log:487）。Enum定義の不整合が残存。
    - 致命的エラーは検出されず。Supabaseクエリは成功しているが、全体的にネットワーク往復に依存した時間が支配的。

- ボトルネック候補（閾値50ms超の代表例）
    1. `controller.loadInitialData` 初回呼び出しが 2.14s（line 125）。内訳として `controller.loadInitialData.getMenuCategories` が 1.81s（line 91, userId=e7171168-34e1-4dbb-9bfd-225ffc84d7c5）を占め、カテゴリ読み込みの Supabase クエリが律速になっている。二回目以降は 170ms 台まで短縮されているため、キャッシュもしくはデータウォームが影響している。
    2. カート操作系（`controller.addMenuItem` 690/466ms、`controller.updateItemQuantity` 553/518ms、`controller.removeItem` 345ms）。いずれも `cartId=ae7710b6-01c2-4794-a13b-dc64dc5d9e5d` を対象とし、`*.addItemToCart` や `*.updateCartItemQuantity` 下で在庫チェック→明細再読込→スナップショット再取得の順に複数クエリが直列化されている。
    3. カート更新後に必ず走る `controller.refreshCart.*` と `controller.loadCartSnapshot.*` が各 70〜140ms（lines 185, 287, 357 ほか）。操作ごとに全件再フェッチしており、UI 側でも `state.filteredMenuItems` が多重更新されていることと合わせて再描画オーバーヘッドが発生。

- 推奨アクション（優先度付き）
    1. **高**: `controller.loadInitialData` 内のカテゴリ取得クエリを最適化。Supabase 側で index 追加・レスポンス列の絞り込み・結果キャッシュ化を検討し、初回 1.8s を 200ms 未満に圧縮する目標。
        - 初回のみ 1.8s・2.1s まで膨らみ、その後 32ms/170ms に収束していることから、コールドキャッシュとネットワーク往復が主要因（_logs/least.log:91,125,577,611）。
        - `QueryUtils` ログでは user_id と display_order の同一条件を複数回適用しており（_logs/least.log:86-105）、クエリビルダー層での条件重複を除去することで Supabase 側の実行計画を簡素化できる。
        - Riverpod の永続プロバイダや Supabase Storage キャッシュでカテゴリとメニューの初回ロードを非同期プリフェッチする構成を検討。
    2. **中**: カート操作サービスでの連続クエリを整理。RPC での一括更新やサービス層キャッシュで `loadCartSnapshot` の再実行回数を削減し、`addMenuItem`/`updateItemQuantity` を 200ms 台に抑える。
        - 例としてアイテム追加時は、在庫確認→材料確認→明細 insert→合計更新→再フェッチ→スナップショット→UI 更新と 8 本以上のクエリが 550ms を要している（_logs/least.log:140-188）。
        - `controller.refreshCart.*` が操作ごとに 70〜140ms の再読込を起動しているため、サービス層で差分応答（更新行のみ）を返し UI では Riverpod の state を部分的に更新する設計に見直す。
        - Supabase RPC（Postgres 関数）化や batched upsert を活用して在庫チェックと明細更新を 1 往復に圧縮する。
    3. **中**: ロギングとデータ整合性の課題解消。FileSink のストリーム競合を修復して計測の欠落を防ぎつつ、`order_status_enum` の `canceled`/`cancelled` 不一致を解消して WARN を無くす。
        - FileSink の書き込み失敗により途中からファイル出力が無効化されており、将来的な計測比較が困難になる（_logs/least.log:89）。ロガーの多重バインド検知・バックオフ設定の導入が必要。
        - Enum 不一致による PostgrestException は互換モード再取得で隠蔽されており、DB 側 enum のリネームかアプリ側の値正規化を本修正すべき。
        - 同時に、`state.filteredMenuItems` の計測欠落を補うため UI 層に `Timeline`/`Stopwatch` 計測を追加し、再描画の体感遅延も可視化する。
