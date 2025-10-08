# 注文管理パフォーマンス改善（サービス層最適化）計画（2025-10-05）

## 背景
- `docs/draft/order_management_perf_summary.md` の調査で、注文管理機能の初期ロードおよびカート操作におけるレスポンス遅延が顕在化した。
- Supabase への同一データ取得がサービス層で多重に発生し、UI では差分更新が行われず全件再読込が繰り返されている。
- ログ計測の欠落および Enum 不整合が残存しており、再発防止と追跡性向上の観点でも是正が必要。

## 現状の主要課題
| 分類 | 症状 | 根本原因 (調査抜粋) |
| --- | --- | --- |
| 初期ロード | `controller.loadInitialData` が初回 2.14s (うちカテゴリ取得 1.81s) | Supabase クエリ条件の重複適用とコールドキャッシュ依存 (_logs/least.log:86-125) |
| カート操作 | `addMenuItem` / `updateItemQuantity` が 500〜690ms、操作ごとに 8〜12 クエリ | `OrderStockService` → `OrderCalculationService` → `OrderManagementService` が同一 `cartId`/`userId` を逐次再取得 (_logs/least.log:140-483) |
| UI 更新 | `controller.refreshCart` / `loadCartSnapshot` が毎回 70〜140ms、`state.filteredMenuItems` 計測欠落 | 差分更新なしで全件フェッチ、Riverpod state が多段で再計算 |
| 計測・整合性 | FileSink 警告でログ欠落、`order_status_enum` の `canceled` で WARN | ロガー多重バインド / Enum 定義不一致により例外リトライが発生 (_logs/least.log:89,487) |

## 定量目標
| 項目 | 現状値 | 目標値 | 評価方法 |
| --- | --- | --- | --- |
| 初期ロード (`loadInitialData`) P95 | 1.9s | ≤ 200ms | DevTools timeline / Supabase query log |
| カート操作 (`add/update/remove`) P95 | 0.55〜0.69s | ≤ 220ms | `_logs/least.log` 相当の計測再取得 |
| カートリフレッシュ (`refreshCart`/`loadCartSnapshot`) | 0.10〜0.14s | ≤ 60ms または差分更新で非同期化 | Riverpod Provider Observer + Timeline |
| 計測欠落 (`filteredMenuItems`) | 24 件未計測 | 100% 追跡 | 新規計測ログの導入 |
| Enum 警告再発 | WARN あり | WARN 0 件 | Supabase ログ確認 |

## フェーズ構成
1. **Phase 0: 計測基盤の再整備** – ログ欠落と Enum 不整合を是正し、再計測の信頼性を確保する。
2. **Phase 1: 初期ロード高速化** – カテゴリ・メニュー取得のクエリ最適化とキャッシュ戦略を導入する。
3. **Phase 2: カート操作パイプライン最適化** – サービス層の逐次クエリを統合し、UI へ差分更新を提供する。

各フェーズ完了時に計測を更新し、次フェーズ着手可否を判断する。

## Phase 0: 計測基盤の再整備
- **対象**: `lib/shared/logging/*`, `lib/features/order/data/repositories/order_repository.dart`, Supabase `order_status_enum`
- **タスク**
  1. FileSink の多重バインド検知とバックオフ実装 (`Bad state` 再発防止)、テスト用にメモリログ出力へフォールバック。
  2. `state.filteredMenuItems` と UI 再描画のタイムライン計測を Riverpod Provider Observer もしくは `TimelineTask` で追加。
  3. `order_status_enum` の定義調整: DB 側 enum リネーム (`canceled`→`cancelled`) もしくはアプリ側マッピングの統一。移行スクリプトと後方互換テストを準備。
  4. 計測ログの出力先/ローテーションを整理し、再発時アラート (Sentry or Supabase log trigger) を設定。
- **完了条件**: 計測ログが 30 分以上無警告で記録され、`state.filteredMenuItems` の計測で再描画時間が算出できること。

