# YATA リファクタリング計画ロードマップ

- 作成日: 2025-09-30
- ステータス: 提案中（着手前）
- 対象: `lib/` 配下のアプリケーション全体（Routing/DI、Logging、Repository、Service、Shared UI、検証）
- 関連ドキュメント: 
  - `docs/standards/architecture.md`
  - `docs/draft/2025-09-15-code-audit-anti-patterns.md`
  - `docs/plan/contracts/2025-09-15-contracts-separation-plan.md`
  - `docs/plan/logging/phase_1.md` など既存ロギング移行ドキュメント

## 背景

- コード監査 (`docs/draft/2025-09-15-code-audit-anti-patterns.md`) で、認証ガード未統合、暫定 DI、互換ロガー依存、例外処理の未整理、UI スケルトン未整備が指摘された。
- `core/contracts/` の整備により contracts → features の依存は概ね統一されたが、app 層での組み立てが未完了なため責務が中途半端に分散している。
- `flutter analyze` がサンドボックス権限不足で実行できず、品質担保のワークフローが止まっている。
- 今後の機能追加の土台として、段階的に安全なリファクタリングを行う必要がある。

## 目的

1. app 層のルーティングと DI を標準構造に揃え、認証ガードとプロバイダの制御ポイントを明確化する。
2. Logging 基盤を契約経由の注入へ刷新し、features 層から `core/logging/compat.dart` 依存を排除する。
3. Supabase ベースの Repository 実装の例外処理とクエリ契約を整理し、`BaseRepository` を堅牢化する。
4. ビジネスロジック内の固定値を設定ソースへ移し、在庫・注文サービスを再構成する。
5. Shared UI コンポーネントを実装し、命名ミスや空ファイルを解消する。
6. 静的解析・テストを再度実行可能にし、CI/ローカルで検証できる状態に戻す。

## スコープと非スコープ

- スコープ
  - `lib/app/router/` と `lib/app/wiring/` の再構成
  - Logging インジェクションの再設計
  - Repository 層 (`infra/repositories/*`, `core/contracts/repositories/*`) の例外・クエリ整理
  - `features/order` と `features/inventory` の主要サービス
  - `lib/shared/components/layout/*`, `lib/shared/foundations/tokens/*`, `lib/shared/themes/*`
  - `flutter analyze` / テスト実行フロー
- 非スコープ
  - Supabase 依存の完全抽象化（長期タスク）
  - 新規 UI デザインの追加開発（既存コンポーネントの整備に限定）
  - モバイル/デスクトップ特化のフラッタービルド最適化

## 全体フェーズ概要

| フェーズ | 概要 | 主担当モジュール | 成果物 |
|---------|------|------------------|--------|
| Phase 1 | Routing & DI 基盤再構成 | `lib/app/router`, `lib/app/wiring`, `features/auth` | 新規 `AuthGuard` 合成、Provider override雛形 |
| Phase 2 | Logging 注入再設計 | `core/logging`, `infra/logging`, `shared` | `compat.dart` 依存削減、`EnvValidator` 等のログ統合 |
| Phase 3 | Repository 例外/クエリ整理 | `infra/repositories`, `core/constants/query_types.dart` | 標準例外ハンドリング、クエリアダプタ方針 |
| Phase 4 | Service/ドメイン調整 | `features/order`, `features/inventory` | 設定化されたパラメータ、在庫分析ロジック改善 |
| Phase 5 | Shared UI 整備 | `shared/components`, `shared/themes` | 空ファイル埋め、命名修正、テーマ適用範囲拡張 |

以下、各フェーズの詳細と作業手順を記載する。

## Phase 1: Routing & DI 基盤再構成

### 目的
- 認証ガードを app 層に移動して単一責務化する。
- Riverpod Provider の override 仕組みを整備し、環境依存の注入を容易にする。

