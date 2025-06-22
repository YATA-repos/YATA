# Analytics Service

## 概要

`analytics`フィーチャーのサービスクラスは、分析・統計機能に関するビジネスロジックを担当します。日別統計、売上分析、トレンド比較などの複雑な計算処理を提供します。

## サービスクラス一覧

### AnalyticsService

分析・統計処理を行うサービスです。

**場所**: `lib/features/analytics/services/analytics_service.dart`

**依存リポジトリ**:

- `OrderRepository`
- `OrderItemRepository`
- `StockTransactionRepository`

#### 主要メソッド

##### `getRealTimeDailyStats(DateTime targetDate, String userId)`

指定日のリアルタイム日次統計を取得します。

- **パラメータ**:
  - `targetDate`: 対象日
  - `userId`: ユーザーID
- **戻り値**: `Future<DailyStatsResult>`
- **動作**:
  - 指定日の注文数をステータス別に集計
  - 完了注文の売上合計を計算
  - 平均調理時間を算出（startedPreparingAt〜readyAtの時間差）
  - 最人気商品を特定

**使用例**:

```dart
final analyticsService = AnalyticsService();
final today = DateTime.now();
final stats = await analyticsService.getRealTimeDailyStats(today, userId);
print('Today revenue: ${stats.totalRevenue}');
```

##### `getPopularItemsRanking(int days, int limit, String userId)`

人気商品ランキングを取得します。

- **パラメータ**:
  - `days`: 集計対象日数
  - `limit`: 取得件数の上限
  - `userId`: ユーザーID
- **戻り値**: `Future<List<Map<String, dynamic>>>`
- **動作**:
  - OrderItemRepositoryから売上集計データを取得
  - 売上順にランキング化
  - ランク、商品ID、数量、売上を含む結果を返却

##### `calculateAveragePreparationTime(int days, String? menuItemId, String userId)`

平均調理時間を計算します。

- **パラメータ**:
  - `days`: 集計対象日数
  - `menuItemId`: 特定メニューアイテムID（null時は全商品）
  - `userId`: ユーザーID
- **戻り値**: `Future<double?>`
- **動作**:
  - 期間内の完了注文を取得
  - 特定メニューアイテム指定時はフィルタリング
  - startedPreparingAt〜readyAtの時間差を分単位で平均化

##### `getHourlyOrderDistribution(DateTime targetDate, String userId)`

時間帯別注文分布を取得します。

- **パラメータ**:
  - `targetDate`: 対象日
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<int, int>>`
- **動作**:
  - 指定日の全注文を時間帯別に集計
  - 0-23時の全時間帯を含むMapを返却
  - 注文がない時間帯は0で埋める

##### `calculateRevenueByDateRange(DateTime dateFrom, DateTime dateTo, String userId)`

期間指定売上を計算します。

- **パラメータ**:
  - `dateFrom`: 開始日
  - `dateTo`: 終了日
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, dynamic>>`
- **動作**:
  - 期間内の完了注文から売上統計を算出
  - 総売上、注文数、平均注文単価を計算
  - 日別売上の詳細内訳も提供

**返却データ構造**:

```dart
{
  "total_revenue": int,
  "total_orders": int,
  "average_order_value": double,
  "daily_breakdown": Map<String, int>,
  "period_start": String,
  "period_end": String,
}
```

##### `getMaterialConsumptionAnalysis(String materialId, int days, String userId)`

材料消費分析を取得します。

- **パラメータ**:
  - `materialId`: 材料ID
  - `days`: 分析期間日数
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, dynamic>>`
- **動作**:
  - StockTransactionRepositoryから消費取引を取得
  - 負の値（消費）の取引のみを抽出
  - 総消費量、日別消費量、平均日次消費量を算出

##### `calculateMenuItemProfitability(String menuItemId, int days, String userId)`

メニューアイテムの収益性を分析します。

- **パラメータ**:
  - `menuItemId`: メニューアイテムID
  - `days`: 分析期間日数
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, dynamic>>`
- **動作**:
  - 指定メニューアイテムの注文明細を期間で取得
  - 売上数量、売上額、平均単価を算出
  - 日別売上詳細を提供

