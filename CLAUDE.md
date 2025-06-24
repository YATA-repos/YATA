# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。これに厳密に従ってください。

**厳格に従うこと:**

- **すべてのコミットメッセージ、ドキュメント、コメント、回答は日本語を使用すること**
- **自己宣伝やプロモーションを含むコードや、コメント、ドキュメント、コミットメッセージを使用しないこと(例: 「私の素晴らしい機能」、「このコミットメッセージはClaudeによって生成されました」など)**
- **常に遠慮せず、自らの最大限の能力を発揮して、プロジェクトの品質向上に貢献すること**
- **質問者・また自らに対して、常に批判的な視点を持ち、改善の余地を探ること**

## プロジェクト概要

- **プロジェクト名**: YATA (Yet Another Task App)
- **プロジェクト概要**: レストラン在庫管理システム (Rin Stock Manager) の移植プロジェクト
- **目的**: Python/Flet から Dart/Flutter への移植
- **システム種別**: レストラン在庫管理システム
- **プラットフォーム**: Flutter クロスプラットフォーム
- **移植元**: Rin Stock Manager (Python/Flet)
- **主要機能**:
  - 在庫追跡
  - 注文管理
  - 分析機能
  - メニュー管理
- **特徴**:
  - オフラインサポート
  - Supabase バックエンド統合
  - クロスプラットフォーム対応

## 開発環境・コマンド

### 依存関係管理

```bash
flutter pub get                 # 依存関係のインストール
dart pub global activate build_runner  # build_runner の有効化
```

### コード生成・ビルド

```bash
dart run build_runner build           # コード生成（一回のみ）
dart run build_runner watch          # コード生成（継続監視）
```

### テスト・品質チェック

```bash
flutter test                    # 全テスト実行
flutter test --coverage       # カバレッジ付きテスト実行
dart analyze                   # 静的解析
dart format lib/ test/         # コードフォーマット
```

### プラットフォーム別ビルド

```bash
flutter run                    # 開発実行
flutter build apk              # Android APK
flutter build web             # Web
flutter build windows         # Windows
flutter build macos           # macOS
flutter build linux           # Linux
```

## アーキテクチャ

### 概要

このプロジェクトは、一言で表すなら、「**フィーチャーベースの『サービスレイヤー・アーキテクチャ』(Feature-based Service Layer Architecture)**」を採用しています。ただし、このアーキテクチャと類似しているClean Architectureとの明確な違いは、「依存性の逆転は使わず、UI→Service→Repositoryという直線的な依存関係にしている」点です。

このアーキテクチャについては、以下のような言い換えも可能です：

- フィーチャーベース・レイヤードアーキテクチャ (Feature-based Layered Architecture)
- サービスレイヤー・アーキテクチャ (Service Layer Architecture)
- 直線的レイヤードアーキテクチャ (Linear Layered Architecture)

### レイヤー構造(依存関係)

```
UI Layer (Flutter Widgets/Pages)
    ↓
Business Services Layer  
    ↓
Repository Layer (Data Access)
```

### ディレクトリ構造

```
lib/
├── core/                     # コア機能
│   ├── auth/                # 認証サービス
│   ├── base/                # 基底クラス（BaseModel, BaseRepository）
│   ├── constants/           # 定数・設定
│   ├── error/               # エラー定義
│   ├── infrastructure/      # インフラ（Supabase等）
│   ├── sync/                # 同期機能
│   └── utils/               # ユーティリティ（ログ、クエリ）
├── features/                # 機能別ディレクトリ
│   ├── analytics/           # 分析機能
│   ├── inventory/           # 在庫管理
│   ├── menu/               # メニュー管理
│   ├── order/              # 注文管理
│   └── stock/              # 在庫機能
│       ├── dto/            # Data Transfer Objects
│       ├── models/         # ドメインモデル
│       ├── presentation/   # UI（providers, screens, widgets）
│       ├── repositories/   # データアクセス
│       └── services/       # ビジネスロジック
├── routing/                # ルーティング
├── shared/                 # 共通UI要素
└── main.dart
```

### 重要な基底クラス

- `BaseModel`: JSON シリアライゼーション機能を持つモデル基底クラス
- `BaseRepository<T>`: CRUD操作とフィルタリング機能を提供するリポジトリ基底クラス
- 複雑なフィルタリングシステム（AND/OR クエリサポート）

### コード生成パターン

- `*.g.dart` ファイルは `json_serializable` で自動生成
- モデルクラスには `@JsonSerializable()` アノテーション使用
- 生成ファイルは `.gitignore` に含めず、バージョン管理対象

## Git ワークフロー

### GitHub CLI の使用

