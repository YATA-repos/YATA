# Logging Compat Layer — Migration Notes

Status: Draft (2025-09-07)

## 背景
- 旧 `YataLogger` / `LoggerMixin` を廃止し、最終APIは `lib/infra/logging/logger.dart` のトップレベル関数（`t/d/i/w/e/f`）へ統一。
- 移行の連続性を確保するため、互換レイヤを暫定導入。

## 追加/変更点（今回）
- 互換ラッパ:
  - `lib/core/logging/compat.dart`（トップレベル `logInfo/logDebug/logWarning/logError/logTrace`）
  - `LoggerComponent` mixin（`loggerComponent` をタグとして付与し、`logInfoMessage/logWarningMessage/logErrorMessage` を提供）
- 後方互換ファサード:
  - `lib/core/logging/yata_logger.dart`（`YataLogger.*` を最終APIへ委譲。`infoWithMessage/errorWithMessage` もサポート）
- 参照置換:
  - 各 Service/Infra から `LoggerMixin` を撤去し、必要なクラスに `with LoggerComponent` を付与
  - `main.dart` では `YataLogger` を廃止し、`installCrashCapture()` と `i/w/e` を直接使用
- 削除:
  - 破損・未参照の `provider_logger_{new_api,old}.dart`

## 今後の修正方針（段階的撤去）
1) 新規コードでは互換APIを使用しない
   - 推奨: `import 'infra/logging/logger.dart';` し、`i/w/d/e` または `withTag('Feature')` を直接使用
2) 既存の `YataLogger.*` を順次置換
   - 検索パターン: `YataLogger\.`
   - 置換指針: `YataLogger.info('Comp', msg)` → `i(msg, tag: 'Comp')`
   - `infoWithMessage/errorWithMessage` は `LogMessage.message.withParams()` で展開し `i/e` で出力
3) `LoggerComponent` 依存の解消
   - `logInfoMessage` 等を `i/w/e` + `withParams` へ移行
   - `loggerComponent` 固有タグが不要になれば mixin を撤去
4) 互換レイヤの削除
   - `compat.dart` と `yata_logger.dart` を最終的に削除

## 実務メモ（grep）
- 互換API検出: `rg -n "YataLogger\.|log(Info|Debug|Warning|Error)Message\(" lib`
- 直接API推奨例:
  - `i('started', tag: 'InventoryService')`
  - `e('failed', error: err, st: st, tag: 'OrderManagementService')`

## 参考
- 標準: `docs/standards/logging.md`
- 実装: `lib/infra/logging/logger.dart`

