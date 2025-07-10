# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。`~/.claude/`にある基本ルールと併せて、これにも厳密に従い、積極的に参考にしてください。

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
