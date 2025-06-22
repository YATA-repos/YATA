# BaseRepository詳細ドキュメント

## 概要

BaseRepositoryは、YATAアプリケーション全体のデータアクセス層の基盤となる抽象ジェネリッククラスです。型安全性を完全に確保しながら、高度なCRUD操作、複雑な検索・フィルタリング、効率的なバルク処理を提供します。

### 設計思想

- **完全な型安全性**: Dart/Flutterの静的型システムを最大限活用したジェネリクス設計
- **複合主キー対応**: 単一・複合主キーの両方に対応する柔軟な設計
- **高度なクエリ機能**: QueryUtilsとの統合による31種類の演算子対応
- **包括的エラーハンドリング**: 統一されたエラーシステムとログ記録
- **パフォーマンス最適化**: バルク操作とチャンク処理による効率性

## アーキテクチャ概要

### クラス定義

```dart
abstract class BaseRepository<T extends BaseModel, ID> {
  /// テーブル名
  final String tableName;
  
  /// 主キーカラム名のリスト（複合主キー対応）
  final List<String> primaryKeyColumns;
  
  /// JSONからモデルインスタンスを作成するファクトリ関数
  T Function(Map<String, dynamic> json) get fromJson;
}
```

### 型パラメータ

| パラメータ | 説明 | 制約 | 使用例 |
|-----------|------|------|-------|
| `T` | モデル型 | `extends BaseModel` | `Order`, `Material`, `MenuItem` |
| `ID` | 主キー型 | なし | `String`, `int`, `PrimaryKeyMap` |

### 主キーシステム

```dart
/// 主キーマップ型定義
typedef PrimaryKeyMap = Map<String, dynamic>;

// 単一主キーの例
final String orderId = "order_123";

// 複合主キーの例
final PrimaryKeyMap compositeKey = {
  "order_id": "order_123",
  "item_id": "item_456"
};
```

## 型システムと安全性

### ジェネリクス型の活用

BaseRepositoryは完全な型安全性を提供します：

```dart
// 具象実装例
class OrderRepository extends BaseRepository<Order, String> {
  OrderRepository() : super(
    tableName: "orders",
    primaryKeyColumns: ["id"],
  );

  @override
  Order Function(Map<String, dynamic> json) get fromJson => Order.fromJson;
}

// 使用例
final OrderRepository repository = OrderRepository();
final Order? order = await repository.getById("order_123"); // 型安全
final List<Order> orders = await repository.list(); // Order型のリストを保証
```

### 複合主キー対応

```dart
class OrderItemRepository extends BaseRepository<OrderItem, PrimaryKeyMap> {
  OrderItemRepository() : super(
    tableName: "order_items",
    primaryKeyColumns: ["order_id", "item_id"],
  );

  @override
  OrderItem Function(Map<String, dynamic> json) get fromJson => OrderItem.fromJson;
}

// 複合主キーでの使用
final OrderItemRepository repository = OrderItemRepository();
final PrimaryKeyMap key = {"order_id": "order_123", "item_id": "item_456"};
final OrderItem? item = await repository.getByPrimaryKey(key);
```

## 主要機能

### 1. CRUD操作

#### Create（作成）

```dart
/// 単一エンティティ作成
Future<T?> create(T entity);

/// 複数エンティティ一括作成
Future<List<T>> bulkCreate(List<T> entities);
```

**使用例**:

```dart
// 単一作成
final Order order = Order(
  id: "order_123",
  userId: "user_456",
  status: OrderStatus.preparing,
  totalAmount: Decimal.parse("1500.00"),
);
final Order? createdOrder = await repository.create(order);

// 一括作成
final List<Order> orders = [order1, order2, order3];
final List<Order> createdOrders = await repository.bulkCreate(orders);
```

#### Read（読取）