## Phase 1: 初期ロード高速化
- **対象**: `lib/features/order/domain/services/order_management_service.dart`, `lib/features/order/data/queries/*`, Supabase テーブル (`menu_categories`, `menu_items`)
- **タスク**
  1. クエリビルダーの条件重複を整理 (`user_id`, `display_order` の二重適用を解消)。共通クエリをユーティリティ化しキャッシュキーを導入。
  2. Supabase/Postgres 側で `menu_categories(user_id, display_order)` など必要な複合インデックスを追加し、不要列の取得を削減。
  3. コールドスタート対策として、アプリ起動直後にカテゴリをプリフェッチする `WarmupService` を実装 (Riverpod `FutureProvider` 永続化、または Supabase キャッシュ API 活用)。
  4. 初期ロード後のデータ再利用: `loadInitialData(reset=true)` 再実行時は差分フェッチとローカルメモリキャッシュを使用。
  5. 計測: DevTools + Supabase ログで P95 200ms 以下を確認。改善結果を検証レポートに追記。
- **完了条件**: 3 回連続の計測で P95 ≤ 200ms、平均 120ms 以下。リグレッションテスト (`flutter drive` シナリオ) 合格。

## Phase 2: カート操作パイプライン最適化
- **対象**: `lib/features/order/domain/services/order_inventory_integration_service.dart`, `order_calculation_service.dart`, `order_management_service.dart`, `order_management_controller.dart`
- **タスク**
  1. 在庫確認→明細更新→合計再計算の処理を Supabase RPC (Postgres 関数) に統合し、ネットワーク往復を 1 回に削減。RPC 追加が困難な場合は `batch` API を使用。
  2. サービス層で取得した `OrderWithItems` を使い回すキャッシュ (`OrderContext`) を追加し、同一 `cartId` の再取得を避ける。キャッシュ失効はトランザクション完了時に限定。
  3. `controller.refreshCart` を差分更新に変更。サービス層から差分 (`CartMutationResult`) を返し、UI では対象項目のみ `state` を更新。
  4. Riverpod state を分割 (`cartSummaryProvider`, `cartItemsProvider`) し、`filteredMenuItems` の再計算回数を抑制。Provider 通知回数をテストで検証。
  5. カート操作レスポンス計測を自動テスト化 (Integration test で連続操作を実行し、ログから P95 を算出)。
- **完了条件**: 各操作 P95 ≤ 220ms、差分更新で UI リビルド件数が 30% 以上減少。機能回帰テスト (カート操作・チェックアウト) 合格。

## 作業ステップ（推奨順）
1. Phase 0 のタスクを 2 日以内に完了し、信頼できる計測環境を整える。
2. Phase 1 を 3 日目から着手し、クエリ最適化→インデックス追加→キャッシュ導入の順で実装。
3. Phase 1 の計測が目標を満たしたら Phase 2 へ移行。まず RPC / batch 実装、次いでキャッシュと差分更新を導入。
4. 各フェーズ完了ごとに `docs/draft/order_management_perf_summary.md` の更新版を作成し、改善状況を記録。

## 検証計画
- **計測ツール**: Flutter DevTools `Performance`, Supabase Query Log, Riverpod Provider Observer, カスタム Timeline 記録。
- **自動テスト**: `flutter test` + サービス層ユニットテスト、`flutter drive` の E2E シナリオ (初期ロード→カート操作→チェックアウト)。
- **ログ監視**: FileSink 復旧後、警告/例外を Sentry に転送し計測欠落を検出。

## リスクとフォローアップ
- RPC 追加に伴う DB 権限調整が必要。デプロイ手順にマイグレーションとロールバック計画を含めること。
- キャッシュ導入によりデータ整合性が崩れるリスク。失敗時のフェイルセーフ (即時完全同期) を必ず実装。
- 差分更新が UI 仕様と乖離する可能性。デザイナー/QA と操作感をレビューし、必要ならトーストやローディング表示を調整。

## 変更履歴
| 日付 | 変更内容 | 作成者 |
| --- | --- | --- |
| 2025-10-05 | 初版作成 | Codex |

---

改善進捗と追加知見に応じて本計画は適宜更新する。