### 前提
- `features/auth/routing/auth_guard.dart` に既存ロジックがある。
- `lib/app/router/guards/auth_guard.dart` は空、`override_dev.dart` / `override_prod.dart` は未実装。

### 作業手順
1. **AuthGuard 移動**
   - `features/auth/routing/auth_guard.dart` のロジックを `lib/app/router/guards/auth_guard.dart` へ移設。
   - `features/auth/routing/` には re-export 用の薄いファイルを残すか、利用箇所を app 側参照に切替。
2. **AppRouter 更新**
   - `lib/app/router/app_router.dart` で新しい guard を参照するようリファクタ。
   - `redirect` クロージャの重複ロジックを削除し、guard 経由で統一。
3. **Provider override 雛形作成**
   - `override_dev.dart` / `override_prod.dart` に `ProviderScope.overrideWithValue` のテンプレートを追加。
   - Auth / Logger / Repository 等、主要 Provider の override 例をコメント付きで提示。
4. **wiring/provider.dart 内依存確認**
   - Provider 型定義が契約を返すことを確認し、具象型が漏れていれば修正。

### 完了条件
- `app_router.dart` から認証ロジックが削除され、guard ファイルで一元化。
- 開発/本番 override ファイルにテンプレートが存在し、`ProviderScope` で利用可能。
- `flutter analyze` を想定し、未使用 import が発生しない状態。

## Phase 2: Logging 注入再設計

### 目的
- features 層からグローバルロガー呼び出しをなくし、DI 経由で Logger 契約を利用する。
- 環境変数検証などの標準出力をロガーに切り替える。

### 作業手順
1. **LoggerContract の確認**
   - `lib/core/contracts/logging/logger.dart` のインターフェースを整理し、必要メソッドを洗い出す。
2. **Provider 経由注入**
   - `lib/app/wiring/provider.dart` の `loggerProvider` を features サービスへ渡すよう修正。
   - 各サービスで `ref.read(loggerProvider)` を受け取るようコンストラクタ変更。
3. **compat レイヤー縮退**
   - `core/logging/compat.dart` を段階的に削除。まず対象ファイルで Provider 注入へ差し替え、未使用になった段階で削除。
4. **EnvValidator 出力統一**
   - `printValidationResult` 等の `debugPrint/print` をロガー経由（debug ビルドでは console sink）に置換。

### 完了条件
- features 層で `import "../../../core/logging/compat.dart";` を使用していない。
- `EnvValidator` がロガーを使用（リリースビルドで標準出力に流れない）。
- ログ基盤の振る舞い変更が `docs/plan/logging/*` の方針と整合。

## Phase 3: Repository 例外/クエリ整理

### 目的
- `BaseRepository` の TODO を解消し、Auth/Repository 例外を標準化する。
- `QueryFilter` を Supabase 非依存の抽象にリファクタするための下準備を行う。

### 作業手順
1. **例外統一**
   - `_requireAuthenticatedUserId()` で `AuthException.invalidSession()` を使用。
   - Supabase 例外を `RepositoryException` の `params` 付きでラップし、エラーコード別に分岐。
2. **TODO 消化**
   - コメント化されているハンドリング箇所（特に `findOne`, `updateById` 等）で catch/throw を整理。
   - 「存在チェック用の効率化」など技術的負債には Issue/TODO を再記録（期限付き）。
3. **Query 抽象準備**
   - `core/constants/query_types.dart` から Supabase 依存メソッド呼び出しを分離し、アダプタ層を `infra` に用意する設計メモを docs に追記。
   - 直近で変更しない場合は、`TODO` ではなく `// *` コメントで今後のタスクを明記。

### 完了条件
- `BaseRepository` 内の TODO が整理され、例外がプロジェクト標準に揃う。
- `QueryConditionBuilder` を利用する箇所で Supabase 依存が明記されている。
- 新しいハンドリング仕様を `docs/draft/2025-09-15-code-audit-anti-patterns.md` に反映。

## Phase 4: Service/ドメイン調整