```dart
/// IDによる単一取得
Future<T?> getById(ID id);

/// 主キーマップによる取得
Future<T?> getByPrimaryKey(PrimaryKeyMap keyMap);

/// 条件による単一取得
Future<T?> findOne({List<QueryFilter>? filters});

/// リスト取得（ページネーション対応）
Future<List<T>> list({int limit = 100, int offset = 0});

/// 高度な検索・フィルタリング
Future<List<T>> find({
  List<QueryFilter>? filters,
  List<OrderByCondition>? orderBy,
  int limit = 100,
  int offset = 0,
});
```

**使用例**:

```dart
// ID取得
final Order? order = await repository.getById("order_123");

// 条件検索
final List<Order> activeOrders = await repository.find(
  filters: [
    QueryConditionBuilder.eq("status", "preparing"),
    QueryConditionBuilder.gte("created_at", "2024-01-01"),
  ],
  orderBy: [QueryConditionBuilder.desc("created_at")],
  limit: 50,
);

// 複雑な条件
final AndCondition complexFilter = QueryConditionBuilder.and([
  QueryConditionBuilder.eq("user_id", userId),
  QueryConditionBuilder.inList("status", ["preparing", "completed"]),
  QueryConditionBuilder.gte("total_amount", 1000),
]);
final List<Order> userOrders = await repository.find(filters: [complexFilter]);
```

#### Update（更新）

```dart
/// IDによる更新
Future<T?> updateById(ID id, Map<String, dynamic> updates);

/// 主キーマップによる更新
Future<T?> updateByPrimaryKey(PrimaryKeyMap keyMap, Map<String, dynamic> updates);
```

**使用例**:

```dart
// ステータス更新
final Order? updatedOrder = await repository.updateById(
  "order_123",
  {"status": "completed", "completed_at": DateTime.now().toIso8601String()},
);

// 複合主キーでの更新
final OrderItem? updatedItem = await orderItemRepository.updateByPrimaryKey(
  {"order_id": "order_123", "item_id": "item_456"},
  {"quantity": 3, "updated_at": DateTime.now().toIso8601String()},
);
```

#### Delete（削除）

```dart
/// IDによる削除
Future<void> deleteById(ID id);

/// 主キーマップによる削除
Future<void> deleteByPrimaryKey(PrimaryKeyMap keyMap);

/// 複数エンティティ一括削除
Future<void> bulkDelete(List<ID> keys);
```

**使用例**:

```dart
// 単一削除
await repository.deleteById("order_123");

// 一括削除（効率的な実装）
final List<String> orderIds = ["order_1", "order_2", "order_3"];
await repository.bulkDelete(orderIds);
```

### 2. 存在確認・カウント機能

```dart
/// IDによる存在確認
Future<bool> existsById(ID id);

/// 主キーマップによる存在確認
Future<bool> existsByPrimaryKey(PrimaryKeyMap keyMap);

/// 条件に一致するエンティティ数を取得
Future<int> count({List<QueryFilter>? filters});
```

**使用例**:

```dart
// 存在確認
final bool orderExists = await repository.existsById("order_123");

// 条件付きカウント
final int activeOrderCount = await repository.count(
  filters: [QueryConditionBuilder.eq("status", "active")],
);

// 全件カウント
final int totalOrders = await repository.count();
```

## 基本的な使用方法

### 1. 具象リポジトリの実装

```dart
// Step 1: モデルクラスの定義（BaseModelを継承）
@JsonSerializable()
class Order extends BaseModel {
  final String userId;
  final OrderStatus status;
  final Decimal totalAmount;
  final DateTime? completedAt;

  const Order({
    required super.id,
    required super.userId,
    required this.status,
    required this.totalAmount,
    this.completedAt,
    super.createdAt,
    super.updatedAt,
  });

  @override
  String get tableName => "orders";

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

// Step 2: リポジトリクラスの実装
class OrderRepository extends BaseRepository<Order, String> {
  OrderRepository() : super(
    tableName: "orders",
    primaryKeyColumns: ["id"],
  );

  @override
  Order Function(Map<String, dynamic> json) get fromJson => Order.fromJson;

  // ビジネス固有のメソッドを追加可能
  Future<List<Order>> findByUserId(String userId) async {
    return find(
      filters: [QueryConditionBuilder.eq("user_id", userId)],
      orderBy: [QueryConditionBuilder.desc("created_at")],
    );
  }

  Future<List<Order>> findActiveOrders() async {
    return find(
      filters: [
        QueryConditionBuilder.inList("status", ["preparing", "in_progress"]),
      ],
    );
  }
}
```

