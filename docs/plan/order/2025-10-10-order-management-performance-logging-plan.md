# 注文管理パフォーマンスログ集約計画（2025-10-10）

## 背景
- `OrderManagementTracer` の `[OMPerf]` ログが `debugPrint` へ直接出力され、ロガー（`infra/logging/logger.dart`）の Console/File sink に到達していない。
- `_logs/` 配下の運用ログには `[OMPerf]` エントリが一切残っておらず、分析チームが取得できるログが欠落している。
- トレーサは `kDebugMode` 依存で有効化されるため、本番ビルドでは計測自体が無効になる設計となっている。
- 2025-10-10 実施の調査レポート（`docs/survey/order_survey/2025-10-10-omperf-log-sink-status.md`）で状況が確認された。

## ゴール
- `[OMPerf]` ログを既存のロガー経由で Console/File sink に正しく出力し、運用ログへ確実に保存する。
- 本番ビルドでも環境設定によりパフォーマンス計測を有効化できる仕組みを整備する。
- ログから計測値・コンテキスト（flowId/spanId など）を失わずに集計できる状態にする。

## 非ゴール
- ログフォーマット全体の刷新や別システムへの転送自動化。
- Supabase 側のパフォーマンスチューニングそのもの。
- 既存トレーシングフレームワーク外の新しい計測機構の導入。

## 現状整理
| 項目 | 現状 | 課題 |
| --- | --- | --- |
| トレーサのログ経路 | `debugPrint` に直接出力 | Console/File sink から切り離され、ログファイルに残らない |
| 有効化条件 | `kDebugMode` + `ORDER_MANAGEMENT_PERF_TRACING` | 本番ビルドで強制的に無効、環境個別制御が不可 |
| コンテキスト | `LogContext` で flowId/spanId を生成 | ロガーに渡らないためフィールドが失われる |
| ログ識別 | 文字列プレフィックス `[OMPerf]` のみ | Sink 側でフィルタリングしづらい |

## 改善方針概要
1. **ロガー経由の出力統合**: `OrderManagementTracer` をロガー API (`logger.d` 等) に載せ替え、`LogContext` で構築したフィールドを `fields` として引き渡す。
2. **環境制御の拡張**: `kDebugMode` 依存を外し、環境変数・リモート設定で有効化を切り替え可能にする（デフォルトは非本番で有効、本番は明示 opt-in）。
3. **シンクと監視の強化**: `[OMPerf]` 専用タグ（例: `omperf`）をロガーに追加し、Console/File sink でのフィルタ・ローテーション整備、存在確認を自動化する。

## 詳細アクション

### 1. ロガー経由の出力統合
- `OrderManagementTracer.logMessage` / `logLazy` / `_logElapsed` を `Logger.withTag('omperf').d(...)` へ置き換え、`fields` に `LogContext` 情報と経過時間、インデックス等を格納する。
- `_logPrefix` はログメッセージのサマリ（`message`）として使用し、sink 側ではタグで区別する方針へ移行。
- `TimelineTask` 計測で生成した追加フィールド（`elapsedMs`, `operation`, `origin` など）をロガーの JSON ペイロードに含める。
- 既存の `OrderManagementTracer.logLazy` 呼び出し箇所を確認し、遅延生成メッセージがロガー呼び出しでも副作用を持たないことをテストで担保する。

### 2. 環境制御の拡張
- `OrderManagementTracer.isEnabled` から `kDebugMode` 判定を除去し、環境変数 `ORDER_MANAGEMENT_PERF_TRACING` または設定サービス経由のブーリアン値で制御する。
- `infra/config/runtime_overrides.dart`（存在する場合）にトグル項目を追加し、アプリ内メニューからの切り替えを可能にする。
- 本番環境で計測を有効化した際のログ量増加を抑制するため、`shouldSample` のデフォルト modulo を環境設定で外から調整可能にする。
- ドキュメント（README/運用手順）に本番有効化手順と注意事項を追記する。

### 3. シンクと監視の強化
- `infra/logging/logger.dart` に `omperf` タグ定義を追加し、既存の Console/File sink がタグ情報を出力することを確認。
- ファイルシンク設定で `[OMPerf]` ログ専用のファイルローテーション規則（`omperf-YYYYMMDD.log`）を追加するか、既存ファイルに混在させる場合は grep 用にタグ出力を保証する。
- `_logs/` のローテーションスクリプト／CI チェックに `omperf` タグ出力の有無を確認するスモークテストを追加。
- `test/infra/logging/logger_test.dart`（存在する場合）に、`omperf` タグ付きログが sink に流れるユニットテストを追加。

## マイルストーン
| 期日 | 成果物 |
| --- | --- |
| 2025-10-12 | `OrderManagementTracer` のロガー統合完了、ユニットテストで `omperf` タグ付きログを検証 |
| 2025-10-13 | 環境制御オプション（Runtime override）の実装とドキュメント更新 |
| 2025-10-14 | シンク設定・CI チェック実装、`_logs/` に `omperf` 出力を確認 |

## 検証方法
- Flutter アプリをローカル起動し、`ORDER_MANAGEMENT_PERF_TRACING=true` で注文フローを実行、`_logs/app-*.log` へ `omperf` タグ付きエントリが出力されることを確認。
- ログ解析スクリプトで flowId/spanId が欠落せず保存されていることをチェック。
- サンプリング設定を変更した際、ログレートが意図通りに変化することをメトリクス（行数・出力量）で比較。
- logger のユニットテストで新タグの sink 連携を確認し、既存処理へ副作用がないことを担保。

## リスクと緩和策
| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| 本番でログ量が急増し、ファイルローテーションが追いつかない | ディスク圧迫・監視負荷増大 | サンプリング率およびログレベルを環境設定で即時調整可能にし、初期値は高いサンプリング（低出力）で開始 |
| ロガー経由に切り替えた結果、計測中の UI 応答性が低下 | フレーム落ちや遅延の発生 | ロガー呼び出しを非同期 Queue に委譲し、ビジネスロジック側では await しないことを確認 |
| 新タグ追加による既存ログ解析ツールの不整合 | 可視化ダッシュボードの障害 | ログフォーマット変更を事前共有し、CI でスキーマ検証を行う |

## 次アクション
1. `feature/order-management-logging` ブランチを作成し、`OrderManagementTracer` ロガー統合を実装する。
2. 環境制御の仕様（環境変数・Runtime override UI）を `docs/intent/order/` にドラフトし、レビュー依頼する。
3. シンク設定変更後、`_logs/` を取得して分析チームへ試験結果を共有する。

**この実装は未着手です**
