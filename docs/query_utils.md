# QueryUtils詳細ドキュメント

## 概要

QueryUtilsは、YATAアプリケーションにおけるSupabaseデータベースクエリの構築と実行を統一的に管理するコアライブラリです。Python版を大幅に上回る型安全性と機能性を提供し、複雑なデータベースクエリを直感的かつ効率的に構築できます。

### 設計思想

- **型安全性の確保**: Dart/Flutterの静的型システムを活用した完全な型安全性
- **表現力の向上**: 31種類の演算子と階層化論理条件による豊富な表現力
- **開発効率の向上**: 直感的なQueryConditionBuilderによる高速開発
- **保守性の確保**: 統一されたインターフェースによる一貫したクエリ管理

## 主要機能

### 1. フィルタ演算子（31種類対応）

#### 基本比較演算子

| 演算子 | 説明 | Supabaseメソッド | 使用例 |
|--------|------|------------------|-------|
| `eq` | 等しい | `eq()` | `age = 25` |
| `neq` | 等しくない | `neq()` | `status != 'inactive'` |
| `gt` | より大きい | `gt()` | `price > 100` |
| `gte` | 以上 | `gte()` | `score >= 80` |
| `lt` | より小さい | `lt()` | `quantity < 10` |
| `lte` | 以下 | `lte()` | `discount <= 0.5` |

#### 文字列検索演算子

| 演算子 | 説明 | Supabaseメソッド | 使用例 |
|--------|------|------------------|-------|
| `like` | 部分一致（大文字小文字区別） | `like()` | `name LIKE '%John%'` |
| `ilike` | 部分一致（大文字小文字区別なし） | `ilike()` | `email ILIKE '%gmail%'` |

#### NULL判定演算子

| 演算子 | 説明 | Supabaseメソッド | 使用例 |
|--------|------|------------------|-------|
| `isNull` | NULL判定 | `is()` | `deleted_at IS NULL` |
| `isNotNull` | NULL以外判定 | `not.is()` | `created_at IS NOT NULL` |

#### 配列・リスト演算子

| 演算子 | 説明 | Supabaseメソッド | 使用例 |
|--------|------|------------------|-------|
| `inList` | 配列に含まれる | `in()` | `status IN ('active', 'pending')` |
| `notInList` | 配列に含まれない | `not.in()` | `category NOT IN ('hidden', 'draft')` |

#### JSON・配列操作演算子

| 演算子 | 説明 | Supabaseメソッド | 使用例 |
|--------|------|------------------|-------|
| `contains` | 値を含む | `contains()` | `tags @> '["important"]'` |
| `containedBy` | 値に含まれる | `containedBy()` | `'["tag1"]' <@ tags` |
| `overlaps` | 重複する | `overlaps()` | `array1 && array2` |

#### 範囲演算子

| 演算子 | 説明 | Supabaseメソッド | 使用例 |
|--------|------|------------------|-------|
| `rangeGt` | 範囲より大きい | `rangeGt()` | `price_range >>= '[50,100)'` |
| `rangeGte` | 範囲以上 | `rangeGte()` | `date_range @> '2024-01-01'` |
| `rangeLt` | 範囲より小さい | `rangeLt()` | `score_range <<= '[0,50]'` |
| `rangeLte` | 範囲以下 | `rangeLte()` | `age_range <@ '[20,30]'` |

### 2. 論理条件システム（階層化対応）

#### 基本論理演算子

| 条件タイプ | クラス | 説明 | 使用例 |
|-----------|--------|------|-------|
| AND条件 | `AndCondition` | すべての条件を満たす | `age >= 18 AND status = 'active'` |
| OR条件 | `OrCondition` | いずれかの条件を満たす | `category = 'food' OR category = 'drink'` |
| 複合条件 | `ComplexCondition` | AND/ORの組み合わせ | `(A AND B) OR (C AND D)` |

#### 階層化論理条件

```dart
// 複雑な論理条件の例
AndCondition(
  [
    QueryConditionBuilder.eq("status", "active"),
    OrCondition([
      QueryConditionBuilder.gte("age", 18),
      QueryConditionBuilder.eq("guardian_consent", true),
    ]),
  ]
)
```

### 3. ソート機能