### 2. 依存性注入とサービス統合

```dart
// サービス層での使用例
class OrderService {
  final OrderRepository _repository;

  OrderService(this._repository);

  Future<Order> createOrder({
    required String userId,
    required List<OrderItem> items,
  }) async {
    try {
      final Order order = Order(
        id: const Uuid().v4(),
        userId: userId,
        status: OrderStatus.preparing,
        totalAmount: _calculateTotal(items),
      );

      final Order? createdOrder = await _repository.create(order);
      if (createdOrder == null) {
        throw OrderException(OrderError.createFailed);
      }

      return createdOrder;
    } catch (e) {
      LogService.error("OrderService", "Failed to create order", null, e);
      rethrow;
    }
  }

  Future<List<Order>> getUserOrders(String userId) async {
    return _repository.findByUserId(userId);
  }

  Future<void> completeOrder(String orderId) async {
    await _repository.updateById(orderId, {
      "status": OrderStatus.completed.name,
      "completed_at": DateTime.now().toIso8601String(),
    });
  }
}
```

## 高度な機能

### 1. 複雑なクエリ構築

QueryUtilsとの統合により、高度な検索条件を構築できます：

```dart
// 複雑な AND/OR 条件
final ComplexCondition complexQuery = QueryConditionBuilder.complex(
  andConditions: [
    QueryConditionBuilder.gte("created_at", "2024-01-01"),
    QueryConditionBuilder.lt("created_at", "2024-12-31"),
  ],
  orConditions: [
    QueryConditionBuilder.eq("status", "completed"),
    QueryConditionBuilder.and([
      QueryConditionBuilder.eq("status", "preparing"),
      QueryConditionBuilder.gte("total_amount", 1000),
    ]),
  ],
);

final List<Order> orders = await repository.find(
  filters: [complexQuery],
  orderBy: [
    QueryConditionBuilder.desc("total_amount"),
    QueryConditionBuilder.asc("created_at"),
  ],
  limit: 100,
);
```

### 2. 効率的なバルク操作

```dart
// 大量データの効率的な処理
class BulkOrderProcessor {
  final OrderRepository _repository;

  BulkOrderProcessor(this._repository);

  Future<void> processBulkOrders(List<Order> orders) async {
    // チャンク処理による効率的な一括作成
    const int chunkSize = 100;
    for (int i = 0; i < orders.length; i += chunkSize) {
      final int end = math.min(i + chunkSize, orders.length);
      final List<Order> chunk = orders.sublist(i, end);
      
      await _repository.bulkCreate(chunk);
      LogService.info("BulkProcessor", "Processed ${chunk.length} orders");
    }
  }

  Future<void> cleanupOldOrders() async {
    // 古い注文の一括削除
    final List<Order> oldOrders = await _repository.find(
      filters: [
        QueryConditionBuilder.lt("created_at", 
          DateTime.now().subtract(const Duration(days: 365)).toIso8601String()),
      ],
    );

    final List<String> orderIds = oldOrders.map((o) => o.id).toList();
    await _repository.bulkDelete(orderIds);
  }
}
```

### 3. トランザクション処理

```dart
// Supabaseトランザクション統合
class TransactionalOrderService {
  final SupabaseClient _client;
  final OrderRepository _orderRepository;
  final OrderItemRepository _itemRepository;

  TransactionalOrderService(this._client, this._orderRepository, this._itemRepository);

  Future<Order> createOrderWithItems(String userId, List<OrderItemData> items) async {
    return _client.rpc('create_order_transaction', params: {
      'user_id': userId,
      'items': items.map((i) => i.toJson()).toList(),
    }).then((response) {
      return Order.fromJson(response as Map<String, dynamic>);
    });
  }
}
```

