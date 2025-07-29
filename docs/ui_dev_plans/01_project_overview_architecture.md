# Phase 1: プロジェクト概要とアーキテクチャ統合

## 1. プロジェクト基本情報

### プロジェクト概要

- **プロジェクト名**: YATA (日本語の「屋台(yatai)」から命名)
- **概要**: 小規模レストラン・飲食系屋台・露店向けの在庫・注文管理システム
- **プラットフォーム**: Flutter クロスプラットフォーム（主要ターゲット: Android, Windows）

### 主要機能

- 在庫追跡
- 注文管理
- 分析機能
- メニュー管理
- オフラインサポート（予定）
- Supabase バックエンド統合

## 2. 既存実装状況の分析

### 2.1 ✅ 実装済み（統合対象）

#### アーキテクチャ基盤
- **フィーチャーベース・サービスレイヤーアーキテクチャ** が完全実装済み
- **直線的依存関係**: UI→Service→Repository の構造が確立済み
- **ディレクトリ構造**: `features/` 配下に各機能が適切に分離済み

#### テーマシステム
- **AppColors**: 業務固有色（調理中、在庫状態等）を含む包括的な色定義
- **AppTextTheme**: UI用途別（カード、ボタン、テーブル等）の詳細なテキストスタイル
- **既存ファイル**: `lib/shared/themes/app_colors.dart`, `app_text_theme.dart`

#### ドメイン層
- **モデル**: `MenuItem`, `Order`, `OrderItem`, `MenuCategory` など完全実装済み
- **JSON対応**: シリアライゼーション・デシリアライゼーション対応済み
- **BaseModel**: 共通基底クラスによる統一された構造

#### サービス層
- **MenuService**: 在庫チェック、可否状態管理、検索機能等の詳細な業務ロジック
- **OrderService**: 注文処理・管理ロジック（推定）
- **InventoryService**: 在庫管理ロジック（推定）
- **バリデーション**: 入力検証システム完備

#### Repository層
- **データアクセス**: 各フィーチャーのRepository実装済み
- **Supabase統合**: インフラ層が実装済み

#### その他
- **DTO**: データ転送オブジェクト実装済み
- **ログシステム**: 詳細なログ管理（LoggerMixin）実装済み
- **例外処理**: 統一された例外ハンドリング

### 2.2 ❌ 未実装（新規作成対象）

#### UI層（プレゼンテーション層）
- **共通Widgetライブラリ**: `shared/widgets/` 配下はほぼ空
- **画面実装**: 各フィーチャーの `presentation/screens/` は空
- **Widgetコンポーネント**: 各フィーチャーの `presentation/widgets/` は空
- **状態管理**: Riverpod プロバイダー未実装

#### ナビゲーション・ルーティング
- **ルーティング設定**: 画面遷移の実装が必要
- **アプリ構造**: `main.dart`, `app/` の基本構造要整備

## 3. Phase 1 の修正された実装計画

### 3.1 統合タスク（既存実装活用）

#### テーマシステム統合
- [x] AppColors の活用準備 - 既存実装を確認済み
- [x] AppTextTheme の活用準備 - 既存実装を確認済み
- [ ] app_theme.dart の作成（既存テーマの統合）
- [ ] ThemeData の設定

#### アプリケーション骨格の整備
- [ ] main.dart の整備
- [ ] app/app.dart の作成
- [ ] app/routes.dart の作成
- [ ] 基本ナビゲーション構造の実装

#### レスポンシブ対応基盤
- [ ] ResponsiveHelper の実装
- [ ] ブレークポイント定義
- [ ] デバイス別レイアウト対応準備

### 3.2 新規実装タスク

#### 基本アプリ構造
```dart
// app/app.dart
class YataApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'YATA - 屋台管理システム',
      theme: AppTheme.lightTheme, // 既存テーマを活用
      routerConfig: AppRouter.router,
    );
  }
}
```

#### AppTheme 統合クラス
```dart
// shared/themes/app_theme.dart
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    textTheme: AppTextTheme.textTheme,
    // 既存の AppColors, AppTextTheme を活用
  );
}
```

#### ResponsiveHelper 実装
```dart
// core/utils/responsive_helper.dart
class ResponsiveHelper {
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 768;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= 768 && 
      MediaQuery.of(context).size.width < 1024;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= 1024;
}
```

## 4. 完了条件（修正版）

### 4.1 統合完了条件
- [x] 既存テーマシステムの確認と理解
- [x] 既存アーキテクチャの確認と理解
- [x] 既存サービス層の確認と理解
- [ ] 既存実装との統合設計完了

### 4.2 実装完了条件
- [ ] 基本アプリケーション構造が動作する
- [ ] 既存テーマシステムが適用されている
- [ ] レスポンシブヘルパーが実装されている
- [ ] 基本ルーティングが設定されている
- [ ] 既存サービスへのアクセス準備が完了している

## 5. 次のPhaseとの連携

### Phase 2 での活用
Phase 2では、ここで統合した基盤の上に共通Widgetライブラリを実装する際、以下を活用：

- **既存テーマシステム**: AppColors, AppTextTheme を直接使用
- **既存モデル**: MenuItem, Order等を UI専用モデルの変換元として活用
- **既存サービス**: MenuService等を直接Riverpodプロバイダーから呼び出し

### Phase 3 での活用
Phase 3の画面実装では：

- **既存サービスとの直接統合**: MenuService.getMenuItems()等を直接使用
- **既存モデルの活用**: ドメインモデルからUI表示用データへの変換
- **既存バリデーション**: InputValidatorの活用

## 6. 工数見積もり（修正版）

### 統合作業
- テーマ統合: 0.5日
- アプリ構造整備: 1日
- ルーティング基本設定: 1日

### 新規実装
- ResponsiveHelper: 0.5日
- 基本テスト・調整: 1日

**合計: 4日** （元計画の4-6日から短縮）

## 7. リスク軽減

### 既存実装活用によるメリット
- **開発期間短縮**: アーキテクチャ設計・サービス層実装が不要
- **品質向上**: 既にテスト済みの業務ロジックを活用
- **一貫性**: 既存のコーディング規約・パターンに準拠

### 注意点
- **既存コードの理解**: 既存実装の詳細理解が必要
- **統合設計**: 既存実装とUI層の適切な統合設計が重要
- **テーマ継承**: 既存テーマシステムの適切な活用