| 機能 | クラス | 説明 | 使用例 |
|------|--------|------|-------|
| 昇順ソート | `OrderByCondition` | 指定カラムで昇順 | `ORDER BY created_at ASC` |
| 降順ソート | `OrderByCondition` | 指定カラムで降順 | `ORDER BY price DESC` |
| 複合ソート | 複数の`OrderByCondition` | 複数カラムでソート | `ORDER BY category, price DESC` |

## 基本的な使用方法

### 1. 単一フィルタ条件

```dart
import 'package:yata/core/utils/query_utils.dart';
import 'package:yata/core/constants/query_types.dart';

// 基本的な等価条件
final condition = QueryConditionBuilder.eq("status", "active");

// Supabaseクエリに適用
final query = supabase
    .from("orders")
    .select("*");

final result = await QueryUtils.applyFilter(query, condition);
```

### 2. 複数フィルタ条件（AND結合）

```dart
// 複数の条件をAND結合で適用
final filters = [
  QueryConditionBuilder.eq("status", "active"),
  QueryConditionBuilder.gte("created_at", "2024-01-01"),
  QueryConditionBuilder.lt("total_amount", 1000),
];

final query = supabase.from("orders").select("*");
final result = await QueryUtils.applyFilters(query, filters);
```

### 3. OR条件の使用

```dart
// OR条件の構築
final orCondition = QueryConditionBuilder.or([
  QueryConditionBuilder.eq("category", "food"),
  QueryConditionBuilder.eq("category", "drink"),
  QueryConditionBuilder.eq("category", "dessert"),
]);

final query = supabase.from("menu_items").select("*");
final result = await QueryUtils.applyFilter(query, orCondition);
```

### 4. ソート条件の適用

```dart
// 単一ソート条件
final orderBy = QueryConditionBuilder.desc("created_at");
final query = supabase.from("orders").select("*");
final result = await QueryUtils.applyOrderBy(query, orderBy);

// 複数ソート条件
final orderBys = [
  QueryConditionBuilder.asc("category"),
  QueryConditionBuilder.desc("price"),
];
final result = await QueryUtils.applyOrderBys(query, orderBys);
```

## 高度な機能

### 1. QueryConditionBuilderの便利メソッド

#### 日付範囲検索

```dart
// 指定期間内のレコードを検索
final dateRangeCondition = QueryConditionBuilder.dateRange(
  "created_at",
  DateTime(2024, 1, 1),
  DateTime(2024, 12, 31),
);

// 実際のクエリ適用例
final recentOrders = await supabase
    .from("orders")
    .select("*")
    .apply((query) => QueryUtils.applyFilter(query, dateRangeCondition));
```

#### テキスト検索

```dart
// 大文字小文字を区別しない部分一致検索
final searchCondition = QueryConditionBuilder.search(
  "product_name",
  "coffee",
  caseSensitive: false,
);

// 実際のクエリ適用例
final products = await supabase
    .from("products")
    .select("*")
    .apply((query) => QueryUtils.applyFilter(query, searchCondition));
```

#### 数値範囲検索

```dart
// 価格帯での商品検索
final priceRangeCondition = QueryConditionBuilder.numberRange(
  "price",
  100,  // 最小値
  500,  // 最大値
);

final affordableProducts = await supabase
    .from("products")
    .select("*")
    .apply((query) => QueryUtils.applyFilter(query, priceRangeCondition));
```

### 2. 複雑な論理条件の構築

#### ネストしたAND/OR条件

```dart
// (status = 'active' AND category IN ['food', 'drink']) 
// OR (status = 'featured' AND price < 1000)
final complexCondition = QueryConditionBuilder.or([
  QueryConditionBuilder.and([
    QueryConditionBuilder.eq("status", "active"),
    QueryConditionBuilder.inList("category", ["food", "drink"]),
  ]),
  QueryConditionBuilder.and([
    QueryConditionBuilder.eq("status", "featured"),
    QueryConditionBuilder.lt("price", 1000),
  ]),
]);

final menuItems = await supabase
    .from("menu_items")
    .select("*")
    .apply((query) => QueryUtils.applyFilter(query, complexCondition));
```

#### 動的クエリ構築

