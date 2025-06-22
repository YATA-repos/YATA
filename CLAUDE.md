# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**厳格に従うこと:**

- **すべてのコミットメッセージ、ドキュメント、コメント、回答は日本語を使用すること**

## プロジェクト概要

- **プロジェクト名**: YATA (Yet Another Task App)
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

### レイヤー構造
```
UI Layer (Flutter Widgets/Pages)
    ↓
Business Services Layer  
    ↓
Repository Layer (Data Access)
    ↓
Model Layer (Domain Models & DTOs)
    ↓
Infrastructure (Supabase)
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

### 開発フロー
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
- 80文字行制限あり
- public API にはドキュメントコメント必須
- 生成ファイル（`*.g.dart`, `*.freezed.dart`）は解析除外

## 移植についての注意点

このプロジェクトは Python/Flet から Dart/Flutter への移植プロジェクトです：
- 元の設計思想とアーキテクチャを維持
- Python の async/await → Dart の Future/Stream
- Pydantic モデル → json_serializable
- 複雑なフィルタリングシステムを保持