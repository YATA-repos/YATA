# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Strictly:**

- **Use Japanese for ALL commit messages, documentation, comments, and answers.**

## Overview

- **Project Name**: YATA
- **System Type**: Restaurant inventory management system
- **Platform**: Flutter cross-platform
- **Migrated From**: Rin Stock Manager (Python/Flet)
- **Core Features**:
  - Inventory tracking
  - Order management
  - Analytics
  - Menu management
- **Key Characteristics**:
  - Offline support
  - Supabase backend integration
  - Cross-platform compatibility

## Technology Stack

```
Frontend:
  Language: Dart 3.8.1
  Framework: Flutter 3.32.4
  State Management: Riverpod 2.6.1
  Authentication: Supabase Auth with Google OAuth
  Platforms: Android, iOS, Web, Windows, macOS, Linux

Backend:
  Framework: Supabase 2.9.0
  Database: PostgreSQL (Supabase)
  Deployment: To be determined

Core Libraries:
  Serialization: json_annotation 4.9.0, json_serializable 6.8.0
  Logging: Custom LogService with file persistence
  UUID: uuid 4.5.1
  Decimal: decimal 3.2.1
  Environment: flutter_dotenv 5.2.1
  Storage: shared_preferences 2.5.3, path_provider 2.1.4

Development & Testing:
  Version Control: Git
  Code Generation: build_runner 2.4.13
  Linting: very_good_analysis 9.0.0, custom_lint 0.7.5
  Test Framework: Flutter standard test framework
  Test Coverage: flutter test --coverage support
```

## Common Commands

### Development Commands

```bash
# Get dependencies
flutter pub get

# Generate JSON serialization code (required after model changes)
flutter packages pub run build_runner build

# Generate with watch mode (automatically regenerate on file changes)
flutter packages pub run build_runner watch

# Clean generated files
flutter packages pub run build_runner clean

# Run application
flutter run

# Format code (required by linting rules)
dart format lib/ test/

# Static analysis
dart analyze

# Run tests
flutter test
flutter test --coverage

# Build for different platforms
flutter build apk       # Android
flutter build ios       # iOS  
flutter build web       # Web
flutter build windows   # Windows
flutter build macos     # macOS
flutter build linux     # Linux
```

### Environment Setup

Project uses environment variables stored in `.env` file:

- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_ANON_KEY`: Supabase anonymous key
- `SUPABASE_AUTH_CALLBACK_URL`: OAuth callback URL (optional)

Environment variables are loaded via `Config` class using flutter_dotenv. Always use `Config.load()` before accessing Supabase credentials.

## Architecture

### Future-based Layered Architecture

Project follows layered architecture with direct linear dependencies (no dependency inversion):
**UI(Presentation) → Service → Repository** dependency flow.

```

lib/
├── core/                 # Shared core functionality
│   ├── auth/            # Authentication services
│   ├── base/            # Base models and classes
│   ├── constants/       # App constants and enums
│   ├── error/           # Error handling
│   ├── infrastructure/  # External service integration
│   └── utils/           # Utility services (logging, etc.)
├── features/            # Feature-based modules
│   ├── analytics/       # Business analytics
│   ├── inventory/       # Inventory management
│   ├── menu/           # Menu management
│   ├── order/          # Order processing
│   └── stock/          # Stock tracking
├── routing/            # App navigation
└── shared/             # Shared UI components
    ├── layouts/
    ├── themes/
    └── widgets/

```

### Feature Module Structure

Each feature follows the same pattern:

```

feature_name/
├── dto/           # Data Transfer Objects
├── models/        # Domain models
├── presentation/  # UI layer
│   ├── providers/ # State management (Riverpod)
│   ├── screens/   # Screen widgets
│   └── widgets/   # Feature-specific widgets
├── repositories/  # Data access layer
└── services/      # Business logic layer

```

### Repository Implementation Pattern

**Base Repository System** (完全実装済み):

- `BaseRepository<T extends BaseModel, ID>`: Generic base repository class
  - 型安全なCRUD操作（create, read, update, delete）
  - 複合主キー対応（`PrimaryKeyMap`）
  - 高度な検索・フィルタリング機能
  - バルク操作（一括作成・削除）
  - 存在確認・カウント機能
  - 包括的なエラーハンドリング

**Repository Concrete Implementation** (未実装):

- `abstract_repository.dart`: Interface definition
- `repository_impl.dart`: Concrete implementation

### Query System and Filtering (完全実装済み)

**QueryUtils System**:

- **31種類のフィルタ演算子**: eq, neq, gt, gte, lt, lte, like, ilike, isNull, isNotNull, inList, notInList, contains, containedBy, 範囲演算子群, overlaps
- **階層化論理条件**: FilterCondition → LogicalCondition (AndCondition, OrCondition, ComplexCondition)
- **型安全なクエリ構築**: QueryConditionBuilder with convenience methods
- **便利メソッド**: dateRange(), search(), numberRange(), anyOf(), allOf()

**Query Types**:

```dart
// Basic filter condition
FilterCondition eq = QueryConditionBuilder.eq("status", "active");

