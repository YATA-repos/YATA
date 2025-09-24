# Logging Standards

Status: Accepted (updated)

## Structure
- Primary API: `lib/infra/logging/logger.dart`（トップレベル関数 `t/d/i/w/e/f` と `withTag` を使用）
- Compatibility: `lib/core/logging/compat.dart`（`logInfo/logDebug/logWarning/logError` の薄いラッパ）
- Facade (temporary): `lib/core/logging/yata_logger.dart`（既存呼び出しの後方互換用。段階的に削除予定）

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

## Usage
- 既存コードは `compat.dart` の `log*` 関数、または `YataLogger` 後方互換を利用。新規コードは `logger.dart` の `i/w/d/e` などを直接使用。
- 機能別タグが必要な場合は `withTag('FeatureName').i('msg')` か `i('msg', tag: 'FeatureName')` を使用。
- 平文で機微情報を出力しない。PII マスキングは二重化のための仕組み。

References: `docs/draft/logging/temp.md:1`