```dart
// ユーザー入力に基づく動的フィルタ構築
List<QueryFilter> buildDynamicFilters({
  String? status,
  String? category,
  double? minPrice,
  double? maxPrice,
  DateTime? fromDate,
  DateTime? toDate,
}) {
  final List<QueryFilter> filters = [];

  if (status != null) {
    filters.add(QueryConditionBuilder.eq("status", status));
  }

  if (category != null) {
    filters.add(QueryConditionBuilder.eq("category", category));
  }

  if (minPrice != null && maxPrice != null) {
    filters.add(QueryConditionBuilder.numberRange("price", minPrice, maxPrice));
  } else if (minPrice != null) {
    filters.add(QueryConditionBuilder.gte("price", minPrice));
  } else if (maxPrice != null) {
    filters.add(QueryConditionBuilder.lte("price", maxPrice));
  }

  if (fromDate != null && toDate != null) {
    filters.add(QueryConditionBuilder.dateRange("created_at", fromDate, toDate));
  }

  return filters;
}

// 使用例
final filters = buildDynamicFilters(
  status: "active",
  category: "food",
  minPrice: 100,
  maxPrice: 500,
);

final results = await supabase
    .from("products")
    .select("*")
    .apply((query) => QueryUtils.applyFilters(query, filters));
```

### 3. BaseRepositoryとの統合

```dart
// BaseRepositoryでの使用例
class ProductRepository extends BaseRepository<Product, String> {
  
  // 商品検索メソッド
  Future<List<Product>> searchProducts({
    String? name,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    final List<QueryFilter> filters = [];

    if (name != null && name.isNotEmpty) {
      filters.add(QueryConditionBuilder.search("name", name));
    }

    if (category != null) {
      filters.add(QueryConditionBuilder.eq("category", category));
    }

    if (minPrice != null && maxPrice != null) {
      filters.add(QueryConditionBuilder.numberRange("price", minPrice, maxPrice));
    }

    final List<OrderByCondition> orderBys = [
      QueryConditionBuilder.asc("category"),
      QueryConditionBuilder.desc("created_at"),
    ];

    return await find(
      filters: filters,
      orderBy: orderBys,
      limit: 50,
    );
  }
}
```

## 実践的使用例

### 1. 在庫管理システムでの活用

```dart
// 在庫不足商品の検索
final lowStockCondition = QueryConditionBuilder.and([
  QueryConditionBuilder.lt("current_stock", "minimum_stock"),
  QueryConditionBuilder.eq("status", "active"),
  QueryConditionBuilder.isNotNull("supplier_id"),
]);

final lowStockProducts = await supabase
    .from("products")
    .select("*, supplier:suppliers(*)")
    .apply((query) => QueryUtils.applyFilter(query, lowStockCondition))
    .apply((query) => QueryUtils.applyOrderBy(
        query, 
        QueryConditionBuilder.asc("current_stock")
      ));
```

### 2. 売上分析クエリ

```dart
// 月次売上分析
final monthlySalesCondition = QueryConditionBuilder.and([
  QueryConditionBuilder.dateRange(
    "order_date",
    DateTime(2024, 6, 1),
    DateTime(2024, 6, 30),
  ),
  QueryConditionBuilder.inList("status", ["completed", "delivered"]),
  QueryConditionBuilder.gt("total_amount", 0),
]);

final monthlySales = await supabase
    .from("orders")
    .select("total_amount, order_date, customer_id")
    .apply((query) => QueryUtils.applyFilter(query, monthlySalesCondition))
    .apply((query) => QueryUtils.applyOrderBy(
        query,
        QueryConditionBuilder.desc("order_date")
      ));
```

### 3. ユーザー権限管理

```dart
// アクティブユーザーの権限チェック
final activeUserCondition = QueryConditionBuilder.and([
  QueryConditionBuilder.eq("status", "active"),
  QueryConditionBuilder.isNotNull("last_login_at"),
  QueryConditionBuilder.gte(
    "last_login_at",
    DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
  ),
]);

final adminUsersCondition = QueryConditionBuilder.or([
  QueryConditionBuilder.eq("role", "admin"),
  QueryConditionBuilder.eq("role", "super_admin"),
]);

final finalCondition = QueryConditionBuilder.and([
  activeUserCondition,
  adminUsersCondition,
]);

final adminUsers = await supabase
    .from("users")
    .select("id, email, role, last_login_at")
    .apply((query) => QueryUtils.applyFilter(query, finalCondition));
```

