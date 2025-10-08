# Windows インストーラーと環境変数管理に関する設計ノート

## 背景

- Supabase 連携に必要な URL / Anonymous Key などをアプリが起動時に参照する必要がある。
- Linux AppImage や `flutter run` ではビルド時に `--dart-define-from-file=.env` を利用して埋め込み済み。
- Windows インストーラー版は `.env` を同梱しておらず、環境変数が存在しない端末でログインが失敗している。
- 将来的に自動アップデート（差分更新や再インストール型）を導入する構想があるため、環境変数の扱いと整合性維持が重要。

## 現状整理

- CI ( `.github/workflows/tagged-builds.yml` ) ではビルド前に GitHub Secrets から `.env` を生成し、`flutter build` 実行後に削除している。
- Windows インストーラー（Inno Setup）はビルド成果物のみを同梱し、ランタイムの環境変数は設定していない。
- その結果、インストーラー経由で導入した環境では `EnvValidator` が必須値の欠損を検知し、Supabase 初期化が失敗する。

## 将来的な自動アップデート機能を見据えた課題

| 課題カテゴリ | 説明 | リスク |
| --- | --- | --- |
| 環境変数の書き込み/更新 | インストーラーで `setx` などを使い、ユーザー/マシン環境変数を設定する | インストール時に権限不足で失敗、値の書き換えが反映されない |
| アップデート方式 | 差分更新 vs 再インストール型。後者はアンインストール後に再設定が必要 | アンインストーラーが環境変数を削除すると新版が動作しない |
| バージョン互換性 | 新しいバージョンが追加の設定値を要求するケース | 古い環境変数のままでは起動不能、エラー分岐の実装が必要 |
| マルチユーザー端末 | MACHINE スコープで書き込むか USER スコープか | 新規ユーザーで値が不足する可能性 |
| 監査/復旧手段 | 環境変数が欠損したときの復旧方法 | サポートコスト増大 |

## 推奨方針（環境変数を OS に設定するアプローチ）

1. **インストール時に環境変数を書き込む**
   - Inno Setup の `[Environment]` セクション、または PowerShell 経由で `setx` を利用。
   - マシン全体で共有したい場合は MACHINE スコープ、ユーザー毎に分離したい場合は USER スコープを選択。
   - 書き込み結果をログに残し、失敗時にはインストールを中断する（fail-fast）。

2. **アンインストール時の扱い**
   - 自動アップデート（再インストール型）を見越して、アンインストーラーが環境変数を削除しない設定を推奨。
   - どうしても削除したい場合は、アップデーターが実行前にバックアップ → 再設定するフローが必要。

3. **起動時の整合性チェック**
   - 既存の `EnvValidator` を活用し、欠損している値を UI へ通知。
   - 必要に応じて再設定用のスクリプトや手順書を用意。

4. **将来のキー追加・変更**
   - 新バージョンが新しい環境変数を要求する場合、起動時に不足を検知して明確なエラーメッセージを出す。
   - インストーラースクリプト/アップデーターで追加値を投入する。
   - 移行処理をコード化する場合はバージョン番号をレジストリなどに記録し、必要な移行を条件付きで実施。

5. **監査・復旧手段**
   - `docs/guide` などに「環境変数の再設定」手順を記載し、PowerShell ワンライナー等を共有。
   - ログにも現在認識している設定値（非機密情報のみ）を出力し、トラブルシュートを容易にする。

## 代替案の比較

| アプローチ | 長所 | 短所 |
| --- | --- | --- |
| 環境変数 (本稿推奨) | ユーザーが後から更新できる。自動アップデートでも保持しやすい | 初期設定が必要、漏れや削除で障害になる |
| `.env` 同梱 | インストールフォルダ内にファイルを置くだけで簡易 | ユーザーが書き換えにくい／ビルドをやり直す必要がある |
| 設定サーバーなどから動的取得 | クライアントに機密情報を持たせない | 初回起動時に認証・ネットワーク対応が必要 |

## 今後の実装メモ

- Inno Setup で環境変数を追加するサンプル
  ```ini
  [Environment]
  Name: "SUPABASE_URL"; Value: "https://example.supabase.co"; Flags: uninsdeletevalue
  Name: "SUPABASE_ANON_KEY"; Value: "your-key"; Flags: dontdeleteatuninstall
  ```
  - `uninsdeletevalue` を付けないことでアンインストール時に残せる。
  - 秘密情報をスクリプト内に直接埋め込むのではなく、CI で生成した `.env` をアップデート時に取り込みたい場合は PowerShell で `setx` を呼ぶ。

- PowerShell 経由での設定例
  ```powershell
  setx SUPABASE_URL "https://example.supabase.co" /M
  setx SUPABASE_ANON_KEY "your-key" /M
  ```
  `/M` は MACHINE スコープでの設定。 `/M` を外すとユーザー単位。

- 設定チェックの実装案
  - `EnvValidator.validate()` の結果を初回ログイン UI に表示し、「再設定する」ボタンから PowerShell スクリプトを起動。

- 監視ポイント
  - Supabase キーが期限切れ／ローテーションされるタイミング。
  - Windows Update などで環境変数の変更が反映されないケース（再起動が必要）。

## 参考リンク

- [Inno Setup: Environment section](https://jrsoftware.org/ishelp/index.php?topic=scriptsectionsenvironment)
- [Setx command (Windows)](https://learn.microsoft.com/windows-server/administration/windows-commands/setx)
- 自動アップデートを検討する際の一般的な設計指針（MSIX, Squirrel, 自前アップデータなど）