// Complex logical conditions
AndCondition complex = QueryConditionBuilder.and([
  QueryConditionBuilder.gte("created_at", "2024-01-01"),
  QueryConditionBuilder.lt("amount", 1000),
]);

// Repository usage
final results = await repository.find(
  filters: [complex],
  orderBy: [QueryConditionBuilder.desc("created_at")],
  limit: 50,
);
```

### Error Handling System (完全実装済み)

**Comprehensive Error Framework**:

- **LogMessage Interface**: 英語・日本語併用メッセージ
- **パラメータ置換**: `withParams()` method for dynamic values
- **専門分野別エラー**: Repository, Auth, Inventory, Order, Analytics
- **階層化例外**: Base Exception → Domain-specific Exceptions

### Type Safety and Null Safety

**Enhanced Type System**:

- **Null Safety**: 完全なnull安全性対応
- **Generic Types**: `BaseRepository<T extends BaseModel, ID>`で型安全なリポジトリ
- **Enum Usage**: すべての定数をenum化、型安全性確保
- **JSON Serialization**: `@JsonSerializable`による自動生成、型安全なシリアライゼーション

## Legacy Code Reference

### Source Code Location

Legacy Python source code: `_old_py_project/src/`

### Key Directory Mapping

```

Python Source              → Flutter Target
constants/                 → lib/core/constants/
models/domains/            → lib/features/{feature}/models/
models/dto/                → lib/features/{feature}/dto/
models/bases/              → lib/core/base/
repositories/bases/        → lib/core/base/
services/business/         → lib/features/{feature}/services/
services/platform/         → lib/core/infrastructure/
utils/                     → lib/core/utils/

```

### Migration Priority

1. **Business Logic**: Reference `services/business/` for core rules
2. **Data Models**: Study `models/domains/` for entity definitions  
3. **Base Classes**: Adapt `models/bases/` and `repositories/bases/` patterns
4. **Constants**: Migrate to Dart enums and constants

## Development Guidelines

### Coding Standards

**Dart/Flutter Coding Style**:

- Prefer double quotes over single quotes
- Trailing commas required
- Explicit type annotations required
- Public API documentation required

**Documentation Standards**:

- Include Japanese documentation using `///` for all variables, methods, and classes in generated code

### Security Guidelines

**Prohibited**:

- Reading .env files

### Code Quality Guidelines

**Prohibited**:

- Any hardcoding or magic numbers
- Implicit casts or dynamic types

**Requirements**:

- Project must comply with strict linting rules defined in `analysis_options.yaml`

## Git Workflow Guidelines

### Branch Strategy

**Branch Types** (4 types only for simplicity):

- `main`: Production-ready code
- `dev`: Development integration branch
- `fix/(issue-id)`: Bug fixes for development
- `hotfix/(issue-id)`: Critical fixes for production

**Workflow**:

- Primary development on `dev` branch
- No feature branches (simplicity priority)
- Bug fixes: `fix/(issue-id)` → `dev`
- Critical fixes: `hotfix/(issue-id)` → `main` (and merge back to `dev`)
- **After committing changes and ensuring the working tree is clean, push to remote repository**

### Commit Message Standards

**Format**: `[type] Japanese message`

**Types**:

- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `chore`: Maintenance tasks
- `build`: Build system changes
- `refactor`: Code refactoring
- `style`: Code style changes
- `test`: Test additions/modifications

**Language**: Japanese for all commit messages

**PROHIBITED**:

- English commit messages
- Write this message:

  ```
  🤖 Generated with [Claude Code](https://claude.ai/code)
  Co-Authored-By: Claude <noreply@anthropic.com>" 
  ```

**Message Format**:

```

[type] タイトル (1行目)

簡潔な説明 (3行目、1-2行程度)

```

**Examples**:

