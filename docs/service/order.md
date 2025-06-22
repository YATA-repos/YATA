# Order Service

## 概要

`order`フィーチャーのサービスクラス群は、注文管理機能に関するビジネスロジックを担当します。カート管理、キッチン管理、注文処理の3つの専門サービスで構成され、注文ライフサイクル全体をカバーします。

## サービスクラス一覧

### CartService

カート（下書き注文）管理を行うサービスです。

**場所**: `lib/features/order/services/cart_service.dart`

**責任範囲**: カート商品の追加・削除・更新、在庫検証、金額計算

**依存リポジトリ**:

- `OrderRepository`
- `OrderItemRepository`
- `MenuItemRepository`
- `MaterialRepository`
- `RecipeRepository`

#### 主要メソッド

##### `getOrCreateActiveCart(String userId)`

アクティブなカート（下書き注文）を取得または作成します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<Order?>`
- **動作**:
  - 既存のアクティブカートを検索
  - 存在しない場合は新しいカートを作成
  - preparing状態で初期化

##### `addItemToCart(String cartId, CartItemRequest request, String userId)`

カートに商品を追加します（戻り値: (OrderItem, 在庫充足フラグ)）。

- **パラメータ**:
  - `cartId`: カートID
  - `request`: カート商品追加要求
  - `userId`: ユーザーID
- **戻り値**: `Future<(OrderItem?, bool)>`
- **動作**:
  - カートとメニューアイテムの存在確認
  - 在庫充足性をチェック
  - 既存アイテムがある場合は数量を加算
  - 新規アイテムの場合は新規作成
  - カート合計金額を自動更新

**在庫チェックロジック**:

```dart
final bool isStockSufficient = await _checkMenuItemStock(
  request.menuItemId,
  request.quantity,
  userId,
);
```

##### `updateCartItemQuantity(String cartId, String orderItemId, int newQuantity, String userId)`

カート内商品の数量を更新します。

- **パラメータ**:
  - `cartId`: カートID
  - `orderItemId`: 注文アイテムID
  - `newQuantity`: 新しい数量
  - `userId`: ユーザーID
- **戻り値**: `Future<(OrderItem?, bool)>`
- **動作**:
  - 数量の妥当性チェック（> 0）
  - 在庫充足性の再確認
  - 小計の再計算
  - カート合計金額の更新

##### `calculateCartTotal(String cartId, {int discountAmount = 0})`

カートの金額を計算します。

- **パラメータ**:
  - `cartId`: カートID
  - `discountAmount`: 割引額（デフォルト: 0）
- **戻り値**: `Future<OrderCalculationResult>`
- **動作**:
  - カート内アイテムの小計を集計
  - 税額を計算（8%と仮定）
  - 割引を適用して合計金額を算出

**計算式**:

```
小計 = Σ(各アイテムの小計)
税額 = 小計 × 0.08
合計 = 小計 + 税額 - 割引額
```

##### `validateCartStock(String cartId, String userId)`

カート内全商品の在庫を検証します（戻り値: {order_item_id: 在庫充足フラグ}）。

- **パラメータ**:
  - `cartId`: カートID
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, bool>>`
- **動作**: 各カートアイテムの在庫充足性を個別チェック

---

### KitchenService

調理・キッチン管理を行うサービスです。

**場所**: `lib/features/order/services/kitchen_service.dart`

**責任範囲**: 調理進行管理、時間管理、キッチン負荷計算

**依存リポジトリ**:

- `OrderRepository`
- `OrderItemRepository`
- `MenuItemRepository`

#### 主要メソッド

##### `getActiveOrdersByStatus(String userId)`

ステータス別進行中注文を取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<OrderStatus, List<Order>>>`
- **動作**: preparing状態の注文をステータス別に分類

##### `getOrderQueue(String userId)`

注文キューを取得（調理順序順）します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Order>>`
- **動作**:
  - 調理未開始の注文を注文時刻順にソート
  - 調理中の注文を開始時刻順にソート
  - 未開始 → 調理中の順序で返却

