# Analytics Repository

## 概要

`analytics`フィーチャーのリポジトリクラスは、分析機能に関するデータアクセスを担当します。日別集計データの管理を行います。

## リポジトリクラス一覧

### DailySummaryRepository

日別集計データの管理を行うリポジトリです。

**場所**: `lib/features/analytics/repositories/daily_summary_repository.dart`

**基底クラス**: `BaseRepository<DailySummary, String>`

#### 主要メソッド

##### `findByDate(DateTime targetDate, String userId)`

指定日の集計データを取得します。

- **パラメータ**:
  - `targetDate`: 取得対象の日付
  - `userId`: ユーザーID
- **戻り値**: `Future<DailySummary?>`
- **動作**:
  - 日付を日の開始時刻（00:00:00）に正規化
  - ユーザーIDと正規化された日付でフィルタリング
  - 該当する集計データを1件取得

**使用例**:

```dart
final repository = DailySummaryRepository();
final today = DateTime.now();
final summary = await repository.findByDate(today, userId);
```

##### `findByDateRange(DateTime dateFrom, DateTime dateTo, String userId)`

期間指定で集計データ一覧を取得します。

- **パラメータ**:
  - `dateFrom`: 開始日
  - `dateTo`: 終了日
  - `userId`: ユーザーID
- **戻り値**: `Future<List<DailySummary>>`
- **動作**:
  - 開始日を日の開始時刻（00:00:00）に正規化
  - 終了日を日の終了時刻（23:59:59.999）に正規化
  - 日付順（昇順）でソート

**使用例**:

```dart
final repository = DailySummaryRepository();
final lastWeek = DateTime.now().subtract(Duration(days: 7));
final today = DateTime.now();
final summaries = await repository.findByDateRange(lastWeek, today, userId);
```

## テーブル構造

### daily_summaries

| カラム名 | 型 | 説明 |
|---------|-----|------|
| id | String | 主キー（UUID） |
| user_id | String | ユーザーID |
| summary_date | DateTime | 集計日（正規化済み） |
| total_orders | int | 総注文数 |
| completed_orders | int | 完了注文数 |
| pending_orders | int | 進行中注文数 |
| total_revenue | int | 総売上（円） |
| average_prep_time_minutes | int? | 平均調理時間（分） |
| most_popular_item_id | String? | 最も人気のある商品ID |
| most_popular_item_count | int | 最も人気のある商品の注文数 |
| created_at | DateTime? | 作成日時 |
| updated_at | DateTime? | 更新日時 |

## 特記事項

### 日付の正規化

- `findByDate`では、指定された日付を`DateTime(year, month, day)`で日の開始時刻に正規化
- `findByDateRange`では、開始日を開始時刻、終了日を終了時刻に正規化
- これにより時分秒の違いによる検索漏れを防止

### フィルタリング

- すべてのメソッドでユーザーIDによるフィルタリングを実施
- マルチテナント環境でのデータ分離を保証

### ソート

- `findByDateRange`では日付順（昇順）でソート
- 時系列分析に適した順序で結果を返却

## 関連モデル

- `DailySummary`: `lib/features/analytics/models/analytics_model.dart`

## 継承関係

```
BaseRepository<DailySummary, String>
  ↓
DailySummaryRepository
```