### 目的
- 税率や在庫使用率などのハードコード値を設定可能にし、将来の多店舗展開に備える。

### 作業手順
1. **設定エントリ作成**
   - `lib/core/constants` もしくは設定サービスに税率・在庫閾値を集約。
   - デフォルト値は `.env` or アプリ設定（Riverpod Provider）で注入。
2. **OrderCalculationService 改修**
   - `taxRate` をコンストラクタ注入に置換。DI 層で値を提供。
   - 割引計算や合計の負値防止ロジックをユニットテストで担保。
3. **MaterialRepository/UsageAnalysis 改修**
   - `_calculateEstimatedUsageDays` と `_calculateDailyUsageRate` をロジックサービスに分離し、トランザクション履歴に基づく計算へ置換する土台を整備。
4. **InventoryService 連携**
   - 新しい設定サービスを利用して在庫アラート・リアルタイム通知の条件を可変化。

### 完了条件
- サービス層のコンストラクタが設定/サービス依存で統一され、テスト可能な状態。
- 少なくとも税率や閾値の変更が Provider override で差し替えられる。

## Phase 5: Shared UI 整備

### 目的
- 空ファイルや命名ミスを解消し、デザインシステムの土台を提供する。

### 作業手順
1. **命名修正**
   - `lib/shared/components/layout/responsitve.dart` → `responsive.dart` へリネーム。
   - `lib/shared/foundations/tokens/elevetion_token.dart` → `elevation_token.dart` に修正し、import を更新。
2. **コンポーネント実装**
   - `gap.dart` に共通スペーサーウィジェットを実装。
   - `app_scaffold.dart` にページ骨格（AppBar、NavigationRail 等）を実装。
   - `responsive.dart` でブレークポイント判定ヘルパーを提供。
3. **テーマファイル整備**
   - `light_theme.dart`, `dark_theme.dart`, `high_contrast_theme.dart` に `AppTheme` から実際の `ThemeData` をエクスポートするラッパーを作成。
4. **ドキュメント更新**
   - 新コンポーネントの仕様を `docs/guide/ui/` 等に追記する場合は別タスクで実施（本計画ではメモを残す）。

### 完了条件
- Shared UI で空ファイルがなく、`flutter analyze` で未使用 import エラーが出ない。
- 命名修正でビルドが通り、アプリ全体が新テーマで統一される。


### 完了条件
- 少なくともローカルまたは代替環境で `flutter analyze` が成功。
- 主要サービスのテストが通り、README に手順が追記される。

## 依存関係と優先順位

1. Phase 1 → Phase 2 → Phase 3 の順に依存（DI → ロギング → Repository）
2. Phase 4 は Phase 2/3 の完了を前提とする（設定注入や例外仕様が必要）。
3. Phase 5 はラウタ/サービスの変更と独立して進められるが、Phase 2 でテーマを利用する際の依存に注意。

## 役割分担（推奨）

| ロール | 推奨フェーズ |
|--------|---------------|
| アプリ構成担当 | Phase 1, Phase 2 |
| データ層担当 | Phase 3 |
| ドメインサービス担当 | Phase 4 |
| UI/デザインチーム | Phase 5 |

## リスクと緩和策

- **Flutter SDK 権限不足**: 事前に権限調査を実施し、CI 環境を用意する。
- **広範囲変更による回帰**: フェーズ毎に小さな PR 単位で進め、テスト追加を同時に行う。
- **互換レイヤ削除による影響**: `compat.dart` 廃止時に一括置換ツールを使用し、テストで回帰確認。
- **命名修正による import 破損**: IDE リファクタリングを利用しつつ、`flutter analyze` で検証。

## 今後のフォローアップ

- 各フェーズ完了時に `docs/draft/2025-09-15-code-audit-anti-patterns.md` を更新し、対応済み項目を記録。
- Supabase 依存削減やリアルタイム機能強化は、Phase 4 以降の派生タスクとして別計画を立案。