##### `getDailySummaryWithTrends(DateTime targetDate, int comparisonDays, String userId)`

日次サマリーをトレンド比較付きで取得します。

- **パラメータ**:
  - `targetDate`: 対象日
  - `comparisonDays`: 比較期間日数
  - `userId`: ユーザーID
- **戻り値**: `Future<Map<String, dynamic>>`
- **動作**:
  - 対象日の統計と比較期間の平均を算出
  - 売上・注文数のトレンド変化率を計算
  - 現在値、トレンド情報、比較平均値を統合して返却

## ビジネスロジック詳細

### 統計計算の特徴

- **リアルタイム性**: 現在時刻までのデータを即座に反映
- **多角的分析**: 売上、時間、商品、材料など様々な視点
- **トレンド分析**: 過去データとの比較による変化の把握

### 調理時間計算

- **精密性**: 秒単位での計算後、分単位に変換
- **フィルタリング**: 特定メニューアイテムでの絞り込み対応
- **例外処理**: 調理開始・完了時刻が未設定の場合を適切に処理

### 集計処理最適化

- **効率的なクエリ**: リポジトリレイヤーでの事前集計を活用
- **メモリ効率**: 大量データの段階的処理
- **キャッシュ活用**: 繰り返し計算の最適化

## データ構造

### DailyStatsResult

```dart
class DailyStatsResult {
  final int completedOrders;
  final int pendingOrders;
  final int totalRevenue;
  final int? averagePrepTimeMinutes;
  final Map<String, dynamic>? mostPopularItem;
}
```

### 人気商品ランキング形式

```dart
[
  {
    "rank": 1,
    "menu_item_id": "item_id",
    "total_quantity": 100,
    "total_amount": 50000,
  },
  // ...
]
```

## パフォーマンス考慮事項

### 大量データ処理

- **段階的処理**: メモリ効率を考慮した分割処理
- **並列処理**: 独立した計算の並行実行
- **結果キャッシュ**: 計算済み結果の再利用

### データベースアクセス

- **最適化クエリ**: 必要最小限のデータ取得
- **一括処理**: 複数の小さなクエリを統合
- **インデックス活用**: 日付範囲検索の効率化

## エラーハンドリング

### データ不整合対応

- **NULL値処理**: 未設定データの適切な処理
- **期間外データ**: 予期しない日付データの除外
- **権限チェック**: ユーザーIDによる厳格なフィルタリング

### 計算エラー対応

- **ゼロ除算**: 分母が0の場合の安全な処理
- **数値オーバーフロー**: 大きな数値の適切な処理
- **精度維持**: 小数点計算での精度保持

## 関連モデル・DTO

- `DailyStatsResult`: `lib/features/analytics/dto/analytics_dto.dart`
- `Order`: `lib/features/order/models/order_model.dart`
- `OrderItem`: `lib/features/order/models/order_model.dart`
- `StockTransaction`: `lib/features/stock/models/stock_model.dart`

## 使用例

### 売上ダッシュボード

```dart
final analyticsService = AnalyticsService();

// 今日の統計取得
final todayStats = await analyticsService.getRealTimeDailyStats(
  DateTime.now(), 
  userId
);

// 週間トレンド取得
final weeklyTrend = await analyticsService.getDailySummaryWithTrends(
  DateTime.now(), 
  7, 
  userId
);

// 人気商品ランキング
final popularItems = await analyticsService.getPopularItemsRanking(
  30, 
  5, 
  userId
);
```

### 詳細分析レポート

```dart
// メニューアイテム分析
final profitability = await analyticsService.calculateMenuItemProfitability(
  menuItemId, 
  30, 
  userId
);

// 材料消費分析
final consumption = await analyticsService.getMaterialConsumptionAnalysis(
  materialId, 
  30, 
  userId
);

// 期間売上分析
final revenue = await analyticsService.calculateRevenueByDateRange(
  startDate, 
  endDate, 
  userId
);
```

## 継承関係

```
AnalyticsService（独立クラス）
│
├─依存→ OrderRepository
├─依存→ OrderItemRepository
└─依存→ StockTransactionRepository
```
