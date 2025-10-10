# Logging Standards

Status: Accepted (updated)

## Structure
- Primary API: `lib/infra/logging/logger.dart`（トップレベル関数 `t/d/i/w/e/f` と `withTag` を使用）
- Compatibility: `lib/core/logging/compat.dart`（`logInfo/logDebug/logWarning/logError` の薄いラッパ）
- Facade (temporary): `lib/core/logging/yata_logger.dart`（既存呼び出しの後方互換用。段階的に削除予定）
- Structured fields catalog: `docs/standards/logging-structured-fields.md`（主要イベントで必須のキー設計）

## PII Masking Policy
- Default: enabled.
- Scope (strings only; depth up to 2):
  - msg (rendered message)
  - fields (map/string values; recurse depth=2)
  - ctx (contextual values if enabled)
  - err.message
  - st (string parts of stacktrace)
- Patterns (representative set):
  - Email: `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`
  - Phone (loose): `\+?\d[\d -]{8,}\d`
  - IP: prefer `InternetAddress.tryParse`; optionally minimal IPv4 regex as helper
  - Credit card (BIN classes; Luhn optional)
  - JWT: `[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,}`
  - Tokens: `(sk-[A-Za-z0-9]{16,})|(AKIA[0-9A-Z]{16})`
  - JP zipcode: `\b\d{3}-\d{4}\b`
- Mask modes:
  - `redact` (default): `[REDACTED]`
  - `hash`: SHA-256 + boot-time salt
  - `partial(keepTail=4)`: `*******1234`
- Customization:
  - `customPatterns`: additional regexes per deployment
  - `allowListKeys`: pass-through for specific `fields` keys (default: empty)

## Levels & Defaults
- Default global level: debug (dev), info (prod). Tag-level overrides allowed.
- Console: colored if supported; emoji fallback otherwise.
- File sink: daily rotation; retain N recent files (configurable).

## Crash Capture
- Global capture enabled by default; dedup window 30s; periodic summary 60s.

## Fatal レベル運用ポリシー
- `fatal` は「アプリケーションを継続できない」か「即時のオペレーション対応が必要」な状態のみで使用する。
- 代表例:
  - 起動時にクリティカル依存（Supabase など）の初期化に失敗し、リトライ不能と判断した場合。
  - 永続化できないデータ破損や不整合を検知し、監視・オンコール対応が必要なケース。
  - ランタイムで復旧不能なクラッシュを捕捉した際のフォールバック通知。
- `fatal` を発火すると以下が自動で行われる:
  - ログシンクのフラッシュ（環境変数でタイムアウトを調整可能）。
  - 登録済み Fatal ハンドラーの順次実行（Slack Webhook など外部通知に利用）。
  - `FatalConfig` の `autoShutdown` / `exitProcess` が有効な場合は安全にクローズし、必要ならプロセスを終了。
- 推奨メッセージテンプレート:
  - `log.f("<大分類>: <概要>", error: err, fields: () => {"component": "...", "ticket": "INC-123"})`

### Fatal ハンドラーとノーティファー
- `registerFatalHandler` に `FatalHandler` を登録すると、fatal 発生時に任意処理を実行できる。
- `registerFatalNotifier(FatalNotifier)` で `StdoutFatalNotifier` や `ClosureFatalNotifier` などを注入可能。
- ハンドラー内では `context.flush()` / `context.shutdown()` を呼び出すことで同期的なフラッシュや安全終了を制御できる。
- ハンドラー実行は `FatalConfig.handlerTimeout` でタイムアウト設定が可能（デフォルト10秒）。

### 環境変数による調整（runtime override）
- `LOG_FATAL_FLUSH_BEFORE_HANDLERS` (`true`/`false`): ハンドラー実行前に強制フラッシュするか。
- `LOG_FATAL_FLUSH_TIMEOUT_MS`: フラッシュ待機のタイムアウト（ミリ秒）。
- `LOG_FATAL_HANDLER_TIMEOUT_MS`: 各ハンドラーの実行タイムアウト（ミリ秒）。
- `LOG_FATAL_AUTO_SHUTDOWN`: ハンドラー完了後に自動的に `shutdown()` を呼び出すか。
- `LOG_FATAL_EXIT_PROCESS`: 自動シャットダウン時にプロセス終了まで行うか。
- `LOG_FATAL_EXIT_CODE`: `exitProcess=true` の際に使用する終了コード。
- `LOG_FATAL_SHUTDOWN_DELAY_MS`: 終了前に待機するディレイ（ミリ秒）。
- `ORDER_MANAGEMENT_PERF_TRACING`: 注文管理パフォーマンストレーサーの有効化フラグ。未設定時は非リリースビルドで自動的に有効、リリースビルドでは opt-in。
- `ORDER_MANAGEMENT_PERF_SAMPLE_MODULO`: 注文管理トレーサーのサンプリング周期（正の整数）。

### 安全モード（PoC）
- Supabase 初期化が致命的に失敗した場合、`SupabaseClientService` が自動で `fatal` を発火し安全モードへ移行する。
- 安全モード中は再初期化をスキップし、`safeModeReason` をログおよび運用側へ通知する。
- UI/サービス層は `SupabaseClientService.isInSafeMode` を参照することでフェイルセーフ分岐を実装できる。

## Usage
- 既存コードは `compat.dart` の `log*` 関数、または `YataLogger` 後方互換を利用。新規コードは `logger.dart` の `i/w/d/e` などを直接使用。
- 機能別タグが必要な場合は `withTag('FeatureName').i('msg')` か `i('msg', tag: 'FeatureName')` を使用。
- 平文で機微情報を出力しない。PII マスキングは二重化のための仕組み。

### パフォーマンストレーシング (`omperf` タグ)
- `OrderManagementTracer` は `omperf` タグ付きでロガーに出力し、Console/File sink 双方に記録される。
- 実行中は `OrderManagementTracer.applyRuntimeOverride(enabled: true, sampleModulo: 5)` のように有効化・サンプリング率を即時調整できる。
- 環境変数 `ORDER_MANAGEMENT_PERF_TRACING=true` と `ORDER_MANAGEMENT_PERF_SAMPLE_MODULO=<正の整数>` を設定すると、本番ビルドでも `_logs/app-*.log` に `tag=omperf` のNDJSONが残り、flow/span情報を含む計測結果を取得できる。

References: `docs/draft/logging/temp.md:1`
