# Stock Repository

## 概要

`stock`フィーチャーのリポジトリクラスは、在庫管理機能に関するデータアクセスを担当します。仕入れ記録、在庫調整、在庫取引履歴の管理を行います。

## リポジトリクラス一覧

### PurchaseRepository

仕入れ記録の管理を行うリポジトリです。

**場所**: `lib/features/stock/repositories/purchase_repository.dart`

**基底クラス**: `BaseRepository<Purchase, String>`

#### 主要メソッド

##### `findRecent(int days, String userId)`

最近の仕入れ一覧を取得します。

- **パラメータ**:
  - `days`: 過去N日間
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Purchase>>`
- **動作**:
  - 仕入れ日で降順ソート

##### `findByDateRange(DateTime dateFrom, DateTime dateTo, String userId)`

期間指定で仕入れ一覧を取得します。

- **パラメータ**:
  - `dateFrom`: 開始日
  - `dateTo`: 終了日
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Purchase>>`
- **動作**:
  - 日付を日の開始時刻・終了時刻に正規化
  - 仕入れ日で降順ソート

---

### PurchaseItemRepository

仕入れ明細の管理を行うリポジトリです。

**場所**: `lib/features/stock/repositories/purchase_item_repository.dart`

**基底クラス**: `BaseRepository<PurchaseItem, String>`

#### 主要メソッド

##### `findByPurchaseId(String purchaseId)`

仕入れIDで明細一覧を取得します。

- **パラメータ**:
  - `purchaseId`: 仕入れID
- **戻り値**: `Future<List<PurchaseItem>>`
- **動作**:
  - 作成順でソート

##### `createBatch(List<PurchaseItem> purchaseItems)`

仕入れ明細を一括作成します。

- **パラメータ**:
  - `purchaseItems`: 仕入れ明細のリスト
- **戻り値**: `Future<List<PurchaseItem>>`
- **動作**:
  - BaseRepositoryの`bulkCreate`を呼び出し

---

### StockAdjustmentRepository

在庫調整の管理を行うリポジトリです。

**場所**: `lib/features/stock/repositories/stock_adjustment_repository.dart`

**基底クラス**: `BaseRepository<StockAdjustment, String>`

#### 主要メソッド

##### `findByMaterialId(String materialId, String userId)`

材料IDで調整履歴を取得します。

- **パラメータ**:
  - `materialId`: 材料ID
  - `userId`: ユーザーID
- **戻り値**: `Future<List<StockAdjustment>>`
- **動作**:
  - 調整日時で降順ソート

##### `findRecent(int days, String userId)`

最近の調整履歴を取得します。

- **パラメータ**:
  - `days`: 過去N日間
  - `userId`: ユーザーID
- **戻り値**: `Future<List<StockAdjustment>>`
- **動作**:
  - 調整日時で降順ソート

---

### StockTransactionRepository

在庫取引記録の管理を行うリポジトリです。全ての在庫変動を記録・追跡します。

**場所**: `lib/features/stock/repositories/stock_transaction_repository.dart`

**基底クラス**: `BaseRepository<StockTransaction, String>`

#### 主要メソッド

##### `createBatch(List<StockTransaction> transactions)`

在庫取引を一括作成します。

- **パラメータ**:
  - `transactions`: 在庫取引のリスト
- **戻り値**: `Future<List<StockTransaction>>`
- **動作**:
  - BaseRepositoryの`bulkCreate`を呼び出し

##### `findByReference(ReferenceType referenceType, String referenceId, String userId)`

参照タイプ・IDで取引履歴を取得します。

- **パラメータ**:
  - `referenceType`: 参照タイプ（注文、仕入れ、調整）
  - `referenceId`: 参照ID
  - `userId`: ユーザーID
- **戻り値**: `Future<List<StockTransaction>>`
- **動作**:
  - 作成日時で降順ソート

**使用例**:
```dart
// 特定注文による在庫変動を追跡
final transactions = await repository.findByReference(
  ReferenceType.order, 
  orderId, 
  userId
);
```

##### `findByMaterialAndDateRange(String materialId, DateTime dateFrom, DateTime dateTo, String userId)`

材料IDと期間で取引履歴を取得します。

- **パラメータ**:
  - `materialId`: 材料ID
  - `dateFrom`: 開始日
  - `dateTo`: 終了日
  - `userId`: ユーザーID
- **戻り値**: `Future<List<StockTransaction>>`

##### `findConsumptionTransactions(DateTime dateFrom, DateTime dateTo, String userId)`

期間内の消費取引（負の値）を取得します。

