# CI/CD ガイド

このドキュメントでは、YATAプロジェクトのCI/CDパイプラインについて説明します。

## 概要

YATAプロジェクトでは、GitHub Actionsを使用して、ビルドとリリースのプロセスを自動化しています。

## リリースワークフロー

### トリガー

バージョンタグ（`v*.*.*` 形式）をリポジトリにpushすると、リリースワークフローが自動的にトリガーされます。

例：
```bash
git tag v1.0.0
git push origin v1.0.0
```

### ビルドプラットフォーム

リリースワークフローでは、以下のプラットフォーム向けにアプリケーションをビルドします：

1. **Linux (AppImage)**
   - Ubuntu環境でビルド
   - GTK依存関係のインストール
   - AppImageツールによるパッケージング
   - 成果物: `YATA-{version}-linux.AppImage`

2. **Windows (ZIP)**
   - Windows環境でビルド
   - リリースバイナリの生成
   - ZIP形式で圧縮
   - 成果物: `YATA-{version}-windows.zip`

3. **Android (APK)**
   - Ubuntu環境でビルド
   - JDK 17を使用
   - Flutter APKビルド
   - 成果物: `YATA-{version}-android.apk`

### ワークフロー構成

ワークフローは2つの主要なジョブで構成されています：

#### 1. `build-platforms`

各プラットフォーム向けに並行してビルドを実行します。以下のステップを含みます：

- リポジトリのチェックアウト
- Flutter環境のセットアップ
- 環境変数ファイルの生成
- プラットフォーム固有の依存関係のインストール
- Flutterの依存関係取得
- build_runnerによるコード生成
- リリースビルドの実行
- プラットフォーム固有のパッケージング
- 成果物のアップロード

#### 2. `publish-release`

すべてのビルドが完了した後、GitHub Releaseを作成します：

- 各プラットフォームの成果物をダウンロード
- リリース用に成果物を整理
- GitHub Releaseの作成と成果物の添付

## 環境変数とシークレット

ワークフローでは、以下のGitHub Secretsを使用します：

### 必須のシークレット

- `SUPABASE_URL`: SupabaseプロジェクトのURL
- `SUPABASE_ANON_KEY`: Supabaseの匿名キー

### オプションのシークレット

- `SUPABASE_OAUTH_CALLBACK_URL_DEV`: 開発環境のOAuthコールバックURL
- `SUPABASE_OAUTH_CALLBACK_URL_PROD`: 本番環境のOAuthコールバックURL
- `SUPABASE_OAUTH_CALLBACK_URL_MOBILE`: モバイルアプリのOAuthコールバックURL
- `SUPABASE_OAUTH_CALLBACK_URL_DESKTOP`: デスクトップアプリのOAuthコールバックURL
- `DEBUG_MODE`: デバッグモードの有効化フラグ
- `LOG_LEVEL`: ログレベルの設定
- `LOG_DIR`: ログディレクトリの設定
- その他のログ関連設定

## リリースの作成手順

新しいバージョンをリリースする手順：

### 1. バージョンの更新

`pubspec.yaml`のバージョン番号を更新します：

```yaml
version: 0.2.0  # 例：0.1.2 → 0.2.0
```

### 2. 変更のコミット

```bash
git add pubspec.yaml
git commit -m "chore: bump version to 0.2.0"
git push origin main  # または dev
```

### 3. タグの作成とプッシュ

```bash
git tag v0.2.0
git push origin v0.2.0
```

### 4. ワークフローの確認

GitHub Actionsのワークフローページでビルドとリリースのプロセスをモニタリングできます：
- https://github.com/YATA-repos/YATA/actions

### 5. リリースの確認

すべてのビルドが成功すると、リリースページに新しいリリースが表示されます：
- https://github.com/YATA-repos/YATA/releases

## トラブルシューティング

### ビルドが失敗した場合

1. **環境変数の確認**
   - 必須のシークレット（SUPABASE_URLとSUPABASE_ANON_KEY）が設定されているか確認

2. **依存関係の問題**
   - `pubspec.yaml`の依存関係が正しく設定されているか確認
   - build_runnerの実行が成功しているか確認

3. **プラットフォーム固有の問題**
   - 各プラットフォームのビルドログを確認
   - 必要な依存関係がすべてインストールされているか確認

### 成果物のアップロードエラー

- artifact-pathが正しく設定されているか確認
- ビルド成果物が実際に生成されているか確認

## ベストプラクティス

1. **セマンティックバージョニング**
   - メジャー.マイナー.パッチの形式を使用
   - 破壊的変更はメジャーバージョンを更新
   - 新機能はマイナーバージョンを更新
   - バグ修正はパッチバージョンを更新

2. **リリースノート**
   - 各リリースには、主な変更点を記載したリリースノートを追加
   - 破壊的変更、新機能、バグ修正を明確に分類

3. **テスト**
   - リリース前に、すべての主要機能をテスト
   - 可能であれば、各プラットフォームで動作確認

4. **プレリリース**
   - 大きな変更の場合は、プレリリースタグ（例：v1.0.0-beta.1）を使用して先行リリース

## 関連ファイル

- ワークフロー定義: `.github/workflows/tagged-builds.yml`
- アプリケーション設定: `pubspec.yaml`
- 環境変数テンプレート: `.env.example`
