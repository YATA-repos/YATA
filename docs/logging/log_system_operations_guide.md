# ログシステム運用ガイド

このドキュメントでは、YATAプロジェクトのログシステムの運用方法とベストプラクティスについて説明します。

## 目次

1. [ログシステム概要](#ログシステム概要)
2. [環境別設定](#環境別設定)
3. [パフォーマンス監視](#パフォーマンス監視)
4. [運用メンテナンス](#運用メンテナンス)
5. [ダッシュボード監視](#ダッシュボード監視)
6. [トラブルシューティング](#トラブルシューティング)
7. [ベストプラクティス](#ベストプラクティス)

## ログシステム概要

### 主要コンポーネント

- **YataLogger**: メインのログサービス（logger パッケージベース）
- **LoggerMixin**: サービス・リポジトリクラス用Mixin
- **UnifiedBufferedFileOutput**: ファイル出力・ローテーション機能
- **LoggerPerformanceStats**: パフォーマンス統計追跡
- **LoggerConfig**: 設定管理

### 特徴

- logger パッケージ完全準拠
- 環境別自動最適化
- リアルタイム統計監視
- 自動ファイルローテーション
- パフォーマンス計測機能

## 環境別設定

### 自動設定

ログレベルは実行環境に応じて自動選択されます：

- **開発環境 (Debug Mode)**: `DEBUG` - 詳細ログでデバッグを支援
- **プロファイル環境 (Profile Mode)**: `INFO` - パフォーマンス重視
- **本番環境 (Release Mode)**: `WARNING` - 問題追跡のみ

### 手動設定

環境変数 `LOG_LEVEL` で明示的に指定可能：

```bash
# 開発時の詳細ログ
flutter run --dart-define=LOG_LEVEL=DEBUG

# 本番環境での最小ログ
flutter run --dart-define=LOG_LEVEL=WARNING
```

### 設定確認

現在の設定を確認するには：

```dart
final Map<String, dynamic> levelInfo = YataLogger.getLogLevelInfo();
print(levelInfo);
```

## パフォーマンス監視

### 基本統計情報

```dart
// パフォーマンス統計を取得
final Map<String, dynamic> stats = YataLogger.getPerformanceStats();

// 健康状態チェック
final Map<String, dynamic> health = YataLogger.getHealthCheck();
```

### パフォーマンス計測

サービス層でのパフォーマンス計測：

```dart
class InventoryService with LoggerMixin {
  Future<void> updateStock(String itemId, int quantity) async {
    // 自動計測機能
    return withPerformanceTimer(
      'updateStock',
      () async {
        // 実際の処理
        await _repository.updateStock(itemId, quantity);
      },
      thresholdMs: 500, // 500ms以上で警告
    );
  }

  // 手動計測
  Future<void> complexOperation() async {
    final DateTime startTime = startPerformanceTimer('complexOperation');
    try {
      // 処理実行
      await _performComplexTask();
    } finally {
      endPerformanceTimer(startTime, 'complexOperation');
    }
  }
}
```

### 特殊ログ種別

```dart
// クリティカルな処理（常に記録）
logCritical('Service startup completed');

// ビジネスメトリクス
logBusinessMetric('daily_sales', {
  'revenue': 50000,
  'orders': 25,
  'average_order': 2000,
});

// ユーザーアクション
logUserAction('order_placed', context: {
  'user_id': userId,
  'order_total': '2500',
});

// システムヘルス
logSystemHealth('memory_usage', 256, unit: 'MB');
```

## 運用メンテナンス

### 自動メンテナンス

- **バッファフラッシュ**: 5秒間隔（設定変更可能）
- **ファイルローテーション**: 10MB到達時
- **古いログ削除**: 30日間保持

### 手動メンテナンス

```dart
// バッファを即座にフラッシュ
await YataLogger.flushBuffer();

// 古いログファイルを削除（7日間保持）
await YataLogger.cleanupOldLogs(daysToKeep: 7);

// ログ統計情報を取得
final Map<String, dynamic> stats = await YataLogger.getLogStats();
```

### 設定調整

```dart
// 環境変数での設定
LOG_BUFFER_SIZE=200          // バッファサイズ
LOG_FLUSH_INTERVAL=3         // フラッシュ間隔（秒）
LOG_MAX_FILE_SIZE_MB=15      // 最大ファイルサイズ
LOG_CLEANUP_DAYS=14          // 保持日数
```

## ダッシュボード監視

### Analytics画面での監視

Analytics画面の「システム監視」セクションで以下を確認できます：

- **健康状態**: ログシステムの全体的な状態
- **ログレベル設定**: 現在の設定と実行環境
- **パフォーマンス統計**: 処理ログ数、平均処理時間、稼働時間
- **ファイル出力情報**: バッファサイズ、ファイルサイズ
- **メンテナンス操作**: フラッシュ、クリーンアップ

### 監視指標

- **失敗率**: 5%未満が健康
- **平均処理時間**: 1秒未満が健康
- **最後のフラッシュ**: 10分以内が健康

## トラブルシューティング

### よくある問題

#### 1. ログが出力されない

**原因**: ログレベルフィルターにより除外されている

**解決方法**:
```dart
// 現在のレベルを確認
final LogLevel currentLevel = YataLogger.currentMinimumLevel;

// レベルを一時的に変更
YataLogger.setMinimumLevel(LogLevel.debug);
```

#### 2. ファイル出力エラー

**原因**: ディスク容量不足またはアクセス権限

**解決方法**:
```dart
// 健康状態をチェック
final Map<String, dynamic> health = YataLogger.getHealthCheck();
if (!health['overallHealthy']) {
  // 古いログを削除
  await YataLogger.cleanupOldLogs(daysToKeep: 7);
}
```

#### 3. パフォーマンス低下

**原因**: バッファサイズが大きすぎる、フラッシュ間隔が短すぎる

**解決方法**:
```dart
// 設定を調整
LoggerConfig.setBufferSize(50);    // デフォルト100から50に削減
LoggerConfig.setFlushInterval(10); // デフォルト5秒から10秒に延長
```

### 診断コマンド

```dart
// 詳細診断情報
print(YataLogger.getPerformanceStatsDebugString());
print(YataLogger.getConfigDebugString());

// 健康状態チェック
final Map<String, dynamic> health = YataLogger.getHealthCheck();
if (!health['overallHealthy']) {
  print('Warning: Log system is not healthy');
  print('Issues: ${health}');
}
```

## ベストプラクティス

### 1. ログレベルの使い分け

```dart
// DEBUG: 開発時の詳細情報
logDebug('Processing item: $itemId with quantity: $quantity');

// INFO: 一般的な動作記録
logInfo('Order processed successfully: $orderId');

// WARNING: 問題の可能性
logWarning('Low stock detected for item: $itemId');

// ERROR: エラー状況
logError('Failed to process payment', error, stackTrace);
```

### 2. 構造化ログの活用

```dart
// ビジネスメトリクス用
logBusinessMetric('inventory_change', {
  'item_id': itemId,
  'old_quantity': oldQty,
  'new_quantity': newQty,
  'change_type': 'stock_update',
});
```

### 3. パフォーマンス監視

```dart
// 重要な処理は必ず計測
Future<List<Order>> getOrderHistory() async {
  return withPerformanceTimer(
    'getOrderHistory',
    () => _repository.getOrderHistory(),
    thresholdMs: 1000, // 1秒以上で警告
  );
}
```

### 4. エラーハンドリング

```dart
try {
  await _performOperation();
} catch (e, stackTrace) {
  logError('Operation failed', e, stackTrace);
  
  // ビジネスメトリクスとしても記録
  logBusinessMetric('operation_failure', {
    'operation': 'performOperation',
    'error_type': e.runtimeType.toString(),
  });
  
  rethrow;
}
```

### 5. 運用監視

```dart
// 定期的な健康状態チェック
Timer.periodic(Duration(minutes: 15), (timer) async {
  final Map<String, dynamic> health = YataLogger.getHealthCheck();
  if (!health['overallHealthy']) {
    logCritical('Log system health check failed: ${health}');
  }
});
```

## 付録: 設定リファレンス

### 環境変数

| 変数名 | デフォルト値 | 説明 |
|--------|-------------|------|
| `LOG_LEVEL` | 自動選択 | ログレベル (DEBUG/INFO/WARNING/ERROR) |
| `LOG_BUFFER_SIZE` | 100 | バッファサイズ |
| `LOG_FLUSH_INTERVAL` | 5 | フラッシュ間隔（秒） |
| `LOG_MAX_FILE_SIZE_MB` | 10 | 最大ファイルサイズ（MB） |
| `LOG_CLEANUP_DAYS` | 30 | ログ保持日数 |

### API リファレンス

#### YataLogger主要メソッド

```dart
// 初期化
await YataLogger.initialize(minimumLevel: LogLevel.debug);

// 基本ログ出力
YataLogger.debug(component, message);
YataLogger.info(component, message);
YataLogger.warning(component, message);
YataLogger.error(component, message, error, stackTrace);

// パフォーマンス監視
DateTime start = YataLogger.startPerformanceTimer(component, operation);
YataLogger.endPerformanceTimer(start, component, operation);

// 特殊ログ
YataLogger.critical(component, message);
YataLogger.businessMetric(component, metric, data);
YataLogger.userAction(component, action, context: context);
YataLogger.systemHealth(component, metric, value, unit: unit);

// 統計・設定
Map<String, dynamic> stats = await YataLogger.getLogStats();
Map<String, dynamic> performance = YataLogger.getPerformanceStats();
Map<String, dynamic> health = YataLogger.getHealthCheck();
Map<String, dynamic> levelInfo = YataLogger.getLogLevelInfo();

// メンテナンス
await YataLogger.flushBuffer();
await YataLogger.cleanupOldLogs(daysToKeep: 30);
```

#### LoggerMixin主要メソッド

```dart
class MyService with LoggerMixin {
  void performOperation() {
    // 基本ログ
    logDebug('Starting operation');
    logInfo('Operation completed');
    logWarning('Performance degraded');
    logError('Operation failed', error, stackTrace);
    
    // パフォーマンス監視
    DateTime start = startPerformanceTimer('operation');
    endPerformanceTimer(start, 'operation');
    
    // 自動計測
    withPerformanceTimer('operation', () async {
      // 処理内容
    });
    
    // 特殊ログ
    logCritical('Critical system event');
    logBusinessMetric('sales', {'amount': 1000});
    logUserAction('button_clicked');
    logSystemHealth('cpu_usage', 75, unit: '%');
  }
}
```

---

このガイドに従って適切にログシステムを運用することで、効率的なデバッグ、監視、トラブルシューティングが可能になります。