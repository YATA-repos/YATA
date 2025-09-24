# Logging Migration Plan (Compat → Final API)

Status: Draft — 2025-09-07

## 現状サマリ（2025-09-07 スキャン）
- 互換ファサード残存: `YataLogger.*` 呼び出し 36 箇所
- メッセージAPI残存: `logInfoMessage|logWarningMessage|logErrorMessage` 呼び出し 66 箇所
- 互換ショートカット残存: `logInfo|logDebug|logWarning|logError` 呼び出し 334 箇所
- 互換インポート/ミックスインの利用状況:
  - `import 'core/logging/yata_logger.dart'`: 一部あり
  - `import 'core/logging/compat.dart'`: 多数あり
  - `with LoggerComponent`: 多数あり（暫定ラッパ提供のため）

参考（確認コマンド）
- `rg -n "YataLogger\\." lib`
- `rg -n "\\blog(Info|Warning|Error|Debug)Message\\(" lib`
- `rg -n "\\b(logInfo|logDebug|logWarning|logError)\\(" lib`
- `rg -n "import .*compat\\.dart|import .*yata_logger\\.dart" lib`
- `rg -n " with LoggerComponent\\b" lib`

## 目標状態
- 互換レイヤ（`compat.dart`, `yata_logger.dart`, `LoggerComponent`）の削除
- すべてのログ呼び出しを `lib/infra/logging/logger.dart` の最終APIへ統一
  - トップレベル: `t/d/i/w/e/f(msg, {tag, fields, error, st})`
  - またはタグ済み: `withTag('Component').i(msg)`
- メッセージenum（`LogMessage` 実装体）は継続活用可。ただし呼び出しは最終APIで実行

## 方針
- 影響範囲が広いため、フェーズ分割で安全に置換。
- 置換は「タグの統一」を優先（`loggerComponent` → 固定タグ文字列へ）。
- 手戻り防止のため各フェーズに Acceptance（確認コマンド）と Revert ポイントを設定。

## フェーズ計画

Phase 0 — 凍結・前提
- フリーズ: 機能改修は停止。ログ置換に専念。
- ベースライン: `flutter analyze` 無エラー（互換レイヤ込み）を確認。

Phase 1 — YataLogger.* の排除（36箇所）
- 置換ポリシー（例）
  - `YataLogger.debug('Comp', 'msg')` → `d('msg', tag: 'Comp')`
  - `YataLogger.infoWithMessage('Comp', SomeInfo.msg, params)` → `i(SomeInfo.msg.withParams(params), tag: 'Comp')`
  - `YataLogger.error('Comp', 'msg', err, st)` → `e('msg', error: err, st: st, tag: 'Comp')`
- Acceptance
  - `rg -n "YataLogger\\." lib` が 0 件
  - `flutter analyze` がエラーなし

Phase 2 — message API の直呼び化（66箇所）
- 置換ポリシー
  - `logInfoMessage(MsgEnum, params)` → `i(MsgEnum.message.withParams(params), tag: 'Component')`
  - `logWarningMessage(MsgEnum, params)` → `w(MsgEnum.message.withParams(params), tag: 'Component')`
  - `logErrorMessage(MsgEnum, params, err, st)` → `e(MsgEnum.message.withParams(params), error: err, st: st, tag: 'Component')`
- Acceptance
  - `rg -n "\\blog(Info|Warning|Error|Debug)Message\\(" lib` が 0 件
  - `flutter analyze` がエラーなし

Phase 3 — 互換ショートカット（logInfo/logDebug/…）の整理（334箇所）
- 置換スタンス: 新規は最終API直呼びへ。既存は段階置換。
- 置換パターン
  - クラス単位でタグを固定:
    - 先頭付近に `final _log = withTag('ClassName');` を導入
    - `logInfo('msg')` → `_log.i('msg')`
    - `logError('msg', err, st)` → `_log.e('msg', error: err, st: st)`
  - またはインラインで `i('msg', tag: 'ClassName')`
- Acceptance
  - `rg -n "\\b(logInfo|logDebug|logWarning|logError)\\(" lib` が 0 件
  - `flutter analyze` がエラーなし

Phase 4 — 互換レイヤ削除
- 対象:
  - `lib/core/logging/compat.dart`
  - `lib/core/logging/yata_logger.dart`
  - `with LoggerComponent` の削除（タグ方式へ移行した後）
- Acceptance
  - `rg -n "import .*compat\\.dart|import .*yata_logger\\.dart" lib` が 0 件
  - `rg -n " with LoggerComponent\\b" lib` が 0 件
  - `flutter analyze` がエラーなし、`flutter build` 成功

## 置換サンプル（コピペ用）
- 単純ログ
  - Before: `logInfo('Started')`
  - After: `i('Started', tag: 'InventoryService')` or `_log.i('Started')`
- 例外つき
  - Before: `logError('Failed', e, st)`
  - After: `e('Failed', error: e, st: st, tag: 'OrderService')`
- メッセージEnum
  - Before: `logWarningMessage(ServiceWarning.accessDenied)`
  - After: `w(ServiceWarning.accessDenied.message, tag: 'MaterialManagementService')`
  - With params: `i(AnalyticsInfo.dailyStatsCompleted.message.withParams({'totalRevenue': '1000'}), tag: 'AnalyticsService')`

## 実行手順（推奨）
1) フェーズ毎にブランチ切り替え（例: `logging/p1-yatalogger`, `logging/p2-message-api` ...）。
2) 各フェーズで次を実行:
   - 部分置換 → `flutter analyze` → 動作確認（主要フローの手動スモーク）
   - コミット → PR（小さくレビュー容易に）
3) 最終フェーズで互換レイヤ削除 → 全体ビルド/テスト → マージ