- **パラメータ**:
  - `dateFrom`: 開始日
  - `dateTo`: 終了日
  - `userId`: ユーザーID
- **戻り値**: `Future<List<StockTransaction>>`
- **動作**:
  - `change_amount < 0`でフィルタリング
  - 作成日時で降順ソート

## テーブル構造

### purchases

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| purchase_date | DateTime | 仕入れ日 |
| notes | String? | 備考 |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

### purchase_items

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| purchase_id | String | 仕入れID |
| material_id | String | 材料ID |
| quantity | double | 仕入れ量（パッケージ単位） |
| created_at | DateTime? | 作成日時 |

### stock_adjustments

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| material_id | String | 材料ID |
| adjustment_amount | double | 調整量（正負両方） |
| notes | String? | メモ |
| adjusted_at | DateTime | 調整日時 |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

### stock_transactions

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| material_id | String | 材料ID |
| transaction_type | TransactionType | 取引タイプ |
| change_amount | double | 変動量（正=入庫、負=出庫） |
| reference_type | ReferenceType? | 参照タイプ |
| reference_id | String? | 参照ID |
| notes | String? | 備考 |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

## 特記事項

### 在庫取引の設計思想

- **すべての在庫変動を記録**: 仕入れ、販売、調整、廃棄すべてを`stock_transactions`で一元管理
- **参照関係の追跡**: どの注文・仕入れ・調整によって在庫が変動したかを記録
- **監査証跡**: 在庫の変動履歴を完全に追跡可能

### 取引タイプ（TransactionType）

- **purchase**: 仕入れ・購入
- **sale**: 販売
- **adjustment**: 在庫調整
- **waste**: 廃棄

### 参照タイプ（ReferenceType）

- **order**: 注文による変動
- **purchase**: 仕入れによる変動
- **adjustment**: 在庫調整による変動

### 在庫変動量の符号規則

- **正の値**: 入庫（仕入れ、返品、調整増など）
- **負の値**: 出庫（販売、廃棄、調整減など）

### 一括処理の活用

- `createBatch`メソッドで大量データの効率的な登録
- 仕入れ時や注文処理時の複数明細を一括処理

### 期間検索の最適化

- 日付の正規化処理で検索漏れを防止
- インデックス効率を考慮した条件指定

## 使用例

```dart
final purchaseRepo = PurchaseRepository();
final purchaseItemRepo = PurchaseItemRepository();
final adjustmentRepo = StockAdjustmentRepository();
final transactionRepo = StockTransactionRepository();

// 最近の仕入れ取得
final recentPurchases = await purchaseRepo.findRecent(30, userId);

// 特定材料の調整履歴
final adjustments = await adjustmentRepo.findByMaterialId(materialId, userId);

// 注文による在庫変動の追跡
final orderTransactions = await transactionRepo.findByReference(
  ReferenceType.order, 
  orderId, 
  userId
);

// 消費量の分析
final consumptions = await transactionRepo.findConsumptionTransactions(
  lastMonth, 
  today, 
  userId
);
```

## 在庫管理のワークフロー

### 1. 仕入れ時
```dart
// 1. 仕入れ記録作成
final purchase = await purchaseRepo.create(purchaseData);

// 2. 仕入れ明細一括作成
final items = await purchaseItemRepo.createBatch(purchaseItems);

// 3. 在庫取引記録一括作成
final transactions = await transactionRepo.createBatch(stockTransactions);
```

### 2. 販売時
```dart
// 注文処理時に在庫取引記録を作成
final transactions = await transactionRepo.createBatch(saleTransactions);
```

### 3. 在庫調整時
```dart
// 1. 調整記録作成
final adjustment = await adjustmentRepo.create(adjustmentData);

// 2. 在庫取引記録作成
final transaction = await transactionRepo.create(transactionData);
```

## 関連モデル

- `Purchase`: `lib/features/stock/models/stock_model.dart`
- `PurchaseItem`: `lib/features/stock/models/stock_model.dart`
- `StockAdjustment`: `lib/features/stock/models/stock_model.dart`
- `StockTransaction`: `lib/features/stock/models/stock_model.dart`
- `TransactionType`: `lib/core/constants/enums.dart`
- `ReferenceType`: `lib/core/constants/enums.dart`

## 継承関係

```
BaseRepository<Purchase, String>
  ↓
PurchaseRepository

BaseRepository<PurchaseItem, String>
  ↓
PurchaseItemRepository

BaseRepository<StockAdjustment, String>
  ↓
StockAdjustmentRepository

BaseRepository<StockTransaction, String>
  ↓
StockTransactionRepository
```