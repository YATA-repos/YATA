# Inventory Service

## 概要

`inventory`フィーチャーのサービスクラスは、在庫管理機能に関するビジネスロジックを担当します。材料管理、在庫追跡、仕入れ処理、アラート管理などの複雑な在庫業務を提供します。

## サービスクラス一覧

### InventoryService

在庫管理業務を行うサービスです。

**場所**: `lib/features/inventory/services/inventory_service.dart`

**依存リポジトリ**:

- `MaterialRepository`
- `MaterialCategoryRepository`
- `RecipeRepository`
- `PurchaseRepository`
- `PurchaseItemRepository`
- `StockAdjustmentRepository`
- `StockTransactionRepository`
- `OrderItemRepository`

#### 主要メソッド

##### `createMaterial(Material material, String userId)`

材料を作成します。

- **パラメータ**:
  - `material`: 作成する材料オブジェクト
  - `userId`: ユーザーID
- **戻り値**: `Future<Material?>`
- **動作**:
  - 材料にユーザーIDを設定
  - MaterialRepositoryを通じて作成

##### `getMaterialCategories(String userId)`

材料カテゴリ一覧を取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MaterialCategory>>`
- **動作**: `findActiveOrdered`で表示順序通りに取得

##### `getMaterialsByCategory(String? categoryId, String userId)`

カテゴリ別材料一覧を取得します。

- **パラメータ**:
  - `categoryId`: 材料カテゴリID（nullで全件取得）
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Material>>`

##### `getStockAlertsByLevel(String userId)`

在庫レベル別アラート材料を取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<StockLevel, List<Material>>>`
- **動作**:
  - 緊急レベルとアラートレベルの材料を個別取得
  - アラートレベルから緊急レベルを除外して重複回避
  - レベル別にマップ形式で返却

**使用例**:

```dart
final inventoryService = InventoryService();
final alerts = await inventoryService.getStockAlertsByLevel(userId);
final criticalMaterials = alerts[StockLevel.critical] ?? [];
final lowMaterials = alerts[StockLevel.low] ?? [];
```

##### `updateMaterialStock(StockUpdateRequest request, String userId)`

材料在庫を手動更新します。

- **パラメータ**:
  - `request`: 在庫更新要求（材料ID、新数量、理由、メモ）
  - `userId`: ユーザーID
- **戻り値**: `Future<Material?>`
- **動作**:
  - 材料の存在とアクセス権限を確認
  - 在庫調整記録を作成（StockAdjustment）
  - 在庫取引記録を作成（StockTransaction）
  - 材料の在庫量を更新

**トランザクション処理**:

1. 調整量計算（新数量 - 現在在庫）
2. StockAdjustment作成
3. StockTransaction作成
4. Material在庫更新

##### `recordPurchase(PurchaseRequest request, String userId)`

仕入れを記録し、在庫を増加します。

- **パラメータ**:
  - `request`: 仕入れ要求（日付、メモ、仕入れアイテム一覧）
  - `userId`: ユーザーID
- **戻り値**: `Future<String?>`（仕入れID）
- **動作**:
  - Purchase（仕入れ）レコードを作成
  - PurchaseItem（仕入れ明細）を一括作成
  - 各材料の在庫を増加
  - StockTransactionで取引履歴を記録

**複合トランザクション**:

```
Purchase作成 → PurchaseItem一括作成 → Material在庫更新 → StockTransaction一括作成
```

##### `getMaterialsWithStockInfo(String? categoryId, String userId)`

材料一覧を在庫レベル・使用可能日数付きで取得します。

- **パラメータ**:
  - `categoryId`: 材料カテゴリID（nullで全件）
  - `userId`: ユーザーID
- **戻り値**: `Future<List<MaterialStockInfo>>`
- **動作**:
  - 基本材料情報を取得
  - 各材料の使用可能日数を一括計算
  - 日次使用量を計算（過去30日間）
  - MaterialStockInfoオブジェクトに変換

##### `calculateMaterialUsageRate(String materialId, int days, String userId)`

材料の平均使用量を計算（日次）します。

- **パラメータ**:
  - `materialId`: 材料ID
  - `days`: 計算対象日数
  - `userId`: ユーザーID
- **戻り値**: `Future<double?>`
- **動作**:
  - 期間内の消費取引（負の値）を取得
  - 総消費量を計算（絶対値）
  - 日数で除算して日次平均を算出

##### `calculateEstimatedUsageDays(String materialId, String userId)`

推定使用可能日数を計算します。

- **パラメータ**:
  - `materialId`: 材料ID
  - `userId`: ユーザーID
- **戻り値**: `Future<int?>`
- **動作**:
  - 材料の現在在庫量を取得
  - 過去30日間の平均使用量を計算
  - 現在在庫 ÷ 日次使用量 = 使用可能日数

**計算式**: `使用可能日数 = floor(現在在庫量 / 日次平均使用量)`

##### `getDetailedStockAlerts(String userId)`

詳細な在庫アラート情報を取得（レベル別 + 詳細情報付き）します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, List<MaterialStockInfo>>>`
- **動作**:
  - 全材料の詳細在庫情報を取得
  - 在庫レベル別に分類（critical、low、sufficient）
  - 各レベル内で材料名順にソート

