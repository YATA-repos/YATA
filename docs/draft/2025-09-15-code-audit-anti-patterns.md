# YATA コード監査（“ずるい/暫定”実装チェック）

- 日付: 2025-09-15
- 対象: リポジトリ全体（主に `lib/` 配下）
- 観点: 以下の“非正規/暫定”傾向の有無
  - モック・スタブ・ダミーや意図的な未実装の放置
  - コメントアウトでのエラー回避や linter の無効化
  - 例外の握りつぶし（空 catch）や場当たり的実装
  - 本来の仕組みを迂回するログ/出力など

## サマリ（結論）

- 本質的な「コメントアウトでエラー回避」「linter 無効化での握りつぶし」は検出なし。
- ただし、暫定レイヤや仮実装（将来置換予定）が複数あり、実装の完成度にばらつきがある。
- 例外握りつぶしは主にロギング周辺（flush/close、ローテーション/リテンション）で限定的に存在。致命ではないが、運用観点で要改善余地あり。
- デバッグ/環境検証で `print` を直接使う箇所があり、ロギング基盤の一貫性から外れる可能性。少なくともリリースビルドでの抑止が望ましい。
- 空ファイル／未実装プレースホルダやスペルミスのあるファイルが散見。早期に整理推奨。

## 検出詳細

### 1) 暫定・互換レイヤ（将来置換を前提）

- `lib/core/logging/compat.dart:1`
  - 互換レイヤ（暫定）。features 層からの参照を core 経由に寄せるための一時的エクスポート。
  - 影響: 多数の service/repository が `compat.dart` を import（恒久 API へ置換計画が必要）。

- `lib/core/logging/levels.dart:1`
  - 最小限の Level enum（後方互換のためのシム）。本番運用では最終 API への統合が望ましい。

### 2) ハードコード・仮実装（将来置換推奨）

- 税率の仮定:
  - `lib/features/order/services/order_calculation_service.dart:32`
    - 「税率（8%と仮定）」で固定。設定やテナント別に変更できるように外出し推奨。

- 在庫予測の仮ロジック:
  - `lib/features/inventory/repositories/material_repository.dart:122`
  - `lib/features/inventory/repositories/material_repository.dart:123`
  - `lib/features/inventory/repositories/material_repository.dart:133`
    - 平均使用量や日間使用率に固定値（仮の値）。トランザクションログからの算出など、実データ駆動に置換が必要。

- OAuth 開始時のプレースホルダユーザー:
  - `lib/features/auth/repositories/auth_repository.dart:67`
    - OAuth フロー開始成功時に `oauth_pending` を返す設計自体は妥当だが、UI 側で「仮ユーザーを認証済みとみなさない」前提の明文化が必要。

### 3) 例外握りつぶし（限定的）

- ログファイルのリテンション/ローテーション周辺（運用上は許容されることが多いが、状況記録は推奨）:
  - `lib/infra/logging/policies.dart:122`, `:147` など
  - `lib/infra/logging/sinks.dart:177`, `:99`, `:242` など
  - `lib/infra/logging/logger.dart:526`, `:462`
    - 一部 `catch (_) {}` で無視。stderr へのワーニング出力や `lastError` の保持はしているが、発生回数の集計やサマリ出力があると運用可視性が上がる。

### 4) デバッグ出力の一貫性逸脱（print 直呼び）

- `lib/core/validation/env_validator.dart`
  - `_log()` は `kDebugMode` ガード付きで `print` 使用。問題は限定的。
  - ただし `printValidationResult(...)` は無条件に `print` 出力（`lib/core/validation/env_validator.dart:229` 付近）。
    - 提案: リリースビルドでは抑止、もしくはロギング基盤へ委譲して出力先を統一。

### 5) TODO/NOTE の未了（実装は概ね正規だが要整備）

- `lib/infra/repositories/base_repository.dart` に多数の TODO（エラーハンドリング詳細化、存在チェックの最適化など）
  - 機能に直結する“ズル”ではないが、例外型の標準化・粒度の揃え込みは優先度が高い。
  - 例: `_requireAuthenticatedUserId()` が汎用 `Exception("無効なセッション")` を投げており、コメント上は `AuthException.invalidSession()` を想定（整合性要修正）。
    - `lib/infra/repositories/base_repository.dart:79`

