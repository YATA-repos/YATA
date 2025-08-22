# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。積極的に活用してください。

---

## 0. 原則

- **日本語で応答すること。**
- **ファイルの存在確認・ディレクトリ構造の確認は、必ず`tree`コマンドを使用すること。gitからこのような情報を取得することを禁止する。**
- **`TODO.md`を積極的に活用する。使用方法は`TODO.md`内に記載されています。**
- **常に、既存実装が存在しないかを確認すること。また明らかな間違いである場合を除いてプロジェクトの方式・手法・思想を踏襲すること。**
- **迂回や別アプローチを独断で行わず、最初の計画が失敗したら次の計画についてユーザーに同意をとること。**
- **中立的立場を維持し、自らが作成したコード、およびユーザーに対しても批判的思考をもって常に改善を試みること。**
- **以上の原則を、すべての回答の冒頭に記載すること。**

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
- **特徴**:
  - オフラインサポート(予定)
  - Supabase バックエンド統合
  - クロスプラットフォーム対応

---

## 2. 技術仕様

### 2.1 技術スタック

#### 主要依存関係

- **Flutter**
- **Riverpod(flutter_riverpod)**
- **Supabase(supabase_flutter)**
- **json_annotation/json_serializable**
- **decimal**

#### 開発依存関係

- **flutter_lints** + **very_good_analysis**
- **build_runner**

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
    ↓
Data Layer (lib/data/) ← 新しく分離されたデータ層
    ├─ Local Data (cache, offline)
    ├─ Remote Data (Supabase)
    ├─ Realtime Data (WebSocket)
    └─ Batch Processing
```

---

## 3. 開発上のベストプラクティス

### 3.1 コーディング規約

- **命名規則**:
  - クラス名: `UpperCamelCase`
  - メソッド名: `lowerCamelCase`
  - 定数: `lowerCamelCase`
  - ファイル名: `snake_case.dart`

- **コメント**:
  - クラス、メソッド、重要なロジックには必ずコメントを記述すること。
  - クラス・メソッドの説明は、`///` を使用してドキュメンテーションコメントを記述
  - 重要なロジックや複雑な部分には、`//` を使用してコメントを記述
  - 冗長性を避け、コード内容から明らかな部分はコメントを省略すること。
  - 以下の接頭辞を使用して、コメントの種類を明確にすること:
    - `// TODO `: 一時的なTODOコメント。`TODO.md`に移行すること。
    - `// ! `: 修正の必要性やクリティカルな情報を示す。将来的に`TODO.md`に移行すること。
    - `// ? `: コードに対する疑問・質問を示す。
    - `// * `: 重要な情報や注意点を示す。
    - **注: これ以外の接頭詞は禁止**

### 3.2 Gitの使用
  - **コミットメッセージ**:
    - 英語で記述すること。
    - 自己宣伝や感情的な表現は使用しないこと。
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

### 3.3 ドキュメンテーション
  - **ドキュメンテーションについてのベストプラクティスとガイドラインは、`docs/standards/documentation_guidelines.md`に記載されています。**
  - **新しいドキュメントを作成する際は、必ずこのガイドラインに従ってください。**