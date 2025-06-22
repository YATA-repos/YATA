# Inventory Repository

## 概要

`inventory`フィーチャーのリポジトリクラスは、在庫管理機能に関するデータアクセスを担当します。材料マスタ、材料カテゴリ、レシピ（メニューと材料の関係）の管理を行います。

## リポジトリクラス一覧

### MaterialRepository

材料マスタの管理を行うリポジトリです。在庫量や閾値管理に特化した機能を提供します。

**場所**: `lib/features/inventory/repositories/material_repository.dart`

**基底クラス**: `BaseRepository<Material, String>`

#### 主要メソッド

##### `findByCategoryId(String? categoryId, String userId)`

カテゴリIDで材料を取得します。

- **パラメータ**:
  - `categoryId`: 材料カテゴリID（nullの場合は全件取得）
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Material>>`

##### `findBelowAlertThreshold(String userId)`

アラート閾値を下回る材料を取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Material>>`
- **動作**:
  - 全材料を取得後、現在在庫 ≤ アラート閾値の材料をフィルタリング

##### `findBelowCriticalThreshold(String userId)`

緊急閾値を下回る材料を取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Material>>`
- **動作**:
  - 全材料を取得後、現在在庫 ≤ 緊急閾値の材料をフィルタリング

##### `findByIds(List<String> materialIds, String userId)`

IDリストで材料を一括取得します。

- **パラメータ**:
  - `materialIds`: 材料IDのリスト
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Material>>`

##### `updateStockAmount(String materialId, double newAmount, String userId)`

材料の在庫量を更新します。

- **パラメータ**:
  - `materialId`: 材料ID
  - `newAmount`: 新しい在庫量
  - `userId`: ユーザーID
- **戻り値**: `Future<Material?>`
- **動作**:
  - 対象材料の存在確認後、在庫量のみを更新

---

### MaterialCategoryRepository

材料カテゴリの管理を行うリポジトリです。

**場所**: `lib/features/inventory/repositories/material_category_repository.dart`

**基底クラス**: `BaseRepository<MaterialCategory, String>`

#### 主要メソッド

##### `findActiveOrdered(String userId)`

アクティブなカテゴリ一覧を表示順で取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MaterialCategory>>`
- **動作**:
  - `display_order`カラムで昇順ソート

---

### RecipeRepository

レシピ（メニューと材料の関係）の管理を行うリポジトリです。

**場所**: `lib/features/inventory/repositories/recipe_repository.dart`

**基底クラス**: `BaseRepository<Recipe, String>`

#### 主要メソッド

##### `findByMenuItemId(String menuItemId, String userId)`

メニューアイテムIDでレシピ一覧を取得します。

- **パラメータ**:
  - `menuItemId`: メニューアイテムID
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Recipe>>`

##### `findByMaterialId(String materialId, String userId)`

材料IDを使用するレシピ一覧を取得します。

- **パラメータ**:
  - `materialId`: 材料ID
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Recipe>>`

##### `findByMenuItemIds(List<String> menuItemIds, String userId)`

複数メニューアイテムのレシピを一括取得します。

- **パラメータ**:
  - `menuItemIds`: メニューアイテムIDのリスト
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Recipe>>`

## テーブル構造

### materials

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| name | String | 材料名 |
| category_id | String | 材料カテゴリID |
| unit_type | UnitType | 管理単位（個数/グラム） |
| current_stock | double | 現在在庫量 |
| alert_threshold | double | アラート閾値 |
| critical_threshold | double | 緊急閾値 |
| notes | String? | メモ |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

### material_categories

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| name | String | カテゴリ名 |
| display_order | int | 表示順序 |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

### recipes

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| menu_item_id | String | メニューアイテムID |
| material_id | String | 材料ID |
| required_amount | double | 必要量 |
| is_optional | bool | オプション材料フラグ |
| notes | String? | 備考 |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

## 特記事項

### 在庫管理の特徴

- **閾値管理**: アラート閾値と緊急閾値の2段階で在庫レベルを管理
- **単位管理**: 個数（piece）とグラム（gram）の2種類の管理単位に対応
- **在庫レベル判定**: Materialモデルの`getStockLevel()`メソッドで在庫レベルを判定

### レシピ管理

- メニューアイテムと材料の多対多関係を管理
- 必要量とオプション材料フラグで詳細な材料管理が可能
- 逆引き検索（材料から使用メニューを検索）にも対応

### パフォーマンス考慮

- `findBelowAlertThreshold`と`findBelowCriticalThreshold`は、Supabaseでの複雑な条件指定を避けるため、アプリケーション側でフィルタリング
- `findByIds`系メソッドでIN句を活用した効率的な一括取得

## 関連モデル

- `Material`: `lib/features/inventory/models/inventory_model.dart`
- `MaterialCategory`: `lib/features/inventory/models/inventory_model.dart`
- `Recipe`: `lib/features/inventory/models/inventory_model.dart`
- `UnitType`: `lib/core/constants/enums.dart`
- `StockLevel`: `lib/core/constants/enums.dart`

## 継承関係

```
BaseRepository<Material, String>
  ↓
MaterialRepository

BaseRepository<MaterialCategory, String>
  ↓
MaterialCategoryRepository

BaseRepository<Recipe, String>
  ↓
RecipeRepository
```