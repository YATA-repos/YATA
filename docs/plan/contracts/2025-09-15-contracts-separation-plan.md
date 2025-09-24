# 契約/実装 分離 再構成計画（Contracts → core, Implementations → infra）

作成日: 2025-09-15
状態: 合意反映済み（One-shot migration）
対象: infra 全般（logging, realtime, local/cache, batch, repositories, supabase client 関連）

## 目的と非目的
- 目的
  - `infra/` 実装群を契約（インターフェース）と実装に明確分離し、契約を `core/` に集約。
  - features 層は `core` の契約にのみ依存させ、`infra` への直接依存を解消。
  - プロジェクト標準（docs/standards/architecture.md）との一致を強化。
- 非目的
  - Supabase 依存の完全除去（短期は行わない）
  - 既存 API の大幅な破壊的変更（必要最小限に抑制）

## ガイドライン（整合性）
- 参照: `docs/standards/architecture.md:1`
  - infra → core（実装は core の抽象を実装）
  - features → core（契約に依存）; features → infra は禁止
  - 相対インポート維持、命名規則は現行踏襲（snake_case, ディレクトリは複数形）
- 既存 `core/constants/query_types.dart` は Supabase 依存を含むため、短期は暫定利用とし段階的剥離は後続課題とする。

## 前提合意事項（ユーザー回答反映）
- 導入方式: 一括導入で実施（One-shot migration）。
- ログ API: 既存トップレベル関数の互換を維持する（`t/d/i/w/e/f` 等）。
- 依存方針: features → infra は禁止、features は core の契約みに依存。
- Supabase 依存: 短期容認。ただし改善対象として明示し、分離の追補計画を残す。
- 契約配置: `lib/core/contracts/` 配下に集約。

## 目標ディレクトリ構成（契約）
```
lib/core/contracts/
  batch/
    batch_processing_service.dart
  cache/
    cache.dart
    cache_strategy.dart
    cache_metadata.dart
  logging/
    logger.dart
    log_sink.dart
    log_formatter.dart
    pii_masker.dart
  realtime/
    connection.dart
    realtime_manager.dart
  repositories/
    crud_repository.dart
```

## 契約と実装の対応表（初期）
- batch
  - 契約: `core/contracts/batch/batch_processing_service.dart`
  - 実装: `infra/batch/batch_processing_service.dart`（implements）
- cache
  - 契約: `core/contracts/cache/{cache.dart, cache_strategy.dart, cache_metadata.dart}`
  - 実装: `infra/local/cache/*`（implements）
- logging
  - 契約: `core/contracts/logging/{logger.dart, log_sink.dart, log_formatter.dart, pii_masker.dart}`
  - 実装: `infra/logging/*`（implements）。トップレベル API はファサードから契約に委譲。
- realtime
  - 契約: `core/contracts/realtime/{connection.dart, realtime_manager.dart}`
  - 実装: `infra/realtime/*`（implements）
- repositories
  - 契約: `core/contracts/repositories/crud_repository.dart`（DB 非依存）
  - 実装: `infra/repositories/base_repository.dart`（Supabase 前提の具象/基底）。必要に応じて `SupabaseCrudRepositoryBase<T,ID>` として契約を実装/委譲。

## 実施ステップ
1. 契約スケルトンの追加（core）
   - 各カテゴリのインターフェースを追加し、戻り値/引数は現行の利用箇所から逆算して最小限の共通 API を定義。
   - クエリ表現は `QueryFilter`, `OrderByCondition`（`lib/core/constants/query_types.dart`）を暫定利用。
2. 実装の契約適合化（infra）
   - `implements` を付与、足りないメソッド署名を補正。
   - Supabase 固有の強結合 API は実装側に温存。契約 API に丸め込む（ラップ）
3. DI（Riverpod）の公開点を契約に変更
   - provider の型を契約型に差し替え、上位層に漏れる具象型を遮断。
4. features の依存整理
   - features が参照する型/関数を契約経由に置換（直接 `infra` 参照を除去）。
5. 互換 API の維持（必要に応じて）
   - `infra/logging` のトップレベル関数は既存シグネチャ維持で、中で契約実装へ委譲。
6. 動作検証と調整
   - ビルド、最低限の手動検証。既存ユニットテストがあれば修正。

## DI（Riverpod）方針
- `app/wiring/provider.dart` に集約（標準踏襲）
- 各契約向けの `Provider`/`NotifierProvider` を公開し、`override_{dev,prod}.dart` で実装切り替え可能に。

## 破壊的変更の扱い
- 一括導入で単一ブランチ/PR で進める（合意事項）。
- 可能な限りラッパー/compat 層で既存呼び出しを吸収。

## 検証
- `flutter analyze` のエラーゼロ
- `flutter build` に成功
- ログ/キャッシュ/リポジトリの主要ユースケースの手動確認

## リスクと対策
- Supabase 依存が core に漏れている
  - 短期は容認。契約導入後、段階的に `query_types.dart` を抽象化して置換
- features が infra に直接依存している（潜在）
  - 参照検出し、契約経由へ順次置換
- `BaseRepository` の契約化
  - 直接移動せず、`CrudRepository` 契約 + Supabase 実装の二層で整理

## マイルストーン/見積もり（粗）
1. 契約スケルトン追加: 0.5〜1.0d
2. logging/realtime/cache の適合: 1.0〜1.5d
3. repositories（基底+各機能）: 1.0〜2.0d
4. DI/置換/検証: 0.5〜1.0d

## 受け入れ条件
- features は `infra` を直接参照しない
- `core/contracts/*` に契約が整備され、`infra/*` はそれを実装
- ビルド/解析に成功し、主要機能の回帰がない

## オープン質問（要回答）
- 一括導入 or 段階導入の希望
- ログのトップレベル API 互換維持の是非
- `query_types.dart` の短期 Supabase 依存容認の可否
- 契約配置を `core/contracts/*` で進めてよいか

## 改善メモ（短期容認する技術的負債）
- `lib/core/constants/query_types.dart` が `supabase_flutter` に依存している。
  - 短期方針: 互換性維持のため暫定利用（契約のクエリ型は当面これを再利用）。
  - 改善方針（後続タスク）:
    1) `QueryFilter`/`OrderByCondition` を外部実装非依存の純粋な抽象に再設計。
    2) Supabase 向けの変換層（Adapter）を `infra/` に配置。
    3) 影響箇所（repositories, query utils）を順次置換。

## 付記
- 将来タスク: `core` の Supabase 依存縮退（`query_types.dart` の再設計、Adapter 導入）
