# Repository Documentation

## 概要

このドキュメントは、YATA（Yet Another Task App）プロジェクトのリポジトリレイヤーに関する包括的なドキュメントです。レストラン在庫管理システムのデータアクセス層を担当する各リポジトリクラスの詳細な仕様を記載しています。

## アーキテクチャ概要

YATAプロジェクトは「**フィーチャーベースの『サービスレイヤー・アーキテクチャ』**」を採用しており、以下の依存関係を持ちます：

```
UI Layer (Flutter Widgets/Pages)
    ↓
Business Services Layer  
    ↓
Repository Layer (Data Access) ← このドキュメントの対象
```

## 基底クラス

すべてのリポジトリクラスは`BaseRepository<T, ID>`を継承しています。

**場所**: `lib/core/base/base_repository.dart`

**提供機能**:

- 基本的なCRUD操作
- フィルタリング・ソート機能
- ページネーション
- 一括操作
- エラーハンドリング
- ログ出力

詳細は[BaseRepositoryドキュメント](../base_repository.md)を参照してください。

## フィーチャー別リポジトリ一覧

### Analytics（分析機能）

| リポジトリクラス | 責任範囲 | 主要機能 |
|----------------|----------|----------|
| `DailySummaryRepository` | 日別集計データ管理 | 日別・期間別集計取得 |

**詳細**: [analytics.md](./analytics.md)

### Inventory（在庫管理）

| リポジトリクラス | 責任範囲 | 主要機能 |
|----------------|----------|----------|
| `MaterialRepository` | 材料マスタ管理 | 在庫閾値チェック、カテゴリ別取得 |
| `MaterialCategoryRepository` | 材料カテゴリ管理 | 表示順序管理 |
| `RecipeRepository` | レシピ管理 | メニュー-材料関係管理 |

**詳細**: [inventory.md](./inventory.md)

### Menu（メニュー管理）

| リポジトリクラス | 責任範囲 | 主要機能 |
|----------------|----------|----------|
| `MenuItemRepository` | メニューアイテム管理 | 検索、可用性フィルタ |
| `MenuCategoryRepository` | メニューカテゴリ管理 | 表示順序管理 |

**詳細**: [menu.md](./menu.md)

### Order（注文管理）

| リポジトリクラス | 責任範囲 | 主要機能 |
|----------------|----------|----------|
| `OrderRepository` | 注文管理 | 状態管理、期間検索、ページネーション |
| `OrderItemRepository` | 注文明細管理 | 売上集計、明細操作 |

**詳細**: [order.md](./order.md)

### Stock（在庫操作）

| リポジトリクラス | 責任範囲 | 主要機能 |
|----------------|----------|----------|
| `PurchaseRepository` | 仕入れ記録管理 | 期間別仕入れ履歴 |
| `PurchaseItemRepository` | 仕入れ明細管理 | 一括作成、明細取得 |
| `StockAdjustmentRepository` | 在庫調整管理 | 調整履歴管理 |
| `StockTransactionRepository` | 在庫取引記録管理 | 全在庫変動の追跡 |

**詳細**: [stock.md](./stock.md)

## 共通設計方針

### 1. ユーザーデータ分離

- すべてのメソッドで`userId`パラメータによるフィルタリングを実施
- マルチテナント環境でのデータ分離を保証

### 2. 型安全性

- 厳密な型定義（Dart/Flutter特性を活用）
- `json_serializable`による自動シリアライゼーション
- 列挙型（enum）による状態管理

### 3. パフォーマンス最適化

- 一括操作（`bulkCreate`, `bulkDelete`）の活用
- 効率的なクエリ設計
- 必要最小限のデータ転送

### 4. 日付処理の統一

- 日付範囲検索時の正規化処理
- タイムゾーン考慮設計
- 検索漏れ防止

### 5. エラーハンドリング

- `RepositoryException`による統一的エラー処理
- ログサービスとの連携
- デバッグ情報の充実

