# YATA Architecture Standards

Status: Accepted — reflects agreed migration decisions.

## Purpose
- Define directory structure, layering, and dependency rules.
- Reduce ambiguity during the migration from `lib/` to `_lib/`.

## Layers & Responsibilities
- app: boot, env, DI, routing composition
- core: cross-cutting concerns and domain-agnostic primitives (base, constants, validation, logging abstractions, utils)
- infra: external IO and integrations (supabase, realtime, logging impl, storage, batch)
- features: vertical slices per domain (models, repositories, services, presentation, routing)
- shared: UI design system (components, foundations, patterns, themes, assets)

## Directory Structure (final)
```
_lib/
  app/
    main.dart
    router/
      app_router.dart
      guards/
    wiring/
      provider.dart
      override_{dev,prod}.dart
  core/
    base/
    constants/
    logging/       # abstractions (levels, mixins)
    utils/
    validation/
  infra/
    local/
    logging/       # concrete impl (sinks, formatters)
    realtime/
    supabase/
    repositories/
    batch/
  features/
    <domain>/
      dto/
      models/
      repositories/
      services/
      presentation/{controllers,pages,widgets}
      routing/
  shared/
    assets/
    components/
    foundations/
    patterns/
    themes/
```

Note: Migration is performed in one shot; no temporary wrapper for `main.dart` is required. After successful migration and validation, `_lib/` will be renamed to `lib/` and the old `lib/` will be removed.

## Allowed Dependencies
- app → {core, features, infra}
- features → core (prefer abstractions/contracts). Avoid direct infra usage; depend on repositories/services contracts.
- infra → core（実装は core の抽象を実装する）。No infra → features.
- shared → core（UI-only; no infra）
- 禁止: feature → feature 直接依存（やり取りは core 抽象 or app 層の合成経由）

## Imports
- 相対インポートを維持（移行中も、移行後の構成でも相対で統一）。
- 外部パッケージは `package:` を使用。プロジェクト内のクロスルートな参照（`lib/` ↔ `_lib/`）は移行一括実施のため発生させない。
- Barrel の許可範囲: `features/` 配下、`core/` 配下、`shared/` の themes および widgets 配下のみ。

## DI (Riverpod)
- Top-level providers は `app/wiring/provider.dart` に集約（環境別オーバーライドは `override_{dev,prod}.dart`）。
- 各 feature のエントリポイント（providers/controllers）は app 層で合成。
- 命名は現状の `lib` と `_lib` の規則を踏襲（ファイルは snake_case、ディレクトリは複数形）。

## Routing (go_router)
- ルーティングは `app/router/app_router.dart` に集約し、各 feature の定義を合成。
- ガードは `app/router/guards/`（feature 固有は各 feature 側でも可、ただし合成は app 層）。
- ルート名/パスの命名規則は既存のスタイルを踏襲（必要時に別途 standards を追加）。

## Logging
- 最終APIは `lib/infra/logging/logger.dart`（トップレベル関数）。
- 互換のため `lib/core/logging/compat.dart` と `lib/core/logging/yata_logger.dart` を暫定提供（段階的に削除）。
- PII マスキング仕様は `docs/standards/logging.md` を参照（デフォルト有効、maskMode は redact）。

## Error Handling
- グローバルエラーハンドラは app 層で設定。
- 環境変数不正時の挙動は現状維持（警告して継続）。

## Supabase & Realtime
- Supabase クライアントは `_lib/infra/supabase`。
- Realtime ユーティリティは `_lib/infra/realtime`。
- Feature 層は raw クライアントへ直接依存しない（repositories/services の契約経由）。

## Build & Codegen
- build_runner/json_serializable/riverpod_generator は `lib/` を監視する前提を維持。
- 移行は一括で行い、完了後に `_lib/` を `lib/` にリネームした上でコード生成を実行（`build.yaml` の追加は不要）。

## Testing
- `test/` はミラーツリー構成。
- モックは `mocktail` を使用。UI のゴールデンテストは将来的に導入（当面は無し）。

## Decision Log
- 本ドキュメントはユーザー合意済み方針を反映。参考: `docs/draft/2025-09-05-open-questions.md:1`。
