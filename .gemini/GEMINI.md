# GEMINI.md

このファイルは、Gemini CLI がこのリポジトリのコードを扱う際のガイダンスを提供します。これに厳密に従ってください。

---

## 1. プロジェクト基本情報

### 1.1 基本指針

**厳格に従いなさい:**

- **すべてのドキュメントとコメント、回答は日本語を使用すること**
- **Pull Request、Issue、コミットメッセージは英語で記述すること**
- **自己宣伝やプロモーションを含むコードや、コメント、ドキュメント、コミットメッセージを使用・挿入しないこと(例: 「私の素晴らしい機能」、「このコミットメッセージはClaudeによって生成されました」など)**
- **常に遠慮せず、自らの最大限の能力を発揮して、プロジェクトの品質向上に貢献すること**
- **質問者・また自らに対して、常に批判的な視点を持ち、改善の余地を探ること**
- **`rm -rf` や `git reset --hard` などの危険なコマンドは、絶対に使用しないこと。どうしても実行する必要があるなら、ユーザーに実行を依頼すること**

### 1.2 プロジェクト概要

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

---

## 3. 開発環境

### 3.1 環境構築

#### 依存関係管理

```bash
flutter pub get                 # 依存関係のインストール
dart pub global activate build_runner  # build_runner の有効化
```

#### コード生成・ビルド

```bash
dart run build_runner build           # コード生成（一回のみ）
dart run build_runner watch          # コード生成（継続監視）
```

#### コード生成パターン

- `*.g.dart` ファイルは `json_serializable` で自動生成
- モデルクラスには `@JsonSerializable()` アノテーション使用

### 3.2 コマンド一覧

#### テスト・品質チェック

```bash
flutter test                    # 全テスト実行
flutter test --coverage       # カバレッジ付きテスト実行
dart analyze                   # 静的解析
dart format lib/ test/         # コードフォーマット
```

#### プラットフォーム別ビルド

```bash
flutter run                    # 開発実行
flutter build apk              # Android APK
flutter build web             # Web
flutter build windows         # Windows
flutter build linux           # Linux
```

---

## 4. 開発ワークフロー

### 4.1 Git ワークフロー

#### GitHub操作に関する重要な指針

- **Githubに関連する操作(PRの作成、レビュー、マージ、Issue関連など)は、MCP経由で行ってください。**
- **PRには、必ず私(penne-0505)をassignee, reviewerに指定してください。**

#### コミット・プッシュガイドライン

1. **必ずテストとlintを実行してから**コミット

   ```bash
   dart analyze && dart format
   ```

2. **コミットメッセージは英語で記述**
3. **変更内容に応じた適切なプレフィックス使用**:
   - `feat:` 新機能
   - `fix:` バグ修正
   - `refactor:` リファクタリング
   - `docs:` ドキュメント更新
   - `style:` コードスタイル修正
   - `test:` テスト追加・修正
   - `chore:` その他のメンテナンス作業

#### 開発フロー

1. 機能ブランチ作成
2. 実装とテスト
3. `dart analyze` と `flutter test` でチェック
4. 英語でコミット
5. Pull Requestを作成

### 4.2 Issue管理

YATAプロジェクトでは、質の高いIssueの作成と効率的な管理を重視します。

#### 基本方針

- 問題の背景と現状を詳細に記載
- 具体的な解決策を明示
- 受け入れ条件を明確に定義
- 適切な優先度を設定

**詳細なガイドライン**: [`docs/guides/issue_guide.md`](../docs/guides/issue_guide.md) を参照してください。

### 4.3 タスク管理

#### Todoist使用判定基準

以下の条件に該当する場合は、**必ず**`../docs/guides/todoist_guide.md`に従ってTodoistでタスク管理を行うこと：

#### 必須使用場面

- **ユーザーから明示的な指示**: タスク管理、進捗追跡、計画立案を求められた場合
- **複数ステップの開発作業**: 設計→実装→テスト→ドキュメント→レビューの流れを含む作業
- **継続的管理が必要**: プロジェクト品質改善、段階的リファクタリング、ドキュメント体系整備

#### 判定フローチャート

```text
1. ユーザーが明示的にタスク管理を求めた？ → YES: Todoist使用
2. 作業予想時間が2時間を超える？ → YES: 次へ
3. 3つ以上のステップが必要？ → YES: 次へ  
4. 複数ファイル・機能への影響がある？ → YES: 次へ
5. 継続的フォローアップが必要？ → YES: 次へ

ステップ2-5で2つ以上該当 → Todoist使用
1つ以下 → Claude Code内TodoWrite使用
```

#### 使用しない場面

