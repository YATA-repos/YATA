# 注文管理パフォーマンスログのシンク状況調査

## 背景 / Context
- Order Management Tracer (`OrderManagementTracer`) で計測したパフォーマンスログ（`[OMPerf]`）が `_logs/` 配下のログファイルに記録されていないとの指摘を受け、シンク設定の有無を確認する必要があった。
- 環境変数 `ORDER_MANAGEMENT_PERF_TRACING` を `true` にするとデバッグ計測が有効化されるが、運用ログへ残らなければ分析チームが参照できないリスクがある。

## 目的 / Goal
- `[OMPerf]` ログが既存のログパイプライン（Console/File sink）に流れているかを確認する。
- シンクされていない場合は、その根本原因と影響範囲を明らかにする。

## 手法 / Method
- `lib/features/order/presentation/performance/order_management_tracing.dart` を調査し、ログ出力方法を確認。
- `lib/infra/logging/logger.dart` および `lib/infra/logging/sinks.dart` を確認し、`debugPrint` とログシンクの接続状況を調査。
- `_logs/app-20251009-*.log` を検索し、`[OMPerf]` プレフィックスを含む行の有無を確認。

## 結果 / Findings
- `OrderManagementTracer` 内の `logMessage` / `logLazy` / `_logElapsed` はすべて `debugPrint` を直接呼び出している。アプリのロガー (`Logger`) 経由ではなく、`ConsoleSink` / `FileSink` に対するハンドオフは行っていない。
- `lib/infra/logging` 配下に `debugPrint` をフックしてロガーへ転送する仕組みは存在しなかった（`debugPrint = ...` の再定義や `runZoned` による `print` 迂回処理も未実装）。
- `_logs/app-20251009-*.log` を含む過去のローテーションファイルを全文検索しても `[OMPerf]` エントリは検出されなかった。
- 以上より、`[OMPerf]` ログはデバッガコンソールにのみ出力され、ファイルシンクや他の集約先には保存されていないと判断した。

## 考察 / Discussion
- `OrderManagementTracer` はデバッグセッション専用の想定で実装されている可能性が高く、運用ログに残さない設計となっている。一方で、パフォーマンス分析を継続的に行う要件がある場合、運用環境でも取得できる仕組みが必要。
- 現行実装では `OrderManagementTracer.isEnabled` が `kDebugMode` に依存するため、リリースビルドではそもそもログが発火しない。シンク処理を追加しても、本番ビルドで有効化する設計変更が別途必要。
- `LogContext` との連携自体は行われているため、ロガー経由で出力するように変更すれば、既存のフィールドを活かしたままログ集約に載せられると考えられる。

## 推奨アクション / Recommendations
- `OrderManagementTracer` の `debugPrint` 呼び出しを、`infra/logging/logger.dart` の `logger.d` などロガー API 経由に置き換える。`log_ctx` で付与したコンテキスト情報を `fields` に引き渡す実装を検討する。
- シンク対象外とする意図がない場合、`kDebugMode` に依存した `isEnabled` 判定を見直し、環境設定で個別に制御できるようにする。
- ロガーの構成に `[OMPerf]` 専用タグ（例: `"omperf"`）を追加し、シンク先でフィルタリングしやすくする。
- 変更後は `_logs/` 配下にログが生成されることを確認し、分析チームと共有する。

## 参考資料 / References
- `lib/features/order/presentation/performance/order_management_tracing.dart`
- `lib/infra/logging/logger.dart`
- `lib/infra/logging/sinks.dart`
- `_logs/app-20251009-05.log`（および同日付の他ファイル）