##### `consumeMaterialsForOrder(String orderId, String userId)`

注文に対する材料を消費（在庫減算）します。

- **パラメータ**:
  - `orderId`: 注文ID
  - `userId`: ユーザーID
- **戻り値**: `Future<bool>`
- **動作**:
  - 注文明細を取得
  - 各メニューアイテムのレシピから必要材料量を計算
  - 材料在庫を減算（負の値にならないよう制御）
  - StockTransactionで消費記録を作成

**複雑な計算処理**:

```
注文明細取得 → レシピ取得 → 必要材料量集計 → 在庫減算 → 取引記録
```

##### `restoreMaterialsForOrder(String orderId, String userId)`

注文キャンセル時の材料を復元（在庫復旧）します。

- **パラメータ**:
  - `orderId`: 注文ID
  - `userId`: ユーザーID
- **戻り値**: `Future<bool>`
- **動作**:
  - 該当注文の消費取引を取得
  - 消費取引（負の値）のみを対象
  - 材料在庫を復元（消費量の絶対値を加算）
  - 復元取引記録を作成

##### `updateMaterialThresholds(String materialId, double alertThreshold, double criticalThreshold, String userId)`

材料のアラート閾値を更新します。

- **パラメータ**:
  - `materialId`: 材料ID
  - `alertThreshold`: アラート閾値
  - `criticalThreshold`: 緊急閾値
  - `userId`: ユーザーID
- **戻り値**: `Future<Material?>`
- **動作**:
  - 材料の存在とアクセス権限を確認
  - 閾値の妥当性チェック（緊急 ≤ アラート、非負数）
  - 材料の閾値を更新

**バリデーション**:

- `criticalThreshold <= alertThreshold`
- `criticalThreshold >= 0 && alertThreshold >= 0`

## ビジネスロジック詳細

### 在庫レベル管理

YATAシステムでは3段階の在庫レベルを採用：

1. **Sufficient（十分）**: `現在在庫 > アラート閾値`
2. **Low（少量）**: `緊急閾値 < 現在在庫 <= アラート閾値`
3. **Critical（緊急）**: `現在在庫 <= 緊急閾値`

### トランザクション設計

複数のデータ操作を含む処理での整合性保証：

**仕入れ処理のトランザクション**:

```
1. Purchase作成
2. PurchaseItem一括作成
3. Material在庫更新（複数）
4. StockTransaction一括作成
```

**注文消費のトランザクション**:

```
1. 注文明細取得
2. レシピ情報取得
3. 必要材料量計算
4. Material在庫減算（複数）
5. StockTransaction一括作成
```

### 使用量予測アルゴリズム

- **期間**: 過去30日間のデータを基準
- **計算**: 消費取引（負の値）の絶対値を平均化
- **精度**: 日次レベルでの使用量予測

## データ構造

### StockUpdateRequest