## データベース設計

### テーブル命名規則

- 複数形の英語名（例: `materials`, `orders`）
- スネークケース（例: `menu_items`, `stock_transactions`）

### 主キー設計

- すべてのテーブルでUUID（String型）を使用
- 複合主キーは使用しない（シンプル性重視）

### 外部キー関係

- 参照整合性の維持
- カスケード削除の適切な設定
- インデックス最適化

### 監査カラム

- `created_at`: 作成日時
- `updated_at`: 更新日時
- `user_id`: ユーザーID（必須）

## フィルタリングシステム

### QueryFilter階層

```dart
QueryFilter（抽象基底）
├── FilterCondition（単一条件）
├── AndCondition（AND条件）
├── OrCondition（OR条件）
└── ComplexCondition（複合条件）
```

### 対応演算子

- **比較**: `eq`, `neq`, `gt`, `gte`, `lt`, `lte`
- **文字列**: `like`, `ilike`
- **配列**: `inList`, `notInList`
- **NULL**: `isNull`, `isNotNull`
- **その他**: `contains`, `overlaps`等

詳細は[QueryUtilsドキュメント](../query_utils.md)を参照してください。

## 使用例

### 基本的な使用パターン

```dart
// リポジトリの初期化
final materialRepo = MaterialRepository();

// 単純な検索
final materials = await materialRepo.findByCategoryId(categoryId, userId);

// 複雑な条件検索
final filters = [
  QueryConditionBuilder.eq("user_id", userId),
  QueryConditionBuilder.lt("current_stock", 10.0),
];
final lowStockMaterials = await materialRepo.find(filters: filters);

// ページネーション
final (orders, totalCount) = await orderRepo.searchWithPagination(
  filters, 
  page: 1, 
  limit: 20
);
```

### 一括操作

```dart
// 一括作成
final newItems = await repository.bulkCreate(itemList);

// 一括削除
await repository.bulkDelete(idList);
```

### 期間検索

```dart
// 日付範囲での検索
final orders = await orderRepo.findByDateRange(
  DateTime.now().subtract(Duration(days: 7)),
  DateTime.now(),
  userId
);
```

## テストガイドライン

### 単体テスト

- 各リポジトリクラスの単体テスト必須
- モックSupabaseクライアントの使用
- エラーケースのテスト

### 統合テスト

- 実際のデータベースとの統合テスト
- トランザクション処理のテスト
- パフォーマンステスト

## パフォーマンス考慮事項

### インデックス戦略

- `user_id`カラムに必須インデックス
- 日付範囲検索用インデックス
- 外部キー制約のインデックス

### クエリ最適化

- N+1問題の回避
- 適切なJOIN使用
- 不要なデータ取得の回避

### キャッシュ戦略

- 頻繁にアクセスされるマスタデータ
- ユーザー設定データ
- カテゴリ・設定情報

## セキュリティ考慮事項

### データアクセス制御

- 必須`userId`フィルタリング
- 権限チェックの実装
- SQL インジェクション対策

### 機密情報保護

- ログ出力時の機密情報マスキング
- 適切なエラーメッセージ
- デバッグ情報の制限

## 今後の拡張予定

### 機能追加

- 全文検索機能の強化
- 地理情報検索対応
- レポート機能の充実

### パフォーマンス改善

- 接続プール最適化
- クエリキャッシュ
- 読み取り専用レプリカ対応

## 関連ドキュメント

- [BaseRepository仕様](../base_repository.md)
- [QueryUtils仕様](../query_utils.md)
- [LogService仕様](../log_service.md)
- [プロジェクト構造](../project_directory_tree.md)

## 変更履歴

| 日付 | 変更内容 | 担当者 |
|------|----------|--------|
| 2024-12-22 | 初版作成 | Claude |

---

**注意**: このドキュメントは実装と併せて継続的に更新される予定です。最新の情報については、常にコードとドキュメントの両方を参照してください。