## パフォーマンス考慮事項

### 1. インデックス戦略

```dart
// インデックスが効率的に使用される条件
final indexFriendlyCondition = QueryConditionBuilder.and([
  // インデックス列を先頭に
  QueryConditionBuilder.eq("status", "active"),
  QueryConditionBuilder.gte("created_at", "2024-01-01"),
  // 選択性の高い条件を優先
  QueryConditionBuilder.eq("user_id", userId),
]);
```

### 2. クエリ最適化

```dart
// ✅ 効率的なクエリパターン
final optimizedCondition = QueryConditionBuilder.and([
  // 最も選択性の高い条件を最初に
  QueryConditionBuilder.eq("user_id", userId),
  QueryConditionBuilder.eq("status", "active"),
  // 範囲条件は後で
  QueryConditionBuilder.gte("created_at", startDate),
]);

// ❌ 非効率なクエリパターン
final inefficientCondition = QueryConditionBuilder.and([
  // 選択性の低い条件が最初
  QueryConditionBuilder.isNotNull("created_at"),
  QueryConditionBuilder.like("description", "%some_text%"),
  // 実際の絞り込み条件が最後
  QueryConditionBuilder.eq("user_id", userId),
]);
```

### 3. メモリ効率

```dart
// ✅ リソース効率的な使用
Future<List<Product>> getProductsPaginated({
  required int page,
  required int pageSize,
  List<QueryFilter>? filters,
}) async {
  final query = supabase
      .from("products")
      .select("*")
      .range(page * pageSize, (page + 1) * pageSize - 1);

  if (filters != null && filters.isNotEmpty) {
    return await QueryUtils.applyFilters(query, filters);
  }

  return await query;
}
```

## エラーハンドリング

### 1. バリデーション機能

```dart
// FilterConditionのバリデーション
final condition = FilterCondition(
  column: "age",
  operator: FilterOperator.inList,
  value: ["18", "25", "30"], // List型が必要
);

if (!condition.isValidValue) {
  throw ArgumentError("Invalid value for ${condition.operator}");
}

// 使用前のバリデーション例
bool validateCondition(FilterCondition condition) {
  // 値の妥当性チェック
  if (!condition.isValidValue) {
    LogService.error(
      "QueryValidation",
      "Invalid value for operator ${condition.operator}",
      "演算子${condition.operator}に対して無効な値です",
    );
    return false;
  }

  // カラム名の存在チェック
  if (condition.column.isEmpty) {
    LogService.error(
      "QueryValidation",
      "Column name cannot be empty",
      "カラム名を指定してください",
    );
    return false;
  }

  return true;
}
```

### 2. 実行時エラー処理

```dart
// クエリ実行時のエラーハンドリング
Future<List<Map<String, dynamic>>> executeQuerySafely(
  PostgrestFilterBuilder query,
  List<QueryFilter> filters,
) async {
  try {
    // フィルタ適用
    final filteredQuery = QueryUtils.applyFilters(query, filters);
    
    // 実行
    final response = await filteredQuery;
    
    LogService.info(
      "QueryExecution",
      "Query executed successfully, ${response.length} records returned",
      "クエリが正常に実行されました。${response.length}件のレコードが返されました",
    );
    
    return response;
    
  } catch (error, stackTrace) {
    LogService.error(
      "QueryExecution",
      "Query execution failed: $error",
      "クエリの実行に失敗しました: $error",
      error,
      stackTrace,
    );
    
    // デフォルト値または例外を再スロー
    rethrow;
  }
}
```

## ベストプラクティス

### 1. 条件構築のベストプラクティス

```dart
// ✅ 推奨パターン：QueryConditionBuilderを使用
final condition = QueryConditionBuilder.and([
  QueryConditionBuilder.eq("status", "active"),
  QueryConditionBuilder.dateRange(
    "created_at",
    DateTime(2024, 1, 1),
    DateTime(2024, 12, 31),
  ),
]);

// ❌ 非推奨パターン：直接コンストラクタを使用
final condition = AndCondition([
  FilterCondition(
    column: "status",
    operator: FilterOperator.eq,
    value: "active",
  ),
  // 複雑な条件の手動構築...
]);
```

