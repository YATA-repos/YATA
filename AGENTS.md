# AGENTS.md

このファイルは、 LLM/AIエージェントがこのリポジトリのコードを扱う際のガイダンスを提供します。積極的に活用してください。

---

## 0. 原則

- **ユーザーとの会話には日本語を使うこと**
- **Serena積極的に活用すること**
- **`git rm`と,ファイルの削除は禁止。その必要がある場合はコマンドをユーザーに提案し、ユーザーが実行するのを待つこと。**

## 1. プロジェクト基本情報

### プロジェクト概要

- **プロジェクト名**: YATA (日本語の「屋台(yatai)」から命名)
- **プロジェクト概要**: 小規模レストラン・飲食系屋台・露店向けの在庫・注文管理システム
- **プラットフォーム**: Flutter クロスプラットフォーム（主要ターゲットプラットフォーム: Android,Windows）
- **主要機能**:
  - 在庫追跡
  - 注文管理
  - 分析機能
  - メニュー管理

---

## 2. 技術仕様

### 2.1 技術スタック

#### 主要依存関係 (現状)

- **Flutter**
- **Riverpod(flutter_riverpod)**
- **Supabase(supabase_flutter)**
- **json_annotation/json_serializable**

#### 開発依存関係

- **flutter_lints** + **very_good_analysis**
- **build_runner**

### 2.2 アーキテクチャ

#### 概要

このプロジェクトの根本となる思想を一言で表すなら、「**フィーチャーベースの『サービスレイヤー・アーキテクチャ』(Feature-based Service Layer Architecture)**」です。ただし、このアーキテクチャと類似しているClean Architectureとの明確な違いは、「依存性の逆転は使わず、UI→Service→Repositoryという直線的な依存関係にしている」点です。

詳細は`docs/standards/architecture.md`に記載されています。

#### レイヤー構造(依存関係)

```text
UI Layer (Flutter Widgets/Pages)
    ↓
Business Services Layer  
    ↓
Repository Layer (Data Access)
```

---

## 3. 開発上のベストプラクティス

### 3.1 Gitの使用
  - **コミットメッセージ**:
    - 英語で記述すること。
    - 自己宣伝や感情的・主観的な表現は使用しないこと。
    - 一行の簡潔な要約を記述し、必要に応じて3~5行程度の詳細を追加すること。
    - コミットメッセージの先頭に、以下の形式を使用すること:
      - `feat:` 新機能
      - `fix:` バグ修正
      - `refactor:` リファクタリング
      - `style:` スタイルの変更（コードの意味に影響しない）
      - `perf:` パフォーマンス改善
      - `docs:` ドキュメントの変更
      - `build:` ビルドシステムや外部依存関係の変更
      - `ci:` CI/CDの設定変更
      - `test:` テストの追加・修正
      - `chore:` 以上のカテゴリに該当しない雑多な変更
    - コミットメッセージの例:
      ```
      feat: add analytics presentation layer

      - Add analytics screens for main view, inventory, and sales analytics
      - Implement analytics UI widgets including charts and stats cards
      - Add index file for organized widget exports
      ```
  - **ブランチ戦略**:
    - 新規作成するブランチ名は、以下の形式を使用すること:
      - `feature/` 機能追加
      - `fix/` バグ修正
      - `chore/` 雑多な変更
    - また、通常、`dev`ブランチをベースにして作業を行うこと。
  - **プルリクエスト**:
    - プルリクエストのタイトルは、コミットメッセージの要約と同様の形式を使用すること。
    - プルリクエストの説明には、変更内容の概要、目的、影響範囲を記述すること。

### 3.2 ドキュメンテーション
  - **ドキュメンテーション・ドキュメントの使用についてのベストプラクティスとガイドラインが、`docs/standards/documentation_guidelines.md`に記載されています。**
  - **新しいドキュメントを作成する際は、必ずこのガイドラインに従ってください。また、通常のコーディング時などにも積極的にこれらドキュメントを活用するようにしてください。**
