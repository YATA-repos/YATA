# 契約/実装 分離 再構成メモ（ドラフト）

作成日: 2025-09-15
担当: AIエージェント（Codex）

## 目的
- `infra/` にある実装群を「契約（インターフェース）」と「実装」に分離し、契約を `core/` へ配置する計画の前提整理。
- 既存実装とプロジェクト標準（docs/standards/architecture.md）との整合性確認。

## 現状スナップショット
- 参照: リポジトリ構成（要約）
  - `lib/infra/`
    - `batch/` … バッチ処理サービス実装
    - `local/cache/` … キャッシュ機構（TTL, Memory, Strategy, Mixin など）
    - `local/offline_queue/` … オフラインキュー（未実装/空 or 別所）
    - `logging/` … ログ実装（sinks, formatters, config, policy, top-level API）
    - `realtime/` … Realtime 管理（接続, 設定, mixin）
    - `repositories/base_repository.dart` … Supabase 前提の抽象ベース
    - `supabase/supabase_client.dart` … Supabase クライアント
  - `lib/core/`
    - `base/` … BaseModel など
    - `constants/query_types.dart` … フィルタ/クエリ型（Supabase 依存あり）
    - `logging/levels.dart` … 最小限の Level 定義
    - `utils/`, `validation/` … 付随ユーティリティ
  - 参考: `docs/standards/architecture.md` は「infra は core 抽象を実装」「features は core 抽象に依存」を想定

### 気付き
- `core/constants/query_types.dart` が `supabase_flutter` に依存しており、現状は core が外部実装に引きずられている（歴史的経緯）。
  - 契約定義は当面この型を再利用し、段階的に脱 Supabase を検討するのが現実的。
- `infra/repositories/base_repository.dart` は抽象だが Supabase 強結合。契約として `core/` に置くには粒度が粗い。
  - 方針: `core` には「DB 非依存な CRUD 契約」を置き、`infra` では Supabase ベースな実装（および必要であればベースクラス）を維持。

## 契約候補（初期案）
- Repository 契約（DB 非依存）
  - `CrudRepository<T, ID>`: `create/bulkCreate/getById/getByPrimaryKey/updateById/updateByPrimaryKey/deleteById/deleteByPrimaryKey/find/count` など。
  - クエリ表現には現行の `QueryFilter`, `OrderByCondition`（`core/constants/query_types.dart`）を暫定利用。
- Logging 契約
  - `Logger` インターフェース、`LogSink`, `LogFormatter`, `PiiMasker` の抽象。
  - 既存の `infra/logging` は実装として維持し、API 互換（トップレベル関数）はファサード経由で提供。
- Realtime 契約
  - `RealtimeConnection`, `RealtimeManager` 抽象（接続状態、購読 API、イベントディスパッチ）
- Cache 契約
  - `Cache<K,V>`, `CacheStrategy`, `CacheMetadata` 抽象。
  - `infra/local/cache` は実装（Memory, TTL など）。
- Batch 契約
  - `BatchProcessingService` の抽象（キュー投入、実行、リトライ、メトリクス）。
- Backend Client 抽象（任意/検討）
  - `DatabaseClient` や `RemoteClient` の薄い抽象を `core` に置くかは要検討。
  - 現在は `supabase_client.dart` でインフラ固有。features から直接使わない方針のため必須ではない。

## ディレクトリ案（契約のみ）
- `lib/core/contracts/`
  - `repositories/crud_repository.dart`
  - `logging/{logger.dart, log_sink.dart, log_formatter.dart, pii_masker.dart}`
  - `realtime/{realtime_manager.dart, connection.dart}`
  - `cache/{cache.dart, cache_strategy.dart, cache_metadata.dart}`
  - `batch/batch_processing_service.dart`

※ 命名・粒度は現行スタイル踏襲（snake_case, ディレクトリは複数形）。

## マイグレーション方針（高レベル）
1. `core/contracts/` に空抽象を定義（既存 API と型整合を優先）
2. `infra/` 実装を契約適合にリファクタ（implements/extends の見直し）
3. DI（Riverpod）の公開ポイントを契約型に寄せる
4. `features/` から `infra/` 直接参照を排除（契約経由に）
5. 互換層（必要に応じて）でトップレベル API を契約実装へ委譲
6. 段階的に `core/constants/query_types.dart` の Supabase 依存を縮退（後続タスク）

## リスク/留意点
- 既存の `BaseRepository` は Supabase/認証/マルチテナント前提のため、そのまま契約化は不可。
- `core` が `supabase_flutter` に依存している事実と折り合いを付ける必要（短期は現状踏襲）。
- 破壊的変更リスク: import パス・型置換・DI の影響範囲が広い。

## 代替案（却下理由）
- 先に `core/constants/query_types.dart` の Supabase 依存剥離 → その後契約導入
  - 筋は良いが初回の変更範囲が広く、タイムラインが伸びるため今回は採用しない案。

## オープン質問
1. 対象範囲: 今回の分離は「logging/realtime/cache/batch/repositories」の全てを一括で行いますか？段階導入の希望有無は？
2. ログ API の公開形態: 既存トップレベル関数（`i/w/e/f` 等）互換を維持しますか？
3. `features` からの直接 `infra` 参照が今後入る可能性はありますか？（原則禁止で進めて良いか）
4. `core/constants/query_types.dart` の Supabase 依存は短期容認で問題ありませんか？
5. 命名: 契約配置は `core/contracts/*` で問題ありませんか？（`core/logging` 配下に抽象を置く案もあり）

## 進捗メモ（作業ログ）
- 契約ディレクトリ `lib/core/contracts/*` 新設（repositories/logging/realtime/cache/batch）
- BaseRepository が CrudRepository 契約を `implements`（互換維持）
- Logging/Realtime のアダプタ追加 + DI公開（`lib/app/wiring/provider.dart`）
- Cache（Memory/TTL）のアダプタ追加 + DI公開
- features 層の Logger 参照を core 互換レイヤに切替（`lib/core/logging/compat.dart` 経由）
- Inventory の Realtime を契約化（`core/realtime/*` Mixin + DI注入）
- Order/Menu の Realtime を横展開（契約Mixin導入 + DI注入）