### 2. 命名規則

```dart
// ✅ 明確な命名
final activeUserCondition = QueryConditionBuilder.eq("status", "active");
final recentOrdersCondition = QueryConditionBuilder.gte(
  "created_at",
  DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
);

// ❌ 曖昧な命名
final condition1 = QueryConditionBuilder.eq("status", "active");
final filter = QueryConditionBuilder.gte("created_at", someDate);
```

### 3. 再利用可能なクエリ条件

```dart
// 共通クエリ条件の定義
class CommonQueryConditions {
  // アクティブレコード条件
  static FilterCondition get activeRecords =>
      QueryConditionBuilder.eq("status", "active");

  // 最近のレコード条件（7日以内）
  static FilterCondition get recentRecords =>
      QueryConditionBuilder.gte(
        "created_at",
        DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
      );

  // ユーザー固有の条件
  static FilterCondition userOwnedRecords(String userId) =>
      QueryConditionBuilder.eq("user_id", userId);

  // 日付範囲条件
  static AndCondition dateRangeRecords(DateTime from, DateTime to) =>
      QueryConditionBuilder.dateRange("created_at", from, to);
}

// 使用例
final condition = QueryConditionBuilder.and([
  CommonQueryConditions.activeRecords,
  CommonQueryConditions.userOwnedRecords(currentUserId),
  CommonQueryConditions.recentRecords,
]);
```

### 4. テストしやすい設計

```dart
// テスト可能な検索メソッド
class ProductSearchService {
  Future<List<Product>> searchProducts({
    String? name,
    String? category,
    PriceRange? priceRange,
    DateTimeRange? dateRange,
  }) async {
    final conditions = _buildSearchConditions(
      name: name,
      category: category,
      priceRange: priceRange,
      dateRange: dateRange,
    );

    return await _executeSearch(conditions);
  }

  // テスト可能な条件構築メソッド
  @visibleForTesting
  List<QueryFilter> buildSearchConditions({
    String? name,
    String? category,
    PriceRange? priceRange,
    DateTimeRange? dateRange,
  }) {
    final List<QueryFilter> conditions = [];

    if (name != null && name.isNotEmpty) {
      conditions.add(QueryConditionBuilder.search("name", name));
    }

    if (category != null) {
      conditions.add(QueryConditionBuilder.eq("category", category));
    }

    if (priceRange != null) {
      conditions.add(QueryConditionBuilder.numberRange(
        "price",
        priceRange.min,
        priceRange.max,
      ));
    }

    if (dateRange != null) {
      conditions.add(QueryConditionBuilder.dateRange(
        "created_at",
        dateRange.start,
        dateRange.end,
      ));
    }

    return conditions;
  }

  Future<List<Product>> _executeSearch(List<QueryFilter> conditions) async {
    // 実際のクエリ実行
    final query = supabase.from("products").select("*");
    return await QueryUtils.applyFilters(query, conditions);
  }
}
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. 型エラーの解決

**症状**: `FilterCondition`で型に関するエラーが発生

```dart
// ❌ エラーが発生するコード
final condition = QueryConditionBuilder.inList("categories", "food"); // String型を渡している

// ✅ 修正されたコード
final condition = QueryConditionBuilder.inList("categories", ["food"]); // List型を渡す
```

**解決方法**:

- `inList`/`notInList`演算子には必ずList型を渡す
- `like`/`ilike`演算子にはString型を渡す
- 数値比較には適切な数値型を使用

#### 2. OR条件の構築エラー

**症状**: OR条件が期待通りに動作しない

```dart
// ❌ 問題のあるコード：ネストしたOR条件
final problematicCondition = QueryConditionBuilder.or([
  QueryConditionBuilder.or([
    QueryConditionBuilder.eq("status", "active"),
    QueryConditionBuilder.eq("status", "pending"),
  ]),
  QueryConditionBuilder.eq("priority", "high"),
]);

