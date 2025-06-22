# YATA

`*このREADMEはClaudeクンに全部生成してもらいました❣️とりあえずビジネスロジックまで完成したら人力で書き直す予定です。*`

## 詳細なドキュメント

<https://pennes-organization.gitbook.io/yata-dev-documents>

## 概要

レストラン在庫管理システム - Rin Stock Manager の Dart/Flutter 移植版  
効率的な在庫追跡、注文管理、分析機能を提供するクロスプラットフォームアプリケーション

## 🚀 主要機能

- **📦 在庫管理**: 材料、カテゴリ、レシピの追跡
- **🛒 注文処理**: 下書き、アクティブ、完了状態での注文処理
- **📊 分析**: 日次サマリーとビジネス洞察
- **🍽️ メニュー管理**: メニュー項目とカテゴリの整理
- **💾 オフラインサポート**: オフライン時の操作キューイング、再接続時の同期（実装予定）
- **🔒 データセキュリティ**: 適切な認証によるユーザー分離データ（実装予定）
- **📱 クロスプラットフォーム**: Android、iOS、Web、Windows、macOS、Linux対応

## 🛠️ 技術スタック

- **フロントエンド**: Flutter framework
- **言語**: Dart 3.8+
- **バックエンド**: Supabase (PostgreSQL) でデータ永続化
- **依存関係**: pubspec.yaml で依存関係管理
- **プラットフォーム**: Android, iOS, Web, Windows, macOS, Linux

## ⚡ クイックスタート

### 前提条件

- Flutter SDK 3.0+
- Dart SDK 3.8+
- Supabase アカウント（バックエンド用）

### インストール

```bash
# リポジトリをクローン
git clone <repository-url>
cd yata

# 依存関係をインストール
flutter pub get

# アプリケーションを実行
flutter run
```

### 設定

1. **Supabase設定**
   - Supabaseプロジェクトを作成
   - 必要なテーブルスキーマを設定
   - APIキーと URL を設定

2. **環境設定**
   - 設定ファイルで Supabase 認証情報を構成

## 📚 ドキュメント

| ドキュメント | 説明 |
|----------|-------------|
| [Python版リポジトリ](https://github.com/penne-0505/rin-stock-manager/) | 元のPython実装 |
| [移植分析ドキュメント](./_py_old_docs/project_analysis.md) | Python→Dart移植分析(仮) |
| [**旧**アーキテクチャガイド](./_py_old_docs/ja/architecture.md) | システム設計詳細 |
| [**旧**APIリファレンス](./_py_old_docs/ja/api-reference.md) | リポジトリ/サービスAPIドキュメント |

## 🏗️ プロジェクト状況

### ✅ 完了

- プロジェクト構造とFlutter設定
- 基本的なモデル定義（DTO、ドメインモデル）

### 🚧 進行中

- リポジトリ層の移植
- ビジネスサービス層の移植
- Flutterによる UI 開発
- オフライン機能統合

### 📋 計画中

- 認証システム統合
- 包括的なテストスイート
- デプロイガイド
- パフォーマンス最適化
- ストア公開準備

## 🏛️ システム構造

システムは階層モジュールで構成されています：

```
┌─────────────────────────────────────────┐
│           UI層 (Flutter)               │  ← ユーザーインターフェース
├─────────────────────────────────────────┤
│           サービス層                     │  ← ビジネスロジック
├─────────────────────────────────────────┤
│         リポジトリ層                     │  ← データアクセス
├─────────────────────────────────────────┤
│           モデル層                       │  ← データモデル
├─────────────────────────────────────────┤
│     インフラストラクチャ (Supabase)      │  ← データベース
└─────────────────────────────────────────┘
```

(サービスレイヤとUIレイヤの間に状態管理的なレイヤを挟むことも検討中)

### 実装詳細

- **リポジトリ層**: 高度なフィルタリングを持つ汎用CRUD操作
- **ビジネスサービス**: 分析、在庫、メニュー、注文管理
- **フィルタリングシステム**: 複雑なAND/ORクエリのサポート
- **オフラインサポート**: 接続問題に対するFileQueue + ReconnectWatcher（実装予定）
- **設定**: Dart標準の設定管理

### ディレクトリ構造

```
lib/
├── config/           # 設定とDI
├── models/           # データモデル
│   ├── bases/        # 基底クラス
│   ├── domains/      # ドメインモデル
│   └── dto/          # データ転送オブジェクト
├── repositories/     # データアクセス層
│   ├── bases/        # 基底リポジトリ
│   └── domains/      # ドメイン特化リポジトリ
├── services/         # ビジネスロジック層
│   ├── business/     # ビジネスサービス
│   └── platform/     # プラットフォームサービス
├── ui/               # ユーザーインターフェース
│   ├── pages/        # 画面
│   ├── routes/       # ルーティング
│   └── widgets/      # 再利用可能ウィジェット
└── utils/            # ユーティリティ
    ├── constants/    # 定数
    ├── filters/      # フィルタリング
    └── helpers/      # ヘルパー関数
```

## 🔧 開発

### 基本コマンド

```bash
# 環境セットアップ
flutter pub get

# テスト実行
flutter test                    # 全テスト実行
flutter test --coverage       # カバレッジ付き実行

# コード品質
dart format lib/ test/         # コードフォーマット
dart analyze                   # 静的解析

# ビルド
flutter build apk              # Android APK
flutter build ios             # iOS
flutter build web             # Web
flutter build windows         # Windows
flutter build macos           # macOS
flutter build linux           # Linux
```

### 貢献方法

1. リポジトリをフォーク
2. 機能ブランチを作成
3. 変更を実装
4. 新機能にテストを追加
5. ドキュメントを更新
6. プルリクエストを提出

詳細な手順については、開発ガイドを参照してください。

## 📦 移植について

このプロジェクトは [Rin Stock Manager](../rin-stock-manager/) のDart/Flutter移植版です。

### 主な変更点

- **言語**: Python 3.12+ → Dart 3.8+
- **UI フレームワーク**: Flet → Flutter
- **型システム**: Pydantic → Dart標準 + カスタムモデル
- **非同期処理**: asyncio → Future/Stream
- **パッケージ管理**: Poetry → pub

### 移植方針

- 元の設計思想とアーキテクチャを維持
- Dart/Flutterのベストプラクティスに準拠
- クロスプラットフォーム対応の最大化
- パフォーマンスと保守性の向上

詳細な移植分析については、[移植分析ドキュメント](./_py_old_docs/project_analysis.md)を参照してください。

## 📄 ライセンス

このプロジェクトは MIT ライセンスの下でライセンスされています - 詳細については [LICENSE.md](LICENSE.md) ファイルを参照してください。

## 🆘 サポート

質問や問題については、リポジトリにIssueを作成してください。