```

feat: ユーザー認証機能を追加

Google OAuthとSupabase認証を統合

fix: 在庫計算のバグを修正

負の値になる問題を解決

docs: APIドキュメントを更新

認証エンドポイントの説明を追加

refactor: リポジトリ層のコードを整理

抽象クラスとの分離を明確化

```

**Merge Strategy**: To be determined
**Release & Tagging Strategy**: To be determined

## Domain Models and Enums (完全実装済み)

### Business Enums in `lib/core/constants/enums.dart`

- `PaymentMethod`: cash, card, other (日本語表示名付き)
- `TransactionType`: purchase, sale, adjustment, waste
- `UnitType`: piece, gram
- `StockLevel`: sufficient, low, critical (色情報・記号付き)
- `OrderStatus`: preparing, completed, canceled (色情報付き)
- `LogLevel`: debug, info, warning, error
- `InventoryCategory`: material, product, supply
- `MenuCategory`: drink, food, dessert, set
- `AlertType`: stockLow, expireSoon, systemError

### Domain Models with JSON Serialization

**Analytics Domain** (`lib/features/analytics/models/`):

- `DailySummary`: 日次集計データ

**Inventory Domain** (`lib/features/inventory/models/`):

- `Material`: 材料マスタ（BaseModel継承）
- `MaterialCategory`: 材料カテゴリ
- `Recipe`: レシピ情報

**Menu Domain** (`lib/features/menu/models/`):

- `MenuCategory`: メニューカテゴリ
- `MenuItem`: メニュー項目
- `MenuItemOption`: メニューオプション

**Order Domain** (`lib/features/order/models/`):

- `Order`: 注文情報（BaseModel継承）
- `OrderItem`: 注文明細

**Stock Domain** (`lib/features/stock/models/`):

- `StockTransaction`: 在庫取引（BaseModel継承）
- `Purchase`: 購入情報
- `PurchaseItem`: 購入明細
- `StockAdjustment`: 在庫調整

### JSON Serialization Features

- **自動生成**: `@JsonSerializable()` による `.g.dart` ファイル自動生成
- **型対応**: DateTime, Enum, 基本型, null許容型完全対応
- **ビジネスロジック**: 各モデルに計算メソッド実装済み
- **BaseModel継承**: 共通のid/userIdフィールドとtableName実装

## Authentication System

App uses `SupabaseClientService` singleton for authentication:

- Google OAuth integration
- Session management with automatic refresh
- Deep link handling for auth callbacks
- Comprehensive error handling and logging

## Logging System (プロダクション対応完了)

**LogService** - 本格的なエンタープライズログシステム:

### 基本機能

- **構造化ログ**: カテゴリ・メタデータ付きログ出力
- **レベル別制御**: debug, info, warning, error の4段階
- **環境別動作**: 開発時はコンソール、リリース時はファイル永続化
- **多言語対応**: 英語・日本語併用メッセージサポート

### 高度な機能

- **ファイルローテーション**: 10MB超過時の自動ローテーション
- **バッファリング**: 100件蓄積後の一括書き込み（性能向上）
- **プラットフォーム別パス**: Android/iOS/Windows/macOS/Linux対応
- **統計情報取得**: ログファイル数・サイズ・バッファ状況の監視
- **古いログ削除**: 30日経過ログの自動クリーンアップ

### 使用例

```dart
// 基本ログ出力
LogService.debug("Component", "Debug message", "デバッグメッセージ");
LogService.info("Component", "Info message");
LogService.warning("Component", "Warning message");
LogService.error("Component", "Error message", null, error, stackTrace);

// 事前定義メッセージ使用
LogService.errorWithMessage("Component", RepositoryError.databaseConnectionFailed);
```

## Development Notes

### Current Status

#### ✅ **Phase 1-3: Core Infrastructure (完全実装済み)**

- ✅ Project structure and Flutter setup complete
- ✅ **LogService**: プロダクション対応ログシステム完成
- ✅ **Domain Models**: 全5ドメイン16モデルクラス、JSON serialization完備
- ✅ **BaseRepository**: 型安全なGeneric Repository、31種類フィルタ演算子対応
- ✅ **QueryUtils**: Python版を上回る高度なクエリシステム
- ✅ **Error Handling**: 包括的なエラーフレームワーク、多言語対応
- ✅ **Type Safety**: Null Safety、Generic Types、Enum活用による型安全性確保

#### 🚧 **Phase 4: Authentication (実装済み・テスト待ち)**

- 🚧 Authentication system: 実装完了、テスト・検証が必要

#### ⏳ **Phase 5以降: 未実装**