// ✅ 修正されたコード：フラットなOR条件
final fixedCondition = QueryConditionBuilder.or([
  QueryConditionBuilder.eq("status", "active"),
  QueryConditionBuilder.eq("status", "pending"),
  QueryConditionBuilder.eq("priority", "high"),
]);
```

#### 3. パフォーマンスの問題

**症状**: クエリが遅い

**診断方法**:

```dart
// クエリのログ出力
LogService.debug(
  "QueryPerformance",
  "Executing query with ${filters.length} filters",
  "${filters.length}個のフィルタでクエリを実行",
);

final stopwatch = Stopwatch()..start();
final results = await QueryUtils.applyFilters(query, filters);
stopwatch.stop();

LogService.info(
  "QueryPerformance",
  "Query completed in ${stopwatch.elapsedMilliseconds}ms, ${results.length} results",
  "クエリが${stopwatch.elapsedMilliseconds}ms で完了、${results.length}件の結果",
);
```

**解決方法**:

- 選択性の高い条件を先頭に配置
- インデックスが活用される条件構造に変更
- 不要な条件を削除
- ページネーションの実装

## アーキテクチャ詳細

### クラス構造

```
QueryUtils (静的ユーティリティ)
├── applyFilter() - 単一フィルタ適用
├── applyFilters() - 複数フィルタ適用（AND結合）
├── applyOrderBy() - ソート条件適用
└── Helper Methods - 後方互換性メソッド群

QueryConditionBuilder (ファクトリクラス)
├── Basic Operators - eq, neq, gt, gte, lt, lte
├── String Operators - like, ilike
├── List Operators - inList, notInList
├── Null Operators - isNull, isNotNull
├── Array Operators - contains, containedBy, overlaps
├── Range Operators - rangeGt, rangeGte, rangeLt, rangeLte
├── Logical Operators - and, or, complex
└── Convenience Methods - dateRange, search, numberRange

Query Types (型定義)
├── QueryFilter (基底クラス)
├── FilterCondition (単一フィルタ条件)
├── LogicalCondition (論理条件基底クラス)
│   ├── AndCondition
│   ├── OrCondition
│   └── ComplexCondition
└── OrderByCondition (ソート条件)
```

### 処理フロー

1. **条件構築フェーズ**

   ```
   QueryConditionBuilder → FilterCondition/LogicalCondition 生成
   ```

2. **クエリ適用フェーズ**

   ```
   QueryUtils.applyFilter() → _applySingleFilter()/_applyLogicalCondition()
   ```

3. **Supabase変換フェーズ**

   ```
   Dart条件オブジェクト → Supabase API呼び出し
   ```

### 型安全性の実現

```dart
// コンパイル時型チェック
abstract class QueryFilter {
  const QueryFilter();
}

// 具象クラスでの型安全性
class FilterCondition extends QueryFilter {
  final String column;
  final FilterOperator operator;
  final dynamic value; // 実行時バリデーションで型安全性確保

  bool get isValidValue {
    // 演算子に応じた型バリデーション
    switch (operator) {
      case FilterOperator.inList:
        return value is List && (value as List).isNotEmpty;
      case FilterOperator.like:
        return value is String && (value as String).isNotEmpty;
      // その他の型チェック...
    }
  }
}
```

## 関連コンポーネント

### BaseRepository統合

QueryUtilsは`BaseRepository`と完全に統合されており：

```dart
// BaseRepositoryでの使用例
abstract class BaseRepository<T extends BaseModel, ID> {
  Future<List<T>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int? limit,
    int? offset,
  }) async {
    var query = _client.from(tableName).select("*");

    // QueryUtilsを使用してフィルタ適用
    if (filters != null && filters.isNotEmpty) {
      query = QueryUtils.applyFilters(query, filters);
    }

    // ソート条件適用
    if (orderBy != null && orderBy.isNotEmpty) {
      query = QueryUtils.applyOrderBys(query, orderBy);
    }

    // ページネーション
    if (offset != null) query = query.range(offset, (offset + (limit ?? 50)) - 1);
    if (limit != null && offset == null) query = query.limit(limit);

    final response = await query;
    return response.map((data) => fromMap(data)).toList();
  }
}
```

### LogServiceとの連携

すべてのクエリ操作はLogServiceと連携し、詳細なログを出力：

```dart
// QueryUtils内でのログ出力例
LogService.debug(
  "QueryUtils",
  "Applying filter: ${condition.column} ${condition.operator} ${condition.value}",
  "フィルタ適用: ${condition.column} ${condition.operator} ${condition.value}",
);