## 検証ポイント
- PIIマスキング（`docs/standards/logging.md`）の期待動作維持
- Tag粒度（component名）の一貫性
- 例外時の `error/st` 付与が正しく移行されていること

## 完了条件（Done）
- すべてのログ呼び出しが `infra/logging/logger.dart` のみを参照
- 互換レイヤ/ファサード/ミックスイン削除済み
- `flutter analyze` 無エラー、主要ユースケースでログが出力される

## 付録 — 現状の代表的呼び出し箇所
- `lib/infra/supabase/supabase_client.dart` — YataLogger.*（情報・エラー・メッセージ系）
- `lib/core/validation/{input_validator.dart,type_validator.dart}` — YataLogger.*
- `lib/core/utils/query_utils.dart` — YataLogger.debug/error
- `lib/features/*/services/*` — logInfoMessage/logErrorMessage + logInfo/logDebug 系多数

---

## 実行前提（Prerequisites）
- ツール: `rg`(ripgrep), `sed`, `git`, `flutter` CLI
- ブランチ運用: フェーズごとに専用ブランチを作成（例: `logging/p1-yatalogger`）
- 検証: 各フェーズで `flutter analyze` と主要フローのスモーク確認を実施

## タグ命名規約（Tagging）
- 基本は「クラス名」をタグに使用（PascalCase）。例: `InventoryService`, `OrderService`
- 呼び出しパターンはどちらかに統一
  - 直呼び: `i('msg', tag: 'InventoryService')`
  - タグ固定: `final _log = withTag('InventoryService'); _log.i('msg');`
- 関数スコープやユーティリティはモジュール名・機能名を使用（例: `QueryUtils`, `AuthRouting`）

## フェーズ別チェックリスト（実務用）

Phase 1 — YataLogger.* の排除（36件）
- 対象例: `infra/supabase/supabase_client.dart`, `core/validation/{input_validator.dart,type_validator.dart}`, `core/utils/query_utils.dart`, `features/auth/presentation/providers/auth_providers.dart`
- 置換例:
  - `YataLogger.info('Comp', 'message')` → `i('message', tag: 'Comp')`
  - `YataLogger.error('Comp', 'message', e, st)` → `e('message', error: e, st: st, tag: 'Comp')`
  - `YataLogger.infoWithMessage('Comp', MsgEnum, params)` → `i(MsgEnum.message.withParams(params), tag: 'Comp')`
- 確認:
  - [ ] `rg -n "YataLogger\\." lib` が 0 件
  - [ ] `flutter analyze` 無エラー

Phase 2 — message API の直呼び化（66件）
- 置換例:
  - `logInfoMessage(Msg, params)` → `i(Msg.message.withParams(params), tag: 'ClassName')`
  - `logWarningMessage(Msg, params)` → `w(Msg.message.withParams(params), tag: 'ClassName')`
  - `logErrorMessage(Msg, params, e, st)` → `e(Msg.message.withParams(params), error: e, st: st, tag: 'ClassName')`
- 確認:
  - [ ] `rg -n "\\blog(Info|Warning|Error|Debug)Message\\(" lib` が 0 件
  - [ ] `flutter analyze` 無エラー

Phase 3 — 互換ショートカット整理（334件）
- 方針: クラスごとに `withTag('ClassName')` を導入し `_log.i/w/d/e/f` へ移行、または `i/w/d/e/f(..., tag: 'ClassName')` に統一
- 置換例:
  - `logInfo('msg')` → `_log.i('msg')` or `i('msg', tag: 'ClassName')`
  - `logError('msg', e, st)` → `_log.e('msg', error: e, st: st)` or `e('msg', error: e, st: st, tag: 'ClassName')`
- 確認:
  - [ ] `rg -n "\\b(logInfo|logDebug|logWarning|logError)\\(" lib` が 0 件
  - [ ] `flutter analyze` 無エラー

Phase 4 — 互換レイヤ削除
- 対象: `lib/core/logging/compat.dart`, `lib/core/logging/yata_logger.dart`, `with LoggerComponent`
- 羺認:
  - [ ] `rg -n "import .*compat\\.dart|import .*yata_logger\\.dart" lib` が 0 件
  - [ ] `rg -n " with LoggerComponent\\b" lib` が 0 件
  - [ ] `flutter analyze` 無エラー、`flutter build` 成功

## 参考コマンド（任意・編集必須）
- YataLogger→最終API（単純形）
  - `sed -E -i "s/YataLogger\\.info\('([^']+)', *'([^']+)'\)/i('\2', tag: '\1')/g" \$(rg -l "YataLogger\\.info\(" lib)`
  - `sed -E -i "s/YataLogger\\.error\('([^']+)', *'([^']+)' *, *([^,]+) *, *([^\)]+)\)/e('\2', error: \3, st: \4, tag: '\1')/g" \$(rg -l "YataLogger\\.error\(" lib)`
  - 注意: 多様な引数パターンがあるため、実行前に小規模ファイルで試験・レビュー必須
- Message API→直呼び
  - `sed -E -i "s/logInfoMessage\(([^,\)]+), *([^\)]*)\)/i(\1.message.withParams(\2), tag: 'ClassName')/g" file.dart`（例・手直し前提）
- ショートカット→withTag
  - ファイル先頭付近: `final _log = withTag('ClassName');`
  - `sed -i "s/\blogInfo\(/_log.i(/g" file.dart` など（手直し前提）

## ロールバック手順
- フェーズごとに小さくコミット・PR化（レビュー容易・影響最小）
- 失敗時はブランチで `git revert <commit>`、または PR を Revert
- 自動置換は必ずローカルで差分確認（`git diff`）→コミット前に `flutter analyze`

