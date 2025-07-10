---
applyTo: '**'
---
# AIエージェント向けガイドライン

This file provides guidance to AI agents when working with code in this repository.

このファイルは、Github Copilot などのAIエージェントがこのリポジトリのコードを扱う際のガイダンスを提供します。これに厳密に従ってください。

**厳格に従いなさい:**

- **すべてのドキュメントとコメント、回答は日本語を使用してください。**
- **Pull Request、Issue、Commit Messageは英語で記述してください。**
- **`rm -rf ~/` や `git reset --hard` などの危険なコマンドは、絶対に使用しないでください。どうしても実行する必要があるなら、ユーザーに実行を依頼してください。**

## 基本的な開発フロー

1. 機能ブランチ作成(`git checkout -b feature/branch-name`)
2. 実装
3. テスト
4. 言語ごとのスタイルに従って、静的解析
5. 言語ごとのスタイルに従って、フォーマット
6. コミット(指示がない場合実行しないこと)
7. Pull Request作成

## Git Workflow Guidelines

1. コミットメッセージは英語で記述し、以下の形式に従うこと:
   - `feat:` 新機能追加
   - `fix:` バグ修正
   - `refactor:` リファクタリング
   - `docs:` ドキュメント更新
   - `style:` コードスタイル修正・フォーマット
   - `test:` テスト追加・修正
   - `perf:` パフォーマンス改善
   - `build:` ビルドシステムや外部依存関係の変更
   - `ci:` CI設定の変更
   - `chore:` その他のメンテナンス作業
2. コミット前に自動で言語ごとのフォーマットと静的解析が実行されるように、`.pre-commit-config.yaml` を設定すること。
3. 感想は含めないこと。コミットメッセージは事実ベースで簡潔に記述すること。
4. コミットやIsssueの解決の遂行、Pull Requestの作成時などは必ず、現在のブランチが適切な`feature`系ブランチもしくは`dev`ブランチであることを確認すること。もし現在のブランチが適切でない場合は、`git checkout` で適切なブランチに切り替えること。
5. **明確に指示が無い限り、コミットは行わないこと。**

## Github Workflow Guidelines

### Github原則

- 全てのGithubの操作は、`gh`で使用できる、CLIを使用して行うこと。

### Pull Request Guidelines

- Pull Requestは必ず英語で記述し、以下の内容を含めること:
  - 変更の概要
  - 影響を受ける機能やファイル
  - テスト結果
- Pull Requestのタイトルは、コミットメッセージと同様に、適切なプレフィックスを使用すること。

### Issue Guidelines

- 大規模な変更や修正が想定される場合は、事前にIssueを作成し、内容を共有すること。
- 英語で記述し、以下の内容を含めること:
  - (問題/バグ/機能追加)の背景
  - 具体的な(解決策/機能追加)の提案
  - 受け入れ条件
  - 優先度(P0, P1, P2, P3, P4)
  - 想定される実装難易度(Easy, Medium, Hard)

## external tools Guidelines

### GitHub CLI (`gh`) Guidelines

- GitHub CLI (`gh`) を使用して、Pull Requestの作成、Issueの管理、PRレビューなどを行うこと。

---

## 1. プロジェクト基本情報

### プロジェクト概要

- **プロジェクト名**: YATA (日本語の「屋台(yatai)」から命名)
- **プロジェクト概要**: 小規模レストラン向けの在庫・注文管理システム
- **プラットフォーム**: Flutter クロスプラットフォーム（主要ターゲットプラットフォーム: Android,Web）
- **主要機能**:
  - 在庫追跡
  - 注文管理
  - 分析機能
  - メニュー管理
- **特徴**:
  - オフラインサポート
  - Supabase バックエンド統合
  - クロスプラットフォーム対応

---

## 2. 技術仕様

### 2.1 技術スタック

#### 主要依存関係

- **Flutter**: UI フレームワーク
- **flutter_riverpod**: 状態管理
- **supabase_flutter**: バックエンド（PostgreSQL）
- **json_annotation/json_serializable**: JSON シリアライゼーション
- **uuid**: UUID生成
- **decimal**: 高精度数値計算

#### 開発依存関係

- **flutter_lints** + **very_good_analysis**: リント設定
- **build_runner**: コード生成
- **flutter_test**: テストフレームワーク

### 2.2 アーキテクチャ

#### 概要

このプロジェクトは、一言で表すなら、「**フィーチャーベースの『サービスレイヤー・アーキテクチャ』(Feature-based Service Layer Architecture)**」を採用しています。ただし、このアーキテクチャと類似しているClean Architectureとの明確な違いは、「依存性の逆転は使わず、UI→Service→Repositoryという直線的な依存関係にしている」点です。

このアーキテクチャについては、以下のような言い換えも可能です：

- フィーチャーベース・レイヤードアーキテクチャ (Feature-based Layered Architecture)
- サービスレイヤー・アーキテクチャ (Service Layer Architecture)
- 直線的レイヤードアーキテクチャ (Linear Layered Architecture)

#### レイヤー構造(依存関係)

```text
UI Layer (Flutter Widgets/Pages)
    ↓
Business Services Layer  
    ↓
Repository Layer (Data Access)
```

#### ディレクトリ構造

```text
lib/
├── main.dart                # アプリケーションエントリーポイント
├── core/                    # コア機能
│   ├── auth/               # 認証サービス
│   ├── base/               # 基底クラス（BaseModel, BaseRepository）
│   ├── constants/          # 定数・設定
│   │   └── log_enums/      # ログ関連列挙型
│   ├── infrastructure/     # インフラ層
│   │   ├── offline/        # オフライン機能
│   │   └── supabase/       # Supabase統合
│   ├── sync/               # 同期機能
│   │   └── models/         # 同期関連モデル
│   └── utils/              # ユーティリティ（ログ、クエリ）
├── features/               # 機能別ディレクトリ
│   ├── analytics/          # 分析機能
│   │   ├── dto/            # Data Transfer Objects
│   │   ├── models/         # ドメインモデル
│   │   ├── presentation/   # UI（providers, screens, widgets）
│   │   ├── repositories/   # データアクセス
│   │   └── services/       # ビジネスロジック
│   ├── inventory/          # 在庫管理
│   │   ├── dto/
│   │   ├── models/
│   │   ├── presentation/
│   │   ├── repositories/
│   │   └── services/
│   ├── menu/               # メニュー管理
│   │   ├── dto/
│   │   ├── models/
│   │   ├── presentation/
│   │   ├── repositories/
│   │   └── services/
│   ├── order/              # 注文管理
│   │   ├── dto/
│   │   ├── models/
│   │   ├── presentation/
│   │   ├── repositories/
│   │   └── services/
│   └── stock/              # 在庫機能
│       ├── dto/
│       ├── models/
│       ├── presentation/
│       ├── repositories/
│       └── services/
├── routing/                # ルーティング
└── shared/                 # 共通UI要素
    ├── layouts/            # レイアウト
    ├── themes/             # テーマ
    └── widgets/            # ウィジェット
```

#### 重要な基底クラス

- `BaseModel`: JSON シリアライゼーション機能を持つモデル基底クラス
- `BaseRepository<T>`: CRUD操作とフィルタリング機能を提供するリポジトリ基底クラス
- 複雑なフィルタリングシステム（AND/OR クエリサポート）

#### DTOに関する注意点

- このプロジェクトにおけるDTOは、Entityとの変換を前提として**いません**。
- このプロジェクトにおいて、DTOはデータ転送専用のオブジェクトです。高度なdictのように振る舞うことを目的としています。