##### `startOrderPreparation(String orderId, String userId)`

注文の調理を開始します。

- **パラメータ**:
  - `orderId`: 注文ID
  - `userId`: ユーザーID
- **戻り値**: `Future<Order?>`
- **動作**:
  - 注文状態の妥当性チェック
  - `started_preparing_at`に現在時刻を記録

##### `completeOrderPreparation(String orderId, String userId)`

注文の調理を完了します。

- **パラメータ**:
  - `orderId`: 注文ID
  - `userId`: ユーザーID
- **戻り値**: `Future<Order?>`
- **動作**:
  - 調理開始済みかチェック
  - `ready_at`に現在時刻を記録

##### `deliverOrder(String orderId, String userId)`

注文を提供完了します。

- **パラメータ**:
  - `orderId`: 注文ID
  - `userId`: ユーザーID
- **戻り値**: `Future<Order?>`
- **動作**:
  - 調理完了済みかチェック
  - ステータスをcompletedに変更
  - `completed_at`に現在時刻を記録

##### `calculateEstimatedCompletionTime(String orderId, String userId)`

完成予定時刻を計算します。

- **パラメータ**:
  - `orderId`: 注文ID
  - `userId`: ユーザーID
- **戻り値**: `Future<DateTime?>`
- **動作**:
  - 注文アイテムの調理時間を集計
  - キューでの待ち時間を考慮
  - 基準時刻（調理開始時刻または注文時刻）から推定時刻を算出

##### `getKitchenWorkload(String userId)`

キッチンの負荷状況を取得します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, dynamic>>`
- **動作**:
  - 進行中注文を段階別に集計
  - 推定総調理時間を計算
  - 平均待ち時間を算出

**戻り値構造**:

```dart
{
  "total_active_orders": int,
  "not_started_count": int,
  "in_progress_count": int,
  "ready_count": int,
  "estimated_total_minutes": int,
  "average_wait_time_minutes": int,
}
```

##### `optimizeCookingOrder(String userId)`

調理順序を最適化（注文IDリストを返す）します。

- **パラメータ**:
  - `userId`: ユーザーID
- **戻り値**: `Future<List<String>>`
- **動作**:
  - 調理未開始の注文を分析
  - 調理時間の短い順、同時間なら注文の早い順でソート
  - 最適化された注文IDリストを返却

##### `getKitchenPerformanceMetrics(DateTime targetDate, String userId)`

キッチンパフォーマンス指標を取得します。

- **パラメータ**:
  - `targetDate`: 対象日
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, dynamic>>`
- **動作**:
  - 指定日の完了注文を分析
  - 調理時間統計、売上、効率指標を算出

---

### OrderService

注文処理を行うサービスです。

**場所**: `lib/features/order/services/order_service.dart`

**責任範囲**: 注文確定、キャンセル処理、履歴管理

**依存リポジトリ**:

- `OrderRepository`
- `OrderItemRepository`
- `MenuItemRepository`
- `MaterialRepository`
- `RecipeRepository`

#### 主要メソッド

##### `checkoutCart(String cartId, OrderCheckoutRequest request, String userId)`

カートを確定して正式注文に変換します（戻り値: (Order, 成功フラグ)）。

- **パラメータ**:
  - `cartId`: カートID
  - `request`: 注文確定要求
  - `userId`: ユーザーID
- **戻り値**: `Future<(Order?, bool)>`
- **動作**:
  - カートの妥当性チェック
  - カート内全アイテムの在庫確認
  - 在庫充足時に材料消費を実行
  - 注文情報を更新（支払い方法、顧客名等）
  - 最終金額を計算・更新

**複合トランザクション**:

```
在庫確認 → 材料消費 → 注文確定 → 金額計算・更新
```