## エラーハンドリング

### 統一されたエラーシステム

BaseRepositoryは包括的なエラーハンドリングを提供します：

```dart
// エラー種別（repository.dart で定義）
enum RepositoryError {
  databaseConnectionFailed,  // データベース接続失敗
  recordNotFound,           // レコードが見つからない
  insertFailed,             // データ挿入失敗
  updateFailed,             // データ更新失敗
  deleteFailed,             // データ削除失敗
  validationFailed,         // データ検証失敗
  concurrencyConflict,      // データ競合状態
  invalidQueryParameters,   // 無効なクエリパラメータ
  transactionFailed,        // トランザクション失敗
}

// エラーハンドリング例
try {
  final Order? order = await repository.getById("invalid_id");
} on RepositoryException catch (e) {
  switch (e.error) {
    case RepositoryError.recordNotFound:
      LogService.warning("UI", "Order not found: ${e.params['id']}");
      showNotFoundDialog();
      break;
    case RepositoryError.databaseConnectionFailed:
      LogService.error("Repository", "Database connection failed", null, e);
      showConnectionErrorDialog();
      break;
    default:
      LogService.error("Repository", "Unexpected error", null, e);
      showGenericErrorDialog();
  }
}
```

### ログ記録の統合

すべての操作は詳細なログ記録を行います：

```dart
// 自動的に記録されるログの例
LogService.debug("BaseRepository", "Creating entity in table: orders");
LogService.info("BaseRepository", "Entity created successfully in table: orders");
LogService.error("BaseRepository", "Failed to create entity in table: orders", null, error);
```

## パフォーマンス特性

### メモリ効率

- **最小限のメモリ使用**: 必要な時のみインスタンス化
- **効率的な型キャスト**: 不要なオブジェクト生成を回避
- **Lazy Loading**: フィルタ・ソート条件の遅延評価

### ネットワーク効率

- **バルク操作**: 複数レコードの一括処理
- **チャンク処理**: 大量データの分割処理
- **クエリ最適化**: 不要なフィールド取得の回避

### 実行時性能

```dart
// パフォーマンス測定例
final Stopwatch stopwatch = Stopwatch()..start();

// 1000件の一括作成
final List<Order> orders = List.generate(1000, (i) => createSampleOrder(i));
await repository.bulkCreate(orders);

stopwatch.stop();
LogService.info("Performance", "Bulk create took ${stopwatch.elapsedMilliseconds}ms");

// 効率的な検索
final List<Order> results = await repository.find(
  filters: [QueryConditionBuilder.eq("status", "active")],
  limit: 10, // 必要な分だけ取得
);
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. 型キャストエラー

**症状**: `type 'String' is not a subtype of type 'int'`

**原因**: JSONデシリアライゼーション時の型不一致

**解決方法**:

```dart
// ❌ 間違った実装
class Order extends BaseModel {
  final int amount; // JSONでは文字列として格納

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    amount: json['amount'], // 型キャストエラー
  );
}

// ✅ 正しい実装
class Order extends BaseModel {
  final int amount;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    amount: int.parse(json['amount'].toString()),
  );
}
```

#### 2. 複合主キーエラー

**症状**: `ArgumentError: 複合主キーにはMap<String, dynamic>形式でキーを指定してください`

**解決方法**:

```dart
// ❌ 間違った使用法
await repository.deleteById("simple_key"); // 複合主キーテーブルで単一キー使用

// ✅ 正しい使用法
await repository.deleteByPrimaryKey({
  "order_id": "order_123",
  "item_id": "item_456",
});
```

#### 3. パフォーマンス問題

**症状**: 大量データ処理が遅い

**解決方法**:

```dart
// ❌ 非効率な実装
for (final String orderId in orderIds) {
  await repository.deleteById(orderId); // 1件ずつ削除
}

// ✅ 効率的な実装
await repository.bulkDelete(orderIds); // 一括削除
```

#### 4. メモリリーク

**症状**: 長時間使用でメモリ使用量が増加

**解決方法**:

```dart
// 定期的なリソースクリーンアップ
class RepositoryManager {
  static final Map<Type, BaseRepository> _cache = {};