LogService.info(
  "QueryUtils",
  "Applied ${filters.length} filters with AND combination",
  "${filters.length}個のフィルタをAND結合で適用しました",
);
```

## Python版からの改善点

### 1. 型安全性の大幅向上

**Python版**:

```python
# 動的型、実行時エラーのリスク
def create_filter(column, operator, value):
    return {"column": column, "op": operator, "value": value}
```

**Dart版**:

```dart
// 静的型、コンパイル時型チェック
class FilterCondition extends QueryFilter {
  const FilterCondition({
    required String column,
    required FilterOperator operator,
    required dynamic value,
  });
  
  bool get isValidValue => /* 型バリデーション */;
}
```

### 2. 演算子の大幅拡張

- **Python版**: 基本的な比較演算子のみ（8種類）
- **Dart版**: 包括的な演算子セット（31種類）

### 3. 階層化論理条件

**Python版**:

```python
# 平坦な条件のみサポート
filters = [
    ("status", "eq", "active"),
    ("age", "gte", 18)
]
```

**Dart版**:

```dart
// 複雑な階層化条件をサポート
final condition = QueryConditionBuilder.and([
  QueryConditionBuilder.eq("status", "active"),
  QueryConditionBuilder.or([
    QueryConditionBuilder.gte("age", 18),
    QueryConditionBuilder.eq("guardian_consent", true),
  ]),
]);
```

### 4. 便利メソッドの追加

```dart
// Python版にはない便利機能
QueryConditionBuilder.dateRange("created_at", from, to);
QueryConditionBuilder.search("name", "search_term");
QueryConditionBuilder.numberRange("price", 100, 500);
```

## 今後の拡張予定

### 1. クエリキャッシュ機能

```dart
// 将来的な機能
class QueryCache {
  static Future<List<Map<String, dynamic>>> getCachedQuery(
    String cacheKey,
    PostgrestFilterBuilder query,
    Duration ttl,
  ) async {
    // キャッシュロジック
  }
}
```

### 2. クエリビルダーパターン

```dart
// 将来的な機能
class FluentQueryBuilder {
  FluentQueryBuilder where(String column) => this;
  FluentQueryBuilder equals(dynamic value) => this;
  FluentQueryBuilder and() => this;
  FluentQueryBuilder or() => this;
  Future<List<T>> execute<T>() async => /* 実行 */;
}

// 使用例
final results = await FluentQueryBuilder()
    .where("status").equals("active")
    .and()
    .where("age").greaterThanOrEqual(18)
    .execute<User>();
```

### 3. GraphQLサポート

```dart
// 将来的な機能
class GraphQLQueryUtils {
  static String buildGraphQLQuery(List<QueryFilter> filters) {
    // GraphQLクエリ生成
  }
}
```

### 4. クエリ最適化支援

```dart
// 将来的な機能
class QueryOptimizer {
  static List<QueryFilter> optimizeFilters(List<QueryFilter> filters) {
    // フィルタの最適化（選択性の高い条件を前に移動など）
  }
  
  static QueryPerformanceReport analyzeQuery(List<QueryFilter> filters) {
    // クエリパフォーマンス分析
  }
}
```

---

## まとめ

QueryUtilsは、YATAアプリケーションにおけるデータベースクエリ構築の中核を担う重要なコンポーネントです：

### 主要な価値

- **開発効率**: 直感的なAPIによる高速開発
- **型安全性**: Dartの静的型システムを活用した堅牢性
- **表現力**: 31種類の演算子による豊富な表現力
- **保守性**: 統一されたインターフェースによる一貫した開発

### 技術的優位性

- Python版を大幅に上回る機能性と安全性
- Supabaseとの完全統合
- BaseRepositoryパターンとの連携
- 包括的なエラーハンドリングとログ機能

QueryUtilsを適切に活用することで、複雑なデータベースクエリを安全かつ効率的に構築し、YATAアプリケーションの品質向上に大きく貢献できます。
