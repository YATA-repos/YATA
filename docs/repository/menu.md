# Menu Repository

## 概要

`menu`フィーチャーのリポジトリクラスは、メニュー管理機能に関するデータアクセスを担当します。メニューアイテムとメニューカテゴリの管理を行います。

## リポジトリクラス一覧

### MenuItemRepository

メニューアイテムの管理を行うリポジトリです。販売商品の検索、可用性管理に特化した機能を提供します。

**場所**: `lib/features/menu/repositories/menu_item_repository.dart`

**基底クラス**: `BaseRepository<MenuItem, String>`

#### 主要メソッド

##### `findByCategoryId(String? categoryId, String userId)`

カテゴリIDでメニューアイテムを取得します。

- **パラメータ**:
  - `categoryId`: メニューカテゴリID（nullの場合は全件取得）
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MenuItem>>`
- **動作**:
  - 表示順序（`display_order`）で昇順ソート

##### `findAvailableOnly(String userId)`

販売可能なメニューアイテムのみ取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MenuItem>>`
- **動作**:
  - `is_available = true`でフィルタリング
  - 表示順序で昇順ソート

##### `searchByName(dynamic keyword, String userId)`

名前でメニューアイテムを検索します。

- **パラメータ**:
  - `keyword`: 検索キーワード（String または List<String>）
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MenuItem>>`
- **動作**:
  - キーワードの正規化処理
  - 複数キーワードの場合はAND条件で検索
  - 大文字小文字を区別しない部分一致検索（ILIKE）

**使用例**:

```dart
// 単一キーワード検索
final items1 = await repository.searchByName("ハンバーガー", userId);

// 複数キーワード検索
final items2 = await repository.searchByName(["チーズ", "バーガー"], userId);
```

##### `findByIds(List<String> menuItemIds, String userId)`

IDリストでメニューアイテムを一括取得します。

- **パラメータ**:
  - `menuItemIds`: メニューアイテムIDのリスト
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MenuItem>>`

---

### MenuCategoryRepository

メニューカテゴリの管理を行うリポジトリです。

**場所**: `lib/features/menu/repositories/menu_category_repository.dart`

**基底クラス**: `BaseRepository<MenuCategory, String>`

#### 主要メソッド

##### `findActiveOrdered(String userId)`

アクティブなカテゴリ一覧を表示順で取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MenuCategory>>`
- **動作**:
  - `display_order`カラムで昇順ソート

## テーブル構造

### menu_items

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| name | String | 商品名 |
| category_id | String | メニューカテゴリID |
| price | int | 販売価格（円） |
| description | String? | 商品説明 |
| is_available | bool | 販売可能フラグ |
| estimated_prep_time_minutes | int | 推定調理時間（分） |
| display_order | int | 表示順序 |
| image_url | String? | 商品画像URL |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

### menu_categories

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| name | String | カテゴリ名 |
| display_order | int | 表示順序 |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

### menu_item_options

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| menu_item_id | String | メニューアイテムID |
| option_name | String | オプション名 |
| option_values | List<String> | 選択肢リスト |
| is_required | bool | 必須選択フラグ |
| additional_price | int | 追加料金 |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

## 特記事項

### 検索機能の特徴

- **柔軟なキーワード検索**: 単一文字列または文字列リストを受け付け
- **正規化処理**: 空白文字の除去、空文字列の除外
- **複数キーワード対応**: AND条件での絞り込み検索
- **大文字小文字非依存**: ILIKEを使用した部分一致検索

### 表示順序管理

- すべてのカテゴリとアイテムで`display_order`による順序制御
- UI上での並び順を柔軟に管理可能

### 販売可能性管理

- `is_available`フラグによる販売可否の制御
- 在庫切れや一時販売停止への対応

### 価格管理

- 価格は整数値（円単位）で管理
- 調理時間の見積もりも併せて管理

## 使用例

```dart
final menuItemRepo = MenuItemRepository();
final categoryRepo = MenuCategoryRepository();

// カテゴリ一覧取得
final categories = await categoryRepo.findActiveOrdered(userId);

// カテゴリ別メニュー取得
final mainDishes = await menuItemRepo.findByCategoryId(
  categories.first.id, 
  userId
);

// 販売可能メニューのみ取得
final availableItems = await menuItemRepo.findAvailableOnly(userId);

// メニュー検索
final searchResults = await menuItemRepo.searchByName("ハンバーガー", userId);
```

## 関連モデル

- `MenuItem`: `lib/features/menu/models/menu_model.dart`
- `MenuCategory`: `lib/features/menu/models/menu_model.dart`
- `MenuItemOption`: `lib/features/menu/models/menu_model.dart`

## 継承関係

```
BaseRepository<MenuItem, String>
  ↓
MenuItemRepository

BaseRepository<MenuCategory, String>
  ↓
MenuCategoryRepository
```