  static T getRepository<T extends BaseRepository>() {
    return _cache.putIfAbsent(T, () => _createRepository<T>()) as T;
  }

  static void clearCache() {
    _cache.clear(); // 定期的にキャッシュクリア
  }
}
```

## ベストプラクティス

### 1. 適切な継承の実装

```dart
// ✅ 良い例：適切な型安全性
class OrderRepository extends BaseRepository<Order, String> {
  OrderRepository() : super(
    tableName: "orders",
    primaryKeyColumns: ["id"],
  );

  @override
  Order Function(Map<String, dynamic> json) get fromJson => Order.fromJson;

  // ビジネス固有のメソッド
  Future<List<Order>> findByStatus(OrderStatus status) async {
    return find(filters: [QueryConditionBuilder.eq("status", status.name)]);
  }
}

// ❌ 悪い例：型安全性の欠如
class BadRepository extends BaseRepository<dynamic, dynamic> {
  // 型安全性が失われる
}
```

### 2. エラーハンドリングの統一

```dart
// ✅ 良い例：包括的エラーハンドリング
Future<Order?> safeGetOrder(String orderId) async {
  try {
    return await repository.getById(orderId);
  } on RepositoryException catch (e) {
    LogService.error("OrderService", "Failed to get order", null, e);
    return null;
  } catch (e) {
    LogService.error("OrderService", "Unexpected error", null, e);
    rethrow;
  }
}

// ❌ 悪い例：エラーの無視
Future<Order?> unsafeGetOrder(String orderId) async {
  try {
    return await repository.getById(orderId);
  } catch (e) {
    return null; // エラー情報が失われる
  }
}
```

### 3. 効率的なクエリ構築

```dart
// ✅ 良い例：効率的な検索
Future<List<Order>> findRecentActiveOrders() async {
  return repository.find(
    filters: [
      QueryConditionBuilder.and([
        QueryConditionBuilder.eq("status", "active"),
        QueryConditionBuilder.gte("created_at", 
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String()),
      ]),
    ],
    orderBy: [QueryConditionBuilder.desc("created_at")],
    limit: 50, // 必要な分だけ取得
  );
}

// ❌ 悪い例：非効率な検索
Future<List<Order>> findRecentActiveOrdersBad() async {
  final List<Order> allOrders = await repository.list(limit: 10000); // 全件取得
  return allOrders
      .where((o) => o.status == OrderStatus.active)
      .where((o) => o.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30))))
      .take(50)
      .toList();
}
```

### 4. リソース管理

```dart
// ✅ 良い例：適切なリソース管理
class OrderService implements Disposable {
  final OrderRepository _repository;
  Timer? _cleanupTimer;