- Issue や PR の作成には GitHub CLI (`gh`) を使用

### コミット・プッシュガイドライン

1. **必ずテストとlintを実行してから**コミット

   ```bash
   dart analyze && flutter test
   ```

2. **コミットメッセージは日本語で記述**
3. **変更内容に応じた適切なプレフィックス使用**:
   - `feat:` 新機能
   - `fix:` バグ修正
   - `refactor:` リファクタリング
   - `docs:` ドキュメント更新
   - `style:` コードスタイル修正
   - `test:` テスト追加・修正
   - `chore:` その他のメンテナンス作業

### 完全新規における開発フロー

1. 機能ブランチ作成
2. 実装とテスト
3. `dart analyze` と `flutter test` でチェック
4. 日本語でコミット
5. プルリクエスト作成（GitHub CLI推奨）

## 技術スタック詳細

### 主要依存関係

- **Flutter**: UI フレームワーク
- **flutter_riverpod**: 状態管理
- **supabase_flutter**: バックエンド（PostgreSQL）
- **json_annotation/json_serializable**: JSON シリアライゼーション
- **uuid**: UUID生成
- **decimal**: 高精度数値計算

### 開発依存関係

- **flutter_lints** + **very_good_analysis**: リント設定
- **build_runner**: コード生成
- **flutter_test**: テストフレームワーク

### Linter 設定

- 厳格な型チェック有効
- public API にはドキュメントコメント必須
- 生成ファイル（`*.g.dart`, `*.freezed.dart`）は解析除外

## 移植についての注意点

このプロジェクトは Python/Flet から Dart/Flutter への移植プロジェクトです：

- 元の設計思想とアーキテクチャを維持
- Python の async/await → Dart の Future/Stream
- Pydantic モデル → json_serializable
- 複雑なフィルタリングシステムを保持
- PythonのSupabaseクライアント → DartのSupabase Flutterクライアント
- 単にコードを移植するのではなく、Dart/Flutterの特性に最適化

## Issue作成ガイドライン

このプロジェクトでは、質の高いIssueを作成するために以下のフォーマットを使用すること。

### Issue作成の基本方針

1. **問題の背景と現状を詳細に記載**
2. **具体的な解決策を明示**
3. **受け入れ条件を明確に定義**
4. **適切な優先度を設定**

### Issue作成フォーマット

#### 1. タイトル

- 簡潔で具体的な内容を表現
- 動詞を含む行動指向のタイトル
- 例：「README.mdの再構成と内容の更新」「各Feature層のコードレビューと品質向上」

#### 2. 本文構成

```markdown
## 問題の概要

現在の状況と問題点を明確に記載。以下の観点を含める：
- 何が問題なのか
- なぜ問題なのか
- 現在の状況の詳細

## 現在の状況（必要に応じて）

具体的な現状を箇条書きで記載

## 解決すべき内容

### 1. カテゴリ別の具体的な作業項目
- 実装すべき機能
- 修正すべき問題
- 改善すべき点

### 2. 技術的な要件
- アーキテクチャ的な制約
- パフォーマンス要件
- 品質基準

## 対象ファイル（必要に応じて）

影響を受けるファイルのリスト

## 受け入れ条件

- [ ] チェックボックス形式で明確な完了条件を記載
- [ ] 測定可能で検証可能な条件
- [ ] 品質基準の明示

## 優先度

High/Medium/Low + 理由を記載
```

### 優先度設定ガイドライン

- **High**: プロジェクトの進行に直接影響する重要な問題
- **Medium**: 品質向上や将来的な保守性に関わる問題
- **Low**: 細かい改善や最適化

### Issue作成時の注意点

1. **プロジェクトの文脈を考慮**
   - レストラン在庫管理システムとしての特性
   - Flutter/Dartの技術的制約
   - 移植プロジェクトとしての背景

2. **具体性を重視**
   - 抽象的な表現は避ける
   - 具体的なファイル名やクラス名を含める
   - 実装方法の提案を含める

3. **品質基準の明確化**
   - コードの品質
   - テストの充実度
   - ドキュメントの完成度

4. **業界特有の要件**
   - レストラン業界の特性
   - ユーザビリティの考慮
   - アクセシビリティの配慮

### Issue作成のベストプラクティス

- **事前調査の実施**: 現状のコードを十分に理解してから作成
- **関連Issueの確認**: 重複や依存関係の整理
- **段階的な作業分割**: 大きな作業は複数のIssueに分割
- **レビュー可能な単位**: 一つのIssueで完結する作業範囲

このフォーマットに従うことで、プロジェクトの品質向上と効率的な開発進行を実現する。
