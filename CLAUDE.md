# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
  Language: Dart 3.8+
  Framework: Flutter 3.0+
  State Management: Riverpod
  Authentication: Supabase Auth with Google OAuth
  Platforms: Android, iOS, Web, Windows, macOS, Linux

Backend:
  Language: Unconfirmed (Supabase Edge Functions assumed)
  Framework: Supabase
  Database: PostgreSQL (Supabase)
  Deployment: To be determined

Development & Testing:
  Version Control: Git
  CI/CD: To be determined
  Test Framework: Flutter standard test framework (unconfirmed)
  Test Coverage: flutter test --coverage support
```

## Common Commands

### Development Commands

```bash
# Get dependencies
flutter pub get

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

Repositories are implemented in two-file structure:

- `abstract_repository.dart`: Interface definition
- `repository_impl.dart`: Concrete implementation

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

## Domain Models and Enums

Key business enums in `lib/core/constants/enums.dart`:

- `PaymentMethod`: cash, card, other
- `TransactionType`: purchase, sale, adjustment, waste
- `UnitType`: piece, gram
- `StockLevel`: sufficient, low, critical
- `OrderStatus`: preparing, completed, canceled
- `LogLevel`: debug, info, warning, error

## Authentication System

App uses `SupabaseClientService` singleton for authentication:

- Google OAuth integration
- Session management with automatic refresh
- Deep link handling for auth callbacks
- Comprehensive error handling and logging

## Logging System

Custom `LogService` provides:

- Structured logging with categories and metadata
- File persistence for warning/error levels in production
- Console output for development
- Buffer-based batch writing for performance

## Development Notes

### Current Status

- ✅ Project structure and Flutter setup complete
- ✅ Log service implemented
- 🚧 Model implementation in progress
- 🚧 Authentication system written but untested

### Development Plan

1. **Complete model implementation**
2. **Complete DTO (Data Transfer Object) implementation**
3. **Complete base repository implementation**
4. **Verify authentication system functionality and prepare for testing after repository layer implementation**
5. **Complete repository layer implementation**
6. **Complete infrastructure and core services implementation**
7. **Complete feature-specific business logic layer (service) implementation**
8. **Begin UI implementation**

### Migration Context

Python/Flet → Dart/Flutter port, preserving business logic while adapting to Flutter conventions.

### Testing

- Use `flutter test` for running tests
- Test coverage reports available with `--coverage` flag
- **Test styles and conventions currently undefined**