- ⏳ Repository concrete implementations
- ⏳ Service layer (business logic)
- ⏳ Infrastructure layer (Supabase integration)
- ⏳ UI layer (screens, widgets, state management)

### Development Plan

#### **Phase 4: Authentication Verification**

1. **認証システムのテスト・検証**
2. **OAuth callbackの動作確認**
3. **セッション管理の検証**

#### **Phase 5: Repository Implementation**

1. **各ドメインのRepository具象実装**
   - InventoryRepository, OrderRepository, StockRepository
   - MenuRepository, AnalyticsRepository
2. **BaseRepositoryを継承した具象クラス実装**
3. **Integration testing with Supabase**

#### **Phase 6: Service Layer Implementation**

1. **Business logic services implementation**
2. **Cross-domain service coordination**
3. **Offline synchronization logic**

#### **Phase 7: Infrastructure & Integration**

1. **Supabase client integration**
2. **Offline storage implementation**
3. **Data synchronization mechanisms**

#### **Phase 8: UI Implementation**

1. **Riverpod state management setup**
2. **Screen implementations**
3. **Widget library development**
4. **Navigation and routing**

### Migration Context

**Python/Flet → Dart/Flutter**: 大幅な改良を伴う移植プロジェクト

#### **完了済み移植と改善**

1. **Architecture Enhancement**:
   - Python版の散在したコードをレイヤー化アーキテクチャに整理
   - 型安全性の大幅向上（動的型 → 静的型、Null Safety）
   - 依存関係の明確化（UI→Service→Repository）

2. **Repository Pattern Upgrade**:
   - Python版: 基本的なCRUD操作
   - Dart版: Generic型、31種類フィルタ演算子、階層化論理条件

3. **Error Handling Systematization**:
   - Python版: 散在したエラー処理
   - Dart版: 統一的なエラーフレームワーク、多言語対応

4. **Type System Enhancement**:
   - Python版: 動的型、Optional型ヒント
   - Dart版: 完全なNull Safety、Generic Types、Enum活用

5. **Logging Infrastructure**:
   - Python版: ログ機能なし
   - Dart版: エンタープライズレベルのLogService

#### **移植済みコンポーネント**

- ✅ `models/domains/` → 16個のドメインモデル
- ✅ `models/bases/` → BaseModel、BaseRepository
- ✅ `constants/` → 9つのEnum型
- ✅ `repositories/bases/` → 型安全なGeneric Repository
- ✅ クエリシステム → Python版を上回る機能

### Testing

- Use `flutter test` for running tests
- Test coverage reports available with `--coverage` flag
- Integration testing planned for repository and service layers
- **Test styles and conventions currently undefined**

## Project Documentation

### External Documentation

- Supabase Flutter Client Library documentation: `docs/supabase_client_document/`

### Code Documentation

- **すべてのpublic API**: 包括的なドキュメンテーション
- **日本語コメント**: 生成コードでの変数・メソッド・クラス説明
- **アーキテクチャガイド**: このCLAUDE.mdファイル
- **JSON自動生成**: `.g.dart`ファイルによる型安全なシリアライゼーション
- **エラーメッセージ**: 英語・日本語併用の構造化メッセージ

### Implementation Status Overview

```
✅ Core Infrastructure (Phase 1-3)    [████████████████████] 100%
🚧 Authentication (Phase 4)           [████████████████░░░░]  80%
⏳ Repository Implementation (Phase 5) [░░░░░░░░░░░░░░░░░░░░]   0%
⏳ Service Layer (Phase 6)             [░░░░░░░░░░░░░░░░░░░░]   0%
⏳ Infrastructure Layer (Phase 7)      [░░░░░░░░░░░░░░░░░░░░]   0%
⏳ UI Implementation (Phase 8)         [░░░░░░░░░░░░░░░░░░░░]   0%

Overall Progress: ~30% (Core foundation complete)
```

### Key Achievements

- **型安全性**: Python版から大幅向上したコンパイル時型チェック
- **Query System**: 31種類の演算子、階層化論理条件によるPython版を上回る機能
- **Error Handling**: 統一的なフレームワークによる包括的エラー処理
- **Enterprise Logging**: プロダクション対応のログシステム
- **JSON Serialization**: `@JsonSerializable`による完全自動化

### Next Development Focus

認証システムのテスト完了後、Repository層の具象実装に着手予定。現在の堅牢な基盤により、後続開発の効率性と品質を大幅に向上させることが期待される。