- ルーティングの認証ガード未実装:
  - `lib/app/router/app_router.dart:17` に TODO、`lib/app/router/guards/auth_guard.dart` は空。

### 6) 空ファイル/未実装プレースホルダ

以下は現時点で中身がなく、将来実装が前提と思われる（ビルド影響は現状軽微）。

- ルーティング/DI 周辺:
  - `lib/app/router/guards/auth_guard.dart`
  - `lib/app/wiring/override_dev.dart`
  - `lib/app/wiring/override_prod.dart`
  - `lib/app/router/routes.dart`（コメントのみ）
  - `lib/app/main.dart`（空。実際のエントリは `lib/main.dart`）

- UI foundations/components/tokens:
  - `lib/shared/components/layout/gap.dart`
  - `lib/shared/components/layout/responsitve.dart`（スペルミスあり: responsive）
  - `lib/shared/foundations/layout/breakpoint.dart`
  - `lib/shared/foundations/layout/grid.dart`
  - `lib/shared/foundations/tokens/color_tokens.dart`
  - `lib/shared/foundations/tokens/elevetion_token.dart`（スペルミス: elevation）
  - `lib/shared/foundations/tokens/radius_tokens.dart`
  - `lib/shared/foundations/tokens/spacing_tokens.dart`
  - `lib/shared/foundations/tokens/typography_tokens.dart`
  - `lib/shared/themes/light_theme.dart`, `dark_theme.dart`, `high_contrast_theme.dart`

### 7) 命名・スペルミス（品質観点）

- `lib/shared/components/layout/responsitve.dart` → `responsive.dart` が妥当。
- `lib/shared/foundations/tokens/elevetion_token.dart` → `elevation_token.dart` が妥当。

### 8) コメントアウトでの回避や linter 無効化の痕跡

- `// ignore:` 系や `ignore_for_file` は検出なし。
- 危険なコメントアウト（`// return ...`, `// throw ...` など）も検出なし。

## 推奨アクション（優先度順）

1) 例外/エラーハンドリングの標準化（高）
   - `BaseRepository` の TODO 消化（`RepositoryException`/`AuthException` の使い分けと詳細化）。
   - `_requireAuthenticatedUserId()` の例外を `AuthException.invalidSession()` に統一。

2) デバッグ出力の統一（中）
   - `EnvValidator.printValidationResult` を `kDebugMode` ガード、またはロガー利用に変更。

3) 暫定ロジックの外出し（中）
   - 税率/しきい値/使用率などの固定値を設定・環境・テナント設定に外出し（`OrderCalculationService`, `MaterialRepository`）。

4) 互換レイヤの段階的縮小（中）
   - `core/logging/compat.dart` 依存の削減。最終 API への移行計画（docs/standards/logging.md 等と整合）。

5) 空ファイルの整理（低）
   - 着手前に一時削除、もしくは TODO とスケジュールを明示したコメントを付与。
   - スペルミスのあるファイルは早期改名（IDE 補完/検索の精度向上）。

## 補足

- `pubspec.yaml` の `intl` コメントアウトは現状問題なし（未使用のため）。
- Realtime の feature マッピング既定値（未知 → analytics）は安全側だが、将来的に `UnknownFeature` 例外へ切替検討。

## 参考（該当箇所抜粋リスト）

- 暫定/互換: `lib/core/logging/compat.dart:1`, `lib/core/logging/levels.dart:1`
- 仮実装: `lib/features/order/services/order_calculation_service.dart:32`,
          `lib/features/inventory/repositories/material_repository.dart:122`, `:123`, `:133`,
          `lib/features/auth/repositories/auth_repository.dart:67`
- 例外握りつぶし: `lib/infra/logging/policies.dart:122`, `:147`,
                  `lib/infra/logging/sinks.dart:99`, `:177`, `:242`,
                  `lib/infra/logging/logger.dart:462`, `:526`
- print 直呼び: `lib/core/validation/env_validator.dart:229` 付近
- TODO 多数: `lib/infra/repositories/base_repository.dart`（多数行）
- 認証ガード未実装: `lib/app/router/app_router.dart:17`, `lib/app/router/guards/auth_guard.dart`
- 空/プレースホルダ: 本文 6) を参照