- 単発の質問・説明・コードレビュー
- 30分以内で完了する軽微な修正
- 一度限りの調査・技術相談

---

## 5. 品質・ドキュメント

### 5.1 コード品質基準

#### Linter 設定

- 厳格な型チェック有効
- public API にはドキュメントコメント必須
- 生成ファイル（`*.g.dart`, `*.freezed.dart`）は解析除外

#### 品質チェック手順

1. **開発中**: `dart run build_runner watch` でコード生成を継続実行
2. **コミット前**: 必ず `dart analyze && dart format && flutter test` を実行
3. **PR作成前**: カバレッジ付きテスト実行で品質確認

### 5.2 ドキュメント管理

#### 基本方針

YATAプロジェクトでは、技術ドキュメントの品質と一貫性を重視します。ドキュメントは単なるAPIの仕様書ではなく、開発者が**「なぜ（Why）」**から理解し、正しく効果的に活用できるよう導くための**「ガイド」**です。

#### ドキュメント種別

- **ガイド型** (`docs/guides/`): 手順やベストプラクティス
- **リファレンス型** (`docs/references/`): API仕様や技術詳細

**詳細なガイドライン**: [`docs/guides/DOCUMENTATION_GUIDE.md`](../docs/guides/DOCUMENTATION_GUIDE.md) を参照してください。

---

## 6. ドキュメント参照

### 6.1 ガイドドキュメント（`docs/guides/`）

開発手順やベストプラクティスを説明するガイド型ドキュメント：

- **[DOCUMENTATION_GUIDE.md](../docs/guides/DOCUMENTATION_GUIDE.md)**: ドキュメント作成ガイドライン
- **[issue_guide.md](../docs/guides/issue_guide.md)**: Issue作成フォーマットとベストプラクティス
- **[logger_guide.md](../docs/guides/logger_guide.md)**: ログシステムの使用方法
- **[todoist_guide.md](../docs/guides/todoist_guide.md)**: Todoistタスク管理ワークフロー
- **[template_guide.md](../docs/guides/template_guide.md)**: ガイド型ドキュメント作成テンプレート

### 6.2 リファレンスドキュメント（`docs/references/`）

API仕様や技術詳細を記述するリファレンス型ドキュメント：

#### コア機能

- **[base_repository.md](../docs/references/base_repository.md)**: BaseRepositoryクラスの詳細仕様
- **[log_service.md](../docs/references/log_service.md)**: ログサービスAPI仕様
- **[logger_mixin.md](../docs/references/logger_mixin.md)**: LoggerMixinの使用方法
- **[query_utils.md](../docs/references/query_utils.md)**: クエリユーティリティ関数群
- **[project_directory_tree.md](../docs/references/project_directory_tree.md)**: プロジェクト構造詳細

#### Repository層（`docs/references/repository/`）

- **[README.md](../docs/references/repository/README.md)**: Repository層の概要
- **[analytics.md](../docs/references/repository/analytics.md)**: 分析機能Repository
- **[inventory.md](../docs/references/repository/inventory.md)**: 在庫管理Repository  
- **[menu.md](../docs/references/repository/menu.md)**: メニュー管理Repository
- **[order.md](../docs/references/repository/order.md)**: 注文管理Repository
- **[stock.md](../docs/references/repository/stock.md)**: 在庫機能Repository

#### Service層（`docs/references/service/`）

- **[README.md](../docs/references/service/README.md)**: Service層の概要
- **[analytics.md](../docs/references/service/analytics.md)**: 分析機能Service
- **[inventory.md](../docs/references/service/inventory.md)**: 在庫管理Service
- **[menu.md](../docs/references/service/menu.md)**: メニュー管理Service
- **[order.md](../docs/references/service/order.md)**: 注文管理Service

#### 外部サービス

- **[Supabase_client_lib_docs.md](../docs/references/supabase_client_document/Supabase_client_lib_docs.md)**: Supabaseクライアント仕様

#### テンプレート

- **[template_reference.md](../docs/references/template_reference.md)**: リファレンス型ドキュメント作成テンプレート

### 6.3 ドキュメント活用のガイドライン

- **開発開始時**: プロジェクト理解のため、このCLAUDE.mdから開始
- **機能実装時**: 該当する機能のService/Repositoryリファレンスを参照
- **問題発生時**: トラブルシューティングのためガイドドキュメントを確認
- **新規ドキュメント作成時**: 適切なテンプレートを使用

---

## 重要な指示

- この文書の内容に従い、プロジェクトの品質向上に最大限貢献してください
- 不明な点があれば、上記リンク集から関連するドキュメントを参照してください
- 常に批判的な視点を持ち、改善の機会を見つけてください