##### `cancelOrder(String orderId, String reason, String userId)`

注文をキャンセル（在庫復元含む）します。

- **パラメータ**:
  - `orderId`: 注文ID
  - `reason`: キャンセル理由
  - `userId`: ユーザーID
- **戻り値**: `Future<(Order?, bool)>`
- **動作**:
  - 注文状態の妥当性チェック
  - 調理開始前の場合は材料在庫を復元
  - 注文ステータスをcanceledに変更
  - キャンセル理由をnotesに記録

##### `getOrderHistory(OrderSearchRequest request, String userId)`

注文履歴を取得（ページネーション付き）します。

- **パラメータ**:
  - `request`: 検索要求（日付範囲、メニューアイテム名等）
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, dynamic>>`
- **動作**:
  - 基本的な注文データを取得（過去1年間）
  - 日付フィルタリング
  - メニューアイテム名での検索
  - ページネーション情報を含む結果を返却

##### `getOrderWithItems(String orderId, String userId)`

注文と注文明細を一括取得します。

- **パラメータ**:
  - `orderId`: 注文ID
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, dynamic>?>`
- **動作**:
  - 注文詳細を取得
  - 関連する注文明細を取得
  - メニューアイテム情報も含めて統合

**戻り値構造**:

```dart
{
  "order": Order,
  "items": [
    {
      "order_item": OrderItem,
      "menu_item": MenuItem,
    },
    // ...
  ],
  "total_items": int,
}
```

## ビジネスロジック詳細

### 注文ライフサイクル

```
カート作成 → 商品追加 → 在庫確認 → 注文確定 → 調理開始 → 調理完了 → 提供完了
    ↑                                          ↓
   CartService                               KitchenService
                     ↑          ↓
                   OrderService
```

### 在庫管理との連携

- **注文確定時**: 材料在庫の即座な減算
- **注文キャンセル時**: 材料在庫の復元（調理開始前のみ）
- **リアルタイム在庫確認**: カート操作時の常時チェック

### 調理時間管理

- **予測アルゴリズム**: メニューアイテムの推定調理時間から算出
- **キュー管理**: 注文順序と調理効率の最適化
- **実績追跡**: 実際の調理時間の記録と分析

## パフォーマンス最適化

### 在庫チェックの効率化

```dart
// 材料レベルでの在庫確認
Future<bool> _checkMenuItemStock(String menuItemId, int quantity, String userId) async {
  final recipes = await _recipeRepository.findByMenuItemId(menuItemId, userId);
  
  for (final recipe in recipes) {
    if (!recipe.isOptional) {
      final requiredAmount = recipe.requiredAmount * quantity;
      final material = await _materialRepository.getById(recipe.materialId);
      
      if (material?.currentStock < requiredAmount) {
        return false;
      }
    }
  }
  
  return true;
}
```

### 一括処理の活用

- **カート検証**: 全アイテムの並列在庫チェック
- **材料消費**: 一括での在庫更新
- **取引記録**: StockTransactionの一括作成

## エラーハンドリング

### アクセス制御

```dart
if (cart == null || cart.userId != userId) {
  throw Exception("Cart $cartId not found or access denied");
}
```

### ビジネスルール検証

```dart
if (order.status == OrderStatus.completed) {
  throw Exception("Cannot cancel completed order");
}

if (newQuantity <= 0) {
  throw Exception("Quantity must be greater than 0");
}
```

### トランザクション失敗対応

```dart
try {
  // 複雑な処理（材料消費等）
  return (updatedOrder, true);
} catch (e) {
  return (order, false);  // 失敗時の安全な戻り値
}
```

## データ構造

### CartItemRequest

```dart
class CartItemRequest {
  final String menuItemId;
  final int quantity;
  final Map<String, dynamic>? selectedOptions;
  final String? specialRequest;
}
```

### OrderCheckoutRequest

