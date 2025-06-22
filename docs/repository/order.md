# Order Repository

## 概要

`order`フィーチャーのリポジトリクラスは、注文管理機能に関するデータアクセスを担当します。注文と注文明細の管理、複雑な検索・集計機能を提供します。

## リポジトリクラス一覧

### OrderRepository

注文の管理を行うリポジトリです。注文状態管理、期間検索、ページネーション、分析機能を提供します。

**場所**: `lib/features/order/repositories/order_repository.dart`

**基底クラス**: `BaseRepository<Order, String>`

#### 主要メソッド

##### `findActiveDraftByUser(String userId)`

ユーザーのアクティブな下書き注文（カート）を取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<Order?>`
- **動作**:
  - ステータスが`preparing`の注文を検索
  - 作成日時で降順ソートし、最新の1件を取得

##### `findByStatusList(List<OrderStatus> statusList, String userId)`

指定ステータスリストの注文一覧を取得します。

- **パラメータ**:
  - `statusList`: 注文ステータスのリスト
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Order>>`
- **動作**:
  - 注文日時で降順ソート

##### `searchWithPagination(List<QueryFilter> filters, int page, int limit)`

注文を検索し、ページネーション情報と共に返します。

- **パラメータ**:
  - `filters`: 検索条件のリスト
  - `page`: ページ番号（1から開始）
  - `limit`: 1ページあたりの件数
- **戻り値**: `Future<(List<Order>, int)>`
- **動作**:
  - タプルで注文リストと総件数を返却
  - 注文日時で降順ソート

##### `findByDateRange(DateTime dateFrom, DateTime dateTo, String userId)`

期間指定で注文一覧を取得します。

- **パラメータ**:
  - `dateFrom`: 開始日
  - `dateTo`: 終了日
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Order>>`
- **動作**:
  - 日付を日の開始時刻・終了時刻に正規化
  - 注文日時で降順ソート

##### `findCompletedByDate(DateTime targetDate, String userId)`

指定日の完了注文を取得します。

- **パラメータ**:
  - `targetDate`: 対象日
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Order>>`
- **動作**:
  - ステータスが`completed`の注文を対象
  - 完了日時（`completed_at`）で期間フィルタリング

##### `countByStatusAndDate(DateTime targetDate, String userId)`

指定日のステータス別注文数を取得します。

- **パラメータ**:
  - `targetDate`: 対象日
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<OrderStatus, int>>`
- **動作**:
  - 注文日時で期間フィルタリング
  - 各ステータスの注文数をカウント

##### `generateNextOrderNumber(String userId)`

次の注文番号を生成します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<String>`
- **動作**:
  - 形式: `YYYYMMDD-XXX`（XXXは当日の連番）
  - 当日の注文数を取得し、+1した番号を生成

**使用例**:

```dart
// 結果例: "20241222-001"
final orderNumber = await repository.generateNextOrderNumber(userId);
```

##### `findOrdersByCompletionTimeRange(DateTime startTime, DateTime endTime, String userId)`

完了時間範囲で注文を取得します（調理時間分析用）。

