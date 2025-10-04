# ログ環境設定適用プラン (2025-10-03)

## 目的
- `.env` で定義したログレベルや関連パラメータをランタイムで確実に反映させる。
- 環境ごとに期待したログ出力制御を行えるようにし、不要な `debug` ログの氾濫を防ぐ。

## ゴール
- アプリ起動直後に `LOG_LEVEL` を含むログ設定が `Logger` に適用される。
- 未指定の場合は既存デフォルトを維持しつつ、指定時は `.env` 側が優先される。
- 想定外の値を検出した場合は安全なフォールバックと警告ログを残す。

## 対応方針
1. **設定読み取りレイヤーの明示化**
   - `EnvValidator` からログ関連設定を読み取り、内部モデル(`LogRuntimeConfig` 仮称) にまとめるユーティリティを追加。
   - 文字列のレベル値を `LogLevel` 列挙体へ変換するマッパーを実装し、無効値は `info` にフォールバック。

2. **適用ポイントの確立**
   - `main.dart` で `EnvValidator.initialize()` の直後に新ユーティリティを呼び出し、`Logger.setGlobalLevel` やキュー設定等を更新。
   - 既存 `installCrashCapture()` 呼び出しとの依存関係を確認し、初期化順序の副作用をテストでカバー。

3. **追加パラメータへの拡張**
   - 優先度高: `LOG_LEVEL`, `LOG_MAX_QUEUE`, `LOG_FLUSH_INTERVAL_MS`, `LOG_BACKPRESSURE`。
   - 優先度中: `LOG_DIR`, `LOG_MAX_FILE_SIZE_MB`, `LOG_MAX_DISK_MB`, `LOG_RETENTION_DAYS` (ファイルシンクの実装調査が必要なため別タスク化も検討)。

4. **検証とテスト**
   - 新規ユーティリティの単体テストを追加し、代表ケース (warn 指定、typo、未指定) をカバー。
   - Flutter 起動テストで `Logger.config.globalLevel` が期待通りになることを確認するスモークテストを作成。

## タスクリスト
- [ ] `lib/infra/logging` にランタイム設定適用サービス(`log_runtime_config.dart` 等)を追加。
- [ ] `EnvValidator` からログ関連キーを読み取り、内部モデルにマッピングする処理を書く。
- [ ] 変換ロジックの単体テストを `test/infra/logging` 配下に作成。
- [ ] `main.dart` の起動フローで設定適用サービスを呼び出す。
- [ ] 既存ログドキュメント(`docs/plan/logging` 系)に関連する更新が必要か確認する。

## リスク / 留意事項
- ロガーはシングルトンのため、適用タイミング以前に出力される起動ログはデフォルトレベルで流れる。必要なら初期適用を `installCrashCapture()` の前へ移動する。
- フィールドスロットルやファイルシンク設定の適用は実装負荷が高いため、段階的に導入する。
- 既存のログレート制御や PII マスキングへの影響がないか確認する。

## 成功指標
- `.env` で `LOG_LEVEL=warn` を設定しデバッグビルドを実行した際、`Logger.config.globalLevel` が `LogLevel.warn` に更新される。
- 想定外の値 (`LOG_LEVEL=loud` 等) を指定すると警告ログが 1 回だけ出力され、自動的に `info` へフォールバックする。
