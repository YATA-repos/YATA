# Menu Service

## 概要

`menu`フィーチャーのサービスクラスは、メニュー管理機能に関するビジネスロジックを担当します。在庫連動、販売可否判定、自動制御などの複雑なメニュー管理業務を提供します。

## サービスクラス一覧

### MenuService

メニュー管理業務を行うサービスです。

**場所**: `lib/features/menu/services/menu_service.dart`

**依存リポジトリ**:

- `MenuItemRepository`
- `MenuCategoryRepository`
- `MaterialRepository`
- `RecipeRepository`

#### 主要メソッド

##### `getMenuCategories(String userId)`

メニューカテゴリ一覧を取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MenuCategory>>`
- **動作**: `findActiveOrdered`で表示順序通りに取得

##### `getMenuItemsByCategory(String? categoryId, String userId)`

カテゴリ別メニューアイテム一覧を取得します。

- **パラメータ**:
  - `categoryId`: メニューカテゴリID（nullで全件取得）
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MenuItem>>`

##### `searchMenuItems(String keyword, String userId)`

メニューアイテムを検索します。

- **パラメータ**:
  - `keyword`: 検索キーワード
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MenuItem>>`
- **動作**:
  - ユーザーの全メニューアイテムを取得
  - アプリケーション側で名前・説明文での部分一致検索
  - 大文字・小文字を区別しない検索

**検索対象フィールド**:

- メニューアイテム名（`name`）
- 説明文（`description`）

**使用例**:

```dart
final menuService = MenuService();
final results = await menuService.searchMenuItems('カレー', userId);
// 'カレー'を含む名前または説明のメニューアイテムを返す
```

##### `checkMenuAvailability(String menuItemId, int quantity, String userId)`

メニューアイテムの在庫可否を詳細チェックします。

- **パラメータ**:
  - `menuItemId`: メニューアイテムID
  - `quantity`: 必要数量
  - `userId`: ユーザーID
- **戻り値**: `Future<MenuAvailabilityInfo>`
- **動作**:
  - メニューアイテムの存在・有効性を確認
  - レシピに基づく材料在庫チェック
  - オプション材料と必須材料を区別
  - 最大作成可能数を計算

**チェック項目**:

1. メニューアイテムの存在確認
2. `isAvailable`フラグの確認
3. レシピの存在確認
4. 各材料の在庫充足性チェック
5. 最大作成可能数の算出

**戻り値構造**:

```dart
class MenuAvailabilityInfo {
  final String menuItemId;
  final bool isAvailable;
  final List<String> missingMaterials;
  final int estimatedServings;
}
```

##### `getUnavailableMenuItems(String userId)`

在庫不足で販売不可なメニューアイテムIDを取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<String>>`
- **動作**:
  - 全メニューアイテムを取得
  - 各アイテムの在庫可否をチェック
  - 販売不可アイテムのIDリストを返却

##### `bulkCheckMenuAvailability(String userId)`

全メニューアイテムの在庫可否を一括チェックします。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, MenuAvailabilityInfo>>`
- **動作**:
  - 全メニューアイテムに対して`checkMenuAvailability`を実行
  - メニューアイテムID -> 在庫可否情報のマップを返却

**使用例**:

```dart
final menuService = MenuService();
final availabilityMap = await menuService.bulkCheckMenuAvailability(userId);

for (final entry in availabilityMap.entries) {
  final menuItemId = entry.key;
  final availability = entry.value;
  
  if (!availability.isAvailable) {
    print('Menu item $menuItemId is unavailable: ${availability.missingMaterials}');
  }
}
```

##### `calculateMaxServings(String menuItemId, String userId)`

現在の在庫で作れる最大数を計算します。

- **パラメータ**:
  - `menuItemId`: メニューアイテムID
  - `userId`: ユーザーID
- **戻り値**: `Future<int>`
- **動作**:
  - レシピを取得
  - 各必須材料について作成可能数を計算
  - 最も制限の厳しい材料をボトルネックとして採用

**計算ロジック**:

```
材料A: 在庫50g, レシピ必要量10g → 5人分可能
材料B: 在庫30g, レシピ必要量15g → 2人分可能
→ 最大作成可能数: 2人分（材料Bがボトルネック）
```

##### `getRequiredMaterialsForMenu(String menuItemId, int quantity, String userId)`

メニュー作成に必要な材料と使用量を計算します。

- **パラメータ**:
  - `menuItemId`: メニューアイテムID
  - `quantity`: 作成数量
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MaterialUsageCalculation>>`
- **動作**:
  - レシピから各材料の必要量を計算
  - 現在の在庫量と比較
  - 材料ごとの充足状況を判定

