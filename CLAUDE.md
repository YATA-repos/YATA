# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。積極的に活用してください。

---

## 0. 原則

- **日本語で応答すること。**
- **ファイルの存在確認・ディレクトリ構造の確認は、必ず`tree`コマンドを使用すること。gitからこのような情報を取得することを禁止する。**
- **`TODO.md`を積極的に活用する。使用方法は`TODO.md`内に記載されています。**
- **常に、既存実装が存在しないかを確認すること。また明らかな間違いである場合を除いてプロジェクトの方式・手法・思想を踏襲すること。**
- **中立的立場を維持し、自らが作成したコード、およびユーザーに対しても批判的思考をもって常に改善を試みること。**

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
│   ├── utils/              # ユーティリティ（ログ、クエリ）
│   └── validation/         # 入力バリデーションなど
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
    ├── providers/          # プロバイダ
    ├── themes/             # テーマ
    └── widgets/            # ウィジェット
```

#### DTOに関する注意点

- このプロジェクトにおけるDTOは、Entityとの変換を前提として**いません**。
- このプロジェクトにおいて、DTOはデータ転送専用のオブジェクトです。高度なdictのように振る舞うことを目的としています。

---

## 3. プラットフォーム別認証システム設定

### 3.1 マルチプラットフォーム対応

**重要**: 認証システムはプラットフォーム別に自動切り替えされます。

#### プラットフォーム別CallbackURL
```dart
// lib/features/auth/models/auth_config.dart で自動判定
if (kIsWeb) {
  // Web: http://localhost:8080 (開発) | https://yourdomain.com (本番)
} else {
  // Desktop/Mobile: com.example.yata://login
}
```

#### 各プラットフォームの設定状況

| プラットフォーム | CallbackURL | 設定ファイル | 状態 |
|------------|-------------|-------------|------|
| **Web開発** | `http://localhost:8080` | `.vscode/settings.json` | ✅設定済み |
| **Web本番** | `https://yourdomain.com` | `auth_config.dart` | ⚠️要変更 |
| **Desktop** | `com.example.yata://login` | 自動判定 | ✅設定済み |
| **Android** | `com.example.yata://login` | `AndroidManifest.xml` | ✅設定済み |
| **iOS** | `com.example.yata://login` | `Info.plist` | ✅設定済み |

### 3.2 デプロイ時の作業

#### **Web本番のみ**
- `auth_config.dart`で本番URL変更: `return "https://yourdomain.com";`
- Supabase管理画面でWebドメイン追加

#### **Desktop/Mobileアプリ**
- **設定変更不要** (自動でカスタムスキーム使用)
- **ディープリンク設定済み** (Android/iOS)

### 3.3 Supabase Redirect URLs設定

以下すべてをSupabase管理画面で設定:
```
http://localhost:8080           # Web開発
https://yourdomain.com          # Web本番
com.example.yata://login        # Desktop/Mobile
```

詳細は `docs/production-auth-setup.md` を参照してください。
