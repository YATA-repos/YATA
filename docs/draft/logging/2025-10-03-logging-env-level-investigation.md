# ログレベル環境設定調査 (2025-10-03)

## 概要
- `.env` で `LOG_LEVEL=warn` 等を設定しても、実行時に `debug` ログが継続的に出力される事象を確認した。
- Flutter アプリのグローバルロガー(`lib/infra/logging/logger.dart`) が、環境変数による上書きを受け取らないままデフォルト設定で初期化されている。

## 再現方法
1. `.env` に `LOG_LEVEL=warn` を記述してアプリを起動する。
2. 起動時ログおよびアプリ内の `debug` ログ呼び出しを確認すると、`warn` 以上にフィルタされず `debug` レベルが出力され続ける。

## 調査ログ
- `lib/infra/logging/logger.dart`
  - `_LoggerCore` のコンストラクタで `LogConfig.defaults` を呼び出し、`kReleaseMode` の判定によりデフォルトレベルを `debug` (デバッグビルド時) に固定している。
  - 初期化後に `.env` の値を読み込んで書き換える処理が存在しない。
- `lib/core/validation/env_validator.dart`
  - `initialize()` で `LOG_LEVEL` を含む環境変数を読み込み `_cachedEnv` に保持する。
  - `logLevel` ゲッターで `LOG_LEVEL` を取得するが、取得値をロガーへ適用するコードはリポジトリ内に見当たらない。

## 原因
- ロガー実装と環境変数管理の間に連携コードが存在しないため、`LOG_LEVEL` を読み出して `Logger.setGlobalLevel` 等で適用する処理が行われていない。
- 同様に `LOG_MAX_QUEUE` や `LOG_FLUSH_INTERVAL_MS` などログ関連の環境変数も未使用である。

## 影響
- ドキュメント化されている `.env` のログ設定値が機能せず、実行環境ごとのログレベル・出力制御ができない。
- デバッグビルドでは常に `debug` 以上が出力され、ログ量が増大する。

## 補足観察
- グローバルロガーは `EnvValidator.initialize()` より前にシングルトンとして確定しているため、適用処理を追加する場合は初期化完了後に `Logger.setGlobalLevel` 等を呼び出す必要がある。