**戻り値構造**:

```dart
class MaterialUsageCalculation {
  final String materialId;
  final double requiredAmount;
  final double availableAmount;
  final bool isSufficient;
}
```

##### `toggleMenuItemAvailability(String menuItemId, bool isAvailable, String userId)`

メニューアイテムの販売可否を切り替えます。

- **パラメータ**:
  - `menuItemId`: メニューアイテムID
  - `isAvailable`: 新しい販売可否状態
  - `userId`: ユーザーID
- **戦り値**: `Future<MenuItem?>`
- **動作**:
  - メニューアイテムの存在・アクセス権限を確認
  - `is_available`フラグを更新

##### `bulkUpdateMenuAvailability(Map<String, bool> availabilityUpdates, String userId)`

メニューアイテムの販売可否を一括更新します。

- **パラメータ**:
  - `availabilityUpdates`: メニューアイテムID -> 可否状態のマップ
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, bool>>`
- **動作**:
  - 各メニューアイテムに対して`toggleMenuItemAvailability`を実行
  - 成功・失敗の結果をマップで返却

##### `autoUpdateMenuAvailabilityByStock(String userId)`

在庫状況に基づいてメニューの販売可否を自動更新します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, bool>>`
- **動作**:
  - 全メニューアイテムの在庫状況をチェック
  - 在庫不足のアイテムを自動的に販売停止
  - 在庫回復のアイテムを自動的に販売再開
  - 状態変更されたアイテムの一括更新を実行

**自動更新ロジック**:

```
在庫充足 && 推定提供数 > 0 → 販売可能
在庫不足 || 推定提供数 ≤ 0 → 販売停止
```

## ビジネスロジック詳細

### 在庫連動システム

メニューの販売可否は常に在庫状況と連動：

1. **リアルタイム在庫チェック**: 注文時点での正確な在庫確認
2. **材料レベル判定**: レシピの各材料における在庫充足性
3. **オプション材料対応**: 必須材料とオプション材料の区別
4. **ボトルネック特定**: 最も制限の厳しい材料の特定

### 作成可能数算出アルゴリズム

```dart
double maxServings = double.infinity;

for (Recipe recipe in recipes) {
  if (!recipe.isOptional && recipe.requiredAmount > 0) {
    int possibleServings = (material.currentStock / recipe.requiredAmount).floor();
    maxServings = min(maxServings, possibleServings.toDouble());
  }
}
```

### 自動制御システム

- **在庫監視**: 定期的な在庫状況のチェック
- **自動販売停止**: 在庫不足時の即座な販売停止
- **自動販売再開**: 在庫回復時の販売再開

## パフォーマンス最適化

### 一括処理の活用

- **bulkCheckMenuAvailability**: 全メニューの一括チェック
- **bulkUpdateMenuAvailability**: 販売可否の一括更新
- **効率的なクエリ**: 不要なデータベースアクセスの削減

### キャッシュ戦略

- **メニューカテゴリ**: 変更頻度の低いマスタデータ
- **レシピ情報**: 材料計算での再利用
- **在庫状況**: 短時間での重複チェック回避

## エラーハンドリング

### アクセス制御

```dart
if (menuItem == null || menuItem.userId != userId) {
  throw Exception("Menu item not found or access denied: $menuItemId");
}
```

### 在庫状況の例外処理