```dart
class StockUpdateRequest {
  final String materialId;
  final double newQuantity;
  final String reason;
  final String? notes;
}
```

### PurchaseRequest

```dart
class PurchaseRequest {
  final DateTime purchaseDate;
  final String? notes;
  final List<PurchaseItemDto> items;
}
```

### MaterialStockInfo

```dart
class MaterialStockInfo {
  final Material material;
  final StockLevel stockLevel;
  final int? estimatedUsageDays;
  final double? dailyUsageRate;
}
```

## パフォーマンス最適化

### 一括処理の活用

- **PurchaseItem**: `createBatch`による一括作成
- **StockTransaction**: `createBatch`による一括記録
- **使用可能日数計算**: `bulkCalculateUsageDays`による並列処理

### 計算処理の効率化

- **事前計算**: 使用量データの事前取得
- **キャッシュ活用**: 頻繁に参照される基準値
- **条件分岐**: 不要な計算の回避

## エラーハンドリング

### アクセス制御

```dart
if (material == null || material.userId != userId) {
  throw Exception("Material not found or access denied");
}
```

### データ整合性

```dart
if (criticalThreshold > alertThreshold) {
  throw Exception("Critical threshold must be less than or equal to alert threshold");
}
```

### 例外処理

```dart
try {
  // 複雑な処理
  return true;
} catch (e) {
  return false;  // 失敗時の安全な戻り値
}
```

## 関連モデル・DTO

- `Material`: `lib/features/inventory/models/inventory_model.dart`
- `MaterialCategory`: `lib/features/inventory/models/inventory_model.dart`
- `Recipe`: `lib/features/inventory/models/inventory_model.dart`
- `StockUpdateRequest`: `lib/features/inventory/dto/inventory_dto.dart`
- `PurchaseRequest`: `lib/features/inventory/dto/inventory_dto.dart`
- `MaterialStockInfo`: `lib/features/inventory/dto/inventory_dto.dart`
- `Purchase`: `lib/features/stock/models/stock_model.dart`
- `PurchaseItem`: `lib/features/stock/models/stock_model.dart`
- `StockAdjustment`: `lib/features/stock/models/stock_model.dart`
- `StockTransaction`: `lib/features/stock/models/stock_model.dart`

## 使用例

### 日常の在庫管理

```dart
final inventoryService = InventoryService();

// アラート材料の確認
final alerts = await inventoryService.getDetailedStockAlerts(userId);
final criticalMaterials = alerts['critical'] ?? [];

// 在庫の手動調整
final updateRequest = StockUpdateRequest(
  materialId: materialId,
  newQuantity: 50.0,
  reason: 'Manual adjustment',
  notes: 'Corrected after physical count',
);
await inventoryService.updateMaterialStock(updateRequest, userId);

// 使用可能日数の確認
final usageDays = await inventoryService.calculateEstimatedUsageDays(
  materialId, 
  userId
);
```

### 仕入れ処理

```dart
// 仕入れ記録
final purchaseRequest = PurchaseRequest(
  purchaseDate: DateTime.now(),
  notes: 'Weekly delivery',
  items: [
    PurchaseItemDto(materialId: materialId1, quantity: 100.0),
    PurchaseItemDto(materialId: materialId2, quantity: 50.0),
  ],
);

final purchaseId = await inventoryService.recordPurchase(
  purchaseRequest, 
  userId
);
```

### 注文処理連携

```dart
// 注文時の材料消費
final success = await inventoryService.consumeMaterialsForOrder(
  orderId, 
  userId
);

// 注文キャンセル時の材料復元
if (orderCanceled) {
  await inventoryService.restoreMaterialsForOrder(orderId, userId);
}
```

## 継承関係

```
InventoryService（独立クラス）
│
├─依存→ MaterialRepository
├─依存→ MaterialCategoryRepository
├─依存→ RecipeRepository
├─依存→ PurchaseRepository
├─依存→ PurchaseItemRepository
├─依存→ StockAdjustmentRepository
├─依存→ StockTransactionRepository
└─依存→ OrderItemRepository
```
