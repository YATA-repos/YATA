# YataLogger使用ガイド

## 概要

YataLoggerは、既存の複数のログ実装を統合し、logger パッケージをベースとした高性能なログシステムを提供します。

## 主な特徴

### 1. 完全な後方互換性
- 既存のAPIとの完全な互換性
- 既存のLoggerMixinのAPIを完全に保持
- LoggerV2Mixinの機能も統合
- 移行途中の参照エラーは一時的なもので、段階的に解決されます

### 2. logger パッケージの利点を活用
- 高性能なログ処理
- 柔軟な出力先設定（コンソール、ファイル）
- カスタムプリンターによる統一フォーマット
- 効率的なフィルタリング

### 3. 統合された機能
- LoggerConfig: 設定の一元管理
- LoggerPerformanceStats: パフォーマンス監視
- BufferedFileOutput: 効率的なファイル出力

## 基本的な使い方

### 初期化
```dart
// main.dart
await YataLogger.initialize();
```

### LoggerMixinを使った基本的なログ出力
```dart
class MyService with LoggerMixin {
  void someMethod() {
    logInfo("処理を開始します");
    logDebug("デバッグ情報: ${someData}");
    logWarning("警告: ${warning}");
    logError("エラーが発生しました", error, stackTrace);
  }
}
```

### 直接呼び出し
```dart
YataLogger.info("MyComponent", "情報メッセージ");
YataLogger.warning("MyComponent", "警告メッセージ");
YataLogger.error("MyComponent", "エラーメッセージ", error, stackTrace);
```

### 事前定義メッセージの使用
```dart
class MyService with LoggerMixin {
  void someMethod() {
    logInfoMessage(ServiceInfo.operationStarted);
    logWarningMessage(ServiceWarning.operationFailed, {"reason": "timeout"});
    logErrorMessage(ServiceError.criticalFailure, {"component": "database"}, error, stackTrace);
  }
}
```

## 高度な機能

### 1. 設定管理
```dart
// 環境変数から設定を読み込み（initialize時に自動実行）
LoggerConfig.loadFromEnvironment();

// 実行時設定変更
YataLogger.setBufferSize(200);
YataLogger.setFlushInterval(10);

// 現在の設定確認
print(YataLogger.getConfigDebugString());
```

### 2. パフォーマンス監視
```dart
// パフォーマンス統計取得
final Map<String, dynamic> stats = YataLogger.getPerformanceStats();
print("処理されたログ数: ${stats['totalLogsProcessed']}");

// 健康状態チェック
final Map<String, dynamic> health = YataLogger.getHealthCheck();
if (health['overallHealthy'] != true) {
  print('ログシステムに問題があります');
}

// デバッグ表示
print(YataLogger.getPerformanceStatsDebugString());
```

### 3. 構造化ログ
```dart
class MyService with LoggerMixin {
  void someMethod() {
    // 構造化データのログ出力
    logStructured(LogLevel.info, {
      'action': 'user_login',
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'ip': userIp,
    });
    
    // オブジェクトのログ出力
    logObject("ユーザーデータ", userObject);
  }
}
```

### 4. より詳細なログレベル
```dart
class MyService with LoggerMixin {
  void debugMethod() {
    logVerbose("詳細なデバッグ情報");
    logTrace("トレースレベル情報");
    logFatal("致命的エラー", error, stackTrace);
  }
}
```

## 環境変数設定

`.env` ファイルで以下の設定が可能です：

```bash
# バッファサイズ（デフォルト: 100）
LOG_BUFFER_SIZE=200

# フラッシュ間隔（秒、デフォルト: 5）
LOG_FLUSH_INTERVAL=10

# 最大ファイルサイズ（MB、デフォルト: 10）
LOG_MAX_FILE_SIZE_MB=20

# 最大リトライ回数（デフォルト: 3）
LOG_MAX_RETRY_ATTEMPTS=5

# ログファイル保持日数（デフォルト: 30）
LOG_CLEANUP_DAYS=60
```

## 移行における一時的な問題について

統合過程で以下のような一時的な参照エラーが発生する可能性がありますが、これらは段階的に解決されます：

1. `YataLogger` への直接参照
2. 古いログサービスパスへの参照
3. `LoggerV2Mixin` への参照

これらのエラーは統合が完了すると自動的に解決されます。

## パフォーマンス向上の効果

### 1. メモリ効率
- バッファリングによる効率的なメモリ使用
- 設定可能なバッファサイズ

### 2. I/O効率
- 定期的なバッチ書き込み
- リトライ機能による信頼性向上

### 3. 運用監視
- リアルタイムパフォーマンス統計
- 健康状態監視

## トラブルシューティング

### ログが出力されない場合
```dart
// 初期化状態の確認
if (!YataLogger.isInitialized) {
  await YataLogger.initialize();
}

// 設定の確認
print(YataLogger.getConfigDebugString());
```

### パフォーマンス問題の調査
```dart
// 健康状態チェック
final health = YataLogger.getHealthCheck();
if (!health['overallHealthy']) {
  print('問題: ${health['issues']}');
}

// 統計情報の確認
print(YataLogger.getPerformanceStatsDebugString());
```

## まとめ

統合LoggerServiceにより、既存のコードを変更することなく、logger パッケージの高性能とrオプション豊富な機能を活用できます。段階的な移行により、システム全体の安定性を保ちながら改善を実現します。