```dart
if (recipes.isEmpty) {
  // レシピがない場合は作成可能とみなす
  return MenuAvailabilityInfo(
    menuItemId: menuItemId,
    isAvailable: true,
    missingMaterials: [],
    estimatedServings: quantity,
  );
}
```

### 計算エラー対応

```dart
// ゼロ除算の回避
if (recipe.requiredAmount > 0) {
  int possibleServings = (availableAmount / recipe.requiredAmount).floor();
  maxServings = math.min(maxServings, possibleServings.toDouble());
}
```

## データ構造

### MenuAvailabilityInfo

```dart
class MenuAvailabilityInfo {
  final String menuItemId;
  final bool isAvailable;
  final List<String> missingMaterials;
  final int? estimatedServings;
}
```

### MaterialUsageCalculation

```dart
class MaterialUsageCalculation {
  final String materialId;
  final double requiredAmount;
  final double availableAmount;
  final bool isSufficient;
}
```

## 関連モデル・DTO

- `MenuItem`: `lib/features/menu/models/menu_model.dart`
- `MenuCategory`: `lib/features/menu/models/menu_model.dart`
- `MenuAvailabilityInfo`: `lib/features/menu/dto/menu_dto.dart`
- `MaterialUsageCalculation`: `lib/features/inventory/dto/inventory_dto.dart`
- `Material`: `lib/features/inventory/models/inventory_model.dart`
- `Recipe`: `lib/features/inventory/models/inventory_model.dart`

## 使用例

### 在庫連動メニュー表示

```dart
final menuService = MenuService();

// カテゴリ別メニュー取得
final categories = await menuService.getMenuCategories(userId);
final menuItems = await menuService.getMenuItemsByCategory(categoryId, userId);

// 在庫可否の一括チェック
final availabilityMap = await menuService.bulkCheckMenuAvailability(userId);

// 表示用データの構築
for (final menuItem in menuItems) {
  final availability = availabilityMap[menuItem.id];
  if (availability?.isAvailable == true) {
    // 販売可能として表示
    displayMenuItem(menuItem, availability.estimatedServings);
  } else {
    // 売り切れとして表示
    displayUnavailableMenuItem(menuItem, availability?.missingMaterials);
  }
}
```

### 注文前の在庫確認

```dart
// 注文前の詳細確認
final availability = await menuService.checkMenuAvailability(
  menuItemId, 
  orderQuantity, 
  userId
);

if (!availability.isAvailable) {
  // 在庫不足の警告表示
  showStockWarning(availability.missingMaterials);
} else if (availability.estimatedServings < orderQuantity) {
  // 数量制限の警告表示
  showQuantityLimitWarning(availability.estimatedServings);
}
```

### 管理者向け在庫管理

```dart
// 販売停止アイテムの確認
final unavailableItems = await menuService.getUnavailableMenuItems(userId);

// 在庫状況に基づく自動更新
final autoUpdated = await menuService.autoUpdateMenuAvailabilityByStock(userId);

// 手動での販売可否制御
final manualUpdates = {
  'menu_item_1': false,  // 一時的に販売停止
  'menu_item_2': true,   // 販売再開
};
await menuService.bulkUpdateMenuAvailability(manualUpdates, userId);
```

### レシピ分析

```dart
// 必要材料の詳細分析
final materialCalculations = await menuService.getRequiredMaterialsForMenu(
  menuItemId, 
  plannedQuantity, 
  userId
);

for (final calc in materialCalculations) {
  if (!calc.isSufficient) {
    final shortage = calc.requiredAmount - calc.availableAmount;
    print('Material ${calc.materialId} shortage: $shortage');
  }
}

// 最大作成可能数の確認
final maxServings = await menuService.calculateMaxServings(menuItemId, userId);
print('Maximum possible servings: $maxServings');
```

## 継承関係

```
MenuService（独立クラス）
│
├─依存→ MenuItemRepository
├─依存→ MenuCategoryRepository
├─依存→ MaterialRepository
└─依存→ RecipeRepository
```