- **パラメータ**:
  - `startTime`: 開始時刻
  - `endTime`: 終了時刻
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Order>>`
- **動作**:
  - ステータスが`completed`の注文を対象
  - 完了時間で昇順ソート（分析に適した順序）

---

### OrderItemRepository

注文明細の管理を行うリポジトリです。明細管理、売上集計機能を提供します。

**場所**: `lib/features/order/repositories/order_item_repository.dart`

**基底クラス**: `BaseRepository<OrderItem, String>`

#### 主要メソッド

##### `findByOrderId(String orderId)`

注文IDに紐づく明細一覧を取得します。

- **パラメータ**:
  - `orderId`: 注文ID
- **戻り値**: `Future<List<OrderItem>>`
- **動作**:
  - 作成順でソート

##### `findExistingItem(String orderId, String menuItemId)`

注文内の既存アイテムを取得します（重複チェック用）。

- **パラメータ**:
  - `orderId`: 注文ID
  - `menuItemId`: メニューアイテムID
- **戻り値**: `Future<OrderItem?>`

##### `deleteByOrderId(String orderId)`

注文IDに紐づく明細を全削除します。

- **パラメータ**:
  - `orderId`: 注文ID
- **戻り値**: `Future<bool>`
- **動作**:
  - 一括削除でパフォーマンス向上
  - 削除成功可否をboolで返却

##### `findByMenuItemAndDateRange(String menuItemId, DateTime dateFrom, DateTime dateTo, String userId)`

期間内の特定メニューアイテムの注文明細を取得します。

- **パラメータ**:
  - `menuItemId`: メニューアイテムID
  - `dateFrom`: 開始日
  - `dateTo`: 終了日
  - `userId`: ユーザーID
- **戻り値**: `Future<List<OrderItem>>`

##### `getMenuItemSalesSummary(int days, String userId)`

メニューアイテム別売上集計を取得します。

- **パラメータ**:
  - `days`: 過去N日間
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Map<String, dynamic>>>`
- **動作**:
  - 過去N日間の注文明細を集計
  - メニューアイテム別に数量と売上金額を計算
  - 売上金額の降順でソート

**戻り値の形式**:

```dart
[
  {
    "menu_item_id": "menu_123",
    "total_quantity": 15,
    "total_amount": 7500
  },
  // ...
]
```

## テーブル構造

### orders

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| total_amount | int | 合計金額（円） |
| status | OrderStatus | 注文ステータス |
| payment_method | PaymentMethod | 支払い方法 |
| discount_amount | int | 割引額（円） |
| customer_name | String? | 顧客名（呼び出し用） |
| notes | String? | 備考 |
| ordered_at | DateTime | 注文日時 |
| started_preparing_at | DateTime? | 調理開始日時 |
| ready_at | DateTime? | 完成日時 |
| completed_at | DateTime? | 提供完了日時 |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

### order_items

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| order_id | String | 注文ID |
| menu_item_id | String | メニューアイテムID |
| quantity | int | 数量 |
| unit_price | int | 単価（注文時点の価格） |
| subtotal | int | 小計（円） |
| selected_options | Map<String, String>? | 選択されたオプション |
| special_request | String? | 特別リクエスト |
| created_at | DateTime? | 作成日時 |

## 特記事項

### 注文ステータス管理

- **preparing**: 準備中（調理中、未対応含む）
- **completed**: 完了（提供済み）
- **canceled**: キャンセル済み

### 日時管理の複雑性

- **ordered_at**: 注文受付日時
- **started_preparing_at**: 調理開始日時
- **ready_at**: 完成日時
- **completed_at**: 提供完了日時

各段階での分析が可能な詳細な時刻管理

### 注文番号生成

- 形式: `YYYYMMDD-XXX`
- 日付ベースで連番管理
- 人間が読みやすい形式

### ページネーション

- `searchWithPagination`でタプルを使用した効率的な実装
- 総件数と結果を同時に取得

### 集計・分析機能

- 日別、期間別、メニュー別の多角的な分析に対応
- パフォーマンスを考慮した集計処理

## 使用例

```dart
final orderRepo = OrderRepository();
final itemRepo = OrderItemRepository();

// アクティブなカート取得
final cart = await orderRepo.findActiveDraftByUser(userId);

// 完了注文の取得
final completedOrders = await orderRepo.findByStatusList(
  [OrderStatus.completed], 
  userId
);

// ページネーション検索
final (orders, totalCount) = await orderRepo.searchWithPagination(
  filters, 
  page: 1, 
  limit: 20
);

// 売上集計
final salesSummary = await itemRepo.getMenuItemSalesSummary(30, userId);
```

## 関連モデル

- `Order`: `lib/features/order/models/order_model.dart`
- `OrderItem`: `lib/features/order/models/order_model.dart`
- `OrderStatus`: `lib/core/constants/enums.dart`
- `PaymentMethod`: `lib/core/constants/enums.dart`

## 継承関係

```
BaseRepository<Order, String>
  ↓
OrderRepository

BaseRepository<OrderItem, String>
  ↓
OrderItemRepository
```