  OrderService(this._repository) {
    // 定期的なクリーンアップ
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _performCleanup();
    });
  }

  Future<void> _performCleanup() async {
    await LogService.cleanupOldLogs();
    // その他のクリーンアップ処理
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
  }
}
```

## 内部実装詳細

### 主キー正規化システム

```dart
/// 単一キーを主キーマップに正規化
PrimaryKeyMap _normalizeKey(Object? key) {
  if (key is Map<String, dynamic>) {
    return key;
  }

  // 単一値の場合、主キーカラムが1つであることを確認
  if (primaryKeyColumns.length != 1) {
    throw ArgumentError("複合主キーにはMap<String, dynamic>形式でキーを指定してください");
  }

  return <String, dynamic>{primaryKeyColumns[0]: key};
}
```

### クエリ構築システム

```dart
/// クエリに主キー条件を適用
PostgrestFilterBuilder<TQuery> _applyPrimaryKey<TQuery>(
  PostgrestFilterBuilder<TQuery> query,
  PrimaryKeyMap keyMap,
) {
  PostgrestFilterBuilder<TQuery> result = query;

  for (final String column in primaryKeyColumns) {
    if (!keyMap.containsKey(column)) {
      throw ArgumentError("主キーカラム '$column' がキーマップに見つかりません");
    }
    result = result.eq(column, keyMap[column] as Object);
  }

  return result;
}
```

### バルク削除の最適化

```dart
Future<void> bulkDelete(List<ID> keys) async {
  if (keys.isEmpty) return;

  try {
    // 単一カラム主キーの場合はin演算子を使用
    if (primaryKeyColumns.length == 1) {
      final String pkColumn = primaryKeyColumns[0];
      final List<Object> values = keys.map((ID key) {
        final PrimaryKeyMap normalized = _normalizeKey(key as Object);
        return normalized[pkColumn] as Object;
      }).toList();

      await _table.delete().inFilter(pkColumn, values);
    } else {
      // 複合主キーの場合はチャンク処理
      const int chunkSize = 100;
      for (int i = 0; i < keys.length; i += chunkSize) {
        final List<ID> chunk = keys.sublist(i, math.min(i + chunkSize, keys.length));
        
        await Future.wait(
          chunk.map((ID key) async {
            if (key is Map<String, dynamic>) {
              return deleteByPrimaryKey(key);
            } else {
              return deleteById(key);
            }
          }),
        );
      }
    }
  } catch (e) {
    throw RepositoryException(
      RepositoryError.deleteFailed,
      params: <String, String>{"error": e.toString()},
    );
  }
}
```

## 関連コンポーネント

### BaseModel

`lib/core/base/base_model.dart`で定義：

```dart
@JsonSerializable()
abstract class BaseModel {
  const BaseModel({
    required this.id,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// テーブル名を返す抽象プロパティ
  String get tableName;

  Map<String, dynamic> toJson();
}
```

### QueryUtils

`lib/core/utils/query_utils.dart`で定義：

```dart
class QueryUtils {
  /// フィルタ条件をクエリに適用
  static PostgrestFilterBuilder<dynamic> applyFilters(
    PostgrestFilterBuilder<dynamic> query,
    List<QueryFilter> filters,
  );

  /// ソート条件をクエリに適用
  static PostgrestTransformBuilder<List<Map<String, dynamic>>> applyOrderBys(
    PostgrestTransformBuilder<List<Map<String, dynamic>>> query,
    List<OrderByCondition> orderBys,
  );
}
```

### RepositoryException

`lib/core/error/repository.dart`で定義：

```dart
class RepositoryException implements Exception {
  const RepositoryException(
    this.error, {
    this.params = const <String, String>{},
  });

  final RepositoryError error;
  final Map<String, String> params;

  String get message => error.withParams(params);
}
```

### LogService

`lib/core/utils/log_service.dart`で定義：

```dart
class LogService {
  static void debug(String component, String message, [String? messageJa]);
  static void info(String component, String message, [String? messageJa]);
  static void warning(String component, String message, [String? messageJa]);
  static void error(String component, String message, [String? messageJa], [Object? error, StackTrace? stackTrace]);
}
```

## 重要な修正履歴

### 2024年実装時の重大な修正

BaseRepositoryの実装において、以下の重大な問題を発見・修正しました：

#### 1. 致命的な型エラーの修正

**問題**: `bulkDelete`メソッドで型的に不可能なキャストを実行

```dart
// 修正前（危険）
Future<void> bulkDelete(List<T> keys) // T = モデル型
final List<T> values = keys.map((T key) {
  return normalized[pkColumn] as T; // ❌ キー値をモデル型にキャスト（不可能）
}).toList();

// 修正後（安全）
Future<void> bulkDelete(List<ID> keys) // ID = キー型
final List<Object> values = keys.map((ID key) {
  return normalized[pkColumn] as Object; // ✅ 型安全なキャスト
}).toList();
```

#### 2. ジェネリクス型の競合解決

**問題**: 型パラメータ`T`がクラスレベルとメソッドレベルで競合

```dart
// 修正前
PostgrestFilterBuilder<T> _applyPrimaryKey<T>( // ❌ クラスのTと競合

// 修正後
PostgrestFilterBuilder<TQuery> _applyPrimaryKey<TQuery>( // ✅ 競合回避
```

#### 3. ログ記録の一貫性確保

**問題**: 一部メソッドでログ記録が欠落

```dart
// 修正前
Future<T?> getByPrimaryKey(PrimaryKeyMap keyMap) async {
  try {
    // ログ記録なし
    final response = await query.maybeSingle();

// 修正後
Future<T?> getByPrimaryKey(PrimaryKeyMap keyMap) async {
  try {
    LogService.debug("BaseRepository", "Getting entity by primary key from table: $tableName");
    final response = await query.maybeSingle();
    LogService.debug("BaseRepository", "Entity found in table: $tableName");
```

これらの修正により、BaseRepositoryは完全な型安全性と一貫性を確保しています。

## 今後の拡張予定

### 1. キャッシュ機能

```dart
// 将来的な機能
class CachedBaseRepository<T extends BaseModel, ID> extends BaseRepository<T, ID> {
  final Duration cacheTtl;
  final Map<ID, CacheEntry<T>> _cache = {};

  Future<T?> getById(ID id) async {
    final CacheEntry<T>? cached = _cache[id];
    if (cached != null && !cached.isExpired) {
      return cached.value;
    }

    final T? entity = await super.getById(id);
    if (entity != null) {
      _cache[id] = CacheEntry(entity, DateTime.now().add(cacheTtl));
    }
    return entity;
  }
}
```

### 2. 監査ログ機能

```dart
// 将来的な機能
abstract class AuditableRepository<T extends AuditableModel, ID> extends BaseRepository<T, ID> {
  @override
  Future<T?> create(T entity) async {
    final T? result = await super.create(entity);
    if (result != null) {
      await _recordAuditLog('CREATE', result);
    }
    return result;
  }

  Future<void> _recordAuditLog(String operation, T entity) async {
    // 監査ログの記録
  }
}
```

### 3. 楽観的ロック

```dart
// 将来的な機能
abstract class OptimisticLockRepository<T extends VersionedModel, ID> extends BaseRepository<T, ID> {
  @override
  Future<T?> updateById(ID id, Map<String, dynamic> updates) async {
    final T? current = await getById(id);
    if (current == null) {
      throw RepositoryException(RepositoryError.recordNotFound);
    }

    updates['version'] = current.version + 1;
    updates['updated_at'] = DateTime.now().toIso8601String();

    try {
      return await super.updateById(id, updates);
    } on PostgrestException catch (e) {
      if (e.message.contains('version')) {
        throw RepositoryException(RepositoryError.concurrencyConflict);
      }
      rethrow;
    }
  }
}
```

---

## まとめ

BaseRepositoryは、YATAアプリケーションのデータアクセス層における中核コンポーネントです。以下の特徴により、高品質で保守性の高いアプリケーション開発を実現します：

### 主要な価値

- **完全な型安全性**: コンパイル時エラー検出による信頼性向上
- **高度な機能性**: 31種類の演算子と複雑な検索条件への対応
- **優れたパフォーマンス**: バルク操作とチャンク処理による効率性
- **包括的エラーハンドリング**: 統一されたエラーシステムと詳細ログ
- **拡張性**: ビジネス固有の機能追加が容易

### 開発効率の向上

- **統一されたインターフェース**: 全ドメインで一貫した操作方法
- **自動化されたCRUD操作**: 定型的な処理の自動化
- **強力なクエリ機能**: 複雑なビジネスロジックの簡潔な表現
- **包括的なドキュメント**: 迅速な理解と実装

### 運用品質の確保

- **詳細なログ記録**: トラブルシューティングの効率化
- **エラーの標準化**: 一貫したエラーハンドリング
- **パフォーマンス監視**: 性能問題の早期発見
- **保守性の向上**: 統一されたコードベース

BaseRepositoryの適切な活用により、YATAアプリケーションの開発効率と品質の両方を大幅に向上させることができます。継続的な改善により、さらなる機能強化を図っていきます。