```dart
class OrderCheckoutRequest {
  final PaymentMethod paymentMethod;
  final String? customerName;
  final int discountAmount;
  final String? notes;
}
```

### OrderCalculationResult

```dart
class OrderCalculationResult {
  final int subtotal;
  final int taxAmount;
  final int discountAmount;
  final int totalAmount;
}
```

### OrderSearchRequest

```dart
class OrderSearchRequest {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? menuItemName;
  final int page;
  final int limit;
}
```

## 関連モデル・DTO

- `Order`: `lib/features/order/models/order_model.dart`
- `OrderItem`: `lib/features/order/models/order_model.dart`
- `CartItemRequest`: `lib/features/order/dto/order_dto.dart`
- `OrderCheckoutRequest`: `lib/features/order/dto/order_dto.dart`
- `OrderCalculationResult`: `lib/features/order/dto/order_dto.dart`
- `OrderSearchRequest`: `lib/features/order/dto/order_dto.dart`

## 使用例

### カート操作フロー

```dart
final cartService = CartService();

// アクティブカート取得
final cart = await cartService.getOrCreateActiveCart(userId);

// 商品追加
final addRequest = CartItemRequest(
  menuItemId: 'menu123',
  quantity: 2,
  selectedOptions: {'size': 'large'},
  specialRequest: 'Extra spicy',
);

final (orderItem, isStockSufficient) = await cartService.addItemToCart(
  cart.id!, 
  addRequest, 
  userId
);

if (!isStockSufficient) {
  showStockWarning();
}

// 金額計算
final calculation = await cartService.calculateCartTotal(cart.id!);
displayTotal(calculation.totalAmount);
```

### 注文確定フロー

```dart
final orderService = OrderService();

// 注文確定
final checkoutRequest = OrderCheckoutRequest(
  paymentMethod: PaymentMethod.cash,
  customerName: 'John Doe',
  discountAmount: 0,
  notes: 'Table 5',
);

final (order, success) = await orderService.checkoutCart(
  cartId, 
  checkoutRequest, 
  userId
);

if (success) {
  showOrderConfirmation(order);
} else {
  showStockError();
}
```

### キッチン管理フロー

```dart
final kitchenService = KitchenService();

// 注文キュー取得
final queue = await kitchenService.getOrderQueue(userId);

// 調理開始
await kitchenService.startOrderPreparation(queue.first.id!, userId);

// 負荷状況確認
final workload = await kitchenService.getKitchenWorkload(userId);
displayKitchenStatus(workload);

// 調理完了
await kitchenService.completeOrderPreparation(orderId, userId);

// 提供完了
await kitchenService.deliverOrder(orderId, userId);
```

### 注文管理フロー

```dart
final orderService = OrderService();

// 注文履歴検索
final searchRequest = OrderSearchRequest(
  dateFrom: DateTime.now().subtract(Duration(days: 7)),
  dateTo: DateTime.now(),
  page: 1,
  limit: 20,
);

final history = await orderService.getOrderHistory(searchRequest, userId);
final orders = history['orders'] as List<Order>;

// 注文詳細取得
final orderDetails = await orderService.getOrderWithItems(orderId, userId);

// 注文キャンセル
final (canceledOrder, success) = await orderService.cancelOrder(
  orderId, 
  'Customer requested cancellation', 
  userId
);
```

## 継承関係

```
CartService（独立クラス）
│
├─依存→ OrderRepository
├─依存→ OrderItemRepository
├─依存→ MenuItemRepository
├─依存→ MaterialRepository
└─依存→ RecipeRepository

KitchenService（独立クラス）
│
├─依存→ OrderRepository
├─依存→ OrderItemRepository
└─依存→ MenuItemRepository

OrderService（独立クラス）
│
├─依存→ OrderRepository
├─依存→ OrderItemRepository
├─依存→ MenuItemRepository
├─依存→ MaterialRepository
└─依存→ RecipeRepository
```
