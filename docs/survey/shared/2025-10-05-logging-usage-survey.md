# Logging Usage Survey (2025-10-05)

## 背景 / Context
- プロジェクト全体で整備されたロギング基盤 (`lib/infra/logging/`) がどの程度活用されているかを把握し、運用改善や追加実装の優先順位を整理するための調査。
- `docs/standards/` にはロギングの詳細ガイドが未整備であり、現行実装の実態をまとめておく必要があった。

## 目的 / Goal
- ロギング基盤の機能と設定手段を棚卸しする。
- 各レイヤー（UI / Service / Infra / Core）での利用状況とギャップを明らかにする。
- 活用不足の機能や運用上のリスクを抽出し、今後の改善タスク候補を提示する。

## 手法 / Method
- `lib/` 配下の Dart ファイルを対象に、`log.<level>(` 呼び出しや `debugPrint` などロギング関連 API を横断検索。
- `rg --no-heading -o "log\.[tidwef]\(" -g "*.dart" lib` による定量カウントでログレベル毎の使用回数を算出。
- 主要なロギング関連ファイル（`infra/logging/logger.dart`, `log_runtime_config.dart`, `sinks.dart` など）をレビューし、機能面を整理。
- Riverpod による `LoggerContract` 注入ポイントや UI 層での利用パターンを調査。

## 結果 / Findings

### ログレベル別の利用回数
| Level | 呼び出し数 |
|-------|------------|
| trace (`log.t`) | 4 |
| debug (`log.d`) | 148 |
| info (`log.i`) | 152 |
| warn (`log.w`) | 52 |
| error (`log.e`) | 164 |
| fatal (`log.f`) | 0 |

- 総計 520 件の `log.<level>` 呼び出しが存在し、Service / Infra 層を中心に広く利用されている。
- `fatal` ログは未使用。エラー以上は `error` で止まっており、重大障害時の共通ハンドリングは未整備。

### ロギング基盤の機能
- `infra/logging/logger.dart`
  - 非同期キュー + バックプレッシャ制御（`OverflowPolicy`）を備えたコア実装。
  - コンソール / ファイル両対応のシンク（`ConsoleSink`, `FileSink`）とファイルローテーション・保持ポリシーを実装（`sinks.dart`）。
  - PII マスキング、レートリミット、コールサイト付与、クラッシュ捕捉 (`installCrashCapture`) など高機能。
  - `LoggerStats` による統計ストリームと、設定の動的更新 API (`setGlobalLevel`, `updateLoggerConfig`) を提供。
- `.env` 連携
  - `applyLogRuntimeConfig`（`log_runtime_config.dart`）が `LOG_LEVEL`, `LOG_FLUSH_INTERVAL_MS`, `LOG_MAX_QUEUE`, `LOG_BACKPRESSURE`, `LOG_DIR` を解釈し、アプリ起動時 (`main.dart`) に適用。
- 依存注入
  - `loggerProvider` (`app/wiring/provider.dart`) が `LoggerContract` を Riverpod で公開し、`InfraLoggerAdapter` がコア実装へブリッジ。
  - 開発 / 本番用の override 雛形 (`override_dev.dart`, `override_prod.dart`) で外部 Logger を差し替え可能。

### レイヤー別の利用状況
- **Infra 層**: Supabase クライアント、Realtime 管理、キャッシュ層などで積極的に利用。多くが `String get loggerComponent` でタグを定義し、`log.<level>(..., tag: loggerComponent)` パターンに統一。
- **Service 層**: メニュー / 注文 / 在庫など各種サービスで広範囲に導入。リクエスト制御や例外ハンドリング時に `log.d`/`log.e` が多用され、ドメインイベントの状況把握に活用。
- **UI / Presentation 層**: Riverpod Controller や Provider でエラー通知・状態遷移をロギングする箇所はあるが、Widget レベルのインスツルメンテーションは限定的。
- **Core 層**: `core/realtime/realtime_service_mixin.dart` などで共通ミックスインがログを発行し、サービス側の実装負担を軽減。
- **テストコード**: `test/` 配下でのロギング利用は確認できず。ログ出力に依存した検証は現状行っていない。

### その他のロギング手段
- `debugPrint` / `debugPrintSynchronously`
  - `features/order/presentation/performance/order_management_tracing.dart` のパフォーマンストレーサ、`core/validation/env_validator.dart` など、一部で Flutter 標準のデバッグ出力を使用。
  - トレーサは `dart:developer` の `TimelineTask` と併用し、開発時のみ有効化される設計。
- `LogContext` (`infra/logging/context.dart`) により Zone ベースのコンテキスト付与が可能だが、プロジェクト内での利用箇所はまだ無い。

## 考察 / Discussion
- サービス / インフラ層では十分なカバレッジがあり、実運用での障害調査に有用な情報量が確保されている一方で、UI 層・リポジトリ層のロギングは限定的。特にユーザー操作とバックエンド処理の因果関係を追跡するには、UI 側でのトレースを追加する余地がある。
- `LoggerContract` の DI 仕組みが用意されているにもかかわらず、features 層は `core/logging/compat.dart` 経由でグローバル API を参照する旧パターンが残っている。差し替えやモックが必要なテストでは支障となる可能性が高い。
- `fatal` ログが未使用であり、致命的クラッシュ時の共通動線（例: 監視サービス連携、クラッシュレポート送信）を整えておくと運用面で安心感が増す。
- `LogContext` や `fields` 引数など、構造化ログを強化する機能が実装済みだが十分に活用されていない。情報密度にばらつきがあるため、重要イベントのフィールド設計を検討する価値がある。
- テストコードでロギングをモック・アサートしていないため、回帰時にログフォーマットが崩れたり、意図しない大量出力が発生しても検知できないリスクがある。

## 推奨アクション / Recommendations
- **DI への移行**: `core/logging/compat.dart` の暫定エクスポートを廃止できるよう、各サービスで `LoggerContract` を明示的に受け取る構造へ段階的に移行する。
- **UI ロギングの強化**: 重要なユーザーフロー（注文登録、在庫調整など）で UI 側にもタグ付きログを追加し、ユーザー行動とバックエンド処理をクロス参照できるようにする。
- **致命エラーラインの定義**: `log.f` 利用ポリシーとハンドラ（例えばクラッシュレポート送信）を整備し、重大障害時の通知・復旧手順を明確化する。
- **構造化フィールドの標準化**: `fields` に格納すべきキーのガイドラインを策定し、最低限の共通属性（ユーザーID、リクエストID など）をログに含める。
- **ランタイム設定検証**: `.env` による `LOG_*` 設定の例と推奨値を `docs/guide/` 等へ追加し、運用担当者が即座に調整できるようにする。
- **LogContext / トレーシング活用**: 特にバッチ処理やリアルタイム処理で `runWithContext` を活用し、同一リクエスト内でのログ紐付けを強化する。
- **テストでの検証**: ロギングをモック化し、エラーパスで適切なメッセージ・レベルが出力されることを確認するユニットテストを追加。

## 参考資料 / References
- `lib/infra/logging/logger.dart`
- `lib/infra/logging/log_runtime_config.dart`
- `lib/infra/logging/sinks.dart`
- `lib/app/wiring/provider.dart`
- `lib/features/order/services/menu_service.dart` 他サービス層実装
- `lib/features/order/presentation/performance/order_management_tracing.dart`
- `lib/core/realtime/realtime_service_mixin.dart`
